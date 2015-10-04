unit Parser.Consumer;

interface

uses
  Classes, Windows, SysUtils,
  Trace.List, Trace.Node, Parser.BufferStorage, Parser.ReadBuffer,
  System.PCharVal;

type
  TConsumer = class(TThread)
  private
    FBufStor: IBufferStorage;
    FTraceList: TTraceList;
    FMultiplier: Double;
    procedure InterpretBuffer(const Buffer: IManagedReadBuffer;
      const BufferLastIndex: Integer);
    function ParseToNode(var CurrLine: PChar; const CurrLineLength: Integer):
      TTraceNode;
    function AppendNilAndGetLineLength(const CurrLine: PChar): Integer;
  public
    constructor Create(const BufStor: IBufferStorage;
      const TraceList: TTraceList; const Multiplier: Double);
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
  const CurrLineLength: Integer): TTraceNode;
const
  FlushNode: TTraceNode = (FIOType: TIOType.ioFlush; FLength: 0; FLBA: 0);
var
  LBAStartIdx: Integer;
  LBALength: Integer;
  LBAEndIdx: Integer;
begin
  case CurrLine[1] of
  'w':
  begin
    result.FIOType := TIOType.ioWrite;
    LBAStartIdx := 7;
  end;
  'f':
  begin
    result := FlushNode;
    exit;
  end;
  'r':
  begin
    result.FIOType := TIOType.ioRead;
    LBAStartIdx := 6;
  end;
  't':
  begin
    result.FIOType := TIOType.ioTrim;
    LBAStartIdx := 7;
  end;
  else
    LBAStartIdx := 0;
  end;

  LBAEndIdx := FindSpace(CurrLine, CurrLineLength);
  LBALength := LBAEndIdx - LBAStartIdx;
  result.FLength := PCharToInt(PChar(@CurrLine[LBAEndIdx + 1]),
    CurrLineLength - (LBAEndIdx + 1));

  CurrLine[LBAStartIdx + LBALength] := #0;
  result.FLBA := PCharToInt64(PChar(@CurrLine[LBAStartIdx]), LBALength);
  result.FLBA := Round(result.FLBA * FMultiplier);
end;

constructor TConsumer.Create(const BufStor: IBufferStorage;
  const TraceList: TTraceList; const Multiplier: Double);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FTraceList := TraceList;
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
    BufferLastIndex := Buffer.GetLength - 1;
    if Buffer.GetLength > 0 then
      InterpretBuffer(Buffer, BufferLastIndex);
  until FBufStor.IsClosed;
end;

function TConsumer.AppendNilAndGetLineLength(const CurrLine: PChar): Integer;
var
  LastCharOfThisLine: Char;
begin
  result := 0;
  LastCharOfThisLine := CurrLine[result];
  while (LastCharOfThisLine > #13) or
        ((LastCharOfThisLine <> #0) and
         (LastCharOfThisLine <> #10) and
         (LastCharOfThisLine <> #13)) do
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
begin
  PBuffer := PChar(Buffer.GetBuffer);

  CurrChar := 0;
  while CurrChar < BufferLastIndex do
  begin
    CurrLine := @PBuffer[CurrChar];
    CurrLineLength := AppendNilAndGetLineLength(CurrLine);
    
    Inc(CurrChar, CurrLineLength);
    Inc(CurrChar, Integer(PBuffer[CurrChar] = #13));
    Inc(CurrChar, Integer(PBuffer[CurrChar] = #10));
    Inc(CurrChar, Integer(PBuffer[CurrChar] = #0));

    if CurrLineLength > 0 then
      FTraceList.AddNode(ParseToNode(CurrLine, CurrLineLength));
  end;
end;

end.
