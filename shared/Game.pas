{*******************************************************}
{                                                       }
{       Game Unit                                       }
{                                                       }
{       Copyright (c) 2012-2013 Gregor A. Cieslak       }
{                                                       }
{*******************************************************}

unit Game;

interface

uses
  SysUtils, Classes,
  {$IFNDEF SERVER}
  Sparks,
  {$ENDIF}
  Vector, Constants, PolyMap, Parts, Sprites, Bullets, Things, Waypoints, Anims,
  Weapons, Sha1, Util;

type
  TKillSort = record
    Kills, Deaths: Integer;
    Flags: Byte;
    PlayerNum: Integer;
    Color: LongWord;
  end;

var
  // TODO: move all dependent functions in this unit
  Ticks, TicksPerSecond: Integer;  // Tick counter and Ticks persecond counter
  // Ticks counter etc
  Frames, FramesPerSecond, TickTime, TickTimelast: Integer;
  GOALTICKS: Integer = DEFAULT_GOALTICKS;

  BulletTimeTimer: Integer;

  SpriteParts, BulletParts, SparkParts,
  GostekSkeleton, BoxSkeleton, FlagSkeleton, ParaSkeleton, StatSkeleton,
  RifleSkeleton10, RifleSkeleton11, RifleSkeleton18, RifleSkeleton22,
  RifleSkeleton28, RifleSkeleton36, RifleSkeleton37, RifleSkeleton39,
  RifleSkeleton43, RifleSkeleton50, RifleSkeleton55: ParticleSystem;

  Run, Stand, RunBack: TAnimation;
  Jump, JumpSide, Roll, RollBack: TAnimation;
  Fall: TAnimation;
  Crouch, CrouchRun, CrouchRunBack: TAnimation;
  Reload, Throw, Recoil, Shotgun, Barret, SmallRecoil, AimRecoil,
    HandsUpRecoil: TAnimation;
  ClipIn, ClipOut, SlideBack: TAnimation;
  Change: TAnimation;
  ThrowWeapon, WeaponNone: TAnimation;
  Punch, ReloadBow, Melee: TAnimation;
  Cigar, Match, Smoke, Wipe, Groin, TakeOff, Victory, Piss, Mercy, Mercy2,
    Own: TAnimation;
  Prone, GetUp, ProneMove: TAnimation;
  Aim, HandsUpAim: TAnimation;

  {$IFNDEF SERVER}
  GameWidth: Integer = DEFAULT_WIDTH;
  GameHeight: Integer = DEFAULT_HEIGHT;

  GameWidthHalf: Single = DEFAULT_WIDTH / 2;
  GameHeightHalf: Single = DEFAULT_WIDTH / 2;
  {$ENDIF}
  // Ping Impr - vars
  OldSpritePos: array[1..MAX_SPRITES, 0..MAX_OLDPOS] of TVector2;

  // survival vars
  AliveNum: Byte;
  TeamAliveNum: array[0..5] of Byte;
  TeamPlayersNum: array[0..4] of Byte;
  SurvivalEndRound: Boolean = False;
  WeaponsCleaned: Boolean = False;

  CeaseFireTime: Integer = DEFAULT_CEASEFIRE_TIME;
  MapChangeTime: Integer = DEFAULT_MAPCHANGE_TIME;
  MapChangeCounter: Integer;
  MapChangeName: string;
  MapChange: TMapInfo;
  MapChangeItemID: uint64;
  MapChangeChecksum: TSHA1Digest;
  TimeLimitCounter: Integer = 3600;
  StartHealth: Integer = 150;
  TimeLeftSec, TimeLeftMin: Integer;
  WeaponSel: array[1..MAX_SPRITES, 1..MAIN_WEAPONS] of Byte;

  TeamScore: array[0..5] of Integer;
  TeamFlag: array[0..4] of Integer;

  SinusCounter: Single = 0;

  Map: TPolyMap;

  GameModChecksum: TSHA1Digest;
  CustomModChecksum: TSHA1Digest;
  MapCheckSum: TSHA1Digest;

  MapIndex: Integer;

  BotPath: TWaypoints;

  SortedPlayers: array[1..MAX_SPRITES] of TKillSort;
  {$IFNDEF SERVER}
  SortedTeamScore: array[1..MAX_SPRITES] of TKillSort;

  HeartbeatTime, HeartbeatTimeWarnings: Integer;
  {$ENDIF}

  // Sprites
  // FIXME: client has frozen bullets when Sprite array position is "bad"
  // if happens again change Sprite array to 0..MAX_SPRITES to "fix" it
  // possible cause: out of range array read (index 0 instead of 1)
  Sprite: array[1..MAX_SPRITES] of TSprite;  // player, game handling sprite
  Bullet: array[1..MAX_BULLETS] of TBullet;  // bullet game handling sprite
  {$IFNDEF SERVER}
  Spark: array[1..MAX_SPARKS] of TSpark;  // spark game handling sprite
  {$ENDIF}
  Thing: array[1..MAX_THINGS] of TThing;  // thing game handling sprite

  // voting
  VoteActive: Boolean = False;
  VoteType: Byte = 0; // VOTE_MAP or VOTE_KICK
  VoteTarget: string = '';
  VoteStarter: string = '';
  VoteReason: string = '';
  VoteTimeRemaining: Integer = -1;
  VoteNumVotes: Byte = 0;
  VoteMaxVotes: Byte = 0;
  VoteHasVoted: array[1..MAX_SPRITES] of Boolean;
  VoteCooldown: array[1..MAX_SPRITES] of Integer;
  VoteKickReasonType: Boolean = False;

