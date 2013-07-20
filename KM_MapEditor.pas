unit KM_MapEditor;
{$I KaM_Remake.inc}
interface
uses Classes, Math, SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points, KM_Terrain, KM_Units, KM_RenderPool, KM_TerrainDeposits, KM_TerrainPainter;


type
  TMarkerType = (mtNone, mtDefence, mtRevealFOW);

  TKMMapEdMarker = record
    MarkerType: TMarkerType;
    Owner: TPlayerIndex;
    Index: SmallInt;
  end;

  TKMSelectionMode = (smSelecting, smPasting);
  TKMSelection = class
  private
    fRawRect: TKMRectF; //Cursor selection bounds (can have inverted bounds)
    fRect: TKMRect; //Tile-space selection, at least 1 tile
    fSelectionMode: TKMSelectionMode;
    fBuffer: array of array of record
      Terrain: Byte;
      Height: Byte;
      Rotation: Byte;
      Obj: Byte;
      OldTerrain, OldRotation: Byte; //Only used for map editor
      TerrainKind: TTerrainKind; //Used for brushes
    end;
    procedure SetRawRect(const aValue: TKMRectF);
  public
    property RawRect: TKMRectF read fRawRect write SetRawRect;
    property Rect: TKMRect read fRect write fRect;
    property SelectionMode: TKMSelectionMode read fSelectionMode;
    function IsBufferHasData: Boolean;
    procedure Copy; //Copies the selected are into buffer
    procedure PasteBegin; //Pastes the area from buffer and lets move it with cursor
    procedure PasteApply; //Do the actual paste from buffer to terrain
    procedure PasteCancel;
    //procedure Transform; //Transforms the buffer data ?
    procedure Paint;
  end;

type
  //Designed to store MapEd specific data and methods
  TKMMapEditor = class
  private
    fTerrainPainter: TKMTerrainPainter;
    fDeposits: TKMDeposits;
    fSelection: TKMSelection;
    fRevealers: array [0..MAX_PLAYERS-1] of TKMPointTagList;
    fVisibleLayers: TMapEdLayerSet;
    function GetRevealer(aIndex: Byte): TKMPointTagList;
  public
    ActiveMarker: TKMMapEdMarker;

    RevealAll: array [0..MAX_PLAYERS-1] of Boolean;
    DefaultHuman: TPlayerIndex;
    PlayerHuman: array [0..MAX_PLAYERS - 1] of Boolean;
    PlayerAI: array [0..MAX_PLAYERS - 1] of Boolean;
    constructor Create;
    destructor Destroy; override;
    property TerrainPainter: TKMTerrainPainter read fTerrainPainter;
    property Deposits: TKMDeposits read fDeposits;
    property Selection: TKMSelection read fSelection;
    property Revealers[aIndex: Byte]: TKMPointTagList read GetRevealer;
    property VisibleLayers: TMapEdLayerSet read fVisibleLayers write fVisibleLayers;
    function HitTest(X,Y: Integer): TKMMapEdMarker;
    procedure Update;
    procedure Paint(aLayer: TPaintLayer);
  end;


implementation
uses KM_PlayersCollection, KM_RenderAux, KM_AIDefensePos, KM_UnitGroups;


{ TKMSelection }
procedure TKMSelection.SetRawRect(const aValue: TKMRectF);
begin
  fRawRect := aValue;

  //Convert RawRect values that can be inverted to tilespace Rect
  fRect.Left   := Trunc(Min(fRawRect.Left, fRawRect.Right));
  fRect.Top    := Trunc(Min(fRawRect.Top, fRawRect.Bottom));
  fRect.Right  := Ceil(Max(fRawRect.Left, fRawRect.Right));
  fRect.Bottom := Ceil(Max(fRawRect.Top, fRawRect.Bottom));
end;


function TKMSelection.IsBufferHasData: Boolean;
begin
  Result := Length(fBuffer) > 0;
end;


//Copy terrain section into buffer
procedure TKMSelection.Copy;
var
  I, K: Integer;
  Sx, Sy: Word;
  Bx, By: Word;
