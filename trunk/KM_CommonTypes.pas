unit KM_CommonTypes;
{$I KaM_Remake.inc}
interface


type
  TCardinalArray = array of Cardinal;


  TEvent = procedure of object;
  TPointEvent = procedure (Sender:TObject; const X,Y: integer) of object;
  TIntegerEvent = procedure (aValue: Integer) of object;
  TStringEvent = procedure (const aData: string) of object;
  TResyncEvent = procedure (aSender:Integer; aTick: cardinal) of object;
  TIntegerStringEvent = procedure (aValue: Integer; const aText: string) of object;


implementation


end.
