unit Form.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Math, DateUtils,
  Vcl.Imaging.pngimage, System.UITypes, Device.PhysicalDrive,
  uSizeStrings, MeasureUnit.DataSize, uRandomBuffer, uGSTestThread,
  Setting.Test.ParamGetter, Setting.Test, Trace.List, Form.Setting,
  Form.Retention;

const
  WM_AFTER_SHOW = WM_USER + 300;

  OuterPadding = 10;
  InnerPadding = 5;
  HalfPadding = InnerPadding;
  BufferSize = 16 shl 10;

  CapacityOf128GB = 250069680;

type
  TResizeUnit = record
    Name: TLabel;
    DynamicText: TStaticText;
    Progressbar: TProgressBar;
    LeftLabel, RightLabel: TLabel;
  end;

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
    tSave: TTimer;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bForceRetenClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure lForceRetenMouseEnter(Sender: TObject);
    procedure lForceRetenMouseLeave(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    FNeedRetention: Boolean;
    FRepeatRetention: Boolean;
    FTestSetting: TTestSetting;
    FTestThread: TGSTestThread;
    procedure WmAfterShow(var Msg: TMessage); message WM_AFTER_SHOW;
    procedure RealignStatusComponents(const BasicTop: Integer;
      const ResizeUnit: TResizeUnit);
    procedure RealignStatusBasicComponents(const BasicTop: Integer;
      const ResizeUnit: TResizeUnit);
    procedure RealignStatusLabels(const ResizeUnit: TResizeUnit);
    procedure gStatusRealign;
    procedure gFirstSetRealign;
    procedure RealignButtons;
    procedure gAlertRealign;
    procedure OpenRetentionSaveFormIfNeeded;
    procedure StopTestThread;
    function GetTestSettingFromForm: TTestSetting;
    procedure StartTestWithSetting;
    procedure SetUIAsSetting;
    procedure LoadTestFromFile;
    procedure PrepareNewTest;
    procedure VerifyRetention;
    procedure Precondition;
    procedure PrepareTestThread(const PhysicalDrive: IPhysicalDrive);
    procedure SetTestThreadProperties(const PhysicalDrive: IPhysicalDrive);
    procedure AlignDestinationAddress(const CurrBasicTop: Integer);
    procedure AlignDestinationModel(const CurrBasicTop: Integer);
    procedure AlignDestinationSerial(const CurrBasicTop: Integer);
    procedure AlignTBWToWrite(const CurrBasicTop: Integer);
    procedure AlignTBWToRetention(const CurrBasicTop: Integer);
    procedure AlignMaxFFR(const CurrBasicTop: Integer);
    procedure RealignGroupboxHorizontal;
    procedure RealignGroupboxVertical;
    procedure RealignComponentsInGroupbox;
    procedure ResizeImages;
    function GetGoodFontSize(const UnitSize: Integer): Integer;
    function GetVerticalMiddlePointOfButtons: Integer;
    procedure RealignButtonTop(const MiddlePoint: Integer);
    procedure RealignButtonLeft;
    procedure SetButtonFont(const NewFontSize: Integer);
    procedure AskForRepeatRetention;
    procedure AddVerifyResultToLog;
    procedure AddTestClosedNormallyToLog;

  public
    property TestSetting: TTestSetting read FTestSetting;
    property RepeatRetention: Boolean read FRepeatRetention;
    property NeedRetention: Boolean read FNeedRetention;
    function GetLogLine(Name: String; Contents: String = ''): String;
  end;

var
  fMain: TfMain;
  AppPath: String;

implementation

{$R *.dfm}

procedure TfMain.bForceRetenClick(Sender: TObject);
begin
  lAlert.Items.Add(GetLogLine('���� ���ټ� �׽�Ʈ'));
  FNeedRetention := true;
  Close;
end;

procedure TfMain.bSaveClick(Sender: TObject);
begin
  lAlert.Items.Add(GetLogLine('���� �� ����'));
  FNeedRetention := false;
  Close;
end;

procedure TfMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (FTestThread <> nil) and
     (FRepeatRetention = false) then
    AddTestClosedNormallyToLog;
  StopTestThread;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  AppPath := ExtractFilePath(Application.ExeName);

  sDestPath.Caption := '';
  sDestModel.Caption := '';
  sDestSerial.Caption := '';
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FTestSetting);
end;

