unit uParser;

interface

uses
  Classes, Windows, SysUtils,
  uIntFunctions, uGSList;

const
  LinearRead = 16 shl 20; // 16MB

type
  TMTBuffer = Array of Char;

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TMTBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
    FToBeClosed: Boolean;
    FHalfInByte, FHalfInArray: Integer;

    FCurrSize: Integer;
    FFirstCopy: Boolean;
  public
    property Closed: Boolean read FClosed;

    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;

    function TakeBuf: TMTBuffer;
    procedure PutBuf(InBuffer: TMTBuffer; CurrSize: Integer; NeedClose: Boolean);
  end;

function makeJEDECListAndFix(TraceList: Pointer; Path: PChar; MultiConst: Double):
                        PTGListHeader; cdecl; export;

implementation

type
  TProducer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileStream: TFileStream;
    FBuffer: TMTBuffer;
  public
    constructor Create(BufStor: TBufferStorage; Path: String);
    destructor Destroy; override;

    procedure Execute; override;
  end;

  TConsumer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FGSList: TGSList;
    FMultiConst: Double;
  public
    constructor Create(BufStor: TBufferStorage; GSList: TGSList;
                       MultiConst: Double);
    procedure Execute; override;
  end;


function FastPos(const ToFind: Char; const S: string):
         Integer; inline;
begin
  for Result := length(S) downto 1 do begin
    if (S[Result] = ToFind) then exit;
  end;

  Result := 0;
end;

function DivideIntoNode(const CurrLine: String): TGSNode; overload;
var
  LBAStartIdx: Integer;
  LBALength: Integer;
  LBAEndIdx: Integer;
begin
  LBAStartIdx := 0;
  case CurrLine[2] of
  'w':
  begin
    result.FIOType := TIOTypeInt[TIOType.ioWrite];
    LBAStartIdx := 8;
  end;
  'f':
  begin
    result.FIOType := TIOTypeInt[TIOType.ioFlush];
    result.FLBA := 0;
    result.FLength := 0;
    exit;
  end;
  'r':
  begin
    result.FIOType := TIOTypeInt[TIOType.ioRead];
    LBAStartIdx := 7;
  end;
  't':
  begin
    result.FIOType := TIOTypeInt[TIOType.ioTrim];
    LBAStartIdx := 8;
  end;
  end;

  LBAEndIdx := FastPos(' ', CurrLine);
  LBALength := LBAEndIdx - LBAStartIdx;

  try
    result.FLBA := StrToInt64(Copy(CurrLine, LBAStartIdx, LBALength));
    result.FLength := StrToInt(Copy(CurrLine, LBAEndIdx + 1, Length(CurrLine)));
  except
    Assert(false, CurrLine);
  end;
end;

function DivideIntoNode(const CurrLine: String;
                        const MultiConst: Double): TGSNode; inline; overload;
begin
  result := DivideIntoNode(CurrLine);
  result.FLBA := Round(result.FLBA * MultiConst);
end;

function makeJEDECListAndFix(TraceList: Pointer; Path: PChar; MultiConst: Double):
                        PTGListHeader; cdecl; export;
var
  BufStor: TBufferStorage;
  Producer: TProducer;
  Consumer: TConsumer;
begin
  BufStor := TBufferStorage.Create;
  Producer := TProducer.Create(BufStor, Path);
  Consumer := TConsumer.Create(BufStor, TGSList(TraceList), MultiConst);

  WaitForSingleObject(Consumer.Handle, INFINITE);
  WaitForSingleObject(Producer.Handle, INFINITE);

  FreeAndNil(Consumer);
  FreeAndNil(Producer);
  FreeAndNil(BufStor);

  exit(TGSList(TraceList).GetListHeader);
end;

function makeJEDECList(TraceList: Pointer; Path: PChar): PTGListHeader; cdecl;
         export;
begin
  result := makeJEDECListAndFix(TraceList, Path, 1);
end;

function makeJedecClass: Pointer; cdecl; export;
begin
  exit(Pointer(TGSList.Create));
end;

procedure deleteJedecClass(delClass: Pointer); cdecl; export;
begin
  FreeAndNil(TGSList(delClass));
end;

exports makeJEDECList, makeJEDECListAndFix, makeJedecClass, deleteJedecClass;

{ BufferStorage }

procedure TBufferStorage.ReadyToClose;
begin
  FToBeClosed := true;
end;

constructor TBufferStorage.Create;
begin
  FEmpty := true;
  FFirstCopy := true;
  FClosed := false;
end;

procedure TBufferStorage.SetInnerBufLength(NewLength: Integer);
begin
  SetLength(FBuffer, NewLength);
  FHalfInByte := SizeOf(Char) * (Length(FBuffer) shr 1);
  FHalfInArray := FHalfInByte shr 1;
end;

procedure TBufferStorage.PutBuf(InBuffer: TMTBuffer;
                                CurrSize: Integer; NeedClose: Boolean);
