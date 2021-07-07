{*******************************************************}
{                                                       }
{       Main Unit for SOLDAT                            }
{                                                       }
{       Copyright (c) 2002 Michal Marcinkowski          }
{                                                       }
{*******************************************************}

unit Server;

interface

{$i IdCompilerDefines.inc}

uses
  // system and delphi units
  SysUtils, Classes, Variants,
  {$IFNDEF MSWINDOWS}
  Baseunix,
  {$ENDIF}

  // helper units
  Vector, Util, Sha1,

  // Cvar units
  Cvar, Command,

  // scripting units
  {$IFDEF SCRIPT}
  ScriptDispatcher,
  {$ENDIF}

  {$IFDEF STEAM}
  Steam, SteamTypes, typinfo,
  {$ENDIF}

  {$IFDEF RCON}
  Rcon,
  {$ENDIF}

  FileServer, LobbyClient,

  // soldat units
  GameNetworkingSockets, Net, NetworkUtils,
  NetworkServerSprite, NetworkServerConnection, NetworkServerGame,
  ServerCommands, PhysFS, Console, ServerHelper,
  Sprites, Anims, PolyMap, SharedConfig, Game, Things,
  BanSystem, LogFile, Version, Constants;

procedure ActivateServer;
function AddBotPlayer(Name: string; team: Integer): Byte;
procedure StartServer;
procedure LoadWeapons(filename: string);
procedure ShutDown;
procedure NextMap;
procedure SpawnThings(style, amount: Byte);
function KickPlayer(num: Byte; Ban: Boolean; why: Integer; time: Integer;
  Reason: string = ''): Boolean;  // True if kicked
function PrepareMapChange(Name: String): Boolean;
{$IFDEF STEAM}
{$IFDEF STEAMSTATS}
procedure RequestUserStats(Player: TSteamID);
procedure GSStatsStored(Callback: PGSStatsStored_t);
procedure StoreStats(Player: TSteamID);
{$ENDIF}
procedure RunManualCallbacks;
{$ENDIF}

const PATH_MAX = 4095;

var
  ProgReady: Boolean = False;
  BaseDirectory: string;
  UserDirectory: string;
  MainThreadID: TThreadID;

  // Cvars
  log_enable: TBooleanCvar;
  log_level: TIntegerCvar;
  log_filesupdate: TIntegerCvar;
  log_timestamp: TBooleanCvar;

  fs_localmount: TBooleanCvar;
  fs_mod: TStringCvar;
  fs_portable: TBooleanCvar;
  fs_basepath: TStringCvar;
  fs_userpath: TStringCvar;

  demo_autorecord: TBooleanCvar;

  sv_respawntime: TIntegerCvar;
  sv_respawntime_minwave: TIntegerCvar;
  sv_respawntime_maxwave: TIntegerCvar;

  sv_dm_limit: TIntegerCvar;
  sv_pm_limit: TIntegerCvar;
  sv_tm_limit: TIntegerCvar;
  sv_rm_limit: TIntegerCvar;

  sv_inf_limit: TIntegerCvar;
  sv_inf_bluelimit: TIntegerCvar;
  sv_inf_redaward: TIntegerCvar;

  sv_htf_limit: TIntegerCvar;
  sv_htf_pointstime: TIntegerCvar;

  sv_ctf_limit: TIntegerCvar;

  sv_bonus_frequency: TIntegerCvar;
  sv_bonus_flamer: TBooleanCvar;
  sv_bonus_predator: TBooleanCvar;
  sv_bonus_berserker: TBooleanCvar;
  sv_bonus_vest: TBooleanCvar;
  sv_bonus_cluster: TBooleanCvar;

  sv_stationaryguns: TBooleanCvar;

  sv_password: TStringCvar;
  sv_adminpassword: TStringCvar;
  sv_maxplayers: TIntegerCvar;
  sv_maxspectators: TIntegerCvar;
  sv_spectatorchat: TBooleanCvar;
  sv_greeting: TStringCvar;
  sv_greeting2: TStringCvar;
  sv_greeting3: TStringCvar;
  sv_info: TStringCvar;
  sv_minping: TIntegerCvar;
  sv_maxping: TIntegerCvar;
  sv_votepercent: TIntegerCvar;
  sv_lockedmode: TBooleanCvar;
  sv_pidfilename: TStringCvar;
  sv_maplist: TStringCvar;
  sv_lobby: TBooleanCvar;
  sv_lobbyurl: TStringCvar;

  sv_steamonly: TBooleanCvar;

  {$IFDEF STEAM}
  sv_voicechat: TBooleanCvar;
  sv_voicechat_alltalk: TBooleanCvar;
  sv_setsteamaccount: TStringCvar;
  {$ENDIF}

  sv_warnings_flood: TIntegerCvar;
  sv_warnings_ping: TIntegerCvar;
  sv_warnings_votecheat: TIntegerCvar;
  sv_warnings_knifecheat: TIntegerCvar;
  sv_warnings_tk: TIntegerCvar;

  sv_anticheatkick: TBooleanCvar;
  sv_punishtk: TBooleanCvar;
  sv_botbalance: TBooleanCvar;
  sv_echokills: TBooleanCvar;
  sv_antimassflag: TBooleanCvar;
  sv_healthcooldown: TIntegerCvar;
  sv_teamcolors: TBooleanCvar;

  net_port: TIntegerCvar;
  net_ip: TStringCvar;
  net_adminip: TStringCvar;
  net_lan: TIntegerCvar;
  net_compression: TBooleanCvar;
  net_allowdownload: TBooleanCvar;
  net_maxconnections: TIntegerCvar;
  net_maxadminconnections: TIntegerCvar;

  net_floodingpacketslan: TIntegerCvar;
  net_floodingpacketsinternet: TIntegerCvar;

  net_t1_snapshot: TIntegerCvar;
  net_t1_majorsnapshot: TIntegerCvar;
  net_t1_deadsnapshot: TIntegerCvar;
  net_t1_heartbeat: TIntegerCvar;
  net_t1_delta: TIntegerCvar;
  net_t1_ping: TIntegerCvar;
  net_t1_thingsnapshot: TIntegerCvar;

  bots_random_noteam: TIntegerCvar;
  bots_random_alpha: TIntegerCvar;
  bots_random_bravo: TIntegerCvar;
  bots_random_charlie: TIntegerCvar;
  bots_random_delta: TIntegerCvar;
  bots_difficulty: TIntegerCvar;
  bots_chat: TBooleanCvar;

  sc_enable: TBooleanCvar;
  sc_onscriptcrash: TStringCvar;
  sc_maxscripts: TIntegerCvar;
  sc_safemode: TBooleanCvar;

  fileserver_enable: TBooleanCvar;
  fileserver_port: TIntegerCvar;
  fileserver_ip: TStringCvar;

  // syncable cvars
  sv_gamemode: TIntegerCvar;
  sv_friendlyfire: TBooleanCvar;
  sv_timelimit: TIntegerCvar;
  sv_maxgrenades: TIntegerCvar;
  sv_bullettime: TBooleanCvar;
  sv_sniperline: TBooleanCvar;
  sv_balanceteams: TBooleanCvar;
  sv_survivalmode: TBooleanCvar;
  sv_survivalmode_antispy: TBooleanCvar;
  sv_survivalmode_clearweapons: TBooleanCvar;
  sv_realisticmode: TBooleanCvar;
  sv_advancemode: TBooleanCvar;
  sv_advancemode_amount: TIntegerCvar;
  sv_guns_collide: TBooleanCvar;
  sv_kits_collide: TBooleanCvar;
  sv_minimap: TBooleanCvar;
  sv_advancedspectator: TBooleanCvar;
  sv_radio: TBooleanCvar;
  sv_gravity: TSingleCvar;
  sv_hostname: TStringCvar;
  sv_killlimit: TIntegerCvar;
  sv_downloadurl: TStringCvar;
  sv_pure: TBooleanCvar;
  sv_website: TStringCvar;

  {$IFDEF ENABLE_FAE}
  ac_enable: TBooleanCvar;
  {$ENDIF}

  // config stuff
  ServerIP: string = '127.0.0.1';
  ServerPort: Integer = 23073;
  BonusFreq: Integer = 3600;
  WeaponActive: array[-1..15] of Byte;

  MapsList: TStrings;

  LastPlayer: Byte;

  OldBulletSnapshotMsg: array[1..MAX_SPRITES] of TMsg_BulletSnapshot;

  // Mute array
  MuteList: array[1..MAX_PLAYERS] of ShortString;
  MuteName: array[1..MAX_PLAYERS] of string;

  // TK array
  TKList: array[1..MAX_PLAYERS] of ShortString;  // IP
  TKListKills: array[1..MAX_PLAYERS] of Byte;    // TK Warnings

  TCPBytesSent: Int64;
  TCPBytesReceived: Int64;

  // Consoles
  MainConsole: TConsole;

  RemoteIPs, AdminIPs: TStrings;

  FloodIP: array[1..1000] of ShortString;
  FloodNum: array[1..1000] of Integer;

  LastReqIP: array[0..3] of ShortString; // last 4 IP's to request game
  LastReqID: Byte = 0;
  DropIP: ShortString = '';

  AdminFloodIP: array [1..MAX_ADMIN_FLOOD_IPS] of string;
  LastAdminIPs: array [0..MAX_LAST_ADMIN_IPS] of string;
  AdminIPCounter: Integer = 0;

  WaveRespawnTime, WaveRespawnCounter: Integer;

  WeaponsInGame: Integer;

  BulletWarningCount: array[1..MAX_SPRITES] of Byte;

  CheatTag: array[1..MAX_SPRITES] of Byte;

  {$IFDEF RCON}
  AdminServer: TAdminServer;  // TIdTCPServer;
  {$ENDIF}
  // bullet shot stats
  ShotDistance: Single;
  ShotLife: Single;
  ShotRicochet: Integer;

  HTFTime: Integer = HTF_SEC_POINT;

  CurrentConf: string = 'soldat.ini';

  WMName, WMVersion: string;
  LastWepMod: string;

  Grav: Single = 0.06;

  ModDir: string = '';

  UDP: TServerNetwork;

  LobbyThread: TLobbyThread;

  {$IFDEF STEAM}
  //SteamCallbacks: TSteamCallbacks;
  SteamAPI: TSteamGS;
  {$ENDIF}

