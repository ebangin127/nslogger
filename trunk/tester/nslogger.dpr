program nslogger;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {fMain},
  OS.Directory in 'Modules\OS.Directory.pas',
  Form.Setting in 'Form.Setting.pas' {fSetting},
  Form.Retention in 'Form.Retention.pas' {fRetention},
  Mersenne in 'Classes\Mersenne.pas',
  Verifier.Thread.Copy in 'Classes\Verifier.Thread.Copy.pas',
  Verifier.Thread.Verify in 'Classes\Verifier.Thread.Verify.pas',
  Tester.Thread.Precondition in 'Classes\Tester.Thread.Precondition.pas',
  MeasureUnit.Time in 'Modules\MeasureUnit.Time.pas',
  LanguageStrings in 'Modules\LanguageStrings.pas',
  System.PCharVal in 'Modules\System.PCharVal.pas',
  Log.Templates in 'Modules\Log.Templates.pas',
  Device.NumberExtractor in 'Modules\Device.NumberExtractor.pas',
  Device.PhysicalDrive in 'WindowsFileAPI\Device.PhysicalDrive.pas',
  Device.SMART.List in 'WindowsFileAPI\Device.SMART.List.pas',
  ErrorLogger in 'Classes\ErrorLogger.pas',
  OS.SecurityDescriptor in 'WindowsFileAPI\OS.SecurityDescriptor.pas',
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
  BufferInterpreter.ATA in 'WindowsFileAPI\BufferInterpreter.ATA.pas',
  BufferInterpreter.NVMe.Samsung in 'WindowsFileAPI\BufferInterpreter.NVMe.Samsung.pas',
  BufferInterpreter in 'WindowsFileAPI\BufferInterpreter.pas',
  CommandSet.ATA.Legacy in 'WindowsFileAPI\CommandSet.ATA.Legacy.pas',
  CommandSet.ATA in 'WindowsFileAPI\CommandSet.ATA.pas',
  CommandSet.Factory in 'WindowsFileAPI\CommandSet.Factory.pas',
  CommandSet.NVMe.Samsung in 'WindowsFileAPI\CommandSet.NVMe.Samsung.pas',
  CommandSet in 'WindowsFileAPI\CommandSet.pas',
  CommandSet.SAT in 'WindowsFileAPI\CommandSet.SAT.pas',
  Device.BusPhysicalDrive in 'WindowsFileAPI\Device.BusPhysicalDrive.pas',
  Device.OSPhysicalDrive in 'WindowsFileAPI\Device.OSPhysicalDrive.pas',
  Device.PhysicalDrive.List in 'WindowsFileAPI\Device.PhysicalDrive.List.pas',
  Getter.DiskGeometry in 'WindowsFileAPI\Getter.DiskGeometry.pas',
  Getter.DriveAvailability in 'WindowsFileAPI\Getter.DriveAvailability.pas',
  Getter.DriveList.Fixed in 'WindowsFileAPI\Getter.DriveList.Fixed.pas',
  Getter.DriveList in 'WindowsFileAPI\Getter.DriveList.pas',
  Getter.NCQAvailability in 'WindowsFileAPI\Getter.NCQAvailability.pas',
  Getter.PartitionExtent in 'WindowsFileAPI\Getter.PartitionExtent.pas',
  Getter.PartitionList in 'WindowsFileAPI\Getter.PartitionList.pas',
  Getter.PhysicalDriveList.Auto in 'WindowsFileAPI\Getter.PhysicalDriveList.Auto.pas',
  Getter.PhysicalDriveList.BruteForce in 'WindowsFileAPI\Getter.PhysicalDriveList.BruteForce.pas',
  Getter.PhysicalDriveList in 'WindowsFileAPI\Getter.PhysicalDriveList.pas',
  Getter.PhysicalDriveList.WMI in 'WindowsFileAPI\Getter.PhysicalDriveList.WMI.pas',
  OSFile.Handle in 'WindowsFileAPI\OSFile.Handle.pas',
  OSFile.Interfaced in 'WindowsFileAPI\OSFile.Interfaced.pas',
  OSFile.IoControl in 'WindowsFileAPI\OSFile.IoControl.pas',
  OSFile in 'WindowsFileAPI\OSFile.pas',
  Device.SMART.Diff in 'Classes\Device.SMART.Diff.pas',
  Getter.DiskLayout in 'WindowsFileAPI\Getter.DiskLayout.pas',
  Partition.List in 'WindowsFileAPI\Partition.List.pas',
  MeasureUnit.DataSize in 'WindowsFileAPI\MeasureUnit.DataSize.pas',
  Overlapped in 'WindowsFileAPI\Overlapped.pas',
  Overlapped.List in 'WindowsFileAPI\Overlapped.List.pas',
  Overlapped.OS in 'WindowsFileAPI\Overlapped.OS.pas',
  Overlapped.AnonymousMethod in 'WindowsFileAPI\Overlapped.AnonymousMethod.pas',
  ErrorCode.List in 'WindowsFileAPI\ErrorCode.List.pas',
  Error.List in 'Classes\Error.List.pas';

{$R *.res}
{$SETPEOPTFLAGS $140}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
