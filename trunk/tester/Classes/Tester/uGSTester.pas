unit uGSTester;

interface

uses Windows, SysUtils, Generics.Collections, MMSystem, Math, Dialogs,
     Classes,
     uGSList, uRandomBuffer, uTrimCommand, uErrorList;

const
  MaxIOSize = 65536;
  TimeoutInMilliSec = 10000;
  MaxParallelIO = 4;

type
  TTestStage = (stReady, stLatencyTest, stCount);
  TGSTester = class
  private
    FMasterTrace: TGSList;

    FOverlapped: TList<POVERLAPPED>;

    FStage: TTestStage;
    FDriveHandle: THandle;
    FIterator: Integer;
    FFrequency: Double;
    FOverallTestCount: Integer;

    FStartLatency, FEndLatency: Int64; //Unit: us(10^-6)
    FSumLatency: UInt64;
    FAvgLatency, FMaxLatency: Int64; //Unit: us(10^-6)
    FHostWrite: Int64;

    FStartTime: Int64;

    FRandomBuffer: PTRandomBuffer;
    FReadBuffer: Array[0..MaxIOSize - 1] of Byte;

    FErrorBuf: TErrorList;
    FErrorCount: Integer;

    FCleared: Boolean;

    function DiskWrite(Contents: PTGSNode): Boolean;
    function DiskRead(Contents: PTGSNode): Boolean;
    function DiskTrim(Contents: PTGSNode): Boolean;
    function DiskFlush: Boolean;
    procedure SetIterator(const Value: Integer);
    procedure ClearAvgLatency;

    function WaitForOverlapped(Handle: THandle;
                                pOverlapped: POVERLAPPED): Cardinal;
  public
    function GetCurrentStage: TTestStage;
    function GetMaximumLatency: Int64;
    function GetAverageLatency: Int64;
    function GetOverallTestCount: Integer;
    function GetLength: Integer;
    function GetHostWrite: Int64;

    property StartLatency: Int64 read FStartLatency write FStartLatency;
    property EndLatency: Int64 read FEndLatency write FEndLatency;
    property SumLatency: UInt64 read FSumLatency write FSumLatency;
    property AvgLatency: Int64 read GetAverageLatency write FAvgLatency;
    property MaxLatency: Int64 read FMaxLatency write FMaxLatency;
    property OverallTestCount: Integer read FOverallTestCount write FOverallTestCount;
    property Iterator: Integer read FIterator write SetIterator;
    property HostWrite: Int64 read FHostWrite write FHostWrite;
    property ErrorBuf: TErrorList read FErrorBuf write FErrorBuf;
    property ErrorCount: Integer read FErrorCount write FErrorCount;

    constructor Create(Capacity: UINT64);
    destructor Destroy; override;

    function SetDisk(DriveNumber: Integer): Boolean;
    function ClearList: Boolean;

    function ProcessNextOperation: Boolean;

    procedure CheckAlign(Align: Integer; MaxLBA: Int64; OrigLBA: Int64 = 250000000);

    function AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
    function AssignListHeader(NewHeader: PTGListHeader): Boolean;
  end;

const
  TTestStageNum: Array[TTestStage] of Integer = (0, 1, 2);

implementation

function TGSTester.DiskWrite(Contents: PTGSNode): Boolean;
var
  BytesWritten: Cardinal;
  BufferPoint: Pointer;
  LowOrder: UINT;
  HighOrder: UINT;
  IOLength: UINT;
  APIResult: Cardinal;
  CurrOvlp: POVERLAPPED;
begin
  IOLength := UINT(Contents.FLength) shl 9;
  BufferPoint := FRandomBuffer.GetBufferPtr(IOLength);

  LowOrder := Contents.FLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.FLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  GetMem(CurrOvlp, sizeof(OVERLAPPED));
  FillMemory(CurrOvlp, sizeof(OVERLAPPED), 0);
  CurrOvlp.hEvent := CreateEvent(nil, true, false, nil);
  CurrOvlp.Offset := LowOrder;
  CurrOvlp.OffsetHigh := HighOrder;

  WriteFile(FDriveHandle, BufferPoint^, IOLength,
            BytesWritten, CurrOvlp);

  APIResult := GetLastError;
  result := ((APIResult = 0) or (APIResult = ERROR_IO_PENDING));

  if APIResult = ERROR_IO_PENDING then
  begin
    FOverlapped.Add(CurrOvlp);
    if FOverlapped.Count > MaxParallelIO then
      result := ClearList;
  end
  else if result = true then
  begin
    CloseHandle(CurrOvlp.hEvent);
    FreeMem(CurrOvlp);
  end;

  if result then
    Inc(FHostWrite, Contents.FLength shl 9);
end;

