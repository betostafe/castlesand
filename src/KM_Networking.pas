﻿unit KM_Networking;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLIntf, {$ENDIF}
  Classes, SysUtils, TypInfo, Forms, KromUtils,
  KM_CommonClasses, KM_CommonTypes, KM_NetworkClasses, KM_NetworkTypes, KM_Defaults,
  KM_Saves, KM_GameOptions, KM_ResLocales, KM_NetFileTransfer, KM_Maps, KM_NetPlayersList,
  KM_DedicatedServer, KM_NetClient, KM_ServerQuery,
  {$IFDEF USESECUREAUTH}
    KM_NetAuthSecure
  {$ELSE}
    KM_NetAuthUnsecure
  {$ENDIF}
  ;

type
  TNetPlayerKind = (lpk_Host, lpk_Joiner);
  TNetGameState = (lgs_None, lgs_Connecting, lgs_Query, lgs_Lobby, lgs_Loading, lgs_Game, lgs_Reconnecting);
  TNetGameKind = (ngk_None, ngk_Map, ngk_Save);
  TChatSound = (csNone, csJoin, csLeave, csSystem, csGameStart, csSaveGame, csChat, csChatWhisper, csChatTeam);
  TChatMode = (cmAll, cmTeam, cmSpectators, cmWhisper);

const
  NetMPGameState:array[TNetGameState] of TMPGameState = (mgsNone, mgsNone, mgsNone, mgsLobby, mgsLoading, mgsGame, mgsGame);
  NetAllowedPackets:array[TNetGameState] of set of TKMessageKind = (
    //lgs_None
    [],
    //lgs_Connecting
    [mk_RefuseToJoin,mk_IndexOnServer,mk_GameVersion,mk_WelcomeMessage,mk_Ping,
     mk_ConnectedToRoom,mk_PingInfo,mk_Kicked,mk_ServerName,mk_ReqPassword],
    //lgs_Query
    [mk_AllowToJoin,mk_RefuseToJoin,mk_AuthChallenge,mk_Ping,mk_PingInfo,mk_Kicked],
    //lgs_Lobby
    [mk_AskForAuth,mk_AskToJoin,mk_ClientLost,mk_ReassignHost,mk_Disconnect,mk_Ping,mk_PingInfo,mk_PlayersList,
     mk_StartingLocQuery,mk_SetTeam,mk_FlagColorQuery,mk_ResetMap,mk_MapSelect,mk_SaveSelect,
     mk_ReadyToStart,mk_Start,mk_TextChat,mk_Kicked,mk_LangCode,mk_GameOptions,mk_ServerName,
     mk_FileRequest,mk_FileChunk,mk_FileEnd,mk_FileAck,mk_TextTranslated],
    //lgs_Loading
    [mk_AskForAuth,mk_ClientLost,mk_ReassignHost,mk_Disconnect,mk_Ping,mk_PingInfo,mk_PlayersList,
     mk_ReadyToPlay,mk_Play,mk_TextChat,mk_Kicked,mk_TextTranslated,mk_Vote],
    //lgs_Game
    [mk_AskForAuth,mk_ClientLost,mk_ReassignHost,mk_Disconnect,mk_Ping,mk_PingInfo,mk_FPS,mk_PlayersList,mk_ReturnToLobby,
     mk_Commands,mk_TextChat,mk_ResyncFromTick,mk_AskToReconnect,mk_Kicked,mk_ClientReconnected,mk_TextTranslated,mk_Vote],
    //lgs_Reconnecting
    [mk_IndexOnServer,mk_GameVersion,mk_WelcomeMessage,mk_Ping,mk_FPS,mk_ConnectedToRoom,
     mk_PingInfo,mk_PlayersList,mk_ReconnectionAccepted,mk_RefuseReconnect,mk_Kicked]
  );

  JOIN_TIMEOUT = 8000; //8 sec. Timeout for join queries
  RECONNECT_PAUSE = 3000; //Time in ms which we wait before attempting to reconnect (stops the socket from becoming overloaded)
  VOTE_TIMEOUT = 60000; //60 sec. Timeout for votes


type
  //Should handle message exchange and routing, interacting with UI
  TKMNetworking = class
  private
    fNetServer: TKMDedicatedServer;
    fNetClient: TKMNetClient;
    fServerQuery: TKMServerQuery;
    fNetPlayerKind: TNetPlayerKind; // Our role (Host or Joiner)
    fNetGameState: TNetGameState;
    fServerAddress: string; // Used for reconnecting
    fServerPort: string; // Used for reconnecting
    fRoomToJoin: integer; // The room we should join once we hear from the server
    fLastProcessedTick: cardinal;
    fReconnectRequested: cardinal; // TickCount at which a reconnection was requested
    fMyNikname: AnsiString;
    fWelcomeMessage: UnicodeString;
    fServerName: UnicodeString; // Name of the server we are currently in (shown in the lobby)
    fPassword: AnsiString;
    fDescription: UnicodeString;
    fEnteringPassword: Boolean;
    fMyIndexOnServer: integer;
    fMyIndex: integer; // In NetPlayers list
    fHostIndex: Integer; //In NetPlayers list
    fIgnorePings: integer; // During loading ping measurements will be high, so discard them. (when networking is threaded this might be unnecessary)
    fJoinTimeout, fLastVoteTime: Cardinal;
    fNetPlayers: TKMNetPlayersList;

    fMapInfo: TKMapInfo; // Everything related to selected map
    fSaveInfo: TKMSaveInfo;
    fSelectGameKind: TNetGameKind;
    fNetGameOptions: TKMGameOptions;

    fFileReceiver: TKMFileReceiver;
    fFileSenderManager: TKMFileSenderManager;
    fMissingFileType: TNetGameKind;
    fMissingFileName: UnicodeString;
    fMissingFileCRC: Cardinal;

    fOnJoinSucc: TNotifyEvent;
    fOnJoinFail: TUnicodeStringEvent;
    fOnJoinPassword: TNotifyEvent;
    fOnJoinAssignedHost: TNotifyEvent;
    fOnHostFail: TUnicodeStringEvent;
    fOnReassignedHost: TNotifyEvent;
    fOnReassignedJoiner: TNotifyEvent;
    fOnFileTransferProgress: TTransferProgressEvent;
    fOnTextMessage: TUnicodeStringEvent;
    fOnPlayersSetup: TNotifyEvent;
    fOnGameOptions: TNotifyEvent;
    fOnMapName: TUnicodeStringEvent;
    fOnMapMissing: TUnicodeStringBoolEvent;
    fOnStartMap: TMapStartEvent;
    fOnStartSave: TGameStartEvent;
    fOnReturnToLobby: TNotifyEvent;
    fOnPlay: TNotifyEvent;
    fOnReadyToPlay: TNotifyEvent;
    fOnDisconnect: TUnicodeStringEvent;
    fOnPingInfo: TNotifyEvent;
    fOnMPGameInfoChanged: TNotifyEvent;
    fOnCommands: TStreamIntEvent;
    fOnResyncFromTick: TResyncEvent;

    procedure DecodePingInfo(aStream: TKMemoryStream);
    procedure ForcedDisconnect(Sender: TObject);
    procedure StartGame;
    procedure TryPlayGame;
    procedure PlayGame;
    procedure SetGameState(aState: TNetGameState);
    procedure SendMapOrSave(Recipient: Integer = NET_ADDRESS_OTHERS);
    procedure DoReconnection;
    procedure PlayerJoined(aServerIndex: Integer; aPlayerName: AnsiString);

    procedure TransferOnCompleted(aClientIndex: Integer);
    procedure TransferOnPacket(aClientIndex: Integer; aStream: TKMemoryStream; out SendBufferEmpty: Boolean);

    procedure ConnectSucceed(Sender:TObject);
    procedure ConnectFailed(const S: string);
    procedure PacketRecieve(aNetClient:TKMNetClient; aSenderIndex:integer; aData:pointer; aLength:cardinal); //Process all commands
    procedure PacketSend(aRecipient: Integer; aKind: TKMessageKind); overload;
    procedure PacketSend(aRecipient: Integer; aKind: TKMessageKind; aStream: TKMemoryStream); overload;
    procedure PacketSend(aRecipient: Integer; aKind: TKMessageKind; aParam: Integer); overload;
    procedure PacketSendA(aRecipient: Integer; aKind: TKMessageKind; const aText: AnsiString);
    procedure PacketSendW(aRecipient: Integer; aKind: TKMessageKind; const aText: UnicodeString);
    procedure SetDescription(const Value: UnicodeString);
  public
    constructor Create(const aMasterServerAddress: string; aKickTimeout, aPingInterval, aAnnounceInterval: Word);
    destructor Destroy; override;

    property MyIndex: Integer read fMyIndex;
    property MyIndexOnServer: Integer read fMyIndexOnServer;
    property HostIndex: Integer read fHostIndex;
    property NetGameState: TNetGameState read fNetGameState;
    function MyIPString:string;
    property ServerName: UnicodeString read fServerName;
    property ServerAddress: string read fServerAddress;
    property ServerPort: string read fServerPort;
    property ServerRoom: Integer read fRoomToJoin;
    function IsHost: Boolean;
    function IsReconnecting: Boolean;
    function CalculateGameCRC: Cardinal;

    //Lobby
    property ServerQuery: TKMServerQuery read fServerQuery;
    procedure Host(aServerName: UnicodeString; aPort: string; aNikname: AnsiString; aAnnounceServer: Boolean);
    procedure Join(aServerAddress, aPort: string; aNikname: AnsiString; aRoom: Integer; aIsReconnection: Boolean = False);
    procedure AnnounceDisconnect;
    procedure Disconnect;
    procedure DropPlayers(aPlayers: TKMByteArray);
    function  Connected: boolean;
    procedure MatchPlayersToSave(aPlayerID:integer=-1);
    procedure SelectNoMap(const aErrorMessage: UnicodeString);
    procedure SelectMap(const aName: UnicodeString);
    procedure SelectSave(const aName: UnicodeString);
    procedure SelectLoc(aIndex:integer; aPlayerIndex:integer);
    procedure SelectTeam(aIndex:integer; aPlayerIndex:integer);
    procedure SelectColor(aIndex:integer; aPlayerIndex:integer);
    procedure KickPlayer(aPlayerIndex:integer);
    procedure BanPlayer(aPlayerIndex:integer);
    procedure SetToHost(aPlayerIndex:integer);
    procedure ResetBans;
    procedure SendPassword(aPassword: AnsiString);
    procedure SetPassword(aPassword: AnsiString);
    property Password: AnsiString read fPassword;
    property Description: UnicodeString read fDescription write SetDescription;
    function ReadyToStart:boolean;
    function CanStart:boolean;
    function CanTakeLocation(aPlayer, aLoc: Integer; AllowSwapping: Boolean): Boolean;
    procedure StartClick; //All required arguments are in our class
    procedure SendPlayerListAndRefreshPlayersSetup(aPlayerIndex:integer = NET_ADDRESS_OTHERS);
    procedure UpdateGameOptions(aPeacetime: Word; aSpeedPT, aSpeedAfterPT: Single);
    procedure SendGameOptions;
    procedure RequestFileTransfer;
    procedure VoteReturnToLobby;

    //Common
    procedure ConsoleCommand(aText: UnicodeString);
    procedure PostMessage(aTextID: Integer; aSound: TChatSound; aText1: UnicodeString=''; aText2: UnicodeString = ''; aRecipient:Integer=NET_ADDRESS_ALL);
    procedure PostChat(aText: UnicodeString; aMode: TChatMode; aRecipientServerIndex: Integer=-1); overload;
    procedure PostLocalMessage(aText: UnicodeString; aSound: TChatSound);
    procedure AnnounceGameInfo(aGameTime: TDateTime; aMap: UnicodeString);

    //Gameplay
    property MapInfo:TKMapInfo read fMapInfo;
    property SaveInfo:TKMSaveInfo read fSaveInfo;
    property NetGameOptions:TKMGameOptions read fNetGameOptions;
    property SelectGameKind: TNetGameKind read fSelectGameKind;
    property NetPlayers:TKMNetPlayersList read fNetPlayers;
    property LastProcessedTick:cardinal write fLastProcessedTick;
    property MissingFileType: TNetGameKind read fMissingFileType;
    property MissingFileName: UnicodeString read fMissingFileName;
    procedure GameCreated;
    procedure SendCommands(aStream: TKMemoryStream; aPlayerIndex: ShortInt = -1);
    procedure AttemptReconnection;
    procedure ReturnToLobby;

    property OnJoinSucc:TNotifyEvent write fOnJoinSucc;         //We were allowed to join
    property OnJoinFail: TUnicodeStringEvent write fOnJoinFail;         //We were refused to join
    property OnJoinPassword:TNotifyEvent write fOnJoinPassword; //Lobby requires password
    property OnHostFail: TUnicodeStringEvent write fOnHostFail;         //Server failed to start (already running a server?)
    property OnJoinAssignedHost:TNotifyEvent write fOnJoinAssignedHost; //We were assigned hosting rights upon connection
    property OnReassignedHost:TNotifyEvent write fOnReassignedHost;     //We were reassigned hosting rights when the host quit
    property OnReassignedJoiner:TNotifyEvent write fOnReassignedJoiner; //We were reassigned to a joiner from host
    property OnFileTransferProgress:TTransferProgressEvent write fOnFileTransferProgress;

    property OnPlayersSetup: TNotifyEvent write fOnPlayersSetup; //Player list updated
    property OnGameOptions: TNotifyEvent write fOnGameOptions; //Game options updated
    property OnMapName: TUnicodeStringEvent write fOnMapName;           //Map name updated
    property OnMapMissing: TUnicodeStringBoolEvent write fOnMapMissing;           //Map missing
    property OnStartMap: TMapStartEvent write fOnStartMap;       //Start the game
    property OnStartSave: TGameStartEvent write fOnStartSave;       //Load the game
    property OnReturnToLobby: TNotifyEvent write fOnReturnToLobby;
    property OnPlay:TNotifyEvent write fOnPlay;                 //Start the gameplay
    property OnReadyToPlay:TNotifyEvent write fOnReadyToPlay;   //Update the list of players ready to play
    property OnPingInfo:TNotifyEvent write fOnPingInfo;         //Ping info updated
    property OnMPGameInfoChanged:TNotifyEvent write fOnMPGameInfoChanged;

    property OnDisconnect: TUnicodeStringEvent write fOnDisconnect;     //Lost connection, was kicked
    property OnCommands: TStreamIntEvent write fOnCommands;        //Recieved GIP commands
    property OnResyncFromTick:TResyncEvent write fOnResyncFromTick;

    property OnTextMessage: TUnicodeStringEvent write fOnTextMessage;   //Text message recieved

    procedure UpdateState(aTick: cardinal);
    procedure UpdateStateIdle;
    procedure FPSMeasurement(aFPS: Cardinal);
  end;


