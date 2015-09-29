unit Parser.Producer;

interface

uses
  Classes, Windows, SysUtils,
  uGSList, uGSNode, Parser.BufferStorage, Parser.Divider;

type
  TProducer = class(TThread)
  private
    FBufStor: IBufferStorage;
    FFileStream: TFileStream;
    FBuffer: TMTBuffer;
    FLimiter: TDividedArea;
    function IsEnter(const CharToCheck: Char): Boolean; inline;
    function FindEnterInWindow(const LastLength, ReadWindow: Integer): Integer;
  public
    constructor Create(const BufStor: IBufferStorage; const Path: String;
      const Limiter: TDividedArea);
    destructor Destroy; override;

    procedure Execute; override;
  end;

implementation

const
  ReadWindow = 512;

{ TProducer }

constructor TProducer.Create(const BufStor: IBufferStorage; const Path: String;
  const Limiter: TDividedArea);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FBufStor.SetInnerBufLength(LinearRead * 2);
  FLimiter := Limiter;
  FFileStream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  FFileStream.Seek(FLimiter.FStart, TSeekOrigin.soBeginning);
  SetLength(FBuffer, LinearRead shl 1);
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

procedure TProducer.Execute;
var
  CurrChar: Char;
  CurrLength: Integer;
  ReadLength: Integer;
  Offset: Integer;
  PrevPosition: Int64;
  IsEnd: Boolean;
begin
  inherited;
  repeat
    PrevPosition := FFileStream.Position;
    CurrLength := FFileStream.Read(FBuffer[0], LinearRead) shr 1;
    CurrChar := FBuffer[CurrLength - 1];
    while (not IsEnter(CurrChar)) and (FFileStream.Position < FLimiter.FEnd) do
    begin
      ReadLength :=
        FFileStream.Read(FBuffer[CurrLength], SizeOf(Char) * ReadWindow);
      Offset := FindEnterInWindow(CurrLength, ReadLength);
      Inc(CurrLength, Offset);
      FFileStream.Seek((Offset - ReadWindow) * SizeOf(Char),
        TSeekOrigin.soCurrent);
      CurrChar := FBuffer[CurrLength - 1];
    end;

    if FFileStream.Position > FLimiter.FEnd then
      CurrLength := (FLimiter.FEnd - PrevPosition + 2) shr 1;

    IsEnd := FFileStream.Position >= FLimiter.FEnd;
    FBufStor.PutBuf(FBuffer, CurrLength, IsEnd);
  until IsEnd;
end;

end.