begin
  TMonitor.Enter(Self);

  try
    while not FEmpty do
    begin
      TMonitor.Wait(Self, INFINITE);
    end;

    if CurrSize = 0 then
    begin
      FClosed := true;
      FEmpty := false;

      TMonitor.PulseAll(Self);
      TMonitor.Exit(Self);

      exit;
    end
    else if NeedClose then
    begin
      ReadyToClose;
      SetLength(FBuffer, CurrSize);
    end;

    CopyMemory(@FBuffer[0], @InBuffer[0], CurrSize * SizeOf(Char));
    FCurrSize := CurrSize;
  finally
    FEmpty := False;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: TMTBuffer;
var
  NewLength: Integer;
begin
  TMonitor.Enter(Self);
  try
    while FEmpty do
    begin
      TMonitor.Wait(Self, INFINITE);
    end;

    if FClosed then
    begin
      SetLength(FOutputBuffer, 0);

      TMonitor.PulseAll(Self);
      TMonitor.Exit(Self);

      exit(FOutputBuffer);
    end;

    NewLength := FCurrSize * SizeOf(Char);
    SetLength(FOutputBuffer, FCurrSize + 1);
    CopyMemory(@FOutputBuffer[0], @FBuffer[0], NewLength);
    FOutputBuffer[FCurrSize] := #0;

    result := FOutputBuffer;

    if FToBeClosed then
      FClosed := true;
  finally
    FEmpty := True;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

{ TProducer }

constructor TProducer.Create(BufStor: TBufferStorage; Path: String);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FFileStream := TFileStream.Create(Path, fmOpenRead);
  SetLength(FBuffer, LinearRead shl 1);
end;

destructor TProducer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

procedure TProducer.Execute;
var
  CurrLength: Integer;
begin
  inherited;

  FBufStor.SetInnerBufLength(LinearRead * 2);

  repeat
    CurrLength := LinearRead shr 1;
    CurrLength := FFileStream.Read(FBuffer[0], CurrLength shl 1) shr 1;
    while (FBuffer[CurrLength - 1] <> #$D) and
          (FBuffer[CurrLength - 1] <> #$A) and
          (FFileStream.Position < FFileStream.Size) do
    begin
      Inc(CurrLength, 1);
      FFileStream.Read(FBuffer[CurrLength - 1], SizeOf(Char));
    end;

    FBufStor.PutBuf(FBuffer, CurrLength,
                    FFileStream.Position = FFileStream.Size);
  until FFileStream.Position = FFileStream.Size;
end;


{ TConsumer }

constructor TConsumer.Create(BufStor: TBufferStorage; GSList: TGSList;
                             MultiConst: Double);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FGSList := GSList;
  FMultiConst := MultiConst;
end;

procedure TConsumer.Execute;
var
  Buffer: TMTBuffer;

  LastLine: String;

  PStrBuffer: PChar;
  CurrLine: PChar;
  CurrChar: Integer;

  StrBuffer: String;
  BufEnd: Integer;
  CurrLineLength: Cardinal;

  NeedMultiConst: Boolean;
begin
  inherited;
  NeedMultiConst := FMultiConst <> 1;

  repeat
    Buffer := FBufStor.TakeBuf;
    BufEnd := Length(Buffer) - 1;

    if Length(Buffer) > 0 then
    begin
      //줄 단위로 분해하기
      StrBuffer := PChar(Buffer);

      PStrBuffer := Pointer(StrBuffer);

      // This is a lot faster than using StrPos/AnsiStrPos when
      // LineBreak is the default (#13#10)
      CurrChar := 0;
      while CurrChar < BufEnd do
      begin
        CurrLineLength := 0;
        CurrLine := PChar(@Buffer[CurrChar]);
        while (CurrLine[CurrLineLength] <> #0) and
              (CurrLine[CurrLineLength] <> #10) and
              (CurrLine[CurrLineLength] <> #13) do
          Inc(CurrLineLength);

        Inc(CurrChar, CurrLineLength);
        if PStrBuffer[CurrChar] = #13 then Inc(CurrChar);
        if PStrBuffer[CurrChar] = #10 then Inc(CurrChar);
        CurrLine[CurrLineLength] := #0;
        if PStrBuffer[CurrChar] = #0 then Inc(CurrChar);
        Assert((CurrLine[0] = '$') or (CurrLineLength = 0),
                LastLine + ' / '
                + CurrLine + ' / '
                + IntToStr(BufEnd) + ' '
                + IntToStr(CurrChar));

        if CurrChar < BufEnd then
        begin
          //줄로 분해된 문장 처리하기
          if (CurrLineLength > 0) then
            if NeedMultiConst then
              FGSList.AddNode(DivideIntoNode(CurrLine, FMultiConst))
            else
              FGSList.AddNode(DivideIntoNode(CurrLine));
            LastLine := CurrLine;
        end
        else
        begin
          //마지막 줄 처리
          LastLine := CurrLine;

          //줄로 분해된 문장 처리하기
          if CurrLineLength > 0 then
            if NeedMultiConst then
              FGSList.AddNode(DivideIntoNode(CurrLine, FMultiConst))
            else
              FGSList.AddNode(DivideIntoNode(CurrLine));
        end;
      end;
    end;
  until FBufStor.Closed;
end;
end.
