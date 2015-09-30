unit Parser.Producer;

interface

uses
  Classes, Windows, SysUtils,
  Trace.List, Trace.Node, Parser.BufferStorage, Parser.Divider,
  Parser.ReadBuffer;

type
  TProducer = class(TThread)
  private
    FBufStor: IBufferStorage;
    FFileStream: TFileStream;
    FBuffer: IManagedReadBuffer;
    FLimiter: TDividedArea;
    function IsEnter(const CharToCheck: Char): Boolean; inline;
    function FindEnterInWindow(const LastLength, ReadWindow: Integer): Integer;
    function GetLengthEndWithEnter(const CurrLength: Integer): Integer;
  public
    constructor Create(const BufStor: IBufferStorage; const Path: String;
      const Limiter: TDividedArea);
    destructor Destroy; override;

    procedure Execute; override;
  end;

implementation

{ TProducer }

constructor TProducer.Create(const BufStor: IBufferStorage; const Path: String;
  const Limiter: TDividedArea);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FLimiter := Limiter;
  FFileStream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  FFileStream.Seek(FLimiter.FStart, TSeekOrigin.soBeginning);
end;

destructor TProducer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

function TProducer.IsEnter(const CharToCheck: Char): Boolean;
begin
  result := (CharToCheck = #$D) or (CharToCheck = #$A);
end;

function TProducer.FindEnterInWindow(const LastLength, ReadWindow: Integer):
  Integer;
var
  CurrChar: Char;
begin
  result := 0;
  CurrChar := FBuffer[LastLength + result];
  while (not IsEnter(CurrChar)) and
    ((LastLength + result) shr 1 < FLimiter.FEnd) do
  begin
    Inc(result);
    CurrChar := FBuffer[LastLength + result];
  end;
  Inc(result);
end;

function TProducer.GetLengthEndWithEnter(const CurrLength: Integer): Integer;
const
  ReadWindow = 512;
var
  CurrChar: Char;
  ReadLength: Integer;
  Offset: Integer;
begin
  result := CurrLength;
  CurrChar := FBuffer[result - 1];
  while (not IsEnter(CurrChar)) and (FFileStream.Position < FLimiter.FEnd) do
  begin
    ReadLength := FFileStream.Read(
      FBuffer.GetBuffer[result], SizeOf(Char) * ReadWindow);
    Offset := FindEnterInWindow(result, ReadLength);
    Inc(result, Offset);
    FFileStream.Seek((Offset - ReadWindow) * SizeOf(Char),
      TSeekOrigin.soCurrent);
    CurrChar := FBuffer[result - 1];
  end;
end;
    

procedure TProducer.Execute;
var
  LengthOfBuffer: Integer;
  PrevPosition: Int64;
  IsEnd: Boolean;
begin
  inherited;
  repeat
    FBuffer := TManagedReadBuffer.Create(LinearRead shl 1);
    PrevPosition := FFileStream.Position;
    LengthOfBuffer := GetLengthEndWithEnter(
      FFileStream.Read(FBuffer.GetBuffer[0], LinearRead) shr 1);

    if FFileStream.Position > FLimiter.FEnd then
      LengthOfBuffer := (FLimiter.FEnd - PrevPosition + 2) shr 1;

    IsEnd := FFileStream.Position >= FLimiter.FEnd;
    FBufStor.PutBuf(FBuffer, LengthOfBuffer, IsEnd);
  until IsEnd;
end;

end.