procedure Number27Timing;
procedure ToggleBulletTime(TurnOn: Boolean; Duration: Integer = 30);
procedure UpdateGameStats;
function PointVisible(X, Y: Single; i: Integer): Boolean;
function PointVisible2(X, Y: Single; i: Integer): Boolean;
procedure StartVote(StarterVote, TypeVote: Byte; TargetVote, ReasonVote: string);
procedure StopVote;
procedure TimerVote;
{$IFDEF SERVER}
procedure CountVote(Voter: Byte);
{$ENDIF}
procedure ShowMapChangeScoreboard(); overload;
procedure ShowMapChangeScoreboard(const NextMap: string); overload;
function IsTeamGame(): Boolean;
{$IFNDEF SERVER}
function IsPointOnScreen(Point: TVector2): Boolean;
{$ENDIF}
procedure ChangeMap;
procedure SortPlayers;

implementation

uses
  {$IFDEF SERVER}Server,{$ELSE}Client,{$ENDIF}
  {$IFDEF SERVER}
  TraceLog, ServerHelper,
  {$IFDEF SCRIPT}
  ScriptDispatcher,
  {$ENDIF}
  {$ELSE}
  Sound, GameMenus, ClientGame, GameRendering, GameStrings, InterfaceGraphics,
  {$ENDIF}
  Net, Demo,
  {$IFNDEF SERVER}
  NetworkClientGame
  {$ELSE}
  NetworkServerGame, NetworkServerSprite
  {$ENDIF};

var
  // NUMBER27's TIMING ROUTINES
  TimeinMil, TimeinMilLast: QWord;  // time in Milliseconds the computer has
                                       // been running
  Timepassed: Cardinal;  // Time in Milliseconds the program has been running
  Seconds, SecondsLast: Integer;  // Seconds the program has been running

// Timing routine
procedure Number27Timing;
begin
  TimeInMilLast := TimeInMil;
  TimeInMil := GetTickCount64;
  if TimeInMil - TimeinMilLast > 2000 then
    TimeInMilLast := TimeInMil;  // safety precaution

  Timepassed := Timepassed + (TimeInMil - TimeInMilLast);
  SecondsLast := Seconds;
  Seconds := Trunc(Timepassed / 1000);

  if Seconds <> SecondsLast then
  begin  // new Second
    TicksPerSecond := Ticks;
    Ticks := 0;

    FramesPerSecond := Frames;
    Frames := 0;
  end;

  Inc(Frames);

  TickTimeLast := TickTime;

  TickTime := Trunc(Timepassed / (1000 / GOALTICKS));
