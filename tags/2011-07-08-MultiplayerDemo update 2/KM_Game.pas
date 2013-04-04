unit KM_Game;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, FileUtil, {$ENDIF}
  {$IFDEF WDC} MPlayer, {$ENDIF}
  Forms, Controls, Classes, Dialogs, SysUtils, KromUtils, Math, Zippit,
  KM_CommonTypes, KM_Defaults, KM_Utils,
  KM_Networking,
  KM_MapEditor,
  KM_GameInputProcess, KM_PlayersCollection, KM_Render, KM_TextLibrary, KM_InterfaceMapEditor, KM_InterfaceGamePlay, KM_InterfaceMainMenu,
  KM_ResourceGFX, KM_Terrain, KM_MissionScript, KM_Projectiles, KM_Sound, KM_Viewport, KM_Settings, KM_Music,
  KM_ArmyEvaluation;

type TGameState = ( gsNoGame,  //No game running at all, MainMenu
                    gsPaused,  //Game is paused and responds to 'P' key only
                    gsOnHold,  //Game is paused, shows victory options (resume, win) and responds to mouse clicks only
                    gsRunning, //Game is running normally
                    gsReplay,  //Game is showing replay, no player input allowed
                    gsEditor); //Game is in MapEditor mode

type
  TKMGame = class
  private //Irrelevant to savegame
    ScreenX,ScreenY:word;
    FormControlsVisible:boolean;
    fFormPassability:integer;
    fIsExiting: boolean; //Set this to true on Exit and unit/house pointers will be released without cross-checking
    fGlobalTickCount:cardinal; //Not affected by Pause and anything (Music, Minimap, StatusBar update)
    fGameSpeed:integer;
    fGameState:TGameState;
    fMultiplayerMode:boolean;
    fAdvanceFrame:boolean; //Replay variable to advance 1 frame, afterwards set to false
    fGlobalSettings: TGlobalSettings;
    fCampaignSettings: TCampaignSettings;
    fMusicLib: TMusicLib;
    fMapEditor: TKMMapEditor;
    fProjectiles:TKMProjectiles;
    fNetworking:TKMNetworking;
  //Should be saved
    fGameTickCount:cardinal;
    fGameName:string;
    fMissionFile:string; //Remember what we are playing incase we might want to replay
    fMissionMode: TKMissionMode;
    ID_Tracker:cardinal; //Mainly Units-Houses tracker, to issue unique numbers on demand
    fActiveCampaign:TCampaign; //Campaign we are playing
    fActiveCampaignMap:byte; //Map of campaign we are playing, could be different than MaxRevealedMap

    procedure GameInit(aMultiplayerMode:boolean);
  public
    PlayOnState:TGameResultMsg;
    DoGameHold:boolean; //Request to run GameHold after UpdateState has finished
    DoGameHoldState:TGameResultMsg; //The type of GameHold we want to occur due to DoGameHold
    SkipReplayEndCheck:boolean;
    fGameInputProcess:TGameInputProcess;
    fGamePlayInterface: TKMGamePlayInterface;
    fMainMenuInterface: TKMMainMenuInterface;
    fMapEditorInterface: TKMapEdInterface;
    constructor Create(ExeDir:string; RenderHandle:HWND; aScreenX,aScreenY:integer; aVSync:boolean; aLS:TNotifyEvent; aLT:TStringEvent; {$IFDEF WDC} aMediaPlayer:TMediaPlayer; {$ENDIF} NoMusic:boolean=false);
    destructor Destroy; override;
    procedure ToggleLocale(aLocale:shortstring);
    procedure ResizeGameArea(X,Y:integer);
    procedure ToggleFullScreen(aToggle:boolean; ReturnToOptions:boolean);
    procedure KeyDown(Key: Word; Shift: TShiftState);
    procedure KeyPress(Key: Char);
    procedure KeyUp(Key: Word; Shift: TShiftState);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; X,Y: Integer);

    procedure GameStart(aMissionFile, aGameName:string; aCamp:TCampaign=cmp_Nil; aCampMap:byte=1);
    procedure GameStartMP(Sender:TObject);
    procedure GameMPPlay(Sender:TObject);
    procedure GameError(aLoc:TKMPoint; aText:string); //Stop the game because of an error
    procedure SetGameState(aNewState:TGameState);
    procedure GameHold(DoHold:boolean; Msg:TGameResultMsg); //Hold the game to ask if player wants to play after Victory/Defeat/ReplayEnd
    procedure RequestGameHold(Msg:TGameResultMsg);
    procedure GameStop(const Msg:TGameResultMsg; TextMsg:string='');

    procedure MapEditorStart(const aMissionPath:string; aSizeX:integer=64; aSizeY:integer=64);
    procedure MapEditorSave(const aMissionName:string; DoExpandPath:boolean);

    function  ReplayExists:boolean;
    procedure ReplayView;

    procedure NetworkInit;

    function GetMissionTime:cardinal;
    function CheckTime(aTimeTicks:cardinal):boolean;
    property GameTickCount:cardinal read fGameTickCount;
    property GetMissionFile:string read fMissionFile;
    property GetGameName:string read fGameName;
    property GetCampaign:TCampaign read fActiveCampaign;
    property GetCampaignMap:byte read fActiveCampaignMap;
    property MultiplayerMode:boolean read fMultiplayerMode;
    property FormPassability:integer read fFormPassability write fFormPassability;
    property IsExiting:boolean read fIsExiting;
    property MissionMode:TKMissionMode read fMissionMode write fMissionMode;
    function GetNewID:cardinal;
    property GameState:TGameState read fGameState;
    procedure SetGameSpeed(aSpeed:byte=0);
    procedure StepOneFrame;

    property GlobalSettings: TGlobalSettings read fGlobalSettings;
    property CampaignSettings: TCampaignSettings read fCampaignSettings;
    property MapEditor: TKMMapEditor read fMapEditor;
    property MusicLib:TMusicLib read fMusicLib;
    property Projectiles:TKMProjectiles read fProjectiles;
    property Networking:TKMNetworking read fNetworking;

    procedure Save(SlotID:shortint);
    function Load(SlotID:shortint):string;
    function SavegameTitle(SlotID:shortint):string;

    procedure UpdateState;
    procedure UpdateStateIdle(aFrameTime:cardinal);
    procedure PaintInterface;
  end;

  var
    fGame:TKMGame;

implementation
uses
  KM_Unit1, KM_Player, KM_GameInputProcess_Single, KM_GameInputProcess_Multi;


