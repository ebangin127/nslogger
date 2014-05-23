unit uSetting;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfSetting = class(TForm)
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    SaveDialog1: TSaveDialog;
    Label1: TLabel;
    eDestTBW: TEdit;
    Label2: TLabel;
    eRetensionTBW: TEdit;
    bStartNew: TButton;
    Label5: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    bOpenExist: TButton;
    cDestination: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure bStartNewClick(Sender: TObject);
  private
    FOptionsSet: Boolean;
    { Private declarations }
  public
    property OptionsSet: Boolean read FOptionsSet;
    { Public declarations }
  end;

var
  fSetting: TfSetting;

implementation

{$R *.dfm}

procedure TfSetting.bStartNewClick(Sender: TObject);
var
  Value: Integer;
begin
  if TryStrToInt(eDestination.Text, Value) = false then
  begin
    ShowMessage('대상 위치를 올바르게 입력해주세요');
    exit;
  end;
  if TryStrToInt(eDestTBW.Text, Value) = false then
  begin
    ShowMessage('목표 TBW를 올바르게 입력해주세요');
    exit;
  end;
  if TryStrToInt(eRetensionTBW.Text, Value) = false then
  begin
    ShowMessage('리텐션 테스트 주기를 올바르게 입력해주세요');
    exit;
  end;

  FOptionsSet := true;
  Close;
end;

procedure TfSetting.FormCreate(Sender: TObject);
begin
  Constraints.MaxWidth := Width;
  Constraints.MinWidth := Width;
  Constraints.MaxHeight := Height;
  Constraints.MinHeight := Height;

  FOptionsSet := false;
end;

end.
