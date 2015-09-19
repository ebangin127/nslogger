object fSetting: TfSetting
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #49444#51221
  ClientHeight = 261
  ClientWidth = 608
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = #47569#51008' '#44256#46357
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 21
  object GroupBox1: TGroupBox
    Left = 409
    Top = 9
    Width = 189
    Height = 242
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #51060#50612#54616#44592
    TabOrder = 0
    object bOpenExist: TButton
      Left = 17
      Top = 25
      Width = 156
      Height = 200
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #44592#51316' '#53580#49828#53944' '#50676#44592
      TabOrder = 0
      OnClick = bOpenExistClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 10
    Top = 10
    Width = 391
    Height = 241
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #49352' '#53580#49828#53944' '#49884#51089
    TabOrder = 1
    object Label1: TLabel
      Left = 21
      Top = 65
      Width = 75
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #47785#54364' TBW:'
    end
    object Label2: TLabel
      Left = 21
      Top = 105
      Width = 150
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #47532#53584#49496' '#53580#49828#53944' '#51452#44592': '
    end
    object Label5: TLabel
      Left = 19
      Top = 26
      Width = 80
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #45824#49345' '#50948#52824': '
    end
    object Label3: TLabel
      Left = 340
      Top = 65
      Width = 33
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'TBW'
    end
    object Label4: TLabel
      Left = 340
      Top = 105
      Width = 33
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'TBW'
    end
    object Label6: TLabel
      Left = 21
      Top = 145
      Width = 170
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #44592#45733' '#49892#54056#50984'(FFR) '#51228#54620': '
    end
    object Label7: TLabel
      Left = 340
      Top = 145
      Width = 13
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = '%'
    end
    object eDestTBW: TEdit
      Left = 109
      Top = 62
      Width = 222
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 0
      Text = '100'
    end
    object eRetentionTBW: TEdit
      Left = 183
      Top = 101
      Width = 148
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 1
      Text = '10'
    end
    object bStartNew: TButton
      Left = 19
      Top = 179
      Width = 354
      Height = 51
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #49352' '#53580#49828#53944' '#49884#51089
      TabOrder = 2
      OnClick = bStartNewClick
    end
    object eFFR: TEdit
      Left = 195
      Top = 141
      Width = 136
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 3
      Text = '3'
    end
  end
  object cDestination: TComboBoxEx
    Left = 120
    Top = 34
    Width = 222
    Height = 30
    ItemsEx = <>
    Style = csExDropDownList
    TabOrder = 2
  end
  object oTrace: TOpenDialog
    Filter = 'JESD219A-MT (*.txt)|*.txt'
    Left = 240
    Top = 128
  end
end
