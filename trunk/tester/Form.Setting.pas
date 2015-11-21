unit Form.Setting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  OS.Directory, SaveFile, SaveFile.SettingForm,
  Device.PhysicalDrive, Getter.PartitionList, Vcl.ComCtrls,
  MeasureUnit.DataSize, Getter.PhysicalDriveList.Auto,
  Device.PhysicalDrive.List, LanguageStrings, Getter.DiskLayout,
  Partition.List;

type
  EDriveNotFound = class(EResNotFound);
  EInvalidDrive = class(EArgumentException);
  TfSetting = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    lRetentionTBW: TLabel;
    eRetentionTBW: TEdit;
    bStartNew: TButton;
    lDestination: TLabel;
    lTBW: TLabel;
    bOpenExist: TButton;
    lFFR: TLabel;
    eFFR: TEdit;
    lPercent: TLabel;
    oTrace: TOpenDialog;
    eTracePath: TEdit;
    lTraceOriginalLBA: TLabel;
    lTracePath: TLabel;
    bTracePath: TButton;
    cDestination: TComboBoxEx;
    eTraceOriginalLBA: TEdit;
    lGB: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure bStartNewClick(Sender: TObject);
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bOpenExistClick(Sender: TObject);
    procedure cDestinationKeyPress(Sender: TObject; var Key: Char);
    procedure bTracePathClick(Sender: TObject);
  private
    FOptionsSet: Boolean;
    FDriveList: TList<Integer>;
    FSavePath: String;
    FNeedToLoad: Boolean;
    function GetSavePath: Boolean;
    procedure InsertDriveByNumber(const SaveFile: TSaveFileForSettingForm);
    procedure SetFormBySaveFile(const SaveFile: TSaveFileForSettingForm);
    function IsAllOptionSet: Boolean;
    function IsDestinationSet: Boolean;
    function IsFFRSet: Boolean;
    function IsTBWToRetentionSet: Boolean;
    procedure SetTracePath;
    procedure IfAlertExistsDelete;
    procedure SetSavePath;
    function IsTraceOriginalLBASet: Boolean;
    function IsTracePathSet: Boolean;
  public
    property SavePath: String read FSavePath;
    property NeedToLoad: Boolean read FNeedToLoad;

    function GetDriveNumber: Integer;
  end;

var
  fSetting: TfSetting;
  AppPath: String;

implementation

{$R *.dfm}

procedure TfSetting.bOpenExistClick(Sender: TObject);
var
  SaveFile: TSaveFileForSettingForm;
begin
  if not GetSavePath then
    exit;
  if FileExists(FSavePath + 'settings.ini') = false then
  begin
    ShowMessage(SettingNoTestFileError[CurrLang]);
    exit;
  end;

  SaveFile := TSaveFileForSettingForm.Create(TSaveFile.Create(
    FSavePath + 'settings.ini'));
  try
    SetFormBySaveFile(SaveFile);
  except
    on E: EInvalidDrive do
      MessageBox(Handle, PChar(Caption), PChar(SettingInvalidDrive[CurrLang]),
        MB_OK + MB_ICONERROR);
    else
      raise;
  end;
  FNeedToLoad := true;
  FOptionsSet := true;
  Close;
end;

function TfSetting.IsDestinationSet: Boolean;
begin
  result := cDestination.ItemIndex <> -1;
  if not result then
    ShowMessage(SettingInvalidDrive[CurrLang]);
end;

function TfSetting.IsTBWToRetentionSet: Boolean;
var
  Dummy: Integer;
begin
  result := TryStrToInt(eRetentionTBW.Text, Dummy);
  if not result then
    ShowMessage(SettingInvalidRetentionTestPeriod[CurrLang]);
end;

function TfSetting.IsFFRSet: Boolean;
var
  Dummy: Integer;
begin
  result := TryStrToInt(eFFR.Text, Dummy);
  if not result then
    ShowMessage(SettingInvalidFFR[CurrLang]);
end;

function TfSetting.IsTracePathSet: Boolean;
begin
  result := FileExists(eTracePath.Text);
  if not result then
    ShowMessage(SettingInvalidTracePath[CurrLang]);
end;

function TfSetting.IsTraceOriginalLBASet: Boolean;
var
  Dummy: Integer;
begin
  result := TryStrToInt(eTraceOriginalLBA.Text, Dummy);
  if not result then
    ShowMessage(SettingInvalidOriginalLBA[CurrLang]);
end;

function TfSetting.IsAllOptionSet: Boolean;
begin
  result :=
    IsDestinationSet and
    IsTBWToRetentionSet and
    IsFFRSet and
    IsTracePathSet and
    IsTraceOriginalLBASet;
end;

