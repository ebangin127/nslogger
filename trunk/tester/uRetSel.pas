unit uRetSel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Generics.Collections,
  uSSDInfo, uDiskFunctions, uCopyThread, uVerifyThread;

type
  TssdCopy  = function (readDrive, writeDrive: THandle;
                        dwRead, dwWrite: PInteger): Integer; cdecl;
  TssdDriveCompare = function (readDrive, compDrive, writeLog: THandle;
                               dwRead, dwWrite: PInteger): Integer; cdecl;

type
  TfRetSel = class(TForm)
    Label5: TLabel;
    cDestination: TComboBox;
    bStart: TButton;
    FileSave: TSaveDialog;
    pProgress: TProgressBar;
    sProgress: TStaticText;
    constructor Create(AOwner: TComponent; OrigPath: String);
    procedure FormCreate(Sender: TObject);
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOrigPath: String;
    FDriveList: TList<Integer>;
    FWritePath: String;
    FVerifyMode: Boolean;
    FEndTask: Boolean;
    FUBER: Double;

    FCopyThrd: TCopyThread;
    FVerifyThrd: TVerifyThread;
  public
    property EndTask: Boolean read FEndTask write FEndTask;
    property UBER: Double read FUBER write FUBER;

    procedure SetMode(VerifyMode: Boolean; WritePath: String); overload;
    procedure SetMode(VerifyMode: Boolean); overload;
  end;

var
  fRetSel: TfRetSel;

implementation

{$R *.dfm}

uses uMain;

procedure TfRetSel.bStartClick(Sender: TObject);
var
  DestPath: String;
  WriteHandle: THandle;
begin
  if cDestination.ItemIndex <> cDestination.Items.Count - 1 then
  begin
    DestPath := '\\.\PhysicalDrive' +
            IntToStr(FDriveList[cDestination.ItemIndex]);
  end
  else
  begin
    if FileSave.Execute(Self.Handle) = false then
      exit;

    DestPath := FileSave.FileName;
  end;


  bStart.Visible := false;

  if FVerifyMode then
  begin
    bStart.Caption := '������';
    FVerifyThrd := TVerifyThread.Create(FOrigPath, DestPath);
  end
  else
  begin
    bStart.Caption := '������';
    FCopyThrd := TCopyThread.Create(FOrigPath, DestPath);
  end;
  FEndTask := false;
end;

constructor TfRetSel.Create(AOwner: TComponent; OrigPath: String);
begin
  inherited Create(AOwner);
  FOrigPath := OrigPath;
end;

procedure TfRetSel.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ((FVerifyThrd <> nil) or (FCopyThrd <> nil)) and
     (EndTask = false) then
    Action := caNone;
end;

procedure TfRetSel.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;

  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;

  FDriveList := TList<Integer>.Create;

  FVerifyMode := false;
  RefreshDrives;
end;

procedure TfRetSel.FormDestroy(Sender: TObject);
begin
  if FVerifyThrd <> nil then
    FreeAndNil(FVerifyThrd)
  else if FCopyThrd <> nil then
    FreeAndNil(FCopyThrd);

  if FDriveList <> nil then
    FreeAndNil(FDriveList);
end;

procedure TfRetSel.RefreshDrives;
var
  TempSSDInfo: TSSDInfo;
  CurrDrv: Integer;
  hdrive: Integer;
  DRVLetters: TDriveLetters;
begin
  TempSSDInfo := TSSDInfo.Create;
  for CurrDrv := 0 to 99 do
  begin
    hdrive := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(CurrDrv)),
                                GENERIC_READ or GENERIC_WRITE,
                                FILE_SHARE_READ or FILE_SHARE_WRITE,
                                nil, OPEN_EXISTING, 0, 0);

    if (GetLastError = 0) and (GetIsDriveAccessible('', hdrive)) then
    begin
      TempSSDInfo.SetDeviceName(CurrDrv);

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

  cDestination.Items.Add('���Ϸ� ����');
end;

procedure TfRetSel.SetMode(VerifyMode: Boolean; WritePath: String);
begin
  SetMode(VerifyMode);
  FWritePath := WritePath;
end;

procedure TfRetSel.SetMode(VerifyMode: Boolean);
begin
  FVerifyMode := VerifyMode;
  if VerifyMode then
  begin
    cDestination.Items[cDestination.Items.Count - 1] := '���Ͽ��� �ҷ�����';
    bStart.Caption := '���� ����';
  end;
end;

end.