implementation

uses
  Weapons, TraceLog;


{$IFNDEF MSWINDOWS}
// from lazdaemon package
// BUG: "Old instance (the parent) writes it's consolelog
// no idea how to avoid it. Perhaps somebody who knows this code could fix it.
var
  devnull: TextFile;
procedure DaemonizeProgram;
var
  pid, sid : TPid;
begin
  pid := FpFork;
  if (pid<0) then
    raise Exception.Create('Failed to fork daemon process.');
  if pid>0 then
  begin
    // We are now in the main program, which has to terminate
    FpExit(0);
  end
  else
  begin
    // Here we are in the daemonized proces
    sid := FpSetsid;
    if sid < 0 then
      raise Exception.Create('Failed to fork daemon process.');
    // Reset the file-mask
    FpUmask(0);
    // commented, it breaks script detection, and seems to work anyway (no locks)
    // Change the current directory, to avoid locking the current directory
    // chdir('/');
    AssignFile(devnull, '/dev/null');
    Rewrite(devnull);
    Input := devnull;
    Output := devnull;
    ErrOutput := devnull;
  end;
end;
{$ENDIF}

{$IFDEF STEAM}
{$IFDEF STEAMSTATS}
procedure StoreStats(Player: TSteamID);
begin
  //SteamCallResultDispatcher.Create(1801, @GSStatsStored, SizeOf(GSStatsStored_t), SteamAPI.GameServerStats.StoreUserStats(Player), k_ECallbackFlagsGameServer);
end;

procedure GSStatsStored(Callback: PGSStatsStored_t);
begin
  Debug(Format('[Steam] GSStatsReceived result %d result steamid %s',
    [Ord(Callback.m_eResult), Callback.m_steamIDUser.GetAsString]));
end;

procedure GSStatsReceived(Callback: PGSStatsReceived_t);
var
 j: Byte;
begin
  Debug(Format('[Steam] GSStatsReceived result %d result steamid %s',
    [Ord(Callback.m_eResult), Callback.m_steamIDUser.GetAsString]));
  for j := 1 to MAX_SPRITES do
    if (Sprite[j].Active) and (Uint64(Sprite[j].Player.SteamID) = Uint64(Callback.m_steamIDUser)) then
    begin
      if Callback.m_eResult = k_EResultOK then
        Sprite[j].Player.SteamStats := True
      else
        Sprite[j].Player.SteamStats := False;
    end;
