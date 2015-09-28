unit uVerifyThread;

interface

uses
  Vcl.ComCtrls, Vcl.StdCtrls, Classes, SysUtils, Windows,
  uStrFunctions, uLegacyReadCommand, Device.PhysicalDrive;

const
  LinearRead = 1 shl 10 shl 10; // 1MB - The max native read

type
  TVerifyThread = class(TThread)
  private
    FSrcPath, FDestPath: String;
    FMaxLength: Int64;
    FUBER: Double;

    FProgressBar: TProgressBar;
    FStaticText: TStaticText;
  public
    constructor Create(SrcPath, DestPath: String);
    procedure Execute; override;
    procedure EndVerify;
  end;

implementation

uses Form.Retention;

const
  OneBitErrUBER = 1 / 8;

type
  TBuffer = Array of UInt32;
  TTakeBuffer = record
    FSrcBuffer: TBuffer;
    FDestBuffer: TBuffer;
  end;

  TCurrTurn = (ctSrc, ctDest, ctConsumer);

  TBufferStorage = class
  private
    FBuffer, FOutputBuffer: TTakeBuffer;
    FCurrTurn: TCurrTurn;
    FReadyToClose: Boolean;
    FClosed: Boolean;
  public
    property Closed: Boolean read FClosed;
    constructor Create;

    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;

    function TakeBuf: TTakeBuffer;
    procedure PutBuf(IsSrc: Boolean; InBuffer: TBuffer; NeedClose: Boolean);
  end;

  TVerifyProducer = class(TThread)
  private
    FBufStor: TBufferStorage;

    FFileStream: TFileStream;
    FFileHandle: THandle;
    FMaxLength: Int64;

    FIsSrc: Boolean;
    FIsDrive: Boolean;
  public
    constructor Create(IsSrc: Boolean; BufStor: TBufferStorage; Path: String;
                       MaxLength: Int64);
    destructor Destroy; override;

    procedure Execute; override;
  end;

  TVerifyConsumer = class(TThread)
  private
    FBufStor: TBufferStorage;
    FMaxLength, FCurrCmp: Int64;
    FCurrErr: Double;
    FProgressBar: TProgressBar;
    FStaticText: TStaticText;

    function GetUBER: Double;
  public
    property UBER: Double read GetUBER;
    constructor Create(BufStor: TBufferStorage; Path: String;
                       MaxLength: Int64; ProgressBar: TProgressBar;
                       StaticText: TStaticText);

    procedure Execute; override;
    procedure ApplyProgress;
  end;

{ TVerifyThrd }

constructor TVerifyThread.Create(SrcPath, DestPath: String);
begin
  inherited Create(false);
  FSrcPath := SrcPath;
  FDestPath := DestPath;

  FProgressBar := fRetention.pProgress;
  FStaticText := fRetention.sProgress;
end;

procedure TVerifyThread.EndVerify;
begin
  fRetention.EndTask := true;
  fRetention.UBER := FUBER;
  fRetention.Close;
end;

procedure TVerifyThread.Execute;
const
  PhyDrv = '\\.\PhysicalDrive';
var
  DestMaxLength: Integer;

  BufStor: TBufferStorage;
  VerifyProducer_Src: TVerifyProducer;
  VerifyProducer_Dest: TVerifyProducer;
  VerifyConsumer: TVerifyConsumer;

  PhysicalDrive: IPhysicalDrive;
begin
  inherited;

  BufStor := TBufferStorage.Create;

  PhysicalDrive := TPhysicalDrive.Create(FSrcPath);
  FMaxLength := PhysicalDrive.IdentifyDeviceResult.UserSizeInKB * 1024;
    //Unit: Bytes
  if Copy(FDestPath, 0, Length(PhyDrv)) = PhyDrv then
  begin
    DestMaxLength := PhysicalDrive.IdentifyDeviceResult.UserSizeInKB * 1024;
      //Unit: Bytes
  end
  else
    DestMaxLength := 0;

  VerifyProducer_Src := TVerifyProducer.Create(true, BufStor, FSrcPath,
                                               FMaxLength);
  VerifyProducer_Dest := TVerifyProducer.Create(false, BufStor, FDestPath,
                                                DestMaxLength);
  VerifyConsumer := TVerifyConsumer.Create(BufStor, FDestPath, FMaxLength,
                                       FProgressBar, FStaticText);

  WaitForSingleObject(VerifyConsumer.Handle, INFINITE);
  WaitForSingleObject(VerifyProducer_Dest.Handle, INFINITE);
  WaitForSingleObject(VerifyProducer_Src.Handle, INFINITE);

  FUBER := VerifyConsumer.UBER;

  FreeAndNil(VerifyConsumer);
  FreeAndNil(VerifyProducer_Dest);
  FreeAndNil(VerifyProducer_Src);

  FreeAndNil(BufStor);
  Synchronize(EndVerify);
