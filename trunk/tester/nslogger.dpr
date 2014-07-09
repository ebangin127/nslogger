program nslogger;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {fMain},
  uGSList in 'Classes\TGSList\uGSList.pas',
  uGSTester in 'Classes\TGSTester\uGSTester.pas',
  uDiskFunctions in 'Modules\Disk\uDiskFunctions.pas',
  uTrimCommand in 'Modules\Disk\uTrimCommand.pas',
  uIntFunctions in 'Modules\Etc\uIntFunctions.pas',
  uStrFunctions in 'Modules\Etc\uStrFunctions.pas',
  uFileFunctions in 'Modules\Windows\uFileFunctions.pas',
  uRandomBuffer in 'Classes\TRandomBuffer\uRandomBuffer.pas',
  uMTforDel in 'Classes\TRandomBuffer\uMTforDel.pas',
  uGSTestThread in 'Classes\TGSTestThread\uGSTestThread.pas',
  uSetting in 'uSetting.pas' {fSetting},
  uSaveFile in 'Classes\TSaveFile\uSaveFile.pas',
  uErrorList in 'Classes\TErrorList\uErrorList.pas',
  uRetSel in 'uRetSel.pas' {fRetSel},
  uHDDInfo in 'Classes\THDDInfo\uHDDInfo.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
