unit uCopyThread;

interface

uses
  Vcl.ComCtrls, Vcl.StdCtrls, Classes, Dialogs, SysUtils, Windows,
  System.UITypes,
  DeviceNumberExtractor, Device.PhysicalDrive;

const
  LinearRead = 1 shl 10 shl 10; // 1MB - The max native read
  TimeoutInMillisec = 10000;

type
  TCopyThread = class(TThread)
  private
    FSrcPath, FDestPath: String;
    FMaxLength: Int64;
    FError: Boolean;

    FProgressBar: TProgressBar;
    FStaticText: TStaticText;
  public
    property IsError: Boolean read FError;
    constructor Create(SrcPath, DestPath: String);
    procedure Execute; override;
    procedure EndCopy;
  end;

implementation

uses Form.Retention;

type
  TBuffer = Array of Byte;

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
    FReadyToClose: Boolean;
    FError: Boolean;
  public                
    property IsError: Boolean read FError;
    property Closed: Boolean read FClosed;
    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;
    procedure Error;

    function TakeBuf: TBuffer;
    procedure PutBuf(InBuffer: TBuffer; NeedClose: Boolean);
  end;

  TCopyProducer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FFileHandle: THandle;
    FMaxLength: Int64;
  public
    constructor Create(BufStor: TBufferStorage; Path: String;
                       MaxLength: Int64);
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

  FProgressBar := fRetention.pProgress;
  FStaticText := fRetention.sProgress;
end;

procedure TCopyThread.EndCopy;
begin
  if IsError then
    MessageDlg('오류가 발생하여 작업을 중단하였습니다',
               mtError, [mbOK], 0);

  fRetention.EndTask := true;
  fRetention.Close;
end;

procedure TCopyThread.Execute;
var
  BufStor: TBufferStorage;
  CopyProducer: TCopyProducer;
  CopyConsumer: TCopyConsumer;

  PhysicalDrive: IPhysicalDrive;
begin
  inherited;

  BufStor := TBufferStorage.Create;

  PhysicalDrive :=
    TPhysicalDrive.Create(FSrcPath);
  FMaxLength := PhysicalDrive.IdentifyDeviceResult.UserSizeInKB * 1024;
    //Unit: Bytes

  CopyProducer := TCopyProducer.Create(BufStor, FSrcPath, FMaxLength);
  CopyConsumer := TCopyConsumer.Create(BufStor, FDestPath, FMaxLength,
                                       FProgressBar, FStaticText);

  FError := BufStor.IsError;

  WaitForSingleObject(CopyConsumer.Handle, INFINITE);
  WaitForSingleObject(CopyProducer.Handle, INFINITE);

  FreeAndNil(CopyProducer);
  FreeAndNil(CopyConsumer);

  FreeAndNil(BufStor);
  Queue(EndCopy);
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
  FError := false;
end;

procedure TBufferStorage.SetInnerBufLength(NewLength: Integer);
begin
  SetLength(FBuffer, NewLength);
end;

procedure TBufferStorage.Error;
begin
  FError := true;
end;

procedure TBufferStorage.PutBuf(InBuffer: TBuffer; NeedClose: Boolean);
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
  if FError then
    exit(nil);

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

constructor TCopyProducer.Create(BufStor: TBufferStorage; Path: String;
                                 MaxLength: Int64);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FFileHandle := CreateFile(PChar(Path), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_FLAG_NO_BUFFERING, 0);
  FMaxLength := MaxLength;
end;

destructor TCopyProducer.Destroy;
begin
  CloseHandle(FFileHandle);
  inherited;
end;

procedure TCopyProducer.Execute;
var
  Buffer: TBuffer;
  ReadLength: DWORD;
  CurrPos: LARGE_INTEGER;
  Result: Boolean;
begin
  inherited;
  FBufStor.SetInnerBufLength(LinearRead);
  SetLength(Buffer, LinearRead);
  CurrPos.QuadPart := 0;

  repeat
    SetFilePointer(FFileHandle, CurrPos.LowPart, @CurrPos.HighPart, FILE_BEGIN);
    Result :=
      ReadFile(FFileHandle, Buffer[0], LinearRead, ReadLength, nil);

    if CurrPos.QuadPart + ReadLength >= FMaxLength then
    begin
      ReadLength := FMaxLength - CurrPos.QuadPart;
      SetLength(Buffer, ReadLength);
    end
    else if (Result) and (LinearRead > ReadLength) then
      SetLength(Buffer, ReadLength);

    if Result = false then
    begin
      SetLength(Buffer, 0);
    end;

    Inc(CurrPos.QuadPart, ReadLength);
    FBufStor.PutBuf(Buffer, CurrPos.QuadPart >= FMaxLength);
  until CurrPos.QuadPart >= FMaxLength;
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
  GotLength: Integer;
  WrittenLength: Integer;
  CurrNum: Integer;
begin
  inherited;

  CurrNum := Period;
  repeat
    Buffer := FBufStor.TakeBuf;
    if Buffer = nil then
      exit;

    WrittenLength := 0;
    GotLength := Length(Buffer);
    if Length(Buffer) > 0 then
    begin
      WrittenLength := FFileStream.Write(Buffer[0], GotLength);
    end;
    Inc(FCurrWritten, WrittenLength);

    if CurrNum = 0 then
    begin
      Queue(ApplyProgress);
      CurrNum := Period;
    end
    else
      Dec(CurrNum);
  until FBufStor.Closed;
end;
end.
