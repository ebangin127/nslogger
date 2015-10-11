unit Setting.Test.ParamGetter.InnerStorage;

interface

type
  TTestSettingParamFromForm = record
    FDiskNumber: Integer;
    FLogSavePath: String;
    FTBWToRetention: Integer;
    FMaxFFR: Integer;
    FTracePath: String;
  end;

  TTestSettingParamFromPhysicalDrive = record
    FModel: String;
    FSerial: String;
    FCapacity: Int64;
  end;

implementation

end.
