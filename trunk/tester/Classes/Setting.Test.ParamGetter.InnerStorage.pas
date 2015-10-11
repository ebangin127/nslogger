unit Setting.Test.ParamGetter.InnerStorage;

interface

type
  TTestSettingParamFromForm = record
    FDiskNumber: Integer;
    FLogSavePath: String;
    FTBWToRetention: Integer;
    FMaxFFR: Integer;
    FTracePath: String;
    FTraceOriginalLBA: Int64;
  end;

  TTestSettingParamFromPhysicalDrive = record
    FModel: String;
    FSerial: String;
    FCapacityInLBA: Int64;
  end;

implementation

end.
