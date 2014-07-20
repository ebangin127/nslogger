unit uGSTestThread;

interface

uses Classes, SysUtils, ComCtrls, Math, Windows, DateUtils, Dialogs,
     uGSTester, uGSList, uRandomBuffer, uSaveFile, uDiskFunctions, uParser;

type
  TmakeJEDECList  = function (TraceList: Pointer; path: PChar): PTGListHeader;
                    cdecl;
  TmakeJEDECListAndFix
                  = function (TraceList: Pointer; path: PChar;
                    MultiConst: Double): PTGListHeader; cdecl;
  TmakeJEDECClass = function: Pointer; cdecl;
  TdeleteJEDECClass = procedure(delClass: Pointer); cdecl;

const
  ByteToTB = 40;
  EXIT_NORMAL = 0;
  EXIT_RETENTION = 1;
  EXIT_HOSTWRITE = 2;
  EXIT_ERROR = 3;
  ABNORMAL_VALUE = 500;
  ERROR_VALUE = 10000;

type
  TGSTestThread = class(TThread)
  private
    FTester: TGSTester;
    FRandomBuffer: TRandomBuffer;
    FSaveFile: TSaveFile;

    FSavePath: String;
    FTracePath: String;
    FAlertPath: String;

    FFullyLoaded: Boolean;
    FStarted: Boolean;

    FBufSize: Integer;

    FLastSync: Cardinal;
    FSecCounter: Integer;
    FLastSyncCount: Integer;

    ClassPTR: TGSList;

    FMaxLBA: UInt64;
    FOrigLBA: UInt64;
    FAlign: Integer;

    FMaxHostWrite: UInt64;
    FRetentionTest: UInt64;
    FMaxFFR: Integer;
    FExitCode: Byte;

    FMainNeedReten: Boolean;
    FMainDriveModel, FMainDriveSerial: String;

    function LBAto48Bit(NewLBA: UInt64): UInt64;

    procedure SetMaxLBA(NewLBA: UInt64);
    procedure SetOrigLBA(NewLBA: UInt64);
    function ReadMaxTBW: UInt64;
    function ReadRetTest: UInt64;
    procedure WriteMaxTBW(const Value: UInt64);
    procedure WriteRetTest(const Value: UInt64);
    function GetFFR: Double;
    procedure AddToAlert(const Value: String);
  public
    property ExitCode: Byte read FExitCode;

    property MaxLBA: UInt64 read FMaxLBA write SetMaxLBA;
    property OrigLBA: UInt64 read FOrigLBA write SetOrigLBA;
    property Align: Integer read FAlign write FAlign;
    property MaxFFR: Integer read FMaxFFR write FMaxFFR;

    property MaxHostWrite: UInt64 read ReadMaxTBW write WriteMaxTBW;
    property RetentionTest: UInt64 read ReadRetTest write WriteRetTest;
    property NeedVerify: Boolean read FMainNeedReten write FMainNeedReten;

    property FFR: Double read GetFFR;

    constructor Create(TracePath: String; Capacity: UINT64); overload;
    constructor Create(TracePath: String; RandomSeed: Int64;
                       Capacity: UINT64); overload;
    constructor Create(TracePath: String; CreateSuspended: Boolean;
                       Capacity: UINT64); overload;
    constructor Create(TracePath: String; CreateSuspended: Boolean;
                       Capacity: UINT64; RandomSeed: Int64); overload;

    destructor Destroy; override;

    procedure ApplyState;
    procedure ApplyState_Progress(TBWStr, DayStr: String);
    procedure ApplyState_WriteError(TBWStr, DayStr: String);
    procedure ApplyState_Latency;
    procedure ApplyState_FFR;


    procedure ApplyStart;
    procedure ApplyEnd;

    procedure Execute; override;

    procedure StartThread;

    procedure AssignSavePath(const Path: String);
    function AssignBufferSetting(BufSize: Integer; RandomnessInInteger: Integer):
              Boolean; overload;
    function AssignBufferSetting(BufSize: Integer; RandomnessInString: String):
              Boolean; overload;
    procedure AssignAlertPath(const Path: String);
    function SetDisk(DriveNumber: Integer): Boolean;

    function Save(SaveFilePath: String): Boolean;
    procedure SaveTodaySpeed(SaveFilePath: String);
    procedure SaveTBW(SaveFilePath: String);
    function Load(SaveFilePath: String): Boolean;

    procedure GetMainInfo;
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
  SaveTodaySpeed(FSavePath);
  SaveTBW(FSavePath);
  Synchronize(GetMainInfo);
  Save(FSavePath);

  FreeAndNil(FTester);
  FreeAndNil(FRandomBuffer);
  FreeAndNil(FSaveFile);
