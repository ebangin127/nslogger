unit SaveFile.SettingForm;

interface

uses
  SaveFile;

type
  TSaveFileForSettingForm = class
  private
    SaveFile: TSaveFile;
  public
    function GetDiskNumber: Integer;
    function GetModel: String;
    function GetSerial: String;
    function GetTBWToRetention: Int64;

    constructor Create(const SaveFileToOpen: TSaveFile);
    destructor Destroy; override;
  end;
implementation

{ TSaveFileForSettingForm }

constructor TSaveFileForSettingForm.Create(const SaveFileToOpen: TSaveFile);
begin
  SaveFile := SaveFileToOpen;
end;

destructor TSaveFileForSettingForm.Destroy;
begin
  SaveFile.Free;
  inherited;
end;

function TSaveFileForSettingForm.GetDiskNumber: Integer;
begin
  result := SaveFile.LoadInteger('Target', 'DiskNumber');
end;

function TSaveFileForSettingForm.GetModel: String;
begin
  result := SaveFile.LoadString('Target', 'Model');
end;

function TSaveFileForSettingForm.GetSerial: String;
begin
  result := SaveFile.LoadString('Target', 'Serial');
end;

function TSaveFileForSettingForm.GetTBWToRetention: Int64;
begin
  result := SaveFile.LoadInt64('TBW', 'ToRetention');
end;

end.
