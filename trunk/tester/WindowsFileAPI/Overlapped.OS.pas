unit Overlapped.OS;

interface

uses
  SysUtils, Windows,
  Overlapped;

type
  TOSOverlapped = class(TOverlapped)
  private
    FHandle: THandle;
    FOverlapped: _OVERLAPPED;
  public
    constructor Create(const Handle: THandle; const Overlapped: _OVERLAPPED);
    destructor Destroy; override;
    function WaitAndGetErrorCode: Cardinal; override;
  end;

implementation

{ TOSOverlapped }

constructor TOSOverlapped.Create(const Handle: THandle;
  const Overlapped: _OVERLAPPED);
begin
  FHandle := Handle;
  FOverlapped := Overlapped;
end;

destructor TOSOverlapped.Destroy;
begin
  if FOverlapped.hEvent = 0 then
  begin
    inherited;
    exit;
  end;

  WaitAndGetErrorCode;
  CloseHandle(FOverlapped.hEvent);
  inherited;
end;

function TOSOverlapped.WaitAndGetErrorCode: Cardinal;
const
  WaitForCompletion = true;
var
  NumberOfBytesTransferred: DWORD;
begin
  result := ERROR_SUCCESS;
  if not GetOverlappedResult(FHandle, FOverlapped, NumberOfBytesTransferred,
    WaitForCompletion) then
      result := GetLastError;

  CloseHandle(FOverlapped.hEvent);
  FOverlapped.hEvent := 0;
end;

end.
