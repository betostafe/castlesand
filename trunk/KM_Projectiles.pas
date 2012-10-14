unit KM_Projectiles;
{$I KaM_Remake.inc}
interface
uses Classes, SysUtils, Math, KromUtils, KM_Utils, KM_Defaults, KM_CommonClasses, KM_Units, KM_Houses, KM_Points, KM_Terrain;


{Projectiles in-game: arrows, bolts, rocks, etc..}
//Once launched they are on their own
type
  TKMProjectiles = class
  private
    fItems: array of record //1..n
      fScreenStart:TKMPointF; //Screen-space trajectory start
      fScreenEnd:TKMPointF;   //Screen-space trajectory end

      fAim:TKMPointF;  //Where we were aiming to hit
      fTarget:TKMPointF; //Where projectile will hit
      fShotFrom:TKMPointF; //Where the projectile was launched from

      fType:TProjectileType; //type of projectile (arrow, bolt, rocks, etc..)
      fOwner:TPlayerIndex; //The ID of the player who launched the projectile, used for kill statistics
      fSpeed:single; //Each projectile speed may vary a little bit
      fArc:single; //Thats how high projectile will go along parabola (varies a little more)
      fPosition:single; //Projectiles position along the route Start>>End
      fLength:single; //Route length to look-up for hit
      fMaxLength:single; //Maximum length the archer could have shot
    end;

    function AddItem(aStart,aAim,aEnd:TKMPointF; aSpeed, aArc, aMaxLength:single; aProjType:TProjectileType; aOwner:TPlayerIndex):word;
    procedure RemItem(aIndex: integer);
    function ProjectileVisible(aIndex:integer):boolean;
  public
    constructor Create;
    function AimTarget(aStart:TKMPointF; aTarget:TKMUnit; aProjType:TProjectileType; aOwner:TPlayerIndex; aMaxRange,aMinRange:single):word; overload;
    function AimTarget(aStart:TKMPointF; aTarget:TKMHouse; aProjType:TProjectileType; aOwner:TPlayerIndex; aMaxRange,aMinRange:single):word; overload;

    procedure UpdateState;
    procedure Paint;

    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
  end;


implementation
uses KM_Sound, KM_RenderPool, KM_RenderAux, KM_PlayersCollection, KM_Resource;


const
  ProjectileLaunchSounds:array[TProjectileType] of TSoundFX = (sfx_BowShoot, sfx_CrossbowShoot, sfx_None, sfx_RockThrow);
  ProjectileHitSounds:   array[TProjectileType] of TSoundFX = (sfx_ArrowHit, sfx_ArrowHit, sfx_ArrowHit, sfx_None);
  ProjectileSpeeds:array[TProjectileType] of single = (0.75, 0.75, 0.6, 0.8);
  ProjectileArcs:array[TProjectileType,1..2] of single = ((1.6, 0.5), (1.4, 0.4), (2.5, 1), (1.2, 0.2)); //Arc curve and random fraction
  ProjectileJitter:array[TProjectileType] of single = (0.26, 0.29, 0.26, 0.2); //Fixed Jitter added every time
  ProjectileJitterHouse:array[TProjectileType] of single = (0.6, 0.6, 0.6, 0); //Fixed Jitter added every time
  //Jitter added according to target's speed (moving target harder to hit) Note: Walking = 0.1, so the added jitter is 0.1*X
  ProjectilePredictJitter:array[TProjectileType] of single = (2, 2, 2, 3);


{ TKMProjectiles }
constructor TKMProjectiles.Create;
begin
  inherited Create;
  //Nothing here yet
end;


procedure TKMProjectiles.RemItem(aIndex: integer);
begin
  fItems[aIndex].fSpeed := 0;
end;


function TKMProjectiles.AimTarget(aStart:TKMPointF; aTarget:TKMUnit; aProjType:TProjectileType; aOwner:TPlayerIndex; aMaxRange,aMinRange:single):word;
var
  TargetVector,Target,TargetPosition:TKMPointF;
  A,B,C,D:single;
  TimeToHit, Time1, Time2, DistanceToHit, DistanceInRange: single;
  Jitter, Speed, Arc:single;
  U:TKMUnit;
