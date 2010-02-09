unit KromUtils;
{$IFDEF FPC} {$MODE DELPHI} {$ENDIF}
interface
uses sysutils,windows,forms,typinfo,ExtCtrls,Math, Dialogs, Registry, ShellApi;

type
  PSingleArray = ^TSingleArray;
  TSingleArray = array[1..1024000] of Single;
  PStringArray = ^TStringArray;
  TStringArray = array[1..256] of String;
  Vector4f = record X,Y,Z,W:single; end;
  Vector3f = record X,Y,Z:single; end;
  Vector2f = record U,V:single; end;
  PVector3f = ^Vector3f;

  FWord = word; //Floating-point with 1 decimal place 0..6553.5  Int/10=FWord

  TKMouseButton = (kmb_None, kmb_Left, kmb_Right, kmb_Middle);

function ElapsedTime(i1: pcardinal): string;
function ExtractOpenedFileName(in_s: string):string;
function GetFileExt (const FileName: string): string;
function AssureFileExt(FileName,Ext:string): string;
function GetFileSize(const FileName: string): LongInt;
function CheckFileExists(const FileName: string; const IsSilent:boolean = false):boolean;

function ReverseString(s1:string):string;

function int2fix(Number,Len:integer):string;
function float2fix(Number:single; Digits:integer):string;
function int2time(Time:integer):string;
procedure Color2RGB(Col:integer; out R,G,B:byte);

function Vectorize(A,B:single):Vector2f; overload;
function Vectorize(A,B,C:single):Vector3f; overload;

function Min(const A,B,C: integer):integer; overload;
function Min(const A,B,C: single):single; overload;

function Max(const A,B,C: integer):integer; overload;
function Max(const A,B,C: single):single; overload;

function Ceil(const X: Extended):Integer;
function Pow(const Base, Exponent: integer): integer;

  function GetLength(ix,iy,iz:single): single; overload;
  function GetLength(ix,iy:single): single; overload;

  function Mix(x1,x2,MixValue:single):single; overload;
  function Mix(x1,x2:integer; MixValue:single):integer; overload;

procedure decs(var AText:string; const Len:integer=1); overload;
procedure decs(var AText:widestring; const Len:integer=1); overload;
function  decs(AText:string; Len,RunAsFunction:integer):string; overload;
function RemoveQuotes(Input:string):string;
procedure SwapStr(var A,B:string);
procedure SwapInt(var A,B:word); overload;
procedure SwapInt(var A,B:integer); overload;
procedure SwapInt(var A,B:cardinal); overload;
procedure SwapFloat(var A,B:single);
function Equals(A,B:single; const Epsilon:single=0.001):boolean;

procedure ConvertSetToArray(iSet:integer; Ar:pointer);
//function WriteLWO(fname:string; PQty,VQty,SQty:integer; xyz:PSingleArray; uv:PSingleArray; v:PIntegerArray; Surf:PStringArray): boolean;
function MakePOT(num:integer):integer;
function Adler32CRC(TextPointer:Pointer; TextLength:integer):integer;
function RandomS(Range_Both_Directions:integer):integer; overload;
function RandomS(Range_Both_Directions:single):single; overload;
function RunOpenDialog(Sender:TOpenDialog; Name,Path,Filter:string):boolean;
function RunSaveDialog(Sender:TSaveDialog; FileName, FilePath, Filter:string; const FileExt:string = ''):boolean;

function BrowseURL(const URL: string) : boolean;
procedure MailTo(Address,Subject,Body:string);
procedure OpenMySite(ToolName:string; Address:string='http://krom.reveur.de');

const
  eol:string=#13+#10; //EndOfLine

implementation

function Vectorize(A,B:single):Vector2f; overload;
begin
Result.U:=A;
Result.V:=B;
end;

function Vectorize(A,B,C:single):Vector3f; overload;
begin
Result.X:=A;
Result.Y:=B;
Result.Z:=C;
end;

function Min(const A,B,C: integer): integer; overload;
begin if A < B then if A < C then Result := A else Result := C
               else if B < C then Result := B else Result := C;
end;

function Min(const A,B,C: single): single; overload;
begin if A < B then if A < C then Result := A else Result := C
               else if B < C then Result := B else Result := C;
end;

function Max(const A,B,C: integer): integer; overload;
begin if A > B then if A > C then Result := A else Result := C
               else if B > C then Result := B else Result := C;
end;

function Max(const A,B,C: single): single; overload;
begin if A > B then if A > C then Result := A else Result := C
               else if B > C then Result := B else Result := C;
end;


function ElapsedTime(i1:pcardinal): string;
begin
result:=' '+inttostr(GetTickCount-i1^)+'ms'; //get time passed
i1^:=GetTickCount;                           //assign new value to source
end;


function ExtractOpenedFileName(in_s: string):string;
var k:word; out_s:string; QMarks:boolean;
begin
k:=0; out_s:=''; QMarks:=false;