end;


procedure TGSTestThread.ApplyEnd;
begin
  with fMain do
  begin
    case FExitCode of
      EXIT_HOSTWRITE:
      begin
        lAlert.Items.Add(GetLogLine('쓰기 종료'));
      end;
      EXIT_RETENTION:
      begin
        lAlert.Items.Add(GetLogLine('주기적 리텐션 테스트'));
      end;
      EXIT_ERROR:
      begin
        lAlert.Items.Add(GetLogLine('기능 실패율 비정상'));
      end;
      EXIT_NORMAL:
      begin
        lAlert.Items.Add(GetLogLine('사용자 종료'));
      end;
    end;
  end;
end;

procedure TGSTestThread.ApplyStart;
begin
  fMain.iSave.Enabled := true;
  fMain.iForceReten.Enabled := true;

  fMain.lSave.Enabled := true;
  fMain.lForceReten.Enabled := true;
end;

procedure TGSTestThread.ApplyState;
var
  TBWStr: String;
  DayStr: String;
begin
  with fMain do
  begin
    if FLastSyncCount <> FTester.GetOverallTestCount + 1 then
    begin
      FLastSyncCount := FTester.GetOverallTestCount + 1;
      AddToAlert(IntToStr(FLastSyncCount) + '회 시작: '
                 + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
    end;

    TBWStr := GetTBWStr(FTester.GetHostWrite shr 20); //Unit: MB
    DayStr := GetDayStr((FTester.GetHostWrite shr 30) / 10); //Unit: 10GB/d

    ApplyState_Latency;
    ApplyState_Progress(TBWStr, DayStr);
    ApplyState_WriteError(TBWStr, DayStr);
    ApplyState_FFR;
  end;
end;

procedure TGSTestThread.ApplyState_FFR;
var
  CurrFFR: Double;
begin
  with fMain do
  begin
    CurrFFR := FFR;
    sFFR.Caption := FormatFloat('0.####', CurrFFR) + '%';
    pFFR.Position := round((CurrFFR / FMaxFFR) * 100);
    if pFFR.Position > 10 then
      pFFR.State := TProgressBarState.pbsPaused
    else if pFFR.Position > 50 then 
      pFFR.State := TProgressBarState.pbsError;
  end;
end;

procedure TGSTestThread.ApplyState_Latency;
var
  AvgLatency, MaxLatency: Double;
  pAvgLatencyPos, pMaxLatencyPos: Integer;
begin
  AvgLatency := FTester.GetAverageLatency / 1000;
  MaxLatency := FTester.GetMaximumLatency / 1000;

  with fMain do
  begin
    if AvgLatency < ABNORMAL_VALUE then
    begin
      sAvgLatency.Caption := '양호(';
      pAvgLatency.State := pbsNormal;
    end
    else if AvgLatency < ERROR_VALUE then
    begin
      sAvgLatency.Caption := '위험(';
      pAvgLatency.State := pbsPaused;
    end
    else if AvgLatency >= ERROR_VALUE then
    begin
      sAvgLatency.Caption := '불량(';
      pAvgLatency.State := pbsError;
    end;

    if MaxLatency < ABNORMAL_VALUE then
    begin
      sMaxLatency.Caption := '양호(';
      pMaxLatency.State := pbsNormal;
    end
    else if MaxLatency < ERROR_VALUE then
    begin
      sMaxLatency.Caption := '보통(';
      pMaxLatency.State := pbsPaused;
    end
    else if MaxLatency >= ERROR_VALUE then
    begin
      sMaxLatency.Caption := '위험(';
      pMaxLatency.State := pbsError;
    end;

    sAvgLatency.Caption := sAvgLatency.Caption +
                            Format('%.2f%s)', [AvgLatency, 'ms']);

    sMaxLatency.Caption := sMaxLatency.Caption +
                            Format('%.2f%s)', [MaxLatency, 'ms']);


    pAvgLatencyPos := 0;
    pMaxLatencyPos := 0;

    if AvgLatency > 0 then
      pAvgLatencyPos := round(Log10((AvgLatency / ERROR_VALUE) * 100)
                               / 2 * 100);
    if MaxLatency > 0 then
      pMaxLatencyPos := round(Log10((MaxLatency / ERROR_VALUE) * 100)
                               / 2 * 100);

    pAvgLatency.Position := Min(pAvgLatencyPos, 100);
    pMaxLatency.Position := Min(pMaxLatencyPos, 100);
  end;
end;

procedure TGSTestThread.ApplyState_Progress(TBWStr, DayStr: String);
var
  TestProgress: Integer;
begin
  with fMain do
  begin
    TestProgress := round(FTester.GetHostWrite / FMaxHostWrite * 100);
    pTestProgress.Position := TestProgress;
    sTestProgress.Caption := IntToStr(TestProgress) + '% (';

    sTestProgress.Caption := sTestProgress.Caption + TBWStr + ' / ';
    sTestProgress.Caption := sTestProgress.Caption + DayStr;

    DayStr := sTestProgress.Caption;
    DayStr[Length(DayStr)] := ')';
    sTestProgress.Caption := DayStr;
  end;
end;

procedure TGSTestThread.AddToAlert(const Value: String);
begin
  with fMain do
  begin
    lAlert.Items.Add(Value);
    FTester.ErrorBuf.AddLine(Value);
  end;
end;

procedure TGSTestThread.ApplyState_WriteError(TBWStr, DayStr: String);
var
  ErrorName: String;
  ErrorContents: String;
  CurrNode: PTGSNode;
  UpdateStarted: Boolean;
begin
  with fMain do
  begin
    UpdateStarted := false;

    DayStr := Trim(DayStr);
    if FTester.ErrorBuf.Count > 0 then
    begin
      lAlert.Items.BeginUpdate;
      AddToAlert('---' + TBWStr + '(' + DayStr + ') 지점의 오류 ---');
      UpdateStarted := true;
    end;

    for CurrNode in FTester.ErrorBuf do
    begin
      case CurrNode.FIOType of
      0{ioRead}:
        ErrorName := '읽기 오류';
      1{ioWrite}:
        ErrorName := '쓰기 오류';
      2{ioTrim}:
        ErrorName := '트림 오류';
      3{ioFlush}:
        ErrorName := '플러시 오류';
      end;

      ErrorContents := '';
      case CurrNode.FIOType of
      0..2:
      begin
        ErrorContents := '위치 '
                          + IntToStr(CurrNode.FLBA)
                          + ', ';
        ErrorContents := ErrorContents + '길이 '
                          + IntToStr(CurrNode.FLength);
      end;
      end;

      AddToAlert(GetLogLine(ErrorName, ErrorContents));
    end;

    if UpdateStarted then
    begin
      AddToAlert('---' + TBWStr + '(' + DayStr + ') 지점의 오류 끝---');
      lAlert.Items.EndUpdate;
      FTester.ErrorBuf.Clear;
    end;
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

  ClassPTR := TGSList.Create;

  FTester.AssignListHeader(makeJEDECListAndFix(ClassPTR, PChar(FTracePath),
                                               MaxLBA / OrigLBA));

  Synchronize(ApplyStart);
  Synchronize(ApplyState);

  while not Terminated do
  begin
    if (((FTester.GetHostWrite mod FRetentionTest) = 0) and
        ((FTester.GetHostWrite <> 0) and (FTester.StartLatency <> 0))) or
       (FTester.GetHostWrite = FMaxHostWrite) or
       (GetFFR > FMaxFFR) then
    begin
      if ((FTester.GetHostWrite mod FRetentionTest) = 0) and
         ((FTester.GetHostWrite <> 0) and (FTester.StartLatency <> 0)) then
         FExitCode := EXIT_RETENTION
      else if GetFFR > FMaxFFR then
         FExitCode := EXIT_ERROR
      else
         FExitCode := EXIT_HOSTWRITE;

      Synchronize(ApplyEnd);

      break;
    end;

    FTester.ProcessNextOperation;

    CurrTime := GetTickCount;
    if ((CurrTime - FLastSync) > 1000) and (not Terminated) then
    begin
      try
        Synchronize(ApplyState);
      except
        ShowMessage('ApplyState 에러');
      end;

      FSecCounter := FSecCounter + 1;
      if FSecCounter >= 300 then // 5 minutes
      begin
        SaveTodaySpeed(FSavePath);
        SaveTBW(FSavePath);
        Save(FSavePath);
        FSecCounter := 0;
      end;

      FLastSync := CurrTime;
    end;
  end;
end;

function TGSTestThread.GetFFR: Double;
begin
  result := (FTester.ErrorCount / FTester.GetLength) * 100;
end;

procedure TGSTestThread.GetMainInfo;
begin
  FMainNeedReten := fMain.NeedRetention;
  FMainDriveModel := fMain.DriveModel;
  FMainDriveSerial := fMain.DriveSerial;
end;

procedure TGSTestThread.SaveTodaySpeed(SaveFilePath: String);
var
  SaveFile: TStringList;
  LastTime, CurrTime: TDateTime;
  SavedToday: Boolean;
begin
  SaveFile := TStringList.Create;
  SavedToday := false;

  if FileExists(SaveFilePath + 'speedlog.txt') then
    SaveFile.LoadFromFile(SaveFilePath + 'speedlog.txt');

  //오늘 저장한 적이 있으면 처리
  CurrTime := Now;
  if SaveFile.Count > 0 then
  begin
    LastTime := UnixToDateTime(StrToInt64(SaveFile[0]));
    if (LastTime >= floor(CurrTime)) and (LastTime < ceil(CurrTime)) then
    begin
      SaveFile.Delete(SaveFile.Count - 1);
      SavedToday := true;
    end;
  end
  else
  begin
    SaveFile.Add('');
  end;

  //저장하기 위해서 내용 적기
  SaveFile[0] := IntToStr(DateTimeToUnix(CurrTime));
  SaveFile.Add(SaveFile[0] + ' ' +
               IntToStr(FTester.StartLatency) + ' ' +
               IntToStr(FTester.EndLatency) + ' ' +
               IntToStr(FTester.MaxLatency) + ' ' +
               IntToStr(FTester.AvgLatency));

  SaveFile.SaveToFile(SaveFilePath + 'speedlog.txt');

  if SavedToday = false then
  begin
    FTester.StartLatency := 0;
    FTester.EndLatency := 0;
    FTester.MaxLatency := 0;
    FTester.AvgLatency := 0;
  end;

  FreeAndNil(SaveFile);
end;

procedure TGSTestThread.SaveTBW(SaveFilePath: String);
var
  SaveFile: TStringList;
begin
  SaveFile := TStringList.Create;

  //저장하기 위해서 내용 적기
  Synchronize(GetMainInfo);
  SaveFile.Add(Trim(FMainDriveModel));
  SaveFile.Add(IntToStr(floor(FTester.GetHostWrite / 1024 / 1024 / 1024 / 10)));

  SaveFile.SaveToFile(SaveFilePath + 'tbwlog.txt');

  FreeAndNil(SaveFile);
end;

function TGSTestThread.Save(SaveFilePath: String): Boolean;
begin
  FSaveFile.NeedVerify := FMainNeedReten;
  FSaveFile.MaxTBW := FMaxHostWrite;
  FSaveFile.RetTBW := FRetentionTest;
  FSaveFile.MaxFFR := FMaxFFR;
  FSaveFile.TracePath := FTracePath;
  FSaveFile.Model := FMainDriveModel;
  FSaveFile.Serial := FMainDriveSerial;

  FSaveFile.CurrTBW := FTester.GetHostWrite;
  FSaveFile.StartLatency := FTester.StartLatency;
  FSaveFile.EndLatency := FTester.EndLatency;

  FSaveFile.SumLatency := FTester.SumLatency;
  FSaveFile.MaxLatency := FTester.GetMaximumLatency;
  FSaveFile.ErrorCount := FTester.ErrorCount;

  FSaveFile.OverallTestCount := FTester.OverallTestCount;
  FSaveFile.Iterator := FTester.Iterator;

  FTester.ErrorBuf.Save;
  result := FSaveFile.SaveToFile(SaveFilePath + 'settings.ini');
end;

function TGSTestThread.Load(SaveFilePath: String): Boolean;
begin
  result := FSaveFile.LoadFromFile(SaveFilePath);

  FMainNeedReten := FSaveFile.NeedVerify;
  FMaxHostWrite := FSaveFile.MaxTBW;
  FRetentionTest := FSaveFile.RetTBW;
  FTracePath := FSaveFile.TracePath;
  FMainDriveModel := FSaveFile.Model;
  FMainDriveSerial := FSaveFile.Serial;
  FMaxFFR := FSaveFile.MaxFFR;

  FTester.HostWrite := FSaveFile.CurrTBW;
  FTester.StartLatency := FSaveFile.StartLatency;
  FTester.EndLatency := FSaveFile.EndLatency;

  FTester.SumLatency := FSaveFile.SumLatency;
  FTester.MaxLatency := FSaveFile.MaxLatency;
  FTester.ErrorCount := FSaveFile.ErrorCount;

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

procedure TGSTestThread.AssignAlertPath(const Path: String);
begin
  FAlertPath := Path;
  FTester.ErrorBuf.AssignSavePath(Path);
end;

function TGSTestThread.AssignBufferSetting(BufSize: Integer;
  RandomnessInInteger: Integer): Boolean;
begin
  FRandomBuffer.CreateBuffer(BufSize);
  FRandomBuffer.FillBuffer(RandomnessInInteger);

  result := FTester.AssignBuffer(@FRandomBuffer);
  if result then
    FBufSize := BufSize;

  FFullyLoaded := true;
end;

function TGSTestThread.AssignBufferSetting(BufSize: Integer;
  RandomnessInString: String): Boolean;
begin
  result := AssignBufferSetting(BufSize, StrToInt(RandomnessInString));
end;
end.
