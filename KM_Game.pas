unit KM_Game;
interface
uses Windows,
  {$IFDEF VER140} MPlayer, {$ENDIF}
  Forms, Controls, Classes, SysUtils, KromUtils, Math,
  KM_Defaults, KM_PlayersCollection, KM_Render, KM_LoadLib, KM_InterfaceMapEditor, KM_InterfaceGamePlay, KM_InterfaceMainMenu,
  KM_ResourceGFX, KM_Terrain, KM_LoadDAT, KM_SoundFX, KM_Viewport, KM_Units, KM_Settings, KM_Utils;

type TGameState = (gsNoGame, gsPaused, gsRunning, gsEditor);
type TLoadResult = (lrIncorrectGameState,lrSuccess,lrFileNotFound,lrParseError);

type
  TKMGame = class
  private
    FormControlsVisible, SelectingTroopDirection:boolean;
    SelectingDirPosition: TPoint;
    SelectedDirection: TKMDirection;
    GameplayTickCount:cardinal; //So that first tick will be #1
    ID_Tracker:cardinal;
  public
    ScreenX,ScreenY:word;
    GameSpeed:integer;
    GameState:TGameState;
    GameName:string;
    fGameSettings: TGameSettings;
    fMainMenuInterface: TKMMainMenuInterface;
    fGamePlayInterface: TKMGamePlayInterface;
    fMapEditorInterface: TKMapEdInterface;
  public
    constructor Create(ExeDir:string; RenderHandle:HWND; aScreenX,aScreenY:integer; NoMusic:boolean=false);
    destructor Destroy; override;
    procedure ToggleLocale();
    procedure ResizeGameArea(X,Y:integer);
    procedure ZoomInGameArea(X:single);
    procedure ToggleFullScreen(aToggle:boolean; ReturnToOptions:boolean);
    procedure KeyUp(Key: Word; Shift: TShiftState; IsDown:boolean=false);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  public
    procedure StartGame(MissionFile, aGameName:string; const aPlayerCount:integer=MAX_PLAYERS);
    procedure PauseGame(DoPause:boolean);
    procedure StopGame(const Msg:gr_Message; TextMsg:string=''; ShowResults:boolean=true);
    procedure StartMapEditor(MissionFile:string; aSizeX,aSizeY:integer);
    function GetMissionTime:cardinal;
    function CheckTime(aTimeTicks:cardinal):boolean;
    property GetTickCount:cardinal read GameplayTickCount;
    property GetGameName:string read GameName;
    function GetNewID():cardinal;
    function Save(SlotID:shortint):string;
    function Load(SlotID:shortint; out LoadError:string):TLoadResult;
    procedure UpdateState;
    procedure PaintInterface;
  end;

  var
    fGame:TKMGame;

implementation
uses
  KM_Unit1, KM_Controls, KM_Houses, KM_CommonTypes;


