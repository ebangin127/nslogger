program nslogger;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {fMain},
  uStrFunctions in 'Modules\Etc\uStrFunctions.pas',
  uFileFunctions in 'Modules\Windows\uFileFunctions.pas',
  Form.Setting in 'Form.Setting.pas' {fSetting},
  Form.Retention in 'Form.Retention.pas' {fRetention},
  uGSList in 'Classes\Tester\uGSList.pas',
  uGSTester in 'Classes\Tester\uGSTester.pas',
  uGSTestThread in 'Classes\Tester\uGSTestThread.pas',
  uErrorList in 'Classes\SaveFile\uErrorList.pas',
  uSaveFile in 'Classes\SaveFile\uSaveFile.pas',
  uMTforDel in 'Classes\RandomBuffer\uMTforDel.pas',
  uRandomBuffer in 'Classes\RandomBuffer\uRandomBuffer.pas',
  uCopyThread in 'Classes\Verifier\uCopyThread.pas',
  uVerifyThread in 'Classes\Verifier\uVerifyThread.pas',
  uParser in 'Classes\Parser\uParser.pas',
  uPreCondThread in 'Classes\Tester\uPreCondThread.pas',
  uInterfacedOSFile in 'WindowsFileAPI\Abstraction\uInterfacedOSFile.pas',
  uIoControlFile in 'WindowsFileAPI\Abstraction\uIoControlFile.pas',
  uOSFile in 'WindowsFileAPI\Abstraction\uOSFile.pas',
  uOSFileWithHandle in 'WindowsFileAPI\Abstraction\uOSFileWithHandle.pas',
  uCommandSet in 'WindowsFileAPI\CommandSet\Abstraction\uCommandSet.pas',
  uCommandSetFactory in 'WindowsFileAPI\CommandSet\Factory\uCommandSetFactory.pas',
  uATACommandSet in 'WindowsFileAPI\CommandSet\Specific\uATACommandSet.pas',
  uLegacyATACommandSet in 'WindowsFileAPI\CommandSet\Specific\uLegacyATACommandSet.pas',
  uSATCommandSet in 'WindowsFileAPI\CommandSet\Specific\uSATCommandSet.pas',
  uATABufferInterpreter in 'WindowsFileAPI\Interpreter\uATABufferInterpreter.pas',
  uDiskGeometryGetter in 'WindowsFileAPI\PhysicalDrive\Getter\uDiskGeometryGetter.pas',
  uDriveAvailabilityGetter in 'WindowsFileAPI\PhysicalDrive\Getter\uDriveAvailabilityGetter.pas',
  uNCQAvailabilityGetter in 'WindowsFileAPI\PhysicalDrive\Getter\uNCQAvailabilityGetter.pas',
  Device.BusPhysicalDrive in 'WindowsFileAPI\PhysicalDrive\Part\Device.BusPhysicalDrive.pas',
  Device.OSPhysicalDrive in 'WindowsFileAPI\PhysicalDrive\Part\Device.OSPhysicalDrive.pas',
  uBufferInterpreter in 'WindowsFileAPI\Abstraction\uBufferInterpreter.pas',
  Device.SMARTValueList in 'Objects\Device.SMARTValueList.pas',
  Device.PhysicalDrive in 'Objects\Device.PhysicalDrive.pas',
  MeasureUnit.DataSize in 'Modules\MeasureUnit.DataSize.pas',
  MeasureUnit.Time in 'Modules\MeasureUnit.Time.pas',
  uSizeStrings in 'Modules\uSizeStrings.pas',
  OS.SecurityDescriptor in 'Objects\OS.SecurityDescriptor.pas',
  uLegacyDiskFunctions in 'Legacy\uLegacyDiskFunctions.pas',
  uPhysicalDriveList in 'WindowsFileAPI\PhysicalDrive\List\uPhysicalDriveList.pas',
  uPhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Abstraction\uPhysicalDriveListGetter.pas',
  uAutoPhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Auto\uAutoPhysicalDriveListGetter.pas',
  uBruteForcePhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Specific\uBruteForcePhysicalDriveListGetter.pas',
  uWMIPhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Specific\uWMIPhysicalDriveListGetter.pas',
  uPartitionListGetter in 'WindowsFileAPI\PhysicalDrive\Getter\uPartitionListGetter.pas',
  uDriveListGetter in 'WindowsFileAPI\Abstraction\uDriveListGetter.pas',
  uPartitionExtentGetter in 'WindowsFileAPI\Partition\Getter\uPartitionExtentGetter.pas',
  uFixedDriveListGetter in 'WindowsFileAPI\Partition\Getter\uFixedDriveListGetter.pas',
  uLanguageSettings in 'Resource\uLanguageSettings.pas',
  Setting.Test in 'Classes\Setting.Test.pas',
  Setting.Test.ParamGetter in 'Classes\Setting.Test.ParamGetter.pas',
  Pattern.Singleton in 'Objects\Pattern.Singleton.pas',
  uGSNode in 'Classes\Tester\uGSNode.pas',
  uLegacyReadCommand in 'Legacy\uLegacyReadCommand.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
