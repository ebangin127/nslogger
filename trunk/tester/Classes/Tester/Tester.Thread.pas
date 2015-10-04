unit Tester.Thread;

interface

uses Classes, SysUtils, ComCtrls, Math, Windows, DateUtils, Dialogs,
     Tester.Iterator, Trace.List, uRandomBuffer, uSaveFile, Parser,
     Trace.Node, Trace.MultiList, uErrorList, Tester.ToView,
     Log.Templates, uLanguageSettings;

const
  ByteToTB = 40;
  EXIT_NORMAL = 0;
  EXIT_RETENTION = 1;
  EXIT_HOSTWRITE = 2;
  EXIT_ERROR = 3;
  EXIT_EXT_RETENTION = 4;

type
  TTesterThread = class(TThread)
  private
    FTester: TTesterIterator;
    FRandomBuffer: TRandomBuffer;
    FSaveFile: TSaveFile;
    FErrorList: TErrorList;

    FSavePath: String;
    FTracePath: String;
    FAlertPath: String;

    FFullyLoaded: Boolean;
    FStarted: Boolean;

    FBufSize: Integer;

    FLastSync: Cardinal;
    FSecCounter: Integer;
    FLastSyncCount: Integer;

    TraceMultiList: TTraceMultiList;

    FMaxLBA: UInt64;
    FOrigLBA: UInt64;
    FAlign: Integer;

    FMaxHostWrite: UInt64;
    FRetentionTest: UInt64;
    FMaxFFR: Integer;
    FExitCode: Byte;

    FMainNeedReten: Boolean;
    FMainDriveModel, FMainDriveSerial: String;
    FTesterToView: TTesterToView;

    function LBAto48Bit(const NewLBA: UInt64): UInt64;

    procedure SetMaxLBA(const NewLBA: UInt64);
    procedure SetOrigLBA(const NewLBA: UInt64);
    function ReadMaxTBW: UInt64;
    function ReadRetTest: UInt64;
    procedure WriteMaxTBW(const Value: UInt64);
    procedure WriteRetTest(const Value: UInt64);
    function GetFFR: Double;
    function GetHostWrite: Int64;
    function GetMaxLatency: Double;
    function GetAvgLatency: Double;
  public
    property ExitCode: Byte read FExitCode;

    property MaxLBA: UInt64 read FMaxLBA write SetMaxLBA;
    property OrigLBA: UInt64 read FOrigLBA write SetOrigLBA;
    property Align: Integer read FAlign write FAlign;
    property MaxFFR: Integer read FMaxFFR write FMaxFFR;

    property MaxHostWrite: UInt64 read ReadMaxTBW write WriteMaxTBW;
    property RetentionTest: UInt64 read ReadRetTest write WriteRetTest;
    property NeedVerify: Boolean read FMainNeedReten write FMainNeedReten;

    property HostWrite: Int64 read GetHostWrite;
    property MaxLatency: Double read GetMaxLatency;
    property AvgLatency: Double read GetAvgLatency;

    property FFR: Double read GetFFR;
    property Path: String read FSavePath write FSavePath;

    constructor Create(TracePath: String);

    destructor Destroy; override;

    procedure ApplyState;
    procedure ApplyWriteError(const TBWStr, DayStr: String);
    procedure AddToAlert(const Value: String);

    procedure ApplyEnd;

    procedure Execute; override;

    procedure StartThread;

    function AssignBufferSetting(const BufSize: Integer;
              const RandomnessInInteger: Integer): Boolean; overload;
    function AssignBufferSetting(const BufSize: Integer;
              const RandomnessInString: String): Boolean; overload;
    procedure AssignAlertPath(const Path: String);
    function SetDisk(const DriveNumber: Integer): Boolean;
    procedure SetHostWrite(const HostWrite: Int64);

    function Save(SaveFilePath: String): Boolean;
    function Load(SaveFilePath: String): Boolean;

    procedure GetMainInfo;
  end;

implementation

uses Form.Main;

constructor TTesterThread.Create(TracePath: String);
var
  RandomSeed: Int64;
begin
  inherited Create;

  FSaveFile := TSaveFile.Create;

  if QueryPerformanceCounter(RandomSeed) = false then
    RandomSeed := GetTickCount;
  FSaveFile.RandomSeed := RandomSeed;

  FErrorList := TErrorList.Create;
  FTester := TTesterIterator.Create(FErrorList);
  FRandomBuffer := TRandomBuffer.Create(RandomSeed);
  FTesterToView := TTesterToView.Create;

  if QueryPerformanceCounter(RandomSeed) = false then
    RandomSeed := GetTickCount;

  FTracePath := TracePath;
