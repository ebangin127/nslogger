unit uErrorList;

interface
uses Classes, SysUtils, DateUtils, Math, Generics.Collections,
     uGSList;

type
  time_t = Int64;

  TErrorNode = record
    FTime: time_t;
    FPos: UINT64;
    FLength: Integer;
  end;

  TErrorList = class(TList<TGSNode>)
  private
    FUnitSize: Double;
    FErrorNodeList: TList<TErrorNode>;
  public
    constructor Create(Size: Integer);
    destructor Destroy; override;

    procedure AddTGSNode(Node: TGSNode);
    function Save(Path: String): Boolean;
  end;

implementation

{ TErrorList }

constructor TErrorList.Create(Size: Integer);
begin
  FUnitSize := Size / 180;
  FErrorNodeList := TList<TErrorNode>.Create;
end;

destructor TErrorList.Destroy;
begin
  FreeAndNil(FErrorNodeList);
end;

procedure TErrorList.AddTGSNode(Node: TGSNode);
var
  ErrorNode: TErrorNode;
begin
  ErrorNode.FTime := DateTimeToUnix(Now);
  ErrorNode.FPos := Node.FLBA;
  ErrorNode.FLength := Node.FLength;
  FErrorNodeList.Add(ErrorNode);
  Add(Node);
end;

function TErrorList.Save(Path: String): Boolean;
var
  DestFile: TStreamWriter;
  CurrNode: TErrorNode;
  CurrLine: String;
begin
  result := false;

  DestFile := TStreamWriter.Create(Path, true, TEncoding.Unicode, 4096);
  if DestFile = nil then
    exit;

  for CurrNode in FErrorNodeList.List do
  begin
    if (CurrNode.FTime <> 0) or
        (CurrNode.FPos <> 0) or
        (CurrNode.FLength <> 0) then
    CurrLine := IntToStr(CurrNode.FTime) + ' ' +
                UIntToStr(CurrNode.FPos) + ' ' +
                IntToStr(CurrNode.FLength);
    DestFile.WriteLine(CurrLine);
  end;

  FreeAndNil(DestFile);
end;

end.