begin
  //Now we know projectiles speed and aim, we can predict where target will be at the time projectile hits it

  //I wonder if medieval archers knew about vectors and quadratic equations

  TargetPosition.X := (aTarget.PositionF.X - aStart.X);
  TargetPosition.Y := (aTarget.PositionF.Y - aStart.Y);
  TargetVector := aTarget.GetMovementVector;

  { Target.X := TargetPosition.X + TargetVector.X * Time;
    Target.Y := TargetPosition.Y + TargetVector.Y * Time;

    FlightDistance := ArrowSpeed * Time;

    sqr(Target.X)+sqr(Target.Y) = sqr(FlightDistance);

    sqr(TargetPosition.X + TargetVector.X * Time) + sqr(TargetPosition.Y + TargetVector.Y * Time) = sqr(ArrowSpeed * Time)

    sqr(TargetPosition.X) + 2 * Time * TargetPosition.X * TargetVector.X + sqr(Time) * sqr(TargetVector.X) +
    sqr(TargetPosition.Y) + 2 * Time * TargetPosition.Y * TargetVector.Y + sqr(Time) * sqr(TargetVector.Y) =
    sqr(ArrowSpeed) * sqr(Time)

    sqr(Time) * (sqr(TargetVector.X) + sqr(TargetVector.Y) - sqr(ArrowSpeed)) +
    2 * Time * (TargetPosition.X * TargetVector.X + TargetPosition.Y * TargetVector.Y) +
    sqr(TargetPosition.X) + sqr(TargetPosition.Y) = 0

    //Lets try to solve this quadratic equation
    //ATT + BT + C = 0
    //by using formulae X = (-B +- sqrt(B*B - 4*A*C)) / 2*A
    A = sqr(TargetVector.X) + sqr(TargetVector.Y) - sqr(ArrowSpeed)
    B = 2 * (TargetPosition.X * TargetVector.X + TargetPosition.Y * TargetVector.Y)
    C = sqr(TargetPosition.X) + sqr(TargetPosition.Y) }

  Speed := ProjectileSpeeds[aProjType] + KaMRandomS(0.05);

  A := sqr(TargetVector.X) + sqr(TargetVector.Y) - sqr(Speed);
  B := 2 * (TargetPosition.X * TargetVector.X + TargetPosition.Y * TargetVector.Y);
  C := sqr(TargetPosition.X) + sqr(TargetPosition.Y);

  D := sqr(B) - 4 * A * C;

  if (D >= 0) and (A <> 0) then
  begin
    Time1 := (-B + sqrt(D)) / (2 * A);
    Time2 := (-B - sqrt(D)) / (2 * A);

    //Choose smallest positive time
    if (Time1 > 0) and (Time2 > 0) then
      TimeToHit := Math.min(Time1, Time2)
    else
    if (Time1 < 0) and (Time2 < 0) then
      TimeToHit := 0
    else
      TimeToHit := Math.max(Time1, Time2);
  end
  else
    TimeToHit := 0;

  if TimeToHit <> 0 then
  begin
    Jitter := ProjectileJitter[aProjType]
            + KMLength(KMPointF(0,0), TargetVector) * ProjectilePredictJitter[aProjType];

    //Calculate the target position relative to start position (the 0;0)
    Target.X := TargetPosition.X + TargetVector.X*TimeToHit + KaMRandomS(Jitter);
    Target.Y := TargetPosition.Y + TargetVector.Y*TimeToHit + KaMRandomS(Jitter);

    //We can try and shoot at a target that is moving away,
    //but the arrows can't flight any further than their max_range
    DistanceToHit := GetLength(Target.X, Target.Y);
    DistanceInRange := EnsureRange(DistanceToHit, aMinRange, aMaxRange);
    Target.X := aStart.X + Target.X / DistanceToHit * DistanceInRange;
    Target.Y := aStart.Y + Target.Y / DistanceToHit * DistanceInRange;

    //Calculate the arc, less for shorter flights
    Arc := ((DistanceInRange-aMinRange)/(aMaxRange-aMinRange))*(ProjectileArcs[aProjType, 1] + KaMRandomS(ProjectileArcs[aProjType, 2]));

    //Check whether this predicted target will hit a friendly unit
    if fTerrain.TileInMapCoords(Round(Target.X), Round(Target.Y)) then //Arrows may fly off map, UnitsHitTest doesn't like negative coordinates
    begin
      U := fTerrain.UnitsHitTest(Round(Target.X), Round(Target.Y));
      if (U <> nil) and (fPlayers.CheckAlliance(aOwner,U.Owner) = at_Ally) then
        Target := aTarget.PositionF; //Shoot at the target's current position instead
    end;

    Result := AddItem(aStart, aTarget.PositionF, Target, Speed, Arc, aMaxRange, aProjType, aOwner);
  end else
    Result := 0;