end;

procedure UpdateGameStats;
var
  i: Integer;
  S: TStringList;
begin
  // Game Stats save
  if log_enable.Value then
  begin
    try
      S := TStringList.Create;

      S.Add('In-Game Statistics');
      S.Add('Players: ' + IntToStr(PlayersNum));
      S.Add('Map: ' + Map.Name);
      case sv_gamemode.Value of
        GAMESTYLE_DEATHMATCH: S.Add('Gamemode: Deathmatch');
        GAMESTYLE_POINTMATCH: S.Add('Gamemode: Pointmatch');
        GAMESTYLE_TEAMMATCH: S.Add('Gamemode: Teammatch');
        GAMESTYLE_CTF: S.Add('Gamemode: Capture the Flag');
        GAMESTYLE_RAMBO: S.Add('Gamemode: Rambomatch');
        GAMESTYLE_INF: S.Add('Gamemode: Infiltration');
        GAMESTYLE_HTF: S.Add('Gamemode: Hold the Flag');
      end;
      S.Add('Timeleft: ' + IntToStr(TimeLeftMin) + ':' + IntToStr(TimeLeftSec));
      if IsTeamGame() then
      begin
        S.Add('Team 1: ' + IntToStr(TeamScore[1]));
        S.Add('Team 2: ' + IntToStr(TeamScore[2]));
        S.Add('Team 3: ' + IntToStr(TeamScore[3]));
        S.Add('Team 4: ' + IntToStr(TeamScore[4]));
      end;

      S.Add('Players list: (name/kills/deaths/team/ping)');
      if PlayersNum > 0 then
        for i := 1 to PlayersNum do
        begin
          S.Add(Sprite[SortedPlayers[i].PlayerNum].Player.Name);
          S.Add(IntToStr(Sprite[SortedPlayers[i].PlayerNum].Player.Kills));
          S.Add(IntToStr(Sprite[SortedPlayers[i].PlayerNum].Player.Deaths));
          S.Add(IntToStr(Sprite[SortedPlayers[i].PlayerNum].Player.Team));
          S.Add(IntToStr(Sprite[SortedPlayers[i].PlayerNum].Player.RealPing));
        end;
      {$IFNDEF SERVER}
      S.Add('');
      S.Add('Server:');
      S.Add(JoinIP + ':' + JoinPort);
      {$ENDIF}

      S.SaveToFile(UserDirectory + 'logs/gamestat.txt');
    finally
      FreeAndNil(S);
    end;
  end;
end;

procedure ToggleBulletTime(TurnOn: Boolean; Duration: Integer = 30);
begin
  {$IFDEF SERVER}
  Trace('ToggleBulletTime');
  {$ENDIF}

  if TurnOn then
  begin
    BulletTimeTimer := Duration;
    GOALTICKS := DEFAULT_GOALTICKS div 3;
  end else
    GOALTICKS := DEFAULT_GOALTICKS;

  Number27Timing;
end;

function PointVisible(X, Y: Single; i: Integer): Boolean;
{$IFDEF SERVER}
const
  // TODO: check why numbers differ on server and client
  GAME_WIDTH = MAX_GAME_WIDTH;
  GAME_HEIGHT = 480;
{$ELSE}
var
  GAME_WIDTH : Integer;
  GAME_HEIGHT : Integer;
{$ENDIF}
var
  SX, SY: Single;
begin
  {$IFDEF SERVER}
  Trace('PointVisible');
  {$ELSE}
  // workaround because of variables instead of constants
  GAME_WIDTH := GameWidth;
  GAME_HEIGHT := GameHeight;
  {$ENDIF}

  Result := False;

  if (i > MAX_PLAYERS) or (i < 1) then
    Exit;

  SX := Spriteparts.Pos[i].X - ((Spriteparts.Pos[i].X - Sprite[i].Control.MouseAimX) / 2);
  SY := Spriteparts.Pos[i].Y - ((Spriteparts.Pos[i].Y - Sprite[i].Control.MouseAimY) / 2);

  if (X > (SX - GAME_WIDTH)) and (X < (SX + GAME_WIDTH)) and
     (Y > (SY - GAME_HEIGHT)) and (Y < (SY + GAME_HEIGHT)) then
    Result := True;
