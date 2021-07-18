{*******************************************************}
{                                                       }
{       ScriptGame unit for SOLDAT                      }
{                                                       }
{       Copyright (c) 2013 Tomasz Kolosowski            }
{                                                       }
{*******************************************************}

// TODO: Documentation
unit ScriptGame;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
  Classes,
  Net,
  NetworkServerGame,
  PascalCompiler,
  PascalExec,
  Script,
  ScriptCore3Api,
  ScriptPlayer,
  ScriptTeam,
  ScriptMapsList,
  ScriptBanLists,
  SysUtils,
  Server,
  Game,
  Command,
  Cvar,
  Demo,
  Version;

type
  TOnClockTick = procedure(Ticks: Integer) of object;
  TOnJoin = procedure(Player: TScriptActivePlayer; Team: TScriptTeam) of object;
  TOnLeave = procedure(Player: TScriptActivePlayer; Kicked: Boolean) of object;
  TOnRequest = function(Ip, Hw: string; Port: Word; State: Byte;
    Forwarded: Boolean; Password: string): Integer of object;
  TOnAdminCommand = function(Player: TScriptActivePlayer; Command: string): Boolean of object;
  TOnTCPMessage = procedure(Ip: string; Port: Word; Message: string) of object;
  TOnTCPCommand = function(Ip: string; Port: Word; Command: string): Boolean of object;
  TOnAdminConnect = procedure(Ip: string; Port: Word) of object;
  TOnAdminDisconnect = procedure(Ip: string; Port: Word) of object;

  TScriptGame = class(TObject)
  private
    FTeams: array [0..5] of TScriptTeam;
    FMapsList: TScriptMapsList;
    FBanLists: TScriptBanLists;
    FOnClockTick: TOnClockTick;
    FOnJoin: TOnJoin;
    FOnLeave: TOnLeave;
    FOnRequest: TOnRequest;
    FOnAdminCommand: TOnAdminCommand;
    FOnTCPMessage: TOnTCPMessage;
    FOnTCPCommand: TOnTCPCommand;
    FOnAdminConnect: TOnAdminConnect;
    FOnAdminDisconnect: TOnAdminDisconnect;
    FTickThreshold: Longint;
    function GetGameStyle: Byte;
    procedure SetGameStyle(Style: Byte);
    function GetMaxPlayers: Byte;
    procedure SetMaxPlayers(Max: Byte);
    function GetNextMap: string;
    function GetCurrentMap: string;
    function GetNumBots: Byte;
    function GetNumPlayers: Byte;
    function GetSpectators: Byte;
    function GetScoreLimit: Word;
    procedure SetScoreLimit(Limit: Word);
    function GetServerIP: string;
    function GetServerName: string;
    function GetServerPort: Word;
    function GetServerVersion: string;
    function GetServerInfo: string;
    function GetGravity: Single;
    procedure SetGravity(Grav: Single);
    function GetPaused: Boolean;
    procedure SetPaused(Paused: Boolean);
    function GetRespawnTime: Integer;
    procedure SetRespawnTime(Time: Integer);
    function GetMinRespawnTime: Integer;
    procedure SetMinRespawnTime(Time: Integer);
    function GetMaxRespawnTime: Integer;
    procedure SetMaxRespawnTime(Time: Integer);
    function GetMaxGrenades: Byte;
    procedure SetMaxGrenades(Num: Byte);
    function GetBonus: Byte;
    procedure SetBonus(Num: Byte);
    function GetTimeLimit: Longint;
    procedure SetTimeLimit(Num: Longint);
    function GetTimeLeft: Longint;
    function GetFriendlyFire: Boolean;
    procedure SetFriendlyFire(Enabled: Boolean);
    function GetPassword: string;
    procedure SetPassword(Pass: string);
    {$IFDEF RCON}
    function GetAdminPassword: string;
    procedure SetAdminPassword(Pass: string);
    {$ENDIF}
    function GetVotePercent: Byte;
    procedure SetVotePercent(Percent: Byte);
    function GetRealistic: Boolean;
    procedure SetRealistic(Enabled: Boolean);
    function GetSurvival: Boolean;
    procedure SetSurvival(Enabled: Boolean);
    function GetAdvance: Boolean;
    procedure SetAdvance(Enabled: Boolean);
    function GetBalance: Boolean;
    procedure SetBalance(Enabled: Boolean);
    function GetTickCount: Longint;
    function GetTeam(ID: Byte): TScriptTeam;
    function GetMapsList: TScriptMapsList;
    function GetBanLists: TScriptBanLists;
  public
    constructor Create;
    procedure Shutdown;
    procedure StartVoteKick(ID: Byte; Reason: string);
    procedure StartVoteMap(Name: string);
    procedure StopRecord;
    procedure Restart;
    function LoadWeap(WeaponMod: string): Boolean;
    function LoadCon(ConfigFile: string): Boolean;
    function LoadList(MapsList: string): Boolean;
    function StartRecord(DemoName: string): Boolean;
    //function LobbyRegister: Boolean;
    property GameStyle: Byte read GetGameStyle write SetGameStyle;
    property MaxPlayers: Byte read GetMaxPlayers write SetMaxPlayers;
    property NextMap: string read GetNextMap;
    property CurrentMap: string read GetCurrentMap;
    property NumBots: Byte read GetNumBots;
    property NumPlayers: Byte read GetNumPlayers;
    property Spectators: Byte read GetSpectators;
    property ScoreLimit: Word read GetScoreLimit write SetScoreLimit;
    property ServerIP: string read GetServerIP;
    property ServerName: string read GetServerName;
    property ServerPort: Word read GetServerPort;
    property ServerVersion: string read GetServerVersion;
    property ServerInfo: string read GetServerInfo;
    property Gravity: Single read GetGravity write SetGravity;
    property Paused: Boolean read GetPaused write SetPaused;
    property RespawnTime: Longint read GetRespawnTime write SetRespawnTime;
    property MinRespawnTime: Longint read GetMinRespawnTime write SetMinRespawnTime;
    property MaxRespawnTime: Longint read GetMaxRespawnTime write SetMaxRespawnTime;
    property MaxGrenades: Byte read GetMaxGrenades write SetMaxGrenades;
    property Bonus: Byte read GetBonus write SetBonus;
    property TimeLimit: Longint read GetTimeLimit write SetTimeLimit;
    property TimeLeft: Longint read GetTimeLeft;
    property FriendlyFire: Boolean read GetFriendlyFire write SetFriendlyFire;
    property Password: string read GetPassword write SetPassword;
    {$IFDEF RCON}
    property AdminPassword: string read GetAdminPassword write SetAdminPassword;
    {$ENDIF}
    property VotePercent: Byte read GetVotePercent write SetVotePercent;
    property Realistic: Boolean read GetRealistic write SetRealistic;
    property Survival: Boolean read GetSurvival write SetSurvival;
    property Advance: Boolean read GetAdvance write SetAdvance;
    property Balance: Boolean read GetBalance write SetBalance;
    property TickThreshold: Longint read FTickThreshold write FTickThreshold;
    property TickCount: Longint read GetTickCount;
    property Teams[ID: Byte]: TScriptTeam read GetTeam;
    property ScriptMapsList: TScriptMapsList read GetMapsList;
    property ScriptBanLists: TScriptBanLists read GetBanLists;
    property OnClockTick: TOnClockTick read FOnClockTick write FOnClockTick;
    property OnJoin: TOnJoin read FOnJoin write FOnJoin;
    property OnLeave: TOnLeave read FOnLeave write FOnLeave;
    property OnRequest: TOnRequest read FOnRequest write FOnRequest;
    property OnAdminCommand: TOnAdminCommand read FOnAdminCommand write FOnAdminCommand;
    property OnTCPMessage: TOnTCPMessage read FOnTCPMessage write FOnTCPMessage;
    property OnTCPCommand: TOnTCPCommand read FOnTCPCommand write FOnTCPCommand;
    property OnAdminConnect: TOnAdminConnect read FOnAdminConnect write FOnAdminConnect;
    property OnAdminDisconnect: TOnAdminDisconnect read FOnAdminDisconnect write FOnAdminDisconnect;
  end;

  TScriptGameAPI = class(TScriptCore3API)
  private
    FGame: TScriptGame;
  public
    constructor Create(ScriptCore3: TScript);
    procedure CompilerRegister(Compiler: TPascalCompiler); override;
    procedure RuntimeRegisterApi(Exec: TPascalExec); override;
    procedure RuntimeRegisterVariables(Exec: TPascalExec); override;
    property Game: TScriptGame read FGame;
  end;