implementation
uses KM_ResTexts, KM_Sound, KM_ResSound, KM_Log, KM_Utils, StrUtils, Math, KM_Resource;


{ TKMNetworking }
constructor TKMNetworking.Create(const aMasterServerAddress:string; aKickTimeout, aPingInterval, aAnnounceInterval:word);
begin
  inherited Create;
  SetGameState(lgs_None);
  fNetServer := TKMDedicatedServer.Create(1, aKickTimeout, aPingInterval, aAnnounceInterval, aMasterServerAddress, '', '', False);
  fNetClient := TKMNetClient.Create;
  fNetPlayers := TKMNetPlayersList.Create;
  fServerQuery := TKMServerQuery.Create(aMasterServerAddress);
  fNetGameOptions := TKMGameOptions.Create;
  fFileSenderManager := TKMFileSenderManager.Create;
  fFileSenderManager.OnTransferCompleted := TransferOnCompleted;
  fFileSenderManager.OnTransferPacket := TransferOnPacket;
end;


destructor TKMNetworking.Destroy;
begin
  fNetPlayers.Free;
  fNetServer.Free;
  fNetClient.Free;
  fServerQuery.Free;
  fFileSenderManager.Free;
  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);
  FreeAndNil(fNetGameOptions);
  inherited;
end;


function TKMNetworking.MyIPString:string;
begin
  Result := fNetClient.MyIPString;
end;


function TKMNetworking.IsHost:boolean;
begin
  Result := (fNetPlayerKind = lpk_Host);
end;


function TKMNetworking.IsReconnecting:boolean;
begin
  Result := (fNetGameState = lgs_Reconnecting) or (fReconnectRequested <> 0);
end;


//Startup a local server and connect to it as ordinary client
procedure TKMNetworking.Host(aServerName: UnicodeString; aPort: string; aNikname: AnsiString; aAnnounceServer: Boolean);
begin
  fWelcomeMessage := '';
  fPassword := '';
  fDescription := '';
  fIgnorePings := 0; //Accept pings
  fNetServer.Stop;

  fNetServer.OnMessage := gLog.AddTime; //Log server messages in case there is a problem, but hide from user
  try
    fNetServer.Start(aServerName, aPort, aAnnounceServer);
  except
    on E : Exception do
    begin
      //Server failed to start
      fOnHostFail(E.Message);
      Exit;
    end;
  end;

  Join('127.0.0.1', aPort, aNikname, 0); //Server will assign hosting rights to us as we are the first joiner
end;


procedure TKMNetworking.Join(aServerAddress, aPort: string; aNikname: AnsiString; aRoom: Integer; aIsReconnection: Boolean = False);
begin
  Assert(not fNetClient.Connected, 'Cannot connect: We are already connected');

  fWelcomeMessage := '';
  fPassword := '';
  fDescription := '';
  fIgnorePings := 0; //Accept pings
  fJoinTimeout := TimeGet;
  fMyIndex := -1; //Host will send us PlayerList and we will get our index from there
  fHostIndex := -1;
  fMyIndexOnServer := -1; //Assigned by Server
  fRoomToJoin := aRoom;
  if aIsReconnection then
    SetGameState(lgs_Reconnecting) //Special state so we know we are reconnecting
  else
    SetGameState(lgs_Connecting); //We are still connecting to the server

  fServerAddress := aServerAddress;
  fServerPort := aPort;
  fMyNikname := aNikname;
  fNetPlayerKind := lpk_Joiner;
  fServerName := ''; //Server will tell us once we are joined

  fNetClient.OnRecieveData := PacketRecieve;
  fNetClient.OnConnectSucceed := ConnectSucceed;
  fNetClient.OnConnectFailed := ConnectFailed;
  fNetClient.OnForcedDisconnect := ForcedDisconnect;
  //fNetClient.OnStatusMessage := fOnTextMessage; //For debugging only
  fNetClient.ConnectTo(fServerAddress, fServerPort);
end;


//Connection was successful, but we still need mk_IndexOnServer to be able to do anything
procedure TKMNetworking.ConnectSucceed(Sender:TObject);
begin
  //This is currently unused, the player does not need to see this message
  //PostLocalMessage('Connection successful');
end;


procedure TKMNetworking.ConnectFailed(const S: string);
begin
  fNetClient.Disconnect;
  fOnJoinFail(S);
end;


//Send message that we have deliberately disconnected
procedure TKMNetworking.AnnounceDisconnect;
begin
  if IsHost then
    PacketSend(NET_ADDRESS_OTHERS, mk_Disconnect) //Host tells everyone when they quit
  else
    PacketSend(NET_ADDRESS_HOST, mk_Disconnect); //Joiners should only tell host when they quit
end;


procedure TKMNetworking.Disconnect;
begin
  fIgnorePings := 0;
  fReconnectRequested := 0; //Cancel any reconnection that was requested
  fEnteringPassword := False;
  SetGameState(lgs_None);
  fOnJoinSucc := nil;
  fOnJoinFail := nil;
  fOnJoinAssignedHost := nil;
  fOnHostFail := nil;
  fOnTextMessage := nil;
  fOnPlayersSetup := nil;
  fOnMapName := nil;
  fOnMapMissing := nil;
  fOnCommands := nil;
  fOnResyncFromTick := nil;
  fOnDisconnect := nil;
  fOnPingInfo := nil;
  fOnReassignedHost := nil;
  fOnReassignedJoiner := nil;
  fWelcomeMessage := '';

  fNetPlayers.Clear;
  fNetGameOptions.Reset;
  fNetClient.Disconnect;
  fNetServer.Stop;

  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);
  FreeAndNil(fFileReceiver);
  fFileSenderManager.AbortAllTransfers;

  fSelectGameKind := ngk_None;
end;


procedure TKMNetworking.DropPlayers(aPlayers: TKMByteArray);
var
  I, ServerIndex: Integer;
begin
  Assert(IsHost, 'Only the host is allowed to drop players');
  for I := Low(aPlayers) to High(aPlayers) do
  begin
    ServerIndex := NetPlayers[aPlayers[I]].IndexOnServer;
    //Make sure this player is properly disconnected from the server
    PacketSend(NET_ADDRESS_SERVER, mk_KickPlayer, ServerIndex);
    NetPlayers.DropPlayer(ServerIndex);
    PostMessage(TX_NET_DROPPED, csLeave, UnicodeString(NetPlayers[aPlayers[I]].Nikname));
  end;
  SendPlayerListAndRefreshPlayersSetup;

  //Player being dropped may cause vote to end
  if (fNetGameState in [lgs_Loading, lgs_Game]) and (fNetPlayers.FurtherVotesNeededForMajority <= 0) then
  begin
    fNetPlayers.ResetVote;
    //This packet is also sent to ourself (host), we will return to lobby when it arrives
    PacketSend(NET_ADDRESS_ALL, mk_ReturnToLobby);
  end;
end;


procedure TKMNetworking.ForcedDisconnect(Sender: TObject);
begin
  fOnDisconnect(gResTexts[TX_NET_SERVER_STOPPED]);
end;


function TKMNetworking.Connected: boolean;
begin
  Result := fNetClient.Connected;
end;


procedure TKMNetworking.DecodePingInfo(aStream: TKMemoryStream);
var
  i:integer;
  PingCount:integer;
  PlayerHandle:integer;
  PingValue:word;
  LocalHandle:integer;
