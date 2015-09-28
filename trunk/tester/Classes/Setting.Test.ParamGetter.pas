unit Setting.Test.ParamGetter;

interface

uses
  SysUtils,
  Pattern.Singleton, Form.Setting, MeasureUnit.DataSize, Device.PhysicalDrive;

type
  ENoDriveSelectedException = class(EArgumentNilException);

  TTestSettingParamFromForm = record
    FDiskNumber: Integer;
    FLogSavePath: String;
    FTBWToWrite: Integer;
    FTBWToRetention: Integer;
    FMaxFFR: Integer;
    FTracePath: String;
  end;

  TTestSettingParamFromPhysicalDrive = record
    FModel: String;
    FSerial: String;
    FCapacity: Int64;
  end;

  TTestSettingParamGetter = class(TSingleton<TTestSettingParamGetter>)
  public
    function GetValuesFromForm(SettingForm: TfSetting):
      TTestSettingParamFromForm;
    function GetValuesFromDrive(DiskNumber: Integer):
      TTestSettingParamFromPhysicalDrive;
  end;

implementation

function TTestSettingParamGetter.GetValuesFromForm(SettingForm: TfSetting):
  TTestSettingParamFromForm;
begin
  result.FDiskNumber := fSetting.GetDriveNumber;
  result.FLogSavePath := fSetting.SavePath;

  result.FTBWToWrite := StrToInt(fSetting.eDestTBW.Text);
  result.FTBWToRetention :=
    StrToInt(fSetting.eRetentionTBW.Text);
  result.FMaxFFR := StrToInt(fSetting.eFFR.Text);
end;

function TTestSettingParamGetter.GetValuesFromDrive(DiskNumber: Integer):
  TTestSettingParamFromPhysicalDrive;
  function DenaryKBtoGB: TDatasizeUnitChangeSetting;
  begin
    result.FNumeralSystem := TNumeralSystem.Denary;
    result.FFromUnit := KiloUnit;
    result.FToUnit := GigaUnit;
  end;
var
  PhysicalDrive: IPhysicalDrive;
begin
  if DiskNumber = -1 then
    raise ENoDriveSelectedException.Create('No Drive Selected');

  PhysicalDrive := TPhysicalDrive.Create(
    TPhysicalDrive.BuildFileAddressByNumber(DiskNumber));

  result.FModel := PhysicalDrive.IdentifyDeviceResult.Model;
  result.FSerial := PhysicalDrive.IdentifyDeviceResult.Serial;
  result.FCapacity := Round(ChangeDatasizeUnit(
    PhysicalDrive.IdentifyDeviceResult.UserSizeInKB, DenaryKBtoGB));
end;

initialization
finalization
  TTestSettingParamGetter.FreeSingletonInstance;
end.
