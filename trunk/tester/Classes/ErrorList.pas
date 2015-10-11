unit ErrorList;

interface
uses
  Classes, SysUtils, DateUtils, Math, Generics.Collections,
  Trace.List, Trace.Node;

const
  SaveLine = 10000;

type
  time_t = Int64;

  TErrorList = class(TList<TTraceNode>)
  private
    FToSaveList: TStringList;
    FSavePath: String;
  public
    constructor Create(const SavePath: String);
    destructor Destroy; override;
    procedure AddLine(const Value: String);
    procedure Save;
  end;

implementation

{ TErrorList }

procedure TErrorList.AddLine(const Value: String);
begin
  FToSaveList.Add(Value);
  if FToSaveList.Count > SaveLine then
  begin
    Save;
    FToSaveList.Clear;
  end;
end;

constructor TErrorList.Create(const SavePath: String);
begin
  inherited Create;
  FToSaveList := TStringList.Create;
  FSavePath := SavePath;
end;

destructor TErrorList.Destroy;
begin
  FreeAndNil(FToSaveList);
  inherited;
end;

procedure TErrorList.Save;
var
  DestFile: TStreamWriter;
  CurrLine: String;
begin
  DestFile := TStreamWriter.Create(FSavePath, true, TEncoding.Unicode, 4096);
  if DestFile = nil then
    exit;

  for CurrLine in FToSaveList do
  begin
    DestFile.WriteLine(CurrLine);
  end;
  FToSaveList.Clear;

  FreeAndNil(DestFile);
end;

end.
