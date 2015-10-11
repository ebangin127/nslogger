unit Setting.Test.ParamGetter;

interface

uses
  SysUtils,
  Pattern.Singleton, Setting.Test.ParamGetter.InnerStorage,
  Form.Setting, MeasureUnit.DataSize, Device.PhysicalDrive;

type
  ENoDriveSelectedException = class(EArgumentNilException);

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
  function DenaryGBToKB: TDatasizeUnitChangeSetting;
  begin
    result.FNumeralSystem := TNumeralSystem.Denary;
    result.FFromUnit := GigaUnit;
    result.FToUnit := KiloUnit;
  end;
begin
  result.FDiskNumber := fSetting.GetDriveNumber;
  result.FLogSavePath := fSetting.SavePath;

  result.FTBWToRetention :=
    StrToInt(fSetting.eRetentionTBW.Text);
  result.FMaxFFR := StrToInt(fSetting.eFFR.Text);
  result.FTracePath := fSetting.eTracePath.Text;
  result.FTraceOriginalLBA :=
    round(ChangeDatasizeUnit(
      StrToInt(fSetting.eTraceOriginalLBA.Text), DenaryGBToKB)) shl 1;
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
  result.FCapacityInLBA :=
    PhysicalDrive.IdentifyDeviceResult.UserSizeInKB shl 1;
end;

initialization
finalization
  TTestSettingParamGetter.FreeSingletonInstance;
end.
