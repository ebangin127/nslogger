unit Device.SMART.Diff;

interface

uses
  Classes,
  Pattern.Singleton, Device.SMART.List;

type
  TSMARTDiff = class(TSingleton<TSMARTDiff>)
    function CompareSMART(const LSide, RSide: TSMARTValueList): TSMARTValueList;
  end;

implementation

{ TSMARTDiff }

function TSMARTDiff.CompareSMART(const LSide, RSide: TSMARTValueList):
  TSMARTValueList;
var
  CurrentIndex: Integer;
begin
  result := TSMARTValueList.Create;
  for CurrentIndex := 0 to RSide.Count - 1 do
  begin
    if CurrentIndex > LSide.Count - 1 then
      result.Add(RSide[CurrentIndex])
    else if LSide[CurrentIndex] <> RSide[CurrentIndex] then
      result.Add(RSide[CurrentIndex] - LSide[CurrentIndex]);
  end;
end;

initialization
finalization
  TSMARTDiff.FreeSingletonInstance;
end.