begin
  if fIgnorePings > 0 then
  begin
    dec(fIgnorePings);
    exit;
  end;
  if fIgnorePings <> 0 then exit; //-1 means ignore all pings

  aStream.Read(PingCount);
  for i:=1 to PingCount do
  begin
    aStream.Read(PlayerHandle);
    LocalHandle := fNetPlayers.ServerToLocal(PlayerHandle);
    aStream.Read(PingValue);
    //This player might not be in the lobby yet, could still be asking to join. If so we do not care about their ping.
    if LocalHandle <> -1 then
      fNetPlayers[LocalHandle].AddPing(PingValue);
  end;
end;


procedure TKMNetworking.SendMapOrSave(Recipient: Integer = NET_ADDRESS_OTHERS);
var M: TKMemoryStream;
begin
  M := TKMemoryStream.Create;
  case fSelectGameKind of
    ngk_Save: begin
                M.WriteW(fSaveInfo.FileName);
                M.Write(fSaveInfo.CRC);
                PacketSend(Recipient, mk_SaveSelect, M);
              end;
    ngk_Map:  begin
                M.WriteW(fMapInfo.FileName);
                M.Write(fMapInfo.CRC);
                PacketSend(Recipient, mk_MapSelect, M);
              end;
    else      PacketSend(Recipient, mk_ResetMap);
  end;
  M.Free;
end;


procedure TKMNetworking.MatchPlayersToSave(aPlayerID: Integer = -1);
var I,K: Integer;
begin
  Assert(IsHost, 'Only host can match players');
  Assert(fSelectGameKind = ngk_Save, 'Not a save');
  if aPlayerID = -1 then
  begin
    //If we are matching all then reset them all first so we don't get clashes
    for I := 1 to fNetPlayers.Count do
      if not fNetPlayers[I].IsSpectator then
        fNetPlayers[I].StartLocation := LOC_RANDOM;

    for I := 1 to MAX_LOBBY_PLAYERS - fSaveInfo.Info.HumanCount - fNetPlayers.GetClosedCount do
      if fNetPlayers.Count - fNetPlayers.GetSpectatorCount < MAX_LOBBY_PLAYERS then
        fNetPlayers.AddClosedPlayer; //Close unused slots
  end;

  //Match players based on their nicknames
  for I := 1 to fNetPlayers.Count do
    for K := 1 to fSaveInfo.Info.PlayerCount do
      if fSaveInfo.Info.Enabled[K-1]
      and ((I = aPlayerID) or (aPlayerID = -1)) //-1 means update all players
      and fNetPlayers.LocAvailable(K)
      and fNetPlayers[I].IsHuman
      and not fNetPlayers[I].IsSpectator
      and (fNetPlayers[I].Nikname = fSaveInfo.Info.OwnerNikname[K-1]) then
      begin
        fNetPlayers[I].StartLocation := K;
        Break;
      end;
end;


//Clear selection from any map/save
procedure TKMNetworking.SelectNoMap(const aErrorMessage: UnicodeString);
begin
  Assert(IsHost, 'Only host can reset map');

  fSelectGameKind := ngk_None;

  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);
  fFileSenderManager.AbortAllTransfers; //Any ongoing transfer is cancelled

  PacketSend(NET_ADDRESS_OTHERS, mk_ResetMap);
  fNetPlayers.ResetLocAndReady; //Reset start locations
  fNetPlayers[fMyIndex].ReadyToStart := True;

  if Assigned(fOnMapName) then
    fOnMapName(aErrorMessage);

  SendPlayerListAndRefreshPlayersSetup;
end;


//Tell other players which map we will be using
//Players will reset their starting locations and "Ready" status on their own
procedure TKMNetworking.SelectMap(const aName: UnicodeString);
begin
  Assert(IsHost, 'Only host can select maps');
  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);

  //Strict scanning to force CRC recalculation
  fMapInfo := TKMapInfo.Create(aName, True, mfMP);

  if not fMapInfo.IsValid then
  begin
    SelectNoMap('Invalid');
    Exit;
  end;

  fMapInfo.LoadExtra; //Lobby requires extra map info such as CanBeHuman

  fNetPlayers.ResetLocAndReady; //Reset start locations

  fSelectGameKind := ngk_Map;
  fNetPlayers[fMyIndex].ReadyToStart := True;
  fFileSenderManager.AbortAllTransfers; //Any ongoing transfer is cancelled

  SendMapOrSave;

  if Assigned(fOnMapName) then
    fOnMapName(fMapInfo.FileName);

  SendPlayerListAndRefreshPlayersSetup;
end;


//Tell other players which save we will be using
//Players will reset their starting locations and "Ready" status on their own
procedure TKMNetworking.SelectSave(const aName: UnicodeString);
var Error: UnicodeString;
begin
  Assert(IsHost, 'Only host can select saves');

  FreeAndNil(fMapInfo);
  FreeAndNil(fSaveInfo);

  fSaveInfo := TKMSaveInfo.Create(ExeDir + 'SavesMP' + PathDelim, aName);

  if not fSaveInfo.IsValid then
  begin
    Error := fSaveInfo.Info.Title; //Make a copy since fSaveInfo is freed in SelectNoMap
    SelectNoMap(Error); //State the error, e.g. wrong version
    Exit;
  end;

  fNetPlayers.ResetLocAndReady; //Reset start locations

  NetGameOptions.Peacetime := fSaveInfo.GameOptions.Peacetime;
  NetGameOptions.SpeedPT := fSaveInfo.GameOptions.SpeedPT;
  NetGameOptions.SpeedAfterPT := fSaveInfo.GameOptions.SpeedAfterPT;
  SendGameOptions;
  if Assigned(fOnGameOptions) then fOnGameOptions(Self);

  fSelectGameKind := ngk_Save;
  fNetPlayers[fMyIndex].ReadyToStart := True;
  //Randomise locations within team is disabled for saves
  NetPlayers.RandomizeTeamLocations := False;
  fFileSenderManager.AbortAllTransfers; //Any ongoing transfer is cancelled

  SendMapOrSave;
  MatchPlayersToSave; //Don't match players if it's not a valid save

  if Assigned(fOnMapName) then
    fOnMapName(fSaveInfo.FileName);

  SendPlayerListAndRefreshPlayersSetup;
end;


//Tell other players which start position we would like to use
//Each players choice should be unique
procedure TKMNetworking.SelectLoc(aIndex:integer; aPlayerIndex:integer);
var NetPlayerIndex: Integer;
begin
  //Check if position can be taken before doing anything
  if not CanTakeLocation(aPlayerIndex, aIndex, IsHost and fNetPlayers.HostDoesSetup) then
  begin
    if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
    Exit;
  end;

  //If someone else has this index, switch them (only when HostDoesSetup)
  if IsHost and fNetPlayers.HostDoesSetup and (aIndex <> LOC_RANDOM) and (aIndex <> LOC_SPECTATE) then
  begin
    NetPlayerIndex := fNetPlayers.StartingLocToLocal(aIndex);
    if NetPlayerIndex <> -1 then
    begin
      fNetPlayers[NetPlayerIndex].StartLocation := fNetPlayers[aPlayerIndex].StartLocation;

      //Spectators can't have team
      if fNetPlayers[NetPlayerIndex].StartLocation = LOC_SPECTATE then
        fNetPlayers[NetPlayerIndex].Team := 0;

      //If host pushes player to a different loc, the player should be set to not ready (they must agree to change)
      if (NetPlayerIndex <> fMyIndex) and not fNetPlayers[NetPlayerIndex].IsComputer then
        fNetPlayers[NetPlayerIndex].ReadyToStart := False;
    end;
  end;

  case fNetPlayerKind of
    lpk_Host:   begin
                  //Host makes rules, Joiner will get confirmation from Host
                  fNetPlayers[aPlayerIndex].StartLocation := aIndex; //Use aPlayerIndex not fMyIndex because it could be an AI

                  //If host pushes player to a different loc, the player should be set to not ready (they must agree to change)
                  if (aPlayerIndex <> fMyIndex) and not fNetPlayers[aPlayerIndex].IsComputer then
                    fNetPlayers[aPlayerIndex].ReadyToStart := False;

                  if aIndex = LOC_SPECTATE then
                    fNetPlayers[aPlayerIndex].Team := 0; //Spectators can't have team

                  SendPlayerListAndRefreshPlayersSetup;
                end;
    lpk_Joiner: PacketSend(NET_ADDRESS_HOST, mk_StartingLocQuery, aIndex);
  end;
end;


//Tell other players which team we are on. Player selections need not be unique
procedure TKMNetworking.SelectTeam(aIndex:integer; aPlayerIndex:integer);
begin
  fNetPlayers[aPlayerIndex].Team := aIndex; //Use aPlayerIndex not fMyIndex because it could be an AI

  case fNetPlayerKind of
    lpk_Host:   begin
                  //If host pushes player to a different team, the player should be set to not ready (they must agree to change)
                  if (aPlayerIndex <> fMyIndex) and not fNetPlayers[aPlayerIndex].IsComputer then
                    fNetPlayers[aPlayerIndex].ReadyToStart := False;

                  SendPlayerListAndRefreshPlayersSetup;
                end;
    lpk_Joiner: PacketSend(NET_ADDRESS_HOST, mk_SetTeam, aIndex);
  end;
end;


//Tell other players which color we will be using
//For now players colors are not unique, many players may have one color
procedure TKMNetworking.SelectColor(aIndex:integer; aPlayerIndex:integer);
begin
  if not fNetPlayers.ColorAvailable(aIndex) then exit;

  //Host makes rules, Joiner will get confirmation from Host
  fNetPlayers[aPlayerIndex].FlagColorID := aIndex; //Use aPlayerIndex not fMyIndex because it could be an AI

  case fNetPlayerKind of
    lpk_Host:   SendPlayerListAndRefreshPlayersSetup;
    lpk_Joiner: begin
                  PacketSend(NET_ADDRESS_HOST, mk_FlagColorQuery, aIndex);
                  if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
                end;
  end;
end;


