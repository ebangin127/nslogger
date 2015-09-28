unit uGSTester;

interface

uses Windows, SysUtils, Generics.Collections, MMSystem, Math, Dialogs,
     Classes,
     uGSList, uRandomBuffer, uErrorList, uGSNode,
     uCommandSet, uCommandSetFactory, Device.PhysicalDrive;

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
    FCommandSet: TCommandSet;
    FIterator: Integer;
    FListIterator: IGSListIterator;
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

    function DiskWrite(const Contents: TGSNode): Boolean;
    function DiskRead(const Contents: TGSNode): Boolean;
    function DiskTrim(const Contents: TGSNode): Boolean;
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

    function AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
    procedure AssignList(const NewList: TGSList);
  end;

const
  TTestStageNum: Array[TTestStage] of Integer = (0, 1, 2);

implementation

function TGSTester.DiskWrite(const Contents: TGSNode): Boolean;
var
  BytesWritten: Cardinal;
  BufferPoint: Pointer;
  LowOrder: UINT;
  HighOrder: UINT;
  IOLength: UINT;
  APIResult: Cardinal;
  CurrOvlp: POVERLAPPED;
begin
  IOLength := UINT(Contents.GetLength) shl 9;
  BufferPoint := FRandomBuffer.GetBufferPtr(IOLength);

  LowOrder := Contents.GetLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.GetLBA shr 23 and $FFFFFFFF;
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

  if (result = false) and (APIResult <> ERROR_IO_PENDING) then
    Assert(false, 'Write Error: ' + IntToStr(APIResult));

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
    Inc(FHostWrite, Contents.GetLength shl 9);
end;

function TGSTester.DiskRead(const Contents: TGSNode): Boolean;
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

  LowOrder := Contents.GetLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.GetLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  IOLength := UINT(Contents.GetLength) shl 9;

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

function TGSTester.DiskTrim(const Contents: TGSNode): Boolean;
var
  TrimResult: Cardinal;
begin
  TrimResult :=
    FCommandSet.DataSetManagement(Contents.GetLBA, Contents.GetLength);
  result := TrimResult = ERROR_SUCCESS;
end;

function TGSTester.DiskFlush: Boolean;
var
  FlushResult: Cardinal;
begin
  FlushResult := ERROR_SUCCESS;
  try
    FCommandSet.Flush;
  except
    on E: EOSError do
      FlushResult := E.ErrorCode
    else
      raise;
  end;
  result := FlushResult = ERROR_SUCCESS;
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
  FMasterTrace := TGSList.Create;
  FListIterator := FMasterTrace.GetIterator;

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
    FreeAndNil(FCommandSet);
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
    FreeAndNil(FCommandSet);
    FDriveHandle := 0;
  end;

  FDriveHandle :=
    CreateFile(PChar(TPhysicalDrive.BuildFileAddressByNumber(DriveNumber)),
      GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE,
      nil, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING or FILE_FLAG_OVERLAPPED, 0);
  FCommandSet :=
    CommandSetFactory.GetSuitableCommandSet(
      TPhysicalDrive.BuildFileAddressByNumber(DriveNumber));

  result := (GetLastError = 0);
end;

procedure TGSTester.SetIterator(const Value: Integer);
begin
  FIterator := Value;
  FListIterator.SetIndex(Value);
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
  result := FMasterTrace.Count;
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
  NextOperation: TGSNode;
  OverallTime: Int64;
  EndTime: Int64;
begin
  result := false;
  ZeroMemory(@NextOperation, SizeOf(NextOperation));
  if FIterator = 0 then
    ClearAvgLatency;

  case FStage of
    stReady:
    begin
      FListIterator.GoToFirst;
      FCleared := true;

      FStage := stLatencyTest;
      result := ProcessNextOperation;
      exit;
    end;

    stLatencyTest:
    begin
      if FIterator = FMasterTrace.Count then
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

      NextOperation := FListIterator.GetNextItem;
    end;
  end;

  if FStage <> stReady then
  begin
    Inc(FIterator, 1);
    if FCleared then
    begin
      QueryPerformanceCounter(FStartTime);
      FCleared := false;
    end;

    case NextOperation.GetIOType of
      TIOType.ioRead:
        result := DiskRead(NextOperation);
      TIOType.ioWrite:
        result := DiskWrite(NextOperation);
      TIOType.ioTrim:
        result := DiskTrim(NextOperation);
      TIOType.ioFlush:
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

procedure TGSTester.AssignList(const NewList: TGSList);
begin
  if FMasterTrace <> nil then
    FreeAndNil(FMasterTrace);
  FMasterTrace := NewList;
  FListIterator := FMasterTrace.GetIterator;
  FListIterator.SetIndex(FIterator);
end;
end.