end;

function PointVisible2(X, Y: Single; I: Integer): Boolean;
const
  // TODO: check why numbers differ on server and client
  {$IFDEF SERVER}
  GAME_WIDTH = MAX_GAME_WIDTH;
  GAME_HEIGHT = 480;
  {$ELSE}
  GAME_WIDTH = 600;
  GAME_HEIGHT = 440;
  {$ENDIF}
var
  SX, SY: Single;
begin
  {$IFDEF SERVER}
  Trace('PointVisible2');
  {$ENDIF}

  Result := False;

  SX := Spriteparts.Pos[I].X;
  SY := Spriteparts.Pos[I].Y;

  if (X > (SX - GAME_WIDTH)) and (X < (SX + GAME_WIDTH)) and
    (Y > (SY - GAME_HEIGHT)) and (Y < (SY + GAME_HEIGHT)) then
    Result := True;
end;

{$IFNDEF SERVER}
function IsPointOnScreen(Point: TVector2): Boolean;
var
  P1, P2: Single;
begin
  Result := True;
  P1 := GameWidthHalf - (CameraX - Point.X);
  P2 := GameHeightHalf - (CameraY - Point.Y);
  if (P1 < 0) or (P1 > GameWidth) then
    Result := False;
  if (P2 < 0) or (P2 > GameHeight) then
    Result := False;
end;
{$ENDIF}

procedure StartVote(StarterVote, TypeVote: Byte; TargetVote, ReasonVote: string);
var
  I: Byte;
begin
  VoteActive := True;
  if (StarterVote < 1) or (StarterVote > MAX_PLAYERS) then
    VoteStarter := 'Server'
  else
  begin
    VoteStarter := Sprite[StarterVote].Player.Name;
    VoteCooldown[StarterVote] := DEFAULT_VOTE_TIME;
    {$IFNDEF SERVER}
    if StarterVote = MySprite then
      if VoteType = VOTE_KICK then
      begin
        MainConsole.Console(_('You have voted to kick') + ' ' +
          WideString(Sprite[KickMenuIndex].Player.Name) + ' ' + _('from the game'),
          VOTE_MESSAGE_COLOR);
        VoteActive := False;
        ClientVoteKick(StrToInt(TargetVote), True, '');
      end;
    {$ENDIF}
  end;
  VoteType := TypeVote;
  VoteTarget := TargetVote;
  VoteReason := ReasonVote;
  VoteTimeRemaining := DEFAULT_VOTING_TIME;
  VoteNumVotes := 0;
  VoteMaxVotes := 0;
  for I := 1 to MAX_PLAYERS do
    if Sprite[I].Active then
      if Sprite[I].Player.ControlMethod = HUMAN then
        VoteMaxVotes := VoteMaxVotes + 1;
end;

procedure StopVote;
var
  I: Byte;
begin
  VoteActive := False;
  VoteNumVotes := 0;
  VoteMaxVotes := 0;
  VoteType := 0;
  VoteTarget := '';
  VoteStarter := '';
  VoteReason := '';
  VoteTimeRemaining := -1;
  for I := 1 to MAX_PLAYERS do
    VoteHasVoted[I] := False;
end;

procedure TimerVote;
begin
  {$IFDEF SERVER}
  if VoteActive then
  begin
  {$ENDIF}
    if VoteTimeRemaining > -1 then
      VoteTimeRemaining := VoteTimeRemaining - 1;

    if VoteTimeRemaining = 0 then
    begin
      if VoteType = VOTE_MAP then
        MainConsole.console(
        {$IFDEF SERVER}
        'No map has been voted',
        {$ELSE}
        _('No map has been voted'),
        {$ENDIF}
        VOTE_MESSAGE_COLOR);
      StopVote;
    end;
  {$IFDEF SERVER}
  end;
  {$ENDIF}
end;
{$IFDEF SERVER}
procedure CountVote(Voter: Byte);
var
  I: Integer;
  Edge: Single;
  //Status: TMapInfo;
