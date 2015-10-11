unit Parser.BufferStorage;

interface

uses
  SysUtils, Windows, Generics.Collections,
  Parser.ReadBuffer;

const
  LinearRead = 8 shl 20;

type
  IBufferStorage = interface
    function IsClosed: Boolean;
    procedure ReadyToClose;
    function TakeBuf: IManagedReadBuffer;
    procedure PutBuf(const InBuffer: IManagedReadBuffer;
      const CurrSize: Integer; const NeedClose: Boolean);
  end;

  TBufferStorage = class(TInterfacedObject, IBufferStorage)
  private
    FBuffer: TQueue<IManagedReadBuffer>;
    FClosed: Boolean;
    FToBeClosed: Boolean;
  public
    function IsClosed: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure ReadyToClose;
    function TakeBuf: IManagedReadBuffer;
    procedure PutBuf(const InBuffer: IManagedReadBuffer;
      const CurrSize: Integer; const NeedClose: Boolean);
  end;

implementation

{ BufferStorage }

procedure TBufferStorage.ReadyToClose;
begin
  FToBeClosed := true;
end;

constructor TBufferStorage.Create;
begin
  FBuffer := TQueue<IManagedReadBuffer>.Create;
  FClosed := false;
end;

destructor TBufferStorage.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited;
end;

function TBufferStorage.IsClosed: Boolean;
begin
  result := FClosed;
end;

procedure TBufferStorage.PutBuf(const InBuffer: IManagedReadBuffer;
  const CurrSize: Integer; const NeedClose: Boolean);
begin
  if CurrSize = 0 then
  begin
    FClosed := true;
    exit;
  end;

  TMonitor.Enter(Self);
  try
    while FBuffer.Count = 1 do
      TMonitor.Wait(Self, INFINITE);

    if NeedClose then
      ReadyToClose;

    InBuffer.SetBufferLength(CurrSize + 1);
    InBuffer[CurrSize] := #0;
    FBuffer.Enqueue(InBuffer);
  finally
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
    while FBuffer.Count = 0 do
      TMonitor.Wait(Self, INFINITE);

    result := FBuffer.Dequeue;

    if FBuffer.Count = 0 then
      FClosed := FToBeClosed;
  finally
    TMonitor.PulseAll(Self);
    TMonitor.Exit(Self);
  end;
end;
end.
