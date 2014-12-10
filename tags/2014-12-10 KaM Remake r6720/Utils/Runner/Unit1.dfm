object Form2: TForm2
  Left = 244
  Top = 169
  Caption = 'Form2'
  ClientHeight = 641
  ClientWidth = 1097
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    1097
    641)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 128
    Width = 31
    Height = 13
    Caption = 'Cycles'
  end
  object Label2: TLabel
    Left = 124
    Top = 128
    Width = 3
    Height = 13
    Alignment = taRightJustify
  end
  object Button1: TButton
    Left = 136
    Top = 128
    Width = 57
    Height = 41
    Caption = 'Run'
    TabOrder = 0
    OnClick = Button1Click
  end
  object seCycles: TSpinEdit
    Left = 8
    Top = 144
    Width = 121
    Height = 22
    MaxValue = 1000000
    MinValue = 0
    TabOrder = 1
    Value = 10
  end
  object ListBox1: TListBox
    Left = 8
    Top = 8
    Width = 185
    Height = 113
    ItemHeight = 13
    TabOrder = 2
  end
  object Memo2: TMemo
    Left = 8
    Top = 256
    Width = 185
    Height = 137
    BorderStyle = bsNone
    Color = clBtnFace
    Lines.Strings = (
      'Runner'
      ''
      'Tool to run a game in pure simulation '
      'mode to test distribution of results '
      'and help catch bugs related to that.'
      ''
      'For example:'
      '  TestStone runs a stone mining that '
      'in theory should yeild same amount '
      'of stone each run')
    ReadOnly = True
    TabOrder = 3
  end
  object PageControl1: TPageControl
    Left = 208
    Top = 8
    Width = 881
    Height = 625
    ActivePage = Render
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 4
    OnChange = PageControl1Change
    ExplicitWidth = 697
    object TabSheet1: TTabSheet
      Caption = 'Results'
      OnResize = TabSheetResize
      ExplicitWidth = 681
      ExplicitHeight = 301
      DesignSize = (
        873
        597)
      object Image1: TImage
        Left = 40
        Top = 8
        Width = 825
        Height = 569
        Anchors = [akLeft, akTop, akRight, akBottom]
        ExplicitWidth = 633
        ExplicitHeight = 273
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Distribution'
      ImageIndex = 1
      OnResize = TabSheetResize
      ExplicitWidth = 681
      ExplicitHeight = 301
      DesignSize = (
        873
        597)
      object Image2: TImage
        Left = 40
        Top = 8
        Width = 825
        Height = 569
        Anchors = [akLeft, akTop, akRight, akBottom]
        ExplicitWidth = 633
        ExplicitHeight = 273
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Times'
      ImageIndex = 2
      OnResize = TabSheetResize
      ExplicitWidth = 681
      ExplicitHeight = 301
      DesignSize = (
        873
        597)
      object Image3: TImage
        Left = 40
        Top = 8
        Width = 825
        Height = 569
        Anchors = [akLeft, akTop, akRight, akBottom]
        ExplicitWidth = 633
        ExplicitHeight = 273
      end
      object Label3: TLabel
        Left = 720
        Top = 8
        Width = 47
        Height = 13
        Anchors = [akTop, akRight]
        Caption = 'Threshold'
        ExplicitLeft = 528
      end
      object TrackBar1: TTrackBar
        Left = 712
        Top = 24
        Width = 150
        Height = 33
        Anchors = [akTop, akRight]
        Max = 25
        Position = 10
        TabOrder = 0
        OnChange = TrackBar1Change
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Log'
      ImageIndex = 3
      ExplicitWidth = 681
      ExplicitHeight = 301
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 873
        Height = 597
        Align = alClient
        TabOrder = 0
        ExplicitLeft = 8
        ExplicitTop = 8
        ExplicitWidth = 665
        ExplicitHeight = 289
      end
    end
    object Render: TTabSheet
      Caption = 'Render'
      ImageIndex = 4
      ExplicitWidth = 681
      ExplicitHeight = 301
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 873
        Height = 597
        Align = alClient
        Caption = 'Panel1'
        TabOrder = 0
        ExplicitLeft = 200
        ExplicitTop = 8
        ExplicitWidth = 249
        ExplicitHeight = 161
      end
    end
  end
  object chkRender: TCheckBox
    Left = 8
    Top = 176
    Width = 57
    Height = 17
    Caption = 'Render'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
end
