unit Trace.MultiList;

interface

uses
  Windows, Math, SysUtils,
  Generics.Collections, Threading,
  Trace.List, Trace.Node;

const
  UnitListShlValue = 24;
  UnitListSize = 1 shl UnitListShlValue; //(16777216) = (1 << 24)

type
  TTraceMultiListIterator = class;

  TTraceMultiList = class
  private
    Lists: TList<TTraceList>;
    function GetItem(Index: Integer): TTraceNode;

  public
    constructor Create;
    destructor Destroy; override;

    procedure AddList(const List: TTraceList);
    function Count: Integer;
    function GetIterator: ITraceListIterator;

    property Items[Index: Integer]: TTraceNode read GetItem; default;
  end;

  TTraceMultiListIterator = class(TInterfacedObject, ITraceListIterator)
  private
    FTraceMultiList: TTraceMultiList;
    CurrentItemIndex: Integer;

  public
    function GetNextItem: TTraceNode;
    procedure GoToFirst;
    procedure SetIndex(NewIndex: Integer);

    constructor Create(TraceMultiList: TTraceMultiList);
  end;

implementation

constructor TTraceMultiList.Create;
begin
  Lists := TList<TTraceList>.Create;
end;

destructor TTraceMultiList.Destroy;
var
  CurrentList: TTraceList;
begin
  for CurrentList in Lists do
    CurrentList.Free;
  FreeAndNil(Lists);
end;

procedure TTraceMultiList.AddList(const List: TTraceList);
begin
  Lists.Insert(Lists.Count, List);
end;

function TTraceMultiList.Count: Integer;
var
  CurrentList: TTraceList;
begin
  result := 0;
  for CurrentList in Lists do
    result := result + CurrentList.Count;
end;

function TTraceMultiList.GetItem(Index: Integer): TTraceNode;
var
  CurrentList: TTraceList;
  CurrentCount: Integer;
begin
  if Index >= Count then
    raise EArgumentOutOfRangeException.Create('Index Out Of Range');
    
  CurrentCount := 0;
  for CurrentList in Lists do
  begin
    if CurrentCount + CurrentList.Count > Index then
      exit(CurrentList[Index - CurrentCount]);
    CurrentCount := CurrentCount + CurrentList.Count;
  end;
end;

function TTraceMultiList.GetIterator: ITraceListIterator;
begin
  result := TTraceMultiListIterator.Create(self);
end;

{ TTraceMultiListIterator }

constructor TTraceMultiListIterator.Create(TraceMultiList: TTraceMultiList);
begin
  FTraceMultiList := TraceMultiList;
end;

procedure TTraceMultiListIterator.GoToFirst;
begin
  SetIndex(0);
end;

function TTraceMultiListIterator.GetNextItem: TTraceNode;
begin
  TMonitor.Enter(self);
  if CurrentItemIndex = FTraceMultiList.Count then
    GoToFirst;
  result := FTraceMultiList[CurrentItemIndex];
  SetIndex(CurrentItemIndex + 1);
  TMonitor.Exit(self);
end;

procedure TTraceMultiListIterator.SetIndex(NewIndex: Integer);
begin
  CurrentItemIndex := NewIndex;
end;

end.
