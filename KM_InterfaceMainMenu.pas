unit KM_InterfaceMainMenu;
interface
uses MMSystem, SysUtils, KromUtils, KromOGLUtils, Math, Classes, Controls,
  {$IFDEF DELPHI} OpenGL, {$ENDIF}
  {$IFDEF FPC} GL, {$ENDIF}
  KM_Controls, KM_Defaults, KM_LoadDAT, Windows, KM_Settings;


type TKMMainMenuInterface = class
  private
    ScreenX,ScreenY:word;
    OffX,OffY:integer;
    Campaign_Selected:TCampaign;
    SingleMap_Top:integer; //Top map in list
    SingleMap_Selected:integer; //Selected map
    SingleMapsInfo:TKMMapsInfo;
    MapEdSizeX,MapEdSizeY:integer; //Map Editor map size
    OldFullScreen:boolean;
    OldResolution:word;
  protected
    Panel_Main1:TKMPanel;
      L:array[1..20]of TKMLabel;
      FL:TKMFileList;
    Panel_MainMenu:TKMPanel;
      Panel_MainButtons:TKMPanel;
      Image_MainMenuBG,Image_MainMenu1,Image_MainMenu3:TKMImage; //Menu background
      Button_MainMenuSinglePlayer,
      Button_MainMenuMultiPlayer,
      Button_MainMenuMapEd,
      Button_MainMenuOptions,
      Button_MainMenuCredit,
      Button_MainMenuQuit:TKMButton;
      Label_Version:TKMLabel;
    Panel_SinglePlayer:TKMPanel;
      Image_SinglePlayerBG,Image_SinglePlayer1,Image_SinglePlayer3:TKMImage; //Background
      Panel_SinglePlayerButtons:TKMPanel;
      Button_SinglePlayerTutor,
      Button_SinglePlayerFight,
      Button_SinglePlayerTSK,
      Button_SinglePlayerTPR,
      Button_SinglePlayerSingle,
      Button_SinglePlayerLoad:TKMButton;
      Button_SinglePlayerBack:TKMButton;
    Panel_Campaign:TKMPanel;
      Image_CampaignBG:TKMImage;
      Campaign_Nodes:array[1..MAX_MAPS] of TKMImage;
      Image_ScrollTop,Image_Scroll:TKMImage;
      Label_CampaignText:TKMLabel;
      Label_CampaignStart:TKMLabel; //A button ;)
      Button_CampaignBack:TKMButton;
    Panel_Single:TKMPanel;
      Image_SingleBG:TKMImage;
      Panel_SingleList,Panel_SingleDesc:TKMPanel;
      Button_SingleHeadMode,Button_SingleHeadTeams,Button_SingleHeadTitle,Button_SingleHeadSize,Button_SingleHeadNix:TKMButton;
      Bevel_SingleBG:array[1..MENU_SP_MAPS_COUNT,1..4]of TKMBevel;
      Button_SingleMode:array[1..MENU_SP_MAPS_COUNT]of TKMImage;
      Button_SinglePlayers,Button_SingleSize:array[1..MENU_SP_MAPS_COUNT]of TKMLabel;
      Label_SingleTitle1,Label_SingleTitle2:array[1..MENU_SP_MAPS_COUNT]of TKMLabel;
      ScrollBar_SingleMaps:TKMScrollBar;
      Shape_SingleMap:TKMShape;
      Image_SingleScroll1:TKMImage;
      Label_SingleTitle,Label_SingleDesc:TKMLabel;
      Label_SingleCondTyp,Label_SingleCondWin,Label_SingleCondDef:TKMLabel;
      Label_SingleAllies,Label_SingleEnemies:TKMLabel;
      Button_SingleBack,Button_SingleStart:TKMButton;
    Panel_Load:TKMPanel;
      Image_LoadBG:TKMImage;
      Button_Load:array[1..SAVEGAME_COUNT] of TKMButton;
      Button_LoadBack:TKMButton;
    Panel_MapEd:TKMPanel;
      Image_MapEd_BG:TKMImage;
      Panel_MapEd_SizeXY:TKMPanel;
      CheckBox_MapEd_SizeX,CheckBox_MapEd_SizeY:array[1..MAPSIZE_COUNT] of TKMCheckBox;
      Button_MapEd_Start,Button_MapEdBack:TKMButton;
    Panel_Options:TKMPanel;
      Image_Options_BG, Image_Options_RightCrest:TKMImage;
      Panel_Options_GFX:TKMPanel;
        Ratio_Options_Brightness:TKMRatioRow;
      Panel_Options_Ctrl:TKMPanel;
        Label_Options_MouseSpeed:TKMLabel;
        Ratio_Options_Mouse:TKMRatioRow;
      Panel_Options_Game:TKMPanel;
        CheckBox_Options_Autosave:TKMCheckBox;
      Panel_Options_Sound:TKMPanel;
        Label_Options_SFX,Label_Options_Music,Label_Options_MusicOn:TKMLabel;
        Ratio_Options_SFX,Ratio_Options_Music:TKMRatioRow;
        Button_Options_MusicOn:TKMButton;
      Panel_Options_Lang:TKMPanel;
        CheckBox_Options_Lang:array[1..LocalesCount] of TKMCheckBox;
      Panel_Options_Res:TKMPanel;
        CheckBox_Options_FullScreen:TKMCheckBox;
        CheckBox_Options_Resolution:array[1..RESOLUTION_COUNT] of TKMCheckBox;
        Button_Options_ResApply:TKMButton;
      Button_Options_Back:TKMButton;
    Panel_Credits:TKMPanel;
      Image_CreditsBG:TKMImage;
      Label_Credits:TKMLabel;
      Button_CreditsBack:TKMButton;
    Panel_Loading:TKMPanel;
      Image_LoadingBG, Image_Loading_RightCrest:TKMImage;
      Label_Loading:TKMLabel;
    Panel_Error:TKMPanel;
      Image_ErrorBG:TKMImage;
      Label_Error:TKMLabel;
      Button_ErrorBack:TKMButton;
    Panel_Results:TKMPanel;
      Image_ResultsBG:TKMImage;
      Label_Results_Result:TKMLabel;
      Panel_Stats:TKMPanel;
      Label_Stat:array[1..9]of TKMLabel;
      Button_ResultsBack,Button_ResultsRepeat,Button_ResultsContinue:TKMButton;
  private
    procedure Create_MainMenu_Page;
    procedure Create_SinglePlayer_Page;
    procedure Create_Campaign_Page;
    procedure Create_Single_Page;
    procedure Create_Load_Page;
    procedure Create_MapEditor_Page;
    procedure Create_Options_Page(aGameSettings:TGlobalSettings);
    procedure Create_Credits_Page;
    procedure Create_Loading_Page;
    procedure Create_Error_Page;
    procedure Create_Results_Page;
    procedure SwitchMenuPage(Sender: TObject);
    procedure MainMenu_PlayTutorial(Sender: TObject);
    procedure MainMenu_PlayBattle(Sender: TObject);
    procedure MainMenu_ReplayLastMap(Sender: TObject);
    procedure Campaign_Set(aCampaign:TCampaign);
    procedure Campaign_SelectMap(Sender: TObject);
    procedure Campaign_StartMap(Sender: TObject);
    procedure SingleMap_PopulateList();
    procedure SingleMap_RefreshList();
    procedure SingleMap_ScrollChange(Sender: TObject);
    procedure SingleMap_SelectMap(Sender: TObject);
    procedure SingleMap_Start(Sender: TObject);
    procedure Load_Click(Sender: TObject);
    procedure Load_PopulateList();
    procedure MapEditor_Start(Sender: TObject);
    procedure MapEditor_Change(Sender: TObject);
    procedure Options_Change(Sender: TObject);
  public
    MyControls: TKMControlsCollection;
    constructor Create(X,Y:word; aGameSettings:TGlobalSettings);
    destructor Destroy; override;
    procedure SetScreenSize(X,Y:word);
    procedure ShowScreen_Loading(Text:string);
    procedure ShowScreen_Error(Text:string);
    procedure ShowScreen_Main();
    procedure ShowScreen_Options();
    procedure ShowScreen_Results(Msg:gr_Message);
    procedure Fill_Results();
  public
    procedure UpdateState;
    procedure Paint;