procedure TfMain.FormResize(Sender: TObject);
begin
  RealignGroupboxHorizontal;
  RealignGroupboxVertical;
  RealignComponentsInGroupbox;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
  PostMessage(Self.Handle, WM_AFTER_SHOW, 0, 0);
end;

procedure TfMain.gStatusRealign;
  function GetTestProgressResizeUnit: TResizeUnit;
  begin
    result.Name := lTestProgress;
    result.DynamicText := sTestProgress;
    result.Progressbar := pTestProgress;
    result.LeftLabel := nil;
    result.RightLabel := nil;
  end;
  function GetAverageLatencyResizeUnit: TResizeUnit;
  begin
    result.Name := lAvgLatency;
    result.DynamicText := sAvgLatency;
    result.Progressbar := pAvgLatency;
    result.LeftLabel := lAvgAlertL;
    result.RightLabel := lAvgAlertR;
  end;
  function GetMaxLatencyResizeUnit: TResizeUnit;
  begin
    result.Name := lMaxLatency;
    result.DynamicText := sMaxLatency;
    result.Progressbar := pMaxLatency;
    result.LeftLabel := lMaxAlertL;
    result.RightLabel := lMaxAlertR;
  end;
  function GetFFRResizeUnit: TResizeUnit;
  begin
    result.Name := lFFR;
    result.DynamicText := sFFR;
    result.Progressbar := pFFR;
    result.LeftLabel := lFFRL;
    result.RightLabel := lFFRR;
  end;
var
  UnitSize: Integer;
  CurrBasicTop: Integer;
begin
  UnitSize := sTestProgress.Height + lTestProgress.Height +
    (OuterPadding shl 1);

  CurrBasicTop := OuterPadding;
  RealignStatusComponents(CurrBasicTop, GetTestProgressResizeUnit);
  Inc(CurrBasicTop, UnitSize);
  RealignStatusComponents(CurrBasicTop, GetAverageLatencyResizeUnit);
  Inc(CurrBasicTop, UnitSize);
  RealignStatusComponents(CurrBasicTop, GetMaxLatencyResizeUnit);
  Inc(CurrBasicTop, UnitSize);
  RealignStatusComponents(CurrBasicTop, GetFFRResizeUnit);
end;

procedure TfMain.lForceRetenMouseEnter(Sender: TObject);
begin
  if Sender is TLabel then
    TLabel(Sender).Font.Color := clHighlight;
end;

procedure TfMain.lForceRetenMouseLeave(Sender: TObject);
begin
  if Sender is TLabel then
    TLabel(Sender).Font.Color := clWindowText;
end;

procedure TfMain.RealignStatusBasicComponents(const BasicTop: Integer;
  const ResizeUnit: TResizeUnit);
begin
  ResizeUnit.Name.Top := BasicTop;
  ResizeUnit.DynamicText.Top := BasicTop;
  ResizeUnit.Progressbar.Top :=
    ResizeUnit.DynamicText.Top + ResizeUnit.DynamicText.Height + InnerPadding;
  ResizeUnit.Progressbar.Width :=
    gStatus.Width - (ResizeUnit.Progressbar.Left shl 1);
end;

procedure TFMain.RealignStatusComponents(const BasicTop: Integer;
  const ResizeUnit: TResizeUnit);
begin
  RealignStatusBasicComponents(BasicTop, ResizeUnit);

  if ResizeUnit.LeftLabel <> nil then
    RealignStatusLabels(ResizeUnit);
end;

procedure TfMain.gFirstSetRealign;
var
  UnitSize: Integer;
  CurrBasicTop: Integer;
begin
  UnitSize := lDest.Height + OuterPadding + InnerPadding;
  CurrBasicTop := OuterPadding;
  AlignDestinationAddress(CurrBasicTop);
  Inc(CurrBasicTop, UnitSize - OuterPadding);
  AlignDestinationModel(CurrBasicTop);
  Inc(CurrBasicTop, UnitSize - OuterPadding);
  AlignDestinationSerial(CurrBasicTop);
  Inc(CurrBasicTop, UnitSize);
  AlignTBWToWrite(CurrBasicTop);
  Inc(CurrBasicTop, UnitSize);
  AlignTBWToRetention(CurrBasicTop);
  Inc(CurrBasicTop, UnitSize);
  AlignMaxFFR(CurrBasicTop);
end;

procedure TfMain.RealignButtons;
var
  UnitSize: Integer;
  NewFontSize: Integer;
  MiddlePoint: Integer;
