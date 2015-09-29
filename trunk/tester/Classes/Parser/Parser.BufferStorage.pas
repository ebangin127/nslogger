unit Parser.BufferStorage;

interface

uses
  SysUtils, Windows;

const
  LinearRead = 16 shl 20;

type
  TMTBuffer = Array of Char;

  IBufferStorage = interface
    function IsClosed: Boolean;
    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;
    function TakeBuf: TMTBuffer;
    procedure PutBuf(InBuffer: TMTBuffer; CurrSize: Integer;
      NeedClose: Boolean);
  end;

  TBufferStorage = class(TInterfacedObject, IBufferStorage)
  private
    FBuffer, FOutputBuffer: TMTBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
    FToBeClosed: Boolean;
    FHalfInByte, FHalfInArray: Integer;

    FCurrSize: Integer;
    FFirstCopy: Boolean;
  public
    function IsClosed: Boolean;
    constructor Create;
    procedure SetInnerBufLength(NewLength: Integer);
    procedure ReadyToClose;
    function TakeBuf: TMTBuffer;
    procedure PutBuf(InBuffer: TMTBuffer; CurrSize: Integer;
      NeedClose: Boolean);
  end;

implementation

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

function TBufferStorage.IsClosed: Boolean;
begin
  result := FClosed;
end;

procedure TBufferStorage.PutBuf(InBuffer: TMTBuffer; CurrSize: Integer;
  NeedClose: Boolean);
begin
  if CurrSize = 0 then
  begin
    FClosed := true;
    FEmpty := false;
    exit;
  end;

  TMonitor.Enter(Self);
  try
    while not FEmpty do
      TMonitor.Wait(Self, INFINITE);

    if NeedClose then
    begin
      ReadyToClose;
      SetLength(FBuffer, CurrSize);
    end;

    CopyMemory(@FBuffer[0], @InBuffer[0], CurrSize * SizeOf(Char));
    FCurrSize := CurrSize;
  finally
    FEmpty := false;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: TMTBuffer;
var
  NewLength: Integer;
begin
  if FClosed then
  begin
    SetLength(result, 0);
    exit;
  end;

  TMonitor.Enter(Self);
  try
    while FEmpty do
      TMonitor.Wait(Self, INFINITE);
    NewLength := FCurrSize * SizeOf(Char);

    if Length(FOutputBuffer) <> FCurrSize + 1 then
      SetLength(FOutputBuffer, FCurrSize + 1);
    CopyMemory(@FOutputBuffer[0], @FBuffer[0], NewLength);
    FOutputBuffer[FCurrSize] := #0;
    FClosed := FToBeClosed;
    result := FOutputBuffer;
  finally
    FEmpty := true;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;
end.
