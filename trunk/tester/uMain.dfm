object fMain: TfMain
  Left = 0
  Top = 0
  Caption = 'Grill Storage'
  ClientHeight = 363
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object gStatus: TGroupBox
    Left = 10
    Top = 10
    Width = 313
    Height = 318
    Caption = #51652#54665' '#49345#54889
    TabOrder = 0
    object Label1: TLabel
      Left = 17
      Top = 139
      Width = 51
      Height = 13
      Caption = #52572#49548' '#51648#50672':'
    end
    object Label2: TLabel
      Left = 15
      Top = 191
      Width = 51
      Height = 13
      Caption = #52572#45824' '#51648#50672':'
    end
    object Label4: TLabel
      Left = 18
      Top = 48
      Width = 87
      Height = 13
      Caption = #54788#51116' '#51652#54665' '#53580#49828#53944':'
    end
    object Label3: TLabel
      Left = 17
      Top = 21
      Width = 76
      Height = 13
      Caption = #54788#51116' '#51652#54665' '#54924#52264':'
    end
    object Label6: TLabel
      Left = 15
      Top = 242
      Width = 40
      Height = 13
      Caption = #45224#51008' '#47016':'
    end
    object Label7: TLabel
      Left = 17
      Top = 89
      Width = 62
      Height = 13
      Caption = #53580#49828#53944' '#51652#54665':'
    end
    object lMaxAlertL: TLabel
      Left = 17
      Top = 212
      Width = 35
      Height = 13
      Caption = #8592' '#50577#54840
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lMinAlertL: TLabel
      Left = 17
      Top = 159
      Width = 35
      Height = 13
      Caption = #8592' '#50577#54840
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lMaxAlertR: TLabel
      Left = 257
      Top = 212
      Width = 35
      Height = 13
      Caption = #50948#54744' '#8594
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lMinAlertR: TLabel
      Left = 257
      Top = 159
      Width = 35
      Height = 13
      Caption = #50948#54744' '#8594
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lFreeR: TLabel
      Left = 254
      Top = 268
      Width = 35
      Height = 13
      Caption = #50668#50976' '#8594
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lFreeL: TLabel
      Left = 16
      Top = 268
      Width = 35
      Height = 13
      Caption = #8592' '#48512#51313
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object pMinLatency: TProgressBar
      Left = 64
      Top = 158
      Width = 189
      Height = 17
      TabOrder = 0
    end
    object pMaxLatency: TProgressBar
      Left = 61
      Top = 210
      Width = 189
      Height = 17
      TabOrder = 1
    end
    object sMinLatency: TStaticText
      Left = 78
      Top = 139
      Width = 72
      Height = 17
      Caption = #50577#54840' (0.00ms)'
      TabOrder = 2
    end
    object sMaxLatency: TStaticText
      Left = 78
      Top = 191
      Width = 72
      Height = 17
      Caption = #50577#54840' (0.00ms)'
      TabOrder = 3
    end
    object sTestStage: TStaticText
      Left = 118
      Top = 48
      Width = 87
      Height = 17
      Caption = #51648#50672' '#49884#44036' '#53580#49828#53944
      TabOrder = 4
    end
    object sCycleCount: TStaticText
      Left = 105
      Top = 21
      Width = 21
      Height = 17
      Caption = '0'#54924
      TabOrder = 5
    end
    object pRamUsage: TProgressBar
      Left = 61
      Top = 265
      Width = 189
      Height = 17
      TabOrder = 6
    end
    object sRamUsage: TStaticText
      Left = 68
      Top = 242
      Width = 24
      Height = 17
      Caption = '0MB'
      TabOrder = 7
    end
    object pTestProgress: TProgressBar
      Left = 61
      Top = 108
      Width = 189
      Height = 17
      TabOrder = 8
    end
    object sTestProgress: TStaticText
      Left = 90
      Top = 89
      Width = 63
      Height = 17
      Caption = '0% (0 TBW)'
      TabOrder = 9
    end
  end
  object gFirstSet: TGroupBox
    Left = 335
    Top = 10
    Width = 225
    Height = 318
    Caption = #52572#52488' '#49444#51221
    TabOrder = 1
    object lFirstSetting: TListBox
      Left = 8
      Top = 21
      Width = 207
      Height = 286
      ItemHeight = 13
      TabOrder = 0
    end
  end
  object gAlert: TGroupBox
    Left = 566
    Top = 10
    Width = 225
    Height = 318
    Caption = #50508#47548
    TabOrder = 2
    object lAlert: TListBox
      Left = 8
      Top = 21
      Width = 207
      Height = 286
      ItemHeight = 13
      TabOrder = 0
    end
  end
  object bSave: TButton
    Left = 652
    Top = 331
    Width = 131
    Height = 25
    Caption = #51200#51109' '#48143' '#51333#47308
    Enabled = False
    TabOrder = 3
    OnClick = bSaveClick
  end
  object bForceReten: TButton
    Left = 515
    Top = 332
    Width = 131
    Height = 25
    Caption = #47532#53584#49496' '#53580#49828#53944' '#49884#51089
    Enabled = False
    TabOrder = 4
    OnClick = bForceRetenClick
  end
end