begin
  UnitSize := (gStatus.Width - (OuterPadding shl 1)) shr 1;
  ResizeImages;

  lForceReten.Left := iForceReten.Left + iForceReten.Width + InnerPadding;
  NewFontSize := GetGoodFontSize(UnitSize);
  SetButtonFont(NewFontSize);

  MiddlePoint := GetVerticalMiddlePointOfButtons;
  RealignButtonTop(MiddlePoint);
  RealignButtonLeft;
end;

function TfMain.GetLogLine(Name, Contents: String): String;
begin
  result := FormatDateTime('[yyyy/mm/dd hh:nn:ss] ', Now) + Name;
  if Contents <> '' then
    result := result + ': ' + Contents;
end;

procedure TfMain.AddTestClosedNormallyToLog;
begin
  FTestThread.AddToAlert(GetLogLine('�׽�Ʈ ���� ����',
    '���ⷮ - ' + GetByte2TBWStr(FTestThread.HostWrite) +
    ' / ���� ���� - ' + Format('%.2f%s', [FTestThread.AvgLatency, 'ms']) +
    ' / �ִ� ���� - ' + Format('%.2f%s', [FTestThread.MaxLatency, 'ms'])));
end;

procedure TfMain.AddVerifyResultToLog;
begin
  if fRetention.bStart.Visible = false then
    FTestThread.AddToAlert(GetLogLine('���ټ� �׽�Ʈ ����',
      'UBER - ' + FloatToStr(fRetention.UBER)))
  else
    FTestThread.AddToAlert(GetLogLine('���ټ� �׽�Ʈ ���� ����'));
end;

procedure TfMain.AskForRepeatRetention;
begin
  if MessageDlg('���ټ� �׽�Ʈ�� �ݺ��Ͻðڽ��ϱ�?', mtWarning, mbOKCancel, 
    0) = mrOK then
  begin
    FNeedRetention := true;
    FRepeatRetention := true;
  end;
end;

procedure TfMain.SetButtonFont(const NewFontSize: Integer);
begin
  lForceReten.Font.Size := NewFontSize;
  lSave.Font.Size := NewFontSize;
end;

procedure TfMain.RealignButtonLeft;
begin
  iSave.Left := (gStatus.Width shr 1) + iForceReten.Left;
  lSave.Left := iSave.Left + iSave.Width + InnerPadding;
end;

procedure TfMain.RealignButtonTop(const MiddlePoint: Integer);
begin
  lForceReten.Top := MiddlePoint - (lForceReten.Height shr 1);
  iForceReten.Top := MiddlePoint - (iForceReten.Height shr 1);
  iSave.Top := iForceReten.Top;
  lSave.Top := lForceReten.Top;
end;

function TfMain.GetVerticalMiddlePointOfButtons: Integer;
var
  MiddlePointOfLabel, MiddlePointOfImage: Integer;
begin
  MiddlePointOfLabel :=
    gStatus.Height - lForceReten.Height - OuterPadding +
    (lForceReten.Height shr 1);
  MiddlePointOfImage :=
    gStatus.Height - iForceReten.Height - OuterPadding +
    (iForceReten.Height shr 1);
  result := Min(MiddlePointOfLabel, MiddlePointOfImage);
end;

function TfMain.GetGoodFontSize(const UnitSize: Integer): Integer;
var
  ForceRetenWidth: Integer;
begin
  result := lForceReten.Font.Size;
  ForceRetenWidth := lForceReten.Left + lForceReten.Width;
  lForceReten.Font.Size := 9;
  while ForceRetenWidth < UnitSize do
  begin
    result := lForceReten.Font.Size;
    lForceReten.Font.Size := lForceReten.Font.Size + 1;
    ForceRetenWidth := lForceReten.Left + lForceReten.Width;
  end;
end;

procedure TfMain.ResizeImages;
begin
  iForceReten.Width := gStatus.Width div 10;
  iForceReten.Height := iForceReten.Width;
  iSave.Width := gStatus.Width div 10;
  iSave.Height := iSave.Width;
end;

procedure TfMain.RealignStatusLabels(const ResizeUnit: TResizeUnit);
begin
  ResizeUnit.LeftLabel.Top := ResizeUnit.Progressbar.Top;
  ResizeUnit.RightLabel.Top := ResizeUnit.Progressbar.Top;
  ResizeUnit.RightLabel.Left :=
    ResizeUnit.Progressbar.Left + ResizeUnit.Progressbar.Width +
    (ResizeUnit.Progressbar.Left - ResizeUnit.LeftLabel.Left -
      ResizeUnit.LeftLabel.Width);
