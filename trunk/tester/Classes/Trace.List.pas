unit Trace.List;

interface

uses
  Windows, Math, SysUtils,
  Generics.Collections, Threading,
  Trace.Node;

const
  UnitListShlValue = 24;
  UnitListSize = 1 shl UnitListShlValue; //(16777216) = (1 << 24)

type
  TTraceListIterator = class;
  ITraceListIterator = interface
    function GetNextItem: TTraceNode;
    procedure GoToFirst;
    procedure SetIndex(const NewIndex: Integer);
  end;

  TTraceList = class
  private
    Nodes: TList<TTraceNode>;
    function GetItem(Index: Integer): TTraceNode;

  public
    constructor Create;
    destructor Destroy; override;

    procedure AddNode(const Node: TTraceNode);
    procedure AddFlush;
    function Count: Integer;
    function GetIterator: ITraceListIterator;

    property Items[Index: Integer]: TTraceNode read GetItem; default;
  end;

  TTraceListIterator = class(TInterfacedObject, ITraceListIterator)
  private
    FTraceList: TTraceList;
    CurrentItemIndex: Integer;

  public
    function GetNextItem: TTraceNode;
    procedure GoToFirst;
    procedure SetIndex(const NewIndex: Integer);

    constructor Create(TraceList: TTraceList);
  end;

implementation

constructor TTraceList.Create;
begin
  Nodes := TList<TTraceNode>.Create;
end;

destructor TTraceList.Destroy;
begin
  FreeAndNil(Nodes);
end;

procedure TTraceList.AddNode(const Node: TTraceNode);
begin
  Nodes.Insert(Count, Node);
end;

procedure TTraceList.AddFlush;
var
  FlushNode: TTraceNode;
begin
  FlushNode := TTraceNode.CreateByValues(TIOType.ioFlush, 0, 0);
  Nodes.Insert(Count, FlushNode);
end;

function TTraceList.Count: Integer;
begin
  result := Nodes.Count;
end;

function TTraceList.GetItem(Index: Integer): TTraceNode;
begin
  result := Nodes[Index];
end;

function TTraceList.GetIterator: ITraceListIterator;
begin
  result := TTraceListIterator.Create(self);
end;

{ TTraceListIterator }

constructor TTraceListIterator.Create(TraceList: TTraceList);
begin
  FTraceList := TraceList;
end;

procedure TTraceListIterator.GoToFirst;
begin
  SetIndex(0);
end;

function TTraceListIterator.GetNextItem: TTraceNode;
begin
  TMonitor.Enter(self);
  if CurrentItemIndex = FTraceList.Count then
    GoToFirst;
  result := FTraceList[CurrentItemIndex];
  SetIndex(CurrentItemIndex + 1);
  TMonitor.Exit(self);
end;

procedure TTraceListIterator.SetIndex(const NewIndex: Integer);
begin
  CurrentItemIndex := NewIndex;
end;

end.