end;


function TKMProjectiles.AimTarget(aStart:TKMPointF; aTarget:TKMHouse; aProjType:TProjectileType; aOwner:TPlayerIndex; aMaxRange,aMinRange:single):word;
var
  Speed, Arc: single;
  DistanceToHit, DistanceInRange: single;
  Aim, Target: TKMPointF;
begin
  Speed := ProjectileSpeeds[aProjType] + KaMRandomS(0.05);

  Aim := KMPointF(aTarget.GetRandomCellWithin);
  Target.X := Aim.X + KaMRandomS(ProjectileJitterHouse[aProjType]); //So that arrows were within house area, without attitude to tile corners
  Target.Y := Aim.Y + KaMRandomS(ProjectileJitterHouse[aProjType]);

  //Calculate the arc, less for shorter flights
  DistanceToHit := GetLength(Target.X, Target.Y);
  DistanceInRange := EnsureRange(DistanceToHit, aMinRange, aMaxRange);
  Arc := (DistanceInRange/DistanceToHit)*(ProjectileArcs[aProjType, 1] + KaMRandomS(ProjectileArcs[aProjType, 2]));

  Result := AddItem(aStart, Aim, Target, Speed, Arc, aMaxRange, aProjType, aOwner);
end;


{ Return flight time (archers like to know when they hit target before firing again) }
function TKMProjectiles.AddItem(aStart,aAim,aEnd:TKMPointF; aSpeed,aArc,aMaxLength:single; aProjType:TProjectileType; aOwner:TPlayerIndex):word;
const //TowerRock position is a bit different for reasons said below
  OffsetX: array [TProjectileType] of Single = (0.5, 0.5, 0.5, -0.25); //Recruit stands in entrance, Tower middleline is X-0.75
  OffsetY: array [TProjectileType] of Single = (0.2, 0.2, 0.2, -0.5); //Add towers height
var
  I: Integer;
begin
  I := -1;
  repeat
    inc(I);
    if I >= length(fItems) then
      SetLength(fItems, I+8); //Add new
  until(fItems[I].fSpeed = 0);

  //Fill in basic info
  fItems[I].fType   := aProjType;
  fItems[I].fSpeed  := aSpeed;
  fItems[I].fArc    := aArc;
  fItems[I].fOwner  := aOwner;
  fItems[I].fAim    := aAim;
  //Don't allow projectile to land off map, (we use fTaret for hit tests, FOW, etc.) but on borders is fine
  fItems[I].fTarget.X := EnsureRange(aEnd.X, 0, fTerrain.MapX-0.01);
  fItems[I].fTarget.Y := EnsureRange(aEnd.Y, 0, fTerrain.MapY-0.01);
  fItems[I].fShotFrom := aStart;

  fItems[I].fScreenStart.X := aStart.X + OffsetX[aProjType];
  fItems[I].fScreenStart.Y := fTerrain.FlatToHeight(aStart).Y + OffsetY[aProjType];
  fItems[I].fScreenEnd.X := fItems[I].fTarget.X + 0.5; //projectile hits on Unit's chest height
  fItems[I].fScreenEnd.Y := fTerrain.FlatToHeight(fItems[I].fTarget).Y + 0.5;

  fItems[I].fPosition := 0; //projectile position on its route
  fItems[I].fLength   := KMLength(fItems[I].fScreenStart, fItems[I].fScreenEnd); //route length
  fItems[I].fMaxLength:= aMaxLength;

  if (MyPlayer.FogOfWar.CheckTileRevelation(KMPointRound(aStart).X, KMPointRound(aStart).Y, true) >= 255) then
    fSoundLib.Play(ProjectileLaunchSounds[aProjType], aStart);

  Result := round(fItems[I].fLength / fItems[I].fSpeed);
