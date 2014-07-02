object fRetSel: TfRetSel
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = #47532#53584#49496' '#53580#49828#53944
  ClientHeight = 103
  ClientWidth = 278
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
    Left = 15
    Top = 11
    Width = 54
    Height = 13
    Caption = #45824#49345' '#50948#52824': '
  end
  object cDestination: TComboBox
    Left = 75
    Top = 8
    Width = 192
    Height = 21
    Style = csDropDownList
    TabOrder = 0
  end
  object bStart: TButton
    Left = 8
    Top = 35
    Width = 262
    Height = 55
    Caption = #48373#49324' '#49884#51089
    TabOrder = 1
    OnClick = bStartClick
  end
  object FileSave: TSaveDialog
    Filter = 'RAW Image File|*.raw'
    Left = 136
    Top = 56
  end
end
