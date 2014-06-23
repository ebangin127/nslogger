//TODO: Implement DiskFlush Accurately
//      In ATA Command
unit uGSTester;

interface

uses Windows, SysUtils, Generics.Collections, MMSystem, Math, Dialogs,
     Classes,
     uGSList, uRandomBuffer, uTrimCommand, uErrorList;

const
  MaxIOSize = 65536;
  MainLatencyRatio = 5;
  TimeoutInMilliSec = 60000;

type
  TTestStage = (stReady, stLatencyTest, stMainTest, stCount);
  TGSTester = class
  private
    FMasterTrace: TGSList;

    FOverlapped: OVERLAPPED;

    FStage: TTestStage;
    FDriveHandle: THandle;
    FIterator: Integer;
    FFrequency: Double;
    FMainTestCount: Integer;
    FOverallTestCount: Integer;

    FStartLatency, FEndLatency: Int64; //Unit: us(10^-6);
    FMinLatency, FMaxLatency: Int64; //Unit: us(10^-6)
    FHostWrite: Int64;

    FRandomBuffer: PTRandomBuffer;
    FReadBuffer: Array[0..MaxIOSize - 1] of Byte;

    FErrorBuf: TErrorList;

    function DiskWrite(Contents: PTGSNode): Boolean;
    function DiskRead(Contents: PTGSNode): Boolean;
    function DiskTrim(Contents: PTGSNode): Boolean;
    function DiskFlush: Boolean;
    procedure SetIterator(const Value: Integer);

    function WaitForOverlapped(Handle: THandle;
                                pOverlapped: POVERLAPPED): Cardinal;
  public
    property StartLatency: Int64 read FStartLatency write FStartLatency;
    property EndLatency: Int64 read FEndLatency write FEndLatency;
    property MinLatency: Int64 read FMinLatency write FMinLatency;
    property MaxLatency: Int64 read FMaxLatency write FMaxLatency;
    property MainTestCount: Integer read FMainTestCount write FMainTestCount;
    property OverallTestCount: Integer read FOverallTestCount write FOverallTestCount;
    property Iterator: Integer read FIterator write SetIterator;
    property HostWrite: Int64 read FHostWrite write FHostWrite;
    property ErrorBuf: TErrorList read FErrorBuf write FErrorBuf;

    constructor Create(Capacity: UINT64);
    destructor Destroy; override;

    function SetDisk(DriveNumber: Integer): Boolean;

    function GetCurrentStage: TTestStage;
    function GetMaximumLatency: Int64;
    function GetMinimumLatency: Int64;
    function GetOverallTestCount: Integer;
    function GetLength: Integer;
    function GetHostWrite: Integer;

    function ProcessNextOperation: Boolean;

    procedure CheckAlign(Align: Integer; MaxLBA: Int64; OrigLBA: Int64 = 250000000);

    function AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
    function AssignListHeader(NewHeader: PTGListHeader): Boolean;
  end;

const
  TTestStageNum: Array[TTestStage] of Integer = (0, 1, 2, 3);

implementation

function TGSTester.DiskWrite(Contents: PTGSNode): Boolean;
var
  BytesWritten: Cardinal;
  BufferPoint: Pointer;
  LowOrder: UINT;
  HighOrder: UINT;
  APIResult: Cardinal;
begin
  BufferPoint := FRandomBuffer.GetBufferPtr(Contents.FLength);

  LowOrder := Contents.FLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.FLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  FillMemory(@FOverlapped, sizeof(OVERLAPPED), 0);
  FOverlapped.hEvent := CreateEvent(nil, false, false, nil);
  FOverlapped.Offset := LowOrder;
  FOverlapped.OffsetHigh := HighOrder;

  WriteFile(FDriveHandle, BufferPoint^, Contents.FLength, BytesWritten, @FOverlapped);

  APIResult := GetLastError;
  result := ((APIResult = 0) or (APIResult = ERROR_IO_PENDING));

  if APIResult = ERROR_IO_PENDING then
  begin
    result := WaitForOverlapped(FDriveHandle, @FOverlapped) = ERROR_SUCCESS;
  end;

  if result then
    Inc(FHostWrite, Contents.FLength);
end;

function TGSTester.DiskRead(Contents: PTGSNode): Boolean;
var
  BytesRead: Cardinal;
  BufferPoint: Pointer;
  LowOrder: UINT;
  HighOrder: UINT;
  APIResult: Cardinal;
