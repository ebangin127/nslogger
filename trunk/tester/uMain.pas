unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Math, DateUtils,
  uRandomBuffer, uGSTestThread, uGSList, uSSDInfo, uTrimCommand,
  uDiskFunctions, uSetting, uRetSel, Vcl.Imaging.pngimage;

const
  WM_AFTER_SHOW = WM_USER + 300;

  OuterPadding = 10;
  InnerPadding = 5;
  HalfPadding = InnerPadding;

  CapacityOf128GB = 250069680;

type
  TfMain = class(TForm)
    gStatus: TGroupBox;
    lAvgLatency: TLabel;
    lMaxLatency: TLabel;
    pAvgLatency: TProgressBar;
    pMaxLatency: TProgressBar;
    sAvgLatency: TStaticText;
    sMaxLatency: TStaticText;
    gFirstSet: TGroupBox;
    gAlert: TGroupBox;
    lAlert: TListBox;
    pFFR: TProgressBar;
    sFFR: TStaticText;
    lFFR: TLabel;
    pTestProgress: TProgressBar;
    sTestProgress: TStaticText;
    lTestProgress: TLabel;
    lMaxAlertL: TLabel;
    lAvgAlertL: TLabel;
    lMaxAlertR: TLabel;
    lAvgAlertR: TLabel;
    lFFRR: TLabel;
    lFFRL: TLabel;
    iForceReten: TImage;
    lForceReten: TLabel;
    iSave: TImage;
    lSave: TLabel;
    iLogo: TImage;
    lDest: TLabel;
    sDestPath: TStaticText;
    sDestModel: TStaticText;
    sDestSerial: TStaticText;
    lDestTBW: TLabel;
    sDestTBW: TStaticText;
    sRetention: TStaticText;
    lRetention: TLabel;
    lMaxFFR: TLabel;
    sMaxFFR: TStaticText;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bForceRetenClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lForceRetenMouseEnter(Sender: TObject);
    procedure lForceRetenMouseLeave(Sender: TObject);
  private
    FDiskNum: Integer;
    FDestDriveModel: String;
    FDestDriveSerial: String;
    FDestDriveCapacity: INT64;
    FDestTBW: Integer;
    FRetentionTBW: Integer;
    FMaxFFR: Integer;
    FSaveFilePath: String;
    FNeedRetention: Boolean;

    procedure WmAfterShow(var Msg: TMessage); message WM_AFTER_SHOW;
    procedure ResizeStatusComponents(BasicTop: Integer;
                                 InnerPadding, OuterPadding: Integer;
                                 gParent: TGroupBox;
                                 lName: TLabel; sDynText: TStaticText;
                                 pProgress: TProgressBar;
                                 lProgressL, lProgressR: TLabel); inline;

    procedure gStatusResize;
    procedure gFirstSetResize;
    procedure gChangeStateResize;
    procedure gAlertResize;
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
const
  BUTTON_MINIMUM_HEIGHT = 65;
var
  UnitSize: Double;
begin
  //가로
  //한 칸 10 + 반 칸 5
  gFirstSet.Left := (ClientWidth div 2) + HalfPadding;
  gStatus.Width := (ClientWidth div 2) - (OuterPadding + HalfPadding);
  gFirstSet.Width := (ClientWidth div 2) - (OuterPadding + HalfPadding);
  gAlert.Width := ClientWidth - (OuterPadding shl 1);

  //세로 - 순서가 바뀌어선 안 됨
  gStatus.Top := iLogo.Top + iLogo.Height + OuterPadding;
  gFirstSet.Top := gStatus.Top;
  gFirstSet.Height := ((ClientHeight - (OuterPadding shl 1)) div 2)
                       - HalfPadding;
  gStatus.Height := gFirstSet.Height;
  gAlert.Top := gStatus.Top + gStatus.Height + OuterPadding;
  gAlert.Height := ClientHeight - (gStatus.Top + gStatus.Height
                                    + (OuterPadding shl 1));

  //각 컴포넌트에 크기조절 요청
  gStatusResize;
  gFirstSetResize;
  gChangeStateResize;
  gAlertResize;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
  PostMessage(Self.Handle, WM_AFTER_SHOW, 0, 0);
end;

procedure TfMain.gStatusResize;
var
  UnitSize: Integer;
  CurrBasicTop: Integer;
