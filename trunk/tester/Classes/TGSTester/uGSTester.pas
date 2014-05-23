//TODO: Implement DiskFlush Accurately
//      In ATA Command
unit uGSTester;

interface

uses Windows, SysUtils, Generics.Collections, MMSystem, Math,
     uGSList, uGSMTAnalyzer, uRandomBuffer, uTrimCommand;

const
  MaxIOSize = 65536;
  MainLatencyRatio = 5;

type
  TTestStage = (stReady, stLatencyTest, stMainTest, stCount);
  TGSTester = class
  private
    FMasterTrace: TGSList;
    FTraceAnalyzer: TGSMTAnalyzer;

    FStage: TTestStage;
    FDriveHandle: THandle;
    FOverlapped: OVERLAPPED;
    FIterator: Integer;
    FFrequency: Double;
    FMainTestCount: Integer;
    FOverallTestCount: Integer;

    FMinLatency, FMaxLatency: Int64; //Unit: us(10^-6)
    FHostWrite: Int64;

    FRandomBuffer: PTRandomBuffer;
    FReadBuffer: Array[0..MaxIOSize - 1] of Byte;

    function DiskWrite(Contents: PTGSNode): Boolean;
    function DiskRead(Contents: PTGSNode): Boolean;
    function DiskTrim(Contents: PTGSNode): Boolean;
    function DiskFlush: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function SetDisk(DriveNumber: Integer): Boolean;

    function GetCurrentStage: TTestStage;
    function GetMaximumLatency: Int64;
    function GetMinimumLatency: Int64;
    function GetOverallTestCount: Integer;
    function GetLength: Integer;
    function GetHostWrite: Integer;

    function ProcessNextOperation: Boolean;

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
begin
  BufferPoint := FRandomBuffer.GetBufferPtr(Contents.FLength);

  if Contents.FLBA = 0 then
    Contents.FLBA := 512;

  if Contents.FLBA shr 23 > 0 then
    Contents.FLBA := Contents.FLBA and ((1 shl 23) - 1);

  LowOrder := Contents.FLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.FLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  result := (SetFilePointer(FDriveHandle, LowOrder, @HighOrder, FILE_BEGIN) = LowOrder);
  result := WriteFile(FDriveHandle, BufferPoint^, Contents.FLength,
                      BytesWritten, nil);

  if result then
    Inc(FHostWrite, Contents.FLength);

  Assert(result, IntToStr(GetLastError) + ' LBA: ' + IntToStr(Contents.FLBA) + ' Length: ' + IntToStr(Contents.FLength));
end;

function TGSTester.DiskRead(Contents: PTGSNode): Boolean;
var
  BytesRead: Cardinal;
  BufferPoint: Pointer;
  LowOrder: UINT;
  HighOrder: UINT;
begin
  BufferPoint := @FReadBuffer;

  LowOrder := Contents.FLBA shl 9 and $FFFFFFFF;
  HighOrder := Contents.FLBA shr 23 and $FFFFFFFF;
  //Because the Unit is in bytes, MAX LBA size is 55 bits > 48bit LBA
  //So now it is okay to use this unit

  SetFilePointer(FDriveHandle, LowOrder, @HighOrder, FILE_BEGIN);
  result := ReadFile(FDriveHandle, BufferPoint, Contents.FLength,
                     BytesRead, nil);
end;

function TGSTester.DiskTrim(Contents: PTGSNode): Boolean;
begin
  result := (SendTrimCommand(FDriveHandle, Contents.FLBA, Contents.FLength)
             = ERROR_SUCCESS);
end;

function TGSTester.DiskFlush: Boolean;
begin
  result := FlushFileBuffers(FDriveHandle);
end;

constructor TGSTester.Create;
var
  Frequency: Int64;
begin
  FDriveHandle := 0;
  FIterator := 0;

  FMasterTrace := TGSList.Create;
  FTraceAnalyzer := TGSMTAnalyzer.Create;
  FTraceAnalyzer.AssignList(@FMasterTrace);

  QueryPerformanceFrequency(Frequency);
  FFrequency := Frequency / 1000000; //us(10^-6)

  FMinLatency := -1;
  FMaxLatency := -1;

  FOverallTestCount := 0;
end;

destructor TGSTester.Destroy;
begin
  if FDriveHandle <> 0 then
  begin
    CloseHandle(FDriveHandle);
    FDriveHandle := 0;
  end;

  FreeAndNil(FMasterTrace);
  FreeAndNil(FTraceAnalyzer);
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
                              FILE_FLAG_NO_BUFFERING,
                              0);

  result := (GetLastError = 0);
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
  case FStage of
    stReady:
    begin
      FTraceAnalyzer.GoToFirst;
      FMasterTrace.GoToFirst;

      FStage := stLatencyTest;
      result := ProcessNextOperation;
      exit;
    end;

    stLatencyTest:
    begin
      if FIterator = FTraceAnalyzer.GetLength then
      begin
        FStage := stMainTest;
        FIterator := 0;
        FMainTestCount := 0;

        Inc(FOverallTestCount, 1);
        result := ProcessNextOperation;
        exit;
      end;

      NextOperation := FTraceAnalyzer.GetNextAction;
    end;

    stMainTest:
    begin
      if FIterator = FMasterTrace.GetLength then
      begin
        if FMainTestCount >= (MainLatencyRatio - 1) then
        begin
          FStage := stReady;
          FIterator := 0;

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
  end;
end;

function TGSTester.AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
begin
  result := RandBuf <> nil;
  FRandomBuffer := RandBuf;
end;

function TGSTester.AssignListHeader(NewHeader: PTGListHeader): Boolean;
begin
  result := FMasterTrace.AssignHeader(NewHeader) and
            FTraceAnalyzer.AssignList(@FMasterTrace);
end;
end.
