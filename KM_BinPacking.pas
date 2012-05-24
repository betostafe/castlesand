unit KM_BinPacking;
{$I KaM_Remake.inc}
interface
uses Classes, Types;

type
  TBinRect = record X, Y, Width, Height: Word; end;

  TIndexItem = record
    ID, X, Y: Word;
  end;

  TIndexSizeArray = array of TIndexItem;

  TBinItem = packed record
    Width, Height: Word;
    Sprites: array of record
      SpriteID: Word;
      PosX, PosY: Word;
    end;
  end;

  TBinArray = array of TBinItem;

  TBin = class
    fChild1: TBin; //
    fChild2: TBin;
    fImageID: Word; //Image that is using this bin (0 if unused)
    fRect: TBinRect; //Our dimensions
  public
    constructor Create(aRect: TBinRect; aImageID: Word);
    function Insert(aItem: TIndexItem): TBin; //Return bin that has accepted the sprite, or nil of Bin is full
    function Width: Word;
    function Height: Word;
    procedure GetAllItems(var aItems: TBinItem);
  end;

  TBinManager = class
    fWidth: Word;
    fHeight: Word;
    fBins: TList;
    function CreateNew(aWidth: Word; aHeight: Word): TBin;
  public
    constructor Create(aWidth, aHeight: Word);
    destructor Destroy; override;
    procedure Insert(aItem: TIndexItem);
    procedure GetAllItems(var aOut: TBinArray);
  end;

  procedure BinPack(aItems: TIndexSizeArray; aPad: Byte; var aOut: TBinArray);


implementation
uses KromUtils;


function BinRect(aX, aY, aWidth, aHeight: Word): TBinRect;
begin
  Result.X := aX;
  Result.Y := aY;
  Result.Width := aWidth;
  Result.Height := aHeight;
end;


procedure BinPack(aItems: TIndexSizeArray; aPad: Byte; var aOut: TBinArray);
var
  I, K: Integer;
  BinManager: TBinManager;
begin
  {//Stub method - fit each sprite into own POT texture
  SetLength(aOut, Length(aItems));
  for I := 0 to High(aItems) do
  begin
    aOut[I].Width := MakePOT(aItems[I].X + aPad * 2);
    aOut[I].Height := MakePOT(aItems[I].Y + aPad * 2);

    SetLength(aOut[I].Sprites, 1);

    aOut[I].Sprites[0].SpriteID := aItems[I].ID;
    aOut[I].Sprites[0].PosX := aPad;
    aOut[I].Sprites[0].PosY := aPad;
  end;}

  //Sort Items by size to improve packing efficiency
  for I := 0 to High(aItems) do
    for K := I + 1 to High(aItems) do
      if (aItems[K].X * aItems[K].Y) > (aItems[I].X * aItems[I].Y) then
      begin
        SwapInt(aItems[I].ID, aItems[K].ID);
        SwapInt(aItems[I].X, aItems[K].X);
        SwapInt(aItems[I].Y, aItems[K].Y);
      end;

  BinManager := TBinManager.Create(1024, 1024);
  try
    for I := 0 to High(aItems) do
      if (aItems[I].X * aItems[I].Y <> 0) then
        BinManager.Insert(aItems[I]);

    BinManager.GetAllItems(aOut);
  finally
    BinManager.Free;
  end;
end;


{ TBin }
constructor TBin.Create(aRect: TBinRect; aImageID: Word);
begin
  inherited Create;

  fRect := aRect; //Our dimensions
  fImageID := aImageID;
end;


