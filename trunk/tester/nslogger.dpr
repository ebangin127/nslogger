program nslogger;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {fMain},
  uStrFunctions in 'Modules\Etc\uStrFunctions.pas',
  uFileFunctions in 'Modules\Windows\uFileFunctions.pas',
  uSetting in 'uSetting.pas' {fSetting},
  uRetSel in 'uRetSel.pas' {fRetSel},
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
  uBusPhysicalDrive in 'WindowsFileAPI\PhysicalDrive\Part\uBusPhysicalDrive.pas',
  uOSPhysicalDrive in 'WindowsFileAPI\PhysicalDrive\Part\uOSPhysicalDrive.pas',
  uBufferInterpreter in 'WindowsFileAPI\Abstraction\uBufferInterpreter.pas',
  uSMARTValueList in 'Objects\uSMARTValueList.pas',
  uPhysicalDrive in 'Objects\uPhysicalDrive.pas',
  uDatasizeUnit in 'Modules\uDatasizeUnit.pas',
  uTimeUnit in 'Modules\uTimeUnit.pas',
  uSizeStrings in 'Modules\uSizeStrings.pas',
  uSecurityDescriptor in 'Objects\uSecurityDescriptor.pas',
  uLegacyTrimCommand in 'Legacy\uLegacyTrimCommand.pas',
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
  uLanguageSettings in 'Resource\uLanguageSettings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
