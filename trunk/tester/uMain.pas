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
    gStatus: TGroupBox;
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
    gFirstSet: TGroupBox;
    lFirstSetting: TListBox;
    gAlert: TGroupBox;
    lAlert: TListBox;
    bSave: TButton;
    pRamUsage: TProgressBar;
    sRamUsage: TStaticText;
    Label6: TLabel;
    pTestProgress: TProgressBar;
    sTestProgress: TStaticText;
    Label7: TLabel;
    lMaxAlertL: TLabel;
    lMinAlertL: TLabel;
    lMaxAlertR: TLabel;
    lMinAlertR: TLabel;
    lFreeR: TLabel;
    lFreeL: TLabel;
    bForceReten: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bForceRetenClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FDiskNum: Integer;
    FDestDriveModel: String;
    FDestDriveSerial: String;
    FDestDriveCapacity: INT64;
    FDestTBW: Integer;
    FRetentionTBW: Integer;
    FSaveFilePath: String;
    FNeedRetention: Boolean;

    procedure WmAfterShow(var Msg: TMessage); message WM_AFTER_SHOW;
  public
    property NeedRetention: Boolean read FNeedRetention;
    property DriveModel: String read FDestDriveModel;
    property DriveSerial: String read FDestDriveSerial;
    { Public declarations }
  end;

var
  fMain: TfMain;
  TestThread: TGSTestThread;
  AppPath: String;

implementation

{$R *.dfm}

procedure TfMain.bForceRetenClick(Sender: TObject);
begin
  FNeedRetention := true;
  lAlert.Items.Add('임의 리텐션 테스트: '
                    + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));

  if TestThread <> nil then
  begin
    TestThread.Terminate;
    WaitForSingleObject(TestThread.Handle, 60);

    FreeAndNil(TestThread);

    if NeedRetention then
    begin
      fRetSel := TfRetSel.Create(self, CreateFile(PChar('\\.\PhysicalDrive'
                                                  + IntToStr(FDiskNum)),
                                                  GENERIC_READ or
                                                    GENERIC_WRITE,
                                                  FILE_SHARE_READ or
                                                    FILE_SHARE_WRITE,
                                                  nil,
                                                  OPEN_EXISTING,
                                                  0, 0));
      fRetSel.ShowModal;
    end;
  end;

  Close;
end;

procedure TfMain.bSaveClick(Sender: TObject);
begin
  FNeedRetention := false;
  Close;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  AppPath := ExtractFilePath(Application.ExeName);
end;

procedure TfMain.FormDestroy(Sender: TObject);
var
  NeedRetention: Boolean;
begin
  if DirectoryExists(FSaveFilePath) then
  begin
    lFirstSetting.Items.SaveToFile(FSaveFilePath + 'firstsetting.txt');
    lAlert.Items.SaveToFile(FSaveFilePath + 'alert.txt');
  end;

  NeedRetention := false or FNeedRetention;
  if TestThread <> nil then
  begin
    TestThread.Terminate;
    WaitForSingleObject(TestThread.Handle, 60);

    case TestThread.ExitCode of
      EXIT_HOSTWRITE:
      begin
        lAlert.Items.Add('쓰기 종료: '
                          + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
      end;
      EXIT_RETENTION:
      begin
        lAlert.Items.Add('주기적 리텐션 테스트: '
                          + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));

        NeedRetention := true;
      end;
      EXIT_NORMAL:
      begin
        lAlert.Items.Add('사용자 종료: '
                          + FormatDateTime('yyyy/mm/dd hh:nn:ss', Now));
      end;
    end;

    FreeAndNil(TestThread);

    if NeedRetention then
    begin
      fRetSel := TfRetSel.Create(self, CreateFile(PChar('\\.\PhysicalDrive'
                                                  + IntToStr(FDiskNum)),
                                                  GENERIC_READ or
                                                    GENERIC_WRITE,
                                                  FILE_SHARE_READ or
                                                    FILE_SHARE_WRITE,
                                                  nil,
                                                  OPEN_EXISTING,
                                                  0, 0));
      fRetSel.ShowModal;
    end;
  end;
end;

procedure TfMain.FormResize(Sender: TObject);
var
  UnitSize: Double;
begin
  //가로
  UnitSize := (ClientWidth - 40) / 16;
  gStatus.Width := round(UnitSize * 5);
  lMinAlertR.Left := gStatus.Width - lMinAlertL.Left - lMinAlertR.Width;
  lMaxAlertR.Left := gStatus.Width - lMaxAlertL.Left - lMaxAlertR.Width;
  lFreeR.Left := gStatus.Width - lFreeL.Left - lFreeR.Width;
  pMinLatency.Width := lMinAlertR.Left - pMinLatency.Left - 8;
  pMaxLatency.Width := lMaxAlertR.Left - pMaxLatency.Left - 8;
  pRamUsage.Width := lFreeR.Left - pRamUsage.Left - 8;
  pTestProgress.Width := pMinLatency.Width;

  gFirstSet.Left := gStatus.Left + gStatus.Width + 10;
  gFirstSet.Width := round(UnitSize * 5);
  lFirstSetting.Width := gFirstSet.Width - 16;

  gAlert.Left := gFirstSet.Left + gFirstSet.Width + 10;
  gAlert.Width := round(UnitSize * 6);
  lAlert.Width := gAlert.Width - 16;

  bSave.Left := ClientWidth - 10 - bSave.Width;
  bForceReten.Left := bSave.Left - 10 - bForceReten.Width;


  //세로
  UnitSize := (ClientHeight - 30) / 12;
  gStatus.Height := round(UnitSize * 11);
  gFirstSet.Height := gStatus.Height;
  gAlert.Height := gStatus.Height;

  lFirstSetting.Height := gFirstSet.Height - 30;
  lAlert.Height := gAlert.Height - 30;

  bForceReten.Height := Round(UnitSize);
  bForceReten.Top := gAlert.Top + gAlert.Height + 10;

  bSave.Height := Round(UnitSize);
  bSave.Top := bForceReten.Top;
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
  FRetentionTBW := StrToInt(fSetting.eRetentionTBW.Text);
  FDestDriveModel := SSDInfo.Model;
  FDestDriveSerial := SSDInfo.Serial;
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
  lFirstSetting.Items.Add('리텐션 테스트 주기: ' + IntToStr(FRetentionTBW)
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
      fRetSel := TfRetSel.Create(self, CreateFile(PChar('\\.\PhysicalDrive'
                                                    + IntToStr(FDiskNum)),
                                                  GENERIC_READ or
                                                    GENERIC_WRITE,
                                                  FILE_SHARE_READ or
                                                    FILE_SHARE_WRITE,
                                                  nil,
                                                  OPEN_EXISTING,
                                                  0, 0));
      fRetSel.SetMode(true, fSetting.SavePath + 'compare_error_log.txt');
      fRetSel.ShowModal;
    end;
  end;
  TestThread.SetDisk(FDiskNum);

  TestThread.MaxLBA := SSDInfo.UserSize;
  TestThread.OrigLBA := 251000000;
  TestThread.Align := 512;

  TestThread.MaxHostWrite := FDestTBW;
  TestThread.RetentionTest := FRetentionTBW;

  TestThread.AssignSavePath(FSaveFilePath);
  TestThread.AssignBufferSetting(128 shl 10, 100);
  TestThread.AssignDLLPath(AppPath + 'parser.dll');
  TestThread.StartThread;

  FreeAndNil(SSDInfo);
end;
end.
