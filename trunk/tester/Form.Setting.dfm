object fSetting: TfSetting
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #49444#51221
  ClientHeight = 254
  ClientWidth = 576
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
    Left = 397
    Top = 7
    Width = 168
    Height = 233
    Caption = #51060#50612#54616#44592
    TabOrder = 0
    object bOpenExist: TButton
      Left = 14
      Top = 22
      Width = 141
      Height = 200
      Caption = #44592#51316' '#53580#49828#53944' '#50676#44592
      TabOrder = 0
      OnClick = bOpenExistClick
    end
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 8
    Width = 381
    Height = 232
    Caption = #49352' '#53580#49828#53944' '#49884#51089
    TabOrder = 1
    object lRetentionTBW: TLabel
      Left = 15
      Top = 54
      Width = 122
      Height = 17
      Caption = #47532#53584#49496' '#53580#49828#53944' '#51452#44592': '
    end
    object lDestination: TLabel
      Left = 15
      Top = 23
      Width = 65
      Height = 17
      Caption = #45824#49345' '#50948#52824': '
    end
    object lTBW: TLabel
      Left = 338
      Top = 54
      Width = 27
      Height = 17
      Caption = 'TBW'
    end
    object lFFR: TLabel
      Left = 15
      Top = 87
      Width = 137
      Height = 17
      Caption = #44592#45733' '#49892#54056#50984'(FFR) '#51228#54620': '
    end
    object lPercent: TLabel
      Left = 338
      Top = 87
      Width = 11
      Height = 17
      Caption = '%'
    end
    object lTraceOriginalLBA: TLabel
      Left = 15
      Top = 151
      Width = 117
      Height = 17
      Caption = #53944#47112#51060#49828' '#44592#51456' '#50857#47049':'
    end
    object lTracePath: TLabel
      Left = 15
      Top = 119
      Width = 86
      Height = 17
      Caption = #53944#47112#51060#49828' '#50948#52824':'
    end
    object lGB: TLabel
      Left = 338
      Top = 151
      Width = 17
      Height = 17
      Caption = 'GB'
    end
    object eRetentionTBW: TEdit
      Left = 147
      Top = 53
      Width = 185
      Height = 25
      TabOrder = 0
      Text = '10'
    end
    object bStartNew: TButton
      Left = 15
      Top = 180
      Width = 350
      Height = 41
      Caption = #49352' '#53580#49828#53944' '#49884#51089
      TabOrder = 1
      OnClick = bStartNewClick
    end
    object eFFR: TEdit
      Left = 160
      Top = 85
      Width = 172
      Height = 25
      TabOrder = 2
      Text = '3'
    end
    object eTracePath: TEdit
      Left = 117
      Top = 117
      Width = 215
      Height = 25
      TabOrder = 3
      Text = '10'
      OnClick = bTracePathClick
    end
    object bTracePath: TButton
      Left = 338
      Top = 120
      Width = 27
      Height = 23
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = '...'
      TabOrder = 4
      OnClick = bTracePathClick
    end
    object cDestination: TComboBoxEx
      Left = 86
      Top = 21
      Width = 279
      Height = 26
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      ItemsEx = <>
      Style = csExDropDownList
      TabOrder = 5
    end
    object eTraceOriginalLBA: TEdit
      Left = 147
      Top = 148
      Width = 185
      Height = 25
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
