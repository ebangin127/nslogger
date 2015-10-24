object fSetting: TfSetting
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #49444#51221
  ClientHeight = 314
  ClientWidth = 712
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
    Left = 491
    Top = 9
    Width = 207
    Height = 288
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #51060#50612#54616#44592
    TabOrder = 0
    object bOpenExist: TButton
      Left = 17
      Top = 27
      Width = 175
      Height = 247
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
    Width = 471
    Height = 287
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #49352' '#53580#49828#53944' '#49884#51089
    TabOrder = 1
    object lRetentionTBW: TLabel
      Left = 19
      Top = 67
      Width = 150
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #47532#53584#49496' '#53580#49828#53944' '#51452#44592': '
    end
    object lDestination: TLabel
      Left = 19
      Top = 29
      Width = 80
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #45824#49345' '#50948#52824': '
    end
    object lTBW: TLabel
      Left = 418
      Top = 67
      Width = 33
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'TBW'
    end
    object lFFR: TLabel
      Left = 19
      Top = 108
      Width = 170
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #44592#45733' '#49892#54056#50984'(FFR) '#51228#54620': '
    end
    object lPercent: TLabel
      Left = 418
      Top = 108
      Width = 13
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = '%'
    end
    object lTraceOriginalLBA: TLabel
      Left = 19
      Top = 186
      Width = 144
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #53944#47112#51060#49828' '#44592#51456' '#50857#47049':'
    end
    object lTracePath: TLabel
      Left = 19
      Top = 147
      Width = 106
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #53944#47112#51060#49828' '#50948#52824':'
    end
    object lGB: TLabel
      Left = 418
      Top = 186
      Width = 20
      Height = 21
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = 'GB'
    end
    object eRetentionTBW: TEdit
      Left = 182
      Top = 66
      Width = 228
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 0
      Text = '10'
    end
    object bStartNew: TButton
      Left = 19
      Top = 222
      Width = 432
      Height = 51
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      Caption = #49352' '#53580#49828#53944' '#49884#51089
      TabOrder = 1
      OnClick = bStartNewClick
    end
    object eFFR: TEdit
      Left = 193
      Top = 105
      Width = 217
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 2
      Text = '3'
    end
    object eTracePath: TEdit
      Left = 144
      Top = 144
      Width = 266
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 3
      Text = '10'
      OnClick = bTracePathClick
    end
    object bTracePath: TButton
      Left = 417
      Top = 148
      Width = 34
      Height = 29
      Caption = '...'
      TabOrder = 4
      OnClick = bTracePathClick
    end
    object cDestination: TComboBoxEx
      Left = 106
      Top = 26
      Width = 345
      Height = 30
      ItemsEx = <>
      Style = csExDropDownList
      TabOrder = 5
    end
    object eTraceOriginalLBA: TEdit
      Left = 182
      Top = 183
      Width = 228
      Height = 29
      Margins.Left = 4
      Margins.Top = 4
      Margins.Right = 4
      Margins.Bottom = 4
      TabOrder = 6
      Text = '128'
    end
  end
  object oTrace: TOpenDialog
    Filter = 'JESD219-Trace (*.txt)|*.txt'
    Left = 520
    Top = 232
  end
end