end;

procedure RequestUserStats(Player: TSteamID);
begin
  SteamAPI.GameServerStats.RequestUserStats(Player);
end;
{$ENDIF}

procedure GetCollectionDetails(Callback: PSteamUGCQueryCompleted_t);
var
  CollectionItems: array of PublishedFileId_t;
  CollectionDetails: SteamUGCDetails_t;
  ItemState: uint32;
  i, j: Integer;
begin
  Debug(Format('[Steam] SteamUGCQueryCompleted id %d result %d numresults %d totalresults %d cached %s',
    [Callback.m_handle, Ord(Callback.m_eResult), Callback.m_unNumResultsReturned,
    Callback.m_unTotalMatchingResults, Callback.m_bCachedData.toString]));

  for j := 0 to Callback.m_unNumResultsReturned - 1 do
  begin
    if SteamAPI.UGC.GetQueryUGCResult(Callback.m_handle, j, @CollectionDetails) then
    begin
      SetLength(CollectionItems, CollectionDetails.m_unNumChildren);
      if SteamAPI.UGC.GetQueryUGCChildren(Callback.m_handle, 0, @CollectionItems[0], Length(CollectionItems)) then
      begin
        for i := 0 to CollectionDetails.m_unNumChildren - 1 do
        begin
          ItemState := SteamAPI.UGC.GetItemState(CollectionItems[i]);
          Debug(Format('[Steam] GetItemState id %d state %d', [CollectionItems[i], ItemState]));
          if (ItemState = 0) or (Ord(k_EItemStateNeedsUpdate) and ItemState <> 0) then
          begin
            Debug('[Steam] Dowloading workshop item id:' + IntToStr(CollectionItems[i]));
            SteamAPI.UGC.DownloadItem(CollectionItems[i], True);
          end else if ItemState = Ord(k_EItemStateInstalled) then
          begin
            MapsList.Add('workshop/' + IntToStr(CollectionItems[i]));
          end;
        end;
      end else
        Debug('[Steam] GetQueryUGCChildren has failed');
    end else
      Debug('[Steam] GetQueryUGCResult has failed');
    SetLength(CollectionItems, 0);
  end;
  SteamAPI.UGC.ReleaseQueryUGCRequest(Callback.m_handle);
end;

procedure DownloadWorkshopCollection(ItemID: Uint64);
var
  QueryHandle: UGCQueryHandle_t;
  Items: Array[0..1] of PublishedFileId_t;
begin
  Items[0] := ItemID;
  QueryHandle := SteamAPI.UGC.CreateQueryUGCDetailsRequest(@Items, 1);
  SteamAPI.UGC.SetReturnChildren(QueryHandle, True);
  SteamAPI.UGC.SetReturnOnlyIDs(QueryHandle, True);
  //ApiCall := SteamAPI.UGC.SendQueryUGCRequest(QueryHandle);
  //SteamCallResultDispatcher.Create(3401, @GetCollectionDetails, SizeOf(SteamUGCQueryCompleted_t), ApiCall, k_ECallbackFlagsGameServer);
  //ParseMapName('workshop/1916893159');
end;

function GetWorkshopItemDir(ItemID: PublishedFileId_t): AnsiString;
var
  FileSizeOnDisk: uint64 = 0;
  DirSizeOnDisk: uint32 = 0;
  Path: array[0..PATH_MAX] of Char;
  TimeStamp: Cardinal = 0;
begin
  Result := '';
  if MapChangeItemID = ItemID then
  begin
    PrepareMapChange('workshop/' + IntToStr(ItemID));
  end else if SteamAPI.UGC.GetItemInstallInfo(ItemID, @FileSizeOnDisk, @Path, PATH_MAX, @TimeStamp) then
  begin
    Result := Path;
  end else
    Result := '';
end;

procedure DownloadItemResult(Callback: PDownloadItemResult_t); cdecl;
begin
  if Callback.m_unAppID = STEAM_APPID then
  begin
    if Callback.m_eResult = k_EResultOK then
    begin
    end else
      WriteLn('[Steam] Failed to download workshop item, id:' + IntToStr(Callback.m_nPublishedFileId) + ' error: ' + IntToStr(Ord(Callback.m_eResult)));
  end;
end;

procedure OnSteamServersConnected(); cdecl;
begin
  WriteLn('[Steam] Successfully connected to the Steam.');
  //DownloadItems;
end;

procedure OnSteamServerConnectFailure(Callback: PSteamServerConnectFailure_t); cdecl;
begin
  WriteLn('[Steam] Connection to the Steam has failed: ' + IntToStr(Ord(Callback.m_eResult)));
end;

procedure OnSteamServersDisconnected(Callback: PSteamServersDisconnected_t); cdecl;
begin
  WriteLn('[Steam] Lost connection to the Steam servers: ' + IntToStr(Ord(Callback.m_eResult)));
end;

procedure SteamNetConnectionStatusChangedCallback(Callback: PSteamNetConnectionStatusChangedCallback_t); cdecl;
begin
  if Assigned(UDP) then
    UDP.ProcessEvents(Callback);
end;

procedure RunManualCallbacks;
var
  callback: CallbackMsg_t;
  pCallCompleted: SteamAPICallCompleted_t;
  bFailed: Boolean;
  Data: Pointer;
begin
  SteamAPI_ManualDispatch_RunFrame(SteamAPI.SteamPipeHandle);
  while SteamAPI_ManualDispatch_GetNextCallback(SteamAPI.SteamPipeHandle, @callback) do
  begin
    if callback.m_iCallback = 703 then
    begin
      pCallCompleted := PSteamAPICallCompleted_t(callback.m_pubParam)^;
      GetMem(Data, pCallCompleted.m_cubParam);
      if SteamAPI_ManualDispatch_GetAPICallResult(SteamAPI.SteamPipeHandle, pCallCompleted.m_hAsyncCall, Data, pCallCompleted.m_cubParam, pCallCompleted.m_iCallback, @bFailed) then
      begin
      end;
      FreeMem(Data);
    end
    else if callback.m_iCallback = 101 then
      OnSteamServersConnected()
    else if callback.m_iCallback = 102 then
      OnSteamServerConnectFailure(callback.m_pubParam)
    else if callback.m_iCallback = 103 then
      OnSteamServersDisconnected(callback.m_pubParam)
    else if callback.m_iCallback = 1221 then
      SteamNetConnectionStatusChangedCallback(callback.m_pubParam);

    SteamAPI_ManualDispatch_FreeLastCallback(SteamAPI.SteamPipeHandle);
  end;
