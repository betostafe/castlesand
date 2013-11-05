unit KM_ResourcePalettes;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils,
  KM_CommonClasses, KM_Defaults;


type
  //There are 9 palette files: Map, Pal0-5, Setup, Setup2, gradient, 2lbm palettes
  TKMPal = (
    pal_map,
    pal_0, //pal_1, pal_2, pal_3, pal_4, pal_5, unused since we change brightness with OpenGL overlay
    pal_set,
    pal_set2,
    pal_lin,
    pal2_mapgold,
    pal2_setup);

  //Individual palette
  TKMPalData = class
    fData: array [0..255,1..3] of Byte;
  public
    procedure LoadFromFile(const aFileName: string);
    function Color32(aIdx: Byte): Cardinal;
  end;

  //All the palettes
  TKMPalettes = class
  private
    fPalData: array [TKMPal] of TKMPalData;
    function GetPalData(aIndex: TKMPal): TKMPalData;
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadPalettes;
    property PalData[aIndex: TKMPal]: TKMPalData read GetPalData; default;
    function DefDal: TKMPalData; //Default palette for the game
    function PalFile(aIndex: TKMPal):string;
  end;


implementation


const
  //Palette filenames, except pal_lin which is generated proceduraly
  PalFiles: array [TKMPal] of string = (
    'map.bbm',
    'pal0.bbm', //'pal1.bbm', 'pal2.bbm', 'pal3.bbm', 'pal4.bbm', 'pal5.bbm', unused
    'setup.bbm',
    'setup2.bbm',
    'linear',
    'mapgold.lbm',
    'setup.lbm');


{ TKMPalData }
function TKMPalData.Color32(aIdx: Byte): Cardinal;
begin
  //Index 0 means that pixel is transparent
  if aIdx = 0 then
    Result := $00000000
  else
    Result := fData[aIdx,1] + fData[aIdx,2] shl 8 + fData[aIdx,3] shl 16 or $FF000000;
end;


procedure TKMPalData.LoadFromFile(const aFileName: string);
var
  i:integer;
  S:TKMemoryStream;
begin
  if FileExists(aFileName) then
  begin
    S := TKMemoryStream.Create;
    S.LoadFromFile(aFileName);
    S.Seek(48, soFromBeginning);
    S.Read(fData, SizeOf(fData)); //768bytes
    S.Free;
  end else
    for i:=0 to 255 do //Gradiant palette for missing files (used by pal_lin)
    begin
      fData[i,1] := i;
      fData[i,2] := i;
      fData[i,3] := i;
    end;
end;


{ TKMPalettes }
constructor TKMPalettes.Create;
var i:TKMPal;
begin
  inherited Create;

  for i:=Low(TKMPal) to High(TKMPal) do
    fPalData[i] := TKMPalData.Create;
end;


destructor TKMPalettes.Destroy;
var i:TKMPal;
begin
  for i:=Low(TKMPal) to High(TKMPal) do
    fPalData[i].Free;

  inherited;
end;


function TKMPalettes.DefDal: TKMPalData;
begin
  //Default palette to use when generating full-color RGB textures
  Result := fPalData[pal_0];
end;


function TKMPalettes.GetPalData(aIndex: TKMPal): TKMPalData;
begin
  Result := fPalData[aIndex];
end;


procedure TKMPalettes.LoadPalettes;
var i:TKMPal;
begin
  for i:=Low(TKMPal) to High(TKMPal) do
    fPalData[i].LoadFromFile(ExeDir+'data' + PathDelim + 'gfx' + PathDelim +PalFiles[i]);
end;


function TKMPalettes.PalFile(aIndex: TKMPal): string;
begin
  Result := PalFiles[aIndex];
end;


end.