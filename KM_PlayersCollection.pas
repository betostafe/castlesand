unit KM_PlayersCollection;
interface
uses
  Windows, Classes, KromUtils, Math, SysUtils,
  KM_Units, KM_Houses, KM_Defaults, KM_Player, KM_PlayerAI;

type
  TMissionMode = (mm_Normal, mm_Tactic);

type
  TKMAllPlayers = class
  private
    fPlayerCount:integer;
  public
    Player:array[1..MAX_PLAYERS] of TKMPlayerAssets;
    PlayerAI:array[1..MAX_PLAYERS] of TKMPlayerAI;
    Selected: TObject;
  public
    constructor Create(PlayerCount:integer);
    destructor Destroy; override;
  public
    property PlayerCount:integer read fPlayerCount;
    function HousesHitTest(X, Y: Integer): TKMHouse;
    function UnitsHitTest(X, Y: Integer): TKMUnit;
    function HitTest(X, Y: Integer):boolean;
    function GetUnitCount():integer;
  public
    procedure Save;
    procedure Load;
    procedure UpdateState(Tick:cardinal);
    procedure Paint;
  end;

var
  fPlayers: TKMAllPlayers;
  MyPlayer: TKMPlayerAssets; //shortcut to access players player
  MissionMode: TMissionMode;

  
implementation
uses KM_CommonTypes;


{TKMAllPlayers}
constructor TKMAllPlayers.Create(PlayerCount:integer);
var i:integer;
begin
  fLog.AssertToLog(InRange(PlayerCount,1,MAX_PLAYERS),'PlayerCount exceeded');

  fPlayerCount:=PlayerCount; //Used internally
  for i:=1 to fPlayerCount do begin
    Player[i]:=TKMPlayerAssets.Create(TPlayerID(i));
    PlayerAI[i]:=TKMPlayerAI.Create(Player[i]);
  end;
end;

destructor TKMAllPlayers.Destroy;
var i:integer;
begin
  for i:=1 to fPlayerCount do begin
    FreeAndNil(Player[i]);
    FreeAndNil(PlayerAI[i]);
  end;

  MyPlayer:=nil;
  Selected:=nil;
  inherited;
end;

function TKMAllPlayers.HousesHitTest(X, Y: Integer): TKMHouse;
var i:integer;
begin
  Result:=nil;
  for i:=1 to fPlayerCount do begin
    Result:= Player[i].HousesHitTest(X,Y);
    if Result<>nil then Break; //else keep on testing
  end;
end;


function TKMAllPlayers.UnitsHitTest(X, Y: Integer): TKMUnit;
var i:integer;
begin
  Result:=nil;
  for i:=1 to fPlayerCount do begin
    Result:= Player[i].UnitsHitTest(X,Y);
    if Result<>nil then Break; //else keep on testing
  end;
end;


{HitTest for houses/units altogether}
function TKMAllPlayers.HitTest(X, Y: Integer):boolean;
var H:TKMHouse;
begin
  //Houses have priority over units, so you can't select an occupant.
  //However, this is only true if the house is built
  H := MyPlayer.HousesHitTest(CursorXc, CursorYc);

  if (H<>nil)and(H.GetBuildingState in [hbs_Stone,hbs_Done]) then
    fPlayers.Selected := H
  else
    fPlayers.Selected := MyPlayer.UnitsHitTest(CursorXc, CursorYc);
  if fPlayers.Selected = nil then
    fPlayers.Selected := H;

  Result := fPlayers.Selected <> nil;
end;


//Get total unit count
function TKMAllPlayers.GetUnitCount():integer;
var i:integer;
begin
  Result:=0;
  for i:=1 to fPlayerCount do
    inc(Result,Player[i].GetUnitCount);
end;


procedure TKMAllPlayers.Save;
var i:word;
begin
  for i:=1 to fPlayerCount do
  begin
    Player[i].Save;
    PlayerAI[i].Save; //Saves AI stuff
  end;
end;


procedure TKMAllPlayers.Load;
begin
  //Load
end;


procedure TKMAllPlayers.UpdateState(Tick:cardinal);
var i:word;
begin
  for i:=1 to fPlayerCount do
    Player[i].UpdateState;

  //This is not ajoined with previous loop since it can result in StopGame which flushes all data
  for i:=1 to fPlayerCount do
    if (Tick+i) mod 20 = 0 then //Do only one player per Tick
      PlayerAI[i].UpdateState;
end;


procedure TKMAllPlayers.Paint;
var i:integer;
begin
  for i:=1 to fPlayerCount do
    Player[i].Paint;
end;




end.
