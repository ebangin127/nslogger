unit Parser.Divider;

interface

uses
  SysUtils, Classes, Math,
  Parser.BufferStorage;

type
  TDividedArea = record
    FStart, FEnd: Int64;
  end;

  TDividedResult = Array of TDividedArea;

  TDivider = class
  private
    FFileStream: TFileStream;
    FBuffer: Array of Char;
    function FindNearestEnterFrom(const StartPoint: Int64): Int64;
    function GetControlCodeOffset: Integer;
  public
    constructor Create(Path: String);
    destructor Destroy; override;
    function Divide(const DivideInto: Integer): TDividedResult;
  end;

implementation

{ TDivider }

constructor TDivider.Create(Path: String);
begin
  inherited Create;
  FFileStream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  SetLength(FBuffer, LinearRead);
end;

destructor TDivider.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

function TDivider.FindNearestEnterFrom(const StartPoint: Int64): Int64;
var
  CurrentDelta: Integer;
begin
  FFileStream.Seek(StartPoint, TSeekOrigin.soBeginning);
  FFileStream.Read(FBuffer[0], LinearRead);

  CurrentDelta := 0;
  while (FBuffer[CurrentDelta - 1] <> #$A) and
        (CurrentDelta < Length(FBuffer) - 1) do
      Inc(CurrentDelta, 1);
  if CurrentDelta = Length(FBuffer) - 1 then
    raise ERangeError.Create('Enter Not In 16MB');
  result := StartPoint + (CurrentDelta shl 1) - 1;
end;

function TDivider.GetControlCodeOffset: Integer;
begin
  FFileStream.Seek(0, TSeekOrigin.soBeginning);
  FFileStream.Read(FBuffer[0], 2);

  result := 0;
  if (FBuffer[0] = Chr($FEFF)) or (FBuffer[0] = Chr($FFFE)) then
    result := 2;
end;

function TDivider.Divide(const DivideInto: Integer): TDividedResult;
var
  CurrentIndex: Integer;
  Divided: Double;
begin
  SetLength(Result, DivideInto);
  Divided := FFileStream.Size / DivideInto;
  result[Length(result) - 1].FEnd := FFileStream.Size - 1;
  result[0].FStart := GetControlCodeOffset;
  for CurrentIndex := 0 to Length(result) - 2 do
  begin
    if CurrentIndex > 0 then
      result[CurrentIndex].FStart := result[CurrentIndex - 1].FEnd + 1;
    result[CurrentIndex].FEnd :=
      FindNearestEnterFrom(Floor(Divided * (CurrentIndex + 1)) div 2 * 2);
  end;
  if Length(result) - 2 >= 0 then
    result[Length(result) - 1].FStart := result[Length(result) - 2].FEnd + 1;
end;

end.
