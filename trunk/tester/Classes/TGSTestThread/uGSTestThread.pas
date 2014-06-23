unit uGSTestThread;

interface

uses Classes, SysUtils, ComCtrls, Math, Windows, DateUtils,
     uGSTester, uGSList, uRandomBuffer, uSMARTManager, uSaveFile;

type
  TmakeJEDECList  = function (TraceList: Pointer; path: PChar): PTGListHeader; cdecl;
  TmakeJEDECClass = function: Pointer; cdecl;
  TdeleteJEDECClass = procedure(delClass: Pointer); cdecl;

const
  ByteToTB = 40;
  EXIT_NORMAL = 0;
  EXIT_RETENTION = 1;
  EXIT_HOSTWRITE = 2;

type
  TGSTestThread = class(TThread)
  private
    FTester: TGSTester;
    FSMARTManager: TSMARTManager;
    FRandomBuffer: TRandomBuffer;
    FSaveFile: TSaveFile;

    FSavePath: String;
    FTracePath: String;

    FLoadedState: Integer; //Bit 0: BufferLoaded, Bit 1: ListLoaded
    FFullyLoaded: Boolean;
    FStarted: Boolean;

    FBufSize: Integer;

    FLastSync: Cardinal;    
    FSecCounter: Integer;
    FLastSyncCount: Integer;

    FDLLHandle: THandle;
    ClassPTR: Pointer;

    FMaxLBA: UInt64;
    FOrigLBA: UInt64;
    FAlign: Integer;

    FMaxHostWrite: UInt64;
    FRetentionTest: UInt64;
    FExitCode: Byte;

    makeJEDECList: TmakeJEDECList;
    makeJEDECClass: TmakeJEDECClass;
    deleteJEDECClass: TdeleteJEDECClass;

    function LBAto48Bit(NewLBA: UInt64): UInt64;

    procedure SetMaxLBA(NewLBA: UInt64);
    procedure SetOrigLBA(NewLBA: UInt64);
    function ReadMaxTBW: UInt64;
    function ReadRetTest: UInt64;
    procedure WriteMaxTBW(const Value: UInt64);
    procedure WriteRetTest(const Value: UInt64);
  public
    property ExitCode: Byte read FExitCode;

    property MaxLBA: UInt64 read FMaxLBA write SetMaxLBA;
    property OrigLBA: UInt64 read FOrigLBA write SetOrigLBA;
    property Align: Integer read FAlign write FAlign;

    property MaxHostWrite: UInt64 read ReadMaxTBW write WriteMaxTBW;
    property RetentionTest: UInt64 read ReadRetTest write WriteRetTest;

    constructor Create(TracePath: String; Capacity: UINT64); overload;
    constructor Create(TracePath: String; RandomSeed: Int64; Capacity: UINT64); overload;
    constructor Create(TracePath: String; CreateSuspended: Boolean; Capacity: UINT64); overload;
    constructor Create(TracePath: String; CreateSuspended: Boolean; Capacity: UINT64; RandomSeed: Int64); overload;

    destructor Destroy; override;

    procedure ApplyState;
    procedure ApplyAlignTest;
    procedure ApplyStart;
    procedure Execute; override;

    procedure StartThread;

    procedure AssignSavePath(const Path: String);
    function AssignBufferSetting(BufSize: Integer; RandomnessInInteger: Integer):
              Boolean; overload;
    function AssignBufferSetting(BufSize: Integer; RandomnessInString: String):
              Boolean; overload;
    function AssignDLLPath(DLLPath: String): Boolean;
    function SetDisk(DriveNumber: Integer): Boolean;

    function Save(SaveFilePath: String): Boolean;
    function SaveTodaySpeed(SaveFilePath: String): Boolean;
    function Load(SaveFilePath: String): Boolean;
  end;

implementation

uses uMain;

constructor TGSTestThread.Create(TracePath: String; RandomSeed: Int64;
                                 Capacity: UINT64);
