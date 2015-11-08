unit Tester.Thread;

interface

uses
  Classes, SysUtils, ComCtrls, Math, Windows, DateUtils, Dialogs,
  Tester.Iterator, Trace.List, RandomBuffer, SaveFile,
  SaveFile.TesterThread, Parser, Trace.Node, Trace.PartialList,
  ErrorList, Tester.ToView, Log.Templates, LanguageStrings,
  Setting.Test, MeasureUnit.Datasize, Device.SMART.List,
  Device.SMART.Diff;

const
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
    FSaveFile: TSaveFileForTesterThread;
    FSavePath: String;
    FErrorList: TErrorList;
    FTracePath: String;
    FFullyLoaded: Boolean;
    FStarted: Boolean;
    FBufSize: Integer;
    FLastSync: Cardinal;
    FLastRetention: Integer;
    FSecCounter: Integer;
    FLastSyncCount: Integer;
    FTracePartialList: TTracePartialList;
    FMaxLBA: UInt64;
    FOrigLBA: UInt64;
    FRetentionTest: UInt64;
    FMaxFFR: Integer;
    FExitCode: Byte;
    FTesterToView: TTesterToView;
    FNeedRetention: Boolean;
    FLastSMARTList: TSMARTValueList;
    function LBAto48Bit(const NewLBA: UInt64): UInt64;
    function GetMaxLatency: Double;
    function GetAvgLatency: Double;
    function IsRetentionTestBoundReached: Boolean;
    function GetSuitableMemorySize: Integer;
    procedure RefreshSMART;
    procedure ReceiveErrorList;
  public
    property ExitCode: Byte read FExitCode;
    constructor Create(const SavePath: String);
    destructor Destroy; override;
    procedure Execute; override;
    procedure ApplyState;
    procedure ApplyWriteError(const TBWStr, DayStr: String);
    procedure AddToAlert(const Value: String);
    procedure ApplyEnd;
    procedure StartThread;
    function AssignBufferSetting(const BufSize: Integer;
      const RandomnessInInteger: Integer): Boolean; overload;
    function SetDisk(const DriveNumber: Integer): Boolean;
    procedure AddToHostWrite(const HostWrite: Int64);
    procedure Save(const SaveFilePath: String);
    procedure Load(const SaveFilePath: String);
    procedure SetMaxLBA(const NewLBA: UInt64);
    procedure SetTraceMaxLBA(const NewLBA: UInt64);
    procedure SetTestSetting(const TestSetting: TTestSetting);
    procedure SetNeedRetention;
    procedure AddTestClosedNormallyToLog;
  end;

implementation

uses Form.Main;

constructor TTesterThread.Create(const SavePath: String);
var
  RandomSeed: Int64;
begin
  inherited Create;

  FSavePath := SavePath;
  FSaveFile := TSaveFileForTesterThread.Create(TSaveFile.Create(
    FSavePath + 'settings.ini'));

  if QueryPerformanceCounter(RandomSeed) = false then
    RandomSeed := GetTickCount;

  FErrorList := TErrorList.Create(FSavePath + 'alert.txt');
  FTester := TTesterIterator.Create(FSavePath);
  FRandomBuffer := TRandomBuffer.Create(RandomSeed);
  FTesterToView := TTesterToView.Create;
  FLastSMARTList := TSMARTValueList.Create;
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

  Save(FSavePath);

  FreeAndNil(FTesterToView);
  FreeAndNil(FTester);
  FreeAndNil(FRandomBuffer);
  FreeAndNil(FSaveFile);
  FreeAndNil(FErrorList);
  FreeAndNil(FLastSMARTList);
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
      IntToStr(FTester.GetIterator)));
  end;

  TBWStr := GetByte2TBWStr(FTester.GetHostWrite);
  DayStr := GetDayStr((FTester.GetHostWrite shr 30) / 10); //Unit: 10GB/d

  FTesterToView.ApplyLatency(GetAvgLatency, GetMaxLatency);
  FTesterToView.ApplyProgress(TBWStr, DayStr,
    FTester.GetHostWrite shr 40, FRetentionTest);
  ApplyWriteError(TBWStr, DayStr);
  FTesterToView.ApplyFFR(FTester.GetFFR, FMaxFFR);
end;

procedure TTesterThread.AddTestClosedNormallyToLog;
begin
  AddToAlert(GetLogLine(MainTestEndNormally[CurrLang],
    MainWrittenAmount[CurrLang] + ' - ' +
    GetByte2TBWStr(FTester.GetHostWrite) + ' / ' +
    MainAverageLatency[CurrLang] + ' - ' +
    Format('%.2f%s', [GetAvgLatency, 'ms']) + ' / ' +
    MainMaxLatency[CurrLang] + ' - ' +
    Format('%.2f%s', [GetMaxLatency, 'ms'])));
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

function TTesterThread.IsRetentionTestBoundReached: Boolean;
begin
  result :=
    ((FTester.GetHostWrite mod (FRetentionTest shl ByteToTB)) = 0) and
    (FTester.GetHostWrite > 0) and
    (FTester.GetHostWrite > FLastRetention);
end;

function TTesterThread.GetSuitableMemorySize: Integer;
const
  DefaultMemoryUseInMiB = 512;
var
  RAMStatus: TMemoryStatus;
  AvailMemoryInMiB: Integer;