begin
  if VoteActive and not VoteHasVoted[Voter] then
  begin
    VoteNumVotes := VoteNumVotes + 1;
    VoteHasVoted[Voter] := True;
    Edge := VoteNumVotes / VoteMaxVotes;
    if (Edge >= (sv_votepercent.Value / 100)) then
    begin
      if VoteType = VOTE_KICK then
      begin
        I := StrToInt(VoteTarget);
        // There should be no permanent bans by votes. Reduced to 1 day.
        if CheatTag[I] = 0 then
          KickPlayer(I, True, KICK_VOTED, HOUR, 'Vote Kicked')
        else
          KickPlayer(I, True, KICK_VOTED, DAY, 'Vote Kicked by Server');
        DoBalanceBots(1, Sprite[I].Player.Team);
      end
      else
      if VoteType = VOTE_MAP then
      begin
        if not PrepareMapChange(VoteTarget) then
        begin
          MainConsole.Console('Map not found (' + VoteTarget + ')', WARNING_MESSAGE_COLOR);
          MainConsole.Console('No map has been voted', VOTE_MESSAGE_COLOR);
        end;
      end;
      StopVote;
      ServerSendVoteOff;
    end;
  end;
end;
{$ENDIF}

procedure ShowMapChangeScoreboard();
begin
  ShowMapChangeScoreboard('EXIT*!*');
end;

procedure ShowMapChangeScoreboard(const NextMap: string);
{$IFNDEF SERVER}
var
  i: Integer;
{$ENDIF}
begin
  MapChangeName := NextMap;
  MapChangeCounter := MapChangeTime;
  {$IFNDEF SERVER}
  GameMenuShow(LimboMenu, False);
  FragsMenuShow := True;
  StatsMenuShow := False;
  for i := 1 to MAX_PLAYERS do
  begin
    if Sprite[i].Active then
    begin
      StopSound(Sprite[i].ReloadSoundChannel);
      StopSound(Sprite[i].JetsSoundChannel);
      StopSound(Sprite[i].GattlingSoundChannel);
      StopSound(Sprite[i].GattlingSoundChannel2);
    end;
  end;
  {$ENDIF}
end;

function IsTeamGame(): Boolean;
begin
  case sv_gamemode.Value of
    GAMESTYLE_TEAMMATCH, GAMESTYLE_CTF, GAMESTYLE_INF, GAMESTYLE_HTF:
      Result := True;
    else
      Result := False;
  end;
end;

procedure ChangeMap;
var
  {$IFDEF SERVER}
  a: TVector2;
  {$ENDIF}
  i, j: Integer;
  SecWep: Integer;
  {$IFNDEF SERVER}
  MapChangeStatus: TMapInfo;
  {$ENDIF}