begin
  inherited Create;

  FSaveFile := TSaveFile.Create;
  FSaveFile.RandomSeed := RandomSeed;

  FTester := TGSTester.Create(Capacity);
  FSMARTManager := TSMARTManager.Create;
  FRandomBuffer := TRandomBuffer.Create(RandomSeed);

  FTracePath := TracePath;
end;

constructor TGSTestThread.Create(TracePath: String; Capacity: UINT64);
var
  RandomSeed: Int64;
begin
  inherited Create;

  if QueryPerformanceCounter(RandomSeed) = false then
    RandomSeed := GetTickCount;

  Create(TracePath, RandomSeed, Capacity);
end;

constructor TGSTestThread.Create(TracePath: String; CreateSuspended: Boolean;
                                 Capacity: UINT64);
begin
  inherited Create(CreateSuspended);
  Create(TracePath, Capacity);
end;

constructor TGSTestThread.Create(TracePath: String; CreateSuspended: Boolean;
                                 Capacity: UINT64; RandomSeed: Int64);
begin
  inherited Create(CreateSuspended);
  Create(TracePath, Capacity, RandomSeed);
end;

destructor TGSTestThread.Destroy;
begin
  FreeAndNil(FTester);
  FreeAndNil(FSMARTManager);
  FreeAndNil(FRandomBuffer);
  FreeAndNil(FSaveFile);
  if FDLLHandle <> 0 then
  begin
    if ClassPTR <> nil then
    begin
      deleteJEDECClass(ClassPTR);
    end;

    FDLLHandle := 0;
    CloseHandle(FDLLHandle);
  end;
end;

procedure TGSTestThread.ApplyAlignTest;
begin
  fMain.sTestStage.Caption :=
    '테스트 SSD에 트레이스 맞추는 중';
end;


procedure TGSTestThread.ApplyStart;
begin
  fMain.bSave.Enabled := true;
end;

procedure TGSTestThread.ApplyState;
var
  MinLatency, MaxLatency: Double;
  HostWrite: Double;
  TestProgress: Integer;
  RamStats: TMemoryStatusEx;
  ErrorString: String;