repeat      //First of all skip exe path
inc(k);
  if in_s[k]='"' then
  repeat inc(k);
  until(in_s[k]='"');
until((k>=length(in_s))or(in_s[k]=#32));  //in_s[k]=#32 now

inc(k);     //in_s[k]=" or first char

if (length(in_s)>k)and(in_s[k]=#32) then //Skip doublespace, WinXP bug ?
    repeat
    inc(k);
    until((k>=length(in_s))or(in_s[k]<>#32));

if (length(in_s)>k) then begin

    if in_s[k]='"' then begin
    inc(k); //Getting path from "...."
    QMarks:=true;
    end;

    repeat
    out_s:=out_s+in_s[k];
    inc(k);
    until((length(in_s)=k-1)or(in_s[k]='"')or((QMarks=false)and(in_s[k]=' ')));

end else out_s:='';

Result:=out_s;
end;

//Returns file extension without dot
function GetFileExt(const FileName: string): string;
var k:integer; s:string;
begin
s:=''; k:=0;
repeat
    s:=FileName[length(FileName)-k]+s;
    inc(k);
  until((length(FileName)-k=0)or(FileName[length(FileName)-k]='.'));
  if length(FileName)-k=0 then
    Result:=''
  else
Result:=uppercase(s);
end;


function AssureFileExt(FileName,Ext:string): string;
begin
if (Ext='')or(GetFileExt(FileName)=UpperCase(Ext)) then
  Result:=FileName
else
  Result:=FileName+'.'+Ext;
end;


function GetFileSize(const FileName: string): LongInt;
var
  SearchRec: TSearchRec;
begin
  try
    if FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0 then
      Result := SearchRec.Size
    else Result := -1;
  finally
    SysUtils.FindClose(SearchRec);
  end;
end;


function CheckFileExists(const FileName: string; const IsSilent:boolean = false):boolean;
begin
if fileexists(FileName) then
  Result:=true
else begin
  if not IsSilent then ShowMessage('Unable to locate '+#13+'"'+FileName+'" file');
  Result:=false;
end;
end;


function ReverseString(s1:string):string;
var s2:string; i:integer;
begin
s2:=s1; //preparing ?
for i:=1 to length(s1) do
s2[i]:=s1[length(s1)-i+1];
ReverseString:=s2;
end;


function int2fix(Number,Len:integer):string;
var ss:string; x:byte;
begin
  ss := inttostr(Number);
  for x:=length(ss) to Len-1 do
    ss := '0' + ss;
  if length(ss)>Len then
    ss:='**********';//ss[99999999]:='0'; //generating an error in lame way
  setlength(ss, Len);
  Result := ss;
end;

function float2fix(Number:single; Digits:integer):string;
begin
  Result := FloatToStrF(Number,ffGeneral,3,2);
end;

function int2time(Time:integer):string;
begin
Result := int2fix(Time div 3600 mod 24,2)+':'+
          int2fix(Time div 60 mod 60,2)+':'+
          int2fix(Time mod 60,2);
end;


procedure Color2RGB(Col:integer; out R,G,B:byte);
begin
R:=Col AND $FF;
G:=Col AND $FF00 SHR 8;
B:=Col AND $FF0000 SHR 16;
end;

function Ceil(const X: Extended): Integer;
begin
  Result := Integer(Trunc(X));
  if Frac(X) > 0 then
    Inc(Result);
end;


function Pow(const Base, Exponent: integer): integer;
begin
  if Exponent = 0 then
    Result := 1               { n**0 = 1 }
  else
  if (Base = 0) and (Exponent > 0) then
    Result := 0               { 0**n = 0, n > 0 }
  else
    Result := round(IntPower(Base, Exponent))
end;


procedure ConvertSetToArray(iSet:integer; Ar:pointer);
var i,k:integer; A:^integer;
begin
k:=1;
for i:=1 to 24 do
  if iSet and pow(2,i) = pow(2,i) then
    begin
      A:=pointer(integer(Ar)+k*4);
      A^:=i;
      inc(k);
    end;
A:=pointer(integer(Ar));
A^:=k-1;
end;


function MakePOT(num:integer):integer;
begin
num := num - 1; //Took this rather smart code from Net
num := num OR (num SHR 1);
num := num OR (num SHR 2);
num := num OR (num SHR 4);
num := num OR (num SHR 8);
num := num OR (num SHR 16); //32bit needs no more
Result := num+1;
end;


function GetLength(ix,iy,iz:single): single; overload;
begin
  Result:=sqrt(sqr(ix)+sqr(iy)+sqr(iz));
end;


function GetLength(ix,iy:single): single; overload;
begin
  Result:=sqrt(sqr(ix)+sqr(iy));
end;


function Mix(x1,x2,MixValue:single):single; overload;
begin
Result:=x1*MixValue+x2*(1-MixValue);
end;

function Mix(x1,x2:integer; MixValue:single):integer; overload;
begin
Result:=round(x1*MixValue+x2*(1-MixValue));
end;


procedure decs(var AText:string; const Len:integer=1);
begin
if length(AText)<=abs(Len) then Atext:=''
else
if Len>=0 then AText:=Copy(AText, 1, length(AText)-Len)
          else AText:=Copy(AText, 1+abs(Len), length(AText)-abs(Len));
end;

procedure decs(var AText:widestring; const Len:integer=1);
begin
if length(AText)<=abs(Len) then Atext:=''
else
if Len>=0 then AText:=Copy(AText, 1, length(AText)-Len)
          else AText:=Copy(AText, 1+abs(Len), length(AText)-abs(Len));
end;

function decs(AText:string; Len,RunAsFunction:integer):string; overload;
begin
if length(AText)<=abs(Len) then result:=''
else
if Len>=0 then result:=Copy(AText, 1, length(AText)-Len)
          else result:=Copy(AText, 1+abs(Len), length(AText)-abs(Len));
end;


function RemoveQuotes(Input:string):string;
var i,k:integer;
begin
  Result:=''; k:=1;
  while (Input[k]<>'"') and (k <= Length(Input)) do
    inc(k);
  if k = Length(Input) then exit; //No quotes found

  for i:=k+1 to length(Input) do
    if Input[i]<>'"' then
      Result:=Result+Input[i]
    else
      exit; //Will exit on first encountered quotes from 2nd character
end;


procedure SwapStr(var A,B:string);
var s:string;
begin
  s:=A; A:=B; B:=s;
end;

procedure SwapInt(var A,B:word);
var s:word;
begin
  s:=A; A:=B; B:=s;
end;

procedure SwapInt(var A,B:integer);
var s:integer;
begin
  s:=A; A:=B; B:=s;
end;

procedure SwapInt(var A,B:cardinal);
var s:cardinal;
begin
  s:=A; A:=B; B:=s;
end;

procedure SwapFloat(var A,B:single);
var s:single;
begin
  s:=A; A:=B; B:=s;
end;

function Equals(A,B:single; const Epsilon:single=0.001):boolean;
begin
  Result := abs(A-B) <= Epsilon;
end;

function Adler32CRC(TextPointer:Pointer; TextLength:integer):integer;
var i,A,B:integer;
begin
  A:=1; B:=0; //A is initialized to 1, B to 0
  for i:=1 to TextLength do begin
  inc(A,pbyte(integer(TextPointer)+i-1)^);
  inc(B,A);
  end;
  A:=A mod 65521; //65521 (the largest prime number smaller than 2^16)
  B:=B mod 65521;
  Adler32CRC:=B+A*65536; //reverse order for smaller numbers
end;

function RandomS(Range_Both_Directions:integer):integer; overload;
begin
  Result:=Random(Range_Both_Directions*2+1)-Range_Both_Directions;
end;

function RandomS(Range_Both_Directions:single):single; overload;
begin
Result:=Random(round(Range_Both_Directions*20000)+1)/10000-Range_Both_Directions;
end;


function RunOpenDialog(Sender:TOpenDialog; Name,Path,Filter:string):boolean;
begin
  Sender.FileName:=Name;
  Sender.InitialDir:=Path;
  Sender.Filter:=Filter;
  Result:=Sender.Execute; //Returns "false" if user pressed "Cancel"
  //Result:=Result and FileExists(Sender.FileName); //Already should be enabled in OpenDialog options
end;

function RunSaveDialog(Sender:TSaveDialog; FileName, FilePath, Filter:string; const FileExt:string = ''):boolean;
begin
Sender.FileName:=FileName;
Sender.InitialDir:=FilePath;
Sender.Filter:=Filter;
Result:=Sender.Execute; //Returns "false" if user pressed "Cancel"
Sender.FileName:=AssureFileExt(Sender.FileName,FileExt);
end;


//By Zarko Gajic, About.com
function BrowseURL(const URL: string) : boolean;
var
   Browser: string;
begin
   Result := True;
   Browser := '';
   with TRegistry.Create do
   try
     RootKey := HKEY_CLASSES_ROOT;
     Access := KEY_QUERY_VALUE;
     if OpenKey('\htmlfile\shell\open\command', False) then
       Browser := ReadString('') ;
     CloseKey;
   finally
     Free;
   end;
   if Browser = '' then
   begin
     Result := False;
     Exit;
   end;
   Browser := Copy(Browser, Pos('"', Browser) + 1, Length(Browser)) ;
   Browser := Copy(Browser, 1, Pos('"', Browser) - 1) ;
   ShellExecute(0, 'open', PChar(@Browser[1]), PChar(@URL[1]), nil, SW_SHOW);
end;


procedure MailTo(Address,Subject,Body:string);
begin
  BrowseURL('mailto:'+Address+'?subject='+Subject+'&body='+Body);
end;


procedure OpenMySite(ToolName:string; Address:string='http://krom.reveur.de');
begin
  BrowseURL(Address+'/index_r.php?t='+ToolName); //Maybe add tool version later..
end;


end.