begin
  UnitSize := sTestProgress.Height + lTestProgress.Height
              + (OuterPadding shl 1);

  //테스트 진행
  CurrBasicTop := OuterPadding;
  lTestProgress.Top := CurrBasicTop;
  sTestProgress.Top := CurrBasicTop;
  pTestProgress.Top := sTestProgress.Top + sTestProgress.Height + InnerPadding;
  pTestProgress.Width := gStatus.Width - pTestProgress.Left;
  ResizeStatusComponents(CurrBasicTop, InnerPadding, OuterPadding, gStatus,
                         lTestProgress, sTestProgress, pTestProgress, nil,
                         nil);

  //평균 지연
  Inc(CurrBasicTop, UnitSize);
  ResizeStatusComponents(CurrBasicTop, InnerPadding, OuterPadding, gStatus,
                         lAvgLatency, sAvgLatency, pAvgLatency, lAvgAlertL,
                         lAvgAlertR);

  //최대 지연
  Inc(CurrBasicTop, UnitSize);
  ResizeStatusComponents(CurrBasicTop, InnerPadding, OuterPadding, gStatus,
                         lMaxLatency, sMaxLatency, pMaxLatency, lMaxAlertL,
                         lMaxAlertR);

  //기능 실패율
  Inc(CurrBasicTop, UnitSize);
  ResizeStatusComponents(CurrBasicTop, InnerPadding, OuterPadding, gStatus,
                         lFFR, sFFR, pFFR, lFFRL, lFFRR);
end;

procedure TfMain.lForceRetenMouseEnter(Sender: TObject);
begin
  if Sender is TLabel then
    TLabel(Sender).Font.Color := clHighlightText;
end;

procedure TfMain.lForceRetenMouseLeave(Sender: TObject);
begin
  if Sender is TLabel then
    TLabel(Sender).Font.Color := clWindowText;
end;

procedure TFMain.ResizeStatusComponents(BasicTop: Integer;
                                        InnerPadding, OuterPadding: Integer;
                                        gParent: TGroupBox;
                                        lName: TLabel; sDynText: TStaticText;
                                        pProgress: TProgressBar;
                                        lProgressL, lProgressR: TLabel);
begin
  lName.Top := BasicTop;
  sDynText.Top := BasicTop;
  pProgress.Top := sDynText.Top + sDynText.Height + InnerPadding;
  pProgress.Width := gParent.Width - (pProgress.Left shl 1);

  if lProgressR <> nil then
  begin
    lProgressL.Top := pProgress.Top;
    lProgressR.Top := pProgress.Top;

    lProgressR.Left := pProgress.Left + pProgress.Width +
                        + (pProgress.Left - lProgressL.Left - lProgressL.Width);
  end;
end;

procedure TfMain.gFirstSetResize;
var
  UnitSize: Integer;
  CurrBasicTop: Integer;
begin
  UnitSize := lDest.Height + OuterPadding + InnerPadding;

  //대상 주소
  CurrBasicTop := OuterPadding;
  lDest.Top := CurrBasicTop;
  lDest.Left := lTestProgress.Left;
  sDestPath.Top := lDest.Top;
  sDestPath.Left := lDest.Left + lDest.Width + OuterPadding;

  //대상 모델
  Inc(CurrBasicTop, UnitSize - OuterPadding);
  sDestModel.Top := CurrBasicTop;
  sDestModel.Left := sDestPath.Left;

  //대상 시리얼
  Inc(CurrBasicTop, UnitSize - OuterPadding);
  sDestSerial.Top := CurrBasicTop;
  sDestSerial.Left := sDestPath.Left;

  //목표 TBW
  Inc(CurrBasicTop, UnitSize);
  lDestTBW.Left := lDest.Left;
  lDestTBW.Top := CurrBasicTop;
  sDestTBW.Top := CurrBasicTop;
  sDestTBW.Left := lDestTBW.Left + lDestTBW.Width + OuterPadding;

  //리텐션 테스트 주기
  Inc(CurrBasicTop, UnitSize);
  lRetention.Left := lDest.Left;
  lRetention.Top := CurrBasicTop;
  sRetention.Top := CurrBasicTop;
  sRetention.Left := lRetention.Left + lRetention.Width + OuterPadding;

  //기능 실패율 상한선
  Inc(CurrBasicTop, UnitSize);
  lMaxFFR.Left := lDest.Left;
  lMaxFFR.Top := CurrBasicTop;
  sMaxFFR.Top := CurrBasicTop;
  sMaxFFR.Left := lMaxFFR.Left + lMaxFFR.Width + OuterPadding;
