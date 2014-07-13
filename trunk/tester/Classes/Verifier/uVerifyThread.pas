unit uVerifyThread;

interface

uses
  Vcl.ComCtrls, Vcl.StdCtrls, Classes, SysUtils, Windows;

const
  LinearRead = 32768;

type
  TVerifyThread = class(TThread)
  private
    FSrcPath, FDestPath: String;
    FVerifyMode: Boolean;
    FMaxLength: Int64;

    FProgressBar: TProgressBar;
    FStaticText: TStaticText;
  public
    constructor Create(SrcPath, DestPath: String);
    procedure Execute; override;
    procedure EndCopy;
  end;

implementation

uses uRetSel;

const
  OneBitErrUBER = 1 / 8;

type
  TBuffer = Array of UInt32;
  TTakeBuffer = record
    FSrcBuffer: TBuffer;
    FDestBuffer: TBuffer;
  end;

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TTakeBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
  public
    property Closed: Boolean read FClosed;
    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure Close;

    function TakeBuf: TTakeBuffer;
    procedure PutBuf(IsSrc: Boolean; InBuffer: TBuffer);
  end;

  TVerifyProducer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileStream: TFileStream;
    FIsSrc: Boolean;
  public
    constructor Create(IsSrc: Boolean; BufStor: TBufferStorage; Path: String);
    destructor Destroy; override;

    procedure Execute; override;
  end;

  TVerifyConsumer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileStream: TFileStream;
    FMaxLength, FCurrCmp: Int64;
    FCurrErr: Double;
    FProgressBar: TProgressBar;
    FStaticText: TStaticText;
    function GetUBER: Double;
  public
    property UBER: Double read GetUBER;
    constructor Create(BufStor: TBufferStorage; Path: String;
                       MaxLength: Integer; ProgressBar: TProgressBar;
                       StaticText: TStaticText);
    destructor Destroy; override;

    procedure Execute; override;
    procedure ApplyProgress;
  end;

{ TCopyThrd }

constructor TVerifyThread.Create(SrcPath, DestPath: String);
begin
  inherited Create(false);
  FSrcPath := SrcPath;
  FDestPath := DestPath;

  FProgressBar := fRetSel.pProgress;
  FStaticText := fRetSel.sProgress;
end;

procedure TVerifyThread.EndCopy;
begin
  fRetSel.Close;
end;

procedure TVerifyThread.Execute;
var
  dwRead: Integer;
  dwWrite: Integer;

  BufStor: TBufferStorage;
  VerifyProducer_Src: TVerifyProducer;
  VerifyProducer_Dest: TVerifyProducer;
  VerifyConsumer: TVerifyConsumer;

  FileStream: TFileStream;
begin
  inherited;

  BufStor := TBufferStorage.Create;
  dwRead := 0;
  dwWrite := 0;

  if not FVerifyMode then
  begin
    FileStream := TFileStream.Create(FSrcPath, fmOpenRead);
    FMaxLength := FileStream.Seek(0, TSeekOrigin.soEnd);
    FreeAndNil(FileStream);

    VerifyProducer_Src := TVerifyProducer.Create(true, BufStor, FSrcPath);
    VerifyProducer_Dest := TVerifyProducer.Create(false, BufStor, FDestPath);
    VerifyConsumer := TVerifyConsumer.Create(BufStor, FDestPath, FMaxLength,
                                         FProgressBar, FStaticText);

    WaitForSingleObject(VerifyConsumer.Handle, INFINITE);
    WaitForSingleObject(VerifyProducer_Dest.Handle, INFINITE);
    WaitForSingleObject(VerifyProducer_Src.Handle, INFINITE);

    FreeAndNil(VerifyConsumer);
    FreeAndNil(VerifyProducer_Dest);
    FreeAndNil(VerifyProducer_Src);
  end;

  FreeAndNil(BufStor);
  Synchronize(EndCopy);
end;

{ BufferStorage }

procedure TBufferStorage.Close;
begin
  FClosed := true;
end;

constructor TBufferStorage.Create;
begin
  FEmpty := true;
  FClosed := false;
end;

procedure TBufferStorage.SetInnerBufLength(NewLength: Integer);
begin
  SetLength(FBuffer.FSrcBuffer, NewLength);
  SetLength(FBuffer.FDestBuffer, NewLength);
end;

procedure TBufferStorage.PutBuf(IsSrc: Boolean; InBuffer: TBuffer);
var
  ReadOffset: Integer;
  MaxLength: Integer;
