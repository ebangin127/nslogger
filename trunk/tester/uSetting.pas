unit uSetting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  uDiskFunctions, uSSDInfo, uFileFunctions, uSaveFile, uGSTestThread;

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
    cDestination: TComboBox;
    Label6: TLabel;
    eTrace: TEdit;
    bTrace: TButton;
    oTrace: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure bStartNewClick(Sender: TObject);
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bOpenExistClick(Sender: TObject);
    procedure bTraceClick(Sender: TObject);
  private
    FOptionsSet: Boolean;
    FDriveList: TList<Integer>;
    FSavePath: String;
    FLoadedFromFile: Boolean;
    { Private declarations }
  public
    property SavePath: String read FSavePath;
    property LoadedFromFile: Boolean read FLoadedFromFile;

    function GetDriveNum: Integer;
    { Public declarations }
  end;

var
  fSetting: TfSetting;

implementation

{$R *.dfm}

procedure TfSetting.bOpenExistClick(Sender: TObject);
var
  SaveFile: TSaveFile;
begin
  FSavePath := SelectDirectory(ExtractFilePath(Application.ExeName));

  if FSavePath = '' then
    exit;

  if FileExists(FSavePath + 'settings.ini') = false then
  begin
    ShowMessage('�׽�Ʈ ������ �����ϴ�.');
    exit;
  end;

  SaveFile := TSaveFile.Create;
  SaveFile.LoadFromFile(FSavePath + 'settings.ini');

  FDriveList.Insert(0, SaveFile.Disknum);
  cDestination.Items.Insert(0, 'Open');
  cDestination.ItemIndex := 0;

  eDestTBW.Text := IntToStr(SaveFile.MaxTBW shr ByteToTB);
  eRetentionTBW.Text := IntToStr(SaveFile.RetTBW shr ByteToTB);
  FLoadedFromFile := true;

  FOptionsSet := true;
  Close;
end;

procedure TfSetting.bStartNewClick(Sender: TObject);
var
  MaxTBW, MaxReten: Integer;
begin
  if cDestination.ItemIndex = -1 then
  begin
    ShowMessage('��� ��ġ�� �ùٸ��� �Է����ּ���');
    exit;
  end;
  if TryStrToInt(eDestTBW.Text, MaxTBW) = false then
  begin
    ShowMessage('��ǥ TBW�� �ùٸ��� �Է����ּ���');
    exit;
  end;
  if TryStrToInt(eRetentionTBW.Text, MaxReten) = false then
  begin
    ShowMessage('���ټ� �׽�Ʈ �ֱ⸦ �ùٸ��� �Է����ּ���');
    exit;
  end;
  if MaxTBW < MaxReten then
  begin
    ShowMessage('��ǥ TBW�� ���ټ� �׽�Ʈ �ֱ⺸�� ���� �� �����ϴ�');
    exit;
  end;
  if FileExists(eTrace.Text) = false then
  begin
    ShowMessage('�������� �ʴ� Ʈ���̽� �����Դϴ�');
    exit;
  end;

  repeat
    FSavePath := SelectDirectory(ExtractFilePath(Application.ExeName));
    if FSavePath = '' then
      exit;

    if FileExists(FSavePath + 'settings.ini') then
    begin
      ShowMessage('�̹� �׽�Ʈ ������ ���� ������ ������ �� �����ϴ�.');
    end;
  until (FSavePath = '') or (FileExists(FSavePath + 'settings.ini'));

  FOptionsSet := true;
  Close;
end;

procedure TfSetting.bTraceClick(Sender: TObject);
begin
  if oTrace.Execute(Self.Handle) then
    eTrace.Text := oTrace.FileName;
end;

procedure TfSetting.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;
  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;

  FOptionsSet := false;
  FLoadedFromFile := false;

  FDriveList := TList<Integer>.Create;
  RefreshDrives;
end;

procedure TfSetting.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDriveList);
end;

function TfSetting.GetDriveNum: Integer;
begin
  if (FOptionsSet = false) or (cDestination.ItemIndex = -1) then
    exit(-1);

  exit(FDriveList[cDestination.ItemIndex]);
end;

procedure TfSetting.RefreshDrives;
var
  TempSSDInfo: TSSDInfo;
  CurrDrv: Integer;
  hdrive: Integer;
  DRVLetters: TDriveLetters;
begin
  TempSSDInfo := TSSDInfo.Create;
  for CurrDrv := 0 to 99 do
  begin
    hdrive := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(CurrDrv)), GENERIC_READ or GENERIC_WRITE,
                                FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

    if (GetLastError = 0) and (GetIsDriveAccessible('', hdrive)) then
    begin
      TempSSDInfo.ATAorSCSI := DetermineModel;
      TempSSDInfo.SetDeviceName('PhysicalDrive' + IntToStr(CurrDrv));

      DRVLetters := GetPartitionList(IntToStr(CurrDrv));
      if DRVLetters.LetterCount = 0 then //����̺갡 ������ OS ��ȣ��
      begin                              //���� ���� �׽�Ʈ �Ұ�.
        FDriveList.Add(CurrDrv);
        cDestination.Items.Add(IntToStr(CurrDrv) + ' - ' + TempSSDInfo.Model);

        if cDestination.ItemIndex = -1 then
          cDestination.ItemIndex := 0;
      end;
    end;

    CloseHandle(hdrive);
  end;
  FreeAndNil(TempSSDInfo);
end;


end.
