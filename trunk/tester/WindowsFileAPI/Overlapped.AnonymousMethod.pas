unit Overlapped.AnonymousMethod;

interface

uses
  Classes, SysUtils, Threading, Windows,
  Overlapped;

type
  TFunctionReturnsErrorCode = reference to function: Cardinal;
  TAnonymousMethodOverlapped = class(TOverlapped)
  private
    FAnonymousFunctionToLoad: TFunctionReturnsErrorCode;
    FAsynchronousTask: ITask;
    FErrorCode: Cardinal;
  public
    constructor Create(
      const AnonymousFunctionToLoad: TFunctionReturnsErrorCode);
    destructor Destroy; override;
    function WaitAndGetErrorCode: Cardinal; override;
  end;

implementation

{ TAnonymousMethodOverlapped }

constructor TAnonymousMethodOverlapped.Create(
  const AnonymousFunctionToLoad: TFunctionReturnsErrorCode);
begin
  FAnonymousFunctionToLoad := AnonymousFunctionToLoad;
  FAsynchronousTask := TTask.Run(procedure
    begin
      FErrorCode := FAnonymousFunctionToLoad;
    end);
end;

destructor TAnonymousMethodOverlapped.Destroy;
begin
  if FAsynchronousTask.Status <> TTaskStatus.Completed then
    WaitAndGetErrorCode;
end;

function TAnonymousMethodOverlapped.WaitAndGetErrorCode: Cardinal;
begin
  FAsynchronousTask.Wait(INFINITE);
  result := FErrorCode;
end;


end.
