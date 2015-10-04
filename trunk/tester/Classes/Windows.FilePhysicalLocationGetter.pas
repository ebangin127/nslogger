unit Windows.FilePhysicalLocationGetter;

interface

uses
  Generics.Collections,
  Pattern.Singleton;

type
  TPhysicalLocation = record
    CurrentLocation: Integer;
    Length: Integer;
  end;
  TPhysicalLocationList = TList<TPhysicalLocation>;
  TFilePhysicalLocationGetter = class(TSingleton<TFilePhysicalLocationGetter>)
  public
    function GetPhysicalLocation: TPhysicalLocationList;
  end;

implementation

{ TFilePhysicalLocationGetter }

function TFilePhysicalLocationGetter.GetPhysicalLocation: TPhysicalLocationList;
begin

end;

initialization
finalization
  TFilePhysicalLocationGetter.FreeSingletonInstance;
end.
