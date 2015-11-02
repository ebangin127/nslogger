unit Tester.Iterator;

interface

uses
  Windows, SysUtils, Generics.Collections, MMSystem, Math, Dialogs,
  Classes,
  Trace.List, Trace.PartialList, RandomBuffer, ErrorList, Trace.Node,
  CommandSet, CommandSet.Factory, Device.PhysicalDrive, Tester.CommandIssuer,
  SaveFile, SaveFile.TesterIterator;

const
  MaxIOSize = 65536;
  TimeoutInMilliSec = 10000;
  MaxParallelIO = 4;

type
  TTestStage = (stReady, stLatencyTest, stCount);
  TTesterIterator = class
  private
    FTesterCommandIssuer: TTesterCommandIssuer;
    FMasterTrace: TTracePartialList;
    FStage: TTestStage;
    FIterator: Integer;
    FListIterator: ITraceListIterator;
    FFrequency: Double;
    FOverallTestCount: Integer;
    FStartLatency, FEndLatency: Int64; //Unit: us(10^-6)
    FSumLatency: UInt64;
    FAvgLatency, FMaxLatency: Int64; //Unit: us(10^-6)
    FHostWrite: Int64;
    FStartTime: Int64;
    FErrorList: TErrorList;
    FErrorCount: Integer;
    FCleared: Boolean;
    FMeasureCount: Integer;
    FSaveFile: TSaveFileForTesterIterator;
    procedure SetIterator(const Value: Integer);
    procedure ClearAvgLatency;
    function PrepareAndStartTest: Boolean;
    function ProcessLatencyTest: Boolean;
    function ResetLatencyTest: Boolean;
    procedure CalculateLatency;
    procedure SetNowAsStart;
  public
    constructor Create(const ErrorList: TErrorList; const SavePath: String);
    destructor Destroy; override;
    procedure Save;
    procedure Load;
    function GetCurrentStage: TTestStage;
    function GetStartLatency: Int64;
    function GetMaximumLatency: Int64;
    function GetAverageLatency: Int64;
    function GetOverallTestCount: Integer;
    function GetLength: Integer;
    function GetHostWrite: Int64;
    function GetIterator: Integer;
    function GetFFR: Double;
    function SetDisk(const DriveNumber: Integer): Boolean;
    function ProcessNextOperation: Boolean;
    function AssignBuffer(const RandBuf: PTRandomBuffer): Boolean;
    procedure AssignList(const NewList: TTracePartialList);
    procedure AddToHostWrite(const Value: Int64);
  end;

implementation

procedure TTesterIterator.ClearAvgLatency;
begin
  FSumLatency := 0;
end;

constructor TTesterIterator.Create(const ErrorList: TErrorList;
  const SavePath: String);
var
  Frequency: Int64;
begin
  FListIterator := FMasterTrace.GetIterator;

  QueryPerformanceFrequency(Frequency);
  FFrequency := Frequency / 1000000; //us(10^-6)

  FSumLatency := 0;
  FAvgLatency := 0;
  FMaxLatency := -1;
  FErrorCount := 0;

  FOverallTestCount := 0;

  FErrorList := TErrorList.Create(SavePath + 'error.txt');
  FTesterCommandIssuer := TTesterCommandIssuer.Create;
  FSaveFile := TSaveFileForTesterIterator.Create(
    TSaveFile.Create(SavePath + 'settings.ini'));
end;

destructor TTesterIterator.Destroy;
begin
  FreeAndNil(FMasterTrace);
  FreeAndNil(FErrorList);
  FreeAndNil(FTesterCommandIssuer);
  FreeAndNil(FSaveFile);
end;

function TTesterIterator.SetDisk(const DriveNumber: Integer): Boolean;
begin
  result := FTesterCommandIssuer.SetDisk(DriveNumber);
end;

procedure TTesterIterator.SetIterator(const Value: Integer);
begin
  FIterator := Value;
  FListIterator.SetIndex(Value);
end;

function TTesterIterator.GetCurrentStage: TTestStage;
begin
  result := FStage;
end;

function TTesterIterator.GetLength: Integer;
begin
  result := FMasterTrace.Count;
end;

function TTesterIterator.GetHostWrite: Int64;
begin
  result := FHostWrite;
end;

function TTesterIterator.GetIterator: Integer;
begin
  result := FIterator;
end;

function TTesterIterator.GetMaximumLatency: Int64;
begin
  result := FMaxLatency;
end;

function TTesterIterator.GetAverageLatency: Int64;
begin
  if FMeasureCount = 0 then
    exit(0);

  result := round(FSumLatency / FMeasureCount);
end;

function TTesterIterator.GetOverallTestCount: Integer;
begin
  result := FOverallTestCount;
end;

function TTesterIterator.GetStartLatency: Int64;
begin
  result := FStartLatency;
