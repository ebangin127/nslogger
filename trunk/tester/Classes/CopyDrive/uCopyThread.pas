unit uCopyThread;

interface

uses Classes, SysUtils, Windows;

const
  LinearRead = 32768;

{$R *.res}

type
  TBuffer = Array of Byte;

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
  public
    property Closed: Boolean read FClosed;
    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure Close;

    function TakeBuf: TBuffer;
    procedure PutBuf(InBuffer: TBuffer);
  end;

  TCopyThread = class(TThread)
  private
    FOrigHandle, FDestHandle: THandle;
    FDLLHandle: THandle;
    FWriteHandle: THandle;

    FVerifyMode: Boolean;
    SSDCopy: TssdCopy;
    SSDDriveCompare: TssdDriveCompare;
    procedure SetCmpHandles(WriteHandle: THandle);
  public
    procedure SetHandles(OrigHandle, DestHandle, DLLHandle: THandle); overload;
    procedure SetHandles(OrigHandle, DestHandle, DLLHandle,
                         WriteHandle: THandle); overload;
    procedure Execute; override;
    procedure EndCopy;
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
    FFileStream: TFileStream;
  public
    constructor Create(BufStor: TBufferStorage; Path: String);
    destructor Destroy; override;

    procedure Execute; override;
  end;

implementation

procedure makeJEDECListAndFix(SrcPath: PChar; DestPath: PChar);
var
  BufStor: TBufferStorage;
  Producer: TProducer;
  Consumer: TConsumer;
begin
  BufStor := TBufferStorage.Create;
  Producer := TProducer.Create(BufStor, SrcPath);
  Consumer := TConsumer.Create(BufStor, DestPath);

  WaitForSingleObject(Consumer.Handle, INFINITE);
  WaitForSingleObject(Producer.Handle, INFINITE);

  FreeAndNil(Consumer);
  FreeAndNil(Producer);
  FreeAndNil(BufStor);
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
  SetLength(FBuffer, NewLength);
end;

procedure TBufferStorage.PutBuf(InBuffer: TBuffer);
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

    CopyMemory(@FBuffer[0], @InBuffer[0], Length(InBuffer));

    FEmpty := False;
    TMonitor.PulseAll(Self);
  finally
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

    if FClosed = false then
    begin
      SetLength(FOutputBuffer, Length(FBuffer));
      CopyMemory(@FOutputBuffer[0], @FBuffer[0], Length(FBuffer));
      FOutputBuffer[Length(FOutputBuffer) - 1] := #0;
    end
    else
    begin
      SetLength(FOutputBuffer, 0);
    end;

    result := FOutputBuffer;

    FEmpty := True;
    TMonitor.PulseAll(Self);
  finally
     TMonitor.Exit(Self);
  end;
end;

{ TCopyThrd }

procedure TCopyThread.EndCopy;
begin
  fRetSel.Close;
end;

procedure TCopyThread.Execute;
var
  dwRead: Integer;
  dwWrite: Integer;
begin
  inherited;

  dwRead := 0;
  dwWrite := 0;

  if not FVerifyMode then SSDCopy(FOrigHandle, FDestHandle, @dwRead, @dwWrite)
  else SSDDriveCompare(FOrigHandle, FDestHandle, FWriteHandle,
                       @dwRead, @dwWrite);
  Synchronize(EndCopy);
end;

procedure TCopyThread.SetHandles(OrigHandle, DestHandle, DLLHandle: THandle);
begin
  FOrigHandle := OrigHandle;
  FDestHandle := DestHandle;
  FDLLHandle := DLLHandle;

  @SSDCopy := GetProcAddress(FDLLHandle, 'ssdCopy');

  FVerifyMode := false;
end;

procedure TCopyThread.SetCmpHandles(WriteHandle: THandle);
begin
  FWriteHandle := WriteHandle;
end;

procedure TCopyThread.SetHandles(OrigHandle, DestHandle, DLLHandle,
                                  WriteHandle: THandle);
begin
  SetHandles(OrigHandle, DestHandle, DLLHandle);
  SetCmpHandles(WriteHandle);

  @SSDDriveCompare := GetProcAddress(FDLLHandle, 'ssdDriveCompare');

  FVerifyMode := true;
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
  Buffer: TBuffer;
  ReadLength: Integer;
begin
  inherited;

  FBufStor.SetInnerBufLength(LinearRead);
  SetLength(Buffer, LinearRead);

  repeat
    ReadLength := FFileStream.Read(Buffer[0], LinearRead);

    if ReadLength = 0 then
      SetLength(Buffer, 0);

    FBufStor.PutBuf(Buffer);
  until ReadLength = 0;
end;


{ TConsumer }

constructor TConsumer.Create(BufStor: TBufferStorage; Path: String);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FFileStream := TFileStream.Create(Path, fmOpenRead);
end;

destructor TConsumer.Destroy;
begin
  FreeAndNil(FFileStream);
  inherited;
end;

procedure TConsumer.Execute;
var
  Buffer: TBuffer;
  ReadLength: Integer;
  GotLength: Integer;
  WrittenLength: Integer;
begin
  inherited;

  repeat
    Buffer := FBufStor.TakeBuf;
    GotLength := Length(Buffer);
    if Length(Buffer) > 0 then
    begin
      WrittenLength := FFileStream.Write(Buffer[0], GotLength);
    end;
  until (GotLength <= 0) or (WrittenLength = 0);
end;
end.
