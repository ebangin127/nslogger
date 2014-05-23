object fSetting: TfSetting
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #49444#51221
  ClientHeight = 173
  ClientWidth = 492
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 264
    Top = 8
    Width = 217
    Height = 158
    Caption = #51060#50612#54616#44592
    TabOrder = 0
    object bOpenExist: TButton
      Left = 12
      Top = 17
      Width = 194
      Height = 134
      Caption = #44592#51316' '#53580#49828#53944' '#50676#44592
      TabOrder = 0
      OnClick = bStartNewClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 8
    Width = 242
    Height = 158
    Caption = #49352' '#53580#49828#53944' '#49884#51089
    TabOrder = 1
    object Label1: TLabel
      Left = 17
      Top = 51
      Width = 51
      Height = 13
      Caption = #47785#54364' TBW:'
    end
    object Label2: TLabel
      Left = 17
      Top = 83
      Width = 101
      Height = 13
      Caption = #47532#53584#49496' '#53580#49828#53944' '#51452#44592': '
    end
    object Label5: TLabel
      Left = 15
      Top = 19
      Width = 54
      Height = 13
      Caption = #45824#49345' '#50948#52824': '
    end
    object Label3: TLabel
      Left = 206
      Top = 51
      Width = 22
      Height = 13
      Caption = 'TBW'
    end
    object Label4: TLabel
      Left = 206
      Top = 83
      Width = 22
      Height = 13
      Caption = 'TBW'
    end
    object eDestTBW: TEdit
      Left = 79
      Top = 48
      Width = 121
      Height = 21
      TabOrder = 0
      Text = '10'
    end
    object eRetensionTBW: TEdit
      Left = 132
      Top = 80
      Width = 68
      Height = 21
      TabOrder = 1
      Text = '10'
    end
    object bStartNew: TButton
      Left = 15
      Top = 107
      Width = 218
      Height = 41
      Caption = #49352' '#53580#49828#53944' '#49884#51089
      TabOrder = 2
      OnClick = bStartNewClick
    end
    object cDestination: TComboBox
      Left = 75
      Top = 16
      Width = 125
      Height = 21
      TabOrder = 3
    end
  end
  object SaveDialog1: TSaveDialog
    Left = 232
    Top = 8
  end
end