function TGSTester.DiskRead(Contents: PTGSNode): Boolean;
var
  BytesRead: Cardinal;
  BufferPoint: Pointer;
  LowOrder: UINT;
  HighOrder: UINT;
  IOLength: UINT;
  APIResult: Cardinal;
  CurrOvlp: POVERLAPPED;
begin
  BufferPoint := @FReadBuffer;

  LowOrder := Contents.FLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.FLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  IOLength := UINT(Contents.FLength) shl 9;

  GetMem(CurrOvlp, sizeof(OVERLAPPED));
  FillMemory(CurrOvlp, sizeof(OVERLAPPED), 0);
  CurrOvlp.hEvent := CreateEvent(nil, true, false, nil);
  CurrOvlp.Offset := LowOrder;
  CurrOvlp.OffsetHigh := HighOrder;

  ReadFile(FDriveHandle, BufferPoint, IOLength,
           BytesRead, CurrOvlp);

  APIResult := GetLastError;
  result := (APIResult = 0) or (APIResult = ERROR_IO_PENDING);

  if APIResult = ERROR_IO_PENDING then
  begin
    FOverlapped.Add(CurrOvlp);
    if FOverlapped.Count > MaxParallelIO then
      result := ClearList;
  end
  else if result = true then
  begin
    CloseHandle(CurrOvlp.hEvent);
    FreeMem(CurrOvlp);
  end;
end;

function TGSTester.DiskTrim(Contents: PTGSNode): Boolean;
var
  TrimResult: Cardinal;
  CurrOvlp: POVERLAPPED;
begin
  GetMem(CurrOvlp, sizeof(OVERLAPPED));
  FillMemory(CurrOvlp, sizeof(OVERLAPPED), 0);
  CurrOvlp.hEvent := CreateEvent(nil, true, false, nil);
  CurrOvlp.Offset := 0;
  CurrOvlp.OffsetHigh := 0;

  TrimResult := SendTrimCommand(FDriveHandle, Contents.FLBA, Contents.FLength,
                                nil);

  result := (TrimResult = 0) or (TrimResult = ERROR_IO_PENDING);

  if TrimResult = ERROR_IO_PENDING then
  begin
    FOverlapped.Add(CurrOvlp);
    if FOverlapped.Count > MaxParallelIO then
      result := ClearList;
  end
  else if result = true then
  begin
    CloseHandle(CurrOvlp.hEvent);
    FreeMem(CurrOvlp);
  end;
end;

function TGSTester.DiskFlush: Boolean;
var
  FlushResult: Cardinal;
  CurrOvlp: POVERLAPPED;
begin
  GetMem(CurrOvlp, sizeof(OVERLAPPED));
  FillMemory(CurrOvlp, sizeof(OVERLAPPED), 0);
  CurrOvlp.hEvent := CreateEvent(nil, true, false, nil);
  CurrOvlp.Offset := 0;
  CurrOvlp.OffsetHigh := 0;

  FlushResult := SendFlushCommand(FDriveHandle);
  result := (FlushResult = 0) or (FlushResult = ERROR_IO_PENDING);

  if FlushResult = ERROR_IO_PENDING then
  begin
    FOverlapped.Add(CurrOvlp);
    if FOverlapped.Count > MaxParallelIO then
      result := ClearList;
  end
  else if result = true then
  begin
    CloseHandle(CurrOvlp.hEvent);
    FreeMem(CurrOvlp);
  end;
end;

procedure TGSTester.CheckAlign(Align: Integer; MaxLBA, OrigLBA: Int64);
begin
  if OrigLBA <= 0 then
    FMasterTrace.CheckAlign(Align, MaxLBA)
  else
    FMasterTrace.CheckAlign(Align, MaxLBA, OrigLBA);
end;

procedure TGSTester.ClearAvgLatency;
begin
  FSumLatency := 0;
end;

function TGSTester.ClearList: Boolean;
var
  CurrOvlp: POVERLAPPED;
begin
  result := true;
  FCleared := true;

  if FOverlapped.Count > 0 then
  begin
    while FOverlapped.Count > 0 do
    begin
      CurrOvlp := FOverlapped[0];
      result := result and
                (WaitForOverlapped(FDriveHandle, CurrOvlp) = ERROR_SUCCESS);

      CloseHandle(CurrOvlp.hEvent);
      FreeMem(CurrOvlp);

      FOverlapped.Delete(0);
    end;
  end;
end;

constructor TGSTester.Create(Capacity: UINT64);
var
  Frequency: Int64;