begin
  TMonitor.Enter(Self);
  if Length(InBuffer) = 0 then
  begin
    Close;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);

    exit;
  end;

  try
    while not FEmpty do
    begin
      TMonitor.Wait(Self, INFINITE);
    end;

    if IsSrc then
      CopyMemory(@FBuffer.FSrcBuffer[0], @InBuffer[0], Length(InBuffer))
    else
      CopyMemory(@FBuffer.FDestBuffer[0], @InBuffer[0], Length(InBuffer));

    FEmpty := False;
    TMonitor.PulseAll(Self);
  finally
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: TTakeBuffer;
begin
  TMonitor.Enter(Self);
  try
    while FEmpty do
    begin
      TMonitor.Wait(Self, INFINITE);
    end;

    if FClosed = false then
    begin
      SetLength(FOutputBuffer.FSrcBuffer, Length(FBuffer.FSrcBuffer));
      SetLength(FOutputBuffer.FDestBuffer, Length(FBuffer.FDestBuffer));

      CopyMemory(@FOutputBuffer.FSrcBuffer[0],
                 @FBuffer.FSrcBuffer[0], Length(FBuffer.FSrcBuffer));
      CopyMemory(@FOutputBuffer.FDestBuffer[0],
                 @FBuffer.FDestBuffer[0], Length(FBuffer.FDestBuffer));
    end
    else
    begin
      SetLength(FOutputBuffer.FSrcBuffer, 0);
      SetLength(FOutputBuffer.FDestBuffer, 0);
    end;

    result := FOutputBuffer;

    FEmpty := True;
    TMonitor.PulseAll(Self);
  finally
     TMonitor.Exit(Self);
  end;
end;

{ TVerifyProducer }

constructor TVerifyProducer.Create(IsSrc: Boolean; BufStor: TBufferStorage;
                                 Path: String);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FFileStream := TFileStream.Create(Path, fmOpenRead);
  FIsSrc := IsSrc;
end;

destructor TVerifyProducer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

procedure TVerifyProducer.Execute;
var
  Buffer: TBuffer;
  ReadLength: Integer;
begin
  inherited;

  FBufStor.SetInnerBufLength(LinearRead div SizeOf(UInt32));
  SetLength(Buffer, LinearRead div SizeOf(UInt32));

  repeat
    ReadLength := FFileStream.Read(Buffer[0], LinearRead);

    if ReadLength = 0 then
      SetLength(Buffer, 0);

    FBufStor.PutBuf(FIsSrc, Buffer);
  until ReadLength = 0;
end;


{ TVerifyConsumer }

procedure TVerifyConsumer.ApplyProgress;
var
  MaxMega, CurrMega: Int64;
begin
  MaxMega := FMaxLength shr 10;
  CurrMega := FCurrCmp shr 10;

  FStaticText.Caption := IntToStr(MaxMega) + 'MB / ' +
                         IntToStr(CurrMega) + 'MB / ' +
                         'UBER: ' + FormatFloat('%.20f', GetUBER) +
                         '%';
  FProgressBar.Position := (CurrMega * 100) div MaxMega;
end;

constructor TVerifyConsumer.Create(BufStor: TBufferStorage; Path: String;
                                 MaxLength: Integer; ProgressBar: TProgressBar;
                                 StaticText: TStaticText);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FCurrCmp := 0;
  FMaxLength := MaxLength;

  FProgressBar := ProgressBar;
  FStaticText := StaticText;

  FFileStream := TFileStream.Create(Path, fmOpenRead);
end;

destructor TVerifyConsumer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

function DenseBitCount(X: UInt32): Integer;
begin
  X := (X and $55555555) + ((X shr 1) and $55555555);
  X := (X and $33333333) + ((X shr 2) and $33333333);
  X := (X and $0f0f0f0f) + ((X shr 4) and $0f0f0f0f);
  X := (X and $00ff00ff) + ((X shr 8) and $00ff00ff);
  X := (X and $0000ffff) + ((X shr 16) and $0000ffff);
  Result := X;
end;

procedure TVerifyConsumer.Execute;
var
  Buffer: TTakeBuffer;
  GotLength: Integer;
  CurrBuf: Integer;
  XorResult: UInt32;
begin
  inherited;

  repeat
    Buffer := FBufStor.TakeBuf;
    GotLength := Length(Buffer.FSrcBuffer);

    for CurrBuf := 0 to GotLength - 1 do
    begin
      XorResult := Buffer.FSrcBuffer[CurrBuf] xor Buffer.FDestBuffer[CurrBuf];
      FCurrErr := FCurrErr + (DenseBitCount(XorResult) * OneBitErrUBER);
    end;

    Inc(FCurrCmp, GotLength);
  until GotLength <= 0;
end;

function TVerifyConsumer.GetUBER: Double;
begin
  exit(FCurrErr / FCurrCmp);
end;

end.