end;
{$ENDIF}

procedure ActivateServer;
var
  i, j: Integer;
begin
  MainThreadID := GetThreadID;

  WriteLn('');
  WriteLn('             -= Soldat Dedicated Server ' + SOLDAT_VERSION + ' - ' +
    DEDVERSION + ' (build ' + SOLDAT_VERSION_LONG + ') =-');
  WriteLn('');
  WriteLn('----------------------------------------------------------------');
  WriteLn('         Soldat Dedicated Server initializing...');
  WriteLn('----------------------------------------------------------------');
  WriteLn('');
  WriteLn('   Need help running your server?');
  WriteLn('   Discord: https://discord.gg/soldat');
  WriteLn('');
  WriteLn('   ---> https://forums.soldat.pl/');
  WriteLn('');
  WriteLn('   Additional parameters:');
  WriteLn('   ./soldatserver -net_port PORT -sv_maxplayers MAXPLAYERS -sv_password PASSWORD');
  WriteLn('   Example: ./soldatserver -net_port 23073 -sv_maxplayers 16 -sv_password "my pass"');
  WriteLn('');
  WriteLn('');

  WriteLn(' Compiled with FreePascal ' + {$I %FPCVERSION%});
  WriteLn('');

  {$IFNDEF CPUARM}
  // Disable FPU exceptions
  Set8087CW($133F);
  {$ENDIF}

  DefaultFormatSettings.DecimalSeparator := '.';
  DefaultFormatSettings.DateSeparator := '-';

  ServerTickCounter := 0;
  MainTickCounter := 0;

  // Initialize player dummy objects (cf. DummyPlayer definition for documentation)
  DummyPlayer := TPlayer.Create;
  for i := 1 to MAX_SPRITES do
    Sprite[i].Player := DummyPlayer;

  // Create Consoles
  MainConsole.CountMax := 7;
  MainConsole.ScrollTickMax := 150;
  MainConsole.NewMessageWait := 150;
  MainConsole.AlphaCount := 255;

  if GetEnvironmentVariable('COLORTERM') <> '' then
    MainConsole.TerminalColors := True;

  CvarInit();
  InitServerCommands();
  ParseCommandLine();

  if fs_basepath.Value = '' then
    BaseDirectory := ExtractFilePath(ParamStr(0));
  if fs_userpath.Value = '' then
    UserDirectory := ExtractFilePath(ParamStr(0));

  Debug('[FS] UserDirectory: ' + UserDirectory);
  Debug('[FS] BaseDirectory: ' + BaseDirectory);

  SetCurrentDir(UserDirectory);

  if not PhysFS_Init(PChar(ParamStr(0))) then
  begin
    WriteLN('Could not initialize PhysFS.');
    ProgReady := False;
    sc_enable.SetValue(False);
    Exit;
  end;
  if not PhysFS_mount(PChar(BaseDirectory + '/soldat.smod'), '/', False) then
  begin
    WriteLn('Could not load base game archive (soldat.smod).');
    ProgReady := False;
    sc_enable.SetValue(False);
    Exit;
  end;

  GameModChecksum := Sha1File(BaseDirectory + '/soldat.smod', 4096);

  ModDir := '';

  if fs_mod.Value <> '' then
  begin
    if not PhysFS_mount(PChar(UserDirectory + 'mods/' + LowerCase(fs_mod.Value) + '.smod'),
      PChar('mods/' + LowerCase(fs_mod.Value) + '/'), False) then
    begin
      WriteLn('Could not load mod archive (' + fs_mod.Value + ').');
      ProgReady := False;
      sc_enable.SetValue(False);
      Exit;
    end;
    ModDir := 'mods/' + LowerCase(fs_mod.Value) + '/';
    CustomModChecksum := Sha1File(UserDirectory + 'mods/' + LowerCase(fs_mod.Value) + '.smod', 4096);
  end;

  // Create the basic folder structure
  CreateDirIfMissing(UserDirectory + '/configs');
  CreateDirIfMissing(UserDirectory + '/demos');
  CreateDirIfMissing(UserDirectory + '/logs');
  CreateDirIfMissing(UserDirectory + '/logs/kills');
  CreateDirIfMissing(UserDirectory + '/maps');
  CreateDirIfMissing(UserDirectory + '/mods');

  // Copy default configs if they are missing
  PHYSFS_CopyFileFromArchive('configs/server.cfg', UserDirectory + '/configs/server.cfg');
  PHYSFS_CopyFileFromArchive('configs/weapons.ini', UserDirectory + '/configs/weapons.ini');
  PHYSFS_CopyFileFromArchive('configs/weapons_realistic.ini', UserDirectory + '/configs/weapons_realistic.ini');

  LoadConfig('server.cfg');

  CvarsInitialized := True;

  NewLogFiles;

  Debug('ActivateServer');

  {$IFDEF SCRIPT}
  ScrptDispatcher.SafeMode := sc_safemode.Value;
  ScrptDispatcher.MaxScripts := sc_maxscripts.Value;
  {$ENDIF}

  if net_ip.Value = '' then
    net_ip.ParseAndSetValue('0.0.0.0');

  {$IFDEF STEAM}
  SteamAPI := TSteamGS.Init(
      0, // The IP address you are going to bind to
      net_port.Value, // The port that clients will connect to for gameplay.
      net_port.Value + 20, // The port that will manage server browser related duties and info pings from clients.
      eServerModeAuthenticationAndSecure, // Sets the authentication method of the server.
      PChar(SOLDAT_VERSION)
    );

  SteamAPI_ManualDispatch_Init();

  if SteamAPI = nil then
  begin
    WriteLn('[Steam] Failed to initialize Steam instance.');
    ShutDown;
  end
  else
  begin
    SteamAPI.Utils.SetWarningMessageHook(@SteamWarning);

    SteamAPI.GameServer.SetModDir(PChar('Soldat'));
    SteamAPI.GameServer.SetProduct(PChar('Soldat'));
    SteamAPI.GameServer.SetGameDescription(PChar('Soldat'));

    //SteamCallbackDispatcher.Create(101, @OnSteamServersConnected, SizeOf(SteamServersConnected_t), k_ECallbackFlagsGameServer);
    //SteamCallbackDispatcher.Create(102, @OnSteamServerConnectFailure, SizeOf(SteamServerConnectFailure_t), k_ECallbackFlagsGameServer);
    //SteamCallbackDispatcher.Create(103, @OnSteamServersConnected, SizeOf(SteamServersDisconnected_t), k_ECallbackFlagsGameServer);
    //SteamCallbackDispatcher.Create(1221, @SteamNetConnectionStatusChangedCallback, SizeOf(SteamNetConnectionStatusChangedCallback_t), k_ECallbackFlagsGameServer);
    //SteamCallbackDispatcher.Create(3406, @DownloadItemResult, SizeOf(DownloadItemResult_t), k_ECallbackFlagsGameServer);

    if sv_setsteamaccount.Value <> '' then
      SteamAPI.GameServer.LogOn(PChar(sv_setsteamaccount.Value))
    else
      SteamAPI.GameServer.LogOnAnonymous();

    if SteamAPI.UGC.BInitWorkshopForGameServer(638490, PChar(UserDirectory + '/workshop')) then
      WriteLn('[Steam] Initialized Workshop.')
    else
      WriteLn('[Steam] Failed to initialize Workshop.');
  end;
  {$ENDIF}

  ProgReady := True;

  {$IFNDEF SCRIPT}
  sc_enable.ParseAndSetValue('0');
  {$ENDIF}

  //TODO: Implement enabled weapons in cvar system
  for i := 1 to MAIN_WEAPONS do
    WeaponActive[i] := 1;

  LoadAnimObjects('');
  if Length(ModDir) > 0 then
    LoadAnimObjects(ModDir);

  // greet!
  WriteLn(' Hit CTRL+C to Exit');
  WriteLn(' Please command the server using the Soldat Admin program');

  MapChangeCounter := -60;

  SinusCounter := 0;

  AddLineToLogFile(GameLog, 'Loading Maps List', ConsoleLogFileName);
  MapsList := TStringList.Create;
  ReloadMapsList(MapsList);

  for i := 1 to MAX_SPRITES do
    for j := 1 to MAX_SPRITES do
      OldHelmetMsg[i, j].WearHelmet := 1;

  // Banned IPs text file
  if not CreateFileIfMissing(UserDirectory + 'configs/banned.txt') then
    raise Exception.Create('Failed to create configs/banned.txt');

  if not CreateFileIfMissing(UserDirectory + 'configs/bannedhw.txt') then
    raise Exception.Create('Failed to create configs/bannedhw.txt');

  LoadBannedList(UserDirectory + 'configs/banned.txt');
  LoadBannedListHW(UserDirectory + 'configs/bannedhw.txt');

  RemoteIPs := TStringList.Create;

  if FileExists(UserDirectory + 'configs/remote.txt') then
    RemoteIPs.LoadFromFile(UserDirectory + 'configs/remote.txt');

  AdminIPs := TStringList.Create;
  AdminIPs.Assign(RemoteIPs);
  AdminIPs.Add('127.0.0.1');

  // Flood IP stuff
  for i := 1 to MAX_FLOODIPS do
    FloodIP[i] := ' ';
  for i := 1 to MAX_FLOODIPS do
    FloodNum[i] := 0;

  WeaponsInGame := 0;
  for j := 1 to MAIN_WEAPONS do
    if WeaponActive[j] = 1 then
      Inc(WeaponsInGame);

  {$IFDEF RCON}
  if sv_adminpassword.Value <> '' then
    AdminServer := TAdminServer.Create(sv_adminpassword.Value, 'Welcome')
  else
  begin
    WriteLn('');
    WriteLn(' The server must be started with an Admin Password parameter' +
      ' to run Admin');
    WriteLn('   edit server.cfg and set sv_adminpassword variable');
    WriteLn('');
  end;
  {$ENDIF}

  WriteLn(' Server name: ' + sv_hostname.Value);
  UpdateGameStats;
  WriteLogFile(KillLog, KillLogFileName);
  WriteLogFile(GameLog, ConsoleLogFileName);

  RunDeferredCommands;
