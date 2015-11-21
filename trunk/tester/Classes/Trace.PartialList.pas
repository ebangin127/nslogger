unit Trace.PartialList;

interface

uses
  Classes, Windows, Math, SysUtils, Generics.Collections, Threading,
  Trace.List, Trace.Node, Parser, Parser.Divider;

const
  UnitListShlValue = 24;
  UnitListSize = 1 shl UnitListShlValue; //(16777216) = (1 << 24)

type
  TTracePartialListIterator = class;

  TTracePartialList = class
  private
    FCurrentList: TTraceList;
    FNextList: TTraceList;
    FPath: String;
    FMultiConst: Double;
    FMaxRAMInMiB: Integer;
    FPartLimit: TDividedResult;
    FPartLimitInItems: Array of Integer;
    FCurrentPosition: Integer;
    FNextPosition: Integer;
    FLastReadingTask: ITask;
    FCount: Integer;
    function GetItem(Index: Integer): TTraceNode;
    procedure LoadSpecific(const ListIndex: Integer);
    procedure Divide;
    procedure WaitForLoad;
    procedure GetCount;
    function GetItemFromSpecificList(const CurrentListIndex: Integer;
      const LastCount: Integer; const Index: Integer): TTraceNode;
    procedure PullNextToCurrent;
    procedure LoadNext;
    function GetNextListIndex: Integer;
    procedure PrepareNextListIfNeeded(const IndexToGet: Integer);
    procedure WaitAndPull;

  public
    constructor Create(const Path: String; const MultiConst: Double;
      const MaxRAMInMiB: Integer);
    destructor Destroy; override;

    function Count: Integer;
    function GetIterator: ITraceListIterator;

    property Items[Index: Integer]: TTraceNode read GetItem; default;
  end;

  TTracePartialListIterator = class(TInterfacedObject, ITraceListIterator)
  private
    FTracePartialList: TTracePartialList;
    CurrentItemIndex: Integer;

  public
    function GetNextItem: TTraceNode;
    procedure GoToFirst;
    procedure SetIndex(const NewIndex: Integer);

    constructor Create(const TracePartialList: TTracePartialList);
  end;

implementation

constructor TTracePartialList.Create(const Path: String;
  const MultiConst: Double; const MaxRAMInMiB: Integer);
begin
  FPath := Path;
  FMultiConst := MultiConst;
  FMaxRAMInMiB := MaxRAMInMiB;
  Divide;
  GetCount;
  LoadSpecific(0);
  WaitAndPull;
end;

destructor TTracePartialList.Destroy;
begin
  FCurrentList.Free;
  FNextList.Free;
end;

procedure TTracePartialList.Divide;
var
  DivideCount: Integer;
  Divider: TDivider;
  OpenedFile: File of Byte;
begin
  AssignFile(OpenedFile, FPath);
  Divider := TDivider.Create(FPath);
  try
    Reset(OpenedFile);
    DivideCount := (FileSize(OpenedFile) shr 20) div (FMaxRAMInMiB shr 3 * 5);
    FPartLimit := Divider.Divide(DivideCount);
  finally
    CloseFile(OpenedFile);
    FreeAndNil(Divider);
  end;
  SetLength(FPartLimitInItems, DivideCount);
end;

function TTracePartialList.GetNextListIndex: Integer;
begin
  result := (FCurrentPosition + 1) mod Length(FPartLimit);
end;

procedure TTracePartialList.LoadNext;
begin
  LoadSpecific(GetNextListIndex);
end;

procedure TTracePartialList.LoadSpecific(const ListIndex: Integer);
begin
  FNextPosition := ListIndex;
  FLastReadingTask := TTask.Create(procedure
  begin
    FNextList := TParser.GetInstance.ImportTrace(
      FPath, FMultiConst, FPartLimit[FCurrentPosition]);
  end);
  FLastReadingTask.Start;
end;

procedure TTracePartialList.WaitForLoad;
var
  ArrayToWaitTask: Array of ITask;
begin
  SetLength(ArrayToWaitTask, 1);
  ArrayToWaitTask[0] := FLastReadingTask;
  TTask.WaitForAll(ArrayToWaitTask);
end;

function TTracePartialList.Count: Integer;
begin
  result := FCount;
end;

procedure TTracePartialList.GetCount;
begin
  FCount := 0;
  repeat
    LoadNext;
    WaitAndPull;
    Inc(FCount, FCurrentList.Count);
    FPartLimitInItems[FCurrentPosition] := FCurrentList.Count;
    FCurrentList.Free;
  until FNextPosition = 0;
end;

function TTracePartialList.GetItem(Index: Integer): TTraceNode;
var
  CurrentListIndex: Integer;
  CurrentCount: Integer;
begin
  if Index >= Count then
    raise EArgumentOutOfRangeException.Create('Index Out Of Range');

  CurrentCount := 0;
  for CurrentListIndex := 0 to Length(FPartLimitInItems) - 1 do
  begin
    if CurrentCount + FPartLimitInItems[CurrentListIndex] > Index then
      exit(GetItemFromSpecificList(CurrentListIndex, CurrentCount, Index));
    CurrentCount := CurrentCount + FPartLimitInItems[CurrentListIndex];
  end;
end;

function TTracePartialList.GetIterator: ITraceListIterator;
begin
  result := TTracePartialListIterator.Create(self);
end;

procedure TTracePartialList.WaitAndPull;
begin
  WaitForLoad;
  PullNextToCurrent;
end;

procedure TTracePartialList.PrepareNextListIfNeeded(const IndexToGet: Integer);
begin
  if FNextPosition <> GetNextListIndex then
    if IndexToGet > (FCurrentList.Count shr 1) then
    begin
      WaitForLoad;
      LoadNext;
    end;
end;

procedure TTracePartialList.PullNextToCurrent;
begin
  FCurrentList := FNextList;
  FCurrentPosition := FNextPosition;
  FNextList := nil;
end;

function TTracePartialList.GetItemFromSpecificList(
  const CurrentListIndex: Integer; const LastCount: Integer;
  const Index: Integer): TTraceNode;
var
  IndexToGet: Integer;
begin
  if CurrentListIndex = FCurrentPosition then
  begin
    IndexToGet := Index - LastCount;
    PrepareNextListIfNeeded(IndexToGet);
    exit(FCurrentList[IndexToGet]);
  end
  else if CurrentListIndex = GetNextListIndex then
  begin
    FreeAndNil(FCurrentList);
    WaitAndPull;
    exit(FCurrentList[Index - LastCount]);
  end
  else
  begin
    FreeAndNil(FCurrentList);
    LoadSpecific(CurrentListIndex);
    WaitAndPull;
    exit(FCurrentList[Index - LastCount]);
  end;
end;

{ TTraceMultiListIterator }

constructor TTracePartialListIterator.Create(
  const TracePartialList: TTracePartialList);
begin
  FTracePartialList := TracePartialList;
end;

procedure TTracePartialListIterator.GoToFirst;
begin
  SetIndex(0);
end;

function TTracePartialListIterator.GetNextItem: TTraceNode;
begin
  TMonitor.Enter(self);
  if CurrentItemIndex = FTracePartialList.Count then
    GoToFirst;
  result := FTracePartialList[CurrentItemIndex];
  SetIndex(CurrentItemIndex + 1);
  TMonitor.Exit(self);
end;

procedure TTracePartialListIterator.SetIndex(const NewIndex: Integer);
begin
  CurrentItemIndex := NewIndex;
end;

end.