end;

{ TVerifyProducer }

constructor TVerifyProducer.Create(IsSrc: Boolean; BufStor: TBufferStorage;
                                   Path: String; MaxLength: Int64);
const
  PhyDrv = '\\.\PhysicalDrive';
begin
  inherited Create(false);
  FBufStor := BufStor;

  FIsDrive := Copy(Path, 0, Length(PhyDrv)) = PhyDrv;
  if FIsDrive then
  begin
    FFileHandle := CreateFile(PChar(Path),
                              GENERIC_READ or GENERIC_WRITE,
                              FILE_SHARE_READ or FILE_SHARE_WRITE,
                              nil,
                              OPEN_EXISTING,
                              FILE_FLAG_NO_BUFFERING,
                              0);
    FFileStream := nil;
  end
  else
  begin
    FFileStream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
    FFileHandle := 0;
  end;
  FIsSrc := IsSrc;
  FMaxLength := MaxLength;
end;

destructor TVerifyProducer.Destroy;
begin
  if FFileHandle <> 0 then
    CloseHandle(FFileHandle);
  if FFileStream <> nil then
    FreeAndNil(FFileStream);
  inherited;
end;

procedure TVerifyProducer.Execute;
var
  Buffer: TBuffer;
  ReadLength: Integer;
  CurrPos: Int64;
  OvlpResult: Boolean;
  IsEnd: Boolean;
begin
  inherited;
  FBufStor.SetInnerBufLength(LinearRead div SizeOf(UInt32));
  SetLength(Buffer, LinearRead div SizeOf(UInt32));
  CurrPos := 0;

  repeat
    if FIsDrive then
    begin
      OvlpResult := true;
      ReadLength := ReadSector(FFileHandle, CurrPos shr 9, @Buffer[0]);
      if ReadLength = -1 then
      begin
        OvlpResult := false;
        ReadLength := 0;
      end;

      if CurrPos + ReadLength > FMaxLength then
      begin
        ReadLength := FMaxLength - CurrPos;
        SetLength(Buffer, ReadLength div SizeOf(UInt32));
      end
      else if (OvlpResult) and (LinearRead > ReadLength)then
        SetLength(Buffer, ReadLength div SizeOf(UInt32));

      if OvlpResult = false then
      begin
        SetLength(Buffer, 0);
      end;

      Inc(CurrPos, ReadLength);
      FBufStor.PutBuf(FIsSrc, Buffer, CurrPos >= FMaxLength);
      IsEnd := CurrPos >= FMaxLength;
    end
    else
    begin
      ReadLength := FFileStream.Read(Buffer[0], LinearRead);

      if FFileStream.Position = FFileStream.Size then
        SetLength(Buffer, ReadLength div SizeOf(UInt32));

      FBufStor.PutBuf(FIsSrc, Buffer, FFileStream.Position = FFileStream.Size);
      IsEnd := FFileStream.Position = FFileStream.Size;
    end;
  until IsEnd;
end;

{ BufferStorage }

procedure TBufferStorage.ReadyToClose;
begin
  FReadyToClose := true;
end;

constructor TBufferStorage.Create;
begin
  FCurrTurn := ctSrc;
  FClosed := false;
  FReadyToClose := false;
end;

procedure TBufferStorage.SetInnerBufLength(NewLength: Integer);
begin
  SetLength(FBuffer.FSrcBuffer, NewLength);
  SetLength(FBuffer.FDestBuffer, NewLength);
end;

procedure TBufferStorage.PutBuf(IsSrc: Boolean; InBuffer: TBuffer; NeedClose: Boolean);
var
  MyTurn: TCurrTurn;