procedure TKMNetworking.KickPlayer(aPlayerIndex: Integer);
begin
  Assert(IsHost, 'Only host is allowed to kick players out');
  //No need to play a sound, server will do that when it announces that player disconnected
  PostMessage(TX_NET_KICKED, csNone, UnicodeString(fNetPlayers[aPlayerIndex].Nikname));
  PacketSend(NET_ADDRESS_SERVER, mk_KickPlayer, fNetPlayers[aPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.BanPlayer(aPlayerIndex: Integer);
begin
  Assert(IsHost, 'Only host is allowed to ban players');
  //No need to play a sound, server will do that when it announces that player disconnected
  PostMessage(TX_NET_BANNED, csNone, UnicodeString(fNetPlayers[aPlayerIndex].Nikname));
  PacketSend(NET_ADDRESS_SERVER, mk_BanPlayer, fNetPlayers[aPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.SetToHost(aPlayerIndex: Integer);
begin
  Assert(IsHost, 'Only host is allowed to promote players');
  //Don't allow host reassigning if the server is running within this client (if host quits server stops)
  if fNetServer.IsListening then
    PostLocalMessage(gResTexts[TX_NET_PROMOTE_LOCAL_SERVER], csSystem)
  else
    PacketSend(NET_ADDRESS_SERVER, mk_GiveHost, fNetPlayers[aPlayerIndex].IndexOnServer);
end;


procedure TKMNetworking.ResetBans;
begin
  PacketSend(NET_ADDRESS_SERVER, mk_ResetBans);
  PostMessage(TX_NET_BANS_RESET, csSystem);
end;


procedure TKMNetworking.SendPassword(aPassword: AnsiString);
var
  M: TKMemoryStream;
begin
  M := TKMemoryStream.Create;
  M.Write(fRoomToJoin);
  M.WriteA(aPassword);
  PacketSend(NET_ADDRESS_SERVER, mk_Password, M);
  M.Free;

  fEnteringPassword := False;
  fJoinTimeout := TimeGet; //Wait another X seconds for host to reply before timing out
end;


procedure TKMNetworking.SetPassword(aPassword: AnsiString);
begin
  Assert(IsHost, 'Only host can set password');
  fPassword := aPassword;
  fOnMPGameInfoChanged(Self); //Send the password state to the server so it is shown in server list
  PacketSendA(NET_ADDRESS_SERVER, mk_SetPassword, fPassword);
end;


//Joiner indicates that he is ready to start
function TKMNetworking.ReadyToStart:boolean;
begin
  if (fSelectGameKind = ngk_Save) and (fNetPlayers[fMyIndex].StartLocation = 0) then
  begin
    PostLocalMessage(gResTexts[TX_LOBBY_ERROR_SELECT_PLAYER], csSystem);
    Result := false;
    Exit;
  end;

  if ((fSelectGameKind = ngk_Map) and fMapInfo.IsValid) or
     ((fSelectGameKind = ngk_Save) and fSaveInfo.IsValid) or
     fNetPlayers[fMyIndex].IsSpectator then //Spectators can be ready without map selected
  begin
    //Toggle it
    PacketSend(NET_ADDRESS_HOST, mk_ReadyToStart);
    Result := not fNetPlayers[fMyIndex].ReadyToStart;
  end
  else
  begin
    PostLocalMessage(gResTexts[TX_LOBBY_ERROR_NO_MAP], csSystem);
    Result := false;
  end;
end;


function TKMNetworking.CanStart:boolean;
var i:integer;
begin
  case fSelectGameKind of
    ngk_Map:  Result := fNetPlayers.AllReady and fMapInfo.IsValid;
    ngk_Save: begin
                Result := fNetPlayers.AllReady and fSaveInfo.IsValid;
                for i:=1 to fNetPlayers.Count do //In saves everyone must chose a location
                  Result := Result and ((fNetPlayers[i].StartLocation <> LOC_RANDOM) or fNetPlayers[i].IsClosed);
              end;
    else      Result := False;
  end;
  //At least one player must NOT be a spectator or closed
  for i:=1 to fNetPlayers.Count do
    if not fNetPlayers[i].IsSpectator and not fNetPlayers[i].IsClosed then
      Exit; //Exit with result from above

  //If we reached here then all players are spectators so only saves can be started,
  //unless this map has AI-only locations (spectators can watch the AIs)
  if (fSelectGameKind = ngk_Map) and (fMapInfo.AIOnlyLocCount = 0) then
    Result := False;
end;


//Tell other players we want to start
procedure TKMNetworking.StartClick;
var
  HumanUsableLocs, AIUsableLocs: TPlayerIndexArray;
  ErrorMessage: UnicodeString;
  M: TKMemoryStream;
begin
  Assert(IsHost, 'Only host can start the game');
  Assert(CanStart, 'Can''t start the game now');
  Assert(fNetGameState = lgs_Lobby, 'Can only start from lobby');

  //Define random parameters (start locations and flag colors)
  //This will also remove odd players from the List, they will lose Host in few seconds
  case fSelectGameKind of
    ngk_Map:  begin
                HumanUsableLocs := fMapInfo.HumanUsableLocations;
                AIUsableLocs := fMapInfo.AIUsableLocations;
              end;
    ngk_Save: begin
                HumanUsableLocs := fSaveInfo.Info.HumanUsableLocations;
                SetLength(AIUsableLocs, 0); //You can't add AIs into a save
              end;
    else      begin
                SetLength(HumanUsableLocs, 0);
                SetLength(AIUsableLocs, 0);
              end;
  end;
  if not fNetPlayers.ValidateSetup(HumanUsableLocs, AIUsableLocs, ErrorMessage) then
  begin
    PostLocalMessage(Format(gResTexts[TX_LOBBY_CANNOT_START], [ErrorMessage]), csSystem);
    Exit;
  end;

  //ValidateSetup removes closed players if successful, so our index changes
  fMyIndex := fNetPlayers.NiknameToLocal(fMyNikname);
  fHostIndex := fMyIndex;

  //Init random seed for all the players
  fNetGameOptions.RandomSeed := RandomRange(1, 2147483646);

  //Let everyone start with final version of fNetPlayers and fNetGameOptions
  SendGameOptions;

  M := TKMemoryStream.Create;
  M.Write(fHostIndex);
  fNetPlayers.SaveToStream(M);
  PacketSend(NET_ADDRESS_OTHERS, mk_Start, M);
  M.Free;

  StartGame;
end;


procedure TKMNetworking.SendPlayerListAndRefreshPlayersSetup(aPlayerIndex: Integer = NET_ADDRESS_OTHERS);
var
  I: Integer;
  M: TKMemoryStream;
begin
  Assert(IsHost, 'Only host can send player list');

  //In saves we should load team and color from the SaveInfo
  if (fNetGameState = lgs_Lobby) and (fSelectGameKind = ngk_Save) then
    for i:=1 to NetPlayers.Count do
      if (NetPlayers[i].StartLocation <> LOC_RANDOM) and (NetPlayers[i].StartLocation <> LOC_SPECTATE) then
      begin
        NetPlayers[i].FlagColorID := fSaveInfo.Info.ColorID[NetPlayers[i].StartLocation-1];
        NetPlayers[i].Team := fSaveInfo.Info.Team[NetPlayers[i].StartLocation-1];
      end
      else
        //Spectators may still change their color
        NetPlayers[i].Team := 0;

  fMyIndex := fNetPlayers.NiknameToLocal(fMyNikname); //The host's index can change when players are removed
  fHostIndex := fMyIndex;

  fOnMPGameInfoChanged(Self); //Tell the server about the changes

  M := TKMemoryStream.Create;
  M.Write(fHostIndex);
  fNetPlayers.SaveToStream(M);
  PacketSend(aPlayerIndex, mk_PlayersList, M);
  M.Free;

  if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
end;


procedure TKMNetworking.UpdateGameOptions(aPeacetime: Word; aSpeedPT, aSpeedAfterPT: Single);
begin
  fNetGameOptions.Peacetime := aPeacetime;
  fNetGameOptions.SpeedPT := aSpeedPT;
  fNetGameOptions.SpeedAfterPT := aSpeedAfterPT;

  fNetPlayers.ResetReady;
  fNetPlayers[fMyIndex].ReadyToStart := True;

  SendGameOptions;
  SendPlayerListAndRefreshPlayersSetup;
end;


procedure TKMNetworking.SendGameOptions;
var
  M: TKMemoryStream;
begin
  Assert(IsHost, 'Only host can send game options');

  M := TKMemoryStream.Create;
  fNetGameOptions.Save(M);
  PacketSend(NET_ADDRESS_OTHERS, mk_GameOptions, M);
  M.Free;
end;


procedure TKMNetworking.RequestFileTransfer;
begin
  if fFileReceiver = nil then
    case fMissingFileType of
      ngk_Map:  begin
                  fFileReceiver := TKMFileReceiver.Create(kttMap, fMissingFileName, fMissingFileCRC);
                  PacketSendW(NET_ADDRESS_HOST, mk_FileRequest, fMissingFileName);
                end;
      ngk_Save: begin
                  fFileReceiver := TKMFileReceiver.Create(kttSave, fMissingFileName);
                  PacketSendW(NET_ADDRESS_HOST, mk_FileRequest, fMissingFileName);
                end;
    end;
end;


procedure TKMNetworking.VoteReturnToLobby;
begin
  //Even if we are the host we still send our vote through the network, that's simpler
  PacketSend(NET_ADDRESS_HOST, mk_Vote);
end;


procedure TKMNetworking.ConsoleCommand(aText: UnicodeString);
{var
  s,PlayerID: Integer;
  ConsoleCmd: UnicodeString;}
begin
  {PostLocalMessage('[$808080]' + aText + '[]');
  s := PosEx(' ', aText);
  if s = 0 then s := Length(aText) + 1;

  ConsoleCmd := LowerCase(LeftStr(aText, s-1));

  if ConsoleCmd = '/kick' then
  begin
    if not IsHost then
    begin
      PostLocalMessage('Only the host can kick players', False);
      Exit;
    end;
    if (Length(aText) >= s+1) and TryStrToInt(aText[s+1], PlayerID)
    and InRange(PlayerID, 1, fNetPlayers.Count) then
    begin
      if fNetPlayers[PlayerID].IsHuman
      and (PlayerID <> MyIndex) then
        KickPlayer(PlayerID)
      else
        PostLocalMessage('You cannot kick yourself or AI players', False);
    end
    else
      PostLocalMessage('Invalid syntax. Type /help for more info', False);
  end
  else
  if ConsoleCmd = '/help' then
    PostLocalMessage('The following console commands are available:|' +
                     '    /kick <Player ID> - Kicks a player from the lobby|' +
                   //'    /ban <Player ID> - Kicks and bans a player from the lobby|'+
                   //'    /newhost <Player ID> - Changes the host player|'+
                     '    /help - Displays this page|' +
                     'Player IDs:|' +
                     fNetPlayers.GetPlayersWithIDs, False)
  else
  begin
    PostLocalMessage('Unknown console command "' + aText + '". Type /help for more info', False);
  end;}
end;


//We route the message through Server to ensure everyone sees messages in the same order
//with exact same timestamps (possibly added by Server?)
procedure TKMNetworking.PostChat(aText: UnicodeString; aMode: TChatMode; aRecipientServerIndex: Integer=-1);
var
  I: Integer;
  M: TKMemoryStream;
begin
  //Sending chat during reconnections at best causes messages to be lost and at worst causes crashes due to intermediate connecting states
  if IsReconnecting then
    Exit; //Fallback in case UI check fails

  M := TKMemoryStream.Create;
  M.Write(aMode, SizeOf(aMode));
  M.Write(aRecipientServerIndex);
  M.WriteW(aText);

  case aMode of
    cmTeam:
      if NetPlayers[fMyIndex].Team = 0 then
        PacketSend(fMyIndexOnServer, mk_TextChat, M) //Send to self only if we have no team
      else
        for I := 1 to NetPlayers.Count do
          if (NetPlayers[I].Team = NetPlayers[fMyIndex].Team) and NetPlayers[I].IsHuman and (NetPlayers[I].IndexOnServer <> -1) then
            PacketSend(NetPlayers[I].IndexOnServer, mk_TextChat, M); //Send to each player on team (includes self)

    cmSpectators:
      for I := 1 to NetPlayers.Count do
        if NetPlayers[I].IsSpectator and NetPlayers[I].IsHuman and (NetPlayers[I].IndexOnServer <> -1) then
          PacketSend(NetPlayers[I].IndexOnServer, mk_TextChat, M); //Send to each spectator (includes self)

    cmWhisper:
      begin
        PacketSend(aRecipientServerIndex, mk_TextChat, M); //Send to specific player
        PacketSend(fMyIndexOnServer, mk_TextChat, M); //Send to self as well so the player sees it
      end;

    cmAll:
      PacketSend(NET_ADDRESS_ALL, mk_TextChat, M); //Send to all;
  end;
  M.Free;
end;


procedure TKMNetworking.PostMessage(aTextID: Integer; aSound: TChatSound; aText1: UnicodeString=''; aText2: UnicodeString = ''; aRecipient:Integer=NET_ADDRESS_ALL);
var M: TKMemoryStream;
begin
  M := TKMemoryStream.Create;
  M.Write(aTextID);
  M.Write(aSound, SizeOf(aSound));
  M.WriteW(aText1);
  M.WriteW(aText2);
  PacketSend(aRecipient, mk_TextTranslated, M);
  M.Free;
end;


procedure TKMNetworking.PostLocalMessage(aText: UnicodeString; aSound: TChatSound);
const
  ChatSound: array[TChatSound] of TSoundFXNew = (sfxn_MPChatSystem, //csNone
                                                 sfxn_MPChatSystem, //csJoin
                                                 sfxn_MPChatSystem, //csLeave
                                                 sfxn_MPChatSystem, //csSystem
                                                 sfxn_MPChatSystem, //csGameStart
                                                 sfxn_MPChatSystem, //csSaveGame
                                                 sfxn_MPChatMessage,//csChat
                                                 sfxn_MPChatTeam,   //csChatTeam
                                                 sfxn_MPChatTeam);  //csChatWhisper
begin
  if Assigned(fOnTextMessage) then
  begin
    fOnTextMessage(aText);
    if aSound <> csNone then gSoundPlayer.Play(ChatSound[aSound]);
  end;
end;


//Send our commands to either to all players, or to specified one
procedure TKMNetworking.SendCommands(aStream: TKMemoryStream; aPlayerIndex: ShortInt = -1);
begin
  if aPlayerIndex = -1 then
    PacketSend(NET_ADDRESS_OTHERS, mk_Commands, aStream)
  else
    PacketSend(fNetPlayers[aPlayerIndex].IndexOnServer, mk_Commands, aStream);
end;


procedure TKMNetworking.AttemptReconnection;
begin
  if fReconnectRequested = 0 then fReconnectRequested := TimeGet; //Do it soon
end;


procedure TKMNetworking.DoReconnection;
var TempMyIndex:integer;
begin
  if WRITE_RECONNECT_LOG then gLog.AddTime(Format('DoReconnection: %s',[fMyNikname]));
  fReconnectRequested := 0;
  PostLocalMessage(gResTexts[TX_NET_RECONNECTING], csSystem);
  //Stop the previous connection without calling Self.Disconnect as that frees everything
  fNetClient.Disconnect;
  TempMyIndex := fMyIndex;
  Join(fServerAddress,fServerPort,fMyNikname,fRoomToJoin, true); //Join the same server/room as before in reconnecting mode
  fMyIndex := TempMyIndex; //Join overwrites it, but we must remember it
end;


procedure TKMNetworking.PlayerJoined(aServerIndex: Integer; aPlayerName: AnsiString);
begin
  fNetPlayers.AddPlayer(aPlayerName, aServerIndex, '');
  PacketSend(aServerIndex, mk_AllowToJoin);
  SendMapOrSave(aServerIndex); //Send the map first so it doesn't override starting locs

  if fSelectGameKind = ngk_Save then MatchPlayersToSave(fNetPlayers.ServerToLocal(aServerIndex)); //Match only this player
  SendPlayerListAndRefreshPlayersSetup;
  SendGameOptions;
  PostMessage(TX_NET_HAS_JOINED, csJoin, UnicodeString(aPlayerName));
end;


function TKMNetworking.CalculateGameCRC:Cardinal;
begin
  //CRC checks are done on the data we already loaded, not the files on HDD which can change.
  Result := gResource.GetDATCRC;

  //For debugging/testing it's useful to skip this check sometimes (but defines .dat files should always be checked)
  if not SKIP_EXE_CRC then
    Result := Result xor Adler32CRC(Application.ExeName);
end;


function TKMNetworking.CanTakeLocation(aPlayer, aLoc: Integer; AllowSwapping: Boolean): Boolean;
begin
  Result := True;
  if (aLoc <> LOC_SPECTATE) and (aLoc <> LOC_RANDOM) then
    case fSelectGameKind of
      ngk_Map:  Result := (fMapInfo <> nil) and fMapInfo.IsValid and (aLoc <= fMapInfo.LocCount);
      ngk_Save: Result := (fSaveInfo <> nil) and fSaveInfo.IsValid and (aLoc <= fSaveInfo.Info.PlayerCount);
      ngk_None: Result := False;
    end;

  //If we are currently a spectator wanting to be a non-spectator, make sure there is a slot for us
  if fNetPlayers[aPlayer].IsSpectator and (aLoc <> LOC_SPECTATE) then
    Result := Result and (NetPlayers.Count-NetPlayers.GetSpectatorCount < MAX_LOBBY_PLAYERS);

  //Can't be a spectator if they are disabled
  if (aLoc = LOC_SPECTATE) and not fNetPlayers.SpectatorsAllowed then
    Result := False;

  //If we are trying to be a spectator and aren't one already, make sure there is an open spectator slot
  if (aLoc = LOC_SPECTATE) and not fNetPlayers[aPlayer].IsSpectator then
    Result := Result and ((NetPlayers.SpectatorSlotsOpen = MAX_LOBBY_SPECTATORS) //Means infinite spectators allowed
                          or (NetPlayers.SpectatorSlotsOpen-NetPlayers.GetSpectatorCount > 0));

  //Check with NetPlayers that the location isn't taken already, unless it's our current location
  //Host may be allowed to swap when HostDoesSetup is set, meaning it doesn't matter if loc is taken
  if (aLoc <> fNetPlayers[aPlayer].StartLocation) and not AllowSwapping then
    Result := Result and fNetPlayers.LocAvailable(aLoc);
end;


procedure TKMNetworking.GameCreated;
begin
  case fNetPlayerKind of
    lpk_Host:   begin
                  fNetPlayers[fMyIndex].ReadyToPlay := True;
                  PacketSend(NET_ADDRESS_OTHERS, mk_ReadyToPlay);
                  SendPlayerListAndRefreshPlayersSetup; //Initialise the in-game player setup
                  //Check this here because it is possible to start a multiplayer game without other humans, just AI (at least for debugging)
                  TryPlayGame;
                end;
    lpk_Joiner: begin
                  fNetPlayers[fMyIndex].ReadyToPlay := True;
                  PacketSend(NET_ADDRESS_OTHERS, mk_ReadyToPlay);
                end;
  end;
end;


procedure TKMNetworking.PacketRecieve(aNetClient: TKMNetClient; aSenderIndex: Integer; aData: Pointer; aLength: Cardinal);
var
  M, M2: TKMemoryStream;
  Kind: TKMessageKind;
  err: UnicodeString;
  tmpInteger: Integer;
  tmpCRC: Cardinal;
  tmpBoolean: Boolean;
  tmpStringA, replyStringA: AnsiString;
  tmpStringW, replyStringW: UnicodeString;
  tmpChatMode: TChatMode;
  I,LocID,TeamID,ColorID,PlayerIndex: Integer;
  ChatSound: TChatSound;
begin
  Assert(aLength >= 1, 'Unexpectedly short message'); //Kind, Message
  if not Connected then Exit;

  M := TKMemoryStream.Create;
  try
    M.WriteBuffer(aData^, aLength);
    M.Position := 0;
    M.Read(Kind, SizeOf(TKMessageKind)); //Depending on kind message contains either Text or a Number

    //Make sure we are allowed to receive this packet at this point
    if not (Kind in NetAllowedPackets[fNetGameState]) then
    begin
      //When querying or reconnecting to a host we may receive data such as commands, player setup, etc. These should be ignored.
      if not (fNetGameState in [lgs_Query, lgs_Reconnecting]) then
      begin
        err := 'Received a packet not intended for this state (' +
          GetEnumName(TypeInfo(TNetGameState), Integer(fNetGameState)) + '): ' +
          GetEnumName(TypeInfo(TKMessageKind), Integer(Kind));
        //These warnings sometimes happen when returning to lobby, log them but don't show user
        gLog.AddTime(err);
        //PostLocalMessage('Error: ' + err, csSystem);
      end;
      Exit;
    end;

    if NET_SHOW_EACH_MSG and not (Kind in [mk_Ping, mk_PingInfo, mk_FPS]) then
      PostLocalMessage(GetEnumName(TypeInfo(TKMessageKind), Integer(Kind)), csNone);

    case Kind of
      mk_GameVersion:
              begin
                M.ReadA(tmpStringA);
                if tmpStringA <> NET_PROTOCOL_REVISON then
                begin
                  Assert(not IsHost);
                  fOnJoinFail(Format(gResTexts[TX_MP_MENU_WRONG_VERSION], [NET_PROTOCOL_REVISON, tmpStringA]));
                  fNetClient.Disconnect;
                  Exit;
                end;
              end;

      mk_WelcomeMessage:
              begin
                M.ReadW(tmpStringW);
                fWelcomeMessage := tmpStringW;
              end;

      mk_ServerName:
              begin
                M.ReadW(tmpStringW);
                fServerName := tmpStringW;
              end;

      mk_IndexOnServer:
              begin
                M.Read(tmpInteger);
                fMyIndexOnServer := tmpInteger;
                //PostLocalMessage('Index on Server - ' + inttostr(fMyIndexOnServer));
                //Now join the room we planned to
                PacketSend(NET_ADDRESS_SERVER, mk_JoinRoom, fRoomToJoin);
              end;

      mk_ConnectedToRoom:
              begin
                M.Read(tmpInteger); //Host's index
                //See if the server assigned hosting rights to us
                if tmpInteger = fMyIndexOnServer then
                begin
                  fNetPlayerKind := lpk_Host;

                  //Enter the lobby if we had hosting rights assigned to us
                  if Assigned(fOnJoinAssignedHost) then
                    fOnJoinAssignedHost(Self);

                  PostLocalMessage(gResTexts[TX_LOBBY_HOST_RIGHTS], csNone);
                end;

                //We are now clear to proceed with our business
                if fNetGameState = lgs_Reconnecting then
                begin
                  if IsHost then
                  begin
                    if WRITE_RECONNECT_LOG then gLog.AddTime('Hosting reconnection');
                    //The other players must have been disconnected too, so we will be the host now
                    SetGameState(lgs_Game); //We are now in control of the game, so we are no longer reconnecting
                    //At this point we now know that every other client was dropped, but we probably missed the disconnect messages
                    fNetPlayers.DisconnectAllClients(fMyNikname); //Mark all human players as disconnected, except for self
                    //Set our new index on server
                    fNetPlayers[fNetPlayers.NiknameToLocal(fMyNikname)].SetIndexOnServer := fMyIndexOnServer;
                  end
                  else
                  begin
                    PacketSendA(NET_ADDRESS_HOST, mk_AskToReconnect, fMyNikname);
                    fJoinTimeout := TimeGet; //Wait another X seconds for host to reply before timing out
                    if WRITE_RECONNECT_LOG then gLog.AddTime('Asking to reconnect');
                  end;
                end
                else
                  case fNetPlayerKind of
                    lpk_Host:
                        begin
                          fNetPlayers.AddPlayer(fMyNikname, fMyIndexOnServer, gResLocales.UserLocale);
                          fMyIndex := fNetPlayers.NiknameToLocal(fMyNikname);
                          fHostIndex := fMyIndex;
                          fNetPlayers[fMyIndex].ReadyToStart := True;
                          if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
                          SetGameState(lgs_Lobby);
                          gSoundPlayer.Play(sfxn_MPChatSystem); //Sound for joining the lobby
                          if fWelcomeMessage <> '' then PostLocalMessage(fWelcomeMessage, csNone);
                        end;
                    lpk_Joiner:
                    begin
                        SetGameState(lgs_Query);
                        fJoinTimeout := TimeGet; //Wait another X seconds for host to reply before timing out
                        M2 := TKMemoryStream.Create;
                        TKMNetSecurity.GenerateChallenge(M2, tmpInteger);
                        PacketSend(NET_ADDRESS_HOST, mk_AskForAuth, M2);
                        M2.Free;
                    end;
                  end;
              end;

      mk_AskToReconnect:
              begin
                M.ReadA(tmpStringA);
                PlayerIndex := fNetPlayers.NiknameToLocal(tmpStringA);
                tmpInteger := fNetPlayers.CheckCanReconnect(PlayerIndex);
                if tmpInteger = -1 then
                begin
                  if WRITE_RECONNECT_LOG then gLog.AddTime(UnicodeString(tmpStringA) + ' successfully reconnected');
                  fNetPlayers[PlayerIndex].SetIndexOnServer := aSenderIndex; //They will have a new index
                  fNetPlayers[PlayerIndex].Connected := True; //This player is now back online
                  SendPlayerListAndRefreshPlayersSetup;
                  PacketSend(aSenderIndex, mk_ReconnectionAccepted); //Tell this client they are back in the game
                  PacketSend(NET_ADDRESS_OTHERS, mk_ClientReconnected, aSenderIndex); //Tell everyone to ask him to resync
                  PacketSend(aSenderIndex, mk_ResyncFromTick, Integer(fLastProcessedTick)); //Ask him to resync us
                  PostMessage(TX_NET_HAS_RECONNECTED, csJoin, UnicodeString(tmpStringA));
                end
                else
                begin
                  if WRITE_RECONNECT_LOG then gLog.AddTime(UnicodeString(tmpStringA) + ' asked to reconnect: ' + IntToStr(tmpInteger));
                  PacketSend(aSenderIndex, mk_RefuseReconnect, tmpInteger);
                end;
              end;

      mk_RefuseReconnect:
              begin
                M.Read(tmpInteger);
                //If the result is < 1 is means silently ignore and keep retrying
                if tmpInteger > 0 then
                  PostLocalMessage(Format(gResTexts[TX_NET_RECONNECTION_FAILED], [gResTexts[tmpInteger]]), csSystem);
                if Assigned(fOnJoinFail) then
                  fOnJoinFail('');
              end;

      mk_AskToJoin:
              if IsHost then
              begin
                if not TKMNetSecurity.ValidateSolution(M, aSenderIndex) then
                  tmpInteger := TX_NET_YOUR_DATA_FILES
                else
                begin
                  M.ReadA(tmpStringA);
                  tmpInteger := fNetPlayers.CheckCanJoin(tmpStringA, aSenderIndex);
                  if (tmpInteger = -1) and (fNetGameState <> lgs_Lobby) then
                    tmpInteger := TX_NET_GAME_IN_PROGRESS;
                end;
                if tmpInteger = -1 then
                begin
                  //Password was checked by server already
                  PlayerJoined(aSenderIndex, tmpStringA);
                end
                else
                begin
                  PacketSend(aSenderIndex, mk_RefuseToJoin, tmpInteger);
                  //Force them to reconnect and ask for a new challenge
                  PacketSend(NET_ADDRESS_SERVER, mk_KickPlayer, aSenderIndex);
                end;
              end;

      mk_FileRequest:
              if IsHost then
              begin
                //Validate request and set up file sender
                M.ReadW(tmpStringW);
                case fSelectGameKind of
                  ngk_Map:  if (tmpStringW <> MapInfo.FileName)
                            or not fFileSenderManager.StartNewSend(kttMap, MapInfo.FileName, aSenderIndex) then
                              PacketSend(aSenderIndex, mk_FileEnd); //Abort
                  ngk_Save: if (tmpStringW <> SaveInfo.FileName)
                            or not fFileSenderManager.StartNewSend(kttSave, SaveInfo.FileName, aSenderIndex) then
                              PacketSend(aSenderIndex, mk_FileEnd); //Abort
                end;
              end;

      mk_FileChunk:
              if not IsHost and (fFileReceiver <> nil) then
              begin
                fFileReceiver.DataReceived(M);
                PacketSend(aSenderIndex, mk_FileAck);
                if Assigned(fOnFileTransferProgress) then
                  fOnFileTransferProgress(fFileReceiver.TotalSize, fFileReceiver.ReceivedSize);
              end;

      mk_FileAck:
              if IsHost then
                fFileSenderManager.AckReceived(aSenderIndex);

      mk_FileEnd:
              if not IsHost and (fFileReceiver <> nil) then
              begin
                fFileReceiver.ProcessTransfer;
                FreeAndNil(fFileReceiver);
              end;

      mk_LangCode:
              begin
                M.ReadA(tmpStringA);
                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if PlayerIndex <> -1 then
                  fNetPlayers[PlayerIndex].LangCode := tmpStringA;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mk_AllowToJoin:
              if fNetPlayerKind = lpk_Joiner then
              begin
                fOnJoinSucc(Self); //Enter lobby
                SetGameState(lgs_Lobby);
                //No need to play a sound here, host will send "<player> has joined" message
                if fWelcomeMessage <> '' then PostLocalMessage(fWelcomeMessage, csNone);
                PacketSendA(NET_ADDRESS_HOST, mk_LangCode, gResLocales.UserLocale);
              end;

      mk_RefuseToJoin:
              if fNetPlayerKind = lpk_Joiner then
              begin
                M.Read(tmpInteger);
                fNetClient.Disconnect;
                fOnJoinFail(gResTexts[tmpInteger]);
              end;

      mk_ReqPassword:
              begin
                fEnteringPassword := True; //Disables timing out
                fOnJoinPassword(Self);
              end;

      mk_AskForAuth:
              if IsHost then
              begin
                //We should refuse the joiner immediately if we are not in the lobby
                if fNetGameState <> lgs_Lobby then
                  PacketSend(aSenderIndex, mk_RefuseToJoin, TX_NET_GAME_IN_PROGRESS)
                else
                begin
                  //Solve joiner's challenge
                  M2 := TKMNetSecurity.SolveChallenge(M, aSenderIndex);
                  //Send our own challenge
                  TKMNetSecurity.GenerateChallenge(M2, aSenderIndex);
                  PacketSend(aSenderIndex, mk_AuthChallenge, M2);
                  M2.Free;
                end;
              end;

      mk_AuthChallenge:
              begin
                //Validate solution the host sent back to us
                if TKMNetSecurity.ValidateSolution(M, aSenderIndex) then
                begin
                  //Solve host's challenge and ask to join
                  M2 := TKMNetSecurity.SolveChallenge(M, aSenderIndex);
                  M2.WriteA(fMyNikname);
                  PacketSend(NET_ADDRESS_HOST, mk_AskToJoin, M2);
                  M2.Free;
                end
                else
                  fOnJoinFail(gResTexts[TX_NET_YOUR_DATA_FILES]);
              end;

      mk_Kicked:
              begin
                M.Read(tmpInteger);
                fOnDisconnect(gResTexts[tmpInteger]);
              end;

      mk_ClientLost:
              begin
                M.Read(tmpInteger);
                if IsHost then
                begin
                  fFileSenderManager.ClientDisconnected(tmpInteger);
                  PlayerIndex := fNetPlayers.ServerToLocal(tmpInteger);
                  if PlayerIndex = -1 then exit; //Has already disconnected or not from our room
                  if not fNetPlayers[PlayerIndex].Dropped then
                  begin
                    PostMessage(TX_NET_LOST_CONNECTION, csLeave, UnicodeString(fNetPlayers[PlayerIndex].Nikname));
                    if WRITE_RECONNECT_LOG then gLog.AddTime(UnicodeString(fNetPlayers[PlayerIndex].Nikname)+' lost connection');
                  end;
                  if fNetGameState = lgs_Game then
                    fNetPlayers.DisconnectPlayer(tmpInteger)
                  else
                    if fNetGameState = lgs_Loading then
                    begin
                      fNetPlayers.DropPlayer(tmpInteger);
                      TryPlayGame;
                    end
                    else
                      fNetPlayers.RemServerPlayer(tmpInteger);
                  SendPlayerListAndRefreshPlayersSetup;
                end
                else
                  if fNetPlayers.ServerToLocal(tmpInteger) <> -1 then
                  begin
                    if fNetGameState = lgs_Game then
                      fNetPlayers.DisconnectPlayer(tmpInteger)
                    else
                      if fNetGameState = lgs_Loading then
                        fNetPlayers.DropPlayer(tmpInteger)
                      else
                        fNetPlayers.RemServerPlayer(tmpInteger); //Remove the player anyway as it might be the host that was lost
                  end;
              end;

      mk_Disconnect:
              case fNetPlayerKind of
                lpk_Host:
                    begin
                      fFileSenderManager.ClientDisconnected(aSenderIndex);
                      if fNetPlayers.ServerToLocal(aSenderIndex) = -1 then exit; //Has already disconnected
                      PostMessage(TX_NET_HAS_QUIT, csLeave, UnicodeString(fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].Nikname));
                      if fNetGameState in [lgs_Loading, lgs_Game] then
                        fNetPlayers.DropPlayer(aSenderIndex)
                      else
                        fNetPlayers.RemServerPlayer(aSenderIndex);
                      SendPlayerListAndRefreshPlayersSetup;
                      //Player leaving may cause vote to end
                      if (fNetGameState in [lgs_Loading, lgs_Game])
                      and (fNetPlayers.FurtherVotesNeededForMajority <= 0) then
                      begin
                        fNetPlayers.ResetVote;
                        //This packet is also sent to ourself (host), we will return to lobby when it arrives
                        PacketSend(NET_ADDRESS_ALL, mk_ReturnToLobby);
                      end;
                    end;
                lpk_Joiner:
                    begin
                      PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                      if PlayerIndex = -1 then exit; //Has already disconnected
                      PostLocalMessage(Format(gResTexts[TX_MULTIPLAYER_HOST_DISCONNECTED], [fNetPlayers[PlayerIndex].Nikname]), csLeave);
                      if fNetGameState in [lgs_Loading, lgs_Game] then
                        fNetPlayers.DropPlayer(aSenderIndex)
                      else
                        fNetPlayers.RemServerPlayer(aSenderIndex);
                    end;
              end;

      mk_ReassignHost:
              begin
                M.Read(tmpInteger);
                if fFileReceiver <> nil then
                begin
                  FreeAndNil(fFileReceiver); //Transfer is aborted if host disconnects/changes
                  if Assigned(fOnMapMissing) then fOnMapMissing(tmpStringW, False); //Reset, otherwise it will freeze in "downloading" state
                end;
                if IsHost then
                begin
                  //We are no longer the host
                  fFileSenderManager.AbortAllTransfers;
                  fNetPlayerKind := lpk_Joiner;
                  if Assigned(fOnReassignedJoiner) then fOnReassignedJoiner(Self); //Lobby/game might need to know
                  if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
                end;
                if tmpInteger = fMyIndexOnServer then
                begin
                  //We are now the host
                  fNetPlayerKind := lpk_Host;
                  fMyIndex := fNetPlayers.NiknameToLocal(fMyNikname);
                  if Assigned(fOnReassignedHost) then fOnReassignedHost(Self); //Lobby/game might need to know that we are now hosting

                  case fNetGameState of
                    lgs_Lobby:   begin
                                   if InRange(fHostIndex, 1, fNetPlayers.Count) then
                                     fNetPlayers[fHostIndex].ReadyToStart := False; //Old host is not ready anymore
                                   fNetPlayers[fMyIndex].ReadyToStart := True; //The host is always ready
                                   fNetPlayers.SetAIReady; //Set all AI players to ready
                                   SendGameOptions; //Only needs to be sent when in the lobby. Our version becomes standard.
                                 end;
                    lgs_Loading: begin
                                   if Assigned(fOnReadyToPlay) then fOnReadyToPlay(Self);
                                   TryPlayGame;
                                 end;
                  end;

                  fHostIndex := MyIndex; //Set it down here as it is used above

                  //Server tells us the password and description in this packet,
                  //so they aren't reset when the host is changed
                  M.ReadA(tmpStringA);
                  M.ReadW(tmpStringW);
                  fPassword := tmpStringA;
                  fDescription := tmpStringW;

                  fOnMPGameInfoChanged(Self);
                  if (fSelectGameKind = ngk_None)
                  or ((fSelectGameKind = ngk_Map)  and (not MapInfo.IsValid or (MapInfo.MapFolder = mfDL)))
                  or ((fSelectGameKind = ngk_Save) and not SaveInfo.IsValid) then
                    SelectNoMap(''); //In case the previous host had the map and we don't
                  SendPlayerListAndRefreshPlayersSetup;
                  PostMessage(TX_NET_HOSTING_RIGHTS, csSystem, UnicodeString(fMyNikname));
                  if WRITE_RECONNECT_LOG then gLog.AddTime('Hosting rights reassigned to us ('+UnicodeString(fMyNikname)+')');
                end;
              end;

      mk_Ping:
              PacketSend(aSenderIndex, mk_Pong); //Server will intercept this message

      mk_PingInfo:
              begin
                DecodePingInfo(M);
                if Assigned(fOnPingInfo) then fOnPingInfo(Self);
              end;

      mk_FPS:
              begin
                M.Read(tmpInteger);
                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if PlayerIndex = -1 then Exit;
                fNetPlayers[PlayerIndex].FPS := Cardinal(tmpInteger);
                if Assigned(fOnPingInfo) then fOnPingInfo(Self);
              end;

      mk_PlayersList:
              if fNetPlayerKind = lpk_Joiner then
              begin
                M.Read(fHostIndex);
                fNetPlayers.LoadFromStream(M); //Our index could have changed on players add/removal
                fMyIndex := fNetPlayers.NiknameToLocal(fMyNikname);
                if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
              end;

      mk_GameOptions:
              if fNetPlayerKind = lpk_Joiner then
              begin
                fNetGameOptions.Load(M);
                if Assigned(fOnGameOptions) then fOnGameOptions(Self);
              end;

      mk_ResetMap:
              begin
                FreeAndNil(fFileReceiver); //Any ongoing transfer is cancelled
                fSelectGameKind := ngk_None;
                FreeAndNil(fMapInfo);
                FreeAndNil(fSaveInfo);
                if Assigned(fOnMapName) then fOnMapName('');
              end;

      mk_MapSelect:
              if fNetPlayerKind = lpk_Joiner then
              begin
                FreeAndNil(fFileReceiver); //Any ongoing transfer is cancelled
                M.ReadW(tmpStringW); //Map name
                M.Read(tmpCRC); //CRC
                //Try to load map from MP or DL folder
                FreeAndNil(fMapInfo);
                fMapInfo := TKMapInfo.Create(tmpStringW, True, mfMP);
                if not fMapInfo.IsValid or (fMapInfo.CRC <> tmpCRC) then
                begin
                  fMapInfo := TKMapInfo.Create(tmpStringW+'_'+IntToHex(Integer(tmpCRC), 8), True, mfDL);
                  if not fMapInfo.IsValid or (fMapInfo.CRC <> tmpCRC) then
                    FreeAndNil(fMapInfo);
                end;

                if fMapInfo <> nil then
                begin
                  fSelectGameKind := ngk_Map;
                  fMapInfo.LoadExtra; //Lobby requires extra map info such as CanBeHuman
                  if Assigned(fOnMapName) then fOnMapName(fMapInfo.FileName);
                end
                else
                begin
                  fMissingFileType := ngk_Map;
                  fMissingFileName := tmpStringW;
                  fMissingFileCRC := tmpCRC;
                  fSelectGameKind := ngk_None;
                  if Assigned(fOnMapName) then fOnMapName(tmpStringW);
                  if Assigned(fOnMapMissing) then fOnMapMissing(tmpStringW + '_' + IntToHex(Integer(tmpCRC), 8), False);
                end;
                if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
              end;

      mk_SaveSelect:
              if fNetPlayerKind = lpk_Joiner then
              begin
                FreeAndNil(fFileReceiver); //Any ongoing transfer is cancelled
                M.ReadW(tmpStringW); //Save name
                M.Read(tmpCRC); //CRC

                //See if the host selected the same save we already downloaded
                FreeAndNil(fSaveInfo);
                fSaveInfo := TKMSaveInfo.Create(ExeDir + 'SavesMP' + PathDelim, DOWNLOADED_LOBBY_SAVE);
                if fSaveInfo.IsValid and (fSaveInfo.CRC = tmpCRC) then
                begin
                  fSelectGameKind := ngk_Save;
                  if Assigned(fOnMapName) then fOnMapName(tmpStringW);
                  if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
                end
                else
                begin
                  FreeAndNil(fSaveInfo);
                  fSelectGameKind := ngk_None;
                  //Save file does not exist, so downloaded it
                  fMissingFileType := ngk_Save;
                  fMissingFileName := tmpStringW;
                  if Assigned(fOnMapMissing) then fOnMapMissing(tmpStringW, True);
                end;
              end;

      mk_StartingLocQuery:
              if IsHost and not fNetPlayers.HostDoesSetup then
              begin
                M.Read(tmpInteger);
                LocID := tmpInteger;
                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if CanTakeLocation(PlayerIndex, LocID, False) then
                begin //Update Players setup
                  fNetPlayers[PlayerIndex].StartLocation := LocID;
                  //Spectators can't have team
                  if LocID = LOC_SPECTATE then
                    fNetPlayers[PlayerIndex].Team := 0;
                  SendPlayerListAndRefreshPlayersSetup;
                end
                else //Quietly refuse
                  SendPlayerListAndRefreshPlayersSetup(aSenderIndex);
              end;

      mk_SetTeam:
              if IsHost and not fNetPlayers.HostDoesSetup then
              begin
                M.Read(tmpInteger);
                TeamID := tmpInteger;
                //Update Players setup
                fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].Team := TeamID;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mk_FlagColorQuery:
              if IsHost then
              begin
                M.Read(tmpInteger);
                ColorID := tmpInteger;
                //The player list could have changed since the joiner sent this request (over slow connection)
                if fNetPlayers.ColorAvailable(ColorID) then
                begin
                  fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].FlagColorID := ColorID;
                  SendPlayerListAndRefreshPlayersSetup;
                end
                else //Quietly refuse
                  SendPlayerListAndRefreshPlayersSetup(aSenderIndex);
              end;

      mk_ReturnToLobby:
              if Assigned(fOnReturnToLobby) then
                fOnReturnToLobby(Self);

      mk_ReadyToStart:
              if IsHost then
              begin
                fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].ReadyToStart := not fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].ReadyToStart;
                SendPlayerListAndRefreshPlayersSetup;
              end;

      mk_Start:
              if fNetPlayerKind = lpk_Joiner then
              begin
                M.Read(fHostIndex);
                fNetPlayers.LoadFromStream(M);
                fMyIndex := fNetPlayers.NiknameToLocal(fMyNikname);
                StartGame;
              end;

      mk_ReadyToPlay:
              begin
                fNetPlayers[fNetPlayers.ServerToLocal(aSenderIndex)].ReadyToPlay := true;
                if Assigned(fOnReadyToPlay) then fOnReadyToPlay(Self);
                if IsHost then TryPlayGame;
              end;

      mk_Play:
              if fNetPlayerKind = lpk_Joiner then PlayGame;

      mk_Commands:
              begin
                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if (PlayerIndex<>-1) and not fNetPlayers[PlayerIndex].Dropped then
                  if Assigned(fOnCommands) then fOnCommands(M, PlayerIndex);
              end;

      mk_ResyncFromTick:
              begin
                M.Read(tmpInteger);
                if WRITE_RECONNECT_LOG then gLog.AddTime('Asked to resync from tick ' + IntToStr(tmpInteger));
                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if Assigned(fOnResyncFromTick) and (PlayerIndex<>-1) then
                begin
                  if WRITE_RECONNECT_LOG then gLog.AddTime('Resyncing player ' + UnicodeString(fNetPlayers[PlayerIndex].Nikname));
                  fOnResyncFromTick(PlayerIndex, Cardinal(tmpInteger));
                end;
              end;

      mk_ReconnectionAccepted:
              begin
                //The host has accepted us back into the game!
                if WRITE_RECONNECT_LOG then gLog.AddTime('Reconnection Accepted');
                SetGameState(lgs_Game); //Game is now running once again
                fReconnectRequested := 0; //Cancel any retry in progress
                //Request all other clients to resync us
                PacketSend(NET_ADDRESS_OTHERS, mk_ResyncFromTick, Integer(fLastProcessedTick));
              end;

      mk_ClientReconnected:
              begin
                M.Read(tmpInteger);
                //The host has accepted a disconnected client back into the game. Request this client to resync us
                if tmpInteger = fMyIndexOnServer then exit;
                if WRITE_RECONNECT_LOG then gLog.AddTime('Requesting resync for reconnected client');
                PacketSend(tmpInteger, mk_ResyncFromTick, Integer(fLastProcessedTick));
              end;

      mk_Vote:
              begin
                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                //No need to vote more than once, and spectators don't get to vote
                if not fNetPlayers[PlayerIndex].VotedYes and not fNetPlayers[PlayerIndex].IsSpectator then
                begin
                  fLastVoteTime := TimeGet;
                  fNetPlayers[PlayerIndex].VotedYes := True;
                  fNetPlayers.VoteActive := True;
                  if fNetPlayers.FurtherVotesNeededForMajority <= 0 then
                  begin
                    PostMessage(TX_NET_VOTE_PASSED, csSystem, UnicodeString(fNetPlayers[PlayerIndex].NiknameColored));
                    fNetPlayers.ResetVote;
                    //This packet is also sent to ourself (host), we will return to lobby when it arrives
                    PacketSend(NET_ADDRESS_ALL, mk_ReturnToLobby);
                  end
                  else
                  begin
                    PostMessage(TX_NET_VOTED, csSystem, UnicodeString(fNetPlayers[PlayerIndex].NiknameColored), IntToStr(fNetPlayers.FurtherVotesNeededForMajority));
                    SendPlayerListAndRefreshPlayersSetup;
                  end;
                end;
              end;

      mk_TextTranslated:
              begin
                M.Read(tmpInteger);
                M.Read(ChatSound, SizeOf(ChatSound));
                M.ReadW(tmpStringW);
                M.ReadW(replyStringW);
                PostLocalMessage(Format(gResTexts[tmpInteger], [tmpStringW, replyStringW]), ChatSound);
              end;

      mk_TextChat:
              begin
                M.Read(tmpChatMode, SizeOf(tmpChatMode));
                M.Read(PlayerIndex);
                M.ReadW(tmpStringW);

                case tmpChatMode of
                  cmTeam:
                    begin
                      tmpStringW := ' [$66FF66]('+gResTexts[TX_CHAT_TEAM]+')[]: ' + tmpStringW;
                      ChatSound := csChatTeam;
                    end;

                  cmSpectators:
                    begin
                      tmpStringW := ' [$66FF66]('+gResTexts[TX_CHAT_SPECTATORS]+')[]: ' + tmpStringW;
                      ChatSound := csChatTeam;
                    end;

                  cmWhisper:
                    begin
                      ChatSound := csChatWhisper;
                      I := NetPlayers.ServerToLocal(PlayerIndex);
                      if I <> -1 then
                        tmpStringA := NetPlayers[I].Nikname
                      else
                        tmpStringA := '';
                      tmpStringW := ' [$00B9FF](' + Format(gResTexts[TX_CHAT_WHISPER_TO], [UnicodeString(tmpStringA)]) + ')[]: ' + tmpStringW;
                    end;

                  cmAll:
                    begin
                      tmpStringW := ' ('+gResTexts[TX_CHAT_ALL]+'): ' + tmpStringW;
                      ChatSound := csChat;
                    end;
                end;

                PlayerIndex := fNetPlayers.ServerToLocal(aSenderIndex);
                if PlayerIndex <> -1 then
                begin
                  if NetPlayers[PlayerIndex].FlagColorID <> 0 then
                    tmpStringW := UnicodeString(WrapColorA(NetPlayers[PlayerIndex].Nikname, FlagColorToTextColor(NetPlayers[PlayerIndex].FlagColor))) + tmpStringW
                  else
                    tmpStringW := UnicodeString(NetPlayers[PlayerIndex].Nikname) + tmpStringW;

                  PostLocalMessage(tmpStringW, ChatSound);
                end;
              end;
    end;

  finally
    M.Free;
  end;
