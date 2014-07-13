object fRetSel: TfRetSel
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #47532#53584#49496' '#53580#49828#53944
  ClientHeight = 104
  ClientWidth = 280
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
  object Label5: TLabel
    Left = 17
    Top = 11
    Width = 65
    Height = 17
    Caption = #45824#49345' '#50948#52824': '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = []
    ParentFont = False
  end
  object sProgress: TStaticText
    Left = 17
    Top = 72
    Width = 234
    Height = 17
    AutoSize = False
    Caption = 'sdfasdfasvasdf'
    TabOrder = 3
  end
  object pProgress: TProgressBar
    Left = 17
    Top = 49
    Width = 248
    Height = 17
    TabOrder = 2
  end
  object cDestination: TComboBox
    Left = 87
    Top = 8
    Width = 185
    Height = 25
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object bStart: TButton
    Left = 10
    Top = 41
    Width = 262
    Height = 55
    Caption = #48373#49324' '#49884#51089
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = bStartClick
  end
  object FileSave: TSaveDialog
    Filter = 'RAW Image File|*.raw'
    Left = 208
    Top = 72
  end
end
