program nslogger;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {fMain},
  uDiskFunctions in 'Modules\Disk\uDiskFunctions.pas',
  uTrimCommand in 'Modules\Disk\uTrimCommand.pas',
  uIntFunctions in 'Modules\Etc\uIntFunctions.pas',
  uStrFunctions in 'Modules\Etc\uStrFunctions.pas',
  uFileFunctions in 'Modules\Windows\uFileFunctions.pas',
  uSetting in 'uSetting.pas' {fSetting},
  uRetSel in 'uRetSel.pas' {fRetSel},
  uATALowOps in 'Classes\ATALowOps\uATALowOps.pas',
  uSMARTFunctions in 'Modules\Disk\uSMARTFunctions.pas',
  uGSList in 'Classes\Tester\uGSList.pas',
  uGSTester in 'Classes\Tester\uGSTester.pas',
  uGSTestThread in 'Classes\Tester\uGSTestThread.pas',
  uErrorList in 'Classes\SaveFile\uErrorList.pas',
  uSaveFile in 'Classes\SaveFile\uSaveFile.pas',
  uMTforDel in 'Classes\RandomBuffer\uMTforDel.pas',
  uRandomBuffer in 'Classes\RandomBuffer\uRandomBuffer.pas',
  uSSDInfo in 'Classes\SSDInfo\uSSDInfo.pas',
  uSSDVersion in 'Classes\SSDInfo\uSSDVersion.pas',
  uCopyThread in 'Classes\Verifier\uCopyThread.pas',
  uVerifyThread in 'Classes\Verifier\uVerifyThread.pas',
  uParser in 'Classes\Parser\uParser.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