begin
  BufferPoint := @FReadBuffer;

  LowOrder := Contents.FLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.FLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  FillMemory(@FOverlapped, sizeof(OVERLAPPED), 0);
  FOverlapped.hEvent := CreateEvent(nil, false, false, nil);
  FOverlapped.Offset := LowOrder;
  FOverlapped.OffsetHigh := HighOrder;

  ReadFile(FDriveHandle, BufferPoint, Contents.FLength,
           BytesRead, @FOverlapped);

  APIResult := GetLastError;
  result := (APIResult = 0) or (APIResult = ERROR_IO_PENDING);

  if APIResult = ERROR_IO_PENDING then
  begin
    result := WaitForOverlapped(FDriveHandle, @FOverlapped) = ERROR_SUCCESS;
  end;
end;

function TGSTester.DiskTrim(Contents: PTGSNode): Boolean;
var
  TrimResult: Cardinal;
begin
  FillMemory(@FOverlapped, sizeof(OVERLAPPED), 0);
  FOverlapped.hEvent := CreateEvent(nil, false, false, nil);
  FOverlapped.Offset := 0;
  FOverlapped.OffsetHigh := 0;

  TrimResult := SendTrimCommand(FDriveHandle, Contents.FLBA, Contents.FLength,
                                @FOverlapped);

  result := (TrimResult = 0) or (TrimResult = ERROR_IO_PENDING);

  if TrimResult = ERROR_IO_PENDING then
  begin
    result := WaitForOverlapped(FDriveHandle, @FOverlapped) = ERROR_SUCCESS;
  end;
end;

function TGSTester.DiskFlush: Boolean;
begin
  result := FlushFileBuffers(FDriveHandle);
end;

procedure TGSTester.CheckAlign(Align: Integer; MaxLBA, OrigLBA: Int64);
begin
  if OrigLBA <= 0 then
    FMasterTrace.CheckAlign(Align, MaxLBA)
  else
    FMasterTrace.CheckAlign(Align, MaxLBA, OrigLBA);
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

  FMinLatency := -1;
  FMaxLatency := -1;

  FOverallTestCount := 0;

  FErrorBuf := TErrorList.Create(Capacity);
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

  if GetOverlappedResult(Handle, pOverlapped^, BytesReturned, false) = false
  then
    result := GetLastError;
end;

function TGSTester.GetCurrentStage: TTestStage;
begin
  result := FStage;
end;

function TGSTester.GetLength: Integer;
begin
  result := FMasterTrace.GetLength;
end;

function TGSTester.GetHostWrite: Integer;
begin
  result := FHostWrite;
end;

function TGSTester.GetMaximumLatency: Int64;
begin
  result := FMaxLatency;
end;

function TGSTester.GetMinimumLatency: Int64;
begin
  result := FMinLatency;
end;

function TGSTester.GetOverallTestCount: Integer;
begin
  result := FOverallTestCount;
end;

function TGSTester.ProcessNextOperation: Boolean;
var
  NextOperation: PTGSNode;
  StartTime, EndTime: Int64;
  OverallTime: Int64;
begin
  result := false;
  NextOperation := nil;
  case FStage of
    stReady:
    begin
      FMasterTrace.GoToFirst;

      FStage := stLatencyTest;
      result := ProcessNextOperation;
      exit;
    end;

    stLatencyTest..stMainTest:
    begin
      if FIterator = FMasterTrace.GetLength then
      begin
        if FMainTestCount >= (MainLatencyRatio - 1) then
        begin
          FStage := stReady;
          FIterator := 0;

          if StartLatency = 0 then
            StartLatency := MaxLatency;
          EndLatency := MaxLatency;

          result := ProcessNextOperation;
          exit;
        end
        else
        begin
          Inc(FMainTestCount, 1);
          FIterator := 0;
        end;
        Inc(FOverallTestCount, 1);
      end;

      NextOperation := FMasterTrace.GetNextItem;
    end;
  end;

  if NextOperation <> nil then
  begin
    Inc(FIterator, 1);
    if FStage = stLatencyTest then
    begin
      QueryPerformanceCounter(StartTime);
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

    if FStage = stLatencyTest then
    begin
      QueryPerformanceCounter(EndTime);

      OverallTime := round((EndTime - StartTime) / FFrequency);
      if (FMinLatency < 0) or (FMinLatency > OverallTime) then
      begin
        FMinLatency := OverallTime;
      end;
      if (FMaxLatency < 0) or (FMaxLatency < OverallTime) then
      begin
        FMaxLatency := OverallTime;
      end;
    end;

    if result = false then
    begin
      FErrorBuf.AddTGSNode(NextOperation^);
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
