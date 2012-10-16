unit KM_MissionScript;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  Classes, KromUtils, SysUtils, Dialogs, Math,
  KM_Utils, KM_CommonClasses, KM_Defaults, KM_Points,
  KM_AIAttacks, KM_Houses, KM_Units, KM_Terrain, KM_Units_Warrior;


type
  TMissionParsingMode = (
                          mpm_Single,
                          mpm_Multi,  //Skip players
                          mpm_Editor, //Ignore errors, load armies differently
                          mpm_Preview //Skip as much as we can
                        );

  TKMCommandType = (ct_Unknown=0,ct_SetMap,ct_SetMaxPlayer,ct_SetCurrPlayer,ct_SetHumanPlayer,ct_SetHouse,
                    ct_SetTactic,ct_AIPlayer,ct_EnablePlayer,ct_SetNewRemap,ct_SetMapColor,ct_CenterScreen,
                    ct_ClearUp,ct_BlockTrade,ct_BlockHouse,ct_ReleaseHouse,ct_ReleaseAllHouses,ct_AddGoal,ct_AddLostGoal,
                    ct_SetUnit,ct_SetRoad,ct_SetField,ct_Set_Winefield,ct_SetStock,ct_AddWare,ct_SetAlliance,
                    ct_SetHouseDamage,ct_SetUnitByStock,ct_SetGroup,ct_SetGroupFood,ct_SendGroup,
                    ct_AttackPosition,ct_AddWareToSecond,ct_AddWareTo,ct_AddWareToAll,ct_AddWeapon,ct_AICharacter,
                    ct_AINoBuild,ct_AIStartPosition,ct_AIDefence,ct_AIAttack,ct_CopyAIAttack);

  TKMCommandParamType = (cpt_Unknown=0,cpt_Recruits,cpt_Constructors,cpt_WorkerFactor,cpt_RecruitCount,cpt_TownDefence,
                         cpt_MaxSoldier,cpt_EquipRate,cpt_AttackFactor,cpt_TroopParam);

  TAIAttackParamType = (cpt_Type, cpt_TotalAmount, cpt_Counter, cpt_Range, cpt_TroopAmount, cpt_Target, cpt_Position, cpt_TakeAll);


type
  TKMMissionInfo = record
    MapPath: string;
    MapSizeX, MapSizeY: Integer;
    MissionMode: TKMissionMode;
    PlayerCount: shortint;
    HumanPlayerID: TPlayerIndex;
    VictoryCond:string;
    DefeatCond:string;
  end;

  TKMAttackPosition = record
    Warrior: TKMUnitWarrior;
    Target: TKMPoint;
  end;


  TMissionParserCommon = class
  private
    fStrictParsing: Boolean; //Report non-fatal script errors such as SEND_GROUP without defining a group first
    fMissionFileName: string;
    fFatalErrors: string; //Fatal errors descriptions accumulate here
    fMinorErrors: string; //Minor error descriptions accumulate here
    fMissionInfo: TKMMissionInfo;
    function TextToCommandType(const ACommandText: AnsiString): TKMCommandType;
    function ReadMissionFile(const aFileName: string): AnsiString;
    procedure AddError(const ErrorMsg: string; aFatal: Boolean = False);
  public
    constructor Create(aStrictParsing: Boolean);
    property FatalErrors: string read fFatalErrors;
    property MinorErrors: string read fMinorErrors;
    property MissionInfo: TKMMissionInfo read fMissionInfo;
    function LoadMission(const aFileName: string): Boolean; overload; virtual;
  end;


  TMissionParserInfo = class(TMissionParserCommon)
  private
    function LoadMapInfo(const aFileName: string): Boolean;
    procedure ProcessCommand(CommandType: TKMCommandType; const P: array of integer; TextParam:AnsiString);
  public
    function LoadMission(const aFileName: string): Boolean; override;
  end;


  TMissionParserStandard = class(TMissionParserCommon)
  private
    fParsingMode: TMissionParsingMode; //Data gets sent to Game differently depending on Game/Editor mode
    fRemapCount: byte;
    fRemap: TPlayerArray;

    fLastPlayer: integer;
    fLastHouse: TKMHouse;
    fLastTroop: TKMUnitWarrior;
    fAIAttack: TAIAttack;
    fAttackPositions: array of TKMAttackPosition;
    fAttackPositionsCount: integer;

    function ProcessCommand(CommandType: TKMCommandType; P: array of integer; TextParam: AnsiString):boolean;
    procedure ProcessAttackPositions;
  public
    constructor Create(aMode:TMissionParsingMode; aStrictParsing:boolean); overload;
    constructor Create(aMode:TMissionParsingMode; aPlayersRemap:TPlayerArray; aStrictParsing:boolean); overload;
    function LoadMission(const aFileName: string):boolean; overload; override;

    procedure SaveDATFile(const aFileName: String);
  end;

  TTilePreviewInfo = record
                       TileID: Byte;
                       TileHeight: Byte; //Used for calculating light
                       TileOwner: Byte;
                       Revealed: Boolean;
                     end;

  TPlayerPreviewInfo = record
                         Color: Cardinal;
                         StartingLoc: TKMPoint;
                       end;

  //Specially optimized mission parser for map previews
  TMissionParserPreview = class(TMissionParserCommon)
  private
    fMapX: Integer;
    fMapY: Integer;
    fPlayerPreview: array [1..MAX_PLAYERS] of TPlayerPreviewInfo;
    fMapPreview: array[1..MAX_MAP_SIZE*MAX_MAP_SIZE] of TTilePreviewInfo;

    fLastPlayer: Integer;
    fHumanPlayer: Integer;

    function GetTileInfo(X,Y: Integer): TTilePreviewInfo;
    function GetPlayerInfo(aIndex: Byte): TPlayerPreviewInfo;
    procedure LoadMapData(const aFileName: string);
    procedure ProcessCommand(CommandType: TKMCommandType; const P: array of integer);
  public
    property MapPreview[X,Y: Integer]: TTilePreviewInfo read GetTileInfo;
    property PlayerPreview[Index: Byte]: TPlayerPreviewInfo read GetPlayerInfo;
    property MapX: integer read fMapX;
    property MapY: integer read fMapY;
    function LoadMission(const aFileName: string): boolean; override;
  end;


implementation
uses KM_PlayersCollection, KM_Player, KM_AI, KM_AIDefensePos,
  KM_Resource, KM_ResourceHouse, KM_ResourceResource, KM_Game;


