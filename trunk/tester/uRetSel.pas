unit uRetSel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Generics.Collections,
  uHDDInfo, uDiskFunctions;

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
    constructor Create(AOwner: TComponent; OriginalHandle: THandle);
    procedure FormCreate(Sender: TObject);
    procedure RefreshDrives;
    procedure FormDestroy(Sender: TObject);
    procedure bStartClick(Sender: TObject);
  private
    FOrignalHandle: THandle;
    FDriveHandle: THandle;
    FDLLHandle: THandle;
    FDriveList: TList<Integer>;
    FWritePath: String;
    FVerifyMode: Boolean;
  public
    procedure SetMode(VerifyMode: Boolean; WritePath: String); overload;
    procedure SetMode(VerifyMode: Boolean); overload;
  end;

  TCopyThread = class(TThread)
  private
    FOrigHandle, FDestHandle: THandle;
    FDLLHandle: THandle;
    FWriteHandle: THandle;

    FVerifyMode: Boolean;
    SSDCopy: TssdCopy;
    SSDDriveCompare: TssdDriveCompare;
    procedure SetCmpHandles(WriteHandle: THandle);
  public
    procedure SetHandles(OrigHandle, DestHandle, DLLHandle: THandle); overload;
    procedure SetHandles(OrigHandle, DestHandle, DLLHandle,
                         WriteHandle: THandle); overload;
    procedure Execute; override;
    procedure EndCopy;
  end;

var
  fRetSel: TfRetSel;

implementation

{$R *.dfm}

uses uMain;

procedure TfRetSel.bStartClick(Sender: TObject);
var
  Path: String;
  CopyThrd: TCopyThread;
  WriteHandle: THandle;
begin
  if cDestination.ItemIndex <> cDestination.Items.Count - 1 then
  begin
    Path := '\\.\PhysicalDrive' +
            IntToStr(FDriveList[cDestination.ItemIndex]);
  end
  else
  begin
    if FileSave.Execute(Self.Handle) = false then
      exit;

    Path := FileSave.FileName;
    if not FVerifyMode then
    begin
      FDriveHandle := CreateFile(PChar(Path), GENERIC_READ or GENERIC_WRITE,
                                  FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                                  CREATE_ALWAYS, 0, 0);
      CloseHandle(FDriveHandle);
    end;
  end;

  if FVerifyMode then
  begin
    FDriveHandle := CreateFile(PChar(Path), GENERIC_READ, FILE_SHARE_READ, nil,
                                OPEN_EXISTING, 0, 0);
    WriteHandle := CreateFile(PChar(FWritePath), GENERIC_READ or GENERIC_WRITE,
                                FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                                CREATE_ALWAYS, 0, 0);
  end
  else
  begin
    FDriveHandle := CreateFile(PChar(Path), GENERIC_READ or GENERIC_WRITE,
                                FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                                OPEN_EXISTING, 0, 0);
  end;


  bStart.Enabled := false;

  CopyThrd := TCopyThread.Create(true);
  if FVerifyMode then
  begin
    bStart.Caption := '검증중';
    CopyThrd.SetHandles(FOrignalHandle, FDriveHandle, FDLLHandle, WriteHandle);
  end
  else
  begin
    bStart.Caption := '복사중';
    CopyThrd.SetHandles(FOrignalHandle, FDriveHandle, FDLLHandle);
  end;

  CopyThrd.Start;
end;

constructor TfRetSel.Create(AOwner: TComponent; OriginalHandle: THandle);
begin
  inherited Create(AOwner);
  FOrignalHandle := OriginalHandle;
end;

procedure TfRetSel.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;

  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;

  FDriveList := TList<Integer>.Create;

  FDLLHandle := LoadLibrary(PChar(AppPath + 'DriveCopy.dll'));

  if GetLastError <> 0 then
    FDLLHandle := 0;

  FVerifyMode := false;
  RefreshDrives;
end;

procedure TfRetSel.FormDestroy(Sender: TObject);
begin
  if FDriveHandle <> 0 then
    CloseHandle(FDriveHandle);
  if FDLLHandle <> 0 then
    FreeLibrary(FDLLHandle);
  if FDriveList <> nil then
    FreeAndNil(FDriveList);
end;

procedure TfRetSel.RefreshDrives;
var
  TempSSDInfo: THDDInfo;
  CurrDrv: Integer;
  hdrive: Integer;
  DRVLetters: TDriveLetters;
begin
  TempSSDInfo := THDDInfo.Create;
  for CurrDrv := 0 to 99 do
  begin
    hdrive := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(CurrDrv)),
                                GENERIC_READ or GENERIC_WRITE,
                                FILE_SHARE_READ or FILE_SHARE_WRITE,
                                nil, OPEN_EXISTING, 0, 0);

    if (GetLastError = 0) and (GetIsDriveAccessible('', hdrive)) then
    begin
      TempSSDInfo.SetDeviceName('PhysicalDrive' + IntToStr(CurrDrv));

      DRVLetters := GetPartitionList(IntToStr(CurrDrv));
      if DRVLetters.LetterCount = 0 then //드라이브가 있으면 OS 보호로
      begin                              //인해 쓰기 테스트 불가.
        FDriveList.Add(CurrDrv);
        cDestination.Items.Add(IntToStr(CurrDrv) + ' - ' + TempSSDInfo.Model);

        if cDestination.ItemIndex = -1 then
          cDestination.ItemIndex := 0;
      end;
    end;

    CloseHandle(hdrive);
  end;
  FreeAndNil(TempSSDInfo);

  cDestination.Items.Add('파일로 저장');
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
    cDestination.Items[cDestination.Items.Count - 1] := '파일에서 불러오기';
    bStart.Caption := '검증 시작';
  end;
end;

{ TCopyThrd }

procedure TCopyThread.EndCopy;
begin
  fRetSel.Close;
end;

procedure TCopyThread.Execute;
var
  dwRead: Integer;
  dwWrite: Integer;
begin
  inherited;

  dwRead := 0;
  dwWrite := 0;

  if not FVerifyMode then SSDCopy(FOrigHandle, FDestHandle, @dwRead, @dwWrite)
  else SSDDriveCompare(FOrigHandle, FDestHandle, FWriteHandle,
                       @dwRead, @dwWrite);
  Synchronize(EndCopy);
end;

procedure TCopyThread.SetHandles(OrigHandle, DestHandle, DLLHandle: THandle);
begin
  FOrigHandle := OrigHandle;
  FDestHandle := DestHandle;
  FDLLHandle := DLLHandle;

  @SSDCopy := GetProcAddress(FDLLHandle, 'ssdCopy');

  FVerifyMode := false;
end;

procedure TCopyThread.SetCmpHandles(WriteHandle: THandle);
begin
  FWriteHandle := WriteHandle;
end;

procedure TCopyThread.SetHandles(OrigHandle, DestHandle, DLLHandle,
                                  WriteHandle: THandle);
begin
  SetHandles(OrigHandle, DestHandle, DLLHandle);
  SetCmpHandles(WriteHandle);

  @SSDDriveCompare := GetProcAddress(FDLLHandle, 'ssdDriveCompare');

  FVerifyMode := true;
end;

end.
