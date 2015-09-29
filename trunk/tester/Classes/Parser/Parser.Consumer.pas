unit Parser.Consumer;

interface

uses
  Classes, Windows, SysUtils,
  uGSList, uGSNode, Parser.BufferStorage;

type
  TConsumer = class(TThread)
  private
    FBufStor: IBufferStorage;
    FGSList: TGSList;
    FMultiplier: Double;
    procedure InterpretCurrentBuffer(const Buffer: TMTBuffer;
      const BufEnd: Integer);
    function ParseToNode(var CurrLine: PChar;
      const CurrLineLength: Integer): TGSNode;
    function ParseToNodeWithMultiplier(var CurrLine: PChar;
      const CurrLineLength: Integer; const Multiplier: Double): TGSNode;
  public
    constructor Create(const BufStor: IBufferStorage; const GSList: TGSList;
      const Multiplier: Double);
    procedure Execute; override;
  end;

implementation

{ TConsumer }

function FastPos(const ToFind: Char; const S: PChar): Integer; inline;
begin
  for Result := length(S) downto 1 do begin
    if (S[Result] = ToFind) then exit;
  end;

  Result := 0;
end;

function TConsumer.ParseToNode(var CurrLine: PChar;
  const CurrLineLength: Integer): TGSNode;
const
  FlushNode: TGSNode = (FIOType: TIOType.ioFlush; FLength: 0; FLBA: 0);
var
  LBAStartIdx: Integer;
  LBALength: Integer;
  LBAEndIdx: Integer;
begin
  LBAStartIdx := 0;
  case CurrLine[1] of
  'w':
  begin
    result.FIOType := TIOType.ioWrite;
    LBAStartIdx := 8;
  end;
  'f':
  begin
    result := FlushNode;
    exit;
  end;
  'r':
  begin
    result.FIOType := TIOType.ioRead;
    LBAStartIdx := 7;
  end;
  't':
  begin
    result.FIOType := TIOType.ioTrim;
    LBAStartIdx := 8;
  end;
  end;

  LBAEndIdx := FastPos(' ', CurrLine);
  LBALength := LBAEndIdx - LBAStartIdx;
  result.FLength := StrToInt(PChar(@CurrLine[LBAEndIdx + 1]));
  CurrLine[LBAStartIdx + LBALength] := #0;
  result.FLBA := StrToInt64(PChar(@CurrLine[LBAStartIdx]));
end;

function TConsumer.ParseToNodeWithMultiplier(var CurrLine: PChar;
  const CurrLineLength: Integer; const Multiplier: Double): TGSNode;
begin
  result := ParseToNode(CurrLine, CurrLineLength);
  result.FLBA := Round(result.GetLBA * Multiplier);
end;

constructor TConsumer.Create(const BufStor: IBufferStorage;
  const GSList: TGSList; const Multiplier: Double);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FGSList := GSList;
  FMultiplier := Multiplier;
end;

procedure TConsumer.Execute;
var
  Buffer: TMTBuffer;
  BufEnd: Integer;
begin
  inherited;
  repeat
    Buffer := FBufStor.TakeBuf;
    BufEnd := Length(Buffer) - 1;
    if Length(Buffer) > 0 then
      InterpretCurrentBuffer(Buffer, BufEnd);
  until FBufStor.IsClosed;
end;

procedure TConsumer.InterpretCurrentBuffer(const Buffer: TMTBuffer;
  const BufEnd: Integer);
var
  PStrBuffer: PChar;
  StrBuffer: String;
  CurrLine: PChar;
  CurrChar: Integer;
  CurrLineLength: Cardinal;
  LastCharOfThisLine: Char;
begin
  StrBuffer := PChar(Buffer);
  PStrBuffer := Pointer(StrBuffer);

  CurrChar := 0;
  while CurrChar < BufEnd do
  begin
    CurrLineLength := 0;
    CurrLine := @PStrBuffer[CurrChar];

    LastCharOfThisLine := CurrLine[CurrLineLength];
    while (LastCharOfThisLine <> #0) and
          (LastCharOfThisLine <> #10) and
          (LastCharOfThisLine <> #13) do
    begin
      Inc(CurrLineLength);
      LastCharOfThisLine := CurrLine[CurrLineLength];
    end;

    Inc(CurrChar, CurrLineLength);
    if PStrBuffer[CurrChar] = #13 then Inc(CurrChar);
    if PStrBuffer[CurrChar] = #10 then Inc(CurrChar);
    CurrLine[CurrLineLength] := #0;
    if PStrBuffer[CurrChar] = #0 then Inc(CurrChar);

    if CurrLineLength > 0 then
      FGSList.AddNode(
        ParseToNodeWithMultiplier(CurrLine, CurrLineLength, FMultiplier));
  end;
end;

end.
