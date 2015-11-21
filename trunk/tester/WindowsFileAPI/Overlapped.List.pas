unit Overlapped.List;

interface

uses
  Generics.Collections,
  ErrorCode.List, Overlapped;

type
  TOverlappedList = class(TList<IOverlapped>)
  public
    function WaitAndGetErrorCode: TErrorCodeList;
  end;

implementation

{ TOverlappedList }

function TOverlappedList.WaitAndGetErrorCode: TErrorCodeList;
var
  CurrentOverlapped: IOverlapped;
begin
  result := TErrorCodeList.Create;
  for CurrentOverlapped in self do
    result.Add(CurrentOverlapped.WaitAndGetErrorCode);
end;

end.