function TBin.Insert(aItem: TIndexItem): TBin;
begin
  //We can't possibly fit the Item (and our Childs can't either)
  if (aItem.X > fRect.Width) or (aItem.Y > fRect.Height) or (fImageID <> 0) then
  begin
    Result := nil;
    Exit;
  end;

  //If both childs are nil we can stop recursion and accept the Item
  if (fChild1 = nil) and (fChild2 = nil) then
  begin

    //If we can perfectly fit the Item
    if (fRect.Width = aItem.X) and (fRect.Height = aItem.Y) then
    begin
      fImageID := aItem.ID;
      Result := Self;
      Exit;
    end;

    //Choose axis by which to split (Doc suggest we favor largest free area)
    if (fRect.Width - aItem.X) * fRect.Height > (fRect.Height - aItem.Y) * fRect.Width then
    begin
      //Vertical split
      fChild1 := TBin.Create(BinRect(fRect.X, fRect.Y, aItem.X, fRect.Height), 0);
      fChild2 := TBin.Create(BinRect(fRect.X + aItem.X, fRect.Y, fRect.Width - aItem.X, fRect.Height), 0);
    end else
    begin
      //Horizontal split
      fChild1 := TBin.Create(BinRect(fRect.X, fRect.Y, fRect.Width, aItem.Y), 0);
      fChild2 := TBin.Create(BinRect(fRect.X, fRect.Y + aItem.Y, fRect.Width, fRect.Height - aItem.Y), 0);
    end;

    //Now let the Child1 handle the Item
    Result := fChild1.Insert(aItem);
    Exit;
  end;

  //We have both Childs initialized, let them try to accept the Item
  Result := fChild1.Insert(aItem);
  if Result = nil then
    Result := fChild2.Insert(aItem);
end;


function TBin.Width: Word;
begin
  Result := fRect.Width;
end;


function TBin.Height: Word;
begin
  Result := fRect.Height;
end;


//Recursively go through all Bins and collect Image info
procedure TBin.GetAllItems(var aItems: TBinItem);
begin
  if (fChild1 <> nil) and (fChild2 <> nil)  then
  begin
    fChild1.GetAllItems(aItems);
    fChild2.GetAllItems(aItems);
  end
  else
    if fImageID <> 0 then
    begin
      SetLength(aItems.Sprites, Length(aItems.Sprites) + 1);
      aItems.Sprites[High(aItems.Sprites)].SpriteID := fImageID;
      aItems.Sprites[High(aItems.Sprites)].PosX := fRect.X;
      aItems.Sprites[High(aItems.Sprites)].PosY := fRect.Y;
    end;
end;


{ TBinManager }
constructor TBinManager.Create(aWidth, aHeight: Word);
begin
  inherited Create;

  Assert((aWidth > 0) and (aHeight > 0));
  fWidth := aWidth;
  fHeight := aHeight;

  fBins := TList.Create;
end;


destructor TBinManager.Destroy;
var
  I: Integer;
begin
  for I := 0 to fBins.Count - 1 do
    TBin(fBins[I]).Free;

  fBins.Free;
  inherited;
end;


function TBinManager.CreateNew(aWidth: Word; aHeight: Word): TBin;
begin
  Result := TBin.Create(BinRect(0, 0, aWidth, aHeight), 0);
  fBins.Add(Result);
end;


procedure TBinManager.Insert(aItem: TIndexItem);
var
  I: Integer;
  B: TBin;
begin
  //Check all Bins (older Bins may still have space for small items)
  for I := 0 to fBins.Count - 1 do
  begin
    //Try to insert into a bin
    B := TBin(fBins[I]).Insert(aItem);
    if B <> nil then
      Exit;
  end;

  //Create new Bin
  if (aItem.X > fWidth) or (aItem.Y > fHeight) then
    //Create new Bin especially for this big item
    B := CreateNew(MakePOT(aItem.X), MakePOT(aItem.Y))
  else
    //Use standard Bin size
    B := CreateNew(fWidth, fHeight);

  B.Insert(aItem);
  Assert(B <> nil);
end;


//Write all Bins and images positions into array
procedure TBinManager.GetAllItems(var aOut: TBinArray);
var
  I: Integer;
begin
  //Recursively scan all Bins
  SetLength(aOut, fBins.Count);
  for I := 0 to fBins.Count - 1 do
  begin
    TBin(fBins[I]).GetAllItems(aOut[I]);
    aOut[I].Width := TBin(fBins[I]).Width;
    aOut[I].Height := TBin(fBins[I]).Height;
  end;
end;


end.