end;


implementation
uses KM_Unit1, KM_Render, KM_LoadLib, KM_Game, KM_PlayersCollection, KM_CommonTypes, Forms, KM_Utils;


constructor TKMMainMenuInterface.Create(X,Y:word; aGameSettings:TGlobalSettings);
{var i:integer;}
begin
inherited Create;

  fLog.AssertToLog(fTextLibrary<>nil, 'fTextLibrary should be initialized before MainMenuInterface');

  MyControls := TKMControlsCollection.Create;
  ScreenX := min(X,MENU_DESIGN_X);
  ScreenY := min(Y,MENU_DESIGN_Y);
  OffX := (X-MENU_DESIGN_X) div 2;
  OffY := (Y-MENU_DESIGN_Y) div 2;
  SingleMap_Top := 1;
  SingleMap_Selected := 1;
  MapEdSizeX := 64;
  MapEdSizeY := 64;

  Panel_Main1 := MyControls.AddPanel(nil, OffX, OffY, ScreenX, ScreenY); //Parent Panel for whole menu

  Create_MainMenu_Page;
  Create_SinglePlayer_Page;
    Create_Campaign_Page;
    Create_Single_Page;
    Create_Load_Page;
  Create_MapEditor_Page;
  Create_Options_Page(aGameSettings);
  Create_Credits_Page;
  Create_Loading_Page;
  Create_Error_Page;
  Create_Results_Page;

  {for i:=1 to length(FontFiles) do
    L[i]:=MyControls.AddLabel(Panel_Main1,550,280+i*20,160,30,'This is a test string for KaM Remake ('+FontFiles[i],TKMFont(i),kaLeft);
  //}

  //Show version info on every page
  Label_Version := MyControls.AddLabel(Panel_Main1,8,8,100,30,GAME_VERSION+' / OpenGL '+fRender.GetRendererVersion,fnt_Antiqua,kaLeft);

  if SHOW_1024_768_OVERLAY then MyControls.AddShape(nil, OffX, OffY, 1024, 768, $FF00FF00);

  //@Lewin: TextEdit example. To be deleted..
  MyControls.AddTextEdit(nil, 32, 32, 200, 20, fnt_Grey);//}

  //@Lewin: FileList example. To be deleted..
  FL := MyControls.AddFileList(nil, 550, 300, 320, 220);
  FL.RefreshList(ExeDir+'Maps\','dat',true);

  SwitchMenuPage(nil);
  //ShowScreen_Results(); //Put here page you would like to debug
end;


destructor TKMMainMenuInterface.Destroy;
begin
  FreeAndNil(SingleMapsInfo);
  FreeAndNil(MyControls);
  inherited;
end;


procedure TKMMainMenuInterface.SetScreenSize(X, Y:word);
begin
  ScreenX := X;
  ScreenY := Y;
end;


procedure TKMMainMenuInterface.ShowScreen_Loading(Text:string);
begin
  Label_Loading.Caption:=Text;
  SwitchMenuPage(Panel_Loading);
end;


procedure TKMMainMenuInterface.ShowScreen_Error(Text:string);
begin
  Label_Error.Caption:=Text;
  SwitchMenuPage(Panel_Error);
end;


procedure TKMMainMenuInterface.ShowScreen_Main();
begin
  SwitchMenuPage(nil);
end;


procedure TKMMainMenuInterface.ShowScreen_Options();
begin
  SwitchMenuPage(Button_MainMenuOptions);
end;


procedure TKMMainMenuInterface.ShowScreen_Results(Msg:gr_Message);
begin
  case Msg of
    gr_Win:    Label_Results_Result.Caption := fTextLibrary.GetSetupString(111);
    gr_Defeat: Label_Results_Result.Caption := fTextLibrary.GetSetupString(112);
    gr_Cancel: Label_Results_Result.Caption := 'Mission canceled';
    else       Label_Results_Result.Caption := '<<<LEER>>>'; //Thats string used in all Synetic games for missing texts =)
  end;

  Button_ResultsRepeat.Enabled := Msg = gr_Defeat;

  //Even if the campaign is complete Player can now return to it's screen to replay any of the maps
  Button_ResultsContinue.Visible := fGame.GetCampaign in [cmp_TSK, cmp_TPR];
  Button_ResultsContinue.Enabled := Msg = gr_Win;

  SwitchMenuPage(Panel_Results);
end;


procedure TKMMainMenuInterface.Fill_Results();
begin
  if (MyPlayer=nil) or (MyPlayer.fMissionSettings=nil) then exit;

  Label_Stat[1].Caption := inttostr(MyPlayer.fMissionSettings.GetUnitsLost);
  Label_Stat[2].Caption := inttostr(MyPlayer.fMissionSettings.GetUnitsKilled);
  Label_Stat[3].Caption := inttostr(MyPlayer.fMissionSettings.GetHousesLost);
  Label_Stat[4].Caption := inttostr(MyPlayer.fMissionSettings.GetHousesDestroyed);
  Label_Stat[5].Caption := inttostr(MyPlayer.fMissionSettings.GetHousesConstructed);
  Label_Stat[6].Caption := inttostr(MyPlayer.fMissionSettings.GetUnitsTrained);
  Label_Stat[7].Caption := inttostr(MyPlayer.fMissionSettings.GetWeaponsProduced);
  Label_Stat[8].Caption := inttostr(MyPlayer.fMissionSettings.GetSoldiersTrained);
  Label_Stat[9].Caption := int2time(fGame.GetMissionTime);
end;


procedure TKMMainMenuInterface.Create_MainMenu_Page;
begin
  Panel_MainMenu:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_MainMenuBG:=MyControls.AddImage(Panel_MainMenu,0,0,ScreenX,ScreenY,2,6);
    Image_MainMenuBG.Stretch;
    Image_MainMenu1:=MyControls.AddImage(Panel_MainMenu,120,80,423,164,4,5);
    Image_MainMenu3:=MyControls.AddImage(Panel_MainMenu,635,220,round(207*1.3),round(295*1.3),6,6);
    Image_MainMenu3.Stretch;

    Panel_MainButtons:=MyControls.AddPanel(Panel_MainMenu,155,280,350,400);
      Button_MainMenuSinglePlayer := MyControls.AddButton(Panel_MainButtons,0,0,350,30,'Single Player',fnt_Metal,bsMenu);
      Button_MainMenuMultiPlayer  := MyControls.AddButton(Panel_MainButtons,0,40,350,30,fTextLibrary.GetSetupString(11),fnt_Metal,bsMenu);
      Button_MainMenuMapEd        := MyControls.AddButton(Panel_MainButtons,0,80,350,30,'Map Editor',fnt_Metal,bsMenu);
      Button_MainMenuOptions      := MyControls.AddButton(Panel_MainButtons,0,120,350,30,fTextLibrary.GetSetupString(12),fnt_Metal,bsMenu);
      Button_MainMenuCredit       := MyControls.AddButton(Panel_MainButtons,0,160,350,30,fTextLibrary.GetSetupString(13),fnt_Metal,bsMenu);
      Button_MainMenuQuit         := MyControls.AddButton(Panel_MainButtons,0,360,350,30,fTextLibrary.GetSetupString(14),fnt_Metal,bsMenu);
      Button_MainMenuSinglePlayer.OnClick    := SwitchMenuPage;
      //Button_MainMenuMultiPlayer.OnClick     := SwitchMenuPage;
      Button_MainMenuMapEd.OnClick    := SwitchMenuPage;
      Button_MainMenuOptions.OnClick  := SwitchMenuPage;
      Button_MainMenuCredit.OnClick   := SwitchMenuPage;
      Button_MainMenuQuit.OnClick     := Form1.Exit1.OnClick;
      if not SHOW_MAPED_IN_MENU then Button_MainMenuMapEd.Hide; //Let it be created, but hidden, I guess there's no need to seriously block it
      Button_MainMenuMultiPlayer.Disable;
      //Button_MainMenuCredit.Disable;
end;


procedure TKMMainMenuInterface.Create_SinglePlayer_Page;
begin
  Panel_SinglePlayer:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_SinglePlayerBG:=MyControls.AddImage(Panel_SinglePlayer,0,0,ScreenX,ScreenY,2,6);
    Image_SinglePlayerBG.Stretch;
    Image_SinglePlayer1:=MyControls.AddImage(Panel_SinglePlayer,120,80,423,164,4,5);
    Image_SinglePlayer3:=MyControls.AddImage(Panel_SinglePlayer,635,220,round(207*1.3),round(295*1.3),6,6);
    Image_SinglePlayer3.Stretch;

    Panel_SinglePlayerButtons:=MyControls.AddPanel(Panel_SinglePlayer,155,280,350,400);
      Button_SinglePlayerTutor  :=MyControls.AddButton(Panel_SinglePlayerButtons,0,  0,350,30,'Town Tutorial',fnt_Metal,bsMenu);
      Button_SinglePlayerFight  :=MyControls.AddButton(Panel_SinglePlayerButtons,0, 40,350,30,'Battle Tutorial',fnt_Metal,bsMenu);
      Button_SinglePlayerTSK    :=MyControls.AddButton(Panel_SinglePlayerButtons,0, 80,350,30,fTextLibrary.GetSetupString( 1),fnt_Metal,bsMenu);
      Button_SinglePlayerTPR    :=MyControls.AddButton(Panel_SinglePlayerButtons,0,120,350,30,fTextLibrary.GetSetupString( 2),fnt_Metal,bsMenu);
      Button_SinglePlayerSingle :=MyControls.AddButton(Panel_SinglePlayerButtons,0,160,350,30,fTextLibrary.GetSetupString( 4),fnt_Metal,bsMenu);
      Button_SinglePlayerLoad   :=MyControls.AddButton(Panel_SinglePlayerButtons,0,200,350,30,fTextLibrary.GetSetupString(10),fnt_Metal,bsMenu);

      Button_SinglePlayerTutor.OnClick    := MainMenu_PlayTutorial;
      Button_SinglePlayerFight.OnClick    := MainMenu_PlayBattle;
      Button_SinglePlayerTSK.OnClick      := SwitchMenuPage;
      Button_SinglePlayerTPR.OnClick      := SwitchMenuPage;
      Button_SinglePlayerSingle.OnClick   := SwitchMenuPage;
      Button_SinglePlayerLoad.OnClick     := SwitchMenuPage;

    Button_SinglePlayerBack := MyControls.AddButton(Panel_SinglePlayer, 45, 650, 220, 30, fTextLibrary.GetSetupString(9), fnt_Metal, bsMenu);
    Button_SinglePlayerBack.OnClick := SwitchMenuPage;
end;


procedure TKMMainMenuInterface.Create_Campaign_Page;
var i:integer;
begin
  Panel_Campaign:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_CampaignBG:=MyControls.AddImage(Panel_Campaign,0,0,ScreenX,ScreenY,12,6);
    Image_CampaignBG.Stretch;

    for i:=1 to length(Campaign_Nodes) do begin
      Campaign_Nodes[i] := MyControls.AddImage(Panel_Campaign, ScreenX div 2, ScreenY div 2,23,29,10,6);
      Campaign_Nodes[i].Center; //I guess it's easier to position them this way
      Campaign_Nodes[i].OnClick := Campaign_SelectMap;
      Campaign_Nodes[i].Tag := i;
    end;

    Image_Scroll := MyControls.AddImage(Panel_Campaign, ScreenX-360, ScreenY-397,360,397,15,6);
    Label_CampaignText := MyControls.AddLabel(Panel_Campaign, ScreenX-340, ScreenY-330,320,310, '', fnt_Briefing, kaLeft);
    Label_CampaignText.AutoWrap := true;

    Label_CampaignStart := MyControls.AddLabel(Panel_Campaign, ScreenX-30, ScreenY-30,100,20, fTextLibrary.GetSetupString(17), fnt_Briefing, kaRight);
    Label_CampaignStart.OnClick := Campaign_StartMap;

    Button_CampaignBack := MyControls.AddButton(Panel_Campaign, 20, ScreenY-50, 220, 30, fTextLibrary.GetSetupString(9), fnt_Metal, bsMenu);
    Button_CampaignBack.OnClick := SwitchMenuPage;
end;


procedure TKMMainMenuInterface.Create_Single_Page;
var i,k:integer;
begin
  SingleMapsInfo:=TKMMapsInfo.Create;

  Panel_Single:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);

    Image_SingleBG:=MyControls.AddImage(Panel_Single,0,0,ScreenX,ScreenY,2,6);
    Image_SingleBG.Stretch;

    Panel_SingleList:=MyControls.AddPanel(Panel_Single,512+22,84,445,600);

      Button_SingleHeadMode :=MyControls.AddButton(Panel_SingleList,  0,0, 40,40,42,4,bsMenu);
      Button_SingleHeadTeams:=MyControls.AddButton(Panel_SingleList, 40,0, 40,40,31,4,bsMenu);
      Button_SingleHeadTitle:=MyControls.AddButton(Panel_SingleList, 80,0,300,40,'Title',fnt_Metal,bsMenu);
      Button_SingleHeadSize :=MyControls.AddButton(Panel_SingleList,380,0, 40,40,'Size',fnt_Metal,bsMenu);
      Button_SingleHeadNix  :=MyControls.AddButton(Panel_SingleList,420,0, 25,40,'',fnt_Game,bsMenu);
      Button_SingleHeadNix.Disable;
      for i:=1 to MENU_SP_MAPS_COUNT do
      begin
        Bevel_SingleBG[i,1]:=MyControls.AddBevel(Panel_SingleList,0,  40+(i-1)*40,40,40);
        Bevel_SingleBG[i,2]:=MyControls.AddBevel(Panel_SingleList,40, 40+(i-1)*40,40,40);
        Bevel_SingleBG[i,3]:=MyControls.AddBevel(Panel_SingleList,80, 40+(i-1)*40,300,40);
        Bevel_SingleBG[i,4]:=MyControls.AddBevel(Panel_SingleList,380,40+(i-1)*40,40,40);
        for k:=1 to length(Bevel_SingleBG[i]) do
        begin
          Bevel_SingleBG[i,k].Tag:=i;
          Bevel_SingleBG[i,k].OnClick:=SingleMap_SelectMap;
        end;
        Button_SingleMode[i]   :=MyControls.AddImage(Panel_SingleList,  0   ,40+(i-1)*40,40,40,28);
        Button_SinglePlayers[i]:=MyControls.AddLabel(Panel_SingleList, 40+20,40+(i-1)*40+14,40,40,'0',fnt_Metal, kaCenter);
        Label_SingleTitle1[i]  :=MyControls.AddLabel(Panel_SingleList, 80+6 ,40+5+(i-1)*40,40,40,'<<<LEER>>>',fnt_Metal, kaLeft);
        Label_SingleTitle2[i]  :=MyControls.AddLabel(Panel_SingleList, 80+6 ,40+22+(i-1)*40,40,40,'<<<LEER>>>',fnt_Game, kaLeft);
        Button_SingleSize[i]   :=MyControls.AddLabel(Panel_SingleList,380+20,40+(i-1)*40+14,40,40,'0',fnt_Metal, kaCenter);
      end;

      ScrollBar_SingleMaps:=MyControls.AddScrollBar(Panel_SingleList,420,40,25,MENU_SP_MAPS_COUNT*40, sa_Vertical, bsMenu);
      ScrollBar_SingleMaps.OnChange:=SingleMap_ScrollChange;

      Shape_SingleMap:=MyControls.AddShape(Panel_SingleList,0,40,420,40,$FFFFFF00);

    Panel_SingleDesc:=MyControls.AddPanel(Panel_Single,45,84,445,600);

      MyControls.AddBevel(Panel_SingleDesc,0,0,445,220);

      //Image_SingleScroll1:=MyControls.AddImage(Panel_SingleDesc,0,0,445,220,15,5);
      //Image_SingleScroll1.StretchImage:=true;
      //Image_SingleScroll1.Height:=220; //Need to reset it after stretching is enabled, cos it can't stretch down by default

      Label_SingleTitle:=MyControls.AddLabel(Panel_SingleDesc,445 div 2,35,420,180,'',fnt_Outline, kaCenter);
      Label_SingleTitle.AutoWrap:=true;

      Label_SingleDesc:=MyControls.AddLabel(Panel_SingleDesc,15,60,420,160,'',fnt_Metal, kaLeft);
      Label_SingleDesc.AutoWrap:=true;

      MyControls.AddBevel(Panel_SingleDesc,125,230,192,192);

      MyControls.AddBevel(Panel_SingleDesc,0,428,445,20);
      Label_SingleCondTyp:=MyControls.AddLabel(Panel_SingleDesc,8,431,445,20,'Mission type: ',fnt_Metal, kaLeft);
      MyControls.AddBevel(Panel_SingleDesc,0,450,445,20);
      Label_SingleCondWin:=MyControls.AddLabel(Panel_SingleDesc,8,453,445,20,'Win condition: ',fnt_Metal, kaLeft);
      MyControls.AddBevel(Panel_SingleDesc,0,472,445,20);
      Label_SingleCondDef:=MyControls.AddLabel(Panel_SingleDesc,8,475,445,20,'Defeat condition: ',fnt_Metal, kaLeft);
      MyControls.AddBevel(Panel_SingleDesc,0,494,445,20);
      Label_SingleAllies:=MyControls.AddLabel(Panel_SingleDesc,8,497,445,20,'Allies: ',fnt_Metal, kaLeft);
      MyControls.AddBevel(Panel_SingleDesc,0,516,445,20);
      Label_SingleEnemies:=MyControls.AddLabel(Panel_SingleDesc,8,519,445,20,'Enemies: ',fnt_Metal, kaLeft);

    Button_SingleBack := MyControls.AddButton(Panel_Single, 45, 650, 220, 30, fTextLibrary.GetSetupString(9), fnt_Metal, bsMenu);
    Button_SingleBack.OnClick := SwitchMenuPage;
    Button_SingleStart := MyControls.AddButton(Panel_Single, 270, 650, 220, 30, fTextLibrary.GetSetupString(8), fnt_Metal, bsMenu);
    Button_SingleStart.OnClick := SingleMap_Start;
end;


procedure TKMMainMenuInterface.Create_Load_Page;
var i:integer;
begin
  Panel_Load:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_LoadBG:=MyControls.AddImage(Panel_Load,0,0,ScreenX,ScreenY,2,6);
    Image_LoadBG.Stretch;
    Image_Loading_RightCrest:=MyControls.AddImage(Panel_Load,635,220,round(207*1.3),round(295*1.3),6,6);
    Image_Loading_RightCrest.Stretch;

    for i:=1 to SAVEGAME_COUNT do
    begin
      Button_Load[i] := MyControls.AddButton(Panel_Load,147,110+i*40,220,30,'Slot '+inttostr(i),fnt_Metal, bsMenu);
      Button_Load[i].Tag := i; //To simplify usage
      Button_Load[i].OnClick := Load_Click;
    end;

    Button_LoadBack := MyControls.AddButton(Panel_Load, 145, 650, 224, 30, fTextLibrary.GetSetupString(9), fnt_Metal, bsMenu);
    Button_LoadBack.OnClick := SwitchMenuPage;
end;


procedure TKMMainMenuInterface.Create_MapEditor_Page;
var i:integer;
begin
  Panel_MapEd:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_MapEd_BG:=MyControls.AddImage(Panel_MapEd,0,0,ScreenX,ScreenY,2,6);
    Image_MapEd_BG.Stretch;

    //Should contain options to make a map from scratch, load map from file, generate random preset

    Panel_MapEd_SizeXY := MyControls.AddPanel(Panel_MapEd, 245, 200, 150, 300);
      MyControls.AddLabel(Panel_MapEd_SizeXY, 6, 0, 100, 30, 'Map size X:Y', fnt_Outline, kaLeft);
      MyControls.AddBevel(Panel_MapEd_SizeXY, 0, 20, 200, 10 + MAPSIZE_COUNT*20);
      for i:=1 to MAPSIZE_COUNT do
      begin
        CheckBox_MapEd_SizeX[i] := MyControls.AddCheckBox(Panel_MapEd_SizeXY, 8, 27+(i-1)*20, 100, 30, inttostr(MapSize[i]),fnt_Metal);
        CheckBox_MapEd_SizeY[i] := MyControls.AddCheckBox(Panel_MapEd_SizeXY, 68, 27+(i-1)*20, 100, 30, inttostr(MapSize[i]),fnt_Metal);
        CheckBox_MapEd_SizeX[i].OnClick := MapEditor_Change;
        CheckBox_MapEd_SizeY[i].OnClick := MapEditor_Change;
      end;

    Button_MapEdBack := MyControls.AddButton(Panel_MapEd, 145, 650, 220, 30, fTextLibrary.GetSetupString(9), fnt_Metal, bsMenu);
    Button_MapEdBack.OnClick := SwitchMenuPage;
    Button_MapEd_Start := MyControls.AddButton(Panel_MapEd, 370, 650, 220, 30, 'Create New Map', fnt_Metal, bsMenu);
    Button_MapEd_Start.OnClick := MapEditor_Start;
end;


procedure TKMMainMenuInterface.Create_Options_Page(aGameSettings:TGlobalSettings);
var i:integer;
begin
  Panel_Options:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_Options_BG:=MyControls.AddImage(Panel_Options,0,0,ScreenX,ScreenY,2,6);
    Image_Options_BG.Stretch;
    Image_Options_RightCrest:=MyControls.AddImage(Panel_Options,635,220,round(207*1.3),round(295*1.3),6,6);
    Image_Options_RightCrest.Stretch;

    Panel_Options_GFX:=MyControls.AddPanel(Panel_Options,520,130,170,80);
      MyControls.AddLabel(Panel_Options_GFX,6,0,100,30,'Graphics:',fnt_Outline,kaLeft);
      MyControls.AddBevel(Panel_Options_GFX,0,20,170,60);
      MyControls.AddLabel(Panel_Options_GFX,18,27,100,30,'Brightness',fnt_Metal,kaLeft);
      Ratio_Options_Brightness:=MyControls.AddRatioRow(Panel_Options_GFX,10,47,150,20,aGameSettings.GetSlidersMin,aGameSettings.GetSlidersMax);
      Ratio_Options_Brightness.OnChange:=Options_Change;

    Panel_Options_Ctrl:=MyControls.AddPanel(Panel_Options,120,130,170,80);
      MyControls.AddLabel(Panel_Options_Ctrl,6,0,100,30,'Controls:',fnt_Outline,kaLeft);
      MyControls.AddBevel(Panel_Options_Ctrl,0,20,170,60);

      Label_Options_MouseSpeed:=MyControls.AddLabel(Panel_Options_Ctrl,18,27,100,30,fTextLibrary.GetTextString(192),fnt_Metal,kaLeft);
      Label_Options_MouseSpeed.Disable;
      Ratio_Options_Mouse:=MyControls.AddRatioRow(Panel_Options_Ctrl,10,47,150,20,aGameSettings.GetSlidersMin,aGameSettings.GetSlidersMax);
      Ratio_Options_Mouse.Disable;

    Panel_Options_Game:=MyControls.AddPanel(Panel_Options,120,230,170,50);
      MyControls.AddLabel(Panel_Options_Game,6,0,100,30,'Gameplay:',fnt_Outline,kaLeft);
      MyControls.AddBevel(Panel_Options_Game,0,20,170,30);

      CheckBox_Options_Autosave := MyControls.AddCheckBox(Panel_Options_Game,18,27,100,30,fTextLibrary.GetTextString(203), fnt_Metal);
      CheckBox_Options_Autosave.OnClick := Options_Change;

    Panel_Options_Sound:=MyControls.AddPanel(Panel_Options,120,300,170,130);
      MyControls.AddLabel(Panel_Options_Sound,6,0,100,30,'Sound:',fnt_Outline,kaLeft);
      MyControls.AddBevel(Panel_Options_Sound,0,20,170,110);

      Label_Options_SFX:=MyControls.AddLabel(Panel_Options_Sound,18,27,100,30,fTextLibrary.GetTextString(194),fnt_Metal,kaLeft);
      Ratio_Options_SFX:=MyControls.AddRatioRow(Panel_Options_Sound,10,47,150,20,aGameSettings.GetSlidersMin,aGameSettings.GetSlidersMax);
      Ratio_Options_SFX.OnChange:=Options_Change;
      Label_Options_Music:=MyControls.AddLabel(Panel_Options_Sound,18,77,100,30,fTextLibrary.GetTextString(196),fnt_Metal,kaLeft);
      Ratio_Options_Music:=MyControls.AddRatioRow(Panel_Options_Sound,10,97,150,20,aGameSettings.GetSlidersMin,aGameSettings.GetSlidersMax);
      Ratio_Options_Music.OnChange:=Options_Change;

      Label_Options_MusicOn:=MyControls.AddLabel(Panel_Options_Sound,18,140,100,20,fTextLibrary.GetTextString(197),fnt_Outline,kaLeft);
      Button_Options_MusicOn:=MyControls.AddButton(Panel_Options_Sound,10,160,150,30,'',fnt_Metal, bsMenu);
      Button_Options_MusicOn.OnClick:=Options_Change;

    Panel_Options_Lang:=MyControls.AddPanel(Panel_Options,320,130,170,30+LocalesCount*20);
      MyControls.AddLabel(Panel_Options_Lang,6,0,100,30,'Language:',fnt_Outline,kaLeft);
      MyControls.AddBevel(Panel_Options_Lang,0,20,170,10+LocalesCount*20);

      for i:=1 to LocalesCount do
      begin
        CheckBox_Options_Lang[i]:=MyControls.AddCheckBox(Panel_Options_Lang,18,27+(i-1)*20,100,30,Locales[i,2],fnt_Metal);
        CheckBox_Options_Lang[i].OnClick:=Options_Change;
      end;

    Panel_Options_Res:=MyControls.AddPanel(Panel_Options,320,300,170,30+RESOLUTION_COUNT*20);
      //Resolution selector
      MyControls.AddLabel(Panel_Options_Res,6,0,100,30,fTextLibrary.GetSetupString(20),fnt_Outline,kaLeft);
      MyControls.AddBevel(Panel_Options_Res,0,20,170,10+RESOLUTION_COUNT*20);
      for i:=1 to RESOLUTION_COUNT do
      begin
        CheckBox_Options_Resolution[i]:=MyControls.AddCheckBox(Panel_Options_Res,18,27+(i-1)*20,100,30,Format('%dx%d',[SupportedResolutions[i,1],SupportedResolutions[i,2],SupportedRefreshRates[i]]),fnt_Metal);
        CheckBox_Options_Resolution[i].Enabled:=(SupportedRefreshRates[i] > 0);
        CheckBox_Options_Resolution[i].OnClick:=Options_Change;
      end;

      CheckBox_Options_FullScreen:=MyControls.AddCheckBox(Panel_Options_Res,18,38+RESOLUTION_COUNT*20,100,30,'Fullscreen',fnt_Metal);
      CheckBox_Options_FullScreen.OnClick:=Options_Change;

      Button_Options_ResApply:=MyControls.AddButton(Panel_Options_Res,10,58+RESOLUTION_COUNT*20,150,30,'Apply',fnt_Metal, bsMenu);
      Button_Options_ResApply.OnClick:=Options_Change;
      Button_Options_ResApply.Disable;

    CheckBox_Options_Autosave.Checked := aGameSettings.IsAutosave;
    Ratio_Options_Brightness.Position := aGameSettings.GetBrightness;
    Ratio_Options_Mouse.Position      := aGameSettings.GetMouseSpeed;
    Ratio_Options_SFX.Position        := aGameSettings.GetSoundFXVolume;
    Ratio_Options_Music.Position      := aGameSettings.GetMusicVolume;

    if aGameSettings.IsMusic then Button_Options_MusicOn.Caption:=fTextLibrary.GetTextString(201)
                             else Button_Options_MusicOn.Caption:=fTextLibrary.GetTextString(199);

    Button_Options_Back:=MyControls.AddButton(Panel_Options,145,650,220,30,fTextLibrary.GetSetupString(9),fnt_Metal,bsMenu);
    Button_Options_Back.OnClick:=SwitchMenuPage;
end;


procedure TKMMainMenuInterface.Create_Credits_Page;
begin
  Panel_Credits:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_CreditsBG:=MyControls.AddImage(Panel_Credits,0,0,ScreenX,ScreenY,2,6);
    Image_CreditsBG.Stretch;
    Label_Credits:=MyControls.AddLabel(Panel_Credits,ScreenX div 2,ScreenY,100,30,fTextLibrary.GetSetupString(300),fnt_Grey,kaCenter);
    Button_CreditsBack:=MyControls.AddButton(Panel_Credits,100,640,224,30,fTextLibrary.GetSetupString(9),fnt_Metal,bsMenu);
    Button_CreditsBack.OnClick:=SwitchMenuPage;
end;


procedure TKMMainMenuInterface.Create_Loading_Page;
begin
  Panel_Loading:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_LoadingBG:=MyControls.AddImage(Panel_Loading,0,0,ScreenX,ScreenY,2,6);
    Image_LoadingBG.Stretch;
    MyControls.AddLabel(Panel_Loading,ScreenX div 2,ScreenY div 2 - 20,100,30,'Loading... Please wait',fnt_Outline,kaCenter);
    Label_Loading:=MyControls.AddLabel(Panel_Loading,ScreenX div 2,ScreenY div 2+10,100,30,'...',fnt_Grey,kaCenter);
end;


procedure TKMMainMenuInterface.Create_Error_Page;
begin
  Panel_Error := MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_ErrorBG := MyControls.AddImage(Panel_Error,0,0,ScreenX,ScreenY,2,6);
    Image_ErrorBG.Stretch;
    MyControls.AddLabel(Panel_Error,ScreenX div 2,ScreenY div 2 - 20,100,30,'An Error Has Occured!',fnt_Antiqua,kaCenter);
    Label_Error := MyControls.AddLabel(Panel_Error,ScreenX div 2,ScreenY div 2+10,100,30,'...',fnt_Grey,kaCenter);
    Button_ErrorBack := MyControls.AddButton(Panel_Error,100,640,224,30,fTextLibrary.GetSetupString(9),fnt_Metal,bsMenu);
    Button_ErrorBack.OnClick := SwitchMenuPage;
end;


procedure TKMMainMenuInterface.Create_Results_Page;
var i:integer; Adv:integer;
begin
  Panel_Results:=MyControls.AddPanel(Panel_Main1,0,0,ScreenX,ScreenY);
    Image_ResultsBG:=MyControls.AddImage(Panel_Results,0,0,ScreenX,ScreenY,7,5);
    Image_ResultsBG.Stretch;

    Label_Results_Result:=MyControls.AddLabel(Panel_Results,512,200,100,30,'<<<LEER>>>',fnt_Metal,kaCenter);

    Panel_Stats:=MyControls.AddPanel(Panel_Results,80,240,400,400);
    Adv:=0;
    for i:=1 to 9 do
    begin
      inc(Adv,25);
      if i in [3,6,7,9] then inc(Adv,15);
      MyControls.AddLabel(Panel_Stats,0,Adv,100,30,fTextLibrary.GetSetupString(112+i),fnt_Metal,kaLeft);
      Label_Stat[i]:=MyControls.AddLabel(Panel_Stats,340,Adv,100,30,'00',fnt_Metal,kaRight);
    end;

    Button_ResultsBack:=MyControls.AddButton(Panel_Results,100,640,200,30,fTextLibrary.GetSetupString(9),fnt_Metal,bsMenu);
    Button_ResultsBack.OnClick:=SwitchMenuPage;
    Button_ResultsRepeat:=MyControls.AddButton(Panel_Results,320,640,200,30,fTextLibrary.GetSetupString(18),fnt_Metal,bsMenu);
    Button_ResultsRepeat.OnClick:=MainMenu_ReplayLastMap;
    Button_ResultsContinue:=MyControls.AddButton(Panel_Results,540,640,200,30,fTextLibrary.GetSetupString(17),fnt_Metal,bsMenu);
    Button_ResultsContinue.OnClick:=SwitchMenuPage;
end;


procedure TKMMainMenuInterface.SwitchMenuPage(Sender: TObject);
var i:integer;
begin
  //First thing - hide all existing pages
  for i:=1 to Panel_Main1.ChildCount do
    if Panel_Main1.Childs[i] is TKMPanel then
      Panel_Main1.Childs[i].Hide;

  {Return to MainMenu if Sender unspecified}
  if Sender=nil then Panel_MainMenu.Show;

  {Return to MainMenu}
  if (Sender=Button_SinglePlayerBack)or
     (Sender=Button_CreditsBack)or
     (Sender=Button_MapEdBack)or
     (Sender=Button_ErrorBack)or
     (Sender=Button_ResultsBack) then
    Panel_MainMenu.Show;

  {Return to SinglePlayerMenu}
  if (Sender=Button_CampaignBack)or
     (Sender=Button_SingleBack)or
     (Sender=Button_LoadBack) then
    Panel_SinglePlayer.Show;

  {Return to MainMenu and restore resolution changes}
  if Sender=Button_Options_Back then begin
    fGame.fGlobalSettings.IsFullScreen := OldFullScreen;
    fGame.fGlobalSettings.SetResolutionID := OldResolution;
    Panel_MainMenu.Show;
  end;

  {Show SinglePlayer menu}
  if Sender=Button_MainMenuSinglePlayer then begin
    Panel_SinglePlayer.Show;
  end;

  {Show TSK campaign menu}
  if (Sender=Button_SinglePlayerTSK) or ((Sender=Button_ResultsContinue) and (fGame.GetCampaign=cmp_TSK)) then begin
    Campaign_Set(cmp_TSK);
    Panel_Campaign.Show;
  end;

  {Show TSK campaign menu}
  if (Sender=Button_SinglePlayerTPR) or ((Sender=Button_ResultsContinue) and (fGame.GetCampaign=cmp_TPR)) then begin
    Campaign_Set(cmp_TPR);
    Panel_Campaign.Show;
  end;

  {Show SingleMap menu}
  if Sender=Button_SinglePlayerSingle then begin
    SingleMap_PopulateList();
    SingleMap_RefreshList();
    Panel_Single.Show;
  end;

  {Show Load menu}
  if Sender=Button_SinglePlayerLoad then begin
    Load_PopulateList();
    Panel_Load.Show;
  end;

  {Show MapEditor menu}
  if Sender=Button_MainMenuMapEd then begin
    MapEditor_Change(nil);
    Panel_MapEd.Show;
  end;

  {Show Options menu}
  if Sender=Button_MainMenuOptions then begin
    OldFullScreen := fGame.fGlobalSettings.IsFullScreen;
    OldResolution := fGame.fGlobalSettings.GetResolutionID;
    Options_Change(nil);
    Panel_Options.Show;
  end;

  {Show Credits}
  if Sender=Button_MainMenuCredit then begin
    Panel_Credits.Show;
    Label_Credits.Top := ScreenY;
    Label_Credits.SmoothScrollToTop := TimeGetTime; //Set initial position
  end;

  {Show Loading... screen}
  if Sender=Panel_Loading then
    Panel_Loading.Show;

  {Show Error... screen}
  if Sender=Panel_Error then
    Panel_Error.Show;

  {Show Results screen}
  if Sender=Panel_Results then //This page can be accessed only by itself
    Panel_Results.Show;

  { Save settings when leaving options, if needed }
  if Sender=Button_Options_Back then
    if fGame.fGlobalSettings.GetNeedsSave then
      fGame.fGlobalSettings.SaveSettings;
end;


procedure TKMMainMenuInterface.MainMenu_PlayTutorial(Sender: TObject);
begin
  fGame.StartGame(ExeDir+'data\mission\mission0.dat', 'Town Tutorial');
end;


procedure TKMMainMenuInterface.MainMenu_PlayBattle(Sender: TObject);
begin
  fGame.StartGame(ExeDir+'data\mission\mission99.dat', 'Battle Tutorial');
end;


procedure TKMMainMenuInterface.MainMenu_ReplayLastMap(Sender: TObject);
begin
  fGame.StartGame('', ''); //Means replay last map
end;


procedure TKMMainMenuInterface.Campaign_Set(aCampaign:TCampaign);
var i,Top,Revealed:integer;
begin
  Campaign_Selected := aCampaign;
  Top := fGame.fCampaignSettings.GetMapsCount(Campaign_Selected);
  Revealed := fGame.fCampaignSettings.GetUnlockedMaps(Campaign_Selected);
  Label_CampaignText.Caption := fGame.fCampaignSettings.GetMapText(Campaign_Selected, Revealed);
  Label_CampaignStart.Tag := Revealed;

  for i:=1 to length(Campaign_Nodes) do begin
    Campaign_Nodes[i].Visible   := i <= Top;
    Campaign_Nodes[i].TexID     := 10 + byte(i<=Revealed);
    Campaign_Nodes[i].HighlightOnMouseOver := i <= Revealed;
  end;

  for i:=1 to Top do
  case Campaign_Selected of
    cmp_TSK:  begin
                Campaign_Nodes[i].Left := TSK_Campaign_Maps[i,1];
                Campaign_Nodes[i].Top  := TSK_Campaign_Maps[i,2];
              end;
    cmp_TPR:  begin
                Campaign_Nodes[i].Left := TPR_Campaign_Maps[i,1];
                Campaign_Nodes[i].Top  := TPR_Campaign_Maps[i,2];
              end;
  end;

  //todo: Place intermediate nodes

  //Select map to play
  Campaign_SelectMap(Campaign_Nodes[Revealed])
end;


procedure TKMMainMenuInterface.Campaign_SelectMap(Sender:TObject);
var i:integer;
begin
  if not (Sender is TKMImage) then exit;

   //Place highlight
  for i:=1 to length(Campaign_Nodes) do
    Campaign_Nodes[i].Highlight := false;
  TKMImage(Sender).Highlight := true;

  Label_CampaignText.Caption := fGame.fCampaignSettings.GetMapText(Campaign_Selected, TKMImage(Sender).Tag);
  Label_CampaignStart.Tag := TKMImage(Sender).Tag;
end;


procedure TKMMainMenuInterface.Campaign_StartMap(Sender: TObject);
begin
  fLog.AssertToLog(Sender=Label_CampaignStart,'not Label_CampaignStart');
  if Campaign_Selected = cmp_TSK then
    fGame.StartGame(
    ExeDir+'Data\mission\mission'+inttostr(Label_CampaignStart.Tag)+'.dat',
    'TSK mission '+inttostr(Label_CampaignStart.Tag), Campaign_Selected, Label_CampaignStart.Tag);
  if Campaign_Selected = cmp_TPR then
    fGame.StartGame(
    ExeDir+'Data\mission\dmission'+inttostr(Label_CampaignStart.Tag)+'.dat',
    'TPR mission '+inttostr(Label_CampaignStart.Tag), Campaign_Selected, Label_CampaignStart.Tag);
end;


procedure TKMMainMenuInterface.SingleMap_PopulateList();
begin
  SingleMapsInfo.ScanSingleMapsFolder();
end;


procedure TKMMainMenuInterface.SingleMap_RefreshList();
var i,ci:integer;
begin
  for i:=1 to MENU_SP_MAPS_COUNT do begin
    ci:=SingleMap_Top+i-1;
    if ci>SingleMapsInfo.GetMapCount then begin
      Button_SingleMode[i].TexID        := 0;
      Button_SinglePlayers[i].Caption   := '';
      Label_SingleTitle1[i].Caption     := '';
      Label_SingleTitle2[i].Caption     := '';
      Button_SingleSize[i].Caption      := '';
    end else begin
      Button_SingleMode[i].TexID        := 28+byte(not SingleMapsInfo.IsFight(ci))*14;  //28 or 42
      Button_SinglePlayers[i].Caption   := inttostr(SingleMapsInfo.GetPlayerCount(ci));
      Label_SingleTitle1[i].Caption     := SingleMapsInfo.GetFolder(ci);
      Label_SingleTitle2[i].Caption     := SingleMapsInfo.GetSmallDesc(ci);
      Button_SingleSize[i].Caption      := SingleMapsInfo.GetMapSize(ci);
    end;
  end;

  ScrollBar_SingleMaps.MinValue := 1;
  ScrollBar_SingleMaps.MaxValue := max(1, SingleMapsInfo.GetMapCount - MENU_SP_MAPS_COUNT + 1);
  ScrollBar_SingleMaps.Position := EnsureRange(ScrollBar_SingleMaps.Position,ScrollBar_SingleMaps.MinValue,ScrollBar_SingleMaps.MaxValue);

  SingleMap_SelectMap(Bevel_SingleBG[1,3]); //Select first map
end;


procedure TKMMainMenuInterface.SingleMap_ScrollChange(Sender: TObject);
begin
  SingleMap_Top := ScrollBar_SingleMaps.Position;
  SingleMap_RefreshList();
end;


procedure TKMMainMenuInterface.SingleMap_SelectMap(Sender: TObject);
var i:integer;
begin           
  i := TKMControl(Sender).Tag;

  Shape_SingleMap.Top := Bevel_SingleBG[i,3].Height * i; // All heights are equal in fact..

  SingleMap_Selected        := SingleMap_Top+i-1;
  Label_SingleTitle.Caption := SingleMapsInfo.GetFolder(SingleMap_Selected);
  Label_SingleDesc.Caption  := SingleMapsInfo.GetBigDesc(SingleMap_Selected);

  Label_SingleCondTyp.Caption := 'Mission type: '+SingleMapsInfo.GetTyp(SingleMap_Selected);
  Label_SingleCondWin.Caption := 'Win condition: '+SingleMapsInfo.GetWin(SingleMap_Selected);
  Label_SingleCondDef.Caption := 'Defeat condition: '+SingleMapsInfo.GetDefeat(SingleMap_Selected);
end;


procedure TKMMainMenuInterface.SingleMap_Start(Sender: TObject);
begin
  fLog.AssertToLog(Sender=Button_SingleStart,'not Button_SingleStart');
  if not InRange(SingleMap_Selected, 1, SingleMapsInfo.GetMapCount) then exit;
  fGame.StartGame(KMRemakeMapPath(SingleMapsInfo.GetFolder(SingleMap_Selected),'dat'),SingleMapsInfo.GetFolder(SingleMap_Selected)); //Provide mission filename mask and title here
end;


procedure TKMMainMenuInterface.Load_Click(Sender: TObject);
var LoadError: string;
begin
  LoadError := fGame.Load(TKMControl(Sender).Tag);
  if LoadError <> '' then ShowScreen_Error(LoadError); //This will show an option to return back to menu
end;


procedure TKMMainMenuInterface.Load_PopulateList();
var i:integer; SaveTitles: TStringList;
begin
  SaveTitles := TStringList.Create;
  try
    if FileExists(ExeDir+'Saves\savenames.dat') then
      SaveTitles.LoadFromFile(ExeDir+'Saves\savenames.dat');

    for i:=1 to SAVEGAME_COUNT do
      if i <= SaveTitles.Count then
        Button_Load[i].Caption := SaveTitles.Strings[i-1]
      else Button_Load[i].Caption := fTextLibrary.GetTextString(202);

    if fGame.fGlobalSettings.IsAutosave then
      Button_Load[AUTOSAVE_SLOT].Caption := fTextLibrary.GetTextString(203);
  finally
    FreeAndNil(SaveTitles);
  end;
end;


procedure TKMMainMenuInterface.MapEditor_Start(Sender: TObject);
begin
  fLog.AssertToLog(Sender = Button_MapEd_Start,'not Button_MapEd_Start');
  fGame.StartMapEditor('', MapEdSizeX, MapEdSizeY); //Provide mission filename here, Mapsize will be ignored if map exists
end;


procedure TKMMainMenuInterface.MapEditor_Change(Sender: TObject);
var i:integer;
begin
  //Find out new map dimensions
  for i:=1 to MAPSIZE_COUNT do
  begin
    if Sender = CheckBox_MapEd_SizeX[i] then MapEdSizeX := MapSize[i];
    if Sender = CheckBox_MapEd_SizeY[i] then MapEdSizeY := MapSize[i];
  end;
  //Put checkmarks
  for i:=1 to MAPSIZE_COUNT do
  begin
    CheckBox_MapEd_SizeX[i].Checked := MapEdSizeX = MapSize[i];
    CheckBox_MapEd_SizeY[i].Checked := MapEdSizeY = MapSize[i];
  end;
end;


procedure TKMMainMenuInterface.Options_Change(Sender: TObject);
var i:integer;
begin
  if Sender = CheckBox_Options_Autosave then fGame.fGlobalSettings.IsAutosave := not CheckBox_Options_Autosave.Checked;
  CheckBox_Options_Autosave.Checked := fGame.fGlobalSettings.IsAutosave;

  if Sender = Ratio_Options_Brightness then fGame.fGlobalSettings.SetBrightness(Ratio_Options_Brightness.Position);
  if Sender = Ratio_Options_Mouse then fGame.fGlobalSettings.SetMouseSpeed(Ratio_Options_Mouse.Position);
  if Sender = Ratio_Options_SFX   then fGame.fGlobalSettings.SetSoundFXVolume(Ratio_Options_SFX.Position);
  if Sender = Ratio_Options_Music then fGame.fGlobalSettings.SetMusicVolume(Ratio_Options_Music.Position);
  if Sender = Button_Options_MusicOn then fGame.fGlobalSettings.IsMusic := not fGame.fGlobalSettings.IsMusic;

  //This is called when the options page is shown, so update all the values
  CheckBox_Options_Autosave.Checked := fGame.fGlobalSettings.IsAutosave;
  Ratio_Options_Brightness.Position := fGame.fGlobalSettings.GetBrightness;
  Ratio_Options_Mouse.Position      := fGame.fGlobalSettings.GetMouseSpeed;
  Ratio_Options_SFX.Position        := fGame.fGlobalSettings.GetSoundFXVolume;
  Ratio_Options_Music.Position      := fGame.fGlobalSettings.GetMusicVolume;
  if fGame.fGlobalSettings.IsMusic then Button_Options_MusicOn.Caption:=fTextLibrary.GetTextString(201)
                                 else Button_Options_MusicOn.Caption:=fTextLibrary.GetTextString(199);

  for i:=1 to LocalesCount do
    if Sender = CheckBox_Options_Lang[i] then begin
      fGame.fGlobalSettings.SetLocale := Locales[i,1];
      ShowScreen_Loading('Loading new locale');
      fRender.Render; //Force to repaint loading screen
      fGame.ToggleLocale;
      exit; //Whole interface will be recreated
    end;

  for i:=1 to LocalesCount do
    CheckBox_Options_Lang[i].Checked := LowerCase(fGame.fGlobalSettings.GetLocale) = LowerCase(Locales[i,1]);

  //@Krom: Yes, I think it should be a proper control in a KaM style. Just text [x] doesn't look great.
  //       Some kind of box with an outline, darkened background and shadow maybe, similar to other controls.

  if Sender = Button_Options_ResApply then begin //Apply resolution changes
    OldFullScreen := fGame.fGlobalSettings.IsFullScreen; //memorize just in case (it will be niled on re-init anyway)
    OldResolution := fGame.fGlobalSettings.GetResolutionID;
    fGame.ToggleFullScreen(fGame.fGlobalSettings.IsFullScreen,true);
    exit;
  end;

  if Sender = CheckBox_Options_FullScreen then
    fGame.fGlobalSettings.IsFullScreen := not fGame.fGlobalSettings.IsFullScreen;

  for i:=1 to RESOLUTION_COUNT do
    if Sender = CheckBox_Options_Resolution[i] then
      fGame.fGlobalSettings.SetResolutionID := i;

  CheckBox_Options_FullScreen.Checked := fGame.fGlobalSettings.IsFullScreen;
  for i:=1 to RESOLUTION_COUNT do begin
    CheckBox_Options_Resolution[i].Checked := (i = fGame.fGlobalSettings.GetResolutionID);
    CheckBox_Options_Resolution[i].Enabled := (SupportedRefreshRates[i] > 0) AND fGame.fGlobalSettings.IsFullScreen;
  end;

  //Make button enabled only if new resolution/mode differs from old
  Button_Options_ResApply.Enabled := (OldFullScreen <> fGame.fGlobalSettings.IsFullScreen) or (OldResolution <> fGame.fGlobalSettings.GetResolutionID);

end;


{Should update anything we want to be updated, obviously}
procedure TKMMainMenuInterface.UpdateState;
begin
  //
end;


procedure TKMMainMenuInterface.Paint;
begin
  MyControls.Paint;
end;



end.