const
  COMMANDVALUES: array[TKMCommandType] of AnsiString = (
    '','SET_MAP','SET_MAX_PLAYER','SET_CURR_PLAYER','SET_HUMAN_PLAYER','SET_HOUSE',
    'SET_TACTIC','SET_AI_PLAYER','ENABLE_PLAYER','SET_NEW_REMAP','SET_MAP_COLOR',
    'CENTER_SCREEN','CLEAR_UP','BLOCK_TRADE','BLOCK_HOUSE','RELEASE_HOUSE','RELEASE_ALL_HOUSES',
    'ADD_GOAL','ADD_LOST_GOAL','SET_UNIT','SET_STREET','SET_FIELD','SET_WINEFIELD',
    'SET_STOCK','ADD_WARE','SET_ALLIANCE','SET_HOUSE_DAMAGE','SET_UNIT_BY_STOCK',
    'SET_GROUP','SET_GROUP_FOOD','SEND_GROUP','ATTACK_POSITION','ADD_WARE_TO_SECOND',
    'ADD_WARE_TO','ADD_WARE_TO_ALL','ADD_WEAPON','SET_AI_CHARACTER',
    'SET_AI_NO_BUILD','SET_AI_START_POSITION','SET_AI_DEFENSE','SET_AI_ATTACK',
    'COPY_AI_ATTACK');

  PARAMVALUES: array [TKMCommandParamType] of AnsiString = (
    '','RECRUTS','CONSTRUCTORS','WORKER_FACTOR','RECRUT_COUNT','TOWN_DEFENSE',
    'MAX_SOLDIER','EQUIP_RATE','ATTACK_FACTOR','TROUP_PARAM');

  AI_ATTACK_PARAMS: array [TAIAttackParamType] of AnsiString = (
    'TYPE', 'TOTAL_AMOUNT', 'COUNTER', 'RANGE', 'TROUP_AMOUNT', 'TARGET', 'POSITION', 'TAKEALL');

  MAX_PARAMS = 8;

  //This is a map of the valid values for !SET_UNIT, and the corresponing unit that will be created (matches KaM behavior)
  UnitsRemap: array[0..31] of TUnitType = (ut_Serf,ut_Woodcutter,ut_Miner,ut_AnimalBreeder,
    ut_Farmer,ut_Lamberjack,ut_Baker,ut_Butcher,ut_Fisher,ut_Worker,ut_StoneCutter,
    ut_Smith,ut_Metallurgist,ut_Recruit, //Units
    ut_Militia,ut_AxeFighter,ut_Swordsman,ut_Bowman,ut_Arbaletman,ut_Pikeman,ut_Hallebardman,
    ut_HorseScout,ut_Cavalry,ut_Barbarian, //Troops
    ut_Wolf,ut_Fish,ut_Watersnake,ut_Seastar,ut_Crab,ut_Waterflower,ut_Waterleaf,ut_Duck); //Animals

  UnitReverseRemap: array[TUnitType] of integer = (
  -1, -1, //ut_None, ut_Any
  0,1,2,3,4,5,6,7,8,9,10,11,12,13, //Citizens
  14,15,16,17,18,19,20,21,22,23, //Warriors
  -1,-1,-1,-1, {-1,-1,} //TPR warriors (can't be placed with SET_UNIT)
  24,25,26,27,28,29,30,31); //Animals

  //This is a map of the valid values for !SET_GROUP, and the corresponing unit that will be created (matches KaM behavior)
  TroopsRemap: array[14..29] of TUnitType = (
  ut_Militia,ut_AxeFighter,ut_Swordsman,ut_Bowman,ut_Arbaletman,
  ut_Pikeman,ut_Hallebardman,ut_HorseScout,ut_Cavalry,ut_Barbarian, //TSK Troops
  ut_Peasant,ut_Slingshot,ut_MetalBarbarian,ut_Horseman,
  {ut_Catapult,ut_Ballista);} //Seige, which are not yet enabled
  ut_None,ut_None); //Temp replacement for seige

  TroopsReverseRemap: array[TUnitType] of integer = (
  -1, -1, //ut_None, ut_Any
  -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1, //Citizens
  14,15,16,17,18,19,20,21,22,23, //Warriors
  24,25,26,27, {28,29,} //TPR warriors
  -1,-1,-1,-1,-1,-1,-1,-1); //Animals


{ TMissionParserGeneric }
constructor TMissionParserCommon.Create(aStrictParsing: boolean);
begin
  inherited Create;
  fStrictParsing := aStrictParsing;
end;


function TMissionParserCommon.LoadMission(const aFileName: string):boolean;
begin
  fMissionFileName := aFileName;

  //Set default values
  fMissionInfo.MapPath := '';
  fMissionInfo.MapSizeX := 0;
  fMissionInfo.MapSizeY := 0;
  fMissionInfo.MissionMode := mm_Normal;
  fMissionInfo.PlayerCount := 0;
  fMissionInfo.HumanPlayerID := PLAYER_NONE;
  fMissionInfo.VictoryCond := '';
  fMissionInfo.DefeatCond := '';

  Result := true;
end;


function TMissionParserCommon.TextToCommandType(const ACommandText: AnsiString): TKMCommandType;
var
  i: TKMCommandType;
begin
  Result := ct_Unknown;
  for i:=low(TKMCommandType) to high(TKMCommandType) do
  begin
    if ACommandText = '!' + COMMANDVALUES[i] then
    begin
      Result := i;
      break;
    end;
  end;
  //Commented out because it slows down mission scanning
  //if Result = ct_Unknown then fLog.AddToLog(String(ACommandText));
end;


//Read mission file to a string and if necessary - decode it
function TMissionParserCommon.ReadMissionFile(const aFileName: string): AnsiString;
var
  I,Num: Cardinal;
  F: TMemoryStream;
begin
  if not FileExists(aFileName) then
  begin
    AddError(Format('Mission file %s could not be found', [aFileName]), True);
    Result := '';
    Exit;
  end;

  //Load and decode .DAT file into FileText
  F := TMemoryStream.Create;
  try
    F.LoadFromFile(aFileName);

    if F.Size = 0 then
    begin
      AddError(Format('Mission file %s is empty', [aFileName]), True);
      Result := '';
      Exit;
    end;

    //Detect whether mission is encoded so we can support decoded/encoded .DAT files
    //We can't test 1st char, it can be any. Instead see how often common chracters meet
    Num := 0;
    for I:=0 to F.Size-1 do               //tab, eol, 0..9, space, !
      if PByte(Cardinal(F.Memory)+I)^ in [9,10,13,ord('0')..ord('9'),$20,$21] then
        inc(Num);

    //Usually 30-50% is numerals/spaces, tested on typical KaM maps, take half of that as margin
    if (Num/F.Size < 0.20) then
    for I := 0 to F.Size - 1 do
      PByte(Cardinal(F.Memory)+I)^ := PByte(Cardinal(F.Memory)+I)^ xor 239;

    //Save text after decoding but before cleaning
    if WRITE_DECODED_MISSION then
      F.SaveToFile(aFileName+'.txt');

    for I := 0 to F.Size - 1 do
      if PByte(Cardinal(F.Memory)+I)^ in [9, 10, 13] then //tab, eol
        PByte(Cardinal(F.Memory)+I)^ := $20; //Space

    Num := 0;
    for I := 0 to F.Size - 1 do
    begin
      PByte(Cardinal(F.Memory)+Num)^ := PByte(Cardinal(F.Memory)+I)^;
      if (Num <= 0) or (
        (PWord(Cardinal(F.Memory)+Num-1)^ <> $2020) //Skip double spaces and !!
        and (PWord(Cardinal(F.Memory)+Num-1)^ <> $2121)) then
        inc(Num);
    end;

    SetLength(Result, Num); //Because some extra characters were removed
    F.Position := 0;
    F.ReadBuffer(Result[1], Num);
  finally
    F.Free;
  end;
end;


//A nice way of debugging script errors.
//Shows the error to the user so they know exactly what they did wrong.
procedure TMissionParserCommon.AddError(const ErrorMsg: string; aFatal: Boolean = False);
begin
  if fStrictParsing or aFatal then
    fFatalErrors := fFatalErrors + ErrorMsg + '|';

  if not aFatal then
    fMinorErrors := fMinorErrors + ErrorMsg + '|';
end;


{ TMissionParserInfo }
function TMissionParserInfo.LoadMission(const aFileName: string):boolean;
const
  Max_Cmd=2;
var
  FileText: AnsiString;
  CommandText, Param, TextParam: AnsiString;
  ParamList: array[1..Max_Cmd] of Integer;
  k, l, IntParam: integer;
  CommandType: TKMCommandType;