begin
  {$IFDEF SERVER}
  a := Default(TVector2);
  try
    Debug('ChangeMap');
    MapsList.Clear;

    if FileExists(UserDirectory + sv_maplist.Value) then
    begin
      MapsList.LoadFromFile(UserDirectory + sv_maplist.Value);
      i := 1;
      while i < MapsList.Count do
      begin
        if MapsList[i] = '' then
        begin
          MapsList.Delete(i);
          Dec(i);
        end;
        Inc(i);
      end;
    end;

    for i := 1 to MAX_WAYPOINTS do
    begin
      BotPath.WayPoint[i].Active := False;
      BotPath.WayPoint[i].id := 0;
      BotPath.WayPoint[i].PathNum := 0;
    end;

    if not Map.LoadMap(MapChange) then
    begin
      MainConsole.Console('Error: Could not load map (' + MapChange.Name + ')',
        DEBUG_MESSAGE_COLOR);
      NextMap;
      Exit;
    end;
  {$ENDIF}
  {$IFNDEF SERVER}
    MapChangeStatus := Default(TMapInfo);
    MapChanged := True;
    DemoRecorder.StopRecord;

    if GetMapInfo(MapChangeName, UserDirectory, MapChangeStatus) and VerifyMapChecksum(MapChangeStatus, TSHA1Digest(MapChangeChecksum)) then
    begin
      if not Map.LoadMap(MapChangeStatus, r_forcebg.Value, r_forcebg_color1.Value, r_forcebg_color2.Value) then
      begin
        RenderGameInfo(_('Could not load map: ') + WideString(MapChangeName));
        ExitToMenu;
        Exit;
      end;
      //Map.Name := MapChangeName;
    end
    else
    begin
      ExitToMenu;
      JoinServer();
      Exit;
    end;
  {$ENDIF}

    for i := 1 to MAX_BULLETS do
      Bullet[i].Kill;
    for i := 1 to MAX_THINGS do
      Thing[i].Kill;
    {$IFNDEF SERVER}
    for i := 1 to MAX_SPARKS do
      Spark[i].Kill;
    {$ENDIF}

    for i := 1 to MAX_SPRITES do
    begin
      if Sprite[i].Active and Sprite[i].IsNotSpectator() then
      begin
        RandomizeStart(SpriteParts.Pos[i], Sprite[i].Player.Team);
        Sprite[i].DeadMeat := False;
        Sprite[i].Respawn;
        Sprite[i].Player.Kills := 0;
        Sprite[i].Player.Deaths := 0;
        Sprite[i].Player.Flags := 0;
        Sprite[i].BonusTime := 0;
        Sprite[i].BonusStyle := BONUS_NONE;
        {$IFNDEF SERVER}
        Sprite[i].SelWeapon := 0;
        {$ENDIF}
        Sprite[i].FreeControls;
        Sprite[i].Weapon := Guns[NOWEAPON];

        SecWep := Sprite[i].Player.SecWep + 1;

        if (SecWep >= 1) and (SecWep <= SECONDARY_WEAPONS) and
           (WeaponActive[PRIMARY_WEAPONS + SecWep] = 1) then
          Sprite[i].SecondaryWeapon := Guns[PRIMARY_WEAPONS + SecWep]
        else
          Sprite[i].SecondaryWeapon := Guns[NOWEAPON];

        Sprite[i].RespawnCounter := 0;
      end;
    end;

    {$IFNDEF SERVER}
    for j := 1 to MAX_SPRITES do
      for i := 1 to PRIMARY_WEAPONS do
        WeaponSel[j][i] := 1;
    {$ENDIF}

    if sv_advancemode.Value then
    begin
      for j := 1 to MAX_SPRITES do
        for i := 1 to PRIMARY_WEAPONS do
          WeaponSel[j][i] := 0;

      {$IFNDEF SERVER}
      if MySprite > 0 then
        for i := 1 to MAIN_WEAPONS do
          LimboMenu.Button[i - 1].Active := Boolean(WeaponSel[MySprite][i]);
      {$ENDIF}
    end;

    for i := 1 to 4 do
      TeamScore[i] := 0;

    for i := 1 to 2 do
      TeamFlag[i] := 0;

    {$IFNDEF SERVER}
    FragsMenuShow := False;
    StatsMenuShow := False;

    if MySprite > 0 then
      GameMenuShow(LimboMenu);
    {$ENDIF}

    {$IFDEF SERVER}
    // add yellow flag
    if (sv_gamemode.Value = GAMESTYLE_POINTMATCH) or (sv_gamemode.Value = GAMESTYLE_HTF) then
    begin
      RandomizeStart(a, 14);
      TeamFlag[1] := CreateThing(a, 255, OBJECT_POINTMATCH_FLAG, 255);
    end;

    if (sv_gamemode.Value = GAMESTYLE_CTF) or (sv_gamemode.Value = GAMESTYLE_INF) then
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

    if not sv_survivalmode.Value then
    begin
      // spawn medikits
      SpawnThings(OBJECT_MEDICAL_KIT, Map.Medikits);

      // spawn grenadekits
      if sv_maxgrenades.Value > 0 then
        SpawnThings(OBJECT_GRENADE_KIT, Map.Grenades);
    end;

    // stat gun
    if sv_stationaryguns.Value then
      for i := 1 to MAX_SPAWNPOINTS do
        if Map.SpawnPoints[i].Active then
          if Map.SpawnPoints[i].Team = 16 then
          begin
            a.x := Map.SpawnPoints[i].X;
            a.y := Map.SpawnPoints[i].Y;
            CreateThing(a, 255, OBJECT_STATIONARY_GUN, 255);
          end;
    {$ENDIF}
    {$IFNDEF SERVER}
    HeartbeatTime := MainTickCounter;
    HeartbeatTimeWarnings := 0;

    if (MySprite > 0) and Sprite[MySprite].IsNotSpectator() then
      CameraFollowSprite := MySprite
    else
    begin
      // If in freecam or the previous followee is gone, then find a new followee
      if (CameraFollowSprite = 0) or not Sprite[CameraFollowSprite].Active then
      begin
        CameraFollowSprite := GetCameraTarget();
        // If no appropriate player found, then just center the camera
        if CameraFollowSprite = 0 then
        begin
          CameraX := 0;
          CameraY := 0;
        end;
      end;
    end;

    if not EscMenu.Active then
    begin
      mx := GameWidthHalf;
      my := GameHeightHalf;
      MousePrev.x := mx;
      MousePrev.y := my;
    end;

    // Spawn sound
    if MySprite > 0 then
      PlaySound(SFX_SPAWN, SpriteParts.Pos[MySprite]);

    {$ENDIF}
    // DEMO
    if demo_autorecord.Value then
    begin
      if DemoRecorder.Active then
        DemoRecorder.StopRecord;

      DemoRecorder.StartRecord(UserDirectory + 'demos/' +
        FormatDateTime('yyyy-mm-dd_hh-nn-ss_', Now()) + Map.Name + '.sdm');
    end;

    SortPlayers;

    MapChangeCounter := -60;

    TimeLimitCounter := sv_timelimit.Value;

  {$IFDEF SCRIPT}
    ScrptDispatcher.OnAfterMapChange(Map.Name);
  {$ENDIF}
  {$IFDEF SERVER}
    ServerSpriteSnapshotMajor(NETW);
  except
    on e: exception do
      WriteLn('Error changing map ' + e.message);
  end;
  {$ENDIF}