end;

procedure ShutDown;
begin
  Debug('ShutDown');
  ProgReady := False;

  MainConsole.Console('Shutting down server...', GAME_MESSAGE_COLOR);
  SysUtils.DeleteFile(UserDirectory + 'logs/' + sv_pidfilename.Value);

  if UDP <> nil then
  begin
    ServerDisconnect;

    MainConsole.Console('Shutting down game networking.', GAME_MESSAGE_COLOR);

    FreeAndNil(UDP);
  end;

  {$IFDEF RCON}
  if sv_adminpassword.Value <> '' then
  begin
    try
      MainConsole.Console('Shutting down admin server...', GAME_MESSAGE_COLOR);
      if AdminServer <> nil then
      begin
        AdminServer.Active := False;
        AdminServer.Bindings.Clear;
        sv_adminpassword.SetValue('');
        FreeAndNil(AdminServer);
      end;
    except
      on e: Exception do
        WriteLn('Error on SHUTDOWN: ' + e.Message);
    end;
  end;
  {$ENDIF}

  StopFileServer;

  {$IFDEF SCRIPT}
  ScrptDispatcher.Free;
  {$ENDIF}

  {$IFDEF STEAM}
  Debug('[Steam] Shutdown');
  SteamAPI.GameServer.Shutdown;
  {$ENDIF}

  {$IFNDEF STEAM}
  GameNetworkingSockets_Kill();
  {$ENDIF}

  try
    AddLineToLogFile(GameLog, '   End of Log.', ConsoleLogFileName);
    Debug('Updating gamestats');
    UpdateGameStats;
    Debug('Saving killlog');
    WriteLogFile(KillLog, KillLogFileName);
    Debug('Saving gamelog');
    WriteLogFile(GameLog, ConsoleLogFileName);
    Debug('Freeing gamelog');
    FreeAndNil(GameLog);
    Debug('Freeing killlog');
    FreeAndNil(KillLog);
  except
    on e: Exception do
      WriteLn('Error on SHUTDOWN during log writing: ' + e.Message);
  end;
end;

procedure LoadWeapons(Filename: string);
var
  IsRealistic: Boolean;
  i: Integer;
