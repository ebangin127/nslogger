program nslogger;

uses
  Vcl.Forms,
  Form.Main in 'Form.Main.pas' {fMain},
  Form.Setting in 'Form.Setting.pas' {fSetting},
  Form.Retention in 'Form.Retention.pas' {fRetention},
  Mersenne in 'Classes\Mersenne.pas',
  Verifier.Thread.Copy in 'Classes\Verifier.Thread.Copy.pas',
  Verifier.Thread.Verify in 'Classes\Verifier.Thread.Verify.pas',
  Tester.Thread.Precondition in 'Classes\Tester.Thread.Precondition.pas',
  ErrorLogger in 'Classes\ErrorLogger.pas',
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
  Device.SMART.Diff in 'Classes\Device.SMART.Diff.pas',
  Error.List in 'Classes\Error.List.pas',
  Device.NumberExtractor in 'Modules\Device.NumberExtractor.pas',
  Device.SlotSpeed in 'Modules\Device.SlotSpeed.pas',
  LanguageStrings in 'Modules\LanguageStrings.pas',
  Log.Templates in 'Modules\Log.Templates.pas',
  MeasureUnit.Time in 'Modules\MeasureUnit.Time.pas',
  OS.Directory in 'Modules\OS.Directory.pas',
  OS.SetupAPI in 'Modules\OS.SetupAPI.pas',
  OS.Version.Helper in 'Modules\OS.Version.Helper.pas',
  OS.Volume in 'Modules\OS.Volume.pas',
  System.PCharVal in 'Modules\System.PCharVal.pas',
  uSizeStrings in 'Modules\uSizeStrings.pas',
  BufferInterpreter.ATA in 'WindowsFileAPI\BufferInterpreter.ATA.pas',
  BufferInterpreter.NVMe.Intel in 'WindowsFileAPI\BufferInterpreter.NVMe.Intel.pas',
  BufferInterpreter.NVMe in 'WindowsFileAPI\BufferInterpreter.NVMe.pas',
  BufferInterpreter in 'WindowsFileAPI\BufferInterpreter.pas',
  BufferInterpreter.SCSI in 'WindowsFileAPI\BufferInterpreter.SCSI.pas',
  CommandSet.ATA.Legacy in 'WindowsFileAPI\CommandSet.ATA.Legacy.pas',
  CommandSet.ATA in 'WindowsFileAPI\CommandSet.ATA.pas',
  CommandSet.Factory in 'WindowsFileAPI\CommandSet.Factory.pas',
  CommandSet.NVMe.Intel in 'WindowsFileAPI\CommandSet.NVMe.Intel.pas',
  CommandSet.NVMe.Intel.PortPart in 'WindowsFileAPI\CommandSet.NVMe.Intel.PortPart.pas',
  CommandSet.NVMe.OS in 'WindowsFileAPI\CommandSet.NVMe.OS.pas',
  CommandSet.NVMe in 'WindowsFileAPI\CommandSet.NVMe.pas',
  CommandSet.NVMe.Samsung in 'WindowsFileAPI\CommandSet.NVMe.Samsung.pas',
  CommandSet.NVMe.WithoutDriver in 'WindowsFileAPI\CommandSet.NVMe.WithoutDriver.pas',
  CommandSet in 'WindowsFileAPI\CommandSet.pas',
  CommandSet.SAT in 'WindowsFileAPI\CommandSet.SAT.pas',
  Device.PhysicalDrive.Bus in 'WindowsFileAPI\Device.PhysicalDrive.Bus.pas',
  Device.PhysicalDrive.List in 'WindowsFileAPI\Device.PhysicalDrive.List.pas',
  Device.PhysicalDrive.OS in 'WindowsFileAPI\Device.PhysicalDrive.OS.pas',
  Device.PhysicalDrive in 'WindowsFileAPI\Device.PhysicalDrive.pas',
  Device.SMART.List in 'WindowsFileAPI\Device.SMART.List.pas',
  ErrorCode.List in 'WindowsFileAPI\ErrorCode.List.pas',
  Getter.DriveList.Fixed in 'WindowsFileAPI\Getter.DriveList.Fixed.pas',
  Getter.DriveList in 'WindowsFileAPI\Getter.DriveList.pas',
  Getter.OS.Version in 'WindowsFileAPI\Getter.OS.Version.pas',
  Getter.PartitionExtent in 'WindowsFileAPI\Getter.PartitionExtent.pas',
  Getter.PartitionList in 'WindowsFileAPI\Getter.PartitionList.pas',
  Getter.PhysicalDrive.DiskGeometry in 'WindowsFileAPI\Getter.PhysicalDrive.DiskGeometry.pas',
  Getter.PhysicalDrive.DriveAvailability in 'WindowsFileAPI\Getter.PhysicalDrive.DriveAvailability.pas',
  Getter.PhysicalDrive.ListChange in 'WindowsFileAPI\Getter.PhysicalDrive.ListChange.pas',
  Getter.PhysicalDrive.NCQAvailability in 'WindowsFileAPI\Getter.PhysicalDrive.NCQAvailability.pas',
  Getter.PhysicalDrive.PartitionList in 'WindowsFileAPI\Getter.PhysicalDrive.PartitionList.pas',
  Getter.PhysicalDriveList.Auto in 'WindowsFileAPI\Getter.PhysicalDriveList.Auto.pas',
  Getter.PhysicalDriveList.OS in 'WindowsFileAPI\Getter.PhysicalDriveList.OS.pas',
  Getter.PhysicalDriveList.OS.Path in 'WindowsFileAPI\Getter.PhysicalDriveList.OS.Path.pas',
  Getter.PhysicalDriveList in 'WindowsFileAPI\Getter.PhysicalDriveList.pas',
  Getter.PhysicalDriveList.WMI in 'WindowsFileAPI\Getter.PhysicalDriveList.WMI.pas',
  Getter.SCSIAddress in 'WindowsFileAPI\Getter.SCSIAddress.pas',
  Getter.SlotSpeed in 'WindowsFileAPI\Getter.SlotSpeed.pas',
  Getter.SlotSpeedByDeviceID in 'WindowsFileAPI\Getter.SlotSpeedByDeviceID.pas',
  MeasureUnit.DataSize in 'WindowsFileAPI\MeasureUnit.DataSize.pas',
  OS.Handle in 'WindowsFileAPI\OS.Handle.pas',
  OS.SecurityDescriptor in 'WindowsFileAPI\OS.SecurityDescriptor.pas',
  OSFile.ForInternal in 'WindowsFileAPI\OSFile.ForInternal.pas',
  OSFile.Handle in 'WindowsFileAPI\OSFile.Handle.pas',
  OSFile.Interfaced in 'WindowsFileAPI\OSFile.Interfaced.pas',
  OSFile.IoControl in 'WindowsFileAPI\OSFile.IoControl.pas',
  OSFile in 'WindowsFileAPI\OSFile.pas',
  Overlapped.AnonymousMethod in 'WindowsFileAPI\Overlapped.AnonymousMethod.pas',
  Overlapped.List in 'WindowsFileAPI\Overlapped.List.pas',
  Overlapped.OS in 'WindowsFileAPI\Overlapped.OS.pas',
  Overlapped in 'WindowsFileAPI\Overlapped.pas',
  Partition.List in 'WindowsFileAPI\Partition.List.pas',
  Version in 'Modules\Version.pas',
  Registry.Helper.Internal in 'WindowsFileAPI\Registry.Helper.Internal.pas',
  Registry.Helper in 'WindowsFileAPI\Registry.Helper.pas',
  WMI in 'WindowsFileAPI\WMI.pas';

{$R *.res}
{$SETPEOPTFLAGS $140}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