begin
  RAMStatus.dwLength := SizeOf(RAMStatus);
  GlobalMemoryStatus(RAMStatus);
  result := DefaultMemoryUseInMiB;
  AvailMemoryInMiB := RAMStatus.dwAvailPhys shr 20;
  if result > AvailMemoryInMiB then
    result := AvailMemoryInMiB;
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
  FTracePartialList := TTracePartialList.Create(FTracePath, FMaxLBA / FOrigLBA,
    GetSuitableMemorySize);
  FTester.AssignList(FTracePartialList);
  FTesterToView.ApplyStart;
  RefreshSMART;
  ApplyState;
  while not Terminated do
  begin
    if (IsRetentionTestBoundReached) or (FTester.GetFFR > FMaxFFR) then
    begin
      if IsRetentionTestBoundReached then
         FExitCode := EXIT_RETENTION
      else if FTester.GetFFR > FMaxFFR then
         FExitCode := EXIT_ERROR;
      Queue(ApplyEnd);
      break;
    end;
    if not FTester.ProcessNextOperation then
      ReceiveErrorList;
    CurrTime := GetTickCount;
    if ((CurrTime - FLastSync) > 1000) and (not Terminated) then
    begin
      try
        Queue(ApplyState);
      except
        ShowMessage('ApplyState ' + TesterThreadError[CurrLang]);
      end;
      FSecCounter := FSecCounter + 1;
      if FSecCounter >= 60 then // 1 minute
      begin
        RefreshSMART;
        Save(FSavePath);
        FSecCounter := 0;
      end;
      FLastSync := CurrTime;
    end;
  end;
end;

procedure TTesterThread.ReceiveErrorList;
begin
  FErrorList.AddRange(FTester.GetErrorList.ToArray);
  FTester.GetErrorList.Clear;
end;

procedure TTesterThread.RefreshSMART;
var
  CurrentSMARTValueList: TSMARTValueList;
  DiffList: TSMARTValueList;
  DifferentItem: TSMARTValueEntry;
begin
  CurrentSMARTValueList := FTester.GetSMARTList;
  DiffList := TSMARTDiff.GetInstance.CompareSMART(FLastSMARTList,
    CurrentSMARTValueList);
  for DifferentItem in DiffList do
    Synchronize(procedure
    begin
      AddToAlert(GetLogLine(TesterThreadNewValue[CurrLang],
        TSMARTValueEntry.ToString(
          CurrentSMARTValueList.GetEntryByID(DifferentItem.ID))));
    end);
  DiffList.Free;
  FLastSMARTList.Free;
  FLastSMARTList := CurrentSMARTValueList;
end;

function TTesterThread.GetAvgLatency: Double;
begin
  result := FTester.GetAverageLatency / 1000;
end;

function TTesterThread.GetMaxLatency: Double;
begin
  result := FTester.GetMaximumLatency / 1000;
end;

procedure TTesterThread.Save(const SaveFilePath: String);
  function DenaryKBToGB: TDatasizeUnitChangeSetting;
  begin
    result.FNumeralSystem := TNumeralSystem.Denary;
    result.FFromUnit := KiloUnit;
    result.FToUnit := GigaUnit;
  end;
begin
  FSaveFile.SetTBWToRetention(FRetentionTest);
  FSaveFile.SetMaxFFR(FMaxFFR);
  FSaveFile.SetNeedRetention(FNeedRetention);
  FSaveFile.SetTracePath(FTracePath);
  FSaveFile.SetTraceOriginalLBA(IntToStr(
    round(ChangeDatasizeUnit(FOrigLBA shr 1, DenaryKBToGB))));
  if FNeedRetention then
    FSaveFile.SetLastRetention(FTester.GetHostWrite);
  FTester.Save;
  FErrorList.Save;
end;

procedure TTesterThread.Load(const SaveFilePath: String);
begin
  FRetentionTest := FSaveFile.GetTBWToRetention;
  FMaxFFR := FSaveFile.GetMaxFFR;
  FNeedRetention := FSaveFile.GetNeedRetention;
  FLastRetention := FSaveFile.GetLastRetention;
  FTester.Load;
  Synchronize(procedure
  begin
    if FNeedRetention then
      fMain.VerifyRetention;
  end);
end;

function TTesterThread.SetDisk(const DriveNumber: Integer): Boolean;
begin
  result := FTester.SetDisk(DriveNumber);
  if result then
    FSaveFile.SetDiskNumber(DriveNumber);
end;

procedure TTesterThread.AddToHostWrite(const HostWrite: Int64);
begin
  FTester.AddToHostWrite(HostWrite);
end;

function TTesterThread.LBAto48Bit(const NewLBA: UInt64): UInt64;
begin
  result := NewLBA and $FFFFFFFFFFFF; //Limit LBA to 48Bit
end;

procedure TTesterThread.SetMaxLBA(const NewLBA: UInt64);
begin
  FMaxLBA := LBAto48Bit(NewLBA);
end;

procedure TTesterThread.SetNeedRetention;
begin
  FNeedRetention := true;
end;

procedure TTesterThread.SetTestSetting(const TestSetting: TTestSetting);
begin
  SetDisk(TestSetting.DiskNumber);
  SetMaxLBA(TestSetting.CapacityInLBA);
  FTracePath := TestSetting.TracePath;
  SetTraceMaxLBA(TestSetting.TraceOriginalLBA);
  FSavePath := TestSetting.LogSavePath;
  if FRetentionTest = 0 then
  begin
    FMaxFFR := TestSetting.MaxFFR;
    FRetentionTest := TestSetting.TBWToRetention;
  end;
end;

procedure TTesterThread.SetTraceMaxLBA(const NewLBA: UInt64);
begin
  FOrigLBA := LBAto48Bit(NewLBA);
end;

procedure TTesterThread.StartThread;
begin
  FStarted := true;
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

end.