end;

procedure TfMain.RealignComponentsInGroupbox;
begin
  gStatusRealign;
  gFirstSetRealign;
  RealignButtons;
  gAlertRealign;
end;

procedure TfMain.RealignGroupboxVertical;
begin
  gStatus.Top := iLogo.Top + iLogo.Height + OuterPadding;
  gFirstSet.Top := gStatus.Top;
  gFirstSet.Height := ((ClientHeight - (OuterPadding shl 1)) div 2) -
    HalfPadding;
  gStatus.Height := gFirstSet.Height;
  gAlert.Top := gStatus.Top + gStatus.Height + OuterPadding;
  gAlert.Height := ClientHeight -
    (gStatus.Top + gStatus.Height + (OuterPadding shl 1));
end;

procedure TfMain.RealignGroupboxHorizontal;
begin
  gFirstSet.Left := (ClientWidth div 2) + HalfPadding;
  gStatus.Width := (ClientWidth div 2) - (OuterPadding + HalfPadding);
  gFirstSet.Width := (ClientWidth div 2) - (OuterPadding + HalfPadding);
  gAlert.Width := ClientWidth - (OuterPadding shl 1);
end;

procedure TfMain.AlignMaxFFR(const CurrBasicTop: Integer);
begin
  lMaxFFR.Left := lDest.Left;
  lMaxFFR.Top := CurrBasicTop;
  sMaxFFR.Top := CurrBasicTop;
  sMaxFFR.Left := lMaxFFR.Left + lMaxFFR.Width + OuterPadding;
end;

procedure TfMain.AlignTBWToRetention(const CurrBasicTop: Integer);
begin
  lRetention.Left := lDest.Left;
  lRetention.Top := CurrBasicTop;
  sRetention.Top := CurrBasicTop;
  sRetention.Left := lRetention.Left + lRetention.Width + OuterPadding;
end;

procedure TfMain.AlignTBWToWrite(const CurrBasicTop: Integer);
begin
  lDestTBW.Left := lDest.Left;
  lDestTBW.Top := CurrBasicTop;
  sDestTBW.Top := CurrBasicTop;
  sDestTBW.Left := lDestTBW.Left + lDestTBW.Width + OuterPadding;
end;

procedure TfMain.AlignDestinationSerial(const CurrBasicTop: Integer);
begin
  sDestSerial.Top := CurrBasicTop;
  sDestSerial.Left := sDestPath.Left;
end;

procedure TfMain.AlignDestinationModel(const CurrBasicTop: Integer);
begin
  sDestModel.Top := CurrBasicTop;
  sDestModel.Left := sDestPath.Left;
end;

procedure TfMain.AlignDestinationAddress(const CurrBasicTop: Integer);
begin
  lDest.Top := CurrBasicTop;
  lDest.Left := lTestProgress.Left;
  sDestPath.Top := lDest.Top;
  sDestPath.Left := lDest.Left + lDest.Width + OuterPadding;
end;

procedure TfMain.SetTestThreadProperties(const PhysicalDrive: IPhysicalDrive);
begin
  FTestThread.SetDisk(TestSetting.DiskNumber);
  FTestThread.MaxLBA := PhysicalDrive.IdentifyDeviceResult.UserSizeInKB * 2;
  FTestThread.OrigLBA := CapacityOf128GB;
  FTestThread.Align := 512;
  FTestThread.MaxFFR := TestSetting.MaxFFR;
  FTestThread.MaxHostWrite := TestSetting.TBWToWrite;
  FTestThread.RetentionTest := TestSetting.TBWToRetention;
  FTestThread.Path := TestSetting.LogSavePath;
  FTestThread.AssignAlertPath(TestSetting.LogSavePath + 'alert.txt');
  FTestThread.AssignBufferSetting(BufferSize, 100);
end;

procedure TfMain.StopTestThread;
begin
  if FTestThread <> nil then
  begin
    FTestThread.Terminate;
    WaitForSingleObject(FTestThread.Handle, 60);
    FNeedRetention := FNeedRetention or (FTestThread.ExitCode = EXIT_RETENTION);
    FreeAndNil(FTestThread);
    OpenRetentionSaveFormIfNeeded;
  end;
end;

procedure TfMain.OpenRetentionSaveFormIfNeeded;
begin
  if FNeedRetention then
  begin
    fRetention := TfRetention.Create(self,
      TPhysicalDrive.BuildFileAddressByNumber(FTestSetting.DiskNumber));
    fRetention.ShowModal;
  end;
