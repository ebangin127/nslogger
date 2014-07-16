library parser;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }


uses
  System.SysUtils,
  Math,
  Windows,
  System.Classes,
  uGSList in '..\tester\Classes\Tester\uGSList.pas';

const
  LinearRead = 32768;

{$R *.res}

type
  TMTBuffer = Array of Char;

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TMTBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
    FToBeClosed: Boolean;
    FReadOffset: Integer;
    FHalfInByte, FHalfInArray: Integer;

    FFirstCopy: Boolean;
  public
    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;

    function TakeBuf: TMTBuffer;
    procedure PutBuf(InBuffer: TMTBuffer; NeedClose: Boolean);
  end;

  TProducer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileStream: TFileStream;
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
    Writeln(CurrLine);
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
  FReadOffset := 0;
  FClosed := false;
end;

procedure TBufferStorage.SetInnerBufLength(NewLength: Integer);
begin
  SetLength(FBuffer, NewLength + 1);
  FBuffer[NewLength] := #0;
  FHalfInByte := SizeOf(Char) * (Length(FBuffer) shr 1);
  FHalfInArray := FHalfInByte shr 1;
end;

procedure TBufferStorage.PutBuf(InBuffer: TMTBuffer; NeedClose: Boolean);
var
  ReadOffset: Integer;
  MaxLength: Integer;
begin
  TMonitor.Enter(Self);

  try
    while not FEmpty do
    begin
      TMonitor.Wait(Self, INFINITE);
    end;

    if Length(InBuffer) = 0 then
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
      SetLength(FBuffer, Length(InBuffer));
    end;

    if FFirstCopy = false then
    begin
      MaxLength := FHalfInByte shl 1;

      ReadOffset := 2;
      if (FBuffer[(MaxLength - ReadOffset) shr 1] = #$D) or
         (FBuffer[(MaxLength - ReadOffset) shr 1] = #$A) then
         ReadOffset := 0
      else
      begin
        while FBuffer[(MaxLength - ReadOffset) shr 1] <> '$' do
          Inc(ReadOffset, SizeOf(Char));
      end;

      CopyMemory(@FBuffer[(FHalfInByte - ReadOffset) shr 1],
                 @FBuffer[(MaxLength - ReadOffset) shr 1],
                 ReadOffset);
      FReadOffset := ReadOffset;
    end
    else
    begin
      FFirstCopy := false;
    end;

    CopyMemory(@FBuffer[FHalfInArray], @InBuffer[0],
               Length(InBuffer) * SizeOf(Char));

    if FToBeClosed then
      FClosed := true;

  finally
    FEmpty := False;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: TMTBuffer;
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
      exit(FOutputBuffer);
    end;

    SetLength(FOutputBuffer, ((FHalfInByte + FReadOffset) shr 1) + 1);
    CopyMemory(@FOutputBuffer[0], @FBuffer[(FHalfInByte - FReadOffset) shr 1],
                                            FHalfInByte + FReadOffset);
    FOutputBuffer[Length(FOutputBuffer) - 1] := #0;

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
end;

destructor TProducer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

procedure TProducer.Execute;
var
  Buffer: TMTBuffer;

  ReadLength: Integer;
  SizeOfChar: Integer;
  ToReadLength: Integer;
begin
  inherited;

  SizeOfChar := SizeOf(Char);
  ToReadLength := LinearRead * SizeOfChar;
  FBufStor.SetInnerBufLength(LinearRead * 2);
  SetLength(Buffer, LinearRead);

  repeat
    ReadLength := FFileStream.Read(Buffer[0], ToReadLength);

    if ReadLength < ToReadLength then
    begin
      ReadLength := ReadLength div SizeOfChar;
      SetLength(Buffer, ReadLength);
    end;

    FBufStor.PutBuf(Buffer, FFileStream.Position = FFileStream.Size);
  until ReadLength = 0;
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
  CurrLineIdx: Integer;

  SizeOfChar: Integer;
  ToReadLength: Integer;
  LastLine: String;
  LastLinePtr: PChar;
  EndTarget: Int64;

  PStrBuffer: PChar;
  CurrLine: PChar;
  CurrChar: Integer;

  StrBuffer: String;
  LastChar: Char;
  EndIndex: Integer;
  BufEnd: Integer;
  CurrLineLength: Cardinal;

  LengthLastLineShl1: Integer;
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
        Assert(CurrLine[0] <> ' ', Format('CurrChar: %d, CurrLineLength: %d',
                                          [CurrChar,CurrLineLength]));

        if CurrChar < BufEnd then
        begin
          //줄로 분해된 문장 처리하기
          if CurrLineLength > 0 then
            if NeedMultiConst then
              FGSList.AddNode(DivideIntoNode(CurrLine, FMultiConst))
            else
              FGSList.AddNode(DivideIntoNode(CurrLine));
        end
        else
        begin
          //마지막 줄 처리
          LastLine := CurrLine;
          LastChar := Buffer[BufEnd - 1];
          if (LastChar = #13) or (LastChar = #10) then
          begin
            //줄로 분해된 문장 처리하기
            if CurrLineLength > 0 then
              if NeedMultiConst then
                FGSList.AddNode(DivideIntoNode(CurrLine, FMultiConst))
              else
                FGSList.AddNode(DivideIntoNode(CurrLine));
          end;
        end;
      end;
    end;
  until BufEnd <= 0;
end;

begin
end.