end;


//MessageKind.Data(depends on Kind)
procedure TKMNetworking.PacketSend(aRecipient: Integer; aKind: TKMessageKind);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfNoData);

  M := TKMemoryStream.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSend(aRecipient: Integer; aKind: TKMessageKind; aStream: TKMemoryStream);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfBinary);

  M := TKMemoryStream.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  aStream.Position := 0;
  M.CopyFrom(aStream, aStream.Size);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSend(aRecipient: Integer; aKind: TKMessageKind; aParam: Integer);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfNumber);

  M := TKMemoryStream.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.Write(aParam);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSendA(aRecipient: Integer; aKind: TKMessageKind; const aText: AnsiString);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfString);

  M := TKMemoryStream.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.WriteA(aText);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.PacketSendW(aRecipient: Integer; aKind: TKMessageKind; const aText: UnicodeString);
var
  M: TKMemoryStream;
begin
  Assert(NetPacketType[aKind] = pfString);

  M := TKMemoryStream.Create;
  M.Write(aKind, SizeOf(TKMessageKind));

  M.WriteW(aText);

  fNetClient.SendData(fMyIndexOnServer, aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetworking.StartGame;
begin
  PostLocalMessage(gResTexts[TX_LOBBY_GAME_STARTED], csGameStart);
  SetGameState(lgs_Loading); //Loading has begun (no further players allowed to join)
  fIgnorePings := -1; //Ignore all pings until we have finished loading

  case fSelectGameKind of
    ngk_Map:  fOnStartMap(fMapInfo.FileName, fMapInfo.MapFolder, fNetPlayers[fMyIndex].IsSpectator);
    ngk_Save: fOnStartSave(fSaveInfo.FileName, fNetPlayers[fMyIndex].IsSpectator);
    else      Assert(False);
  end;
end;


procedure TKMNetworking.TryPlayGame;
begin
  if fNetPlayers.AllReadyToPlay then
  begin
    PacketSend(NET_ADDRESS_OTHERS, mk_Play);
    PlayGame;
  end;
end;


procedure TKMNetworking.PlayGame;
begin
  fIgnorePings := 5; //Ignore the next few pings as they will have been measured during loading
  SetGameState(lgs_Game); //The game has begun (no further players allowed to join)
  if Assigned(fOnPlay) then fOnPlay(Self);
end;


procedure TKMNetworking.SetDescription(const Value: UnicodeString);
begin
  Assert(IsHost, 'Only host can set description');
  fDescription := Value;
  fOnMPGameInfoChanged(Self); //Send the description to the server so it is shown in room info
end;


procedure TKMNetworking.SetGameState(aState: TNetGameState);
begin
  fNetGameState := aState;
  if (fNetGameState in [lgs_Lobby,lgs_Loading,lgs_Game]) and IsHost and (fMyIndexOnServer <> -1) then
    fOnMPGameInfoChanged(Self);
end;


//Tell the server what we know about the game
procedure TKMNetworking.AnnounceGameInfo(aGameTime: TDateTime; aMap: UnicodeString);
var
  MPGameInfo: TMPGameInfo;
  M: TKMemoryStream;
  I, K: Integer;
begin
  //Only one player per game should send the info - Host
  if not IsHost then Exit;

  MPGameInfo := TMPGameInfo.Create;
  try
    if (fNetGameState in [lgs_Lobby, lgs_Loading]) then
    begin
      case fSelectGameKind of
        ngk_Save: aMap := fSaveInfo.Info.Title;
        ngk_Map:  aMap := fMapInfo.FileName;
        else      aMap := '';
      end;
      aGameTime := -1;
    end;
    MPGameInfo.Description := fDescription;
    MPGameInfo.Map := aMap;
    MPGameInfo.GameTime := aGameTime;
    MPGameInfo.GameState := NetMPGameState[fNetGameState];
    MPGameInfo.PasswordLocked := (fPassword <> '');
    MPGameInfo.PlayerCount := NetPlayers.Count;

    K := 1;
    if HostIndex <> -1 then
    begin
      MPGameInfo.Players[K].Name := NetPlayers[HostIndex].Nikname;
      MPGameInfo.Players[K].Color := NetPlayers[HostIndex].FlagColor($FFFFFFFF);
      MPGameInfo.Players[K].Connected := NetPlayers[HostIndex].Connected;
      MPGameInfo.Players[K].PlayerType := NetPlayers[HostIndex].PlayerNetType;
      Inc(K);
    end;
    for I := 1 to NetPlayers.Count do
      if I <> HostIndex then
      begin
        MPGameInfo.Players[K].Name := NetPlayers[I].Nikname;
        MPGameInfo.Players[K].Color := NetPlayers[I].FlagColor($FFFFFFFF);
        MPGameInfo.Players[K].Connected := NetPlayers[I].Connected;
        MPGameInfo.Players[K].PlayerType := NetPlayers[I].PlayerNetType;
        Inc(K);
      end;

    M := TKMemoryStream.Create;
    MPGameInfo.SaveToStream(M);
    PacketSend(NET_ADDRESS_SERVER, mk_SetGameInfo, M);
    M.Free;
  finally
    MPGameInfo.Free;
  end;
end;


procedure TKMNetworking.TransferOnCompleted(aClientIndex: Integer);
begin
  PacketSend(aClientIndex, mk_FileEnd);
  SendMapOrSave(aClientIndex);
  SendPlayerListAndRefreshPlayersSetup(aClientIndex);
end;


procedure TKMNetworking.TransferOnPacket(aClientIndex: Integer; aStream: TKMemoryStream; out SendBufferEmpty: Boolean);
begin
  PacketSend(aClientIndex, mk_FileChunk, aStream);
  SendBufferEmpty := fNetClient.SendBufferEmpty;
end;


procedure TKMNetworking.UpdateState(aTick: cardinal);
begin
  //Reconnection delay
  if (fReconnectRequested <> 0) and (GetTimeSince(fReconnectRequested) > RECONNECT_PAUSE) then DoReconnection;
  //Joining timeout
  if fNetGameState in [lgs_Connecting,lgs_Reconnecting,lgs_Query] then
    if (GetTimeSince(fJoinTimeout) > JOIN_TIMEOUT) and not fEnteringPassword
    and (fReconnectRequested = 0) then
      if Assigned(fOnJoinFail) then fOnJoinFail(gResTexts[TX_NET_QUERY_TIMED_OUT]);
  //Vote expiring
  if (fNetGameState in [lgs_Loading, lgs_Game]) and IsHost
  and fNetPlayers.VoteActive and (GetTimeSince(fLastVoteTime) > VOTE_TIMEOUT) then
  begin
    PostMessage(TX_NET_VOTE_FAILED, csSystem);
    fNetPlayers.ResetVote;
    SendPlayerListAndRefreshPlayersSetup;
  end;
end;


procedure TKMNetworking.UpdateStateIdle;
begin
  fNetServer.UpdateState; //Server measures pings etc.
  //LNet requires network update calls unless it is being used as visual components
  fNetClient.UpdateStateIdle;
  fServerQuery.UpdateStateIdle;
  fFileSenderManager.UpdateStateIdle(fNetClient.SendBufferEmpty);
end;


procedure TKMNetworking.FPSMeasurement(aFPS: Cardinal);
begin
  if fNetGameState = lgs_Game then
    PacketSend(NET_ADDRESS_ALL, mk_FPS, Integer(aFPS));
end;


procedure TKMNetworking.ReturnToLobby;
begin
  //Clear events that were used by Game
  fOnCommands := nil;
  fOnResyncFromTick := nil;
  fOnPlay := nil;
  fOnReadyToPlay := nil;

  fNetGameState := lgs_Lobby;
  if IsHost then
  begin
    NetPlayers.RemAllAIs; //AIs are included automatically when you start the save
    NetPlayers.RemDisconnectedPlayers; //Disconnected players must not be shown in lobby
    //Don't refresh player setup here since events aren't attached to lobby yet
  end;
end;


end.