begin
  Sx := fRect.Right - fRect.Left;
  Sy := fRect.Bottom - fRect.Top;
  SetLength(fBuffer, Sy, Sx);

  for I := fRect.Top to fRect.Bottom - 1 do
  for K := fRect.Left to fRect.Right - 1 do
  if gTerrain.TileInMapCoords(K+1, I+1, 0) then
  begin
    Bx := K - fRect.Left;
    By := I - fRect.Top;
    fBuffer[By,Bx].Terrain     := gTerrain.Land[I+1, K+1].Terrain;
    fBuffer[By,Bx].Height      := gTerrain.Land[I+1, K+1].Height;
    fBuffer[By,Bx].Rotation    := gTerrain.Land[I+1, K+1].Rotation;
    fBuffer[By,Bx].Obj         := gTerrain.Land[I+1, K+1].Obj;
    fBuffer[By,Bx].OldTerrain  := gTerrain.Land[I+1, K+1].OldTerrain;
    fBuffer[By,Bx].OldRotation := gTerrain.Land[I+1, K+1].OldRotation;
//TODO: Move to TerrainPainter    fBuffer[By,Bx].TerrainKind := fTerrainPainter.TerrainKind[I+1, K+1];
  end;
end;


procedure TKMSelection.PasteBegin;
begin
  //Mapmaker could have changed selection rect, sync it with Buffer size
  fRect.Right := fRect.Left + Length(fBuffer[0]);
  fRect.Bottom := fRect.Top + Length(fBuffer);

  fSelectionMode := smPasting;
end;


procedure TKMSelection.PasteApply;
var
  I, K: Integer;
  Bx, By: Word;
begin
  for I := fRect.Top to fRect.Bottom - 1 do
  for K := fRect.Left to fRect.Right - 1 do
  if gTerrain.TileInMapCoords(K+1, I+1, 0) then
  begin
    Bx := K - fRect.Left;
    By := I - fRect.Top;
    gTerrain.Land[I+1, K+1].Terrain     := fBuffer[By,Bx].Terrain;
    gTerrain.Land[I+1, K+1].Height      := fBuffer[By,Bx].Height;
    gTerrain.Land[I+1, K+1].Rotation    := fBuffer[By,Bx].Rotation;
    gTerrain.Land[I+1, K+1].Obj         := fBuffer[By,Bx].Obj;
    gTerrain.Land[I+1, K+1].OldTerrain  := fBuffer[By,Bx].OldTerrain;
    gTerrain.Land[I+1, K+1].OldRotation := fBuffer[By,Bx].OldRotation;
//TODO: Move to TerrainPainter    fTerrainPainter.TerrainKind[I+1, K+1] := fBuffer[By,Bx].TerrainKind;
  end;

  gTerrain.UpdateLighting(fRect);
  gTerrain.UpdatePassability(fRect);

  fSelectionMode := smSelecting;
end;


procedure TKMSelection.PasteCancel;
begin
  fSelectionMode := smSelecting;
end;


procedure TKMSelection.Paint;
var
  Sx, Sy: Word;
  I, K: Integer;
begin
  Sx := Rect.Right - Rect.Left;
  Sy := Rect.Bottom - Rect.Top;

  case fSelectionMode of
    smSelecting:  begin
                    //fRenderAux.SquareOnTerrain(RawRect.Left, RawRect.Top, RawRect.Right, RawRect.Bottom, $40FFFF00);
                    fRenderAux.SquareOnTerrain(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, $FFFFFF00);
                  end;
    smPasting:    begin
                    for I := 0 to Sy - 1 do
                    for K := 0 to Sx - 1 do
                      fRenderPool.RenderTerrain.RenderTile(fBuffer[I,K].Terrain, Rect.Left+K+1, Rect.Top+I+1, fBuffer[I,K].Rotation);

                    fRenderAux.SquareOnTerrain(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, $FF0000FF);
                  end;
  end;
end;


{ TKMMapEditor }
constructor TKMMapEditor.Create;
var
  I: Integer;
begin
  inherited Create;

  fTerrainPainter := TKMTerrainPainter.Create;
  fDeposits := TKMDeposits.Create;
  fSelection := TKMSelection.Create;

  fVisibleLayers := [mlObjects, mlHouses, mlUnits, mlDeposits];

  for I := Low(fRevealers) to High(fRevealers) do
    fRevealers[I] := TKMPointTagList.Create;
end;


destructor TKMMapEditor.Destroy;
var
  I: Integer;
begin
  FreeAndNil(fTerrainPainter);
  FreeAndNil(fDeposits);
  FreeAndNil(fSelection);

  for I := Low(fRevealers) to High(fRevealers) do
    fRevealers[I].Free;

  inherited;
end;


function TKMMapEditor.GetRevealer(aIndex: Byte): TKMPointTagList;
begin
  Result := fRevealers[aIndex];
end;