{ Creating everything needed for MainMenu, game stuff is created on StartGame }
constructor TKMGame.Create(ExeDir:string; RenderHandle:HWND; aScreenX,aScreenY:integer; NoMusic:boolean=false);
begin
  ID_Tracker := 0; //Init only once on Create
  SelectingTroopDirection := false;
  SelectingDirPosition := Point(0,0);
  ScreenX:=aScreenX;
  ScreenY:=aScreenY;
  fGameSettings         := TGameSettings.Create;
  fLog.AppendLog('<== Render init follows ==>');
  fRender:= TRender.Create(RenderHandle);
  fLog.AppendLog('<== TextLib init follows ==>');
  fTextLibrary:= TTextLibrary.Create(ExeDir+'data\misc\', fGameSettings.GetLocale);
  fLog.AppendLog('<== SoundLib init follows ==>');
  fSoundLib:= TSoundLib.Create(); //Needed for button click sounds and etc?
  fMusicLib:= TMusicLib.Create(); //Needed for button click sounds and etc?
  fGameSettings.UpdateSFXVolume;
  fLog.AppendLog('<== ReadGFX init follows ==>');
  fResource:=TResource.Create;
  fResource.LoadMenuResources(fGameSettings.GetLocale);
  fLog.AppendLog('<== Main menu interface follows ==>');
  fMainMenuInterface    := TKMMainMenuInterface.Create(ScreenX,ScreenY,fGameSettings);
  fLog.AppendLog('<== Sound playback follows ==>');

  if not NoMusic then fMusicLib.PlayMenuTrack(not fGameSettings.IsMusic);

  GameSpeed := 1;
  GameState := gsNoGame;
  FormControlsVisible:=true;
  fLog.AppendLog('<== Game creation is done ==>');
end;


{ Destroy what was created }
destructor TKMGame.Destroy;
begin
  //Stop music imediently, so it doesn't keep playing and jerk while things closes
  fMusicLib.StopMusic;

  FreeAndNil(fGameSettings);
  FreeAndNil(fMainMenuInterface);
  FreeAndNil(fResource);
  FreeAndNil(fSoundLib);
  FreeAndNil(fMusicLib);
  FreeAndNil(fTextLibrary);
  FreeAndNil(fRender);
  inherited;
end;


procedure TKMGame.ToggleLocale();
begin
  FreeAndNil(fMainMenuInterface);
  FreeAndNil(fTextLibrary);
  fTextLibrary := TTextLibrary.Create(ExeDir+'data\misc\', fGameSettings.GetLocale);
  fResource.LoadFonts(false, fGameSettings.GetLocale);
  fMainMenuInterface := TKMMainMenuInterface.Create(ScreenX, ScreenY, fGameSettings);
  fMainMenuInterface.ShowScreen_Options;
end;


procedure TKMGame.ResizeGameArea(X,Y:integer);
begin
  ScreenX:=X;
  ScreenY:=Y;
  fRender.RenderResize(X,Y,rm2D);
  if GameState in [gsPaused, gsRunning, gsEditor] then begin //If game is running
    fViewport.SetVisibleScreenArea(X,Y);
    if GameState in [gsPaused, gsRunning] then fGamePlayInterface.SetScreenSize(X,Y);
    if GameState in [gsEditor] then fMapEditorInterface.SetScreenSize(X,Y); 
    ZoomInGameArea(1);
  end else begin
    //Should resize all Controls somehow...
    //Remember last page and all relevant menu settings
    FreeAndNil(fMainMenuInterface);
    fMainMenuInterface:= TKMMainMenuInterface.Create(X,Y, fGameSettings);
    GameSpeed:=1;
    fMainMenuInterface.SetScreenSize(X,Y);
  end;
end;


procedure TKMGame.ZoomInGameArea(X:single);
begin
  if GameState in [gsRunning, gsEditor] then fViewport.SetZoom(X);
end;


procedure TKMGame.ToggleFullScreen(aToggle:boolean; ReturnToOptions:boolean);
begin
  Form1.ToggleFullScreen(aToggle, fGameSettings.GetResolutionID, ReturnToOptions);
end;


procedure TKMGame.KeyUp(Key: Word; Shift: TShiftState; IsDown:boolean=false);
begin
  //List of conflicting keys:
  //F12 Pauses Execution and switches to debug
  //F10 sets focus on MainMenu1
  //F9 is the default key in Fraps for video capture
  //others.. unknown
  if (GameState = gsPaused) and not (Key=ord('P')) then exit; //Ignore all keys if game is on 'Pause'
  if not IsDown then
  begin
    if Key=VK_F11 then begin
      Form1.ToggleControlsVisibility(FormControlsVisible);
      FormControlsVisible := not FormControlsVisible;
    end;
    if Key=VK_BACK then begin
      //Backspace resets the zoom and view, similar to other RTS games like Dawn of War.
      //This is useful because it is hard to find default zoom using the scroll wheel, and if not zoomed 100% things can be scaled oddly (like shadows)
      fViewport.SetZoom(1);
      Form1.TB_Angle.Position := 0;
      Form1.TB_Angle_Change(Form1.TB_Angle);
    end;
    if (Key = VK_F8) and (GameState = gsRunning) then begin
      GameSpeed:=fGameSettings.GetSpeedup+1-GameSpeed; //1 or 11
      if not (GameSpeed in [1,fGameSettings.GetSpeedup]) then GameSpeed:=1; //Reset just in case
      fGameplayInterface.ShowClock(GameSpeed = fGameSettings.GetSpeedup);
    end;
    if (Key=ord('P')) and (GameState in [gsPaused, gsRunning]) then begin
      if GameState = gsRunning then
        GameState := gsPaused
      else
        GameState := gsRunning;
      fGameplayInterface.ShowPause(GameState = gsPaused);
    end;
    if (Key=ord('W')) and (GameState = gsRunning) then begin
      fTerrain.RevealWholeMap(MyPlayer.PlayerID);
    end;
    {Thats my debug example}
    if (Key=ord('5')) and (GameState = gsRunning) then begin
      fGameplayInterface.IssueMessage(msgText,'123',KMPoint(0,0));
    end;
    if (Key=ord('6')) and (GameState = gsRunning) then begin
      fGameplayInterface.IssueMessage(msgHouse,'123',fViewport.GetCenter);
    end;
    if (Key=ord('7')) and (GameState = gsRunning) then begin
      fGameplayInterface.IssueMessage(msgUnit,'123',KMPoint(0,0));
    end;
    if (Key=ord('8')) and (GameState = gsRunning) then begin
      fGameplayInterface.IssueMessage(msgHorn,'123',KMPoint(0,0));
    end;
    if (Key=ord('9')) and (GameState = gsRunning) then begin
      fGameplayInterface.IssueMessage(msgQuill,'123',KMPoint(0,0));
    end;
    if (Key=ord('0')) and (GameState = gsRunning) then begin
      fGameplayInterface.IssueMessage(msgScroll,'123',KMPoint(0,0));
    end;
  end;

  //Also send shortcut to GamePlayInterface if it is there
  if (GameState = gsRunning) and (fGamePlayInterface <> nil) then
    fGamePlayInterface.ShortcutPress(Key,IsDown);

  //Scrolling
  if (GameState = gsRunning) and (Key=VK_LEFT)  then fViewport.ScrollKeyLeft  := IsDown;
  if (GameState = gsRunning) and (Key=VK_RIGHT) then fViewport.ScrollKeyRight := IsDown;
  if (GameState = gsRunning) and (Key=VK_UP)    then fViewport.ScrollKeyUp    := IsDown;
  if (GameState = gsRunning) and (Key=VK_DOWN)  then fViewport.ScrollKeyDown  := IsDown;
end;


procedure TKMGame.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var P: TKMPoint; MyRect: TRect; MOver:TKMControl;
begin
  case GameState of
    gsNoGame:   fMainMenuInterface.MyControls.OnMouseDown(X,Y,Button);
    gsPaused:   exit; //No clicking when paused
    gsRunning:  begin
                  fGameplayInterface.MyControls.OnMouseDown(X,Y,Button);
                  MOver := fGameplayInterface.MyControls.MouseOverControl;
                  if (Button = mbMiddle) and (fGameplayInterface.MyControls.MouseOverControl = nil) then
                    MyPlayer.AddUnit(ut_HorseScout, KMPoint(CursorXc,CursorYc)); //Add only when cursor is over the map

                  P := KMPoint(CursorXc,CursorYc); //Get cursor position tile-wise
                  //These are only for testing purposes, Later on it should be changed a lot
                  if (Button = mbRight)
                    and(MOver = nil)
                    and(fGamePlayInterface <> nil)
                    and(not fGamePlayInterface.JoiningGroups)
                    and(fGamePlayInterface.GetShownUnit is TKMUnitWarrior)
                    and(TKMUnit(fGamePlayInterface.GetShownUnit).GetOwner = MyPlayer.PlayerID)
                    and(fTerrain.Route_CanBeMade(TKMUnit(fGamePlayInterface.GetShownUnit).GetPosition, P, canWalk, true))
                    then
                  begin
                    SelectingTroopDirection := true; //MouseMove will take care of cursor changing
                    //Record current cursor position so we can stop it from moving while we are setting direction
                    GetCursorPos(SelectingDirPosition); //First record it in referance to the screen pos for the clipcursor function
                    //Restrict cursor to a rectangle (half a rect in both axes)
                    MyRect := Rect(SelectingDirPosition.X-((DirCursorSqrSize-1) div 2),
                                   SelectingDirPosition.Y-((DirCursorSqrSize-1) div 2),
                                   SelectingDirPosition.X+((DirCursorSqrSize-1) div 2)+1,
                                   SelectingDirPosition.Y+((DirCursorSqrSize-1) div 2)+1);
                    ClipCursor(@MyRect);
                    //Now record it as Client XY
                    SelectingDirPosition := Point(X,Y);
                    SelectedDirection := dir_NA;
                  end
                  else
                  begin
                    if SelectingTroopDirection then
                      Form1.ApplyCursorRestriction; //Reset the cursor restrictions from selecting direction
                    SelectingTroopDirection := false;
                    fGamePlayInterface.ShowDirectionCursor(false);
                  end;
                end;
    gsEditor:   fMapEditorInterface.MyControls.OnMouseDown(X,Y,Button);
  end;
  MouseMove(Shift,X,Y);
end;


procedure TKMGame.MouseMove(Shift: TShiftState; X,Y: Integer);
var P:TKMPoint; HitUnit: TKMUnit; HitHouse: TKMHouse; DeltaX,DeltaY:shortint;
begin
  if InRange(X,1,ScreenX-1) and InRange(Y,1,ScreenY-1) then else exit; //Exit if Cursor is outside of frame

  case GameState of
    gsNoGame:   fMainMenuInterface.MyControls.OnMouseOver(X,Y,Shift);
    gsPaused:   exit; //No clicking when paused
    gsRunning:  begin
                  if SelectingTroopDirection then
                  begin
                    DeltaX := SelectingDirPosition.X - X;
                    DeltaY := SelectingDirPosition.Y - Y;
                    //Compare cursor position and decide which direction it is
                    SelectedDirection := KMGetCursorDirection(DeltaX, DeltaY);
                    //Update the cursor based on this direction and negate the offset
                    fGamePlayInterface.ShowDirectionCursor(true,X+DeltaX,Y+DeltaY,SelectedDirection);
                    Screen.Cursor := c_Invisible;
                  end
                  else
                  begin
                  fGameplayInterface.MyControls.OnMouseOver(X,Y,Shift);
                  if fGameplayInterface.MyControls.MouseOverControl()<>nil then
                    Screen.Cursor := c_Default
                  else begin
                    fTerrain.ComputeCursorPosition(X,Y);
                    if CursorMode.Mode=cm_None then
                      if fGamePlayInterface.JoiningGroups and
                        (fGamePlayInterface.GetShownUnit is TKMUnitWarrior) then
                      begin
                        HitUnit  := MyPlayer.UnitsHitTest(CursorXc, CursorYc);
                        if (HitUnit <> nil) and (not TKMUnitWarrior(HitUnit).IsSameGroup(TKMUnitWarrior(fGamePlayInterface.GetShownUnit))) and
                           (UnitGroups[byte(HitUnit.GetUnitType)] = UnitGroups[byte(fGamePlayInterface.GetShownUnit.GetUnitType)]) then
                          Screen.Cursor := c_JoinYes
                        else
                          Screen.Cursor := c_JoinNo;
                      end
                      else
                        if (MyPlayer.HousesHitTest(CursorXc, CursorYc)<>nil)or
                           (MyPlayer.UnitsHitTest(CursorXc, CursorYc)<>nil) then
                          Screen.Cursor := c_Info
                        else
                        if fGamePlayInterface.GetShownUnit is TKMUnitWarrior then
                        begin
                          HitUnit  := fPlayers.UnitsHitTest (CursorXc, CursorYc);
                          HitHouse := fPlayers.HousesHitTest(CursorXc, CursorYc);
                          if (fTerrain.CheckTileRevelation(CursorXc, CursorYc, MyPlayer.PlayerID)>0) and
                             (((HitUnit<>nil) and (not (HitUnit is TKMUnitAnimal)) and (fPlayers.Player[byte(HitUnit.GetOwner)].fAlliances[byte(MyPlayer.PlayerID)] = at_Enemy))or
                              ((HitHouse<>nil) and (fPlayers.Player[byte(HitHouse.GetOwner)].fAlliances[byte(MyPlayer.PlayerID)] = at_Enemy))) then
                            Screen.Cursor := c_Attack
                          else if not Scrolling then
                            Screen.Cursor := c_Default;
                        end
                        else if not Scrolling then
                          Screen.Cursor := c_Default;
                    fTerrain.UpdateCursor(CursorMode.Mode, KMPoint(CursorXc,CursorYc));
                  end;
                  end;
                end;
    gsEditor:   begin
                  fMapEditorInterface.MyControls.OnMouseOver(X,Y,Shift);
                  if fMapEditorInterface.MyControls.MouseOverControl()<>nil then
                    Screen.Cursor:=c_Default
                  else
                  begin
                    fTerrain.ComputeCursorPosition(X,Y);
                    if CursorMode.Mode=cm_None then
                      if (MyPlayer.HousesHitTest(CursorXc, CursorYc)<>nil)or
                         (MyPlayer.UnitsHitTest(CursorXc, CursorYc)<>nil) then
                        Screen.Cursor:=c_Info
                      else if not Scrolling then
                        Screen.Cursor:=c_Default;
                    fTerrain.UpdateCursor(CursorMode.Mode,KMPoint(CursorXc,CursorYc));

                    if ssLeft in Shift then //Only allow placing of roads etc. with the left mouse button
                    begin
                      P := KMPoint(CursorXc,CursorYc); //Get cursor position tile-wise
                      case CursorMode.Mode of
                        cm_Road:  if fTerrain.CanPlaceRoad(P, mu_RoadPlan) then MyPlayer.AddRoad(P,false);
                        cm_Field: if fTerrain.CanPlaceRoad(P, mu_FieldPlan) then MyPlayer.AddField(P,ft_Corn);
                        cm_Wine:  if fTerrain.CanPlaceRoad(P, mu_WinePlan) then MyPlayer.AddField(P,ft_Wine);
                        //cm_Wall: if fTerrain.CanPlaceRoad(P, mu_WinePlan) then MyPlayer.AddField(P,ft_Wine);
                        cm_Erase: begin
                                    MyPlayer.RemHouse(P,false,false,true);
                                    fTerrain.RemRoad(P);
                                    fTerrain.RemField(P);
                                  end;
                      end;
                    end;
                  end;
                end;
  end;

Form1.StatusBar1.Panels.Items[1].Text:='Cursor: '+floattostr(round(CursorX*10)/10)+' '+floattostr(round(CursorY*10)/10)
+' | '+inttostr(CursorXc)+' '+inttostr(CursorYc);
end;


procedure TKMGame.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var P:TKMPoint; MOver:TKMControl; HitUnit: TKMUnit;
begin
  if SelectingTroopDirection then
  begin
    //Reset the cursor position as it will have moved during direction selection
    SetCursorPos(Form1.Panel5.ClientToScreen(SelectingDirPosition).X,Form1.Panel5.ClientToScreen(SelectingDirPosition).Y);
    Form1.ApplyCursorRestriction; //Reset the cursor restrictions from selecting direction
    SelectingTroopDirection := false; //As soon as mouse is released
    fGamePlayInterface.ShowDirectionCursor(false);
  end;

  case GameState of //Remember clicked control
    gsNoGame:   MOver := fMainMenuInterface.MyControls.MouseOverControl();
    gsPaused:   exit; //No clicking allowed when game is paused
    gsRunning:  MOver := fGameplayInterface.MyControls.MouseOverControl();
    gsEditor:   MOver := fMapEditorInterface.MyControls.MouseOverControl();
    else        MOver := nil; //MOver should always be initialized
  end;

  if (MOver <> nil) and (MOver is TKMButton) and MOver.Enabled and TKMButton(MOver).MakesSound then fSoundLib.Play(sfx_click);

  case GameState of
    gsNoGame:   fMainMenuInterface.MyControls.OnMouseUp(X,Y,Button);
    gsRunning:
      begin
        P := KMPoint(CursorXc,CursorYc); //Get cursor position tile-wise
        if MOver <> nil then
          fGameplayInterface.MyControls.OnMouseUp(X,Y,Button)
        else begin

          if Button = mbLeft then //Only allow placing of roads etc. with the left mouse button
          begin
            case CursorMode.Mode of
              cm_None:
                if not fGamePlayInterface.JoiningGroups then
                begin
                  fPlayers.HitTest(CursorXc, CursorYc);
                  if (fPlayers.Selected is TKMHouse) then
                    fGamePlayInterface.ShowHouseInfo(TKMHouse(fPlayers.Selected));
                  if (fPlayers.Selected is TKMUnit) then
                    fGamePlayInterface.ShowUnitInfo(TKMUnit(fPlayers.Selected));
                end;
              cm_Road:  if fTerrain.Land[P.Y,P.X].Markup = mu_RoadPlan then
                          MyPlayer.RemPlan(P)
                        else
                          MyPlayer.AddRoadPlan(P, mu_RoadPlan, false, MyPlayer.PlayerID);
              cm_Field: if fTerrain.Land[P.Y,P.X].Markup = mu_FieldPlan then
                          MyPlayer.RemPlan(P)
                        else
                          MyPlayer.AddRoadPlan(P, mu_FieldPlan, false, MyPlayer.PlayerID);
              cm_Wine:  if fTerrain.Land[P.Y,P.X].Markup = mu_WinePlan then
                          MyPlayer.RemPlan(P)
                        else
                          MyPlayer.AddRoadPlan(P, mu_WinePlan, false, MyPlayer.PlayerID);
              cm_Wall:  if fTerrain.Land[P.Y,P.X].Markup = mu_WallPlan then
                          MyPlayer.RemPlan(P)
                        else
                          MyPlayer.AddRoadPlan(P, mu_WallPlan, false, MyPlayer.PlayerID);
              cm_Houses: if MyPlayer.AddHousePlan(THouseType(CursorMode.Param),P,false,MyPlayer.PlayerID) then
                           fGamePlayInterface.Build_SelectRoad;
              cm_Erase:
                begin
                  fPlayers.Selected := MyPlayer.HousesHitTest(CursorXc, CursorYc); //Select the house irregardless of unit below/above
                  if MyPlayer.RemHouse(P,false,true) then //Ask wherever player wants to destroy own house
                  begin
                    //don't ask about houses that are not started, they are removed bellow
                    if TKMHouse(fPlayers.Selected).GetBuildingState <> hbs_Glyph then
                    begin
                      fGamePlayInterface.ShowHouseInfo(TKMHouse(fPlayers.Selected),true);
                      fSoundLib.Play(sfx_click);
                    end;
                  end;
                  if (not MyPlayer.RemPlan(P)) and (not MyPlayer.RemHouse(P,false,true)) then
                    fSoundLib.Play(sfx_CantPlace,P,false,4.0); //Otherwise there is nothing to erase
                  //Now remove houses that are not started
                  if MyPlayer.RemHouse(P,false,true) and (TKMHouse(fPlayers.Selected).GetBuildingState = hbs_Glyph) then
                  begin
                    MyPlayer.RemHouse(P,false);
                    fSoundLib.Play(sfx_click);
                  end;
                end;

            end; //case CursorMode.Mode of..
            if fGamePlayInterface.JoiningGroups and (fGamePlayInterface.GetShownUnit <> nil) and
              (fGamePlayInterface.GetShownUnit is TKMUnitWarrior) then
            begin
              HitUnit  := MyPlayer.UnitsHitTest(CursorXc, CursorYc);
              if (HitUnit <> nil) and (not TKMUnitWarrior(HitUnit).IsSameGroup(TKMUnitWarrior(fGamePlayInterface.GetShownUnit))) and
                 (UnitGroups[byte(HitUnit.GetUnitType)] = UnitGroups[byte(fGamePlayInterface.GetShownUnit.GetUnitType)]) then
              begin
                TKMUnitWarrior(fGamePlayInterface.GetShownUnit).LinkTo(TKMUnitWarrior(HitUnit));
                fGamePlayInterface.JoiningGroups := false;
                fGamePlayInterface.ShowUnitInfo(fGamePlayInterface.GetShownUnit); //Refresh unit display
                Screen.Cursor:=c_Default; //Reset cursor when mouse released
              end;
            end;
          end;
        end; //if MOver<>nil then else..

        //These are only for testing purposes, Later on it should be changed a lot
        if (Button = mbRight)
        and(MOver = nil)
        and(fGamePlayInterface <> nil)
        and(fGamePlayInterface.GetShownUnit <> nil)
        and(SelectingDirPosition.x <> 0)
        and(fGamePlayInterface.GetShownUnit is TKMUnitWarrior)
        and(TKMUnit(fGamePlayInterface.GetShownUnit).GetOwner = MyPlayer.PlayerID)
        and(not fGamePlayInterface.JoiningGroups)
        and(fTerrain.Route_CanBeMade(TKMUnit(fGamePlayInterface.GetShownUnit).GetPosition, P, canWalk, true))
        then
        begin
          Screen.Cursor:=c_Default; //Reset cursor when mouse released
          TKMUnitWarrior(fGamePlayInterface.GetShownUnit).GetCommander.PlaceOrder(wo_walk, P, SelectedDirection);
        end;
        if (Button = mbRight) and (MOver = nil) then
        begin
          fGameplayInterface.RightClickCancel; //Right clicking closes some menus
          Screen.Cursor:=c_Default; //Reset cursor as it might have been joining
        end;

      end; //gsRunning
    gsEditor: begin
                P := KMPoint(CursorXc,CursorYc); //Get cursor position tile-wise        
                if MOver <> nil then
                  fMapEditorInterface.MyControls.OnMouseUp(X,Y,Button)
                else
                if Button = mbRight then fMapEditorInterface.Build_RightClickCancel
                else
                if Button = mbLeft then //Only allow placing of roads etc. with the left mouse button
                  case CursorMode.Mode of
                    cm_None:
                      begin
                        fPlayers.HitTest(CursorXc, CursorYc);
                        if fPlayers.Selected is TKMHouse then
                          fGamePlayInterface.ShowHouseInfo(TKMHouse(fPlayers.Selected));
                        if fPlayers.Selected is TKMUnit then
                          fGamePlayInterface.ShowUnitInfo(TKMUnit(fPlayers.Selected));
                        //if (fPlayers.SelectedUnit is TKMUnitWarrior) and (not TKMUnitWarrior(fPlayers.SelectedUnit).fIsCommander) then
                        //  fPlayers.SelectedUnit:=TKMUnitWarrior(fPlayers.SelectedUnit).fCommanderID;
                      end;
                    cm_Road:  if fTerrain.CanPlaceRoad(P, mu_RoadPlan) then MyPlayer.AddRoad(P,false);
                    cm_Field: if fTerrain.CanPlaceRoad(P, mu_FieldPlan) then MyPlayer.AddField(P,ft_Corn);
                    cm_Wine:  if fTerrain.CanPlaceRoad(P, mu_WinePlan) then MyPlayer.AddField(P,ft_Wine);
                    //cm_Wall: if fTerrain.CanPlaceRoad(P, mu_WinePlan) then MyPlayer.AddField(P,ft_Wine);
                    cm_Houses:
                    if fTerrain.CanPlaceHouse(P, THouseType(CursorMode.Param)) then
                                MyPlayer.AddHouse(THouseType(CursorMode.Param),P);
                    cm_Units:
                                MyPlayer.AddUnit(TUnitType(CursorMode.Param),P);
              cm_Erase:
                begin
                  MyPlayer.RemHouse(P,false); { TODO : split apart according to opened page e.g. do not remove Houses if user is on Units page }
                  //MyPlayer.RemUnit(P); //@Lewin: Need your help here - how do we remove unit according to new pointer tracking system? Simply remove it from list or..
                                         //@Krom: Well this is different because it's the map editor. There shouldn't really be any pointers here right?
                                         //       According to the pointer system you should run KillUnit and somehow disable the dying animation. (so IsDead gets set to true, then the memory will be removed on next player UpdateState)
                                         //       But you probably could just remove it from the list because it's the map editor and there shouldn't be any pointer issues.
                  fTerrain.RemRoad(P);
                  fTerrain.RemField(P);
                end;


                  end;
              end;

  end;

end;


procedure TKMGame.StartGame(MissionFile, aGameName:string; const aPlayerCount:integer=MAX_PLAYERS);
var ResultMsg:string; fMissionParser: TMissionParser;
begin
  RandSeed := 4; //Sets right from the start since it affects TKMAllPlayers.Create and other Types
  GameSpeed := 1; //In case it was set in last run mission

  if fResource.GetDataState<>dls_All then begin
    fMainMenuInterface.ShowScreen_Loading('units and houses');
    fRender.Render;
    fResource.LoadGameResources();
    fMainMenuInterface.ShowScreen_Loading('tileset');
    fRender.Render;
    fRender.LoadTileSet();
  end;

  fMainMenuInterface.ShowScreen_Loading('initializing');
  fRender.Render;

  fViewport := TViewport.Create;
  fGamePlayInterface := TKMGamePlayInterface.Create;

  //Here comes terrain/mission init
  fTerrain := TTerrain.Create;

  fLog.AppendLog('Loading DAT...');
  if CheckFileExists(MissionFile,true) then
  begin
    //todo: Use exception trapping and raising system here similar to that used for load
    fMissionParser := TMissionParser.Create;
    ResultMsg := fMissionParser.LoadDATFile(MissionFile);
    FreeAndNil(fMissionParser);
    if ResultMsg<>'' then begin
      StopGame(gr_Error, ResultMsg);
      //Show all required error messages here
      exit;
    end;
    fLog.AppendLog('DAT Loaded');
  end
  else
  begin
    fTerrain.MakeNewMap(64, 64); //For debug we use blank mission
    fPlayers := TKMAllPlayers.Create(aPlayerCount);
    MyPlayer := fPlayers.Player[1];
  end;
  Form1.StatusBar1.Panels[0].Text:='Map size: '+inttostr(fTerrain.MapX)+' x '+inttostr(fTerrain.MapY);
  fGamePlayInterface.EnableOrDisableMenuIcons(not (fPlayers.fMissionMode = mm_Tactic));

  fLog.AppendLog('Gameplay initialized',true);

  fRender.RenderResize(ScreenX,ScreenY,rm2D);
  fViewport.SetVisibleScreenArea(ScreenX,ScreenY);
  fViewport.SetZoom(1);
  //fSoundLib.PlayNextTrack();  //Discussed. No need to feed new music track.

  GameplayTickCount:=0; //Restart counter

  GameName := aGameName;
  GameState := gsRunning;
end;


procedure TKMGame.PauseGame(DoPause:boolean);
begin
  GameSpeed:=1-byte(DoPause);
end;

                     
procedure TKMGame.StopGame(const Msg:gr_Message; TextMsg:string=''; ShowResults:boolean=true);
begin
  GameState := gsNoGame;

  //Fill results before data is flushed
  if Msg in [gr_Win, gr_Defeat, gr_Cancel] then
    fMainMenuInterface.Fill_Results;

  FreeAndNil(fPlayers);
  FreeAndNil(fTerrain);

  FreeAndNil(fGamePlayInterface);  //Free both interfaces
  FreeAndNil(fMapEditorInterface); //Free both interfaces
  FreeAndNil(fViewport);
  ID_Tracker := 0; //Reset ID tracker

  case Msg of
    gr_Win,gr_Defeat: begin
                        fLog.AppendLog('Gameplay ended',true);
                        fMainMenuInterface.ShowScreen_Results(Msg); //Mission results screen
                      end;
    gr_Cancel:        begin
                        fLog.AppendLog('Gameplay canceled',true);
                        fMainMenuInterface.ShowScreen_Results(Msg); //show the results so the user can see how they are going so far
                      end;
    gr_Error:         begin
                        fLog.AppendLog('Gameplay error',true);
                        fMainMenuInterface.ShowScreen_Error(TextMsg);
                      end;
    gr_Silent:        fLog.AppendLog('Gameplay stopped silently',true); //Used when loading new savegame from gameplay UI
    gr_MapEdEnd:      begin
                        fLog.AppendLog('MapEditor closed',true);
                        fMainMenuInterface.ShowScreen_Main;
                      end;
  end;
end;


procedure TKMGame.StartMapEditor(MissionFile:string; aSizeX,aSizeY:integer);
var ResultMsg:string; fMissionParser:TMissionParser;
begin
  RandSeed:=4; //Sets right from the start since it affects TKMAllPlayers.Create and other Types
  GameSpeed := 1; //In case it was set in last run mission

  if fResource.GetDataState<>dls_All then begin
    fMainMenuInterface.ShowScreen_Loading('units and houses');
    fRender.Render;
    fResource.LoadGameResources();
    fMainMenuInterface.ShowScreen_Loading('tileset');
    fRender.Render;
    fRender.LoadTileSet();
  end;

  fMainMenuInterface.ShowScreen_Loading('initializing');
  fRender.Render;

  fViewport:=TViewport.Create;
  fMapEditorInterface:= TKMapEdInterface.Create;

  //Here comes terrain/mission init
  fTerrain:= TTerrain.Create;

  fLog.AppendLog('Loading DAT...');
  if CheckFileExists(MissionFile,true) then begin
    fMissionParser:= TMissionParser.Create;
    ResultMsg := fMissionParser.LoadDATFile(MissionFile);
    if ResultMsg<>'' then begin
      StopGame(gr_Error,ResultMsg);
      //Show all required error messages here
      exit;
    end;
    FreeAndNil(fMissionParser);
    fLog.AppendLog('DAT Loaded');
  end else begin
    fTerrain.MakeNewMap(aSizeX,aSizeY);
    fPlayers := TKMAllPlayers.Create(MAX_PLAYERS); //Create MAX players
    MyPlayer := fPlayers.Player[1];
  end;
  fTerrain.RevealWholeMap(play_1); //@Lewin: Should be all players?
  Form1.StatusBar1.Panels[0].Text:='Map size: '+inttostr(fTerrain.MapX)+' x '+inttostr(fTerrain.MapY);

  fLog.AppendLog('Gameplay initialized',true);

  fRender.RenderResize(ScreenX,ScreenY,rm2D);
  fViewport.SetVisibleScreenArea(ScreenX,ScreenY);
  fViewport.SetZoom(1);

  GameplayTickCount:=0; //Restart counter

  GameState := gsEditor;
end;


function TKMGame.GetMissionTime:cardinal;
begin
  //Treat 10 ticks as 1 sec irregardless of user-set pace
  Result := MyPlayer.fMissionSettings.GetMissionTime + (GameplayTickCount div 10);
end;


//Tests whether time has past
function TKMGame.CheckTime(aTimeTicks:cardinal):boolean;
begin
  Result := (GameplayTickCount >= aTimeTicks);
end;


function TKMGame.GetNewID():cardinal;
begin
  inc(ID_Tracker);
  Result := ID_Tracker;
end;


//Saves the game and returns string for savegame name OR empty if save failed
function TKMGame.Save(SlotID:shortint):string;
  function GetSaveName(Num:integer):string;
  begin
    Result := 'Saves\'+'save'+int2fix(Num,2)+'.sav';
    if Num = 99 then Result := 'BugReport.sav'; //99 means this is a bug crash save
  end;
var
  SaveStream:TKMemoryStream;
  i:integer;
begin
  fLog.AppendLog('Saving game');
  case GameState of
    gsNoGame:   exit; //Don't need to save the game if we are in menu. Never call Save from menu anyhow
    gsEditor:   exit; {Don't Save MapEditor yet..}  { TODO : Add MapEditor Save function here}
    gsPaused,gsRunning: //Can't save from Paused state yet, but we could add it later
    begin
      SaveStream := TKMemoryStream.Create;
      SaveStream.Write('KaM_Savegame');
      SaveStream.Write(SAVE_VERSION); //This is savegame version
      SaveStream.Write(GameName); //Save game title
      SaveStream.Write(GameplayTickCount, 4); //dunno if it's required to save, but it won't hurt anyone
      SaveStream.Write(ID_Tracker, 4); //Units-Houses ID tracker

      fTerrain.Save(SaveStream); //Saves the map
      fPlayers.Save(SaveStream); //Saves all players properties individually
      fViewport.Save(SaveStream); //Saves viewed area settings
      //Don't include fGameSettings.Save it's not required for settings are Game-global, not mission
      fGamePlayInterface.Save(SaveStream); //Saves message queue and school/barracks selected units

      CreateDir(ExeDir+'Saves\'); //Makes the folder incase it was deleted

      if SlotID = AUTOSAVE_SLOT then begin //Backup earlier autosaves
        DeleteFile(ExeDir+GetSaveName(AUTOSAVE_SLOT+5));
        for i:=AUTOSAVE_SLOT+5 downto AUTOSAVE_SLOT+1 do //15 to 11
          RenameFile(ExeDir+GetSaveName(i-1), ExeDir+GetSaveName(i)); //We don't need Result here
      end;

      SaveStream.SaveToFile(ExeDir+GetSaveName(SlotID)); //Some 70ms for TPR7 map
      SaveStream.Free;
      Result := GameName + ' ' + int2time(GetMissionTime);
      if (fGameSettings.IsAutosave) and (SlotID = AUTOSAVE_SLOT) then
        Result := fTextLibrary.GetTextString(203); //Autosave
    end;
  end;
  fLog.AppendLog('Saving game',true);
end;


function TKMGame.Load(SlotID:shortint; out LoadError:string):TLoadResult;
var LoadStream:TKMemoryStream;
s,FileName:string;
begin
  fLog.AppendLog('Loading game');
  Result := lrIncorrectGameState; //Three exit cases bellow use this
  LoadError := '';
  FileName := 'Saves\'+'save'+int2fix(SlotID,2)+'.sav'; //Full path is EXEDir+FileName

  //Check if file exists early so that current game will not be lost if user tries to load an empty save
  if not FileExists(ExeDir+'Saves\'+'save'+int2fix(SlotID,2)+'.sav') then
  begin
    Result := lrFileNotFound;
    exit;
  end;

  if GameState in [gsRunning, gsPaused] then StopGame(gr_Silent);

  LoadStream := TKMemoryStream.Create; //Read data from file into stream
  try //Make sure LoadStream is always freed, even if other processes crash/exit
  case GameState of
    gsNoGame:   //Load only from menu or stopped game
    begin
      try //Catch exceptions
        LoadStream.LoadFromFile(ExeDir+FileName);
        LoadStream.Seek(0, soFromBeginning);

        //Raise some exceptions if the file is invalid or the wrong save version
        LoadStream.Read(s); if s <> 'KaM_Savegame' then Raise Exception.Create('Not a valid KaM Remake save file');
        LoadStream.Read(s); if s <> SAVE_VERSION then Raise Exception.CreateFmt('Incompatible save version ''%s''. This version is ''%s''',[s,SAVE_VERSION]);

        //Create empty environment
        StartGame('','',1);

        //Substitute tick counter and id tracker
        LoadStream.Read(GameName); //Save game title
        LoadStream.Read(GameplayTickCount, 4);
        LoadStream.Read(ID_Tracker, 4);

        //Load the data into the game
        fTerrain.Load(LoadStream);
        fPlayers.Load(LoadStream);
        fViewport.Load(LoadStream);
        fGamePlayInterface.Load(LoadStream);
        fGamePlayInterface.EnableOrDisableMenuIcons(not (fPlayers.fMissionMode = mm_Tactic)); //Preserve disabled icons

        fPlayers.SyncLoad(); //Should parse all Unit-House ID references and replace them with actual pointers
        Result := lrSuccess; //Loading has now completed successfully :)
      except
        on E : Exception do
        begin
          //Trap the exception and show the user. Note: While debugging, Delphi will still stop execution for the exception, but normally the dialouge won't show.
          Result := lrParseError;
          LoadError := 'An error was encountered while parsing the file '+FileName+'.|Details of the error:|'+
                        E.ClassName+' error raised with message: '+E.Message;
          if GameState in [gsRunning, gsPaused] then StopGame(gr_Silent); //Stop the game so that the main menu error can be shown
          exit;
        end;
      end;
    end;
    gsEditor:   exit; //Taken care of earlier with default lrIncorrectGameState
    gsPaused:   exit; //Taken care of earlier with default lrIncorrectGameState
    gsRunning:  exit; //Taken care of earlier with default lrIncorrectGameState
  end;
  finally
    LoadStream.Free;
  end;
  fLog.AppendLog('Loading game',true);
end;


procedure TKMGame.UpdateState;
var i:integer;
begin
  inc(GlobalTickCount);
  case GameState of
    gsPaused:   exit;
    gsNoGame:   begin
                  fMainMenuInterface.UpdateState;
                  if GlobalTickCount mod 10 = 0 then //Once a sec
                  if fMusicLib.IsMusicEnded then
                    fMusicLib.PlayMenuTrack(not fGameSettings.IsMusic); //Menu tune
                end;
    gsRunning:  begin
                  fViewport.DoScrolling; //Check to see if we need to scroll
                  for i:=1 to GameSpeed do begin
                    inc(GameplayTickCount); //Thats our tick counter for gameplay events
                    fTerrain.UpdateState;
                    fPlayers.UpdateState(GameplayTickCount); //Quite slow
                    if GameState = gsNoGame then exit; //Quit the update if game was stopped by MyPlayer defeat

                    if GameplayTickCount mod 600 = 0 then //Each 1min of gameplay time
                      if fGameSettings.IsAutosave then
                        Save(AUTOSAVE_SLOT); //Autosave slot
                  end;

                  fGamePlayInterface.UpdateState;

                  if GlobalTickCount mod 5 = 0 then //Every 500ms
                    fTerrain.RefreshMinimapData(); //Since this belongs to UI it should refresh at UI refresh rate, not Terrain refresh (which is affected by game speed-up)

                  if GlobalTickCount mod 10 = 0 then
                    if fMusicLib.IsMusicEnded then
                      fMusicLib.PlayNextTrack(); //Feed new music track
                end;
    gsEditor:   begin
                  fViewport.DoScrolling; //Check to see if we need to scroll
                  fMapEditorInterface.UpdateState;
                  fTerrain.IncAnimStep;
                  if GlobalTickCount mod 10 = 0 then //Every 500ms
                    fTerrain.RefreshMinimapData(); //Since this belongs to UI it should refresh at UI refresh rate, not Terrain refresh (which is affected by game speed-up)
                end;
    end;
end;


procedure TKMGame.PaintInterface;
begin
  case GameState of
    gsNoGame:  fMainMenuInterface.Paint;
    gsPaused:  fGameplayInterface.Paint;
    gsRunning: fGameplayInterface.Paint;
    gsEditor:  fMapEditorInterface.Paint;
  end;
end;


end.