begin
  TMonitor.Enter(Self);

  try
    if IsSrc then
      MyTurn := ctSrc
    else
      MyTurn := ctDest;

    while FCurrTurn <> MyTurn do
    begin
      TMonitor.Wait(Self, INFINITE);
      if FClosed then exit;
    end;

    if Length(InBuffer) = 0 then
    begin
      FClosed := true;

      if FCurrTurn = ctSrc then
        FCurrTurn := ctDest
      else
        FCurrTurn := ctConsumer;

      TMonitor.PulseAll(Self);
      TMonitor.Exit(Self);

      exit;
    end
    else if NeedClose and IsSrc then
    begin
      ReadyToClose;

      if IsSrc then
        SetLength(FBuffer.FSrcBuffer, Length(InBuffer))
      else
        SetLength(FBuffer.FDestBuffer, Length(InBuffer));
    end;

    if IsSrc then
      CopyMemory(@FBuffer.FSrcBuffer[0], @InBuffer[0], Length(InBuffer)
                                                       * SizeOf(UInt32))
    else
      CopyMemory(@FBuffer.FDestBuffer[0], @InBuffer[0], Length(InBuffer)
                                                       * SizeOf(UInt32));
  finally
    if FCurrTurn = ctSrc then
      FCurrTurn := ctDest
    else
      FCurrTurn := ctConsumer;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: TTakeBuffer;
begin
  TMonitor.Enter(Self);
  try
    while FCurrTurn <> ctConsumer do
    begin
      TMonitor.Wait(Self, INFINITE);
    end;

    if FClosed then
    begin
      SetLength(FOutputBuffer.FSrcBuffer, 0);
      SetLength(FOutputBuffer.FDestBuffer, 0);
      exit(FOutputBuffer);
    end;

    if FClosed = false then
    begin
      SetLength(FOutputBuffer.FSrcBuffer, Length(FBuffer.FSrcBuffer));
      SetLength(FOutputBuffer.FDestBuffer, Length(FBuffer.FDestBuffer));

      CopyMemory(@FOutputBuffer.FSrcBuffer[0],
                 @FBuffer.FSrcBuffer[0], Length(FBuffer.FSrcBuffer)
                                         * SizeOf(UInt32));
      CopyMemory(@FOutputBuffer.FDestBuffer[0],
                 @FBuffer.FDestBuffer[0], Length(FBuffer.FDestBuffer)
                                          * SizeOf(UInt32));
    end
    else
    begin
      SetLength(FOutputBuffer.FSrcBuffer, 0);
      SetLength(FOutputBuffer.FDestBuffer, 0);
    end;

    result := FOutputBuffer;

    if FReadyToClose then
      FClosed := true;
  finally
    FCurrTurn := ctSrc;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

{


{ TVerifyConsumer }

procedure TVerifyConsumer.ApplyProgress;
var
  MaxMega, CurrMega: Int64;
begin
  MaxMega := FMaxLength shr 20;
  CurrMega := FCurrCmp shr 20;

  FStaticText.Caption := IntToStr(MaxMega) + 'MB / ' +
                         IntToStr(CurrMega) + 'MB / ' +
                         'UBER: ' + FloatToStr(GetUBER);
  FProgressBar.Position := (CurrMega * 100) div MaxMega;
end;

constructor TVerifyConsumer.Create(BufStor: TBufferStorage; Path: String;
                                 MaxLength: Int64; ProgressBar: TProgressBar;
                                 StaticText: TStaticText);
begin
  inherited Create(false);
  FBufStor := BufStor;
  FCurrCmp := 0;
  FMaxLength := MaxLength;

  FProgressBar := ProgressBar;
  FStaticText := StaticText;
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
const
  Period = 4;
var
  Buffer: TTakeBuffer;
  GotLength: Integer;
  CurrBuf: Integer;
  XorResult: UInt32;
  CurrNum: Integer;
begin
  inherited;

  CurrNum := Period;
  repeat
    Buffer := FBufStor.TakeBuf;
    GotLength := Length(Buffer.FSrcBuffer);

    for CurrBuf := 0 to GotLength - 1 do
    begin
      XorResult := Buffer.FSrcBuffer[CurrBuf] xor Buffer.FDestBuffer[CurrBuf];
      FCurrErr := FCurrErr + (DenseBitCount(XorResult) * OneBitErrUBER);
    end;

    Inc(FCurrCmp, GotLength * SizeOf(UInt32));

    if CurrNum = 0 then
    begin
      Synchronize(ApplyProgress);
      CurrNum := Period;
    end
    else
      Dec(CurrNum);
  until FBufStor.Closed;
end;

function TVerifyConsumer.GetUBER: Double;
begin
  exit(FCurrErr / FCurrCmp);
end;

end.
