object Form1: TForm1
  Left = 40
  Top = 87
  Caption = 'KaM Remake Translation Manager'
  ClientHeight = 569
  ClientWidth = 825
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poDesktopCenter
  Scaled = False
  WindowState = wsMaximized
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    825
    569)
  PixelsPerInch = 96
  TextHeight = 16
  object Label1: TLabel
    Left = 488
    Top = 8
    Width = 89
    Height = 16
    Caption = 'Constant name'
  end
  object Label2: TLabel
    Left = 336
    Top = 374
    Width = 85
    Height = 16
    Caption = 'Show Missing:'
  end
  object LabelIncludeSameAsEnglish: TLabel
    Left = 357
    Top = 424
    Width = 116
    Height = 49
    AutoSize = False
    Caption = 'Include strings that are the same in English'
    Enabled = False
    WordWrap = True
    OnClick = LabelIncludeSameAsEnglishClick
  end
  object Label3: TLabel
    Left = 336
    Top = 8
    Width = 34
    Height = 16
    Caption = 'Count'
  end
  object Label4: TLabel
    Left = 336
    Top = 488
    Width = 32
    Height = 16
    Caption = 'Filter:'
  end
  object Label5: TLabel
    Left = 336
    Top = 314
    Width = 100
    Height = 16
    Caption = 'Show Language:'
  end
  object lbFolders: TListBox
    Left = 8
    Top = 8
    Width = 321
    Height = 249
    TabOrder = 15
    OnClick = lbFoldersClick
  end
  object ListBox1: TListBox
    Left = 8
    Top = 264
    Width = 321
    Height = 297
    Anchors = [akLeft, akTop, akBottom]
    TabOrder = 0
    OnClick = ListBox1Click
  end
  object EditConstName: TEdit
    Left = 488
    Top = 24
    Width = 297
    Height = 24
    Enabled = False
    TabOrder = 1
    OnChange = EditConstNameChange
  end
  object btnSortByIndex: TButton
    Left = 336
    Top = 232
    Width = 145
    Height = 25
    Caption = 'Sort by Index'
    TabOrder = 2
    OnClick = btnSortByIndexClick
  end
  object btnSave: TButton
    Left = 336
    Top = 32
    Width = 145
    Height = 33
    Caption = 'Save'
    TabOrder = 3
    OnClick = btnSaveClick
  end
  object btnInsert: TButton
    Left = 336
    Top = 80
    Width = 145
    Height = 25
    Caption = 'Insert New'
    TabOrder = 4
    OnClick = btnInsertClick
  end
  object ScrollBox1: TScrollBox
    Left = 488
    Top = 48
    Width = 329
    Height = 513
    HorzScrollBar.Visible = False
    VertScrollBar.Smooth = True
    VertScrollBar.Tracking = True
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 5
  end
  object btnInsertSeparator: TButton
    Left = 336
    Top = 104
    Width = 145
    Height = 25
    Caption = 'Insert Separator'
    TabOrder = 7
    OnClick = btnInsertSeparatorClick
  end
  object btnMoveUp: TButton
    Left = 336
    Top = 168
    Width = 145
    Height = 25
    Caption = 'Move Up'
    TabOrder = 8
    OnClick = btnMoveUpClick
  end
  object btnMoveDown: TButton
    Left = 336
    Top = 192
    Width = 145
    Height = 25
    Caption = 'Move Down'
    TabOrder = 9
    OnClick = btnMoveDownClick
  end
  object cbShowMissing: TComboBox
    Left = 336
    Top = 392
    Width = 145
    Height = 24
    Style = csDropDownList
    DropDownCount = 16
    TabOrder = 10
    OnChange = cbShowMissingChange
  end
  object cbIncludeSameAsEnglish: TCheckBox
    Left = 336
    Top = 424
    Width = 17
    Height = 17
    Enabled = False
    TabOrder = 11
    OnClick = cbIncludeSameAsEnglishClick
  end
  object btnSortByName: TButton
    Left = 336
    Top = 256
    Width = 145
    Height = 25
    Caption = 'Sort by Name'
    TabOrder = 12
    OnClick = btnSortByNameClick
  end
  object btnCompactIndexes: TButton
    Left = 336
    Top = 280
    Width = 145
    Height = 25
    Caption = 'Compact Indexes'
    TabOrder = 13
    OnClick = btnCompactIndexesClick
  end
  object Button1: TButton
    Left = 16
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Export TSK'
    TabOrder = 14
    Visible = False
    OnClick = Button1Click
  end
  object btnDelete: TButton
    Left = 336
    Top = 128
    Width = 145
    Height = 25
    Caption = 'Delete'
    TabOrder = 6
    OnClick = btnDeleteClick
  end
  object btnCopy: TButton
    Left = 688
    Top = 24
    Width = 65
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Copy'
    TabOrder = 16
    OnClick = btnCopyClick
  end
  object btnPaste: TButton
    Left = 752
    Top = 24
    Width = 65
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Paste'
    Enabled = False
    TabOrder = 17
    OnClick = btnPasteClick
  end
  object Edit1: TEdit
    Left = 336
    Top = 504
    Width = 145
    Height = 24
    TabOrder = 18
    OnChange = Edit1Change
  end
  object cbShowLang: TComboBox
    Left = 336
    Top = 330
    Width = 145
    Height = 24
    Style = csDropDownList
    DropDownCount = 16
    ItemHeight = 16
    TabOrder = 19
    OnChange = cbShowLangChange
  end
  object btnUnused: TButton
    Left = 336
    Top = 304
    Width = 145
    Height = 25
    Caption = 'List unused'
    TabOrder = 20
    OnClick = btnUnusedClick
  end
end
