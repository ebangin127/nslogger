unit uGSTestThread;

interface

uses Classes, SysUtils, ComCtrls, Math, Windows,
     uGSTester, uGSList, uRandomBuffer, uSMARTManager;

type
  TGSTestThread = class(TThread)
  private
    FTester: TGSTester;
    FSMARTManager: TSMARTManager;
    FRandomBuffer: TRandomBuffer;

    FLoadedState: Integer; //Bit 0: BufferLoaded, Bit 1: ListLoaded
    FFullyLoaded: Boolean;
    FStarted: Boolean;

    FBufSize: Integer;

    FLastSync: Cardinal;
    FLastSyncCount: Integer;
  public
    constructor Create; overload;
    constructor Create(CreateSuspended: Boolean); overload;
    destructor Destroy; override;

    procedure ApplyState;
    procedure Execute; override;

    procedure StartThread;
    function AssignBufferSetting(BufSize: Integer; RandomnessInInteger: Integer): Boolean; overload;
    function AssignBufferSetting(BufSize: Integer; RandomnessInString: String): Boolean; overload;
    function AssignListHeader(NewHeader: PTGListHeader): Boolean;
    function SetDisk(DriveNumber: Integer): Boolean;
  end;

implementation

uses uMain;

constructor TGSTestThread.Create;
var
  RandomSeed: Int64;
begin
  inherited Create;

  if QueryPerformanceCounter(RandomSeed) = false then
    RandomSeed := GetTickCount;

  FTester := TGSTester.Create;
  FSMARTManager := TSMARTManager.Create;
  FRandomBuffer := TRandomBuffer.Create(RandomSeed);
end;

constructor TGSTestThread.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  Create;
end;

destructor TGSTestThread.Destroy;
begin
  FreeAndNil(FTester);
  FreeAndNil(FSMARTManager);
  FreeAndNil(FRandomBuffer);
end;

procedure TGSTestThread.ApplyState;
var
  MinLatency, MaxLatency: Double;
  TraceSize: Double;
  BufferSize: Double;
  HostWrite: Double;
  RamStats: TMemoryStatusEx;
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

    HostWrite := FTester.GetHostWrite / 1024 / 1024; //Unit: MB
    if HostWrite > (1024 * 1024 * 1024 / 4 * 3) then //Above 0.75PB
    begin
      sTestProgress.Caption := Format('%.2fPBW', [HostWrite / 1024 / 1024 / 1024]);
    end
    else if HostWrite > (1024 * 1024 / 4 * 3) then //Above 0.75TB
    begin
      sTestProgress.Caption := Format('%.2fTBW', [HostWrite / 1024 / 1024]);
    end
    else if HostWrite > (1024 / 4 * 3) then //Above 0.75GB
    begin
      sTestProgress.Caption := Format('%.2fGBW', [HostWrite / 1024]);
    end
    else
    begin
      sTestProgress.Caption := Format('%.2fMBW', [HostWrite]);
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

    TraceSize := FTester.GetLength * SizeOf(TGSNode) / 1024 / 1024; //Byte to MB
    BufferSize := FBufSize shr 10; //Byte to MB
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

  Synchronize(ApplyState);
  while not Terminated do
  begin
    if FTester.ProcessNextOperation then
    begin
      CurrTime := GetTickCount;
      if (CurrTime - FLastSync) > 1000 then
      begin
        Synchronize(ApplyState);
        FLastSync := CurrTime;
      end;
    end
    else
    begin
      break;
    end;
  end;
end;

function TGSTestThread.SetDisk(DriveNumber: Integer): Boolean;
begin
  result := FTester.SetDisk(DriveNumber);
end;

procedure TGSTestThread.StartThread;
begin
  FStarted := true;
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

function TGSTestThread.AssignListHeader(NewHeader: PTGListHeader): Boolean;
begin
  result := FTester.AssignListHeader(NewHeader);
  FLoadedState := FLoadedState or ((1 and Integer(result)) shl 1);
  FFullyLoaded := (FLoadedState = (1 or (1 shl 1)));
end;
end.