begin
  with fMain do
  begin
    if FLastSyncCount <> FTester.GetOverallTestCount + 1 then
    begin
      FLastSyncCount := FTester.GetOverallTestCount + 1;
      lAlert.Items.Add(IntToStr(FLastSyncCount) + '회 시작: '
                        + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
      sCycleCount.Caption := IntToStr(FLastSyncCount) + '회';
    end;

    while FTester.ErrorBuf.Count > 0 do
    begin
      ErrorString := FormatDateTime('[yyyy/mm/dd hh:nn:ss]', Now);
      case FTester.ErrorBuf.Items[0].FIOType of
      0{ioRead}:
        ErrorString := ErrorString + '읽기 오류: ';
      1{ioWrite}:
        ErrorString := ErrorString + '쓰기 오류: ';
      2{ioTrim}:
        ErrorString := ErrorString + '트림 오류: ';
      3{ioFlush}:
        ErrorString := ErrorString + '플러시 오류';
      end;

      case FTester.ErrorBuf.Items[0].FIOType of
      0..2:
      begin
        ErrorString := ErrorString + '위치 ' + IntToStr(FTester.ErrorBuf.Items[0].FLBA)
                        + ', ';
        ErrorString := ErrorString + '길이 ' + IntToStr(FTester.ErrorBuf.Items[0].FLength);
      end;
      end;

      lAlert.Items.Add(ErrorString);
      FTester.ErrorBuf.Delete(0);
    end;

    with sTestStage do
    begin
      case FTester.GetCurrentStage of
        stReady:
        begin
          Caption := '테스트 준비중';
        end;

        stLatencyTest:
        begin
          Caption := '지연 시간 테스트';
        end;

        stMainTest:
        begin
          Caption := '쓰기 테스트';
        end;
      end;
    end;

    MinLatency := FTester.GetMinimumLatency / 1000;
    MaxLatency := FTester.GetMaximumLatency / 1000;

    if MinLatency < 100 then
    begin
      sMinLatency.Caption := '양호(';
      pMinLatency.State := pbsNormal;
    end
    else if MinLatency < 500 then
    begin
      sMinLatency.Caption := '위험(';
      pMinLatency.State := pbsPaused;
    end
    else if MinLatency >= 500 then
    begin
      sMinLatency.Caption := '불량(';
      pMinLatency.State := pbsError;
    end;

    if MaxLatency < 100 then
    begin
      sMaxLatency.Caption := '양호(';
      pMaxLatency.State := pbsNormal;
    end
    else if MaxLatency < 500 then
    begin
      sMaxLatency.Caption := '보통(';
      pMaxLatency.State := pbsPaused;
    end
    else if MaxLatency >= 500 then
    begin
      sMaxLatency.Caption := '위험(';
      pMaxLatency.State := pbsError;
    end;

    sMinLatency.Caption := sMinLatency.Caption +
                            Format('%.2f%s)', [MinLatency, 'ms']);

    sMaxLatency.Caption := sMaxLatency.Caption +
                            Format('%.2f%s)', [MaxLatency, 'ms']);


    if MinLatency > 0 then
    begin
      pMinLatency.Position := round(Log10((MinLatency / 500) * 100) / 2 * 100);
      pMaxLatency.Position := round(Log10((MaxLatency / 500) * 100) / 2 * 100);
    end;

    TestProgress := round(FTester.GetHostWrite / FMaxHostWrite * 100);
    pTestProgress.Position := TestProgress;
    sTestProgress.Caption := IntToStr(TestProgress) + '% (';

    HostWrite := FTester.GetHostWrite / 1024 / 1024; //Unit: MB
    if HostWrite > (1024 * 1024 * 1024 / 4 * 3) then //Above 0.75PB
    begin
      sTestProgress.Caption :=
        sTestProgress.Caption +
          Format('%.2fPBW)', [HostWrite / 1024 / 1024 / 1024]);
    end
    else if HostWrite > (1024 * 1024 / 4 * 3) then //Above 0.75TB
    begin
      sTestProgress.Caption :=
        sTestProgress.Caption +
          Format('%.2fTBW)', [HostWrite / 1024 / 1024]);
    end
    else if HostWrite > (1024 / 4 * 3) then //Above 0.75GB
    begin
      sTestProgress.Caption :=
        sTestProgress.Caption +
          Format('%.2fGBW)', [HostWrite / 1024]);
    end
    else
    begin
      sTestProgress.Caption :=
        sTestProgress.Caption +
          Format('%.2fMBW)', [HostWrite]);
    end;


    FillChar(RamStats, SizeOf(RamStats), 0);
    RamStats.dwLength := SizeOf(RamStats);
    GlobalMemoryStatusEx(RamStats);

    if RamStats.ullAvailPhys < (50 shl 20) then
    begin
      sRamUsage.Caption := '램 부족(';
      pRamUsage.State := pbsError;
    end
    else if RamStats.ullAvailPhys < (100 shl 20) then
    begin
      sRamUsage.Caption := '보통(';
      pRamUsage.State := pbsPaused;
    end
    else
    begin
      sRamUsage.Caption := '여유로움(';
      pRamUsage.State := pbsNormal;
    end;

    sRamUsage.Caption := sRamUsage.Caption + Format('%dMB)',
                                                    [RamStats.ullAvailPhys shr 20]);
    pRamUsage.Position := round(((RamStats.ullAvailPhys shr 20) /
                                 (RamStats.ullTotalPhys shr 20)) * 100);
  end;
end;

procedure TGSTestThread.Execute;
var
  CurrTime: Cardinal;
begin
  while not FStarted do
    Sleep(100);

  if FFullyLoaded = false then
    exit;

  FLastSync := 0;
  FSecCounter := 0;

  ClassPTR := makeJEDECClass;
  FTester.AssignListHeader(makeJEDECList(ClassPTR, PChar(FTracePath)));

  Synchronize(ApplyAlignTest);
  FTester.CheckAlign(Align, MaxLBA, OrigLBA);

  Synchronize(ApplyStart);
  Synchronize(ApplyState);
  while not Terminated do
  begin
    if (((FTester.GetHostWrite mod FRetentionTest) = 0) and
        ((FTester.GetHostWrite <> 0) and (FTester.StartLatency <> 0))) or
       (FTester.GetHostWrite = FMaxHostWrite) then
    begin
      if ((FTester.GetHostWrite mod FRetentionTest) = 0) and
         ((FTester.GetHostWrite <> 0) and (FTester.StartLatency <> 0)) then
         FExitCode := EXIT_RETENTION
      else
         FExitCode := EXIT_HOSTWRITE;

      exit;
    end;

    if FTester.ProcessNextOperation then
    begin
      CurrTime := GetTickCount;
      if (CurrTime - FLastSync) > 1000 then
      begin
        Synchronize(ApplyState);

        FSecCounter := FSecCounter + 1;
        if FSecCounter >= 600 then // 10 minutes
        begin
          SaveTodaySpeed(FSavePath);
          Save(FSavePath);
          FSecCounter := 0;
        end;

        FLastSync := CurrTime;
      end;
    end
    else
    begin
      break;
    end;
  end;

  SaveTodaySpeed(FSavePath);
  Save(FSavePath);
end;

function TGSTestThread.SaveTodaySpeed(SaveFilePath: String): Boolean;
var
  SaveFile: TStringList;
  LastTime, CurrTime: TDateTime;
begin
  SaveFile := TStringList.Create;

  if FileExists(SaveFilePath + 'speedlog.txt') then
    SaveFile.LoadFromFile(SaveFilePath + 'speedlog.txt');

  //오늘 저장한 적이 있으면 처리
  if SaveFile.Count > 0 then
  begin
    LastTime := UnixToDateTime(StrToInt64(SaveFile[0]));
    CurrTime := Time;
    if (LastTime >= floor(CurrTime)) and (LastTime < ceil(CurrTime)) then
    begin
      SaveFile.Delete(SaveFile.Count - 1);
    end;
  end;

  //저장하기 위해서 내용 적기
  SaveFile[0] := IntToStr(DateTimeToUnix(CurrTime));
  SaveFile.Add(IntToStr(FTester.StartLatency) + ' ' +
               IntToStr(FTester.EndLatency) + ' ' +
               IntToStr(FTester.MaxLatency) + ' ' +
               IntToStr(FTester.MinLatency));

  SaveFile.SaveToFile(SaveFilePath + 'speedlog.txt');

  FTester.StartLatency := 0;
  FTester.EndLatency := 0;
  FTester.MaxLatency := 0;
  FTester.MinLatency := 0;

  FreeAndNil(SaveFile);
end;

function TGSTestThread.Save(SaveFilePath: String): Boolean;
begin
  FSaveFile.MaxTBW := FMaxHostWrite;
  FSaveFile.RetTBW := FRetentionTest;
  FSaveFile.TracePath := FTracePath;

  FSaveFile.CurrTBW := FTester.GetHostWrite;
  FSaveFile.StartLatency := FTester.StartLatency;
  FSaveFile.EndLatency := FTester.EndLatency;

  FSaveFile.MinLatency := FTester.GetMinimumLatency;
  FSaveFile.MaxLatency := FTester.GetMaximumLatency;

  FSaveFile.MainTestCount := FTester.MainTestCount;
  FSaveFile.OverallTestCount := FTester.OverallTestCount;
  FSaveFile.Iterator := FTester.Iterator;

  FTester.ErrorBuf.Save(SaveFilePath + 'error.txt');
  result := FSaveFile.SaveToFile(SaveFilePath + 'settings.ini');
end;

function TGSTestThread.Load(SaveFilePath: String): Boolean;
begin
  result := FSaveFile.LoadFromFile(SaveFilePath);

  FMaxHostWrite := FSaveFile.MaxTBW;
  FRetentionTest := FSaveFile.RetTBW;
  FTracePath := FSaveFile.TracePath;

  FTester.HostWrite := FSaveFile.CurrTBW;
  FTester.StartLatency := FSaveFile.StartLatency;
  FTester.EndLatency := FSaveFile.EndLatency;

  FTester.MinLatency := FSaveFile.MinLatency;
  FTester.MaxLatency := FSaveFile.MaxLatency;

  FTester.MainTestCount := FSaveFile.MainTestCount;
  FTester.OverallTestCount := FSaveFile.OverallTestCount;
  FTester.Iterator := FSaveFile.Iterator;
end;

function TGSTestThread.SetDisk(DriveNumber: Integer): Boolean;
begin
  result := FTester.SetDisk(DriveNumber);
  if result then
    FSaveFile.Disknum := DriveNumber;
end;

function TGSTestThread.LBAto48Bit(NewLBA: UInt64): UInt64;
begin
  result := NewLBA and $FFFFFFFFFFFF; //Limit LBA to 48Bit
end;

procedure TGSTestThread.SetMaxLBA(NewLBA: UInt64);
begin
  FMaxLBA := LBAto48Bit(NewLBA);
end;

procedure TGSTestThread.SetOrigLBA(NewLBA: UInt64);
begin
  FOrigLBA := LBAto48Bit(NewLBA);
end;

procedure TGSTestThread.StartThread;
begin
  FStarted := true;
end;

function TGSTestThread.ReadMaxTBW: UInt64;
begin
  result := FMaxHostWrite shr ByteToTB;
end;

function TGSTestThread.ReadRetTest: UInt64;
begin
  result := FRetentionTest shr ByteToTB;
end;

procedure TGSTestThread.WriteMaxTBW(const Value: UInt64);
begin
  FMaxHostWrite := Value shl ByteToTB;
end;

procedure TGSTestThread.WriteRetTest(const Value: UInt64);
begin
  FRetentionTest := Value shl ByteToTB;
end;

procedure TGSTestThread.AssignSavePath(const Path: String);
begin
  FSavePath := Path;
end;

function TGSTestThread.AssignDLLPath(DLLPath: String): Boolean;
begin
  if FileExists(DLLPath) then

  FDLLHandle := LoadLibrary(PChar(DLLPath));

  @makeJEDECList := GetProcAddress(FDLLHandle, 'makeJEDECList');
  @makeJEDECClass := GetProcAddress(FDLLHandle, 'makeJedecClass');
  @deleteJEDECClass := GetProcAddress(FDLLHandle, 'deleteJedecClass');

  if (@makeJEDECList = nil) or (@makeJEDECClass = nil)
  or (@deleteJEDECClass = nil) then
  begin
    CloseHandle(FDLLHandle);
    FDLLHandle := 0;
    exit(false);
  end;

  result := true;
  FLoadedState := FLoadedState or ((1 and Integer(result)) shl 1);
  FFullyLoaded := (FLoadedState = (1 or (1 shl 1)));
end;

function TGSTestThread.AssignBufferSetting(BufSize: Integer;
  RandomnessInInteger: Integer): Boolean;
begin
  FRandomBuffer.CreateBuffer(BufSize);
  FRandomBuffer.FillBuffer(RandomnessInInteger);

  result := FTester.AssignBuffer(@FRandomBuffer);
  if result then
    FBufSize := BufSize;

  FLoadedState := FLoadedState or (1 and Integer(result));
  FFullyLoaded := (FLoadedState = (1 or (1 shl 1)));
end;

function TGSTestThread.AssignBufferSetting(BufSize: Integer;
  RandomnessInString: String): Boolean;
begin
  result := AssignBufferSetting(BufSize, StrToInt(RandomnessInString));
end;
end.
