unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Math, DateUtils,
  uRandomBuffer, uGSTestThread, uGSList, uHDDInfo, uTrimCommand,
  uSetting, uRetSel;

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
    bSave: TButton;
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
    procedure bSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FDiskNum: Integer;
    FDestDriveModel: String;
    FDestDriveCapacity: INT64;
    FDestTBW: Integer;
    FRetensionTBW: Integer;
    FSaveFilePath: String;

    procedure WmAfterShow(var Msg: TMessage); message WM_AFTER_SHOW;
  public
    { Public declarations }
  end;

var
  fMain: TfMain;
  TestThread: TGSTestThread;
  AppPath: String;

implementation

{$R *.dfm}

procedure TfMain.bSaveClick(Sender: TObject);
begin
  Close;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;

  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;

  AppPath := ExtractFilePath(Application.ExeName);

    fRetSel := TfRetSel.Create(self, CreateFile(PChar('\\.\PhysicalDrive'
                                      + IntToStr(1)),
                                      GENERIC_READ or GENERIC_WRITE,
                                      FILE_SHARE_READ or FILE_SHARE_WRITE,
                                      nil,
                                      OPEN_EXISTING,
                                      0, 0));
    fRetSel.ShowModal;
end;

procedure TfMain.FormDestroy(Sender: TObject);
var
  NeedRetension: Boolean;
begin
  if DirectoryExists(FSaveFilePath) then
  begin
    lFirstSetting.Items.SaveToFile(FSaveFilePath + 'firstsetting.txt');
    lAlert.Items.SaveToFile(FSaveFilePath + 'alert.txt');
  end;

  NeedRetension := false;
  if TestThread <> nil then
  begin
    TestThread.Terminate;
    WaitForSingleObject(TestThread.Handle, INFINITE);

    case TestThread.ExitCode of
      EXIT_HOSTWRITE:
      begin
        lAlert.Items.Add('쓰기 종료: '
                          + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
      end;
      EXIT_RETENTION:
      begin
        lAlert.Items.Add('리텐션 테스트: '
                          + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));

        NeedRetension := true;
      end;
      EXIT_NORMAL:
      begin
        lAlert.Items.Add('사용자 종료: '
                          + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
      end;
    end;

    FreeAndNil(TestThread);

    if NeedRetension then
    begin
      fRetSel := TfRetSel.Create(self, CreateFile(PChar('\\.\PhysicalDrive'
                                        + IntToStr(FDiskNum)),
                                        GENERIC_READ or GENERIC_WRITE,
                                        FILE_SHARE_READ or FILE_SHARE_WRITE,
                                        nil,
                                        OPEN_EXISTING,
                                        0, 0));
      fRetSel.ShowModal;
    end;
  end;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
  PostMessage(Self.Handle, WM_AFTER_SHOW, 0, 0);
end;

procedure TfMain.WmAfterShow(var Msg: TMessage);
var
  SSDInfo: THDDInfo;
begin
  fSetting := TfSetting.Create(self);
  fSetting.ShowModal;

  FDiskNum := fSetting.GetDriveNum;
  if FDiskNum = -1 then
  begin
    Close;
    exit;
  end;

  FSaveFilePath := fSetting.SavePath;

  SSDInfo := THDDInfo.Create;
  SSDInfo.SetDeviceName('PhysicalDrive' + IntToStr(FDiskNum));
  FDestTBW := StrToInt(fSetting.eDestTBW.Text);
  FRetensionTBW := StrToInt(fSetting.eRetentionTBW.Text);
  FDestDriveModel := SSDInfo.Model;
  FDestDriveCapacity := floor(SSDInfo.UserSize
                              / 2 / 1024 / 1000 / 1000 * 1024 * 1.024); //In GB

  sTestStage.Caption := '트레이스 불러오는 중';

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

  TestThread := TGSTestThread.Create(fSetting.eTrace.Text,
                                     true, SSDInfo.UserSize shr 9);
  if fSetting.LoadedFromFile then
  begin
    TestThread.Load(fSetting.SavePath + 'settings.ini');
    lFirstSetting.Items.LoadFromFile(FSaveFilePath + 'firstsetting.txt');
    lAlert.Items.LoadFromFile(FSaveFilePath + 'alert.txt');

    if Pos('리텐션', lAlert.Items[lAlert.Count - 1]) > 0 then
    begin
      //리텐션 구현
    end;
  end;
  TestThread.SetDisk(FDiskNum);

  TestThread.MaxLBA := SSDInfo.UserSize;
  TestThread.OrigLBA := 251000000;
  TestThread.Align := 512;

  TestThread.MaxHostWrite := FDestTBW;
  TestThread.RetentionTest := FRetensionTBW;

  TestThread.AssignSavePath(FSaveFilePath);
  TestThread.AssignBufferSetting(128 shl 10, 100);
  TestThread.AssignDLLPath(AppPath + 'MAKEdll.dll');
  TestThread.StartThread;

  FreeAndNil(SSDInfo);
end;
end.
