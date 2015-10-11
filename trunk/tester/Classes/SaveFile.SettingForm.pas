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
    function GetTBWToRetention: Int64;
    function GetTraceOriginalLBA: String;
    function GetTracePath: String;

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

function TSaveFileForSettingForm.GetTBWToRetention: Int64;
begin
  result := SaveFile.LoadInt64('TBW', 'ToRetention');
end;

function TSaveFileForSettingForm.GetTracePath: String;
begin
  result := SaveFile.LoadString('Trace', 'Path');
end;

function TSaveFileForSettingForm.GetTraceOriginalLBA: String;
begin
  result := SaveFile.LoadString('Trace', 'OriginalLBA');
end;

end.
