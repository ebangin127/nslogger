unit Overlapped;

interface

type
  IOverlapped = interface
    function WaitAndGetErrorCode: Cardinal;
  end;

  TOverlapped = class abstract(TInterfacedObject, IOverlapped)
  public
    function WaitAndGetErrorCode: Cardinal; virtual; abstract;
  end;

implementation

end.