begin
  Debug('LoadWeapons');

  IsRealistic := sv_realisticmode.Value = True;
  CreateWeapons(IsRealistic);
  // FIXME (falcon) while the above instruction has to be done every time,
  // because you never know if WM provides all the values,
  // this could be done only once per mode (realistic/non-realistic)
  DefaultWMChecksum := CreateWMChecksum();

  if not LoadWeaponsConfig(UserDirectory +  'configs/' + Filename + '.ini') then
  begin
    WriteLn('Using default weapons mod');
    CreateWeapons(IsRealistic);
  end;

  LoadedWMChecksum := CreateWMChecksum();

  if LoadedWMChecksum <> DefaultWMChecksum then
  begin
    MainConsole.Console('Loaded weapons mod "' + WMName + ' v' + WMVersion + '"',
      SERVER_MESSAGE_COLOR);
  end;

  for i := 1 to MAX_PLAYERS do
    if Sprite[i].Active then
      Sprite[i].ApplyWeaponByNum(Sprite[i].Weapon.Num, 1, Sprite[i].Weapon.AmmoCount);
end;

function AddBotPlayer(name: string; team: Integer): Byte;
var
  a, b: TVector2;
  p: Integer;
  NewPlayer: TPlayer;
  TempStr: String = '';
begin
  Debug('AddBotPlayer');
  Result := 0;

  if PlayersNum = MAX_PLAYERS then
  begin
    MainConsole.Console('Bot cannot be added because server is full', WARNING_MESSAGE_COLOR);
    Exit;
  end;

  NewPlayer := TPlayer.Create;
  NewPlayer.Team := team;
  NewPlayer.ApplyShirtColorFromTeam();

  a := Default(TVector2);
  b := Default(TVector2);
  RandomizeStart(a, team);
  p := CreateSprite(a, b, 1, 255, NewPlayer, True);
  Result := p;

  if not LoadBotConfig(UserDirectory + 'configs/bots/' + Name + '.bot', Sprite[p]) then
  begin
    MainConsole.Console('Bot file ' + Name + ' not found', WARNING_MESSAGE_COLOR);
    Sprite[p].Kill;
    Exit;
  end;

  Sprite[p].Respawn;
  Sprite[p].Player.ControlMethod := BOT;
  Sprite[p].Player.ChatWarnings := 0;
  Sprite[p].Player.GrabsPerSecond := 0;

  ServerSendNewPlayerInfo(p, JOIN_NORMAL);

  case team of
    0: TempStr := 'the game';
    1: TempStr := 'alpha team';
    2: TempStr := 'bravo team';
    3: TempStr := 'charlie team';
    4: TempStr := 'delta team';
    5: TempStr := 'as spectator';
  end;
  MainConsole.Console(Sprite[p].Player.Name + ' ' + 'has joined ' +
    TempStr + '.', ENTER_MESSAGE_COLOR);

  {$IFDEF SCRIPT}
  ScrptDispatcher.OnJoinTeam(p, Sprite[p].Player.Team, Sprite[p].Player.Team, True);
  ScrptDispatcher.OnWeaponChange(p, Sprite[p].Weapon.Num, Sprite[p].SecondaryWeapon.Num,
    Sprite[p].Weapon.AmmoCount, Sprite[p].SecondaryWeapon.AmmoCount);
  {$ENDIF}

  SortPlayers;
end;

procedure StartServer;
var
  a: TVector2;
  i, k, j: Integer;
  StartMap: TMapInfo;