end;


//Update all items positions and kill some targets
procedure TKMProjectiles.UpdateState;
const HTicks = 6; //The number of ticks before hitting that an arrow will make the hit noise
var i:integer; U:TKMUnit; H:TKMHouse;
    Damage : Smallint;
begin
  for i:=0 to length(fItems)-1 do
    with fItems[i] do
      if fSpeed <> 0 then
      begin
        fPosition := fPosition + fSpeed;

        //Will hit the target in X..X-1 ticks (this ensures it only happens once)
        //Can't use InRange cos it might get called twice due to <= X <= comparison
        if MyPlayer.FogOfWar.CheckRevelation(fTarget, true) >= 255 then
          if (fLength - HTicks*fSpeed <= fPosition) and (fPosition < fLength - (HTicks-1)*fSpeed) then
            fSoundLib.Play(ProjectileHitSounds[fType], fTarget);

        if fPosition >= fLength then
        begin
          U := fTerrain.UnitsHitTestF(fTarget);
          //Projectile can miss depending on the distance to the unit
          if (U = nil) or ((1 - Math.min(KMLength(U.PositionF, fTarget), 1)) > KaMRandom) then
          begin
            case fType of
              pt_Arrow,
              pt_SlingRock,
              pt_Bolt:      if (U <> nil) and not U.IsDeadOrDying and U.Visible and not (U is TKMUnitAnimal)
                            //Can't hit units past max range because that's unintuitive/confusing to player
                            and (KMLengthSqr(fShotFrom, U.PositionF) <= Sqr(fMaxLength)) then
                            begin
                              Damage := 0;
                              if fType = pt_Arrow then Damage := fResource.UnitDat[ut_Bowman].Attack;
                              if fType = pt_Bolt then Damage := fResource.UnitDat[ut_Arbaletman].Attack;
                              if fType = pt_SlingRock then Damage := fResource.UnitDat[ut_Slingshot].Attack;
                              Damage := Damage div Math.max(fResource.UnitDat[U.UnitType].GetDefenceVsProjectiles, 1); //Not needed, but animals have 0 defence
                              if (FRIENDLY_FIRE or (fPlayers.CheckAlliance(fOwner, U.Owner)= at_Enemy))
                              and (Damage >= KaMRandom(101))
                              and U.HitPointsDecrease(1) then
                                fPlayers[fOwner].Stats.UnitKilled(U.UnitType);
                            end
                            else
                            begin
                              H := fPlayers.HousesHitTest(Round(fTarget.X), Round(fTarget.Y));
                              if (H <> nil)
                              and (FRIENDLY_FIRE or (fPlayers.CheckAlliance(fOwner, H.Owner)= at_Enemy))
                              and H.AddDamage(1) then //House was destroyed
                                fPlayers[fOwner].Stats.HouseDestroyed(H.HouseType);
                            end;
              pt_TowerRock: if (U <> nil) and not U.IsDeadOrDying and U.Visible
                            and not (U is TKMUnitAnimal)
                            and (FRIENDLY_FIRE or (fPlayers.CheckAlliance(fOwner, U.Owner)= at_Enemy))
                            and U.HitPointsDecrease(U.HitPointsMax) then //Instant death
                              fPlayers[fOwner].Stats.UnitKilled(U.UnitType);
            end;
          end;
          RemItem(i);
        end;
      end;