implementation

uses
  ScriptCore3,
  ScriptPlayers;

function TScriptGame.GetGameStyle: Byte;
begin
  Result := Byte(sv_gamemode.Value);
end;

procedure TScriptGame.SetGameStyle(Style: Byte);
begin
  ParseInput('gamemode ' + IntToStr(Style), 255);
end;

function TScriptGame.GetMaxPlayers: Byte;
begin
  Result := sv_maxplayers.Value;
end;

procedure TScriptGame.SetMaxPlayers(Max: Byte);
begin
  if not sv_lockedmode.Value then
    sv_maxplayers.SetValue(Max)
  else
    //TODO: exceptions
    raise Exception.Create('Locked');
end;

function TScriptGame.GetNextMap: string;
var
  M: Integer;
begin
  M := MapIndex + 1;
  if M >= MapsList.Count then
    M := 0;
  Result := MapsList[M];
end;

function TScriptGame.GetCurrentMap: string;
begin
  Result := Map.Name;
end;

function TScriptGame.GetNumBots: Byte;
begin
  Result := BotsNum;
end;

function TScriptGame.GetNumPlayers: Byte;
begin
  Result := PlayersNum;
end;

function TScriptGame.GetSpectators: Byte;
begin
  Result := SpectatorsNum;
end;

