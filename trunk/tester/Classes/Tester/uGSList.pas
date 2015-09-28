unit uGSList;

interface

uses
  Windows, Math, SysUtils,
  Generics.Collections, Threading,
  uGSNode;

const
  UnitListShlValue = 24;
  UnitListSize = 1 shl UnitListShlValue; //(16777216) = (1 << 24)

type
  TGSListIterator = class;
  IGSListIterator = interface
    function GetNextItem: TGSNode;
    procedure GoToFirst;
    procedure SetIndex(NewIndex: Integer);
  end;

  TGSList = class
  private
    Nodes: TList<TGSNode>;
    function GetItem(Index: Integer): TGSNode;

  public
    constructor Create;
    destructor Destroy; override;

    procedure AddNode(const Node: TGSNode);
    procedure AddFlush;
    function Count: Integer;
    function GetIterator: IGSListIterator;

    property Items[Index: Integer]: TGSNode read GetItem; default;
  end;

  TGSListIterator = class(TInterfacedObject, IGSListIterator)
  private
    FGSList: TGSList;
    CurrentItemIndex: Integer;

  public
    function GetNextItem: TGSNode;
    procedure GoToFirst;
    procedure SetIndex(NewIndex: Integer);

    constructor Create(GSList: TGSList);
  end;

implementation

constructor TGSList.Create;
begin
  Nodes := TList<TGSNode>.Create;
end;

destructor TGSList.Destroy;
begin
  FreeAndNil(Nodes);
end;

procedure TGSList.AddNode(const Node: TGSNode);
begin
  Nodes.Insert(Count, Node);
end;

procedure TGSList.AddFlush;
var
  FlushNode: TGSNode;
begin
  FlushNode := TGSNode.CreateByValues(TIOType.ioFlush, 0, 0);
  Nodes.Insert(Count, FlushNode);
end;

function TGSList.Count: Integer;
begin
  result := Nodes.Count;
end;

function TGSList.GetItem(Index: Integer): TGSNode;
begin
  result := Nodes[Index];
end;

function TGSList.GetIterator: IGSListIterator;
begin
  result := TGSListIterator.Create(self);
end;

{ TGSListIterator }

constructor TGSListIterator.Create(GSList: TGSList);
begin
  FGSList := GSList;
end;

procedure TGSListIterator.GoToFirst;
begin
  SetIndex(0);
end;

function TGSListIterator.GetNextItem: TGSNode;
begin
  TMonitor.Enter(self);
  if CurrentItemIndex = FGSList.Count then
    GoToFirst;
  result := FGSList[CurrentItemIndex];
  SetIndex(CurrentItemIndex + 1);
  TMonitor.Exit(self);
end;

procedure TGSListIterator.SetIndex(NewIndex: Integer);
begin
  CurrentItemIndex := NewIndex;
end;

end.