function TKMMapEditor.HitTest(X, Y: Integer): TKMMapEdMarker;
var I,K: Integer;
begin
  if mlDefences in fVisibleLayers then
  begin
    for I := 0 to gPlayers.Count - 1 do
      for K := 0 to gPlayers[I].AI.General.DefencePositions.Count - 1 do
        if (gPlayers[I].AI.General.DefencePositions[K].Position.Loc.X = X)
        and (gPlayers[I].AI.General.DefencePositions[K].Position.Loc.Y = Y) then
        begin
          Result.MarkerType := mtDefence;
          Result.Owner := I;
          Result.Index := K;
          Exit;
        end;
  end;

  if mlRevealFOW in fVisibleLayers then
  begin
    for I := 0 to gPlayers.Count - 1 do
      for K := 0 to fRevealers[I].Count - 1 do
        if (fRevealers[I][K].X = X) and (fRevealers[I][K].Y = Y) then
        begin
          Result.MarkerType := mtRevealFOW;
          Result.Owner := I;
          Result.Index := K;
          Exit;
        end;
  end;

  //Else nothing is found
  Result.MarkerType := mtNone;
  Result.Owner := PLAYER_NONE;
  Result.Index := -1;
end;


procedure TKMMapEditor.Update;
begin
  if mlDeposits in VisibleLayers then
    fDeposits.UpdateAreas([rdStone, rdCoal, rdIron, rdGold, rdFish]);

  //todo: if mlNavMesh in VisibleLayers then
    //fAIFields.NavMesh.Init;
end;


procedure TKMMapEditor.Paint(aLayer: TPaintLayer);
var
  I, K: Integer;
  Loc: TKMPoint;
  G: TKMUnitGroup;
  DP: TAIDefencePosition;
begin
  if mlDefences in fVisibleLayers then
  begin
    if aLayer = plCursors then
      for I := 0 to gPlayers.Count - 1 do
      for K := 0 to gPlayers[I].AI.General.DefencePositions.Count - 1 do
      begin
        DP := gPlayers[I].AI.General.DefencePositions[K];
        fRenderPool.RenderSpriteOnTile(DP.Position.Loc, 510 + Byte(DP.Position.Dir), gPlayers[I].FlagColor);
      end;

    if ActiveMarker.MarkerType = mtDefence then
    if InRange(ActiveMarker.Index, 0, gPlayers[ActiveMarker.Owner].AI.General.DefencePositions.Count - 1) then
    begin
      DP := gPlayers[ActiveMarker.Owner].AI.General.DefencePositions[ActiveMarker.Index];
      fRenderAux.CircleOnTerrain(DP.Position.Loc.X, DP.Position.Loc.Y, DP.Radius,
                                 gPlayers[ActiveMarker.Owner].FlagColor AND $20FFFF80,
                                 gPlayers[ActiveMarker.Owner].FlagColor);
    end;
  end;

  if mlRevealFOW in fVisibleLayers then
  for I := 0 to gPlayers.Count - 1 do
  for K := 0 to fRevealers[I].Count - 1 do
  begin
    Loc := fRevealers[I][K];
    case aLayer of
      plTerrain:  fRenderAux.CircleOnTerrain(Loc.X, Loc.Y,
                                           fRevealers[I].Tag[K],
                                           gPlayers[I].FlagColor and $20FFFFFF,
                                           gPlayers[I].FlagColor);
      plCursors:  fRenderPool.RenderSpriteOnTile(Loc,
                      394, gPlayers[I].FlagColor);
    end;
  end;

  if mlCenterScreen in fVisibleLayers then
  for I := 0 to gPlayers.Count - 1 do
  begin
    Loc := gPlayers[I].CenterScreen;
    case aLayer of
      plTerrain:  fRenderAux.SquareOnTerrain(Loc.X - 3, Loc.Y - 2.5,
                                             Loc.X + 2, Loc.Y + 1.5,
                                             gPlayers[I].FlagColor);
      plCursors:  fRenderPool.RenderSpriteOnTile(Loc,
                      391, gPlayers[I].FlagColor);
    end;
  end;

  if mlSelection in fVisibleLayers then
    fSelection.Paint;

  //Show selected group order target
  if MySpectator.Selected is TKMUnitGroup then
  begin
    G := TKMUnitGroup(MySpectator.Selected);
    if G.MapEdOrder.Order <> ioNoOrder then
    begin
      fRenderAux.Quad(G.MapEdOrder.Pos.Loc.X, G.MapEdOrder.Pos.Loc.Y, $40FF00FF);
      fRenderAux.LineOnTerrain(G.Position.X - 0.5, G.Position.Y - 0.5, G.MapEdOrder.Pos.Loc.X - 0.5, G.MapEdOrder.Pos.Loc.Y - 0.5, $FF0000FF);
    end;
  end;
end;


end.
