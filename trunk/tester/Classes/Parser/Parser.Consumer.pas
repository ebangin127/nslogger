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
    procedure InterpretBuffer(const Buffer: IManagedReadBuffer;
      const BufferLastIndex: Integer);
    function ParseToNode(var CurrLine: PChar; const CurrLineLength: Integer):
      TGSNode;
    function AppendNilAndGetLineLength(const CurrLine: PChar): Integer;
  public
    constructor Create(const BufStor: IBufferStorage; const GSList: TGSList;
      const Multiplier: Double);
    procedure Execute; override;
  end;

implementation

{ TConsumer }

function FindSpace(const AtString: PChar; const LengthOfAtString: Integer):
  Integer; inline;
begin
  for Result := LengthOfAtString - 1 downto 0 do begin
    if (AtString[Result] = ' ') then exit;
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
  else
    LBAStartIdx := 0;
  end;

  LBAEndIdx := FindSpace(CurrLine, CurrLineLength);
  LBALength := LBAEndIdx - LBAStartIdx;
  result.FLength := StrToInt(PChar(@CurrLine[LBAEndIdx + 1]));
  
  CurrLine[LBAStartIdx + LBALength] := #0;
  result.FLBA := StrToInt64(PChar(@CurrLine[LBAStartIdx]));
  result.FLBA := Round(result.FLBA * FMultiplier);
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
  Buffer: IManagedReadBuffer;
  BufferLastIndex: Integer;
begin
  inherited;
  repeat
    Buffer := FBufStor.TakeBuf;
    BufferLastIndex := Length(Buffer) - 1;
    if Length(Buffer) > 0 then
      InterpretBuffer(Buffer, BufferLastIndex);
  until FBufStor.IsClosed;
end;

function TConsumer.AppendNilAndGetLineLength(const CurrLine: PChar): Integer;
begin
  result := 0;
  LastCharOfThisLine := CurrLine[result];
  while (LastCharOfThisLine <> #0) and
        (LastCharOfThisLine <> #10) and
        (LastCharOfThisLine <> #13) do
  begin
    Inc(result);
    LastCharOfThisLine := CurrLine[result];
  end;
  CurrLine[result] := #0;
end;

procedure TConsumer.InterpretBuffer(const Buffer: IManagedReadBuffer;
  const BufferLastIndex: Integer);
var
  PBuffer: PChar;
  CurrLine: PChar;
  CurrChar: Integer;
  CurrLineLength: Cardinal;
  LastCharOfThisLine: Char;
begin
  PBuffer := PChar(Buffer.GetBuffer);

  CurrChar := 0;
  while CurrChar < BufferLastIndex do
  begin
    CurrLine := @PBuffer[CurrChar];
    CurrLineLength := AppendNilAndGetLineLength(CurrLine);
    
    Inc(CurrChar, CurrLineLength);
    Inc(CurrChar, Ord(PBuffer[CurrChar] = #13));
    Inc(CurrChar, Ord(PBuffer[CurrChar] = #10));
    Inc(CurrChar, Ord(PBuffer[CurrChar] = #0));

    if CurrLineLength > 0 then
      FGSList.AddNode(ParseToNode(CurrLine, CurrLineLength));
  end;
end;

end.