function TScriptGame.GetScoreLimit: Word;
begin
  Result := sv_killlimit.Value;
end;

procedure TScriptGame.SetScoreLimit(Limit: Word);
begin
  ParseInput('limit ' + IntToStr(Limit), 255);
end;

function TScriptGame.GetServerIP: string;
begin
  Result := Server.ServerIP;
end;

function TScriptGame.GetServerName: string;
begin
  Result := sv_hostname.Value;
end;

function TScriptGame.GetServerPort: Word;
begin
  Result := Server.ServerPort;
end;

function TScriptGame.GetServerVersion: string;
begin
  Result := DEDVERSION;
end;

function TScriptGame.GetServerInfo: string;
begin
  Result := sv_info.Value;
end;

function TScriptGame.GetGravity: Single;
begin
  Result := Grav;
end;

procedure TScriptGame.SetGravity(Grav: Single);
begin
  sv_gravity.SetValue(Grav);
end;

function TScriptGame.GetPaused: Boolean;
begin
  Result := MapChangeCounter = 999999999;
end;

procedure TScriptGame.SetPaused(Paused: Boolean);
begin
  if Paused then
    ParseInput('pause', 255)
  else
    ParseInput('unpause', 255);
end;

function TScriptGame.GetRespawnTime: Integer;
begin
  Result := sv_respawntime.Value;
end;

procedure TScriptGame.SetRespawnTime(Time: Integer);
begin
  sv_respawntime.SetValue(Time);
end;

function TScriptGame.GetMinRespawnTime: Integer;
begin
  Result := sv_respawntime_minwave.Value;
end;

procedure TScriptGame.SetMinRespawnTime(Time: Integer);
begin
  sv_respawntime_minwave.SetValue(Time);
end;

function TScriptGame.GetMaxRespawnTime: Integer;
begin
  Result := sv_respawntime_maxwave.Value;
end;

procedure TScriptGame.SetMaxRespawnTime(Time: Integer);
begin
  sv_respawntime_maxwave.SetValue(Time);
end;

function TScriptGame.GetMaxGrenades: Byte;
begin
  Result := sv_maxgrenades.Value;
end;

procedure TScriptGame.SetMaxGrenades(Num: Byte);
begin
  sv_maxgrenades.SetValue(Num);
end;

function TScriptGame.GetBonus: Byte;
begin
  Result := sv_bonus_frequency.Value;
end;

procedure TScriptGame.SetBonus(Num: Byte);
begin
  sv_bonus_frequency.SetValue(Num);
end;

function TScriptGame.GetTimeLimit: Longint;
begin
  Result := sv_timelimit.Value;
end;

procedure TScriptGame.SetTimeLimit(Num: Longint);
begin
  sv_timelimit.SetValue(Num);
end;

function TScriptGame.GetTimeLeft: Longint;
begin
  Result := 60 * Game.TimeLeftMin + Game.TimeLeftSec;
end;

function TScriptGame.GetFriendlyFire: Boolean;
begin
  Result := sv_friendlyfire.Value;
end;

procedure TScriptGame.SetFriendlyFire(Enabled: Boolean);
begin
  sv_friendlyfire.SetValue(Enabled);
end;

function TScriptGame.GetPassword: string;
begin
  Result := sv_password.Value;
end;

procedure TScriptGame.SetPassword(Pass: string);
begin
  sv_password.SetValue(Pass);
end;
{$IFDEF RCON}
function TScriptGame.GetAdminPassword: string;
begin
  if Assigned(AdminServer) then
    Result := AdminServer.Password
  else
    Result := '';
end;

procedure TScriptGame.SetAdminPassword(Pass: string);
begin
  if Assigned(AdminServer) then
    AdminServer.Password := Pass;
end;
{$ENDIF}
function TScriptGame.GetVotePercent: Byte;
begin
  Result := sv_votepercent.Value;
end;

procedure TScriptGame.SetVotePercent(Percent: Byte);
begin
  sv_votepercent.SetValue(Percent);
end;

function TScriptGame.GetRealistic: Boolean;
begin
  Result := sv_realisticmode.Value;
end;

procedure TScriptGame.SetRealistic(Enabled: Boolean);
begin
  sv_realisticmode.SetValue(Enabled);
end;

function TScriptGame.GetSurvival: Boolean;
begin
  Result := sv_survivalmode.Value;
end;

procedure TScriptGame.SetSurvival(Enabled: Boolean);
begin
  sv_survivalmode.SetValue(Enabled);
end;