end;

destructor TTesterThread.Destroy;
begin
  Synchronize(procedure
  begin
    if fMain <> nil then
    begin
      if fMain.RepeatRetention = false then
        ApplyState
      else
        FExitCode := EXIT_EXT_RETENTION;
    end;
  end);

  Queue(GetMainInfo);
  Save(FSavePath);

  FreeAndNil(FTesterToView);
  FreeAndNil(FTester);
  FreeAndNil(FRandomBuffer);
  FreeAndNil(FSaveFile);
  FreeAndNil(FErrorList);
end;

procedure TTesterThread.ApplyEnd;
begin
  case FExitCode of
    EXIT_HOSTWRITE:
    begin
      FTesterToView.AddToAlert(GetLogLine(TesterThreadExitHostWrite[CurrLang]));
    end;
    EXIT_RETENTION:
    begin
      FTesterToView.AddToAlert(GetLogLine(
        TesterThreadExitPeriodicRetention[CurrLang]));
    end;
    EXIT_EXT_RETENTION:
    begin
      FTesterToView.AddToAlert(GetLogLine(
        TesterThreadExitRetentionExtended[CurrLang]));
    end;
    EXIT_ERROR:
    begin
      FTesterToView.AddToAlert(GetLogLine(TesterThreadExitFFR[CurrLang]));
    end;
    EXIT_NORMAL:
    begin
      FTesterToView.AddToAlert(GetLogLine(TesterThreadExitNormal[CurrLang]));
    end;
  end;
end;

procedure TTesterThread.ApplyState;
var
  TBWStr: String;
  DayStr: String;
begin
  if FLastSyncCount <> FTester.GetOverallTestCount + 1 then
  begin
    FLastSyncCount := FTester.GetOverallTestCount + 1;
    FTesterToView.AddToAlert(GetLogLine(
      TesterThreadTestNumPre[CurrLang] + IntToStr(FLastSyncCount) + ' ' +
      TesterThreadTestStarted[CurrLang],
      TesterThreadIteratorPosition[CurrLang] + ' - ' +
      IntToStr(FTester.Iterator)));
  end;

  TBWStr := GetByte2TBWStr(FTester.GetHostWrite);
  DayStr := GetDayStr((FTester.GetHostWrite shr 30) / 10); //Unit: 10GB/d

  FTesterToView.ApplyLatency(GetAvgLatency, GetMaxLatency);
  FTesterToView.ApplyProgress(TBWStr, DayStr, GetHostWrite shr 30, ReadMaxTBW);
  ApplyWriteError(TBWStr, DayStr);
  FTesterToView.ApplyFFR(GetFFR, MaxFFR);
end;

procedure TTesterThread.AddToAlert(const Value: String);
begin
  FErrorList.AddLine(Value);
  FTesterToView.AddToAlert(Value);
end;

procedure TTesterThread.ApplyWriteError(const TBWStr, DayStr: String);
var
  ErrorName: String;
  ErrorContents: String;
  CurrNode: TTraceNode;
  UpdateStarted: Boolean;
  TrimmedDayStr: String;
begin
  UpdateStarted := false;

  TrimmedDayStr := Trim(DayStr);
  if FErrorList.Count > 0 then
  begin
    FTesterToView.FreezeAlertListBox;
    AddToAlert('---' + TBWStr + '(' + TrimmedDayStr + ') ' +
      TesterThreadErrorAt[CurrLang] + ' ---');
    UpdateStarted := true;
  end;

  for CurrNode in FErrorList do
  begin
    case CurrNode.GetIOType of
    TIOType.ioRead:
      ErrorName := TesterThreadRead[CurrLang];
    TIOType.ioWrite:
      ErrorName := TesterThreadWrite[CurrLang];
    TIOType.ioTrim:
      ErrorName := TesterThreadTrim[CurrLang];
    TIOType.ioFlush:
      ErrorName := TesterThreadFlush[CurrLang];
    end;
    ErrorName := ErrorName + ' ' + TesterThreadError[CurrLang];
    ErrorContents := '';
    case CurrNode.GetIOType of
    TIOType.ioRead..TIOType.ioTrim:
    begin
      ErrorContents := TesterThreadPosition[CurrLang] + ' ' +
        IntToStr(CurrNode.GetLBA) + ', ';
      ErrorContents := ErrorContents + TesterThreadLength[CurrLang] + ' ' +
        IntToStr(CurrNode.GetLength);
    end;
    end;

    AddToAlert(GetLogLine(ErrorName, ErrorContents));
  end;

  if UpdateStarted then
  begin
    AddToAlert('---' + TBWStr + '(' + TrimmedDayStr + ') ' +
      TesterThreadErrorEnd[CurrLang] + '---');
    FTesterToView.UnfreezeAlertListBox;
    FErrorList.Clear;
  end;
