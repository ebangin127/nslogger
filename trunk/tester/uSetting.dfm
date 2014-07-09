object fSetting: TfSetting
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #49444#51221
  ClientHeight = 211
  ClientWidth = 492
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #47569#51008' '#44256#46357
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 17
  object GroupBox1: TGroupBox
    Left = 331
    Top = 7
    Width = 153
    Height = 194
    Caption = #51060#50612#54616#44592
    TabOrder = 0
    object bOpenExist: TButton
      Left = 14
      Top = 20
      Width = 126
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
    Height = 193
    Caption = #49352' '#53580#49828#53944' '#49884#51089
    TabOrder = 1
    object Label1: TLabel
      Left = 17
      Top = 51
      Width = 61
      Height = 17
      Caption = #47785#54364' TBW:'
    end
    object Label2: TLabel
      Left = 17
      Top = 83
      Width = 122
      Height = 17
      Caption = #47532#53584#49496' '#53580#49828#53944' '#51452#44592': '
    end
    object Label5: TLabel
      Left = 15
      Top = 19
      Width = 65
      Height = 17
      Caption = #45824#49345' '#50948#52824': '
    end
    object Label3: TLabel
      Left = 275
      Top = 51
      Width = 27
      Height = 17
      Caption = 'TBW'
    end
    object Label4: TLabel
      Left = 275
      Top = 83
      Width = 27
      Height = 17
      Caption = 'TBW'
    end
    object Label6: TLabel
      Left = 17
      Top = 115
      Width = 137
      Height = 17
      Caption = #44592#45733' '#49892#54056#50984'(FFR) '#51228#54620': '
    end
    object Label7: TLabel
      Left = 275
      Top = 115
      Width = 11
      Height = 17
      Caption = '%'
    end
    object eDestTBW: TEdit
      Left = 88
      Top = 48
      Width = 180
      Height = 25
      TabOrder = 0
      Text = '100'
    end
    object eRetentionTBW: TEdit
      Left = 148
      Top = 80
      Width = 120
      Height = 25
      TabOrder = 1
      Text = '10'
    end
    object bStartNew: TButton
      Left = 15
      Top = 143
      Width = 287
      Height = 41
      Caption = #49352' '#53580#49828#53944' '#49884#51089
      TabOrder = 2
      OnClick = bStartNewClick
    end
    object cDestination: TComboBox
      Left = 88
      Top = 16
      Width = 180
      Height = 22
      Style = csOwnerDrawFixed
      TabOrder = 3
      OnKeyPress = cDestinationKeyPress
    end
    object eFFR: TEdit
      Left = 158
      Top = 112
      Width = 110
      Height = 25
      TabOrder = 4
      Text = '3'
    end
  end
  object oTrace: TOpenDialog
    Filter = 'JESD219A-MT (*.txt)|*.txt'
    Left = 240
    Top = 128
  end
end
