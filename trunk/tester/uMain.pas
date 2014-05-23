unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Math,
  uRandomBuffer, uGSTestThread, uGSList, uSSDInfo,
  uSetting;

const
  WM_AFTER_SHOW = WM_USER + 300;

type
  TfMain = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    pMinLatency: TProgressBar;
    pMaxLatency: TProgressBar;
    sMinLatency: TStaticText;
    sMaxLatency: TStaticText;
    sTestStage: TStaticText;
    Label3: TLabel;
    sCycleCount: TStaticText;
    GroupBox2: TGroupBox;
    lFirstSetting: TListBox;
    GroupBox3: TGroupBox;
    lAlert: TListBox;
    Button2: TButton;
    pRamUsage: TProgressBar;
    sRamUsage: TStaticText;
    Label6: TLabel;
    pTestProgress: TProgressBar;
    sTestProgress: TStaticText;
    Label7: TLabel;
    Label5: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FDiskNum: Integer;
    FDestDriveModel: String;
    FDestDriveCapacity: INT64;
    FDestFolder: String;
    FDestTBW: Integer;
    FRetensionTBW: Integer;

    procedure WmAfterShow(var Msg: TMessage); message WM_AFTER_SHOW;
  public
    { Public declarations }
  end;

var
  fMain: TfMain;
  TestThread: TGSTestThread;
  TestList: TGSList;

implementation

{$R *.dfm}

procedure TfMain.FormDestroy(Sender: TObject);
begin
  if TestThread <> nil then
  begin
    TestThread.Terminate;
    WaitForSingleObject(TestThread.Handle, INFINITE);
    FreeAndNil(TestThread);
  end;

  if TestList <> nil then
    FreeAndNil(TestList);
end;

procedure TfMain.FormShow(Sender: TObject);
begin
  PostMessage(Self.Handle, WM_AFTER_SHOW, 0, 0);
end;

procedure TfMain.WmAfterShow(var Msg: TMessage);
var
  SSDInfo: TSSDInfo;
begin
  fSetting := TfSetting.Create(self);
  fSetting.ShowModal;

  if fSetting.OptionsSet = false then
  begin
    Close;
    exit;
  end;

  SSDInfo := TSSDInfo.Create;
  SSDInfo.SetDeviceName('PhysicalDrive' + IntToStr(FDiskNum));
  {$IF FALSE}
  FDiskNum := StrToInt(fSetting.eDestination);
  {$ENDIF}
  FDestTBW := StrToInt(fSetting.eDestTBW.Text);
  FRetensionTBW := StrToInt(fSetting.eRetensionTBW.Text);
  FDestDriveModel := SSDInfo.Model;
  FDestDriveCapacity := floor(SSDInfo.UserSize
                              / 2 / 1024 / 1000 / 1000 * 1024 * 1.024); //In GB
  FreeAndNil(SSDInfo);

  sTestStage.Caption := '자료 불러오는 중';

  lFirstSetting.Items.Add('- 디스크 정보 -');
  lFirstSetting.Items.Add('디스크 위치: \\.\PhysicalDrive' + IntToStr(FDiskNum));
  lFirstSetting.Items.Add('모델명: ' + FDestDriveModel);
  lFirstSetting.Items.Add('용량: ' + IntToStr(FDestDriveCapacity) + 'GB');
  lFirstSetting.Items.Add('');

  lFirstSetting.Items.Add('- 테스트 정보 -');
  lFirstSetting.Items.Add('목표 TBW: ' + IntToStr(FDestTBW) + 'TBW');
  lFirstSetting.Items.Add('리텐션 테스트 주기: ' + IntToStr(FRetensionTBW)
                                                 + 'TBW');

  Application.ProcessMessages;


  TestList := TGSList.Create;
  TestList.Test(false);

  TestThread := TGSTestThread.Create(true);
  TestThread.SetDisk(1);
  TestThread.AssignBufferSetting(128 shl 10, 100);
  TestThread.AssignListHeader(TestList.GetListHeader);
  TestThread.StartThread;
end;
end.