end;

function TTesterIterator.GetFFR: Double;
begin
  if GetLength > 0 then
    result := (FErrorCount / GetLength) * 100
  else
    result := 0;
end;

function TTesterIterator.PrepareAndStartTest: Boolean;
begin
  FListIterator.GoToFirst;
  FStage := stLatencyTest;
  FCleared := true;
  result := ProcessNextOperation;
end;

function TTesterIterator.ResetLatencyTest: Boolean;
begin
  FStage := stReady;
  FIterator := 0;

  if FStartLatency = 0 then
    FStartLatency := FMaxLatency;
  FEndLatency := FMaxLatency;

  Inc(FOverallTestCount, 1);
  result := ProcessNextOperation;
end;

procedure TTesterIterator.SetNowAsStart;
begin
  QueryPerformanceCounter(FStartTime);
end;

function TTesterIterator.ProcessLatencyTest: Boolean;
var
  NextOperation: TTraceNode;
  CommandResult: TCommandResult;
begin
  result := false;
  if FIterator = FMasterTrace.Count then
  begin
    ResetLatencyTest;
    exit;
  end;
  NextOperation := FListIterator.GetNextItem;
  Inc(FIterator);
  if FCleared then
    SetNowAsStart;
  case NextOperation.GetIOType of
    TIOType.ioRead:
      CommandResult := FTesterCommandIssuer.DiskRead(NextOperation);
    TIOType.ioWrite:
    begin
      CommandResult := FTesterCommandIssuer.DiskWrite(NextOperation);
      if CommandResult.CommandSuccess then
        Inc(FHostWrite, NextOperation.GetLength shl 9);
    end;
    TIOType.ioTrim:
      CommandResult := FTesterCommandIssuer.DiskTrim(NextOperation);
    TIOType.ioFlush:
      CommandResult := FTesterCommandIssuer.DiskFlush;
  end;
  result := CommandResult.CommandSuccess;
  FCleared := CommandResult.OverlapFinished;
  if FCleared then
    CalculateLatency;
  if result = false then
  begin
    FErrorList.Add(NextOperation);
    Inc(FErrorCount);
  end;
end;

procedure TTesterIterator.CalculateLatency;
var
  EndTime: Int64;
  OverallTime: Integer;
begin
  QueryPerformanceCounter(EndTime);
  OverallTime := round((EndTime - FStartTime) / FFrequency);
  Inc(FSumLatency, OverallTime);
  Inc(FMeasureCount);
  if (FMaxLatency < 0) or (FMaxLatency < OverallTime) then
    FMaxLatency := OverallTime;
end;

function TTesterIterator.ProcessNextOperation: Boolean;
begin
  result := false;
  if FIterator = 0 then
    ClearAvgLatency;
  case FStage of
    stReady:
      result := PrepareAndStartTest;
    stLatencyTest:
      result := ProcessLatencyTest;
  end;
end;

procedure TTesterIterator.AddToHostWrite(const Value: Int64);
begin
  FHostWrite := FHostWrite + Value;
end;

function TTesterIterator.AssignBuffer(const RandBuf: PTRandomBuffer): Boolean;
begin
  result := FTesterCommandIssuer.AssignBuffer(RandBuf);
end;

procedure TTesterIterator.AssignList(const NewList: TTracePartialList);
begin
  if FMasterTrace <> nil then
    FreeAndNil(FMasterTrace);
  FMasterTrace := NewList;
  FListIterator := FMasterTrace.GetIterator;
  FListIterator.SetIndex(FIterator);
end;

procedure TTesterIterator.Save;
begin
  FSaveFile.SetHostWrite(GetHostWrite);
  FSaveFile.SetStartLatency(FStartLatency);
  FSaveFile.SetEndLatency(FEndLatency);
  FSaveFile.SetSumLatency(FSumLatency);
  FSaveFile.SetMaxLatency(FMaxLatency);
  FSaveFile.SetErrorCount(FErrorCount);
  FSaveFile.SetOverallTestCount(FOverallTestCount);
  FSaveFile.SetIterator(FIterator);
  FSaveFile.SetMeasureCount(FMeasureCount);
end;

procedure TTesterIterator.Load;
begin
  FHostWrite := FSaveFile.GetHostWrite;
  FStartLatency := FSaveFile.GetStartLatency;
  FEndLatency := FSaveFile.GetEndLatency;
  FSumLatency := FSaveFile.GetSumLatency;
  FMaxLatency := FSaveFile.GetMaxLatency;
  FErrorCount := FSaveFile.GetErrorCount;
  FOverallTestCount := FSaveFile.GetOverallTestCount;
  FMeasureCount := FSaveFile.GetMeasureCount;
  SetIterator(FSaveFile.GetIterator);
end;

end.