begin
  inherited LoadMission(aFileName);

  Result := false;

  FileText := ReadMissionFile(aFileName);
  if FileText = '' then Exit;

  //We need only these 6 commands
  //!SET_MAP, !SET_MAX_PLAYER, !SET_TACTIC, !SET_HUMAN_PLAYER, !ADD_GOAL, !ADD_LOST_GOAL

  //FileText should now be formatted nicely with 1 space between each parameter/command
  k := 1;
  repeat
    if FileText[k]='!' then
    begin
      for l:=1 to Max_Cmd do
        ParamList[l]:=-1;
      TextParam:='';
      CommandText:='';
      //Extract command until a space
      repeat
        CommandText:=CommandText+FileText[k];
        inc(k);
      until((FileText[k]=#32)or(k>=length(FileText)));

      //Try to make it faster by only processing commands used
      if (CommandText='!SET_MAP')or(CommandText='!SET_MAX_PLAYER')or
         (CommandText='!SET_TACTIC')or(CommandText='!SET_HUMAN_PLAYER')or
         (CommandText='!ADD_GOAL')or(CommandText='!ADD_LOST_GOAL') then
      begin
        //Now convert command into type
        CommandType := TextToCommandType(CommandText);
        inc(k);
        //Extract parameters
        for l:=1 to Max_Cmd do
          if (k<length(FileText)) and (FileText[k]<>'!') then
          begin
            Param := '';
            repeat
              Param := Param + FileText[k];
              inc(k);
            until((k >= Length(FileText)) or (FileText[k]='!') or (FileText[k]=#32)); //Until we find another ! OR we run out of data

            //Convert to an integer, if possible
            if TryStrToInt(String(Param), IntParam) then
              ParamList[l] := IntParam
            else
              if l = 1 then
                TextParam := Param; //Accept text for first parameter

            if FileText[k]=#32 then inc(k);
          end;
        //We now have command text and parameters, so process them
        ProcessCommand(CommandType,ParamList,TextParam);
      end;
    end
    else
      inc(k);
  until (k>=length(FileText));
  //Apparently it's faster to parse till file end than check if all details are filled

  Result := LoadMapInfo(ChangeFileExt(fMissionFileName,'.map')) and (fFatalErrors='');
end;


procedure TMissionParserInfo.ProcessCommand(CommandType: TKMCommandType; const P: array of integer; TextParam:AnsiString);
begin
  with fMissionInfo do
  case CommandType of
    ct_SetMap:         MapPath       := RemoveQuotes(String(TextParam));
    ct_SetMaxPlayer:   PlayerCount   := P[0];
    ct_SetTactic:      MissionMode   := mm_Tactic;
    ct_SetHumanPlayer: HumanPlayerID := P[0];
{                       if TGoalCondition(P[0]) = gc_Time then
                         VictoryCond := VictoryCond + fPlayers[fLastPlayer].AddGoal(glt_Victory,TGoalCondition(P[0]),TGoalStatus(P[1]),P[3],P[2],play_none)
                       else
                         fPlayers[fLastPlayer].AddGoal(glt_Victory,TGoalCondition(P[0]),TGoalStatus(P[1]),0,P[2],TPlayerID(P[3]));
}
    ct_AddGoal:        VictoryCond   := VictoryCond
                                        + GoalConditionStr[TGoalCondition(P[0])] + ' '
                                        + GoalStatusStr[TGoalStatus(P[1])]+', ';
    ct_AddLostGoal:    DefeatCond    := DefeatCond
                                        + GoalConditionStr[TGoalCondition(P[0])] + ' '
                                        + GoalStatusStr[TGoalStatus(P[1])]+', ';
  end;
end;


{Acquire specific map details in a fast way}
function TMissionParserInfo.LoadMapInfo(const aFileName:string):boolean;
var F:TKMemoryStream; sx,sy:integer;
begin
  Result := false;
  if not FileExists(aFileName) then Exit;

  F := TKMemoryStream.Create;
  try
    F.LoadFromFile(aFileName);
    F.Read(sx);
    F.Read(sy);
  finally
    F.Free;
  end;

  if (sx > MAX_MAP_SIZE) or (sy > MAX_MAP_SIZE) then
  begin
    AddError('MissionParser can''t open the map because it''s too big.',true);
    Result := false;
    Exit;
  end;

  fMissionInfo.MapSizeX := sx;
  fMissionInfo.MapSizeY := sy;
  Result := true;
end;


{ TMissionParserStandard }
//Mode affect how certain parameters are loaded a bit differently
constructor TMissionParserStandard.Create(aMode: TMissionParsingMode; aStrictParsing: boolean);
var i:integer;
begin
  inherited Create(aStrictParsing);
  fParsingMode := aMode;

  for i:=0 to High(fRemap) do
    fRemap[i] := i;

  fRemapCount := MAX_PLAYERS;
end;


constructor TMissionParserStandard.Create(aMode: TMissionParsingMode; aPlayersRemap: TPlayerArray; aStrictParsing: Boolean);
var i:integer;
begin
  inherited Create(aStrictParsing);
  fParsingMode := aMode;

  //PlayerRemap tells us which player should be used for which index
  //and which players should be ignored
  fRemap := aPlayersRemap;

  for i:=0 to High(fRemap) do
    inc(fRemapCount);
end;


function TMissionParserStandard.LoadMission(const aFileName: string): Boolean;
var
  FileText, CommandText, Param, TextParam: AnsiString;
  ParamList: array [1..MAX_PARAMS] of integer;
  k, l, IntParam: integer;
  CommandType: TKMCommandType;
begin
  inherited LoadMission(aFileName);

  Assert((fTerrain <> nil) and (fPlayers <> nil));

  Result := false; //Set it right from the start

  //Reset fPlayers and other stuff
  fLastPlayer := -1;

  //Read the mission file into FileText
  FileText := ReadMissionFile(aFileName);
  if FileText = '' then Exit;

  //FileText should now be formatted nicely with 1 space between each parameter/command
  k := 1;
  repeat
    if FileText[k]='!' then
    begin
      for l:=1 to MAX_PARAMS do
        ParamList[l]:=-1;
      TextParam:='';
      CommandText:='';
      //Extract command until a space
      repeat
        CommandText:=CommandText+FileText[k];
        inc(k);
      until((FileText[k]=#32)or(k>=length(FileText)));
      //Now convert command into type
      CommandType := TextToCommandType(CommandText);
      inc(k);
      //Extract parameters
      for l:=1 to MAX_PARAMS do
        if (k<=length(FileText)) and (FileText[k]<>'!') then
        begin
          Param := '';
          repeat
            Param:=Param+FileText[k];
            inc(k);
          until((k>=length(FileText))or(FileText[k]='!')or(FileText[k]=#32)); //Until we find another ! OR we run out of data

          //Convert to an integer, if possible
          if TryStrToInt(String(Param), IntParam) then
            ParamList[l] := IntParam
          else
            if l = 1 then
              TextParam := Param; //Accept text for first parameter

          if (k<=length(FileText)) and (FileText[k]=#32) then inc(k);
        end;
      //We now have command text and parameters, so process them

      if not ProcessCommand(CommandType, ParamList, TextParam) then //A returned value of false indicates an error has occoured and we should exit
      begin
        Result := false;
        Exit;
      end;
    end
    else
      inc(k);
  until (k>=length(FileText));

  //Post-processing of ct_Attack_Position commands which must be done after mission has been loaded
  ProcessAttackPositions;

  //SinglePlayer needs a player
  if (fMissionInfo.HumanPlayerID = PLAYER_NONE) and (fParsingMode = mpm_Single) then
    if ALLOW_NO_HUMAN_IN_SP then
      fMissionInfo.HumanPlayerID := 0 //We need to choose some player to look at
    else
      AddError('No human player detected - ''ct_SetHumanPlayer''', True);

  //If we have reach here without exiting then loading was successful if no errors were reported
  Result := (fFatalErrors = '');
end;


function TMissionParserStandard.ProcessCommand(CommandType: TKMCommandType; P: array of integer; TextParam: AnsiString):boolean;
var
  MapFileName: string;
  i: integer;
  Qty: integer;
  H: TKMHouse;
  HT: THouseType;
  iPlayerAI: TKMPlayerAI;
begin
  Result := false; //Set it right from the start. There are several Exit points below

  case CommandType of
    ct_SetMap:          begin
                          MapFileName := RemoveQuotes(String(TextParam));
                          //Check for same filename.map in same folder first - Remake format
                          if FileExists(ChangeFileExt(fMissionFileName,'.map')) then
                            fTerrain.LoadFromFile(ChangeFileExt(fMissionFileName,'.map'), fParsingMode = mpm_Editor)
                          else
                          //Check for KaM format map path
                          if FileExists(ExeDir+MapFileName) then
                            fTerrain.LoadFromFile(ExeDir+MapFileName, fParsingMode = mpm_Editor)
                          else
                          begin
                            //Else abort loading and fail
                            AddError('Map file couldn''t be found',true);
                            Exit;
                          end;
                        end;
    ct_SetMaxPlayer:    begin
                          if fParsingMode = mpm_Single then
                            fPlayers.AddPlayers(P[0])
                          else
                            fPlayers.AddPlayers(fRemapCount);
                        end;
    ct_SetTactic:       begin
                          fMissionInfo.MissionMode := mm_Tactic;
                        end;
    ct_SetCurrPlayer:   if InRange(P[0], 0, MAX_PLAYERS-1) then
                        begin
                          fLastPlayer := fRemap[P[0]]; //
                          fLastHouse := nil;
                          fLastTroop := nil;
                        end;
    ct_SetHumanPlayer:  if (fParsingMode <> mpm_Multi) and (fPlayers <> nil) then
                          if InRange(P[0], 0, fPlayers.Count-1) then
                          begin
                            fMissionInfo.HumanPlayerID := P[0];
                            fPlayers[P[0]].PlayerType := pt_Human;
                          end;
                        //Multiplayer will set Human player itself after loading
    ct_AIPlayer:        if (fParsingMode <> mpm_Multi) and (fPlayers <> nil) then
                          if InRange(P[0],0,fPlayers.Count-1) then
                            fPlayers[P[0]].PlayerType:=pt_Computer
                          else //This command doesn't require an ID, just use the current player
                            fPlayers[fLastPlayer].PlayerType:=pt_Computer;
                        //Multiplayer will set AI players itself after loading
    ct_CenterScreen:    if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].CenterScreen := KMPoint(P[0]+1,P[1]+1);
    ct_ClearUp:         if fLastPlayer >= 0 then
                        begin
                          if fParsingMode = mpm_Editor then
                            if P[0] = 255 then
                              fGame.MapEditor.Revealers[fLastPlayer].AddEntry(KMPoint(0,0), 255, 0)
                            else
                              fGame.MapEditor.Revealers[fLastPlayer].AddEntry(KMPoint(P[0]+1,P[1]+1), P[2], 0)
                          else
                            if P[0] = 255 then
                              fPlayers[fLastPlayer].FogOfWar.RevealEverything
                            else
                              fPlayers[fLastPlayer].FogOfWar.RevealCircle(KMPoint(P[0]+1,P[1]+1), P[2], 255);
                        end;
    ct_SetHouse:        if fLastPlayer >= 0 then
                          if InRange(P[0], Low(HouseKaMType), High(HouseKaMType)) then
                            if fTerrain.CanPlaceHouseFromScript(HouseKaMType[P[0]], KMPoint(P[1]+1, P[2]+1)) then
                              fLastHouse := fPlayers[fLastPlayer].AddHouse(
                                HouseKaMType[P[0]], P[1]+1, P[2]+1, false)
                            else
                              AddError('ct_SetHouse failed, can not place house at ' + TypeToString(KMPoint(P[1]+1, P[2]+1)));
    ct_SetHouseDamage:  if fLastPlayer >= 0 then //Skip false-positives for skipped players
                          if fLastHouse <> nil then
                            fLastHouse.AddDamage(min(P[0],high(word)), fParsingMode = mpm_Editor)
                          else
                            AddError('ct_SetHouseDamage without prior declaration of House');
    ct_SetUnit:         begin
                          //Animals should be added regardless of current player
                          if UnitsRemap[P[0]] in [ANIMAL_MIN..ANIMAL_MAX] then
                            fPlayers.PlayerAnimals.AddUnit(UnitsRemap[P[0]], KMPoint(P[1]+1, P[2]+1))
                          else
                          if (fLastPlayer >= 0) and (UnitsRemap[P[0]] in [HUMANS_MIN..HUMANS_MAX]) then
                            fPlayers[fLastPlayer].AddUnit(UnitsRemap[P[0]], KMPoint(P[1]+1, P[2]+1));
                        end;

    ct_SetUnitByStock:  if fLastPlayer >= 0 then
                          if UnitsRemap[P[0]] in [HUMANS_MIN..HUMANS_MAX] then
                          begin
                            H := fPlayers[fLastPlayer].FindHouse(ht_Store, 1);
                            if H <> nil then
                              fPlayers[fLastPlayer].AddUnit(UnitsRemap[P[0]], KMPoint(H.GetEntrance.X, H.GetEntrance.Y+1));
                          end;
    ct_SetRoad:         if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0]+1,P[1]+1));
    ct_SetField:        if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AddField(KMPoint(P[0]+1,P[1]+1),ft_Corn);
    ct_Set_Winefield:   if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AddField(KMPoint(P[0]+1,P[1]+1),ft_Wine);
    ct_SetStock:        if fLastPlayer >= 0 then
                        begin //This command basically means: Put a SH here with road bellow it
                          fLastHouse := fPlayers[fLastPlayer].AddHouse(ht_Store, P[0]+1,P[1]+1, false);
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0]+1,P[1]+2));
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0],P[1]+2));
                          fPlayers[fLastPlayer].AddRoadToList(KMPoint(P[0]-1,P[1]+2));
                        end;
    ct_AddWare:         if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources
                          H := fPlayers[fLastPlayer].FindHouse(ht_Store,1);
                          if (H <> nil) and (ResourceKaMIndex[P[0]] in [WARE_MIN..WARE_MAX]) then
                          begin
                            H.ResAddToIn(ResourceKaMIndex[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceKaMIndex[P[0]], Qty);
                          end;

                        end;
    ct_AddWareToAll:    if (fParsingMode <> mpm_Preview) then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources
                          for i:=0 to fPlayers.Count-1 do
                          begin
                            H := fPlayers[i].FindHouse(ht_Store,1);
                            if (H<>nil) and (ResourceKaMIndex[P[0]] in [WARE_MIN..WARE_MAX]) then
                            begin
                              H.ResAddToIn(ResourceKaMIndex[P[0]], Qty, True);
                              fPlayers[i].Stats.GoodInitial(ResourceKaMIndex[P[0]], Qty);
                            end;
                          end;
                        end;
    ct_AddWareToSecond: if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          H := TKMHouseStore(fPlayers[fLastPlayer].FindHouse(ht_Store, 2));
                          if (H <> nil) and (ResourceKaMIndex[P[0]] in [WARE_MIN..WARE_MAX]) then
                          begin
                            H.ResAddToIn(ResourceKaMIndex[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceKaMIndex[P[0]], Qty);
                          end;
                        end;
    ct_AddWareTo:       if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin //HouseType, House Order, Ware Type, Count
                          Qty := EnsureRange(P[3], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum resources

                          H := fPlayers[fLastPlayer].FindHouse(HouseKaMType[P[0]], P[1]);
                          if (H <> nil) and (ResourceKaMIndex[P[2]] in [WARE_MIN..WARE_MAX]) then
                          begin
                            H.ResAddToIn(ResourceKaMIndex[P[2]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceKaMIndex[P[2]], Qty);
                          end;
                        end;
    ct_AddWeapon:       if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          Qty := EnsureRange(P[1], -1, High(Word)); //Sometimes user can define it to be 999999
                          if Qty = -1 then Qty := High(Word); //-1 means maximum weapons
                          H := TKMHouseBarracks(fPlayers[fLastPlayer].FindHouse(ht_Barracks, 1));
                          if (H <> nil) and (ResourceKaMIndex[P[0]] in [WARFARE_MIN..WARFARE_MAX]) then
                          begin
                            H.ResAddToIn(ResourceKaMIndex[P[0]], Qty, True);
                            fPlayers[fLastPlayer].Stats.GoodInitial(ResourceKaMIndex[P[0]], Qty);
                          end;
                        end;
    ct_BlockTrade:      if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          if ResourceKaMIndex[P[0]] in [WARE_MIN..WARE_MAX] then
                            fPlayers[fLastPlayer].Stats.AllowToTrade[ResourceKaMIndex[P[0]]] := false;
                        end;
    ct_BlockHouse:      if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          if InRange(P[0], Low(HouseKaMType), High(HouseKaMType)) then
                            fPlayers[fLastPlayer].Stats.HouseBlocked[HouseKaMType[P[0]]] := True;
                        end;
    ct_ReleaseHouse:    if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          if InRange(P[0], Low(HouseKaMType), High(HouseKaMType)) then
                            fPlayers[fLastPlayer].Stats.HouseGranted[HouseKaMType[P[0]]] := True;
                        end;
    ct_ReleaseAllHouses:if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                          for HT:=Low(THouseType) to High(THouseType) do
                            fPlayers[fLastPlayer].Stats.HouseGranted[HT] := True;
    ct_SetGroup:        if fLastPlayer >= 0 then
                          if InRange(P[0], Low(TroopsRemap), High(TroopsRemap)) and (TroopsRemap[P[0]] <> ut_None) then
                            fLastTroop := TKMUnitWarrior(fPlayers[fLastPlayer].AddUnitGroup(
                              TroopsRemap[P[0]],
                              KMPoint(P[1]+1, P[2]+1),
                              TKMDirection(P[3]+1),
                              P[4],
                              P[5],
                              fParsingMode=mpm_Editor //Editor mode = true
                              ));
    ct_SendGroup:       if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          if fLastTroop <> nil then
                            fLastTroop.OrderWalk(KMPoint(P[0]+1, P[1]+1), TKMDirection(P[2]+1))
                          else
                            AddError('ct_SendGroup without prior declaration of Troop');
                        end;
    ct_SetGroupFood:    if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          if fLastTroop <> nil then
                            fLastTroop.SetGroupFullCondition
                          else
                            AddError('ct_SetGroupFood without prior declaration of Troop');
                        end;
    ct_AICharacter:     if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                        begin
                          if fPlayers[fLastPlayer].PlayerType <> pt_Computer then Exit;
                          iPlayerAI := fPlayers[fLastPlayer].AI; //Setup the AI's character
                          if TextParam = PARAMVALUES[cpt_Recruits]     then iPlayerAI.Setup.RecruitFactor := P[1];
                          if TextParam = PARAMVALUES[cpt_Constructors] then iPlayerAI.Setup.WorkerFactor  := P[1];
                          if TextParam = PARAMVALUES[cpt_WorkerFactor] then iPlayerAI.Setup.SerfFactor    := P[1];
                          if TextParam = PARAMVALUES[cpt_RecruitCount] then iPlayerAI.Setup.RecruitDelay  := P[1];
                          if TextParam = PARAMVALUES[cpt_TownDefence]  then iPlayerAI.Setup.TownDefence   := P[1];
                          if TextParam = PARAMVALUES[cpt_MaxSoldier]   then iPlayerAI.Setup.MaxSoldiers   := P[1];
                          if TextParam = PARAMVALUES[cpt_EquipRate]    then
                          begin
                            iPlayerAI.Setup.EquipRateLeather := P[1];
                            iPlayerAI.Setup.EquipRateIron    := P[1]; //Both the same for now, could be separate commands later
                          end;
                          if TextParam = PARAMVALUES[cpt_AttackFactor] then iPlayerAI.Setup.Aggressiveness:= P[1];
                          if TextParam = PARAMVALUES[cpt_TroopParam]   then
                          begin
                            iPlayerAI.DefencePositions.TroopFormations[TGroupType(P[1])].NumUnits := P[2];
                            iPlayerAI.DefencePositions.TroopFormations[TGroupType(P[1])].UnitsPerRow  := P[3];
                          end;
                        end;
    ct_AINoBuild:       if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AI.Setup.Autobuild := False;
    ct_AIStartPosition: if fLastPlayer >= 0 then
                          fPlayers[fLastPlayer].AI.Setup.StartPosition := KMPoint(P[0]+1,P[1]+1);
    ct_SetAlliance:     if (fLastPlayer >=0) and (fRemap[P[0]] >= 0) then
                          if P[1] = 1 then
                            fPlayers[fLastPlayer].Alliances[fRemap[P[0]]] := at_Ally
                          else
                            fPlayers[fLastPlayer].Alliances[fRemap[P[0]]] := at_Enemy;
    ct_AttackPosition:  if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                          //If target is building: Attack building
                          //If target is unit: Chase/attack unit
                          //If target is nothing: move to position
                          //However, because the unit/house target may not have been created yet, this must be processed after everything else
                          if fLastTroop <> nil then
                          begin
                            inc(fAttackPositionsCount);
                            SetLength(fAttackPositions, fAttackPositionsCount+1);
                            fAttackPositions[fAttackPositionsCount-1].Warrior := fLastTroop;
                            fAttackPositions[fAttackPositionsCount-1].Target := KMPoint(P[0]+1,P[1]+1);
                          end
                          else
                            AddError('ct_AttackPosition without prior declaration of Troop');
    ct_AddGoal:         if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                          //If the condition is time then P[3] is the time, else it is player ID
                          if TGoalCondition(P[0]) = gc_Time then
                            fPlayers[fLastPlayer].Goals.AddGoal(glt_Victory,TGoalCondition(P[0]),TGoalStatus(P[1]),P[3],P[2],-1)
                          else
                            if fRemap[P[3]] >= 0 then
                              if fRemap[P[3]] <= fPlayers.Count-1 then
                                fPlayers[fLastPlayer].Goals.AddGoal(glt_Victory,TGoalCondition(P[0]),TGoalStatus(P[1]),0,P[2],fRemap[P[3]])
                              else
                                AddError('Add_Goal for non existing player');
    ct_AddLostGoal:     if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                          //If the condition is time then P[3] is the time, else it is player ID
                          if TGoalCondition(P[0]) = gc_Time then
                            fPlayers[fLastPlayer].Goals.AddGoal(glt_Survive,TGoalCondition(P[0]),TGoalStatus(P[1]),P[3],P[2],-1)
                          else
                            if fRemap[P[3]] >= 0 then
                              fPlayers[fLastPlayer].Goals.AddGoal(glt_Survive,TGoalCondition(P[0]),TGoalStatus(P[1]),0,P[2],fRemap[P[3]])
                            else
                              AddError('Add_LostGoal for non existing player');
    ct_AIDefence:       if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >=0 then
                        if InRange(P[3], Integer(Low(TGroupType)), Integer(High(TGroupType))) then //TPR 3 tries to set TGroupType 240 due to a missing space
                          fPlayers[fLastPlayer].AI.DefencePositions.AddDefencePosition(KMPointDir(P[0]+1, P[1]+1, TKMDirection(P[2]+1)),TGroupType(P[3]),P[4],TAIDefencePosType(P[5]));
    ct_SetMapColor:     if fLastPlayer >=0 then
                          //For now simply use the minimap color for all color, it is too hard to load all 8 shades from ct_SetNewRemap
                          fPlayers[fLastPlayer].FlagColor := fResource.Palettes.DefDal.Color32(P[0]);
    ct_AIAttack:        if (fParsingMode <> mpm_Preview) then
                        begin
                          //Set up the attack command
                          if TextParam = AI_ATTACK_PARAMS[cpt_Type] then
                            if InRange(P[1], Low(RemakeAttackType), High(RemakeAttackType)) then
                              fAIAttack.AttackType := RemakeAttackType[P[1]]
                            else
                              AddError('Unknown parameter ' + IntToStr(P[1]) + ' at ct_AIAttack');
                          if TextParam = AI_ATTACK_PARAMS[cpt_TotalAmount] then
                            fAIAttack.TotalMen := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cpt_Counter] then
                            fAIAttack.Delay := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cpt_Range] then
                            fAIAttack.Range := P[1];
                          if TextParam = AI_ATTACK_PARAMS[cpt_TroopAmount] then
                            fAIAttack.GroupAmounts[TGroupType(P[1])] := P[2];
                          if TextParam = AI_ATTACK_PARAMS[cpt_Target] then
                            fAIAttack.Target := TAIAttackTarget(P[1]);
                          if TextParam = AI_ATTACK_PARAMS[cpt_Position] then
                            fAIAttack.CustomPosition := KMPoint(P[1]+1,P[2]+1);
                          if TextParam = AI_ATTACK_PARAMS[cpt_TakeAll] then
                            fAIAttack.TakeAll := True;
                        end;
    ct_CopyAIAttack:    if (fParsingMode <> mpm_Preview) then
                        if fLastPlayer >= 0 then
                          //Save the attack to the AI assets
                          fPlayers[fLastPlayer].AI.Attacks.AddAttack(fAIAttack);
    ct_EnablePlayer:    begin
                          //Serves no real purpose, all players have this command anyway
                        end;
    ct_SetNewRemap:     begin
                          //Disused. Minimap color is used for all colors now. However it might be better to use these values in the long run as sometimes the minimap colors do not match well
                        end;
  end;
  Result := true; //Must have worked if we haven't exited by now
end;


//Determine what we are attacking: House, Unit or just walking to some place
procedure TMissionParserStandard.ProcessAttackPositions;
var
  i: integer;
  H: TKMHouse;
  U: TKMUnit;
begin
  for i:=0 to fAttackPositionsCount-1 do
    with fAttackPositions[i] do
    begin
      H := fPlayers.HousesHitTest(Target.X,Target.Y); //Attack house
      if (H <> nil) and (not H.IsDestroyed) and (fPlayers.CheckAlliance(Warrior.Owner,H.Owner) = at_Enemy) then
        Warrior.OrderAttackHouse(H)
      else
      begin
        U := fTerrain.UnitsHitTest(Target.X,Target.Y); //Chase/attack unit
        if (U <> nil) and (not U.IsDeadOrDying) and (fPlayers.CheckAlliance(Warrior.Owner,U.Owner) = at_Enemy) then
          Warrior.OrderAttackUnit(U)
        else
          Warrior.OrderWalk(Target); //Just move to position
      end;
    end;
end;


//Write out a KaM format mission file to aFileName
procedure TMissionParserStandard.SaveDATFile(const aFileName: String);
const
  COMMANDLAYERS = 4;
var
  f:textfile;
  i: longint; //longint because it is used for encoding entire output, which will limit the file size
  k,iX,iY,CommandLayerCount: Integer;
  HouseCount: array[THouseType] of Integer;
  Res: TResourceType;
  G: TGroupType;
  U: TKMUnit;
  H: TKMHouse;
  HT: THouseType;
  ReleaseAllHouses: boolean;
  SaveString: AnsiString;

  procedure AddData(aText: AnsiString);
  begin
    if CommandLayerCount = -1 then //No layering
      SaveString := SaveString + aText + eol //Add to the string normally
    else
    begin
      case (CommandLayerCount mod COMMANDLAYERS) of
        0:   SaveString := SaveString + eol + aText //Put a line break every 4 commands
        else SaveString := SaveString + ' ' + aText; //Just put spaces so commands "layer"
      end;
      inc(CommandLayerCount);
    end
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TKMCommandParamType; aParams: array of integer); overload;
  var OutData: AnsiString; i:integer;
  begin
    OutData := '!' + COMMANDVALUES[aCommand];

    if aComParam <> cpt_Unknown then
      OutData := OutData + ' ' + PARAMVALUES[aComParam];

    for i:=Low(aParams) to High(aParams) do
      OutData := OutData + ' ' + AnsiString(IntToStr(aParams[i]));

    AddData(OutData);
  end;

  procedure AddCommand(aCommand: TKMCommandType; aComParam: TAIAttackParamType; aParams: array of integer); overload;
  var OutData: AnsiString; i:integer;
  begin
    OutData := '!' + COMMANDVALUES[aCommand] + ' ' + AI_ATTACK_PARAMS[aComParam];

    for i:=Low(aParams) to High(aParams) do
      OutData := OutData + ' ' + AnsiString(IntToStr(aParams[i]));

    AddData(OutData);
  end;

  procedure AddCommand(aCommand:TKMCommandType; aParams:array of integer); overload;
  begin
    AddCommand(aCommand, cpt_Unknown, aParams);
  end;

begin

  //Put data into stream
  SaveString := '';
  CommandLayerCount := -1; //Some commands (road/fields) are layered so the file is easier to read (not so many lines)

  //Main header, use same filename for MAP
  AddData('!'+COMMANDVALUES[ct_SetMap] + ' "data\mission\smaps\' + AnsiString(ExtractFileName(TruncateExt(aFileName))) + '.map"');
  if fGame.MissionMode = mm_Tactic then AddCommand(ct_SetTactic, []);
  AddCommand(ct_SetMaxPlayer, [fPlayers.Count]);
  AddData(''); //NL

  //Player loop
  for i:=0 to fPlayers.Count-1 do
  begin
    //Player header, using same order of commands as KaM
    AddCommand(ct_SetCurrPlayer, [i]); //In script player 0 is the first
    if fPlayers[i].PlayerType = pt_Human then
      AddCommand(ct_SetHumanPlayer, [i]);
    AddCommand(ct_EnablePlayer, [i]);
    if fPlayers[i].PlayerType = pt_Computer then
      AddCommand(ct_AIPlayer, []);

    AddCommand(ct_SetMapColor, [fPlayers[i].FlagColorIndex]);
    if not KMSamePoint(fPlayers[i].CenterScreen, KMPoint(0,0)) then
      AddCommand(ct_CenterScreen, [fPlayers[i].CenterScreen.X-1,fPlayers[i].CenterScreen.Y-1]);

    with fGame.MapEditor.Revealers[I] do
    for K := 0 to Count - 1 do
      if (Items[K].X = 0) and (Items[K].Y = 0) and (Tag[K] = 255) then
        AddCommand(ct_ClearUp, [255])
      else
        AddCommand(ct_ClearUp, [Items[K].X-1, Items[K].Y-1, Tag[K]]);

    AddData(''); //NL

    //Human specific, e.g. goals, center screen (though all players can have it, only human can use it)
    for k:=0 to fPlayers[i].Goals.Count-1 do
      with fPlayers[i].Goals[k] do
      begin
        if (GoalType = glt_Victory) or (GoalType = glt_None) then //For now treat none same as normal goal, we can add new command for it later
          if GoalCondition = gc_Time then
            AddCommand(ct_AddGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,GoalTime])
          else
            AddCommand(ct_AddGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,PlayerIndex]);

        if GoalType = glt_Survive then
          if GoalCondition = gc_Time then
            AddCommand(ct_AddLostGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,GoalTime])
          else
            AddCommand(ct_AddLostGoal, [byte(GoalCondition),byte(GoalStatus),MessageToShow,PlayerIndex]);
      end;
    AddData(''); //NL

    //Computer specific, e.g. AI commands
    if fPlayers[i].PlayerType = pt_Computer then
    begin
      AddCommand(ct_AIStartPosition, [fPlayers[i].AI.Setup.StartPosition.X-1,fPlayers[i].AI.Setup.StartPosition.Y-1]);
      if not fPlayers[i].AI.Setup.Autobuild then
        AddCommand(ct_AINoBuild, []);
      AddCommand(ct_AICharacter,cpt_Recruits, [fPlayers[i].AI.Setup.RecruitFactor]);
      AddCommand(ct_AICharacter,cpt_WorkerFactor, [fPlayers[i].AI.Setup.SerfFactor]);
      AddCommand(ct_AICharacter,cpt_Constructors, [fPlayers[i].AI.Setup.WorkerFactor]);
      AddCommand(ct_AICharacter,cpt_TownDefence, [fPlayers[i].AI.Setup.TownDefence]);
      //Only store if a limit is in place (high is the default)
      if fPlayers[i].AI.Setup.MaxSoldiers <> High(fPlayers[i].AI.Setup.MaxSoldiers) then
        AddCommand(ct_AICharacter,cpt_MaxSoldier, [fPlayers[i].AI.Setup.MaxSoldiers]);
      AddCommand(ct_AICharacter,cpt_EquipRate,    [fPlayers[i].AI.Setup.EquipRateLeather]); //Iron and Leather could be made into separate commands later
      AddCommand(ct_AICharacter,cpt_AttackFactor, [fPlayers[i].AI.Setup.Aggressiveness]);
      AddCommand(ct_AICharacter,cpt_RecruitCount, [fPlayers[i].AI.Setup.RecruitDelay]);
      for G:=Low(TGroupType) to High(TGroupType) do
        if fPlayers[i].AI.DefencePositions.TroopFormations[G].NumUnits <> 0 then //Must be valid and used
          AddCommand(ct_AICharacter, cpt_TroopParam, [KaMGroupType[G], fPlayers[i].AI.DefencePositions.TroopFormations[G].NumUnits, fPlayers[i].AI.DefencePositions.TroopFormations[G].UnitsPerRow]);
      AddData(''); //NL
      for k:=0 to fPlayers[i].AI.DefencePositions.Count - 1 do
        with fPlayers[i].AI.DefencePositions[k] do
          AddCommand(ct_AIDefence, [Position.Loc.X-1,Position.Loc.Y-1,byte(Position.Dir)-1,KaMGroupType[GroupType],Radius,byte(DefenceType)]);
      AddData(''); //NL
      AddData(''); //NL
      for k:=0 to fPlayers[i].AI.Attacks.Count - 1 do
        with fPlayers[i].AI.Attacks[k] do
        begin
          AddCommand(ct_AIAttack, cpt_Type, [KaMAttackType[AttackType]]);
          AddCommand(ct_AIAttack, cpt_TotalAmount, [TotalMen]);
          if TakeAll then
            AddCommand(ct_AIAttack, cpt_TakeAll, [])
          else
            for G:=Low(TGroupType) to High(TGroupType) do
              AddCommand(ct_AIAttack, cpt_TroopAmount, [KaMGroupType[G], GroupAmounts[G]]);

          if (Delay > 0) or (AttackType = aat_Once) then //Type once must always have counter because it uses the delay
            AddCommand(ct_AIAttack,cpt_Counter, [Delay]);

          AddCommand(ct_AIAttack,cpt_Target, [Byte(Target)]);
          if Target = att_CustomPosition then
            AddCommand(ct_AIAttack,cpt_Position, [CustomPosition.X-1,CustomPosition.Y-1]);

          if Range > 0 then
            AddCommand(ct_AIAttack,cpt_Range, [Range]);

          AddCommand(ct_CopyAIAttack, [k]); //Store attack with ID number
          AddData(''); //NL
        end;
      AddData(''); //NL
    end;

    //General, e.g. units, roads, houses, etc.
    //Alliances
    for k:=0 to fPlayers.Count-1 do
      if k<>i then
        AddCommand(ct_SetAlliance, [k, byte(fPlayers[i].Alliances[k])]); //0=enemy, 1=ally
    AddData(''); //NL

    //Release/block houses
    ReleaseAllHouses := True;
    for HT := Low(THouseType) to High(THouseType) do
    if fResource.HouseDat[HT].IsValid then //Exclude ht_None / ht_Any
    begin
      if fPlayers[i].Stats.HouseBlocked[HT] then
      begin
        AddCommand(ct_BlockHouse, [HouseKaMOrder[HT]-1]);
        ReleaseAllHouses := false;
      end
      else
        if fPlayers[i].Stats.HouseGranted[HT] then
          AddCommand(ct_ReleaseHouse, [HouseKaMOrder[HT]-1])
        else
          ReleaseAllHouses := false;
    end;
    if ReleaseAllHouses then
      AddCommand(ct_ReleaseAllHouses, []);

    //Block trades
    for Res := WARE_MIN to WARE_MAX do
      if not fPlayers[i].Stats.AllowToTrade[Res] then
        AddCommand(ct_BlockTrade, [ResourceKaMOrder[Res]]);

    //Houses
    for k:=0 to fPlayers[i].Houses.Count-1 do
    begin
      H := fPlayers[i].Houses[k];
      if not H.IsDestroyed then
      begin
        AddCommand(ct_SetHouse, [HouseKaMOrder[H.HouseType]-1, H.GetPosition.X-1, H.GetPosition.Y-1]);
        if H.IsDamaged then
          AddCommand(ct_SetHouseDamage, [H.GetDamage]);
      end;
    end;
    AddData(''); //NL

    //Wares. Check every house to see if it has any wares in it
    FillChar(HouseCount, SizeOf(HouseCount), #0);
    for k:=0 to fPlayers[i].Houses.Count-1 do
    begin
      H := fPlayers[i].Houses[k];
      inc(HouseCount[H.HouseType]);

      if H.IsDestroyed then Continue;

      //First two Stores use special KaM commands
      if (H.HouseType = ht_Store) and (HouseCount[ht_Store] <= 2) then
      begin
        for Res := WARE_MIN to WARE_MAX do
          if H.CheckResIn(Res) > 0 then
            case HouseCount[ht_Store] of
              1:  AddCommand(ct_AddWare, [ResourceKaMOrder[Res], H.CheckResIn(Res)]);
              2:  AddCommand(ct_AddWareToSecond, [ResourceKaMOrder[Res], H.CheckResIn(Res)]);
            end;
      end
      else
      //First Barracks uses special KaM command
      if (H.HouseType = ht_Barracks) and (HouseCount[ht_Barracks] <= 1) then
      begin
        for Res := WARFARE_MIN to WARFARE_MAX do
          if H.CheckResIn(Res) > 0 then
            AddCommand(ct_AddWeapon, [ResourceKaMOrder[Res], H.CheckResIn(Res)]); //Ware, Count
      end
      else
        for Res := WARE_MIN to WARE_MAX do
          if H.CheckResIn(Res) > 0 then
            AddCommand(ct_AddWareTo, [HouseKaMOrder[H.HouseType]-1, HouseCount[H.HouseType], ResourceKaMOrder[Res], H.CheckResIn(Res)]);

    end;
    AddData(''); //NL


    //Roads and fields. We must check EVERY terrain tile
    CommandLayerCount := 0; //Enable command layering
    for iY := 1 to fTerrain.MapY do
      for iX := 1 to fTerrain.MapX do
        if fTerrain.Land[iY,iX].TileOwner = fPlayers[i].PlayerIndex then
        begin
          if fTerrain.Land[iY,iX].TileOverlay = to_Road then
            AddCommand(ct_SetRoad, [iX-1,iY-1]);
          if fTerrain.TileIsCornField(KMPoint(iX,iY)) then
            AddCommand(ct_SetField, [iX-1,iY-1]);
          if fTerrain.TileIsWineField(KMPoint(iX,iY)) then
            AddCommand(ct_Set_Winefield, [iX-1,iY-1]);
        end;
    CommandLayerCount := -1; //Disable command layering
    AddData(''); //Extra NL because command layering doesn't put one
    AddData(''); //NL

    //Units
    for k:=0 to fPlayers[i].Units.Count-1 do
    begin
      U := fPlayers[i].Units[k];
      if U is TKMUnitWarrior then
      begin
        if TKMUnitWarrior(U).IsCommander then //Parse only Commanders
        begin
          AddCommand(ct_SetGroup, [TroopsReverseRemap[U.UnitType], U.GetPosition.X-1, U.GetPosition.Y-1, Byte(U.Direction)-1, TKMUnitWarrior(U).UnitsPerRow, TKMUnitWarrior(U).fMapEdMembersCount+1]);
          if U.Condition = UNIT_MAX_CONDITION then
            AddCommand(ct_SetGroupFood, []);
        end;
      end
      else
        AddCommand(ct_SetUnit, [UnitReverseRemap[U.UnitType], U.GetPosition.X-1, U.GetPosition.Y-1]);
    end;

    AddData(''); //NL
    AddData(''); //NL
  end; //Player loop

  //Main footer

  //Animals, wares to all, etc. go here
  AddData('//Animals');
  for i:=0 to fPlayers.PlayerAnimals.Units.Count-1 do
  begin
    U := fPlayers.PlayerAnimals.Units[i];
    AddCommand(ct_SetUnit, [UnitReverseRemap[U.UnitType], U.GetPosition.X-1, U.GetPosition.Y-1]);
  end;
  AddData(''); //NL

  //Similar footer to one in Lewin's Editor, useful so ppl know what mission was made with.
  AddData('//This mission was made with KaM Remake Map Editor version '+GAME_VERSION+' at '+AnsiString(DateTimeToStr(Now)));

  //Write uncoded file for debug
  assignfile(f, aFileName+'.txt'); rewrite(f);
  write(f, SaveString);
  closefile(f);

  //Encode it
  for i:=1 to Length(SaveString) do
    SaveString[i] := AnsiChar(Byte(SaveString[i]) xor 239);

  //Write it
  assignfile(f, aFileName); rewrite(f);
  write(f, SaveString);
  closefile(f);
end;


function TMissionParserPreview.GetTileInfo(X,Y:integer):TTilePreviewInfo;
begin
  Result := fMapPreview[(Y-1)*fMapX + X];
end;


function TMissionParserPreview.GetPlayerInfo(aIndex:byte):TPlayerPreviewInfo;
begin
  Result := fPlayerPreview[aIndex];
end;


procedure TMissionParserPreview.LoadMapData(const aFileName: string);
var
  i:integer;
  S:TKMemoryStream;
  NewX,NewY:integer;
begin
  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(aFileName);
    S.Read(NewX); //We read header to new variables to avoid damage to existing map if header is wrong
    S.Read(NewY);
    Assert((NewX <= MAX_MAP_SIZE) and (NewY <= MAX_MAP_SIZE), 'Can''t open the map cos it has too big dimensions');
    fMapX := NewX;
    fMapY := NewY;
    for i:=1 to fMapX*fMapY do
    begin
      S.Read(fMapPreview[i].TileID);
      S.Seek(1, soFromCurrent);
      S.Read(fMapPreview[i].TileHeight); //Height (for lighting)
      S.Seek(20, soFromCurrent);
    end;
  finally
    S.Free;
  end;
end;


procedure TMissionParserPreview.ProcessCommand(CommandType: TKMCommandType; const P: array of integer);

  procedure SetOwner(X,Y:Word);
  begin
    fMapPreview[X + Y*fMapX].TileOwner := fLastPlayer;
  end;

  procedure RevealCircle(X,Y,Radius:Word);
  var i,k:Word;
  begin
    if (fHumanPlayer = 0) or (fHumanPlayer <> fLastPlayer) then exit;
    for i:=max(Y-Radius,1) to min(Y+Radius,fMapY) do
    for k:=max(X-Radius,1) to min(X+Radius,fMapX) do
       if (sqr(X-k) + sqr(Y-i)) <= sqr(Radius) then
         fMapPreview[(i-1)*fMapX + k].Revealed := True;
  end;

var i,k:integer; HA:THouseArea; Valid: Boolean; Loc: TKMPoint;
begin
  case CommandType of
    ct_SetCurrPlayer:  fLastPlayer := P[0]+1;
    ct_SetHumanPlayer: fHumanPlayer := P[0]+1;
    ct_SetHouse:       if InRange(P[0], Low(HouseKaMType), High(HouseKaMType)) then
                       begin
                         RevealCircle(P[1]+1, P[2]+1, fResource.HouseDat[HouseKaMType[P[0]]].Sight);
                         HA := fResource.HouseDat[HouseKaMType[P[0]]].BuildArea;
                         for i:=1 to 4 do for k:=1 to 4 do
                           if HA[i,k]<>0 then
                             if InRange(P[1]+1+k-3, 1, fMapX) and InRange(P[2]+1+i-4, 1, fMapY) then
                               SetOwner(P[1]+1+k-3, P[2]+1+i-4);
                       end;
    ct_SetMapColor:    if InRange(fLastPlayer, 1, MAX_PLAYERS) then
                         fPlayerPreview[fLastPlayer].Color := fResource.Palettes.DefDal.Color32(P[0]);
    ct_CenterScreen:   fPlayerPreview[fLastPlayer].StartingLoc := KMPoint(P[0]+1,P[1]+1);
    ct_SetRoad,
    ct_SetField,
    ct_Set_Winefield:  SetOwner(P[0]+1, P[1]+1);
    ct_SetUnit:        if not (UnitsRemap[P[0]] in [ANIMAL_MIN..ANIMAL_MAX]) then //Skip animals
                       begin
                         SetOwner(P[1]+1, P[2]+1);
                         RevealCircle(P[1]+1, P[2]+1, fResource.UnitDat.UnitsDat[UnitsRemap[P[0]]].Sight);
                       end;
    ct_SetStock:       begin
                         ProcessCommand(ct_SetHouse,[11,P[0]+1,P[1]+1]);
                         ProcessCommand(ct_SetRoad, [   P[0]-2,P[1]+1]);
                         ProcessCommand(ct_SetRoad, [   P[0]-1,P[1]+1]);
                         ProcessCommand(ct_SetRoad, [   P[0]  ,P[1]+1]);
                       end;
    ct_SetGroup:       if InRange(P[0], Low(TroopsRemap), High(TroopsRemap)) and (TroopsRemap[P[0]] <> ut_None) then
                         for i:= 1 to P[5] do
                         begin
                           Loc := GetPositionInGroup2(P[1]+1,P[2]+1,TKMDirection(P[3]+1),i,P[4],fMapX,fMapY,Valid);
                           if Valid then
                           begin
                             SetOwner(Loc.X,Loc.Y);
                             RevealCircle(P[1]+1, P[2]+1, fResource.UnitDat.UnitsDat[UnitsRemap[P[0]]].Sight);
                           end;
                         end;
    ct_ClearUp:        if (fHumanPlayer <> 0) and (fHumanPlayer = fLastPlayer) then
                       begin
                         if P[0] = 255 then
                           for i:=1 to MAX_MAP_SIZE*MAX_MAP_SIZE do
                             fMapPreview[i].Revealed := True
                         else
                           RevealCircle(P[0]+1,P[1]+1,P[2]);
                       end;
  end;
end;


function TMissionParserPreview.LoadMission(const aFileName: string):boolean;
const
  Max_Cmd=6;
var
  FileText: AnsiString;
  CommandText, Param: AnsiString;
  ParamList: array[1..Max_Cmd] of integer;
  k, l, IntParam: integer;
  CommandType: TKMCommandType;
begin
  inherited LoadMission(aFileName);

  fLastPlayer := 0;
  fHumanPlayer := 0;
  FillChar(fMapPreview, SizeOf(fMapPreview), #0);
  FillChar(fPlayerPreview, SizeOf(fPlayerPreview), #0);

  LoadMapData(ChangeFileExt(fMissionFileName,'.map'));
  Result := false;

  FileText := ReadMissionFile(aFileName);
  if FileText = '' then Exit;

  //FileText should now be formatted nicely with 1 space between each parameter/command
  k := 1;
  repeat
    if FileText[k]='!' then
    begin
      for l:=1 to Max_Cmd do
        ParamList[l]:=-1;
      CommandText:='';
      //Extract command until a space
      repeat
        CommandText:=CommandText+FileText[k];
        inc(k);
      until((FileText[k]=#32)or(k>=length(FileText)));

      //Try to make it faster by only processing commands used
      if (CommandText='!SET_CURR_PLAYER')or(CommandText='!SET_HUMAN_PLAYER')or
         (CommandText='!SET_MAP_COLOR')or(CommandText='!CENTER_SCREEN')or
         (CommandText='!SET_STREET')or(CommandText='!SET_FIELD')or
         (CommandText='!SET_WINEFIELD')or(CommandText='!SET_STOCK')or
         (CommandText='!SET_HOUSE')or(CommandText='!CLEAR_UP')or
         (CommandText='!SET_UNIT')or(CommandText='!SET_GROUP') then
      begin
        //Now convert command into type
        CommandType := TextToCommandType(CommandText);
        inc(k);
        //Extract parameters
        for l:=1 to Max_Cmd do
          if (k<length(FileText)) and (FileText[k]<>'!') then
          begin
            Param := '';
            repeat
              Param := Param + FileText[k];
              inc(k);
            until((k >= Length(FileText)) or (FileText[k]='!') or (FileText[k]=#32)); //Until we find another ! OR we run out of data

            //Convert to an integer, if possible
            if TryStrToInt(String(Param), IntParam) then
              ParamList[l] := IntParam;

            if FileText[k]=#32 then inc(k);
          end;
        //We now have command text and parameters, so process them
        ProcessCommand(CommandType,ParamList);
      end;
    end
    else
      inc(k);
  until (k>=length(FileText));
  //Apparently it's faster to parse till file end than check if all details are filled

  Result := (fFatalErrors='');
end;

end.