begin
  Debug('StartServer');

  a := Default(TVector2);

  {$IFDEF SCRIPT}
  if sc_enable.Value then
    ScrptDispatcher.Launch();
  {$ENDIF}

  if (not IsTeamGame) then
    k := bots_random_noteam.Value
  else if sv_gamemode.Value = GAMESTYLE_TEAMMATCH then
    k := bots_random_alpha.Value + bots_random_bravo.Value + bots_random_charlie.Value + bots_random_delta.Value
  else
    k := bots_random_alpha.Value + bots_random_bravo.Value;

  //if (k > (MAX_SPRITES - 1)) then
  //  Exit;

  Randomize;

  for i := 1 to MAX_SPRITES do
  begin
    NoClientUpdatetime[i] := 0;
    Time_SpriteSnapshot[i] := 0;
    Time_SpriteSnapshot_Mov[i] := 0;
  end;

  for i := 1 to 4 do
    TeamScore[i] := 0;

  AddLineToLogFile(GameLog, 'Loading Map.', ConsoleLogFileName);

  // playing over internet - optimize
  if net_lan.Value = LAN then
  begin
    sv_guns_collide.SetValue(True);
    sv_kits_collide.SetValue(True);
  end;
  if net_lan.Value = INTERNET then
  begin
    sv_guns_collide.SetValue(False);
    sv_kits_collide.SetValue(False);
  end;

  MapIndex := 0;
  //StartMap := MapsList[MapIndex];

  // Load Map
  {
  if not Map.LoadMap(StartMap) then
  begin
    MainConsole.Console('Error: Could not load map ' + 'maps/' +
      StartMap + '.smap', DEBUG_MESSAGE_COLOR);
    if not Map.LoadMap('Arena') then
    begin
      MainConsole.Console('Error: Could not load map ' +
        'maps/' + 'Arena.smap', DEBUG_MESSAGE_COLOR);
      Exit;
    end else
      Map.Name := 'Arena';
  end
  else
    Map.Name := StartMap;

  MapCheckSum := GetMapChecksum(MapChangeName, UserDirectory);
  }

  if GetMapInfo(MapsList[MapIndex], UserDirectory, StartMap) then
  begin
    if not Map.LoadMap(StartMap) then
    begin
      MainConsole.Console('Error: Could not load map ' +
        StartMap.Name, DEBUG_MESSAGE_COLOR);
      Exit;
    end;
  end;

  MapCheckSum := GetMapChecksum(StartMap);

  {$IFDEF SCRIPT}
  ScrptDispatcher.OnAfterMapChange(Map.Name);
  {$ENDIF}

  // Create Weapons
  AddLineToLogFile(GameLog, 'Creating Weapons.', ConsoleLogFileName);

  if sv_realisticmode.Value then
  begin
    MainConsole.Console('Realistic Mode ON', MODE_MESSAGE_COLOR);
    StartHealth := REALISTIC_HEALTH;
    LoadWeapons('weapons_realistic');
    LastWepMod := 'weapons_realistic';
  end
  else
  begin
    StartHealth := DEFAULT_HEALTH;
    LoadWeapons('weapons');
    LastWepMod := 'weapons';
  end;

  // Weapons
  WeaponsInGame := 0;
  for i := 1 to 14 do
  begin
    if WeaponActive[i] = 1 then
      Inc(WeaponsInGame);
  end;

  for j := 1 to MAX_SPRITES do
    for i := 1 to 10 do
      WeaponSel[j][i] := WeaponActive[i];

  if sv_advancemode.Value then
  begin
    for j := 1 to MAX_SPRITES do
      for i := 1 to 10 do
        WeaponSel[j][i] := 1;

    MainConsole.Console('Advance Mode ON', MODE_MESSAGE_COLOR);
  end;

  if sv_gamemode.Value = GAMESTYLE_DEATHMATCH then
  begin
  end;

  // add yellow flag
  if sv_gamemode.Value = GAMESTYLE_POINTMATCH then
  begin
    RandomizeStart(a, 14);
    TeamFlag[1] := CreateThing(a, 255, OBJECT_POINTMATCH_FLAG, 255);
  end;

  // add yellow flag
  if sv_gamemode.Value = GAMESTYLE_HTF then
  begin
    RandomizeStart(a, 14);
    TeamFlag[1] := CreateThing(a, 255, OBJECT_POINTMATCH_FLAG, 255);
  end;

  if sv_gamemode.Value = GAMESTYLE_CTF then
  begin
    // red flag
    if RandomizeStart(a, 5) then
      TeamFlag[1] := CreateThing(a, 255, OBJECT_ALPHA_FLAG, 255);

    // blue flag
    if RandomizeStart(a, 6) then
      TeamFlag[2] := CreateThing(a, 255, OBJECT_BRAVO_FLAG, 255);
  end;

  if sv_gamemode.Value = GAMESTYLE_RAMBO then
  begin
    RandomizeStart(a, 15);
    CreateThing(a, 255, OBJECT_RAMBO_BOW, 255);
  end;

  if sv_gamemode.Value = GAMESTYLE_INF then
  begin
    // red flag
    if RandomizeStart(a, 5) then
      TeamFlag[1] := CreateThing(a, 255, OBJECT_ALPHA_FLAG, 255);

    // blue flag
    if RandomizeStart(a, 6) then
      TeamFlag[2] := CreateThing(a, 255, OBJECT_BRAVO_FLAG, 255);
  end;

  if not sv_survivalmode.Value then
  begin
    // spawn medikits
    SpawnThings(OBJECT_MEDICAL_KIT, Map.Medikits);

    // spawn grenadekits
    if sv_maxgrenades.Value > 0 then
      SpawnThings(OBJECT_GRENADE_KIT, Map.Grenades);
  end else
  begin
    MainConsole.Console('Survival Mode ON', MODE_MESSAGE_COLOR);
  end;


  // stat gun
  if sv_stationaryguns.Value then
  begin
    for i := 1 to MAX_SPAWNPOINTS do
    begin
      if Map.SpawnPoints[i].Active then
      begin
        if Map.SpawnPoints[i].Team = 16 then
        begin
          a.x := Map.SpawnPoints[i].X;
          a.y := Map.SpawnPoints[i].Y;
          CreateThing(a, 255, OBJECT_STATIONARY_GUN, 255);
        end;
      end;
    end;
  end;

  case sv_gamemode.Value of
    GAMESTYLE_DEATHMATCH: sv_killlimit.SetValue(sv_dm_limit.Value);
    GAMESTYLE_POINTMATCH: sv_killlimit.SetValue(sv_pm_limit.Value);
    GAMESTYLE_RAMBO:      sv_killlimit.SetValue(sv_rm_limit.Value);
    GAMESTYLE_TEAMMATCH:  sv_killlimit.SetValue(sv_tm_limit.Value);
    GAMESTYLE_CTF:        sv_killlimit.SetValue(sv_ctf_limit.Value);
    GAMESTYLE_INF:        sv_killlimit.SetValue(sv_inf_limit.Value);
    GAMESTYLE_HTF:        sv_killlimit.SetValue(sv_htf_limit.Value);
  end;

  // sort the players frag list
  SortPlayers;

  MapChangeCounter := -60;

  LastPlayer := 0;

  TimeLimitCounter := sv_timelimit.Value;

  // Wave respawn time
  UpdateWaveRespawnTime;
  WaveRespawnCounter := WaveRespawnTime;

  AddLineToLogFile(GameLog, 'Starting Game Server.', ConsoleLogFileName);

  UDP := TServerNetwork.Create(net_ip.Value, net_port.Value);

  if UDP.Active = True then
  begin
    WriteLn('[NET] Game networking initialized.');
    WriteLn('[NET] Server is listening on ' + UDP.GetStringAddress(@UDP.Address, True));
  end
  else
  begin
    WriteLn('[NET] Failed to bind to ' + net_ip.Value + ':' + IntToStr(net_port.Value));
    ShutDown;
    Exit;
  end;

  ServerPort := UDP.Port;

  if fileserver_enable.Value then
    StartFileServer;

  {$IFDEF ENABLE_FAE}
  if ac_enable.Value then
  begin
    WriteLn('[AC] Anti-Cheat enabled');
  end;
  {$ENDIF}

  if sv_lobby.Value then
    if not Assigned(LobbyThread) then
      LobbyThread := TLobbyThread.Create();

  if bots_random_alpha.Value > 0 then
    for k := 1 to bots_random_alpha.Value do
      AddBotPlayer(RandomBot, 1);
  if bots_random_bravo.Value > 0 then
    for k := 1 to bots_random_bravo.Value do
      AddBotPlayer(RandomBot, 2);
  if bots_random_charlie.Value > 0 then
    for k := 1 to bots_random_charlie.Value do
      AddBotPlayer(RandomBot, 3);
  if bots_random_delta.Value > 0 then
    for k := 1 to bots_random_delta.Value do
      AddBotPlayer(RandomBot, 4);

  UpdateGameStats;

end;

function PrepareMapChange(Name: String): Boolean;
var
  Status: TMapInfo;
begin
  Result := False;
  if GetMapInfo(Name, UserDirectory, Status) then
  begin
    MapChange := Status;
    MapChangeCounter := MapChangeTime;
    // send to client that map changes
    ServerMapChange(ALL_PLAYERS);
    MainConsole.Console('Next map: ' + Status.Name, GAME_MESSAGE_COLOR);
    {$IFDEF SCRIPT}
    ScrptDispatcher.OnBeforeMapChange(Status.Name);
    {$ENDIF}
    Result := True;
  end;
end;