function TScriptGame.GetAdvance: Boolean;
begin
  Result := sv_advancemode.Value;
end;

procedure TScriptGame.SetAdvance(Enabled: Boolean);
begin
  sv_advancemode.SetValue(Enabled);
end;

function TScriptGame.GetBalance: Boolean;
begin
  Result := sv_botbalance.Value;
end;

procedure TScriptGame.SetBalance(Enabled: Boolean);
begin
  sv_botbalance.SetValue(Enabled);
end;

function TScriptGame.GetTickCount: Longint;
begin
  Result := MainTickCounter;
end;

function TScriptGame.GetTeam(ID: Byte): TScriptTeam;
begin
  if ID > 5 then
    raise Exception.Create('Wrong parameter');
  Result := Self.FTeams[ID];
end;

function TScriptGame.GetMapsList: TScriptMapsList;
begin
  Result := Self.FMapsList;
end;

function TScriptGame.GetBanLists: TScriptBanLists;
begin
  Result := Self.FBanLists;
end;

procedure TScriptGame.Restart;
begin
  ParseInput('restart', 255);
end;

procedure TScriptGame.StopRecord;
begin
  DemoRecorder.StopRecord;
end;

function TScriptGame.LoadWeap(WeaponMod: string): Boolean;
begin
  Result := Boolean(ParseInput('loadwep ' + WeaponMod, 255));
end;

function TScriptGame.LoadCon(ConfigFile: string): Boolean;
begin
  Result := Boolean(ParseInput('loadcon ' + ConfigFile, 255));
end;

function TScriptGame.LoadList(MapsList: string): Boolean;
begin
  Result := Boolean(ParseInput('loadlist ' + MapsList, 255));
end;

function TScriptGame.StartRecord(DemoName: string): Boolean;
begin
  Result := DemoRecorder.StartRecord(DemoName + '.sdm');
end;

//function TScriptGame.LobbyRegister: Boolean;
//begin
//  Result := RegisterAtLobby;
//end;

constructor TScriptGame.Create;
var
  i: Shortint;
begin
  Self.TickThreshold := 60;
  for i := 0 to 5 do
    Self.FTeams[i] := TScriptTeam.Create(i);
  Self.FMapsList := TScriptMapsList.Create;
  Self.FBanLists := TScriptBanLists.Create;
end;

procedure TScriptGame.Shutdown;
begin
  Server.ShutDown;
end;

procedure TScriptGame.StartVoteKick(ID: Byte; Reason: string);
begin
  StartVote(255, 1, IntToStr(ID), Reason);
  ServerSendVoteOn(1, 255, IntToStr(ID), Reason);
end;

procedure TScriptGame.StartVoteMap(Name: string);
begin
  StartVote(255, 0, Name, '');
  ServerSendVoteOn(0, 255, Name, '');
end;


procedure GameStyleReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.GameStyle;
end;

procedure GameStyleWriteHelper(Self: TScriptGame; const Result: Byte);
begin
  Self.GameStyle := Result;
end;

procedure MaxPlayersReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.MaxPlayers;
end;

procedure MaxPlayersWriteHelper(Self: TScriptGame; const Result: Byte);
begin
  Self.MaxPlayers := Result;
end;

procedure NextMapReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.NextMap;
end;

procedure CurrentMapReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.CurrentMap;
end;

procedure NumBotsReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.NumBots;
end;

procedure NumPlayersReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.NumPlayers;
end;

procedure SpectatorsReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.Spectators;
end;

procedure ScoreLimitReadHelper(Self: TScriptGame; var Result: Word);
begin
  Result := Self.ScoreLimit;
end;

procedure ScoreLimitWriteHelper(Self: TScriptGame; const Result: Word);
begin
  Self.ScoreLimit := Result;
end;

procedure ServerIPReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.ServerIP;
end;

procedure ServerNameReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.ServerName;
end;

procedure ServerPortReadHelper(Self: TScriptGame; var Result: Word);
begin
  Result := Self.ServerPort;
end;

procedure ServerVersionReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.ServerVersion;
end;

procedure ServerInfoReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.ServerInfo;
end;

procedure GravityReadHelper(Self: TScriptGame; var Result: Single);
begin
  Result := Self.Gravity;
end;

procedure GravityWriteHelper(Self: TScriptGame; const Result: Single);
begin
  Self.Gravity := Result;
end;

procedure PausedReadHelper(Self: TScriptGame; var Result: Boolean);
begin
  Result := Self.Paused;
end;

procedure PausedWriteHelper(Self: TScriptGame; const Result: Boolean);
begin
  Self.Paused := Result;
end;

procedure RespawnTimeReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.RespawnTime;
end;

procedure RespawnTimeWriteHelper(Self: TScriptGame; const Result: Longint);
begin
  Self.RespawnTime := Result;
end;

procedure MinRespawnTimeReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.MinRespawnTime;
end;

