object fSetting: TfSetting
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #49444#51221
  ClientHeight = 200
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
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 331
    Top = 7
    Width = 153
    Height = 186
    Caption = #51060#50612#54616#44592
    TabOrder = 0
    object bOpenExist: TButton
      Left = 10
      Top = 15
      Width = 134
      Height = 162
      Caption = #44592#51316' '#53580#49828#53944' '#50676#44592
      TabOrder = 0
      OnClick = bOpenExistClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 8
    Width = 317
    Height = 185
    Caption = #49352' '#53580#49828#53944' '#49884#51089
    TabOrder = 1
    object Label1: TLabel
      Left = 17
      Top = 51
      Width = 53
      Height = 13
      Caption = #47785#54364' TBW:'
    end
    object Label2: TLabel
      Left = 17
      Top = 83
      Width = 109
      Height = 13
      Caption = #47532#53584#49496' '#53580#49828#53944' '#51452#44592': '
    end
    object Label5: TLabel
      Left = 15
      Top = 19
      Width = 58
      Height = 13
      Caption = #45824#49345' '#50948#52824': '
    end
    object Label3: TLabel
      Left = 275
      Top = 51
      Width = 22
      Height = 13
      Caption = 'TBW'
    end
    object Label4: TLabel
      Left = 275
      Top = 83
      Width = 22
      Height = 13
      Caption = 'TBW'
    end
    object Label6: TLabel
      Left = 17
      Top = 111
      Width = 67
      Height = 13
      Caption = #51116#54788#54624' '#54028#51068':'
    end
    object eDestTBW: TEdit
      Left = 79
      Top = 48
      Width = 188
      Height = 21
      TabOrder = 0
      Text = '10'
    end
    object eRetentionTBW: TEdit
      Left = 132
      Top = 80
      Width = 135
      Height = 21
      TabOrder = 1
      Text = '10'
    end
    object bStartNew: TButton
      Left = 15
      Top = 135
      Width = 287
      Height = 41
      Caption = #49352' '#53580#49828#53944' '#49884#51089
      TabOrder = 2
      OnClick = bStartNewClick
    end
    object cDestination: TComboBox
      Left = 75
      Top = 16
      Width = 192
      Height = 21
      Style = csDropDownList
      TabOrder = 3
    end
    object eTrace: TEdit
      Left = 90
      Top = 108
      Width = 177
      Height = 21
      ReadOnly = True
      TabOrder = 4
      OnClick = bTraceClick
    end
    object bTrace: TButton
      Left = 273
      Top = 106
      Width = 29
      Height = 25
      Caption = '...'
      TabOrder = 5
      OnClick = bTraceClick
    end
  end
  object oTrace: TOpenDialog
    DefaultExt = '*.txt'
    Filter = 'Trace File|*.txt'
    Left = 240
    Top = 64
  end
end
