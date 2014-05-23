program GrillStorage;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {fMain},
  uGSList in 'Classes\TGSList\uGSList.pas',
  uGSMTAnalyzer in 'Classes\TGSMTAnalyzer\uGSMTAnalyzer.pas',
  uGSTester in 'Classes\TGSTester\uGSTester.pas',
  uDiskFunctions in 'Modules\Disk\uDiskFunctions.pas',
  uPartitionFunctions in 'Modules\Disk\uPartitionFunctions.pas',
  uSMARTFunctions in 'Modules\Disk\uSMARTFunctions.pas',
  uTrimCommand in 'Modules\Disk\uTrimCommand.pas',
  uIntFunctions in 'Modules\Etc\uIntFunctions.pas',
  uStrFunctions in 'Modules\Etc\uStrFunctions.pas',
  uLanguageSettings in 'Modules\Language\uLanguageSettings.pas',
  uFileFunctions in 'Modules\Windows\uFileFunctions.pas',
  uPlugAndPlay in 'Modules\Windows\uPlugAndPlay.pas',
  uRegFunctions in 'Modules\Windows\uRegFunctions.pas',
  uSSDInfo in 'Classes\SSDInfo\uSSDInfo.pas',
  uRandomBuffer in 'Classes\TRandomBuffer\uRandomBuffer.pas',
  uMTforDel in 'Classes\TRandomBuffer\uMTforDel.pas',
  uSSDVersion in 'Classes\SSDInfo\uSSDVersion.pas',
  uGSTestThread in 'Classes\TGSTestThread\uGSTestThread.pas',
  uSMARTManager in 'Classes\TSMARTManager\uSMARTManager.pas',
  uSetting in 'uSetting.pas' {fSetting};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfSetting, fSetting);
  Application.Run;
end.
