unit uRetSel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Generics.Collections,
  uSSDInfo, uDiskFunctions, uStrFunctions,
  uCopyThread, uVerifyThread, uPreCondThread;

type
  TRetSelMode = (rsmVerify, rsmCopy, rsmPreCond);

type
  TfRetSel = class(TForm)
    Label5: TLabel;
    cDestination: TComboBox;
    bStart: TButton;
    FileSave: TSaveDialog;
    pProgress: TProgressBar;
    sProgress: TStaticText;
    FileOpen: TOpenDialog;
    constructor Create(AOwner: TComponent; OrigPath: String); reintroduce;
    procedure FormCreate(Sender: TObject);
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FOrigPath: String;
    FDriveList: TList<Integer>;
    FWritePath: String;
    FMode: TRetSelMode;
    FEndTask: Boolean;
    FUBER: Double;
    FWritten: Int64;

    FCopyThrd: TCopyThread;
    FVerifyThrd: TVerifyThread;
    FPreCondThrd: TPreCondThread;
  public
    property Written: Int64 read FWritten write FWritten;
    property EndTask: Boolean read FEndTask write FEndTask;
    property UBER: Double read FUBER write FUBER;

    procedure SetMode(Mode: TRetSelMode; WritePath: String); overload;
    procedure SetMode(Mode: TRetSelMode); overload;
  end;

var
  fRetSel: TfRetSel;

implementation

{$R *.dfm}

uses uMain;

procedure TfRetSel.bStartClick(Sender: TObject);
var
  DestPath: String;
begin
  if (cDestination.ItemIndex <> cDestination.Items.Count - 1) and
      (FMode <> rsmPreCond) then
  begin
    DestPath := '\\.\PhysicalDrive' +
            IntToStr(FDriveList[cDestination.ItemIndex]);
  end
  else
  begin
    case FMode of
      rsmVerify:
      begin
        if FileOpen.Execute(Self.Handle) = false then
          exit
        else
          DestPath := FileOpen.FileName;
      end;

      rsmCopy:
      begin
        if FileSave.Execute(Self.Handle) = false then
          exit
        else
          DestPath := FileSave.FileName;
      end;

      rsmPreCond:
      begin
        DestPath := FOrigPath;
      end;
    end;
  end;


  bStart.Visible := false;

  case FMode of
    rsmVerify:
    begin
      FVerifyThrd := TVerifyThread.Create(FOrigPath, DestPath);
    end;

    rsmCopy:
    begin
      FCopyThrd := TCopyThread.Create(FOrigPath, DestPath);
    end;

    rsmPreCond:
    begin
      FPreCondThrd := TPreCondThread.Create(DestPath, pProgress, sProgress);
    end;
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
  if ((FVerifyThrd <> nil) or (FCopyThrd <> nil) or (FPreCondThrd <> nil)) and
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

  FMode := rsmCopy;
  RefreshDrives;
  cDestination.ItemIndex := 0;
end;

procedure TfRetSel.FormDestroy(Sender: TObject);
begin
  if FVerifyThrd <> nil then
    FreeAndNil(FVerifyThrd)
  else if FCopyThrd <> nil then
    FreeAndNil(FCopyThrd)
  else if FPreCondThrd <> nil then
    FreeAndNil(FPreCondThrd);

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
    if FOrigPath = '\\.\PhysicalDrive' + IntToStr(CurrDrv) then
      Continue;

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
      end;
    end;

    CloseHandle(hdrive);
  end;
  FreeAndNil(TempSSDInfo);

  cDestination.Items.Add('���Ϸ� ����');
end;

procedure TfRetSel.SetMode(Mode: TRetSelMode; WritePath: String);
begin
  SetMode(Mode);
  FWritePath := WritePath;
end;

procedure TfRetSel.SetMode(Mode: TRetSelMode);
var
  ItemIndexBkup: Integer;
begin
  FMode := Mode;
  ItemIndexBkup := cDestination.ItemIndex;

  if Mode = rsmVerify then
  begin
    cDestination.Items[cDestination.Items.Count - 1] := '���Ͽ��� �ҷ�����';
    bStart.Caption := '���� ����';
  end
  else if Mode = rsmPreCond then
  begin
    cDestination.Clear;
    cDestination.Items.Add(FOrigPath);

    FDriveList.Clear;
    FDriveList.Add(StrToInt(ExtractDeviceNum(FOrigPath)));

    bStart.Caption := '�׽�Ʈ ���� �غ� ����';
    Caption := '�׽�Ʈ ���� �غ�';
  end;

  cDestination.ItemIndex := ItemIndexBkup;
end;

end.