procedure NextMap;
begin
  Debug('NextMap');

  if MapsList.Count < 1 then
  begin
    MainConsole.console('Can''t load maps from mapslist', GAME_MESSAGE_COLOR);
  end else
  begin
    MapIndex := MapIndex + 1;

    if MapIndex >= MapsList.Count then
      MapIndex := 0;
    PrepareMapChange(MapsList[MapIndex]);
  end;
end;


procedure SpawnThings(Style, Amount: Byte);
var
  i, k, l, team: Integer;
  a: TVector2;
begin
  Trace('SpawnThings');

  a := Default(TVector2);
  k := 0;
  case Style of
    OBJECT_MEDICAL_KIT:  k := 8;
    OBJECT_GRENADE_KIT:  k := 7;
    OBJECT_FLAMER_KIT:   k := 11;
    OBJECT_PREDATOR_KIT: k := 13;
    OBJECT_VEST_KIT:     k := 10;
    OBJECT_BERSERK_KIT:  k := 12;
    OBJECT_CLUSTER_KIT:  k := 9;
  end;

  for i := 1 to Amount do
  begin
    team := 0;
    if sv_gamemode.Value = GAMESTYLE_CTF then
      if (Style = OBJECT_MEDICAL_KIT) or (Style = OBJECT_GRENADE_KIT) then
      begin
        if i mod 2 = 0 then
          team := 1
        else
          team := 2;
      end;

    Thing[MAX_THINGS - 1].Team := team;

    if team = 0 then
    begin
      if not RandomizeStart(a, k) then Exit
    end else
      if not SpawnBoxes(a, k, MAX_THINGS - 1) then
        if not RandomizeStart(a, k) then Exit;

    a.X := a.X - SPAWNRANDOMVELOCITY +
      (Random(Round(2 * 100 * SPAWNRANDOMVELOCITY)) / 100);
    a.Y := a.Y - SPAWNRANDOMVELOCITY +
      (Random(Round(2 * 100 * SPAWNRANDOMVELOCITY)) / 100);
    l := CreateThing(a, 255, Style, 255);

    if (l > 0) and (l < MAX_THINGS + 1) then
      Thing[l].Team := team;
  end;
end;

function KickPlayer(num: Byte; Ban: Boolean; why: Integer; time: Integer;
  Reason: string = ''): Boolean;
var
  i: Integer;
  timestr: string;
begin
  Result := False;
  Debug('KickPlayer');

  // bound check
  if (num > MAX_PLAYERS) or (num < 1) then
    Exit;

  i := num;

  if (not Sprite[i].Active) then
    Exit;

  if ((why = KICK_CHEAT)) and (sv_anticheatkick.Value) then
    Exit;

  // check if admin should be kicked
  if (Why in [KICK_PING, KICK_FLOODING, KICK_VOTED]) and
     (Length(Sprite[i].Player.IP) > 5) then
  begin
    if IsRemoteAdminIP(Sprite[i].Player.IP) or
       IsAdminIP(Sprite[i].Player.IP) then
    begin
      MainConsole.Console(Sprite[i].Player.Name +
      ' is admin and cannot be kicked.', CLIENT_MESSAGE_COLOR);
      Exit;
    end;
  end;

  if Why = KICK_LEFTGAME then
    case Sprite[i].Player.Team of
      0: MainConsole.Console(Sprite[i].Player.Name + ' has left the game.', ENTER_MESSAGE_COLOR);
      1: MainConsole.Console(Sprite[i].Player.Name + ' has left alpha team.', ALPHAJ_MESSAGE_COLOR);
      2: MainConsole.Console(Sprite[i].Player.Name + ' has left bravo team.', BRAVOJ_MESSAGE_COLOR);
      3: MainConsole.Console(Sprite[i].Player.Name + ' has left charlie team.', CHARLIEJ_MESSAGE_COLOR);
      4: MainConsole.Console(Sprite[i].Player.Name + ' has left delta team.', DELTAJ_MESSAGE_COLOR);
      5: MainConsole.Console(Sprite[i].Player.Name + ' has left spectators', DELTAJ_MESSAGE_COLOR);
    end;

  if not Ban and not (why = KICK_LEFTGAME) and not (why = KICK_SILENT) then
    MainConsole.Console(Sprite[i].Player.Name + ' has been kicked.' +
      iif(Sprite[i].Player.ControlMethod = BOT, '',
      '(' + Sprite[i].Player.IP + ')'), CLIENT_MESSAGE_COLOR);

  if Ban then
  begin
    AddBannedIP(Sprite[i].Player.IP, Reason, time);
    {$IFDEF STEAM}
    AddBannedHW(IntToStr(Sprite[i].Player.SteamID.GetAccountID), Reason, time);
    {$ELSE}
    AddBannedHW(Sprite[i].Player.HWid, Reason, time);
    {$ENDIF}
  end;

  if Ban then
  begin
    if time > 0 then
    begin
      TimeStr := iif((time + 1) div 3600 > 1439,
        IntToStr((time + 1) div 5184000) + ' days',
        IntToStr((time + 1) div 3600) + ' minutes');
      MainConsole.Console(Sprite[i].Player.Name +
        ' has been kicked and banned for ' + TimeStr + ' (' + Reason + ')',
        CLIENT_MESSAGE_COLOR)
    end else
      MainConsole.Console(Sprite[i].Player.Name +
      ' has been kicked and permanently banned (' + Reason + ')',
      CLIENT_MESSAGE_COLOR);
  end;

  SaveTxtLists;

  if not Sprite[i].Active then
    Exit;
  {$IFDEF SCRIPT}
  if why in [KICK_AC, KICK_CHEAT, KICK_CONSOLE, KICK_PING, KICK_NORESPONSE,
      KICK_NOCHEATRESPONSE, KICK_FLOODING, KICK_VOTED, KICK_SILENT] then
    ScrptDispatcher.OnLeaveGame(i, true);
  {$ENDIF}

  ServerPlayerDisconnect(i, why);

  if ((why <> KICK_AC) and (why <> KICK_CHEAT) and (why <> KICK_CONSOLE) and
    (why <> KICK_VOTED)) then
  begin
    Sprite[i].DropWeapon();
  end;

  Sprite[i].Kill;

  Result := True;
end;

{$IFDEF STEAM}
initialization
  // Mask exceptions on 32 and 64 bit fpc builds
  {$IF defined(cpui386) or defined(cpux86_64)}
  //SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  {$ENDIF}
{$ENDIF}

end.
