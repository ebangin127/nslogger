unit Form.Setting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  uFileFunctions, uSaveFile, uGSTestThread, Device.PhysicalDrive,
  uPartitionListGetter, Vcl.ComCtrls, Threading;

type
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
  FSavePath := SelectDirectory('로그가 저장된 폴더를 선택해주세요', AppPath);

  if FSavePath = '' then
    exit;

  if FileExists(FSavePath + 'settings.ini') = false then
  begin
    ShowMessage('테스트 파일이 없습니다.');
    exit;
  end;

  SaveFile := TSaveFile.Create;
  SaveFile.LoadFromFile(FSavePath + 'settings.ini');

  if FDriveList.IndexOf(SaveFile.Disknum) >= 0 then
  begin
    FDriveList.Insert(0, SaveFile.Disknum);
    cDestination.Items.Insert(0, 'Open');
    cDestination.ItemIndex := 0;
  end
  else
  begin
    FDriveList.Insert(0, FindDrive(SaveFile.Model,
                                   SaveFile.Serial));
    cDestination.Items.Insert(0, 'Open');
    cDestination.ItemIndex := 0;
  end;

  eDestTBW.Text := IntToStr(SaveFile.MaxTBW shr ByteToTB);
  eRetentionTBW.Text := IntToStr(SaveFile.RetTBW shr ByteToTB);
  FNeedToLoad := true;

  FOptionsSet := true;
  Close;
end;

procedure TfSetting.bStartNewClick(Sender: TObject);
var
  MaxTBW, MaxReten: Integer;
  MaxFFR: Integer;
begin
  if cDestination.ItemIndex = -1 then
  begin
    ShowMessage('대상 위치를 올바르게 입력해주세요');
    exit;
  end;
  if TryStrToInt(eDestTBW.Text, MaxTBW) = false then
  begin
    ShowMessage('목표 TBW를 올바르게 입력해주세요');
    exit;
  end;
  if TryStrToInt(eRetentionTBW.Text, MaxReten) = false then
  begin
    ShowMessage('리텐션 테스트 주기를 올바르게 입력해주세요');
    exit;
  end;
  if TryStrToInt(eFFR.Text, MaxFFR) = false then
  begin
    ShowMessage('기능 실패율을 올바르게 입력해주세요');
    exit;
  end;
  if MaxTBW < MaxReten then
  begin
    ShowMessage('목표 TBW는 리텐션 테스트 주기보다 작을 수 없습니다');
    exit;
  end;

  FTracePath := AppPath + 'mt.txt';
  while (FTracePath = '') or (not(FileExists(FTracePath))) do
  begin
    if oTrace.Execute = false then
      exit;

    FTracePath := oTrace.FileName;
  end;

  repeat
    FSavePath := SelectDirectory('로그가 저장될 폴더를 선택해주세요', AppPath);
    if FSavePath = '' then
      exit;

    if FileExists(FSavePath + 'settings.ini') then
    begin
      if MessageDlg('해당 폴더에 이미 로그가 있습니다. 덮어씌우시겠습니까?',
                    mtWarning, mbOKCancel, 0) = mrCancel then
        Exit
      else
      begin
        DeleteFile(FSavePath + 'settings.ini');
      end;
    end;
  until (FSavePath <> '') and (not(FileExists(FSavePath + 'settings.ini')));

  if FileExists(FSavePath + 'alert.txt') then
    DeleteFile(PChar(FSavePath + 'alert.txt'));

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

function TfSetting.FindDrive(Model, Serial: String): Integer;
var
  PhysicalDrive: IPhysicalDrive;
  CurrDrv: Integer;
  PartitionList: TPartitionList;
begin
  result := -1;
  for CurrDrv := 0 to 99 do
  begin
    try
      PhysicalDrive := TPhysicalDrive.Create(
        TPhysicalDrive.BuildFileAddressByNumber(CurrDrv));

      if not PhysicalDrive.IsDriveAvailable then
        Continue;
    except
      Continue;
    end;

    PartitionList := PhysicalDrive.GetPartitionList;
    if PartitionList.Count > 0 then
    begin
      FreeAndNil(PartitionList);
      Continue;
    end;

    if (Model = PhysicalDrive.IdentifyDeviceResult.Model) and
       (Serial = PhysicalDrive.IdentifyDeviceResult.Serial) then
    begin
      result := CurrDrv;
      break;
    end;
    FreeAndNil(PartitionList);
  end;
end;

procedure TfSetting.RefreshDrives;
begin
  TParallel.For(0, 99, procedure (CurrDrv: Integer)
  var
    PhysicalDrive: IPhysicalDrive;
    PartitionList: TPartitionList;
  begin
    try
      PhysicalDrive := TPhysicalDrive.Create(
        TPhysicalDrive.BuildFileAddressByNumber(CurrDrv));

      if not PhysicalDrive.IsDriveAvailable then
        exit;
    except
      exit;
    end;

    PartitionList := PhysicalDrive.GetPartitionList;
    if PartitionList.Count > 0 then
    begin
      FreeAndNil(PartitionList);
      exit;
    end;

    TThread.Queue(TThread.CurrentThread, procedure
    begin
      FDriveList.Add(CurrDrv);
      cDestination.Items.Add(IntToStr(CurrDrv) + ' - ' +
        PhysicalDrive.IdentifyDeviceResult.Model);
      if cDestination.ItemIndex = -1 then
        cDestination.ItemIndex := 0;
    end);

    FreeAndNil(PartitionList);
  end);
end;


end.