procedure TfSetting.SetTracePath;
begin
  if FileExists(AppPath + 'mt.txt') then
    eTracePath.Text := AppPath + 'mt.txt';
end;

procedure TfSetting.SetSavePath;
  function IsUserNeedOverwrite: Boolean;
  begin
    result := MessageDlg(SettingOverwriteLog[CurrLang], mtWarning,
      mbOKCancel, 0) = mrOk;
  end;
begin
  repeat
    //FSavePath := SelectDirectory(SettingSelectFolderToSaveLog[CurrLang],
    //  AppPath);
    FSavePath := 'D:\Logs\';
    if FSavePath = '' then
      exit;

    if FileExists(FSavePath + 'settings.ini') then
    begin
      if IsUserNeedOverwrite then
        DeleteFile(FSavePath + 'settings.ini')
      else
      begin
        FSavePath := '';
        exit;
      end;
    end;
  until FSavePath <> '';
end;

procedure TfSetting.bStartNewClick(Sender: TObject);
begin
  if not IsAllOptionSet then
    exit;

  SetSavePath;
  if FSavePath = '' then
    exit;

  IfAlertExistsDelete;

  FOptionsSet := true;
  Close;
end;

procedure TfSetting.bTracePathClick(Sender: TObject);
begin
  if oTrace.Execute then
    eTracePath.Text := oTrace.FileName;
end;

procedure TfSetting.cDestinationKeyPress(Sender: TObject; var Key: Char);
begin
  Key := #0;
end;

procedure TfSetting.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;
  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;

  FOptionsSet := false;
  FNeedToLoad := false;

  AppPath := ExtractFilePath(Application.ExeName);

  FDriveList := TList<Integer>.Create;
  RefreshDrives;
  SetTracePath;
end;

procedure TfSetting.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDriveList);
end;

function TfSetting.GetDriveNumber: Integer;
begin
  if (FOptionsSet = false) or (cDestination.ItemIndex = -1) then
    exit(-1);

  exit(FDriveList[cDestination.ItemIndex]);
end;

procedure TfSetting.IfAlertExistsDelete;
begin
  if FileExists(FSavePath + 'alert.txt') then
    DeleteFile(PChar(FSavePath + 'alert.txt'));
end;

procedure TfSetting.SetFormBySaveFile(const SaveFile: TSaveFileForSettingForm);
begin
  if FDriveList.IndexOf(SaveFile.GetDiskNumber) >= 0 then
    InsertDriveByNumber(SaveFile)
  else
    raise EInvalidDrive.Create(SettingInvalidDrive[CurrLang]);
  eRetentionTBW.Text := IntToStr(SaveFile.GetTBWToRetention shr ByteToTB);
  eTracePath.Text := SaveFile.GetTracePath;
  eTraceOriginalLBA.Text := SaveFile.GetTraceOriginalLBA;
end;

procedure TfSetting.InsertDriveByNumber(const SaveFile:
  TSaveFileForSettingForm);
begin
  FDriveList.Insert(0, SaveFile.GetDiskNumber);
  cDestination.Items.Insert(0, 'Open');
  cDestination.ItemIndex := 0;
end;

function TfSetting.GetSavePath: Boolean;
begin
  FSavePath := SelectDirectory(SettingSelectFolderSavedLog[CurrLang], AppPath);
  result := FSavePath <> '';
end;

procedure TfSetting.RefreshDrives;
var
  DriveList: TPhysicalDriveList;
  DiskLayoutGetter: TDiskLayoutGetter;
  PartitionList: TPartitionList;
  PhysicalDrive: IPhysicalDrive;
  CurrentDriveNumber: Integer;
begin
  DriveList := AutoPhysicalDriveListGetter.GetPhysicalDriveList;
  if DriveList = nil then
    exit;
  for PhysicalDrive in DriveList do
  begin
    DiskLayoutGetter :=
      TDiskLayoutGetter.Create(PhysicalDrive.GetPathOfFileAccessing);
    PartitionList := DiskLayoutGetter.GetPartitionList;
    FreeAndNil(DiskLayoutGetter);
    if (PartitionList <> nil) and (PartitionList.Count = 0) then
    begin
      CurrentDriveNumber :=
        StrToInt(PhysicalDrive.GetPathOfFileAccessingWithoutPrefix);
      FDriveList.Add(CurrentDriveNumber);
      cDestination.Items.Add(
        PhysicalDrive.GetPathOfFileAccessingWithoutPrefix + ' - ' +
        PhysicalDrive.IdentifyDeviceResult.Model);
      if cDestination.ItemIndex = -1 then
        cDestination.ItemIndex := 0;
    end;
    FreeAndNil(PartitionList);
  end;
  FreeAndNil(DriveList);
end;

end.