end;

procedure SortPlayers;
var
  i, j: Integer;
  temp: TKillSort;
begin
  PlayersNum := 0;
  BotsNum := 0;
  SpectatorsNum := 0;
  for i := 1 to 4 do
    PlayersTeamNum[i] := 0;

  for i := 1 to MAX_SPRITES do
  begin
    SortedPlayers[i].Kills := 0;
    SortedPlayers[i].Deaths := 0;
    SortedPlayers[i].Flags := 0;
    SortedPlayers[i].PlayerNum := 0;
  end;

  for i := 1 to MAX_SPRITES do
    if Sprite[i].Active and (not Sprite[i].Player.DemoPlayer) then
    begin
      Inc(PlayersNum);
      if Sprite[i].Player.ControlMethod = BOT then
        Inc(BotsNum);

      if Sprite[i].IsSpectator() then
        Inc(SpectatorsNum);

      if Sprite[i].IsNotSolo() and Sprite[i].IsNotSpectator() then
        Inc(PlayersTeamNum[Sprite[i].Player.Team]);

      if Sprite[i].IsNotSpectator() then
      begin
        SortedPlayers[PlayersNum].Kills := Sprite[i].Player.Kills;
        SortedPlayers[PlayersNum].Deaths := Sprite[i].Player.Deaths;
        SortedPlayers[PlayersNum].Flags := Sprite[i].Player.Flags;
        SortedPlayers[PlayersNum].PlayerNum := i;
      end else
      begin
        SortedPlayers[PlayersNum].Kills := 0;
        SortedPlayers[PlayersNum].Deaths := High(Integer);
        SortedPlayers[PlayersNum].Flags := 0;
        SortedPlayers[PlayersNum].PlayerNum := i;
      end;

      // Kill Limit
      if MapChangeCounter < 1 then
        if (not IsTeamGame) then
          if Sprite[i].Player.Kills >= sv_killlimit.Value then
          begin
            {$IFNDEF SERVER}
            CameraFollowSprite := i;
            if not EscMenu.Active then
            begin
              mx := GameWidthHalf;
              my := GameHeightHalf;
              MousePrev.x := mx;
              MousePrev.y := my;
            end;
            {$ELSE}
            NextMap;
            {$ENDIF}
          end;
    end;

  // sort by caps first if new score board
  if (PlayersNum > 0) then
    for i := 1 to PlayersNum do
      for j := i + 1 to PlayersNum do
        if SortedPlayers[j].Flags > SortedPlayers[i].Flags then
        begin
          temp := SortedPlayers[i];
          SortedPlayers[i] := SortedPlayers[j];
          SortedPlayers[j] := temp;
        end;

  // sort by kills
  if PlayersNum > 0 then
    for i := 1 to PlayersNum do
      for j := i + 1 to PlayersNum do
        if (SortedPlayers[j].Flags = SortedPlayers[i].Flags) then
          if SortedPlayers[j].Kills > SortedPlayers[i].Kills then
          begin
            temp := SortedPlayers[i];
            SortedPlayers[i] := SortedPlayers[j];
            SortedPlayers[j] := temp;
          end; // if

  // final sort by deaths
  if PlayersNum > 0 then
    for i := 1 to PlayersNum do
      for j := i + 1 to PlayersNum do
        if (SortedPlayers[j].Flags = SortedPlayers[i].Flags) then
          if SortedPlayers[j].Kills = SortedPlayers[i].Kills then
            if SortedPlayers[j].Deaths < SortedPlayers[i].Deaths then
            begin
              temp := SortedPlayers[i];
              SortedPlayers[i] := SortedPlayers[j];
              SortedPlayers[j] := temp;
            end;

  {$IFNDEF SERVER}
  // Sort Team Score
  for i := 1 to 4 do
  begin
    SortedTeamScore[i].Kills := TeamScore[i];
    SortedTeamScore[i].PlayerNum := i;
  end;

  SortedTeamScore[1].Color := (LongWord(ui_status_transparency.Value) shl 24) or $D20F05;  // ARGB
  SortedTeamScore[2].Color := (LongWord(ui_status_transparency.Value) shl 24) or $050FD2;
  SortedTeamScore[3].Color := (LongWord(ui_status_transparency.Value) shl 24) or $D2D205;
  SortedTeamScore[4].Color := (LongWord(ui_status_transparency.Value) shl 24) or $05D205;

  for i := 1 to 4 do
    for j := i + 1 to 4 do
      if SortedTeamScore[j].Kills > SortedTeamScore[i].Kills then
      begin
        temp := SortedTeamScore[i];
        SortedTeamScore[i] := SortedTeamScore[j];
        SortedTeamScore[j] := temp;
      end;
  {$ENDIF}

  {$IFDEF SERVER}
  // Team - Kill Limit
  if MapChangeCounter < 1 then
    for i := 1 to 4 do
      if TeamScore[i] >= sv_killlimit.Value then
      begin
        NextMap;
        Break;
      end;
  // Wave respawn time
  UpdateWaveRespawnTime;
  {$ENDIF}

  {$IFNDEF SERVER}
  TeamPlayersNum[0] := 0;
  TeamPlayersNum[1] := 0;
  TeamPlayersNum[2] := 0;
  TeamPlayersNum[3] := 0;
  TeamPlayersNum[4] := 0;
  {$ELSE}
  TeamAliveNum[1] := 0;
  TeamAliveNum[2] := 0;
  TeamAliveNum[3] := 0;
  TeamAliveNum[4] := 0;
  {$ENDIF}

  for i := 1 to MAX_SPRITES do
  begin
    if Sprite[i].Active then
    begin
      if Sprite[i].Player.Team in [TEAM_ALPHA..TEAM_DELTA] then
      {$IFDEF SERVER}
        Inc(TeamAliveNum[Sprite[i].Player.Team]);
      {$ELSE}
        Inc(TeamPlayersNum[Sprite[i].Player.Team]);
      {$ENDIF}
    end;
  end;
end;

end.