{ Creating everything needed for MainMenu, game stuff is created on StartGame }
constructor TKMGame.Create(ExeDir:string; RenderHandle:HWND; aScreenX,aScreenY:integer; aVSync:boolean; aLS:TNotifyEvent; aLT:TStringEvent; {$IFDEF WDC} aMediaPlayer:TMediaPlayer; {$ENDIF} NoMusic:boolean=false);
begin
  Inherited Create;
  ScreenX := aScreenX;
  ScreenY := aScreenY;
  fAdvanceFrame := false;
  ID_Tracker    := 0;
  PlayOnState   := gr_Cancel;
  DoGameHold    := false;
  fGameSpeed    := 1;
  fGameState    := gsNoGame;
  SkipReplayEndCheck  := false;
  FormControlsVisible := false;

  fGlobalSettings   := TGlobalSettings.Create;
  fRender           := TRender.Create(RenderHandle, aVSync);
  fTextLibrary      := TTextLibrary.Create(ExeDir+'Data\misc\', fGlobalSettings.Locale);
  fSoundLib         := TSoundLib.Create(fGlobalSettings.Locale, fGlobalSettings.SoundFXVolume/fGlobalSettings.SlidersMax); //Required for button click sounds
  fMusicLib         := TMusicLib.Create({$IFDEF WDC} aMediaPlayer, {$ENDIF} fGlobalSettings.MusicVolume/fGlobalSettings.SlidersMax);
  fResource         := TResource.Create(fGlobalSettings.Locale, aLS, aLT);
  fMainMenuInterface:= TKMMainMenuInterface.Create(ScreenX,ScreenY,fGlobalSettings);
  fCampaignSettings := TCampaignSettings.Create;

  if not NoMusic then fMusicLib.PlayMenuTrack(not fGlobalSettings.MusicOn);

  fLog.AppendLog('<== Game creation is done ==>');
end;


{ Destroy what was created }
destructor TKMGame.Destroy;
begin
  fMusicLib.StopMusic; //Stop music imediently, so it doesn't keep playing and jerk while things closes

  FreeThenNil(fCampaignSettings);
  if fNetworking <> nil then FreeAndNil(fNetworking);
  FreeThenNil(fGlobalSettings);
  FreeThenNil(fMainMenuInterface);
  FreeThenNil(fResource);
  FreeThenNil(fSoundLib);
  FreeThenNil(fMusicLib);
  FreeThenNil(fTextLibrary);
  FreeThenNil(fRender);
  Inherited;
end;


procedure TKMGame.ToggleLocale(aLocale:shortstring);
begin
  fGlobalSettings.Locale := aLocale; //Wrong Locale will be ignored
  FreeAndNil(fMainMenuInterface);
  FreeAndNil(fTextLibrary);
  fTextLibrary := TTextLibrary.Create(ExeDir+'Data\misc\', fGlobalSettings.Locale);
  fResource.LoadFonts(false, fGlobalSettings.Locale);
  fMainMenuInterface := TKMMainMenuInterface.Create(ScreenX, ScreenY, fGlobalSettings);
  fMainMenuInterface.ShowScreen(msOptions);
end;


procedure TKMGame.ResizeGameArea(X,Y:integer);
begin
  ScreenX := X;
  ScreenY := Y;
  fRender.ResizeGameArea(X,Y,rm2D);

  //Main menu is invisible while in game, but it still exists and when we return to it
  //it must be properly sized (player could resize the screen while playing)
  if fMainMenuInterface<>nil then fMainMenuInterface.ResizeGameArea(X,Y);
  if fMapEditorInterface<>nil then fMapEditorInterface.ResizeGameArea(X,Y);
  if fGamePlayInterface<>nil then fGamePlayInterface.ResizeGameArea(X,Y);
end;


procedure TKMGame.ToggleFullScreen(aToggle:boolean; ReturnToOptions:boolean);
begin
  Form1.ToggleFullScreen(aToggle, fGlobalSettings.ResolutionID, fGlobalSettings.VSync, ReturnToOptions);
end;


procedure TKMGame.KeyDown(Key: Word; Shift: TShiftState);
begin
  case fGameState of
    gsNoGame:   fMainMenuInterface.KeyDown(Key, Shift);
    gsPaused:   fGamePlayInterface.KeyDown(Key, Shift);
    gsOnHold:   fGamePlayInterface.KeyDown(Key, Shift);
    gsRunning:  fGamePlayInterface.KeyDown(Key, Shift);
    gsReplay:   fGamePlayInterface.KeyDown(Key, Shift);
    gsEditor:   fMapEditorInterface.KeyDown(Key, Shift);
  end;
end;


procedure TKMGame.KeyPress(Key: Char);
begin
  case fGameState of
    gsNoGame:   fMainMenuInterface.KeyPress(Key);
    gsPaused:   fGamePlayInterface.KeyPress(Key);
    gsOnHold:   fGamePlayInterface.KeyPress(Key);
    gsRunning:  fGamePlayInterface.KeyPress(Key);
    gsReplay:   fGamePlayInterface.KeyPress(Key);
    gsEditor:   fMapEditorInterface.KeyPress(Key);
  end;
end;


procedure TKMGame.KeyUp(Key: Word; Shift: TShiftState);
begin
  //List of conflicting keys:
  //F12 Pauses Execution and switches to debug
  //F10 sets focus on MainMenu1
  //F9 is the default key in Fraps for video capture
  //F4 and F9 are used in debug to control run-flow
  //others.. unknown

  //GLOBAL KEYS
  if Key = VK_F5 then SHOW_CONTROLS_OVERLAY := not SHOW_CONTROLS_OVERLAY;
  if (Key = VK_F7) and ENABLE_DESIGN_CONTORLS then
    MODE_DESIGN_CONTORLS := not MODE_DESIGN_CONTORLS;
  if Key = VK_F11  then begin
    FormControlsVisible := not FormControlsVisible;
    Form1.ToggleControlsVisibility(FormControlsVisible);
  end;

  case fGameState of
    gsNoGame:   fMainMenuInterface.KeyUp(Key, Shift); //Exit if handled
    gsPaused:   fGamePlayInterface.KeyUp(Key, Shift);
    gsOnHold:   fGamePlayInterface.KeyUp(Key, Shift);
    gsRunning:  fGamePlayInterface.KeyUp(Key, Shift);
    gsReplay:   fGamePlayInterface.KeyUp(Key, Shift);
    gsEditor:   fMapEditorInterface.KeyUp(Key, Shift);
  end;
end;


procedure TKMGame.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  case fGameState of
    gsNoGame:   fMainMenuInterface.MouseDown(Button,Shift,X,Y);
    gsPaused:   fGamePlayInterface.MouseDown(Button,Shift,X,Y);
    gsOnHold:   fGamePlayInterface.MouseDown(Button,Shift,X,Y);
    gsReplay:   fGamePlayInterface.MouseDown(Button,Shift,X,Y);
    gsRunning:  fGamePlayInterface.MouseDown(Button,Shift,X,Y);
    gsEditor:   fMapEditorInterface.MouseDown(Button,Shift,X,Y);
  end;
end;


procedure TKMGame.MouseMove(Shift: TShiftState; X,Y: Integer);
begin
  if not InRange(X,1,ScreenX-1) or not InRange(Y,1,ScreenY-1) then exit; //Exit if Cursor is outside of frame

  case fGameState of
    gsNoGame:   fMainMenuInterface.MouseMove(Shift, X,Y);
    gsPaused:   fGamePlayInterface.MouseMove(Shift, X,Y);
    gsOnHold:   fGamePlayInterface.MouseMove(Shift, X,Y);
    gsRunning:  fGamePlayInterface.MouseMove(Shift, X,Y);
    gsReplay:   fGamePlayInterface.MouseMove(Shift, X,Y);
    gsEditor:   fMapEditorInterface.MouseMove(Shift,X,Y);
  end;

Form1.StatusBar1.Panels.Items[1].Text := Format('Cursor: %.1f:%.1f [%d:%d]', [
                                         GameCursor.Float.X, GameCursor.Float.Y,
                                         GameCursor.Cell.X, GameCursor.Cell.Y]);
end;


procedure TKMGame.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  case fGameState of
    gsNoGame:   fMainMenuInterface.MouseUp(Button, Shift, X,Y);
    gsPaused:   fGamePlayInterface.MouseUp(Button, Shift, X,Y);
    gsOnHold:   fGamePlayInterface.MouseUp(Button, Shift, X,Y);
    gsReplay:   fGamePlayInterface.MouseUp(Button, Shift, X,Y);
    gsRunning:  fGamePlayInterface.MouseUp(Button, Shift, X,Y);
    gsEditor:   fMapEditorInterface.MouseUp(Button, Shift, X,Y)
  end;
end;


procedure TKMGame.MouseWheel(Shift: TShiftState; WheelDelta: Integer; X, Y: Integer);
begin
  case fGameState of
    gsNoGame:   fMainMenuInterface.MouseWheel(Shift, WheelDelta, X, Y);
    gsPaused:   fGamePlayInterface.MouseWheel(Shift, WheelDelta, X, Y);
    gsOnHold:   fGamePlayInterface.MouseWheel(Shift, WheelDelta, X, Y);
    gsRunning:  fGamePlayInterface.MouseWheel(Shift, WheelDelta, X, Y);
    gsReplay:   fGamePlayInterface.MouseWheel(Shift, WheelDelta, X, Y);
    gsEditor:   fMapEditorInterface.MouseWheel(Shift, WheelDelta, X, Y);
  end;
end;


procedure TKMGame.GameInit(aMultiplayerMode:boolean);
begin
  fGameSpeed := 1; //In case it was set in last run mission
  PlayOnState := gr_Cancel;
  SkipReplayEndCheck := false; //Reset before each mission
  fMultiplayerMode := aMultiplayerMode;

  if fResource.DataState<>dls_All then begin
    fMainMenuInterface.ShowScreen(msLoading, 'trees, houses and units');
    fRender.Render;
    fResource.LoadGameResources;
    InitUnitStatEvals;
    fMainMenuInterface.ShowScreen(msLoading, 'tileset');
    fRender.Render;
    fRender.LoadTileSet;
  end;

  fMainMenuInterface.ShowScreen(msLoading, 'initializing');
  fRender.Render;

  fViewport := TViewport.Create;
  fGamePlayInterface := TKMGamePlayInterface.Create;

  //Here comes terrain/mission init
  RandSeed := 4; //Every time the game will be the same as previous. Good for debug.
  fTerrain := TTerrain.Create;
  fProjectiles := TKMProjectiles.Create;

  fRender.ResizeGameArea(ScreenX,ScreenY,rm2D);
  fViewport.ResizeGameArea(ScreenX,ScreenY);

  fGameTickCount := 0; //Restart counter
end;


procedure TKMGame.GameStart(aMissionFile, aGameName:string; aCamp:TCampaign=cmp_Nil; aCampMap:byte=1);
var LoadError:string; fMissionParser: TMissionParser;
begin
  fLog.AppendLog('GameStart');
  GameInit(false);

  //If input is empty - replay last map
  if aMissionFile <> '' then begin
    fMissionFile := aMissionFile;
    fGameName := aGameName;
    fActiveCampaign := aCamp;
    fActiveCampaignMap := aCampMap; //MapID is incremented in CampSettings and passed on to here from outside
  end;

  fLog.AppendLog('Loading DAT file: '+fMissionFile);
  if CheckFileExists(fMissionFile,true) then
  begin
    fMainMenuInterface.ShowScreen(msLoading, 'script');
    fRender.Render;

    try //Catch exceptions
      fMissionParser := TMissionParser.Create(mpm_Single);
      if fMissionParser.LoadMission(fMissionFile) then
        fLog.AppendLog('DAT Loaded')
      else
        Raise Exception.Create(fMissionParser.ErrorMessage);
      MyPlayer := fPlayers.Player[fMissionParser.MissionDetails.HumanPlayerID];
      Assert(MyPlayer.PlayerType = pt_Human);
      fMissionMode := fMissionParser.MissionDetails.MissionMode;
      FreeAndNil(fMissionParser);
    except
      on E : Exception do
      begin
        //Trap the exception and show the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
        LoadError := 'An error has occured while parsing the file '+fMissionFile+'||'+
                      E.ClassName+': '+E.Message;
        if fGameState in [gsRunning, gsPaused] then GameStop(gr_Silent); //Stop the game so that the main menu error can be shown
        fMainMenuInterface.ShowScreen(msError, LoadError);
        fLog.AppendLog('DAT Load Exception: '+LoadError);
        exit;
      end;
    end;
  end
  else
  begin
    fTerrain.MakeNewMap(64, 64); //For debug we use blank mission
    fPlayers := TKMPlayersCollection.Create;
    fPlayers.AddPlayers(MAX_PLAYERS);
    MyPlayer := fPlayers.Player[0];
  end;
  fPlayers.AfterMissionInit(true);

  fViewport.SetZoom(1); //This ensures the viewport is centered on the map

  Form1.StatusBar1.Panels[0].Text:='Map size: '+inttostr(fTerrain.MapX)+' x '+inttostr(fTerrain.MapY);
  fGamePlayInterface.MenuIconsEnabled(fMissionMode <> mm_Tactic);

  fLog.AppendLog('Gameplay initialized', true);

  fGameState := gsRunning;

  fGameInputProcess := TGameInputProcess_Single.Create(gipRecording);
  Save(99); //Thats our base for a game record

  {$IFDEF Unix} //In Linux CopyFile does not overwrite
  if FileExists(KMSlotToSaveName(99,'bas')) then DeleteFile(KMSlotToSaveName(99,'bas'));
  {$ENDIF}
  CopyFile(PChar(KMSlotToSaveName(99,'sav')), PChar(KMSlotToSaveName(99,'bas')), false);

  fLog.AppendLog('Gameplay recording initialized',true);
  RandSeed := 4; //Random after StartGame and ViewReplay should match
end;


//All setup data gets taken from fNetworking class
procedure TKMGame.GameStartMP(Sender:TObject);
var
  LoadError:string;
  i:integer;
  fMissionParser:TMissionParser;
  PlayerIndex:integer;
  PlayerUsed:array[0..MAX_PLAYERS-1]of boolean;
begin
  fLog.AppendLog('GameStart Multiplayer');
  fNetworking.LANGameState := lgs_Game; //The game has begun (no further players allowed to join)
  GameInit(true);

  fMissionFile := KMMapNameToPath(fNetworking.MapInfo.Folder, 'dat');
  fGameName := fNetworking.MapInfo.Folder + ' MP';

  fLog.AppendLog('Loading DAT file: '+fMissionFile);

  if CheckFileExists(fMissionFile) then
  begin
    fMainMenuInterface.ShowScreen(msLoading, 'script');
    fRender.Render;

    try //Catch exceptions
      fMissionParser := TMissionParser.Create(mpm_Multi);
      if fMissionParser.LoadMission(fMissionFile) then
        fLog.AppendLog('DAT Loaded')
      else
        Raise Exception.Create(fMissionParser.ErrorMessage);
      fMissionMode := fMissionParser.MissionDetails.MissionMode;
      FreeAndNil(fMissionParser);
    except
      on E : Exception do
      begin
        //Trap the exception and show the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
        LoadError := 'An error has occured while parsing the file '+fMissionFile+'||'+
                      E.ClassName+': '+E.Message;
        if fGameState in [gsRunning, gsPaused] then GameStop(gr_Silent); //Stop the game so that the main menu error can be shown
        fMainMenuInterface.ShowScreen(msError, LoadError);
        fLog.AppendLog('DAT Load Exception: '+LoadError);
        exit;
      end;
    end;
  end;
  fPlayers.AfterMissionInit(true);

  fMainMenuInterface.ShowScreen(msLoading, 'multiplayer init');
  fRender.Render;

  fMissionMode := fNetworking.MapInfo.MissionMode; //Tactic or normal

  //Initilise
  FillChar(PlayerUsed, SizeOf(PlayerUsed), #0);

  //Assign existing NetPlayers(1..N) to map players(0..N-1)
  for i:=1 to fNetworking.NetPlayers.Count do
  begin
    PlayerIndex := fNetworking.NetPlayers[i].StartLocation - 1; //PlayerID is 0 based
    fNetworking.NetPlayers[i].PlayerIndex := fPlayers.Player[PlayerIndex];
    fPlayers.Player[PlayerIndex].PlayerType := fNetworking.NetPlayers[i].PlayerType;
    fPlayers.Player[PlayerIndex].FlagColor := MP_TEAM_COLORS[fNetworking.NetPlayers[i].FlagColorID];
    PlayerUsed[PlayerIndex] := true;
  end;

  //MyPlayer is a pointer to TKMPlayer
  MyPlayer := fPlayers.Player[fNetworking.NetPlayers[fNetworking.MyIndex].StartLocation-1];

  //Clear remaining players
  for i:=fPlayers.Count-1 downto 0 do
    if not PlayerUsed[i] then
      fPlayers.RemovePlayer(i);

  fViewport.SetZoom(1); //This ensures the viewport is centered on the map

  Form1.StatusBar1.Panels[0].Text:='Map size: '+inttostr(fTerrain.MapX)+' x '+inttostr(fTerrain.MapY);
  fGamePlayInterface.MenuIconsEnabled(fMissionMode <> mm_Tactic);

  fLog.AppendLog('Gameplay initialized', true);

  fGameState := gsPaused;

  fGameInputProcess := TGameInputProcess_Multi.Create(gipRecording, fNetworking);
  Save(99); //Thats our base for a game record

  {$IFDEF Unix} //In Linux CopyFile does not overwrite
  if FileExists(KMSlotToSaveName(99,'bas')) then DeleteFile(KMSlotToSaveName(99,'bas'));
  {$ENDIF}
  CopyFile(PChar(KMSlotToSaveName(99,'sav')), PChar(KMSlotToSaveName(99,'bas')), false);

  fNetworking.OnPlay := GameMPPlay;
  fNetworking.OnCommands := TGameInputProcess_Multi(fGameInputProcess).RecieveCommands;
  fNetworking.GameCreated;

  fLog.AppendLog('Gameplay recording initialized',true);
  //@Krom: Thanks for that, you are right. Can we delete this line then? As I see it we should set the
  //random seed once in the init, then not change it. If the random seeds to not match at this point,
  //surely that means there is a flaw somewhere?
  //@Lewin: 1. We need Seed to be the same after GameStart and ReplayLoad, before starting main game
  //        loop. GameStart loads the mission and uses Random to e.g. set units health, while
  //        Replay does not sets anything it just loads savegame. Thats why we need to reset Seed
  //        AFTER everything is init here or replay is loaded.
  //        2. We don't want to remove Seed from GameInit and MapEdStart (where they are meaningless)
  //        because of the similar reason - to keep consistency in debug. We can start TownTutorial
  //        again and again and each time game will be created perfectly the same.
  //@Krom: Thanks, I understand now. To be deleted (or converted to a comment if you think it's necessary)
  RandSeed := 4; //Random after StartGameMP and ViewReplay should match
end;


//Everyone is ready to start playing
//Issued by fNetworking at the time depending on each Players lag individually
procedure TKMGame.GameMPPlay(Sender:TObject);
begin
  fGameState := gsRunning;
  fLog.AppendLog('Net game began');
end;


{ Set viewport and save command log }
procedure TKMGame.GameError(aLoc:TKMPoint; aText:string);
var
  PreviousState: TGameState;
  MyZip: TZippit;
  CrashFile: string;
begin
  //Negotiate duplicate calls for GameError
  if fGameState = gsNoGame then exit;

  PreviousState := GameState; //Could be running, replay, map editor, etc.
  SetGameState(gsPaused);
  if not KMSamePoint(aLoc, KMPoint(0,0)) then
  begin
    fViewport.SetCenter(aLoc.X, aLoc.Y);
    SHOW_UNIT_ROUTES := true;
    SHOW_UNIT_MOVEMENT := true;
  end;

  fLog.AppendLog('Gameplay Error: "'+aText+'" at location '+TypeToString(aLoc));

  if (fGameInputProcess <> nil) and (fGameInputProcess.ReplayState = gipRecording) then
    fGameInputProcess.SaveToFile(KMSlotToSaveName(99,'rpl')); //Save replay data ourselves

  MyZip := TZippit.Create;
  //Include in the bug report:
  MyZip.AddFiles(ExeDir+'Saves\save99.*','Replay'); //Replay files
  MyZip.AddFile(fLog.LogPath); //Log file
  MyZip.AddFile(ExeDir+'Saves\save15.sav','Autosaves'); //All autosaves
  MyZip.AddFile(ExeDir+'Saves\save14.sav','Autosaves');
  MyZip.AddFile(ExeDir+'Saves\save13.sav','Autosaves');
  MyZip.AddFile(ExeDir+'Saves\save12.sav','Autosaves');
  MyZip.AddFile(ExeDir+'Saves\save11.sav','Autosaves');
  MyZip.AddFile(ExeDir+'Saves\save10.sav','Autosaves');
  MyZip.AddFile(fMissionFile,'Mission');

  //Save it
  CrashFile := 'KaM Crash '+GAME_REVISION+' '+FormatDateTime('yyyy-mm-dd hh-nn-ss',Now)+'.zip'; //KaM Crash r1830 2007-12-23 15-24-33.zip
  CreateDir(ExeDir+'Crash Reports');
  MyZip.SaveToFile(ExeDir+'Crash Reports\'+CrashFile);
  FreeAndNil(MyZip); //Free the memory

  if MessageDlg(
    fTextLibrary.GetRemakeString(48)+eol+aText+eol+eol+Format(fTextLibrary.GetRemakeString(49),[CrashFile])
    , mtWarning, [mbYes, mbNo], 0) <> mrYes then

    GameStop(gr_Error, StringReplace(aText, eol, '|', [rfReplaceAll]) )
  else
    //If they choose to play on, start the game again because the player cannot tell that the game is paused
    SetGameState(PreviousState);
end;


procedure TKMGame.SetGameState(aNewState:TGameState);
begin
  fGameState := aNewState;
end;


//Put the game on Hold for Victory screen
procedure TKMGame.GameHold(DoHold:boolean; Msg:TGameResultMsg);
begin
  DoGameHold := false;
  fGamePlayInterface.ReleaseDirectionSelector; //In case of victory/defeat while moving troops
  PlayOnState := Msg;
  case Msg of
    gr_ReplayEnd:     begin
                        if DoHold then begin
                          SetGameState(gsOnHold);
                          fGamePlayInterface.ShowPlayMore(true, Msg);
                        end else
                          SetGameState(gsReplay);
                      end;
    gr_Win,gr_Defeat: begin
                        if DoHold then begin
                          SetGameState(gsOnHold);
                          fGamePlayInterface.ShowPlayMore(true, Msg);
                        end else
                          SetGameState(gsRunning);
                      end;
  end;
end;


procedure TKMGame.RequestGameHold(Msg:TGameResultMsg);
begin
  DoGameHold := true;
  DoGameHoldState := Msg;
end;


procedure TKMGame.GameStop(const Msg:TGameResultMsg; TextMsg:string='');
begin
  fIsExiting := true;
  try
    fGameState := gsNoGame;

    if MultiplayerMode then
      fNetworking.Disconnect;

    //Take results from MyPlayer before data is flushed
    if Msg in [gr_Win, gr_Defeat, gr_Cancel] then
      fMainMenuInterface.Fill_Results;

    if (fGameInputProcess <> nil) and (fGameInputProcess.ReplayState = gipRecording) then
      fGameInputProcess.SaveToFile(KMSlotToSaveName(99,'rpl'));

    FreeThenNil(fGameInputProcess);
    FreeThenNil(fPlayers);
    FreeThenNil(fProjectiles);
    FreeThenNil(fTerrain);
    FreeThenNil(fMapEditor);

    FreeThenNil(fGamePlayInterface);  //Free both interfaces
    FreeThenNil(fMapEditorInterface); //Free both interfaces
    FreeThenNil(fViewport);
    ID_Tracker := 0; //Reset ID tracker

    case Msg of
      gr_Win    :  begin
                     fLog.AppendLog('Gameplay ended - Win',true);
                     fMainMenuInterface.ShowScreen(msResults, '', Msg); //Mission results screen
                     fCampaignSettings.RevealMap(fActiveCampaign, fActiveCampaignMap+1);
                   end;
      gr_Defeat:   begin
                     fLog.AppendLog('Gameplay ended - Defeat',true);
                     fMainMenuInterface.ShowScreen(msResults, '', Msg); //Mission results screen
                   end;
      gr_Cancel:   begin
                     fLog.AppendLog('Gameplay canceled',true);
                     fMainMenuInterface.ShowScreen(msResults, '', Msg); //show the results so the user can see how they are going so far
                   end;
      gr_Error:    begin
                     fLog.AppendLog('Gameplay error',true);
                     fMainMenuInterface.ShowScreen(msError, TextMsg);
                   end;
      gr_Disconnect:begin
                     fLog.AppendLog('Network error',true);
                     fMainMenuInterface.ShowScreen(msError, TextMsg);
                   end;
      gr_Silent:   fLog.AppendLog('Gameplay stopped silently',true); //Used when loading new savegame from gameplay UI
      gr_ReplayEnd:begin
                     fLog.AppendLog('Replay canceled',true);
                     fMainMenuInterface.ShowScreen(msMain);
                   end;
      gr_MapEdEnd: begin
                     fLog.AppendLog('MapEditor closed',true);
                     fMainMenuInterface.ShowScreen(msMain);
                   end;
    end;
  finally
    fIsExiting := false;
  end;
end;


{Mission name accepted in 2 formats:
- absolute path, when opening a map from Form1.Menu
- relative, from Maps folder}
procedure TKMGame.MapEditorStart(const aMissionPath:string; aSizeX:integer=64; aSizeY:integer=64);
var fMissionParser:TMissionParser; i:integer;
begin
  if not FileExists(aMissionPath) and (aSizeX*aSizeY=0) then exit; //Erroneous call

  fLog.AppendLog('Starting Map Editor');
  GameStop(gr_Silent); //Stop MapEd if we are loading from existing MapEd session

  RandSeed := 4; //Every time MapEd will be the same as previous. Good for debug.
  fGameSpeed := 1; //In case it was set in last run mission

  if fResource.DataState<>dls_All then begin
    fMainMenuInterface.ShowScreen(msLoading, 'units and houses');
    fRender.Render;
    fResource.LoadGameResources;
    fMainMenuInterface.ShowScreen(msLoading, 'tileset');
    fRender.Render;
    fRender.LoadTileSet;
  end;

  fMainMenuInterface.ShowScreen(msLoading, 'initializing');
  fRender.Render;

  fViewport := TViewport.Create;
  fMapEditor := TKMMapEditor.Create;
  fMapEditorInterface := TKMapEdInterface.Create;

  //Here comes terrain/mission init
  fTerrain := TTerrain.Create;

  fLog.AppendLog('Loading DAT file: '+aMissionPath);
  if FileExists(aMissionPath) then
  begin
    fMissionParser := TMissionParser.Create(mpm_Editor);

    if fMissionParser.LoadMission(aMissionPath) then
      fLog.AppendLog('DAT Loaded')
    else
    begin
      //Show all required error messages here
      GameStop(gr_Error, fMissionParser.ErrorMessage);
      Exit;
    end;
    MyPlayer := fPlayers.Player[0];
    fPlayers.AddPlayers(MAX_PLAYERS-fPlayers.Count); //Activate all players
    FreeAndNil(fMissionParser);
    fLog.AppendLog('DAT Loaded');
    fGameName := TruncateExt(ExtractFileName(aMissionPath));
  end else begin
    fTerrain.MakeNewMap(aSizeX, aSizeY);
    fPlayers := TKMPlayersCollection.Create;
    fPlayers.AddPlayers(MAX_PLAYERS); //Create MAX players
    MyPlayer := fPlayers.Player[0];
    MyPlayer.PlayerType := pt_Human; //Make Player1 human by default
    fGameName := 'New Mission';
  end;

  fMapEditorInterface.Player_UpdateColors;
  fPlayers.AfterMissionInit(false);

  for i:=0 to fPlayers.Count-1 do //Reveal all players since we'll swap between them in MapEd
    fPlayers[i].FogOfWar.RevealEverything;

  Form1.StatusBar1.Panels[0].Text:='Map size: '+inttostr(fTerrain.MapX)+' x '+inttostr(fTerrain.MapY);

  fLog.AppendLog('Gameplay initialized',true);

  fRender.ResizeGameArea(ScreenX,ScreenY,rm2D);
  fViewport.ResizeGameArea(ScreenX,ScreenY);
  fViewport.SetZoom(1);

  fGameTickCount := 0; //Restart counter

  fGameState := gsEditor;
end;


//DoExpandPath means that input is a mission name which should be expanded into:
//ExeDir+'Maps\'+MissionName+'\'+MissionName.dat
//ExeDir+'Maps\'+MissionName+'\'+MissionName.map
procedure TKMGame.MapEditorSave(const aMissionName:string; DoExpandPath:boolean);
var fMissionParser: TMissionParser;
begin
  if aMissionName = '' then exit;
  if DoExpandPath then begin
    CreateDir(ExeDir+'Maps');
    CreateDir(ExeDir+'Maps\'+aMissionName);
    fTerrain.SaveToMapFile(KMMapNameToPath(aMissionName, 'map'));
    fMissionParser := TMissionParser.Create(mpm_Editor);
    fMissionParser.SaveDATFile(KMMapNameToPath(aMissionName, 'dat'));
    FreeAndNil(fMissionParser);
    fGameName := aMissionName;
  end else
    Assert(false,'SaveMapEditor call with DoExpandPath=false');
end;


{ Check if replay files exist at location }
function TKMGame.ReplayExists:boolean;
begin
  Result := FileExists(KMSlotToSaveName(99,'bas')) and
            FileExists(KMSlotToSaveName(99,'rpl'));
end;


procedure TKMGame.ReplayView;
begin
  CopyFile(PChar(KMSlotToSaveName(99,'bas')), PChar(KMSlotToSaveName(99,'sav')), false);
  Load(99); //We load what was saved right before starting Recording
  FreeAndNil(fGameInputProcess); //Override GIP from savegame

  fGameInputProcess := TGameInputProcess_Single.Create(gipReplaying);
  fGameInputProcess.LoadFromFile(KMSlotToSaveName(99,'rpl'));

  RandSeed := 4; //Random after StartGame and ViewReplay should match
  fGameState := gsReplay;
end;


procedure TKMGame.NetworkInit;
begin
  if fNetworking = nil then
    fNetworking := TKMNetworking.Create;
end;


//Treat 10 ticks as 1 sec irregardless of user-set pace
function TKMGame.GetMissionTime:cardinal;
begin
  Result := fGameTickCount div 10;
end;


//Tests whether time has past
function TKMGame.CheckTime(aTimeTicks:cardinal):boolean;
begin
  Result := (fGameTickCount >= aTimeTicks);
end;


function TKMGame.GetNewID:cardinal;
begin
  inc(ID_Tracker);
  Result := ID_Tracker;
end;


procedure TKMGame.SetGameSpeed(aSpeed:byte=0);
begin
  if aSpeed=0 then //Make sure it's either 1 or Max, not something inbetween
    if fGameSpeed = 1 then
      fGameSpeed := fGlobalSettings.Speedup
    else
      fGameSpeed := 1
  else
    fGameSpeed := aSpeed;

  fGamePlayInterface.ShowClock(fGameSpeed <> 1);
end;


procedure TKMGame.StepOneFrame;
begin
  Assert(fGameState in [gsPaused,gsReplay], 'We can work step-by-step only in Replay');
  SetGameSpeed(1); //Do not allow multiple updates in fGame.UpdateState loop
  fAdvanceFrame := true;
end;


//Saves the game in all its glory
//Base savegame gets copied from save99.bas
//Saves command log to RPL file
procedure TKMGame.Save(SlotID:shortint);
var
  SaveStream:TKMemoryStream;
  i:integer;
begin
  fLog.AppendLog('Saving game');
  if not (fGameState in [gsPaused, gsRunning]) then begin
    Assert(false, 'Saving from wrong state?');
    exit;
  end;

  SaveStream := TKMemoryStream.Create;
  SaveStream.Write('KaM_Savegame');
  SaveStream.Write(GAME_REVISION); //This is savegame version
  SaveStream.Write(fMissionFile); //Save game mission file
  SaveStream.Write(fGameName); //Save game title
  SaveStream.Write(fGameTickCount); //Required to be saved, e.g. messages being shown after a time
  SaveStream.Write(fMissionMode, SizeOf(fMissionMode));
  SaveStream.Write(ID_Tracker); //Units-Houses ID tracker
  SaveStream.Write(PlayOnState, SizeOf(PlayOnState));
  SaveStream.Write(RandSeed); //Include the random seed in the save file to ensure consistency in replays

  fTerrain.Save(SaveStream); //Saves the map
  fPlayers.Save(SaveStream); //Saves all players properties individually
  fProjectiles.Save(SaveStream);

  fViewport.Save(SaveStream); //Saves viewed area settings
  //Don't include fGameSettings.Save it's not required for settings are Game-global, not mission
  fGamePlayInterface.Save(SaveStream); //Saves message queue and school/barracks selected units

  CreateDir(ExeDir+'Saves\'); //Makes the folder incase it was deleted

  if SlotID = AUTOSAVE_SLOT then begin //Backup earlier autosaves
    DeleteFile(KMSlotToSaveName(AUTOSAVE_SLOT+AUTOSAVE_COUNT,'sav'));
    for i:=AUTOSAVE_SLOT+AUTOSAVE_COUNT downto AUTOSAVE_SLOT+1 do //13 to 11
      RenameFile(KMSlotToSaveName(i-1,'sav'), KMSlotToSaveName(i,'sav'));
  end;

  SaveStream.SaveToFile(KMSlotToSaveName(SlotID,'sav')); //Some 70ms for TPR7 map
  SaveStream.Free;

  fLog.AppendLog('Sav done');

  if SlotID <> AUTOSAVE_SLOT then begin //Backup earlier autosaves
    CopyFile(PChar(KMSlotToSaveName(99,'bas')), PChar(KMSlotToSaveName(SlotID,'bas')), false); //replace Replay base savegame
    fGameInputProcess.SaveToFile(KMSlotToSaveName(SlotID,'rpl')); //Adds command queue to savegame
  end;//

  fLog.AppendLog('Saving game', true);
end;


function TKMGame.SavegameTitle(SlotID:shortint):string;
var
  FileName,s,ver:string;
  LoadStream:TKMemoryStream;
  i:cardinal;
begin
  Result := '';
  FileName := KMSlotToSaveName(SlotID,'sav'); //Full path
  if not FileExists(FileName) then begin
    Result := fTextLibrary.GetTextString(202); //Empty
    exit;
  end;

  LoadStream := TKMemoryStream.Create; //Read data from file into stream
  LoadStream.LoadFromFile(FileName);

  LoadStream.Read(s);
  if s = 'KaM_Savegame' then begin
    LoadStream.Read(ver);
    if ver = GAME_REVISION then begin
      LoadStream.Read(s); //Savegame mission file
      LoadStream.Read(s); //GameName
      LoadStream.Read(i);
      Result := s + ' ' + int2time(i div 10);
      if SlotID = AUTOSAVE_SLOT then Result := fTextLibrary.GetTextString(203) + ' ' + Result;
    end else
      Result := 'Unsupported save ' + ver;
  end else
    Result := 'Unsupported format';
  LoadStream.Free;
end;


function TKMGame.Load(SlotID:shortint):string;
var
  LoadStream:TKMemoryStream;
  s,FileName:string;
  LoadedSeed:Longint;
begin
  fLog.AppendLog('Loading game');
  Result := '';
  FileName := KMSlotToSaveName(SlotID,'sav'); //Full path

  //Check if file exists early so that current game will not be lost if user tries to load an empty save
  if not FileExists(FileName) then
  begin
    Result := 'Savegame file not found';
    exit;
  end;

  if fGameState in [gsRunning, gsPaused] then GameStop(gr_Silent);

  //Load only from menu or stopped game
  if not (fGameState in [gsNoGame]) then begin
    Assert(false, 'Loading from wrong state?');
    exit;
  end;

  LoadStream := TKMemoryStream.Create; //Read data from file into stream
  try //Catch exceptions
    LoadStream.LoadFromFile(FileName);

    //Raise some exceptions if the file is invalid or the wrong save version
    LoadStream.Read(s); if s <> 'KaM_Savegame' then Raise Exception.Create('Not a valid KaM Remake save file');
    LoadStream.Read(s); if s <> GAME_REVISION then Raise Exception.CreateFmt('Incompatible save version ''%s''. This version is ''%s''',[s, GAME_REVISION]);

    //Create empty environment
    GameInit(false);

    //Substitute tick counter and id tracker
    LoadStream.Read(fMissionFile); //Savegame mission file
    LoadStream.Read(fGameName); //Savegame title
    LoadStream.Read(fGameTickCount);
    LoadStream.Read(fMissionMode, SizeOf(fMissionMode));
    LoadStream.Read(ID_Tracker);
    LoadStream.Read(PlayOnState, SizeOf(PlayOnState));
    LoadStream.Read(LoadedSeed);

    fPlayers := TKMPlayersCollection.Create;

    //Load the data into the game
    fTerrain.Load(LoadStream);
    fPlayers.Load(LoadStream);
    fProjectiles.Load(LoadStream);

    fViewport.Load(LoadStream);
    fGamePlayInterface.Load(LoadStream);

    LoadStream.Free;

    fGameInputProcess := TGameInputProcess_Single.Create(gipRecording);
    fGameInputProcess.LoadFromFile(KMSlotToSaveName(SlotID,'rpl'));

    CopyFile(PChar(KMSlotToSaveName(SlotID,'bas')), PChar(KMSlotToSaveName(99,'bas')), false); //replace Replay base savegame

    fGamePlayInterface.MenuIconsEnabled(fMissionMode <> mm_Tactic); //Preserve disabled icons
    fPlayers.SyncLoad; //Should parse all Unit-House ID references and replace them with actual pointers
    fTerrain.SyncLoad; //IsUnit values should be replaced with actual pointers
    fViewport.SetZoom(1); //This ensures the viewport is centered on the map (game could have been saved with a different resolution/zoom)
    Result := ''; //Loading has now completed successfully :)
    Form1.StatusBar1.Panels[0].Text:='Map size: '+inttostr(fTerrain.MapX)+' x '+inttostr(fTerrain.MapY);
  except
    on E : Exception do
    begin
      //Trap the exception and show the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
      Result := 'An error was encountered while parsing the file '+FileName+'.|Details of the error:|'+
                    E.ClassName+' error raised with message: '+E.Message;
      if fGameState in [gsRunning, gsPaused] then GameStop(gr_Silent); //Stop the game so that the main menu error can be shown
      exit;
    end;
  end;

  RandSeed := LoadedSeed;
  fGameState := gsRunning;
  fLog.AppendLog('Loading game',true);
end;


procedure TKMGame.UpdateState;
var i:integer;
begin
  inc(fGlobalTickCount);
  case fGameState of
    gsPaused:   exit;
    gsOnHold:   exit;
    gsNoGame:   begin
                  if fNetworking <> nil then fNetworking.UpdateState(fGlobalTickCount); //Measures pings
                  fMainMenuInterface.UpdateState;
                end;
    gsRunning:  begin
                  if fMultiplayerMode then  fNetworking.UpdateState(fGlobalTickCount); //Measures pings
                  try //Catch exceptions during update state

                    for i:=1 to fGameSpeed do
                    begin
                      if fGameInputProcess.CommandsConfirmed(fGameTickCount+1) then
                      begin
                        inc(fGameTickCount); //Thats our tick counter for gameplay events
                        fTerrain.UpdateState;
                        fPlayers.UpdateState(fGameTickCount); //Quite slow
                        if fGameState = gsNoGame then exit; //Quit the update if game was stopped by MyPlayer defeat
                        fProjectiles.UpdateState; //If game has stopped it's NIL

                        fGameInputProcess.RunningTimer(fGameTickCount); //GIP_Multi issues all commands for this tick
                        //In aggressive mode store a command every tick so we can find exactly when a replay mismatch occurs
                        if AGGRESSIVE_REPLAYS then
                          fGameInputProcess.CmdTemp(gic_TempDoNothing);

                        if (fGameTickCount mod 600 = 0) and fGlobalSettings.Autosave
                          and not (GameState = gsOnHold) then //Don't autosave if the game was put on hold during this tick
                          Save(AUTOSAVE_SLOT); //Each 1min of gameplay time
                        //During this tick we were requested to GameHold
                        if DoGameHold then break; //Break the for loop (if we are using speed up)
                      end;
                      fGameInputProcess.UpdateState(fGameTickCount); //Do maintenance
                    end;
                    fGamePlayInterface.UpdateState;

                  except
                    //Trap the exception and show the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
                    on E : ELocError do GameError(E.Loc, E.ClassName+': '+E.Message);
                    on E : Exception do GameError(KMPoint(0,0), E.ClassName+': '+E.Message);
                  end;
                end;
    gsReplay:   begin
                  try //Catch exceptions during update state

                    for i:=1 to fGameSpeed do
                    begin
                      inc(fGameTickCount); //Thats our tick counter for gameplay events
                      fTerrain.UpdateState;
                      fPlayers.UpdateState(fGameTickCount); //Quite slow
                      if fGameState = gsNoGame then exit; //Quit the update if game was stopped by MyPlayer defeat
                      fProjectiles.UpdateState; //If game has stopped it's NIL

                      //Issue stored commands
                      fGameInputProcess.ReplayTimer(fGameTickCount);
                      if fGameState = gsNoGame then exit; //Quit if the game was stopped by a replay mismatch
                      if not SkipReplayEndCheck and fGameInputProcess.ReplayEnded then
                        RequestGameHold(gr_ReplayEnd);

                      if fAdvanceFrame then begin
                        fAdvanceFrame := false;
                        SetGameState(gsPaused);
                      end;

                      //During this tick we were requested to GameHold
                      if DoGameHold then break; //Break the for loop (if we are using speed up)
                    end;

                    fGamePlayInterface.UpdateState;

                  except
                    //Trap the exception and show the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
                    on E : ELocError do GameError(E.Loc, E.ClassName+': '+E.Message);
                    on E : Exception do GameError(KMPoint(0,0), E.ClassName+': '+E.Message);
                  end;
                end;
    gsEditor:   begin
                  fMapEditorInterface.UpdateState;
                  fTerrain.IncAnimStep;
                  fPlayers.IncAnimStep;
                end;
    end;

  //Every 1000ms
  if fGlobalTickCount mod 10 = 0 then
  begin
    //Minimap
    if (fGameState in [gsRunning, gsReplay, gsEditor]) then
      fTerrain.RefreshMinimapData;

    //Music
    if fMusicLib.IsMusicEnded then
      case fGameState of
        gsRunning, gsReplay: fMusicLib.PlayNextTrack; //Feed new music track
        gsNoGame:            fMusicLib.PlayMenuTrack(not fGlobalSettings.MusicOn); //Menu tune
      end;

    //StatusBar  
    if (fGameState in [gsRunning, gsReplay]) then
      Form1.StatusBar1.Panels[2].Text := 'Time: '+int2time(GetMissionTime);
  end;
  if DoGameHold then GameHold(true,DoGameHoldState);
end;


{This is our real-time thread, use it wisely}
procedure TKMGame.UpdateStateIdle(aFrameTime:cardinal);
begin
  case fGameState of
    gsRunning,
    gsReplay:   fViewport.DoScrolling(aFrameTime); //Check to see if we need to scroll
    gsEditor:   begin
                  fViewport.DoScrolling(aFrameTime); //Check to see if we need to scroll
                  fTerrain.UpdateStateIdle;
                end;
  end;
end;


procedure TKMGame.PaintInterface;
begin
  case fGameState of
    gsNoGame:  fMainMenuInterface.Paint;
    gsPaused:  fGamePlayInterface.Paint;
    gsOnHold:  fGamePlayInterface.Paint;
    gsRunning: fGamePlayInterface.Paint;
    gsReplay:  fGamePlayInterface.Paint;
    gsEditor:  fMapEditorInterface.Paint;
  end;
end;


end.