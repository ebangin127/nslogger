unit Form.Retention;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Generics.Collections,
  uCopyThread, uVerifyThread, uPreCondThread,
  Device.PhysicalDrive, uPartitionListGetter, uPhysicalDriveList,
  uAutoPhysicalDriveListGetter, Device.NumberExtractor, uLanguageSettings;

type
  TRetentionMode = (rsmVerify, rsmCopy, rsmPreCond);

  TSelectedThread = record
    case FMode: TRetentionMode of
      rsmVerify:
        (FVerifyThrd: TVerifyThread);
      rsmCopy:
        (FCopyThrd: TCopyThread);
      rsmPreCond:
        (FPreCondThrd: TPreCondThread);
  end;

  TfRetention = class(TForm)
    lDestination: TLabel;
    cDestination: TComboBox;
    bStart: TButton;
    FileSave: TSaveDialog;
    pProgress: TProgressBar;
    sProgress: TStaticText;
    FileOpen: TOpenDialog;
    constructor Create(AOwner: TComponent; SavedPath: String); reintroduce;
    procedure FormCreate(Sender: TObject);
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    FSavedFilePath: String;
    FDriveList: TList<Integer>;
    FWritePath: String;
    FEndTask: Boolean;
    FUBER: Double;
    FWritten: Int64;
    FSelectedThread: TSelectedThread;

    procedure DisableUIComponents;
    function GetDestination: String;
    procedure SetStringsForVerify;
    procedure SetStringsForPreconditioning;
    procedure FixFormSize;

  public
    property Written: Int64 read FWritten write FWritten;
    property EndTask: Boolean read FEndTask write FEndTask;
    property UBER: Double read FUBER write FUBER;

    procedure SetAsMode(Mode: TRetentionMode; WritePath: String);
  end;

var
  fRetention: TfRetention;

implementation

{$R *.dfm}

uses Form.Main;

procedure TfRetention.DisableUIComponents;
begin
  bStart.Visible := false;
  cDestination.Enabled := false;
end;

function TfRetention.GetDestination: String;
  function IsFileOpenNotNeeded: Boolean;
  begin
    result := cDestination.ItemIndex < cDestination.Items.Count - 1;
  end;
  function IsSourceNeeded: Boolean;
  begin
    result := FSelectedThread.FMode <> rsmPreCond;
  end;
  function GetSelectedFilePath: String;
  begin
    if FileOpen.Execute(Self.Handle) = false then
      result := ''
    else
      result := FileOpen.FileName;
  end;
begin
  if IsFileOpenNotNeeded and IsSourceNeeded then
    result :=
      TPhysicalDrive.BuildFileAddressByNumber(
        FDriveList[cDestination.ItemIndex])
  else
  begin
    case FSelectedThread.FMode of
      rsmVerify:
        result := GetSelectedFilePath;
      rsmCopy:
        result := GetSelectedFilePath;
      rsmPreCond:
        result := FSavedFilePath;
    end;
  end;
end;

procedure TfRetention.bStartClick(Sender: TObject);
var
  Destination: String;
begin
  FEndTask := false;
  DisableUIComponents;
  Destination := GetDestination;
  case FSelectedThread.FMode of
    rsmVerify:
      FSelectedThread.FVerifyThrd := TVerifyThread.Create(FSavedFilePath,
        Destination);
    rsmCopy:
      FSelectedThread.FCopyThrd := TCopyThread.Create(FSavedFilePath,
        Destination);
    rsmPreCond:
      FSelectedThread.FPreCondThrd := TPreCondThread.Create(Destination,
        pProgress, sProgress);
  end;
end;

constructor TfRetention.Create(AOwner: TComponent; SavedPath: String);
begin
  inherited Create(AOwner);
  FSavedFilePath := SavedPath;
end;

procedure TfRetention.FormClose(Sender: TObject; var Action: TCloseAction);
  function IsThreadStarted: Boolean;
  begin
    case FSelectedThread.FMode of
      rsmVerify:
        result := FSelectedThread.FVerifyThrd <> nil;
      rsmCopy:
        result := FSelectedThread.FCopyThrd <> nil;
      rsmPreCond:
        result := FSelectedThread.FPreCondThrd <> nil;
      else
        raise EArgumentOutOfRangeException.Create('Invalid Thread Mode');
    end;
  end;
begin
  if (IsThreadStarted) and (EndTask = false) then
    Action := caNone;
end;

procedure TfRetention.FormCreate(Sender: TObject);
begin
  FixFormSize;
  FDriveList := TList<Integer>.Create;
  FSelectedThread.FMode := rsmCopy;
  RefreshDrives;
  cDestination.ItemIndex := 0;
end;

procedure TfRetention.FormDestroy(Sender: TObject);
  procedure FreeThread;
  begin
    case FSelectedThread.FMode of
      rsmVerify:
        FreeAndNil(FSelectedThread.FVerifyThrd);
      rsmCopy:
        FreeAndNil(FSelectedThread.FCopyThrd);
      rsmPreCond:
        FreeAndNil(FSelectedThread.FPreCondThrd);
    end;
  end;
begin
  FreeThread;

  if FDriveList <> nil then
    FreeAndNil(FDriveList);
end;

procedure TfRetention.RefreshDrives;
var
  DriveList: TPhysicalDriveList;
  PartitionList: TPartitionList;
  PhysicalDrive: IPhysicalDrive;
begin
  DriveList := AutoPhysicalDriveListGetter.GetPhysicalDriveList;
  for PhysicalDrive in DriveList do
  begin
    PartitionList := PhysicalDrive.GetPartitionList;
    if PartitionList.Count = 0 then
    begin
      FDriveList.Add(
        StrToInt(PhysicalDrive.GetPathOfFileAccessingWithoutPrefix));
      cDestination.Items.Add(
        PhysicalDrive.GetPathOfFileAccessingWithoutPrefix + ' - ' +
        PhysicalDrive.IdentifyDeviceResult.Model);
    end;
    FreeAndNil(PartitionList);
  end;
  FreeAndNil(DriveList);
  cDestination.Items.Add(CommonSaveToFile[CurrLang]);
end;

procedure TfRetention.SetAsMode(Mode: TRetentionMode;
  WritePath: String);
var
  LastItemIndex: Integer;
begin
  FSelectedThread.FMode := Mode;
  LastItemIndex := cDestination.ItemIndex;

  case Mode of
    rsmVerify:
      SetStringsForVerify;
    rsmPreCond:
      SetStringsForPreconditioning;
  end;

  cDestination.ItemIndex := LastItemIndex;
  FWritePath := WritePath;
end;

procedure TfRetention.FixFormSize;
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;
  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;
end;

procedure TfRetention.SetStringsForPreconditioning;
begin
  cDestination.Clear;
  cDestination.Items.Add(FSavedFilePath);
  FDriveList.Clear;
  FDriveList.Add(StrToInt(ExtractDeviceNumber(FSavedFilePath)));
  bStart.Caption := RetentionStartPreconditioning[CurrLang];
  Caption := RetentionPreconditioning[CurrLang];
end;

procedure TfRetention.SetStringsForVerify;
begin
  cDestination.Items[cDestination.Items.Count - 1] :=
    CommonLoadFromFile[CurrLang];
  bStart.Caption := RetentionStartVerifying[CurrLang];
end;

end.