end;

procedure TTesterThread.Execute;
var
  CurrTime: Cardinal;
begin
  while not FStarted do
    Sleep(100);
  if FFullyLoaded = false then
    exit;
  FLastSync := 0;
  FSecCounter := 0;
  TraceMultiList := TTraceMultiList.Create;
  ImportTrace(TraceMultiList, PChar(FTracePath), MaxLBA / OrigLBA);
  FTester.AssignList(TraceMultiList);
  FTesterToView.ApplyStart;
  ApplyState;
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
      Queue(ApplyEnd);
      break;
    end;
    FTester.ProcessNextOperation;
    CurrTime := GetTickCount;
    if ((CurrTime - FLastSync) > 1000) and (not Terminated) then
    begin
      try
        Queue(ApplyState);
      except
        ShowMessage('ApplyState ' + TesterThreadError[CurrLang]);
      end;
      FSecCounter := FSecCounter + 1;
      if FSecCounter >= 300 then // 5 minutes
      begin
        Save(FSavePath);
        FSecCounter := 0;
      end;
      FLastSync := CurrTime;
    end;
  end;
end;

function TTesterThread.GetAvgLatency: Double;
begin
  result := FTester.GetAverageLatency / 1000;
end;

function TTesterThread.GetMaxLatency: Double;
begin
  result := FTester.GetMaximumLatency / 1000;
end;

function TTesterThread.GetFFR: Double;
begin
  if FTester.GetLength > 0 then
    result := (FTester.ErrorCount / FTester.GetLength) * 100
  else
    result := 0;
end;

function TTesterThread.GetHostWrite: Int64;
begin
  result := FTester.HostWrite;
end;

procedure TTesterThread.GetMainInfo;
begin
  FMainNeedReten := fMain.NeedRetention;
  FMainDriveModel := fMain.TestSetting.Model;
  FMainDriveSerial := fMain.TestSetting.Serial;
end;

function TTesterThread.Save(SaveFilePath: String): Boolean;
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

  FErrorList.Save;
  result := FSaveFile.SaveToFile(SaveFilePath + 'settings.ini');
end;

function TTesterThread.Load(SaveFilePath: String): Boolean;
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

function TTesterThread.SetDisk(const DriveNumber: Integer): Boolean;
begin
  result := FTester.SetDisk(DriveNumber);
  if result then
    FSaveFile.Disknum := DriveNumber;
end;

procedure TTesterThread.SetHostWrite(const HostWrite: Int64);
begin
  FTester.HostWrite := HostWrite;
end;

function TTesterThread.LBAto48Bit(const NewLBA: UInt64): UInt64;
begin
  result := NewLBA and $FFFFFFFFFFFF; //Limit LBA to 48Bit
end;

procedure TTesterThread.SetMaxLBA(const NewLBA: UInt64);
begin
  FMaxLBA := LBAto48Bit(NewLBA);
end;

procedure TTesterThread.SetOrigLBA(const NewLBA: UInt64);
begin
  FOrigLBA := LBAto48Bit(NewLBA);
end;

procedure TTesterThread.StartThread;
begin
  FStarted := true;
end;

function TTesterThread.ReadMaxTBW: UInt64;
begin
  result := FMaxHostWrite shr ByteToTB;
end;

function TTesterThread.ReadRetTest: UInt64;
begin
  result := FRetentionTest shr ByteToTB;
end;

procedure TTesterThread.WriteMaxTBW(const Value: UInt64);
begin
  FMaxHostWrite := Value shl ByteToTB;
end;

procedure TTesterThread.WriteRetTest(const Value: UInt64);
begin
  FRetentionTest := Value shl ByteToTB;
end;

procedure TTesterThread.AssignAlertPath(const Path: String);
begin
  FAlertPath := Path;
  FErrorList.AssignSavePath(Path);
end;

function TTesterThread.AssignBufferSetting(const BufSize: Integer;
  const RandomnessInInteger: Integer): Boolean;
begin
  FRandomBuffer.CreateBuffer(BufSize);
  FRandomBuffer.FillBuffer(RandomnessInInteger);

  result := FTester.AssignBuffer(@FRandomBuffer);
  if result then
    FBufSize := BufSize;

  FFullyLoaded := true;
end;

function TTesterThread.AssignBufferSetting(const BufSize: Integer;
  const RandomnessInString: String): Boolean;
begin
  result := AssignBufferSetting(BufSize, StrToInt(RandomnessInString));
end;

end.
