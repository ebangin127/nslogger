unit Form.Setting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  Windows.Directory, uSaveFile, Tester.Thread, Device.PhysicalDrive,
  uPartitionListGetter, Vcl.ComCtrls, uAutoPhysicalDriveListGetter,
  uPhysicalDriveList, uLanguageSettings;

type
  EDriveNotFound = class(EResNotFound);

  TfSetting = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    eDestTBW: TEdit;
    Label2: TLabel;
    eRetentionTBW: TEdit;
    bStartNew: TButton;
    Label5: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    bOpenExist: TButton;
    Label6: TLabel;
    eFFR: TEdit;
    Label7: TLabel;
    oTrace: TOpenDialog;
    cDestination: TComboBoxEx;
    procedure FormCreate(Sender: TObject);
    procedure bStartNewClick(Sender: TObject);
    function FindDrive(Model, Serial: String): Integer;
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bOpenExistClick(Sender: TObject);
    procedure cDestinationKeyPress(Sender: TObject; var Key: Char);
  private
    FOptionsSet: Boolean;
    FDriveList: TList<Integer>;
    FSavePath: String;
    FTracePath: String;
    FNeedToLoad: Boolean;
    function GetSavePath: Boolean;
    procedure InsertDriveByNumber(SaveFile: TSaveFile);
    procedure InsertDriveByModelSerial(SaveFile: TSaveFile);
    procedure SetFormBySaveFile(SaveFile: TSaveFile);
    function IsAllOptionSet: Boolean;
    function IsDestinationSet: Boolean;
    function IsFFRSet: Boolean;
    function IsMaxTBWBiggerThanRetentionTBW: Boolean;
    function IsTBWToRetentionSet: Boolean;
    function IsTBWToWriteSet: Boolean;
    procedure SetTracePath;
    procedure IfAlertExistsDelete;
    procedure SetSavePath;
  public
    property SavePath: String read FSavePath;
    property TracePath: String read FTracePath;
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
  SaveFile: TSaveFile;
begin
  if not GetSavePath then
    exit;
  if FileExists(FSavePath + 'settings.ini') = false then
  begin
    ShowMessage(SettingNoTestFileError[CurrLang]);
    exit;
  end;

  SaveFile := TSaveFile.Create;
  SaveFile.LoadFromFile(FSavePath + 'settings.ini');
  SetFormBySaveFile(SaveFile);
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

function TfSetting.IsTBWToWriteSet: Boolean;
var
  Dummy: Integer;
begin
  result := TryStrToInt(eDestTBW.Text, Dummy);
  if not result then
    ShowMessage(SettingInvalidTBWToWrite[CurrLang]);
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

function TfSetting.IsMaxTBWBiggerThanRetentionTBW: Boolean;
begin
  result := StrToInt(eDestTBW.Text) >= StrToInt(eRetentionTBW.Text);
  if not result then
    ShowMessage(SettingTBWToWriteIsLowerThanPeriod[CurrLang]);
end;

function TfSetting.IsAllOptionSet: Boolean;
begin
  result :=
    IsDestinationSet and
    IsTBWToWriteSet and
    IsTBWToRetentionSet and
    IsFFRSet and
    IsMaxTBWBiggerThanRetentionTBW;
end;

procedure TfSetting.SetTracePath;
begin
  FTracePath := AppPath + 'mt.txt';
  while (FTracePath = '') or (not(FileExists(FTracePath))) do
  begin
    if oTrace.Execute = false then
      exit;

    FTracePath := oTrace.FileName;
  end;
end;

procedure TfSetting.SetSavePath;
  function IsUserNeedOverwrite: Boolean;
  begin
    result := MessageDlg(SettingOverwriteLog[CurrLang], mtWarning,
      mbOKCancel, 0) = mrOk;
  end;
begin
  repeat
    FSavePath := SelectDirectory(SettingSelectFolderToSaveLog[CurrLang],
      AppPath);
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

  SetTracePath;
  if FTracePath = '' then
    exit;

  SetSavePath;
  if FSavePath = '' then
    exit;

  IfAlertExistsDelete;

  FOptionsSet := true;
  Close;
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

procedure TfSetting.SetFormBySaveFile(SaveFile: TSaveFile);
begin
  if FDriveList.IndexOf(SaveFile.Disknum) >= 0 then
    InsertDriveByNumber(SaveFile)
  else
    InsertDriveByModelSerial(SaveFile);
  eDestTBW.Text := IntToStr(SaveFile.MaxTBW shr ByteToTB);
  eRetentionTBW.Text := IntToStr(SaveFile.RetTBW shr ByteToTB);
end;

procedure TfSetting.InsertDriveByNumber(SaveFile: TSaveFile);
begin
  FDriveList.Insert(0, SaveFile.Disknum);
  cDestination.Items.Insert(0, 'Open');
  cDestination.ItemIndex := 0;
end;

procedure TfSetting.InsertDriveByModelSerial(SaveFile: TSaveFile);
begin
  FDriveList.Insert(0, FindDrive(SaveFile.Model, SaveFile.Serial));
  cDestination.Items.Insert(0, 'Open');
  cDestination.ItemIndex := 0;
end;

function TfSetting.GetSavePath: Boolean;
begin
  FSavePath := SelectDirectory(SettingSelectFolderSavedLog[CurrLang], AppPath);
  result := FSavePath <> '';
end;

function TfSetting.FindDrive(Model, Serial: String): Integer;
var
  DriveList: TPhysicalDriveList;
  PhysicalDrive: IPhysicalDrive;
begin
  DriveList := AutoPhysicalDriveListGetter.GetPhysicalDriveList;
  result := -1;
  for PhysicalDrive in DriveList do
  begin
    if (Model = PhysicalDrive.IdentifyDeviceResult.Model) and
       (Serial = PhysicalDrive.IdentifyDeviceResult.Serial) then
      result :=
        StrToInt(PhysicalDrive.GetPathOfFileAccessingWithoutPrefix);
  end;
  if result = -1 then
    raise
      EDriveNotFound.Create('DriveNotFound Model ' + Model + ', Serial ' +
        Serial);
  FreeAndNil(DriveList);
end;

procedure TfSetting.RefreshDrives;
var
  DriveList: TPhysicalDriveList;
  PartitionList: TPartitionList;
  PhysicalDrive: IPhysicalDrive;
  CurrentDriveNumber: Integer;
begin
  DriveList := AutoPhysicalDriveListGetter.GetPhysicalDriveList;
  for PhysicalDrive in DriveList do
  begin
    PartitionList := PhysicalDrive.GetPartitionList;
    if PartitionList.Count = 0 then
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