procedure MinRespawnTimeWriteHelper(Self: TScriptGame; const Result: Longint);
begin
  Self.MinRespawnTime := Result;
end;

procedure MaxRespawnTimeReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.MaxRespawnTime;
end;

procedure MaxRespawnTimeWriteHelper(Self: TScriptGame; const Result: Longint);
begin
  Self.MaxRespawnTime := Result;
end;

procedure MaxGrenadesReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.MaxGrenades;
end;

procedure MaxGrenadesWriteHelper(Self: TScriptGame; const Result: Byte);
begin
  Self.MaxGrenades := Result;
end;

procedure BonusReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.Bonus;
end;

procedure BonusWriteHelper(Self: TScriptGame; const Result: Byte);
begin
  Self.Bonus := Result;
end;

procedure TimeLimitReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.TimeLimit;
end;

procedure TimeLimitWriteHelper(Self: TScriptGame; const Result: Longint);
begin
  Self.TimeLimit := Result;
end;

procedure TimeLeftReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.TimeLeft;
end;

procedure FriendlyFireReadHelper(Self: TScriptGame; var Result: Boolean);
begin
  Result := Self.FriendlyFire;
end;

procedure FriendlyFireWriteHelper(Self: TScriptGame; const Result: Boolean);
begin
  Self.FriendlyFire := Result;
end;

procedure PasswordReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.Password;
end;

procedure PasswordWriteHelper(Self: TScriptGame; const Result: string);
begin
  Self.Password := Result;
end;
{$IFDEF RCON}
procedure AdminPasswordReadHelper(Self: TScriptGame; var Result: string);
begin
  Result := Self.AdminPassword;
end;

procedure AdminPasswordWriteHelper(Self: TScriptGame; const Result: string);
begin
  Self.AdminPassword := Result;
end;
{$ENDIF}
procedure VotePercentReadHelper(Self: TScriptGame; var Result: Byte);
begin
  Result := Self.VotePercent;
end;

procedure VotePercentWriteHelper(Self: TScriptGame; const Result: Byte);
begin
  Self.VotePercent := Result;
end;

procedure RealisticReadHelper(Self: TScriptGame; var Result: Boolean);
begin
  Result := Self.Realistic;
end;

procedure RealisticWriteHelper(Self: TScriptGame; const Result: Boolean);
begin
  Self.Realistic := Result;
end;

procedure SurvivalReadHelper(Self: TScriptGame; var Result: Boolean);
begin
  Result := Self.Survival;
end;

procedure SurvivalWriteHelper(Self: TScriptGame; const Result: Boolean);
begin
  Self.Survival := Result;
end;

procedure AdvanceReadHelper(Self: TScriptGame; var Result: Boolean);
begin
  Result := Self.Advance;
end;

procedure AdvanceWriteHelper(Self: TScriptGame; const Result: Boolean);
begin
  Self.Advance := Result;
end;

procedure BalanceReadHelper(Self: TScriptGame; var Result: Boolean);
begin
  Result := Self.Balance;
end;

procedure BalanceWriteHelper(Self: TScriptGame; const Result: Boolean);
begin
  Self.Balance := Result;
end;

procedure TickThresholdReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.TickThreshold;
end;

procedure TickThresholdWriteHelper(Self: TScriptGame; const Result: Longint);
begin
  Self.TickThreshold := Result;
end;

procedure TickCountReadHelper(Self: TScriptGame; var Result: Longint);
begin
  Result := Self.TickCount;
end;

procedure TeamsReadHelper(Self: TScriptGame; var Result: TScriptTeam; const ID: Byte);
begin
  Result := Self.Teams[ID];
end;

procedure MapsListReadHelper(Self: TScriptGame; var Result: TScriptMapsList);
begin
  Result := Self.ScriptMapsList;
end;

procedure BanListsReadHelper(Self: TScriptGame; var Result: TScriptBanLists);
begin
  Result := Self.ScriptBanLists;
end;

procedure OnClockTickReadHelper(Self: TScriptGame; var Result: TOnClockTick);
begin
  Result := Self.OnClockTick;
end;

procedure OnClockTickWriteHelper(Self: TScriptGame; const Result: TOnClockTick);
begin
  Self.OnClockTick := Result;
end;

procedure OnRequestReadHelper(Self: TScriptGame; var Result: TOnRequest);
begin
  Result := Self.OnRequest;
end;

procedure OnRequestWriteHelper(Self: TScriptGame; const Result: TOnRequest);
begin
  Self.OnRequest := Result;
end;

procedure OnJoinReadHelper(Self: TScriptGame; var Result: TOnJoin);
begin
  Result := Self.OnJoin;
end;

procedure OnJoinWriteHelper(Self: TScriptGame; const Result: TOnJoin);
begin
  Self.OnJoin := Result;