end;

procedure TfMain.gAlertRealign;
begin
  lAlert.Width := gAlert.Width - (lAlert.Left shl 1);
  lAlert.Height := gAlert.Height - (OuterPadding shl 1);
end;

function TfMain.GetTestSettingFromForm: TTestSetting;
var
  TestSettingParamFromForm: TTestSettingParamFromForm;
begin
  TestSettingParamFromForm :=
    (TTestSettingParamGetter.GetInstance as TTestSettingParamGetter).
      GetValuesFromForm(fSetting);
  result :=
    TTestSetting.Create(
      TestSettingParamFromForm,
      TTestSettingParamGetter.GetInstance.GetValuesFromDrive(
        TestSettingParamFromForm.FDiskNumber));
end;

procedure TfMain.SetUIAsSetting;
begin
  sDestPath.Caption :=
    TPhysicalDrive.BuildFileAddressByNumber(TestSetting.DiskNumber);
  sDestModel.Caption :=
    TestSetting.Model +
    ' (' + IntToStr(TestSetting.Capacity) + 'GB)';
  sDestSerial.Caption := TestSetting.Serial;
  sDestTBW.Caption :=
    IntToStr(TestSetting.TBWToWrite) + 'TBW / ' +
    GetDayStr((TestSetting.TBWToWrite shl 10) / 10);
  sRetention.Caption :=
    IntToStr(TestSetting.TBWToRetention) + 'TBW / ' +
    GetDayStr((TestSetting.TBWToRetention shl 10) / 10);
  sMaxFFR.Caption := IntToStr(TestSetting.MaxFFR) + '%';
end;

procedure TfMain.LoadTestFromFile;
begin
  FTestThread.Load(fSetting.SavePath + 'settings.ini');
  if FTestThread.NeedVerify then
    VerifyRetention;
end;

procedure TfMain.VerifyRetention;
begin
  fRetention := TfRetention.Create(self,
    TPhysicalDrive.BuildFileAddressByNumber(TestSetting.DiskNumber));
  fRetention.SetAsMode(rsmVerify, fSetting.SavePath + 'compare_error_log.txt');
  fRetention.ShowModal;
  AddVerifyResultToLog;
  FreeAndNil(fRetention);
  AskForRepeatRetention;
end;

procedure TfMain.Precondition;
begin
  fRetention := TfRetention.Create(self,
    TPhysicalDrive.BuildFileAddressByNumber(TestSetting.DiskNumber));
  fRetention.SetAsMode(rsmPreCond, fSetting.SavePath);
  fRetention.ShowModal;
end;

procedure TfMain.PrepareNewTest;
begin
  Precondition;
  FTestThread.SetHostWrite(fRetention.Written);
  FTestThread.AddToAlert(
    GetLogLine('�׽�Ʈ ���� �غ� �Ϸ�',
      '���ⷮ - ' + GetByte2TBWStr(fRetention.Written)));
  FreeAndNil(fRetention);
end;

procedure TfMain.PrepareTestThread(const PhysicalDrive: IPhysicalDrive);
begin
  if fSetting.NeedToLoad then
    LoadTestFromFile
  else
    PrepareNewTest;
  SetTestThreadProperties(PhysicalDrive);
end;

procedure TfMain.StartTestWithSetting;
var
  PhysicalDrive: IPhysicalDrive;
begin
  SetUIAsSetting;
  Application.ProcessMessages;

  PhysicalDrive := TPhysicalDrive.Create(
    TPhysicalDrive.BuildFileAddressByNumber(TestSetting.DiskNumber));
  FTestThread :=
    TGSTestThread.Create(fSetting.TracePath, true,
      PhysicalDrive.IdentifyDeviceResult.UserSizeInKB shr 9);
  FRepeatRetention := false;
  PrepareTestThread(PhysicalDrive);
  if FRepeatRetention then
  begin
    Close;
    exit;
  end;
  FTestThread.StartThread;
end;

procedure TfMain.WmAfterShow(var Msg: TMessage);
begin
  fSetting := TfSetting.Create(self);
  fSetting.ShowModal;
  try
    FTestSetting := GetTestSettingFromForm;
    StartTestWithSetting;
  except
    on E: ENoDriveSelectedException do
      Close
    else
      raise;
  end;
  FreeAndNil(fSetting);
end;
end.
