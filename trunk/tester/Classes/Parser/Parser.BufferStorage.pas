unit Parser.BufferStorage;

interface

uses
  SysUtils, Windows,
  Parser.ReadBuffer;

const
  LinearRead = 16 shl 20;

type
  IBufferStorage = interface
    function IsClosed: Boolean;
    procedure ReadyToClose;
    function TakeBuf: IManagedReadBuffer;
    procedure PutBuf(InBuffer: IManagedReadBuffer; CurrSize: Integer;
      NeedClose: Boolean);
  end;

  TBufferStorage = class(TInterfacedObject, IBufferStorage)
  private
    FBuffer: IManagedReadBuffer;
    FEmpty: Boolean;
    FClosed: Boolean;
    FToBeClosed: Boolean;

    FCurrSize: Integer;
  public
    function IsClosed: Boolean;
    constructor Create;
    procedure ReadyToClose;
    function TakeBuf: IManagedReadBuffer;
    procedure PutBuf(InBuffer: IManagedReadBuffer; CurrSize: Integer;
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
  FClosed := false;
end;

function TBufferStorage.IsClosed: Boolean;
begin
  result := FClosed;
end;

procedure TBufferStorage.PutBuf(InBuffer: IManagedReadBuffer; CurrSize: Integer;
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
      FBuffer.SetBufferLength(CurrSize);
    end;

    FBuffer := InBuffer;
    FCurrSize := CurrSize;
  finally
    FEmpty := false;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;

function TBufferStorage.TakeBuf: IManagedReadBuffer;
begin
  if FClosed then
  begin
    result := TManagedReadBuffer.Create(0);
    exit;
  end;

  TMonitor.Enter(Self);
  try
    while FEmpty do
      TMonitor.Wait(Self, INFINITE);

    FClosed := FToBeClosed;
    result := FBuffer;
    result[FCurrSize] := #0;
  finally
    FEmpty := true;

    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;
end.
