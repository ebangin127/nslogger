unit Tester.Iterator;

interface

uses
  Windows, SysUtils, Generics.Collections, MMSystem, Math, Dialogs,
  Classes,
  Trace.List, Trace.MultiList, uRandomBuffer, uErrorList, Trace.Node,
  uCommandSet, uCommandSetFactory, Device.PhysicalDrive, Tester.CommandIssuer;

const
  MaxIOSize = 65536;
  TimeoutInMilliSec = 10000;
  MaxParallelIO = 4;

type
  TTestStage = (stReady, stLatencyTest, stCount);
  TTesterIterator = class
  private
    FTesterCommandIssuer: TTesterCommandIssuer;
    FMasterTrace: TTraceMultiList;
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

    procedure SetIterator(const Value: Integer);
    procedure ClearAvgLatency;
    function PrepareAndStartTest: Boolean;
    function ProcessLatencyTest: Boolean;
    function ResetLatencyTest: Boolean;
    procedure CalculateLatency;
    procedure SetNowAsStart;

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
    property ErrorCount: Integer read FErrorCount write FErrorCount;

    constructor Create(const ErrorList: TErrorList);
    destructor Destroy; override;

    function SetDisk(const DriveNumber: Integer): Boolean;

    function ProcessNextOperation: Boolean;

    function AssignBuffer(const RandBuf: PTRandomBuffer): Boolean;
    procedure AssignList(const NewList: TTraceMultiList);
  end;

implementation

procedure TTesterIterator.ClearAvgLatency;
begin
  FSumLatency := 0;
end;

constructor TTesterIterator.Create(const ErrorList: TErrorList);
var
  Frequency: Int64;
begin
  FMasterTrace := TTraceMultiList.Create;
  FListIterator := FMasterTrace.GetIterator;

  QueryPerformanceFrequency(Frequency);
  FFrequency := Frequency / 1000000; //us(10^-6)

  FSumLatency := 0;
  FAvgLatency := 0;
  FMaxLatency := -1;
  FErrorCount := 0;

  FOverallTestCount := 0;

  FErrorList := TErrorList.Create;
  FTesterCommandIssuer := TTesterCommandIssuer.Create;
end;

destructor TTesterIterator.Destroy;
begin
  FreeAndNil(FMasterTrace);
  FreeAndNil(FErrorList);
  FreeAndNil(FTesterCommandIssuer);
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

function TTesterIterator.GetMaximumLatency: Int64;
begin
  result := FMaxLatency;
end;

function TTesterIterator.GetAverageLatency: Int64;
begin
  if (FIterator div MaxParallelIO) = 0 then
    exit(0);

  result := round(FSumLatency / (FIterator div MaxParallelIO));
end;

function TTesterIterator.GetOverallTestCount: Integer;
begin
  result := FOverallTestCount;
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

  if StartLatency = 0 then
    StartLatency := MaxLatency;
  EndLatency := MaxLatency;

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

function TTesterIterator.AssignBuffer(const RandBuf: PTRandomBuffer): Boolean;
begin
  result := FTesterCommandIssuer.AssignBuffer(RandBuf);
end;

procedure TTesterIterator.AssignList(const NewList: TTraceMultiList);
begin
  if FMasterTrace <> nil then
    FreeAndNil(FMasterTrace);
  FMasterTrace := NewList;
  FListIterator := FMasterTrace.GetIterator;
  FListIterator.SetIndex(FIterator);
end;
end.