end;

procedure OnLeaveReadHelper(Self: TScriptGame; var Result: TOnLeave);
begin
  Result := Self.OnLeave;
end;

procedure OnLeaveWriteHelper(Self: TScriptGame; const Result: TOnLeave);
begin
  Self.OnLeave := Result;
end;

procedure OnAdminCommandReadHelper(Self: TScriptGame; var Result: TOnAdminCommand);
begin
  Result := Self.OnAdminCommand;
end;

procedure OnAdminCommandWriteHelper(Self: TScriptGame; const Result: TOnAdminCommand);
begin
  Self.OnAdminCommand := Result;
end;

procedure OnTCPMessageReadHelper(Self: TScriptGame; var Result: TOnTCPMessage);
begin
  Result := Self.OnTCPMessage;
end;

procedure OnTCPMessageWriteHelper(Self: TScriptGame; const Result: TOnTCPMessage);
begin
  Self.OnTCPMessage := Result;
end;

procedure OnTCPCommandReadHelper(Self: TScriptGame; var Result: TOnTCPCommand);
begin
  Result := Self.OnTCPCommand;
end;

procedure OnTCPCommandWriteHelper(Self: TScriptGame; const Result: TOnTCPCommand);
begin
  Self.OnTCPCommand := Result;
end;

procedure OnAdminConnectReadHelper(Self: TScriptGame; var Result: TOnAdminConnect);
begin
  Result := Self.OnAdminConnect;
end;

procedure OnAdminConnectWriteHelper(Self: TScriptGame; const Result: TOnAdminConnect);
begin
  Self.OnAdminConnect := Result;
end;

procedure OnAdminDisconnectReadHelper(Self: TScriptGame; var Result: TOnAdminDisconnect);
begin
  Result := Self.OnAdminDisconnect;
end;

procedure OnAdminDisconnectWriteHelper(Self: TScriptGame; const Result: TOnAdminDisconnect);
begin
  Self.OnAdminDisconnect := Result;
end;

constructor TScriptGameAPI.Create(ScriptCore3: TScript);
begin
  inherited Create(ScriptCore3);
end;

procedure TScriptGameAPI.CompilerRegister(Compiler: TPascalCompiler);
var
  AClass: TPascalCompiletimeClass;
begin
  Compiler.AddType('TOnClockTickEvent', 'procedure(Ticks: Integer)');
  Compiler.AddType('TOnJoinGameEvent', 'procedure(Player: TActivePlayer; Team: TTeam)');
  Compiler.AddType('TOnLeaveGameEvent',
    'procedure(Player: TActivePlayer; Kicked: Boolean)');
  Compiler.AddType('TOnRequestEvent',
    'function(Ip, Hw: string; Port: Word; State: Byte; Forwarded: Boolean; Password: string): Integer;');
  Compiler.AddType('TOnAdminCommandEvent', 'function(Player: TActivePlayer; Command: string): Boolean;');
  Compiler.AddType('TOnTCPMessageEvent', 'procedure(Ip: string; Port: Word; Message: string)');
  Compiler.AddType('TOnTCPCommandEvent', 'function(Ip: string; Port: Word; Command: string): Boolean;');
  Compiler.AddType('TOnAdminConnectEvent', 'procedure(Ip: string; Port: Word)');
  Compiler.AddType('TOnAdminDisconnectEvent', 'procedure(Ip: string; Port: Word)');
  AClass := Compiler.AddClass(nil, 'TGame');
  with AClass do
  begin
    RegisterMethod('procedure Shutdown');
    RegisterMethod('procedure StartVoteKick(ID: Byte; Reason: string)');
    RegisterMethod('procedure StartVoteMap(Name: string)');
    RegisterMethod('procedure StopRecord');
    RegisterMethod('procedure Restart');
    RegisterMethod('function LoadWeap(WeaponMod: string): Boolean;');
    RegisterMethod('function LoadCon(ConfigFile: string): Boolean');
    RegisterMethod('function LoadList(MapsList: string): Boolean');
    RegisterMethod('function StartRecord(DemoName: string): Boolean');
    //RegisterMethod('procedure LobbyRegister');
    RegisterProperty('GameStyle', 'Byte', iptRW);
    RegisterProperty('MaxPlayers', 'Byte', iptRW);
    RegisterProperty('NextMap', 'string', iptR);
    RegisterProperty('CurrentMap', 'string', iptR);
    RegisterProperty('NumBots', 'Byte', iptR);
    RegisterProperty('NumPlayers', 'Byte', iptR);
    RegisterProperty('Spectators', 'Byte', iptR);
    RegisterProperty('ScoreLimit', 'Word', iptRW);
    RegisterProperty('ServerIP', 'string', iptR);
    RegisterProperty('ServerName', 'string', iptR);
    RegisterProperty('ServerPort', 'Word', iptR);
    RegisterProperty('ServerVersion', 'string', iptR);
    RegisterProperty('ServerInfo', 'string', iptR);
    RegisterProperty('Gravity', 'Single', iptRW);
    RegisterProperty('Paused', 'Boolean', iptRW);
    RegisterProperty('RespawnTime', 'LongInt', iptRW);
    RegisterProperty('MinRespawnTime', 'LongInt', iptRW);
    RegisterProperty('MaxRespawnTime', 'LongInt', iptRW);
    RegisterProperty('MaxGrenades', 'Byte', iptRW);
    RegisterProperty('Bonus', 'Byte', iptRW);
    RegisterProperty('TimeLimit', 'LongInt', iptRW);
    RegisterProperty('TimeLeft', 'LongInt', iptR);
    RegisterProperty('FriendlyFire', 'Boolean', iptRW);
    RegisterProperty('Password', 'string', iptRW);
    RegisterProperty('AdminPassword', 'string', iptRW);
    RegisterProperty('VotePercent', 'Byte', iptRW);
    RegisterProperty('Realistic', 'Boolean', iptRW);
    RegisterProperty('Survival', 'Boolean', iptRW);
    RegisterProperty('Advance', 'Boolean', iptRW);
    RegisterProperty('Balance', 'Boolean', iptRW);
    RegisterProperty('TickThreshold', 'LongInt', iptRW);
    RegisterProperty('TickCount', 'LongInt', iptR);
    RegisterProperty('Teams', 'TTeam Byte', iptR);
    RegisterProperty('MapsList', 'TMapsList', iptR);
    RegisterProperty('BanLists', 'TBanLists', iptR);
    RegisterProperty('OnClockTick', 'TOnClockTickEvent', iptRW);
    RegisterProperty('OnJoin', 'TOnJoinGameEvent', iptRW);
    RegisterProperty('OnLeave', 'TOnLeaveGameEvent', iptRW);
    RegisterProperty('OnRequest', 'TOnRequestEvent', iptRW);
    RegisterProperty('OnAdminCommand', 'TOnAdminCommandEvent', iptRW);
    RegisterProperty('OnTCPMessage', 'TOnTCPMessageEvent', iptRW);
    RegisterProperty('OnTCPCommand', 'TOnTCPCommandEvent', iptRW);
    RegisterProperty('OnAdminConnect', 'TOnAdminConnectEvent', iptRW);
    RegisterProperty('OnAdminDisconnect', 'TOnAdminDisconnectEvent', iptRW);
  end;
  Compiler.AddPtrVariable('Game', AClass.aType);
