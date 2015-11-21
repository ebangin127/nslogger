unit ErrorCode.List;

interface

uses
  Generics.Collections, Windows;

type
  TErrorCodeList = class(TList<Cardinal>)
  private
    IsThereError: Boolean;
  public
    function IsAllSucceed: Boolean;
    procedure Add(const Value: Cardinal);
  end;

implementation

{ TErrorCodeList }

procedure TErrorCodeList.Add(const Value: Cardinal);
begin
  IsThereError := IsThereError or (Value > ERROR_SUCCESS);
end;

function TErrorCodeList.IsAllSucceed: Boolean;
begin
  result := IsThereError;
end;

end.
