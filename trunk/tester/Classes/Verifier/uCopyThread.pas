unit uCopyThread;

interface

uses
  Vcl.ComCtrls, Vcl.StdCtrls, Classes, SysUtils, Windows;

const
  LinearRead = 16 shl 10 shl 10; // 16MB

type
  TCopyThread = class(TThread)
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

type
  TBuffer = Array of Byte;

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
    FReadyToClose: Boolean;
  public
    property Closed: Boolean read FClosed;
    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;

    function TakeBuf: TBuffer;
    procedure PutBuf(InBuffer: TBuffer; NeedClose: Boolean);
  end;

  TCopyProducer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileStream: TFileStream;
  public
    constructor Create(BufStor: TBufferStorage; Path: String);
    destructor Destroy; override;

    procedure Execute; override;
  end;

  TCopyConsumer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileStream: TFileStream;
    FMaxLength, FCurrWritten: Int64;
    FProgressBar: TProgressBar;
    FStaticText: TStaticText;
  public
    constructor Create(BufStor: TBufferStorage; Path: String;
                       MaxLength: Int64; ProgressBar: TProgressBar;
                       StaticText: TStaticText);
    destructor Destroy; override;

    procedure Execute; override;
    procedure ApplyProgress;
  end;

{ TCopyThrd }

constructor TCopyThread.Create(SrcPath, DestPath: String);
begin
  inherited Create(false);
  FSrcPath := SrcPath;
  FDestPath := DestPath;

  FProgressBar := fRetSel.pProgress;
  FStaticText := fRetSel.sProgress;
end;

procedure TCopyThread.EndCopy;
begin
  fRetSel.EndTask := true;
  fRetSel.Close;
end;

procedure TCopyThread.Execute;
var
  dwRead: Integer;
  dwWrite: Integer;

  BufStor: TBufferStorage;
  CopyProducer: TCopyProducer;
  CopyConsumer: TCopyConsumer;

  FileStream: TFileStream;
begin
  inherited;

  BufStor := TBufferStorage.Create;
  dwRead := 0;
  dwWrite := 0;

  if not FVerifyMode then
  begin
    FileStream := TFileStream.Create(FSrcPath, fmOpenRead);
    FMaxLength := FileStream.Size;
    FreeAndNil(FileStream);

    CopyProducer := TCopyProducer.Create(BufStor, FSrcPath);
    CopyConsumer := TCopyConsumer.Create(BufStor, FDestPath, FMaxLength,
                                         FProgressBar, FStaticText);

    WaitForSingleObject(CopyConsumer.Handle, INFINITE);
    WaitForSingleObject(CopyProducer.Handle, INFINITE);

    FreeAndNil(CopyProducer);
    FreeAndNil(CopyConsumer);
  end;

  FreeAndNil(BufStor);
  Synchronize(EndCopy);
end;

{ BufferStorage }

procedure TBufferStorage.ReadyToClose;
begin
  FReadyToClose := true;
end;

constructor TBufferStorage.Create;
begin
  FEmpty := true;
  FClosed := false;
  FReadyToClose := false;
end;

procedure TBufferStorage.SetInnerBufLength(NewLength: Integer);
begin
  SetLength(FBuffer, NewLength);
end;

procedure TBufferStorage.PutBuf(InBuffer: TBuffer; NeedClose: Boolean);
var
  ReadOffset: Integer;
  MaxLength: Integer;
begin
  TMonitor.Enter(Self);

  try
    while not FEmpty do
    begin
      TMonitor.Wait(Self, INFINITE);
      if FClosed then exit;
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

    CopyMemory(@FBuffer[0], @InBuffer[0], Length(InBuffer));
  finally
    FEmpty := false;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: TBuffer;
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

    SetLength(FOutputBuffer, Length(FBuffer));
    CopyMemory(@FOutputBuffer[0], @FBuffer[0], Length(FBuffer));

    result := FOutputBuffer;

    if FReadyToClose then
      FClosed := true;
  finally
    FEmpty := true;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

{ TCopyProducer }

constructor TCopyProducer.Create(BufStor: TBufferStorage; Path: String);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FFileStream := TFileStream.Create(Path, fmOpenRead);
end;

destructor TCopyProducer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

procedure TCopyProducer.Execute;
var
  Buffer: TBuffer;
  ReadLength: Integer;
begin
  inherited;

  FBufStor.SetInnerBufLength(LinearRead);
  SetLength(Buffer, LinearRead);

  repeat
    ReadLength := FFileStream.Read(Buffer[0], LinearRead);

    if FFileStream.Position = FFileStream.Size then
      SetLength(Buffer, ReadLength);

    FBufStor.PutBuf(Buffer, FFileStream.Position = FFileStream.Size);
  until ReadLength = 0;
end;


{ TCopyConsumer }

procedure TCopyConsumer.ApplyProgress;
var
  MaxMega, CurrMega: Int64;
begin
  MaxMega := FMaxLength shr 20;
  CurrMega := FCurrWritten shr 20;

  FStaticText.Caption := IntToStr(MaxMega) + 'MB / ' +
                         IntToStr(CurrMega) + 'MB';
  FProgressBar.Position := (CurrMega * 100) div MaxMega;
end;

constructor TCopyConsumer.Create(BufStor: TBufferStorage; Path: String;
                                 MaxLength: Int64; ProgressBar: TProgressBar;
                                 StaticText: TStaticText);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FCurrWritten := 0;
  FMaxLength := MaxLength;

  FProgressBar := ProgressBar;
  FStaticText := StaticText;

  FFileStream := TFileStream.Create(Path, fmOpenWrite or fmCreate);
end;

destructor TCopyConsumer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

procedure TCopyConsumer.Execute;
const
  FiftyMB = 50 shl 10;
  Period = FiftyMB div LinearRead;
var
  Buffer: TBuffer;
  ReadLength: Integer;
  GotLength: Integer;
  WrittenLength: Integer;
  CurrNum: Integer;
begin
  inherited;

  CurrNum := Period;
  repeat
    Buffer := FBufStor.TakeBuf;
    GotLength := Length(Buffer);
    if Length(Buffer) > 0 then
    begin
      WrittenLength := FFileStream.Write(Buffer[0], GotLength);
    end;
    Inc(FCurrWritten, WrittenLength);

    if CurrNum = 0 then
    begin
      Synchronize(ApplyProgress);
      CurrNum := Period;
    end
    else
      Dec(CurrNum);
  until FBufStor.Closed;
end;
end.