end;

procedure TScriptGameAPI.RuntimeRegisterApi(Exec: TPascalExec);
begin
  with Exec.AddClass(TScriptGame, 'TGame') do
  begin
    RegisterMethod(@TScriptGame.Shutdown, 'Shutdown');
    RegisterMethod(@TScriptGame.StartVoteKick, 'StartVoteKick');
    RegisterMethod(@TScriptGame.StartVoteMap, 'StartVoteMap');
    RegisterMethod(@TScriptGame.StopRecord, 'StopRecord');
    RegisterMethod(@TScriptGame.Restart, 'Restart');
    RegisterMethod(@TScriptGame.LoadWeap, 'LoadWeap');
    RegisterMethod(@TScriptGame.LoadCon, 'LoadCon');
    RegisterMethod(@TScriptGame.LoadList, 'LoadList');
    RegisterMethod(@TScriptGame.StartRecord, 'StartRecord');
    //RegisterMethod(@TScriptGame.LobbyRegister, 'LobbyRegister');
    RegisterPropertyHelper(@GameStyleReadHelper, @GameStyleWriteHelper,
      'GameStyle');
    RegisterPropertyHelper(@MaxPlayersReadHelper, @MaxPlayersWriteHelper,
      'MaxPlayers');
    RegisterPropertyHelper(@NextMapReadHelper, nil, 'NextMap');
    RegisterPropertyHelper(@CurrentMapReadHelper, nil, 'CurrentMap');
    RegisterPropertyHelper(@NumBotsReadHelper, nil, 'NumBots');
    RegisterPropertyHelper(@NumPlayersReadHelper, nil, 'NumPlayers');
    RegisterPropertyHelper(@SpectatorsReadHelper, nil, 'Spectators');
    RegisterPropertyHelper(@ScoreLimitReadHelper, @ScoreLimitWriteHelper,
      'ScoreLimit');
    RegisterPropertyHelper(@ServerIPReadHelper, nil, 'ServerIP');
    RegisterPropertyHelper(@ServerNameReadHelper, nil, 'ServerName');
    RegisterPropertyHelper(@ServerPortReadHelper, nil, 'ServerPort');
    RegisterPropertyHelper(@ServerVersionReadHelper, nil, 'ServerVersion');
    RegisterPropertyHelper(@ServerInfoReadHelper, nil, 'ServerInfo');
    RegisterPropertyHelper(@GravityReadHelper, @GravityWriteHelper, 'Gravity');
    RegisterPropertyHelper(@PausedReadHelper, @PausedWriteHelper, 'Paused');
    RegisterPropertyHelper(@RespawnTimeReadHelper, @RespawnTimeWriteHelper,
      'RespawnTime');
    RegisterPropertyHelper(@MinRespawnTimeReadHelper, @MinRespawnTimeWriteHelper,
      'MinRespawnTime');
    RegisterPropertyHelper(@MaxRespawnTimeReadHelper, @MaxRespawnTimeWriteHelper,
      'MaxRespawnTime');
    RegisterPropertyHelper(@MaxGrenadesReadHelper, @MaxGrenadesWriteHelper,
      'MaxGrenades');
    RegisterPropertyHelper(@BonusReadHelper, @BonusWriteHelper, 'Bonus');
    RegisterPropertyHelper(@TimeLimitReadHelper, @TimeLimitWriteHelper,
      'TimeLimit');
    RegisterPropertyHelper(@TimeLeftReadHelper, nil, 'TimeLeft');
    RegisterPropertyHelper(@FriendlyFireReadHelper, @FriendlyFireWriteHelper,
      'FriendlyFire');
    RegisterPropertyHelper(@PasswordReadHelper, @PasswordWriteHelper,
      'Password');
    {$IFDEF RCON}
    RegisterPropertyHelper(@AdminPasswordReadHelper, @AdminPasswordWriteHelper,
      'AdminPassword');
    {$ENDIF}
    RegisterPropertyHelper(@VotePercentReadHelper, @VotePercentWriteHelper,
      'VotePercent');
    RegisterPropertyHelper(@RealisticReadHelper, @RealisticWriteHelper,
      'Realistic');
    RegisterPropertyHelper(@SurvivalReadHelper, @SurvivalWriteHelper,
      'Survival');
    RegisterPropertyHelper(@AdvanceReadHelper, @AdvanceWriteHelper, 'Advance');
    RegisterPropertyHelper(@BalanceReadHelper, @BalanceWriteHelper, 'Balance');
    RegisterPropertyHelper(@TickThresholdReadHelper, @TickThresholdWriteHelper,
      'TickThreshold');
    RegisterPropertyHelper(@TickCountReadHelper, nil, 'TickCount');
    RegisterPropertyHelper(@TeamsReadHelper, nil, 'Teams');
    RegisterPropertyHelper(@MapsListReadHelper, nil, 'MapsList');
    RegisterPropertyHelper(@BanListsReadHelper, nil, 'BanLists');
    RegisterEventPropertyHelper(@OnClockTickReadHelper, @OnClockTickWriteHelper,
      'OnClockTick');
    RegisterEventPropertyHelper(@OnRequestReadHelper, @OnRequestWriteHelper,
      'OnRequest');
    RegisterEventPropertyHelper(@OnJoinReadHelper, @OnJoinWriteHelper, 'OnJoin');
    RegisterEventPropertyHelper(@OnLeaveReadHelper, @OnLeaveWriteHelper, 'OnLeave');
    RegisterEventPropertyHelper(@OnAdminCommandReadHelper, @OnAdminCommandWriteHelper,
      'OnAdminCommand');
    RegisterEventPropertyHelper(@OnTCPMessageReadHelper, @OnTCPMessageWriteHelper,
      'OnTCPMessage');
    RegisterEventPropertyHelper(@OnTCPCommandReadHelper, @OnTCPCommandWriteHelper,
      'OnTCPCommand');
    RegisterEventPropertyHelper(@OnAdminConnectReadHelper, @OnAdminConnectWriteHelper,
      'OnAdminConnect');
    RegisterEventPropertyHelper(@OnAdminDisconnectReadHelper, @OnAdminDisconnectWriteHelper,
      'OnAdminDisconnect');
  end;
end;

procedure TScriptGameAPI.RuntimeRegisterVariables(Exec: TPascalExec);
var
  i: Byte;
  FScriptPlayers: TScriptPlayersAPI;
begin
  Self.FGame := TScriptGame.Create;
  Exec.SetPointerToData('Game', @Self.FGame, Exec.FindType(btClass));
  // This is a workaround. Be sure that the positions of the API-List does
  // not get altered. If it does, check if TScriptPlayersAPI is still in
  // the position as shown below. (TScriptCore3.Create)
  FScriptPlayers := TScriptPlayersAPI(TScriptCore3(Self.FScript).Api[9]);
  for i := 1 to MAX_PLAYERS do
    if FScriptPlayers.Players[i].Active then
      Self.FGame.Teams[FScriptPlayers.Players[i].Team].AddPlayer(FScriptPlayers.Players[i]);
end;

end.
