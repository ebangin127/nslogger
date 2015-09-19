object fRetSel: TfRetSel
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #47532#53584#49496' '#53580#49828#53944
  ClientHeight = 136
  ClientWidth = 366
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 17
  object Label5: TLabel
    Left = 22
    Top = 14
    Width = 84
    Height = 23
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #45824#49345' '#50948#52824': '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = []
    ParentFont = False
  end
  object sProgress: TStaticText
    Left = 22
    Top = 94
    Width = 306
    Height = 22
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    AutoSize = False
    Caption = 'sdfasdfasvasdf'
    TabOrder = 3
  end
  object pProgress: TProgressBar
    Left = 22
    Top = 64
    Width = 325
    Height = 22
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    TabOrder = 2
  end
  object cDestination: TComboBox
    Left = 114
    Top = 10
    Width = 242
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Style = csDropDownList
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = []
    ImeName = 'Microsoft Office IME 2007'
    ParentFont = False
    TabOrder = 0
  end
  object bStart: TButton
    Left = 13
    Top = 54
    Width = 343
    Height = 72
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = #48373#49324' '#49884#51089
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = #47569#51008' '#44256#46357
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = bStartClick
  end
  object FileSave: TSaveDialog
    DefaultExt = 'RAW Image File'
    Filter = 'RAW Image File|*.raw'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 232
    Top = 40
  end
  object FileOpen: TOpenDialog
    FileName = 'E:\M6S.raw'
    Filter = 'RAW Image File|*.raw'
    Options = [ofEnableSizing]
    Left = 176
    Top = 40
  end
end
