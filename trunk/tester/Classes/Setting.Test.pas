unit Setting.Test;

interface

uses
  SysUtils,
  Setting.Test.ParamGetter, Device.PhysicalDrive;

type
  TTestSetting = class
  private
    FTestSettingParamFromForm: TTestSettingParamFromForm;
    FTestSettingParamFromPhysicalDrive: TTestSettingParamFromPhysicalDrive;

  public
    constructor Create(TestSettingToCopy: TTestSetting); overload;
    constructor Create(
      TestSettingParamFromForm: TTestSettingParamFromForm;
      TestSettingParamFromPhysicalDrive: TTestSettingParamFromPhysicalDrive);
      overload;

    property DiskNumber: Integer read
      FTestSettingParamFromForm.FDiskNumber;
    property LogSavePath: String read
      FTestSettingParamFromForm.FLogSavePath;
    property TBWToWrite: Integer read
      FTestSettingParamFromForm.FTBWToWrite;
    property TBWToRetention: Integer read
      FTestSettingParamFromForm.FTBWToRetention;
    property MaxFFR: Integer read
      FTestSettingParamFromForm.FMaxFFR;
    property TracePath: String read
      FTestSettingParamFromForm.FTracePath;
    property Model: String read
      FTestSettingParamFromPhysicalDrive.FModel;
    property Serial: String read
      FTestSettingParamFromPhysicalDrive.FSerial;
    property Capacity: Int64 read
      FTestSettingParamFromPhysicalDrive.FCapacity;
  end;

implementation

{ TTestSetting }

constructor TTestSetting.Create(TestSettingToCopy: TTestSetting);
begin
  Create(
    TestSettingToCopy.FTestSettingParamFromForm,
    TestSettingToCopy.FTestSettingParamFromPhysicalDrive);
end;

constructor TTestSetting.Create(
  TestSettingParamFromForm: TTestSettingParamFromForm;
  TestSettingParamFromPhysicalDrive: TTestSettingParamFromPhysicalDrive);
begin
  self.FTestSettingParamFromForm := TestSettingParamFromForm;
  self.FTestSettingParamFromPhysicalDrive := TestSettingParamFromPhysicalDrive;
end;

end.
