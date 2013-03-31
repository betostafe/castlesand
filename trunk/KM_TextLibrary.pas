unit KM_TextLibrary;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math, StrUtils, KromUtils, KM_Defaults;


const
  //NAME__## means that this const defines first element of some range that is ## long
  //TX_UNITS_NAMES__29 = 70; //todo: add animal unit names

  //Load text IDs from this include file that is managed by the Translation Manager
  {$I KM_TextIDs.inc}

  //Supposed for places where some text must be placed
  //That string was used in all Synetic games for missing texts
  NO_TEXT = '<<<LEER>>>';

type
  TTextLibrary = class
  private
    fLocale: AnsiString;
    fFallbackLocale: AnsiString;
    GameStrings: TAnsiStringArray;
    MissionStrings: TAnsiStringArray; //Strings used in a mission
    procedure LoadLIBXFile(FilePath: string; aFirstIndex: Word; var aArray: TAnsiStringArray; aOverwrite: Boolean);
    procedure ExportTextLibrary(aLibrary: array of AnsiString; aFileName: string);
    function GetTexts(aIndex: Word): AnsiString;
  public
    constructor Create(aLibPath: string; aLocale: AnsiString);

    function AppendCampaign(aFileName: string): Word;
    procedure LoadMissionStrings(aFileName: string);

    function GetMissionString(aIndex: Word): AnsiString;

    property Texts[aIndex: Word]: AnsiString read GetTexts; default;

    procedure ExportTextLibraries;
  end;


var
  fTextLibrary: TTextLibrary;


implementation
uses KM_Log, KM_Locales;


{ TTextLibrary }
constructor TTextLibrary.Create(aLibPath: string; aLocale: AnsiString);
begin
  inherited Create;

  //Remember preferred locale, it will remain constant until reinit
  fLocale := aLocale;
  fFallbackLocale := fLocales.GetLocale(aLocale).FallbackLocale;

  //We load the English LIBX by default, then overwrite it with the selected language (this way missing strings are in English)
  LoadLIBXFile(aLibPath+'text.'+DEFAULT_LOCALE+'.libx', 0, GameStrings, False); //Initialize with English strings

  if (fFallbackLocale <> '') and FileExists(aLibPath+'text.'+fFallbackLocale+'.libx') then
    LoadLIBXFile(aLibPath+'text.'+fFallbackLocale+'.libx', 0, GameStrings, True);

  if (fLocale <> DEFAULT_LOCALE) and FileExists(aLibPath+'text.'+fLocale+'.libx') then
    LoadLIBXFile(aLibPath+'text.'+fLocale+'.libx', 0, GameStrings, True); //Overwrite with selected locale

  fLog.AddTime('TextLib init done');
end;


{LIBX files consist of lines. Each line has an index and a text. Lines without index are skipped}
procedure TTextLibrary.LoadLIBXFile(FilePath: string; aFirstIndex: Word; var aArray: TAnsiStringArray; aOverwrite: Boolean);
var
  aStringList: TStringList;
  I: Integer;
  s: AnsiString;
  firstDelimiter: Integer;
  ID, MaxID: Integer;
begin
  if not FileExists(FilePath) then Exit;

  aStringList := TStringList.Create;
  aStringList.LoadFromFile(FilePath);

  //First line is empty or comment and could have first 3 bytes Unicode Byte-Order Mark (BOM)
  s := aStringList[1];
  if Copy(s, 1, 6) <> 'MaxID:' then Exit;

  firstDelimiter := Pos(':', s);
  if not TryStrToInt(RightStr(s, Length(s) - firstDelimiter), MaxID) then Exit;

  if not aOverwrite then
    SetLength(aArray, aFirstIndex + MaxID + 1);

  for I := 0 to aStringList.Count - 1 do
  begin
    s := aStringList[I];

    //Get string index and skip erroneous lines
    firstDelimiter := Pos(':', s);
    if firstDelimiter = 0 then Continue;
    if not TryStrToInt(TrimLeft(LeftStr(s, firstDelimiter - 1)), ID) then Continue;
    if ID > MaxID then Continue;

    s := RightStr(s, Length(s) - firstDelimiter);
    //Required characters that can't be stored in plain text
    s := StringReplace(s, '\n', eol, [rfReplaceAll, rfIgnoreCase]); //EOL
    s := StringReplace(s, '\\', '\', [rfReplaceAll, rfIgnoreCase]); //Slash
    if not aOverwrite or (s <> '') then aArray[aFirstIndex + ID] := s;
  end;

  aStringList.Free; //Must free at last to avoid memory-leaks
end;


//Campaign description and briefings get appended to main list
//as they are used in Main Menu right away
function TTextLibrary.AppendCampaign(aFileName: string): Word;
begin
  Assert(Pos('%s', aFileName) <> 0, 'Input string must be formatted properly with an %s');

  Result := Length(GameStrings);
  LoadLIBXFile(Format(aFileName, [DEFAULT_LOCALE]), Result, GameStrings, False);
  
  if (fFallbackLocale <> '') and FileExists(Format(aFileName, [fFallbackLocale])) then
    LoadLIBXFile(Format(aFileName, [fFallbackLocale]), Result, GameStrings, True);

  if (fLocale <> DEFAULT_LOCALE) and FileExists(Format(aFileName, [fLocale])) then
    LoadLIBXFile(Format(aFileName, [fLocale]), Result, GameStrings, True);
end;


//Load mission strings into separate array, as they get reloaded for each mission
//Only one set of mission strings is required at a time
procedure TTextLibrary.LoadMissionStrings(aFileName: string);
begin
  LoadLIBXFile(Format(aFileName, [DEFAULT_LOCALE]), 0, MissionStrings, False);

  if (fFallbackLocale <> '') and FileExists(Format(aFileName, [fFallbackLocale])) then
    LoadLIBXFile(Format(aFileName, [fFallbackLocale]), 0, MissionStrings, True);

  if (fLocale <> DEFAULT_LOCALE) and FileExists(Format(aFileName, [fLocale])) then
    LoadLIBXFile(Format(aFileName, [fLocale]), 0, MissionStrings, True);
end;


function TTextLibrary.GetTexts(aIndex: word): AnsiString;
begin
  if aIndex < Length(GameStrings) then
    Result := GameStrings[aIndex]
  else
    Result := '~~~String '+IntToStr(aIndex)+' out of range!~~~';
end;


function TTextLibrary.GetMissionString(aIndex: word): AnsiString;
begin
  if aIndex < Length(MissionStrings) then
    Result := MissionStrings[aIndex]
  else
    Result := '~~~MissionString '+IntToStr(aIndex)+' out of range!~~~';
end;


procedure TTextLibrary.ExportTextLibrary(aLibrary: array of AnsiString; aFileName: string);
var
  i: integer;
  FileData: TStringList;
begin
  //Here we will export all of the text to a file
  FileData := TStringList.Create;
  try
    if FileExists(aFileName) then
      DeleteFile(aFileName);

    for i := Low(GameStrings) to High(GameStrings) do
      FileData.Add(IntToStr(i) + ':' + aLibrary[i]);

    FileData.SaveToFile(aFileName);
  finally
    FileData.Free;
  end;
end;


procedure TTextLibrary.ExportTextLibraries;
begin
  CreateDir(ExeDir + 'Export' + PathDelim);
  ExportTextLibrary(GameStrings, ExeDir + 'Export' + PathDelim + 'text.'+fLocale+'.libx');
end;


end.
