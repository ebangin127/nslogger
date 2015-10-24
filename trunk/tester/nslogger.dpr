program nslogger;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {fMain},
  Windows.Directory in 'Modules\Windows.Directory.pas',
  Form.Setting in 'Form.Setting.pas' {fSetting},
  Form.Retention in 'Form.Retention.pas' {fRetention},
  Mersenne in 'Classes\Mersenne.pas',
  Verifier.Thread.Copy in 'Classes\Verifier.Thread.Copy.pas',
  Verifier.Thread.Verify in 'Classes\Verifier.Thread.Verify.pas',
  Tester.Thread.Precondition in 'Classes\Tester.Thread.Precondition.pas',
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
  MeasureUnit.DataSize in 'Modules\MeasureUnit.DataSize.pas',
  MeasureUnit.Time in 'Modules\MeasureUnit.Time.pas',
  uPhysicalDriveList in 'WindowsFileAPI\PhysicalDrive\List\uPhysicalDriveList.pas',
  uPhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Abstraction\uPhysicalDriveListGetter.pas',
  uAutoPhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Auto\uAutoPhysicalDriveListGetter.pas',
  uBruteForcePhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Specific\uBruteForcePhysicalDriveListGetter.pas',
  uWMIPhysicalDriveListGetter in 'WindowsFileAPI\PhysicalDrive\ListGetter\Specific\uWMIPhysicalDriveListGetter.pas',
  uPartitionListGetter in 'WindowsFileAPI\PhysicalDrive\Getter\uPartitionListGetter.pas',
  uDriveListGetter in 'WindowsFileAPI\Abstraction\uDriveListGetter.pas',
  uPartitionExtentGetter in 'WindowsFileAPI\Partition\Getter\uPartitionExtentGetter.pas',
  uFixedDriveListGetter in 'WindowsFileAPI\Partition\Getter\uFixedDriveListGetter.pas',
  LanguageStrings in 'Modules\LanguageStrings.pas',
  System.PCharVal in 'Modules\System.PCharVal.pas',
  Log.Templates in 'Modules\Log.Templates.pas',
  Device.NumberExtractor in 'Modules\Device.NumberExtractor.pas',
  Device.PhysicalDrive in 'Classes\Device.PhysicalDrive.pas',
  Device.SMARTValueList in 'Classes\Device.SMARTValueList.pas',
  ErrorList in 'Classes\ErrorList.pas',
  OS.SecurityDescriptor in 'Classes\OS.SecurityDescriptor.pas',
  Parser.BufferStorage in 'Classes\Parser.BufferStorage.pas',
  Parser.Consumer in 'Classes\Parser.Consumer.pas',
  Parser.Divider in 'Classes\Parser.Divider.pas',
  Parser in 'Classes\Parser.pas',
  Parser.Producer in 'Classes\Parser.Producer.pas',
  Parser.ReadBuffer in 'Classes\Parser.ReadBuffer.pas',
  Pattern.Singleton in 'Classes\Pattern.Singleton.pas',
  RandomBuffer in 'Classes\RandomBuffer.pas',
  SaveFile in 'Classes\SaveFile.pas',
  SaveFile.SettingForm in 'Classes\SaveFile.SettingForm.pas',
  SaveFile.TesterIterator in 'Classes\SaveFile.TesterIterator.pas',
  SaveFile.TesterThread in 'Classes\SaveFile.TesterThread.pas',
  Setting.Test.ParamGetter.InnerStorage in 'Classes\Setting.Test.ParamGetter.InnerStorage.pas',
  Setting.Test.ParamGetter in 'Classes\Setting.Test.ParamGetter.pas',
  Setting.Test in 'Classes\Setting.Test.pas',
  Tester.CommandIssuer in 'Classes\Tester.CommandIssuer.pas',
  Tester.Iterator in 'Classes\Tester.Iterator.pas',
  Tester.Thread in 'Classes\Tester.Thread.pas',
  Tester.ToView in 'Classes\Tester.ToView.pas',
  Trace.List in 'Classes\Trace.List.pas',
  Trace.PartialList in 'Classes\Trace.PartialList.pas',
  Trace.Node in 'Classes\Trace.Node.pas',
  uSCSICommandSet in 'WindowsFileAPI\CommandSet\Specific\uSCSICommandSet.pas',
  uSCSIBufferInterpreter in 'WindowsFileAPI\Interpreter\uSCSIBufferInterpreter.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