begin
  FDriveHandle := 0;
  FIterator := 0;

  FMasterTrace := TGSList.Create;

  QueryPerformanceFrequency(Frequency);
  FFrequency := Frequency / 1000000; //us(10^-6)

  FSumLatency := 0;
  FAvgLatency := 0;
  FMaxLatency := -1;
  FErrorCount := 0;

  FOverallTestCount := 0;

  FErrorBuf := TErrorList.Create;
  FOverlapped := TList<POVERLAPPED>.Create;
end;

destructor TGSTester.Destroy;
begin
  if FDriveHandle <> 0 then
  begin
    CloseHandle(FDriveHandle);
    FDriveHandle := 0;
  end;

  FreeAndNil(FMasterTrace);
  FreeAndNil(FErrorBuf);
  FreeAndNil(FOverlapped);
end;

function TGSTester.SetDisk(DriveNumber: Integer): Boolean;
begin
  if FDriveHandle <> 0 then
  begin
    CloseHandle(FDriveHandle);
    FDriveHandle := 0;
  end;

  FDriveHandle := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(DriveNumber)),
                              GENERIC_READ or GENERIC_WRITE,
                              FILE_SHARE_READ or FILE_SHARE_WRITE,
                              nil,
                              OPEN_EXISTING,
                              FILE_FLAG_NO_BUFFERING or
                              FILE_FLAG_OVERLAPPED,
                              0);
  result := (GetLastError = 0);
end;

procedure TGSTester.SetIterator(const Value: Integer);
begin
  FMasterTrace.GoToNum(Value);
  FIterator := Value;
end;

function TGSTester.WaitForOverlapped(Handle: THandle;
                                      pOverlapped: POVERLAPPED): Cardinal;
var
  BytesReturned: DWORD;
begin
  WaitForSingleObject(pOverlapped.hEvent, TimeoutInMilliSec);
  result := 0;

  if (GetOverlappedResult(Handle, pOverlapped^, BytesReturned, false) = false) or
     (BytesReturned = 0)
  then
  begin
    result := GetLastError;
  end;
end;

function TGSTester.GetCurrentStage: TTestStage;
begin
  result := FStage;
end;

function TGSTester.GetLength: Integer;
begin
  result := FMasterTrace.GetLength;
end;

function TGSTester.GetHostWrite: Int64;
begin
  result := FHostWrite;
end;

function TGSTester.GetMaximumLatency: Int64;
begin
  result := FMaxLatency;
end;

function TGSTester.GetAverageLatency: Int64;
begin
  if (FIterator div MaxParallelIO) = 0 then
    exit(0);

  result := round(FSumLatency / (FIterator div MaxParallelIO));
end;

function TGSTester.GetOverallTestCount: Integer;
begin
  result := FOverallTestCount;
end;

function TGSTester.ProcessNextOperation: Boolean;
var
  NextOperation: PTGSNode;
  OverallTime: Int64;
  EndTime: Int64;
begin
  result := false;
  NextOperation := nil;
  if FIterator = 0 then
    ClearAvgLatency;

  case FStage of
    stReady:
    begin
      FMasterTrace.GoToFirst;
      FCleared := true;

      FStage := stLatencyTest;
      result := ProcessNextOperation;
      exit;
    end;

    stLatencyTest:
    begin
      if FIterator = FMasterTrace.GetLength then
      begin
        FStage := stReady;
        FIterator := 0;

        if StartLatency = 0 then
          StartLatency := MaxLatency;
        EndLatency := MaxLatency;

        Inc(FOverallTestCount, 1);
        result := ProcessNextOperation;
        exit;
      end;

      NextOperation := FMasterTrace.GetNextItem;
    end;
  end;

  if NextOperation <> nil then
  begin
    Inc(FIterator, 1);
    if FCleared then
    begin
      QueryPerformanceCounter(FStartTime);
      FCleared := false;
    end;

    case NextOperation.FIOType of
      0{ioRead}:
        result := DiskRead(NextOperation);
      1{ioWrite}:
        result := DiskWrite(NextOperation);
      2{ioTrim}:
        result := DiskTrim(NextOperation);
      3{ioFlush}:
        result := DiskFlush;
    end;

    if FCleared then
    begin
      QueryPerformanceCounter(EndTime);

      OverallTime := round((EndTime - FStartTime) / FFrequency);
      Inc(FSumLatency, OverallTime);
      if (FMaxLatency < 0) or (FMaxLatency < OverallTime) then
      begin
        FMaxLatency := OverallTime;
      end;
    end;

    if result = false then
    begin
      FErrorBuf.Add(NextOperation);
      Inc(FErrorCount);
    end;
  end;
end;

function TGSTester.AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
begin
  result := RandBuf <> nil;
  FRandomBuffer := RandBuf;
end;

function TGSTester.AssignListHeader(NewHeader: PTGListHeader): Boolean;
begin
  result := FMasterTrace.AssignHeader(NewHeader);
end;
end.