end;

procedure TfMain.gChangeStateResize;
var
  UnitSize: Integer;
  ForceRetenWidth: Integer;
  LastFontSize: Integer;
  MiddlePoint: Integer;
begin
  UnitSize := (gStatus.Width - (OuterPadding shl 1)) shr 1;

  iForceReten.Width := gStatus.Width div 10;
  iForceReten.Height := iForceReten.Width;
  iSave.Width := gStatus.Width div 10;
  iSave.Height := iSave.Width;

  lForceReten.Left := iForceReten.Left + iForceReten.Width + InnerPadding;
  LastFontSize := lForceReten.Font.Size;
  ForceRetenWidth := lForceReten.Left + lForceReten.Width;
  while ForceRetenWidth < UnitSize do
  begin
    LastFontSize := lForceReten.Font.Size;
    lForceReten.Font.Size := lForceReten.Font.Size + 1;
    ForceRetenWidth := lForceReten.Left + lForceReten.Width;
  end;
  lForceReten.Font.Size := LastFontSize;

  MiddlePoint := Min(gStatus.Height - lForceReten.Height - OuterPadding
                                     + (lForceReten.Height shr 1),
                     gStatus.Height - iForceReten.Height - OuterPadding)
                                     + (iForceReten.Height shr 1);
  lForceReten.Top := MiddlePoint - (lForceReten.Height shr 1);
  iForceReten.Top := MiddlePoint - (iForceReten.Height shr 1);

  iSave.Left := (gStatus.Width shr 1) + iForceReten.Left;
  lSave.Font.Size := LastFontSize;
  lSave.Left := iSave.Left + iSave.Width + InnerPadding;
  lSave.Top := lForceReten.Top;
  iSave.Top := iForceReten.Top;
end;

procedure TfMain.gAlertResize;
begin
  lAlert.Width := gAlert.Width - (lAlert.Left shl 1);
  lAlert.Height := gAlert.Height - (OuterPadding shl 1);
end;

procedure TfMain.WmAfterShow(var Msg: TMessage);
var
  SSDInfo: TSSDInfo;
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

  SSDInfo := TSSDInfo.Create;
  SSDInfo.SetDeviceName(FDiskNum);
  FDestTBW := StrToInt(fSetting.eDestTBW.Text);
  FRetentionTBW := StrToInt(fSetting.eRetentionTBW.Text);
  FDestDriveModel := SSDInfo.Model;
  FDestDriveSerial := SSDInfo.Serial;
  FDestDriveCapacity := floor(SSDInfo.UserSize
                              / 2 / 1024 / 1000 / 1000 * 1024 * 1.024); //In GB
  FMaxFFR := StrToInt(fSetting.eFFR.Text);

  sDestPath.Caption := '\\.\PhysicalDrive' + IntToStr(FDiskNum);
  sDestModel.Caption := FDestDriveModel
                        + ' (' + IntToStr(FDestDriveCapacity) + 'GB)';
  sDestSerial.Caption := FDestDriveSerial;

  sDestTBW.Caption := IntToStr(FDestTBW) + 'TBW / ' +
                      GetDayStr(FDestTBW shl 10 * 10);
  sRetention.Caption := IntToStr(FRetentionTBW) + 'TBW / ' +
                        GetDayStr(FRetentionTBW shl 10 * 10);
  sMaxFFR.Caption := IntToStr(FMaxFFR) + '%';

  Application.ProcessMessages;

  TestThread := TGSTestThread.Create(fSetting.TracePath,
                                     true, SSDInfo.UserSize shr 9);
  if fSetting.LoadedFromFile then
  begin
    TestThread.Load(fSetting.SavePath + 'settings.ini');
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
  TestThread.OrigLBA := CapacityOf128GB;
  TestThread.Align := 512;
  TestThread.MaxFFR := FMaxFFR;

  TestThread.MaxHostWrite := FDestTBW;
  TestThread.RetentionTest := FRetentionTBW;

  TestThread.AssignSavePath(FSaveFilePath);
  TestThread.AssignBufferSetting(128 shl 10, 100);
  TestThread.AssignDLLPath(AppPath + 'parser.dll');
  TestThread.StartThread;

  FreeAndNil(SSDInfo);
end;
end.