end;


//Test wherever projectile is visible (used by rocks thrown from Towers)
function TKMProjectiles.ProjectileVisible(aIndex:integer):boolean;
begin
  if (fItems[aIndex].fType = pt_TowerRock) 
  and ((fItems[aIndex].fScreenEnd.Y - fItems[aIndex].fScreenStart.Y) < 0) then
    Result := fItems[aIndex].fPosition >= 0.2 //fly behind a Tower
  else
    Result := True;
end;


procedure TKMProjectiles.Paint;
var
  i:integer;
  MixValue,MixValueMax:single;
  MixArc:single; //mix Arc shape
  P: TKMPointF; //Arrows and bolts send 2 points for head and tail
  PTileBased: TKMPointF;
  Dir: TKMDirection;
begin
  for i:=0 to length(fItems)-1 do
    if (fItems[i].fSpeed<>0) and ProjectileVisible(i) then
    begin

      MixValue := fItems[i].fPosition / fItems[i].fLength; // 0 >> 1
      MixValueMax := fItems[i].fPosition / fItems[i].fMaxLength; // 0 >> 1
      P := KMLerp(fItems[i].fScreenStart, fItems[i].fScreenEnd, MixValue);
      PTileBased := KMLerp(fItems[i].fShotFrom, fItems[i].fTarget, MixValue);
      case fItems[i].fType of
        pt_Arrow, pt_SlingRock, pt_Bolt:
          begin
            MixArc := sin(MixValue*pi);   // 0 >> 1 >> 0 Parabola
            //Looks better moved up, launches from the bow not feet and lands in target's body
            P.Y := P.Y - fItems[i].fArc * MixArc - 0.4;
            Dir := KMGetDirection(fItems[i].fScreenStart, fItems[i].fScreenEnd);
            fRenderPool.AddProjectile(fItems[i].fType, P, PTileBased, Dir, MixValueMax);
          end;

        pt_TowerRock:
          begin
            MixArc := cos(MixValue*pi/2); // 1 >> 0      Half-parabola
            //Looks better moved up, lands on the target's body not at his feet
            P.Y := P.Y - fItems[i].fArc * MixArc - 0.4;
            fRenderPool.AddProjectile(fItems[i].fType, P, PTileBased, dir_N, MixValue); //Direction will be ignored
          end;
      end;

      if SHOW_PROJECTILES then begin
        fRenderAux.Projectile(fItems[i].fScreenStart.X,
                              fItems[i].fScreenStart.Y,
                              fItems[i].fScreenEnd.X,
                              fItems[i].fScreenEnd.Y);

        fRenderAux.Projectile(fItems[i].fAim.X,
                              fItems[i].fAim.Y,
                              fItems[i].fTarget.X,
                              fItems[i].fTarget.Y);
      end;
    end;
end;


procedure TKMProjectiles.Save(SaveStream:TKMemoryStream);
var i, Count:integer;
begin
  SaveStream.Write('Projectiles');

  Count := 0;
  for i:=0 to length(fItems)-1 do
    if fItems[i].fSpeed <> 0 then inc(Count);
  SaveStream.Write(Count);

  for i:=0 to length(fItems)-1 do
    if fItems[i].fSpeed <> 0 then
      SaveStream.Write(fItems[i], SizeOf(fItems[i]));
end;


procedure TKMProjectiles.Load(LoadStream:TKMemoryStream);
var
  i,Count:integer;
begin
  LoadStream.ReadAssert('Projectiles');

  LoadStream.Read(Count);
  SetLength(fItems, Count);

  for i:=0 to Count-1 do
    LoadStream.Read(fItems[i], SizeOf(fItems[i]));
end;


end.
