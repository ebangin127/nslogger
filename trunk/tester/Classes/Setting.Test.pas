unit Setting.Test;

interface

uses
  SysUtils,
  Setting.Test.ParamGetter, Setting.Test.ParamGetter.InnerStorage,
  Device.PhysicalDrive;

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
    property TBWToRetention: Integer read
      FTestSettingParamFromForm.FTBWToRetention;
    property MaxFFR: Integer read
      FTestSettingParamFromForm.FMaxFFR;
    property TracePath: String read
      FTestSettingParamFromForm.FTracePath;
    property TraceOriginalLBA: Int64 read
      FTestSettingParamFromForm.FTraceOriginalLBA;
    property Model: String read
      FTestSettingParamFromPhysicalDrive.FModel;
    property Serial: String read
      FTestSettingParamFromPhysicalDrive.FSerial;
    property CapacityInLBA: Int64 read
      FTestSettingParamFromPhysicalDrive.FCapacityInLBA;
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
