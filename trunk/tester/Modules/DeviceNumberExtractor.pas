unit DeviceNumberExtractor;

interface

uses SysUtils, uOSFile;

function ExtractDeviceNumber(const Input: String): String;

implementation

type
  TTempOSFile = class(TOSFile);

function ExtractDeviceNumber(const Input: String): String;
var
  TempOSFile: TTempOSFile;
begin
  TempOSFile := TTempOSFile.Create(Input);
  result := TempOSFile.GetPathOfFileAccessingWithoutPrefix;
  FreeAndNil(TempOSFile);
end;

end.
