unit InterfaceGraphics;

interface

uses
  Vector, Sprites, Constants;

var
  // Chat stuff
  ChatMessage: array[1..MAX_SPRITES] of WideString;
  ChatTeam: array[1..MAX_SPRITES] of Boolean;
  ChatDelay: array[1..MAX_SPRITES] of Integer;

  // Big Text
  BigText: array[0..MAX_BIG_MESSAGES] of WideString;
  BigDelay: array[0..MAX_BIG_MESSAGES] of Integer;
  BigX: array[0..MAX_BIG_MESSAGES] of Integer;
  BigScale: array[0..MAX_BIG_MESSAGES] of Single;
  BigColor: array[0..MAX_BIG_MESSAGES] of LongWord;
  BigPosX, BigPosY: array[0..MAX_BIG_MESSAGES] of Single;

  // World Text
  WorldText: array[0..MAX_BIG_MESSAGES] of WideString;
  WorldDelay: array[0..MAX_BIG_MESSAGES] of Integer;
  WorldX: array[0..MAX_BIG_MESSAGES] of Integer;
  WorldScale: array[0..MAX_BIG_MESSAGES] of Single;
  WorldColor: array[0..MAX_BIG_MESSAGES] of LongInt;
  WorldPosX, WorldPosY: array[0..MAX_BIG_MESSAGES] of Single;

  CursorText: string;
  CursorTextLength: Integer;
  CursorFriendly: Boolean;

  FragsMenuShow, StatsMenuShow, ConInfoShow, PlayerNamesShow, MiniMapShow, NoobShow: Boolean;

  FragsScrollMax: Byte = 0;
  FragsScrollLev: Byte = 0;
  _RScala: TVector2;
  _IScala: TVector2;
  fragx, fragy: Integer;

procedure LoadInterfaceArchives(Path: AnsiString; FirstOnly: Boolean = False);
function LoadInterfaceData(InterfaceName: string): Boolean;
procedure RenderInterface(TimeElapsed: Single; Width, Height: Single);
procedure RenderActionSnapText(t: Extended);
function IsDefaultInterface(const InterfaceName: string): Boolean;

implementation

uses
  Client, SysUtils, Types, TraceLog,
  Game, Math, Calc, Version, Util, PolyMap,
  Demo, Weapons, GameStrings, Net, GameMenus, Gfx, GameRendering, PhysFS,
  ClientGame, Console, MapGraphics, GameNetworkingSockets;

type
  TInterfaceRelInfo = record
    HealthBar_Rel_X, HealthBar_Rel_Y: Integer;
    JetBar_Rel_X, JetBar_Rel_Y: Integer;
    AmmoBar_Rel_X, AmmoBar_Rel_Y: Integer;
    FireBar_Rel_X, FireBar_Rel_Y: Integer;
    NadesBar_Rel_X, NadesBar_Rel_Y: Integer;
  end;

  TInterface = record
    Alpha: Byte;
    Health, Ammo, Vest, Jet, Nades, Bullets, Weapon, Fire, Team, Ping,
      Status: Boolean;
    HealthIco_X, HealthIco_Y: Integer;
    HealthIco_Rotate: Integer;
    HealthBar_X, HealthBar_Y: Integer;
    HealthBar_Width, HealthBar_Height: Integer;
    HealthBar_Pos: Byte;
    HealthBar_Rotate: Integer;
    AmmoIco_X, AmmoIco_Y: Integer;
    AmmoIco_Rotate: Integer;
    AmmoBar_X, AmmoBar_Y: Integer;
    AmmoBar_Width, AmmoBar_Height: Integer;
    AmmoBar_Pos: Byte;
    AmmoBar_Rotate: Integer;
    JetIco_X, JetIco_Y: Integer;
    JetIco_Rotate: Integer;
    JetBar_X, JetBar_Y: Integer;
    JetBar_Width, JetBar_Height: Integer;
    JetBar_Pos: Byte;
    JetBar_Rotate: Integer;
    VestBar_X, VestBar_Y: Integer;
    VestBar_Width, VestBar_Height: Integer;
    VestBar_Pos: Byte;
    VestBar_Rotate: Integer;
    Nades_X, Nades_Y: Integer;
    Nades_Width, Nades_Height: Integer;
    Nades_Pos: Byte;
    Bullets_X, Bullets_Y: Integer;
    Weapon_X, Weapon_Y: Integer;
    FireIco_X, FireIco_Y: Integer;
    FireIco_Rotate: Integer;
    FireBar_X, FireBar_Y: Integer;
    FireBar_Width, FireBar_Height: Integer;
    FireBar_Pos: Byte;
    FireBar_Rotate: Integer;
    TeamBox_X, TeamBox_Y: Integer;
    Ping_X, Ping_Y: Integer;
    Status_X, Status_Y: Integer;
  end;

  PInterface = ^TInterface;

var
  Int: TInterface;
  relinfo: TInterfaceRelInfo;
  PixelSize: TVector2;
  ChatInputTime: Extended;
  IntAlign: record  // 0: left; 1: right
    Weapon: Byte;
    Bullets: Byte;
    HealthBar: Byte;
    AmmoBar: Byte;
    ReloadBar: Byte;
    FireBar: Byte;
    JetBar: Byte;
    VestBar: Byte;
  end;

procedure LoadInterfaceArchives(Path: AnsiString; FirstOnly: Boolean = False);
var
 Sr: TSearchRec;
 Name: String;
begin
  if FindFirst(Path + '*.sint', faAnyFile - faDirectory, sr) = 0 then
  begin
    repeat
      Name := Sr.Name;
      Name := Name.SubString(0, Name.Length - 5);
      if PhysFS_mount(
            PChar(Path + Sr.Name),
            PChar('custom-interfaces/' + Name + '/'), False) then
        begin
          Debug('Mounted interface: ' + Sr.Name);
          if FirstOnly then
          begin
            ui_style.SetValue(Name);
            break;
          end;
        end
        else
          Debug('Failed to mount interface: ' + Sr.Name);
    until FindNext(Sr) <> 0;
    FindClose(Sr);
  end;
end;

function IsDefaultInterface(const InterfaceName: string): Boolean;
begin
  Result := (InterfaceName = '') or (InterfaceName = 'Default');
end;

procedure LoadDefaultInterfaceData;
begin
  // Create default INTERFACE
  IntAlign.Weapon    := 1;
  IntAlign.Bullets   := 1;
  IntAlign.HealthBar := 0;
  IntAlign.AmmoBar   := 0;
  IntAlign.ReloadBar := 0;
  IntAlign.FireBar   := 1;
  IntAlign.JetBar    := 0;
  IntAlign.VestBar   := 0;

  Int.Alpha := 255;
  Int.Health := True;
  Int.Ammo := True;
  Int.Vest := True;
  Int.Jet := True;
  Int.Nades := True;
  Int.Bullets := True;
  Int.Weapon := True;
  Int.Fire := True;
  Int.Team := True;
  Int.Ping := True;
  Int.Status := True;
  Int.HealthBar_Width := 115;
  Int.HealthBar_Height := 9;
  Int.HealthBar_Pos := HORIZONTAL;
  Int.HealthBar_Rotate := 0;
  Int.AmmoBar_Width := 120;
  Int.AmmoBar_Height := 9;
  Int.AmmoBar_Pos := HORIZONTAL;
  Int.AmmoBar_Rotate := 0;
  Int.JetBar_Width := 115;
  Int.JetBar_Height := 9;
  Int.JetBar_Pos := HORIZONTAL;
  Int.JetBar_Rotate := 0;
  Int.VestBar_Width := 115;
  Int.VestBar_Height := 9;
  Int.VestBar_Pos := HORIZONTAL;
  Int.VestBar_Rotate := 0;
  Int.FireBar_Width := 57;
  Int.FireBar_Height := 4;
  Int.FireBar_Pos := HORIZONTAL;
  Int.FireBar_Rotate := 0;
  Int.HealthIco_X := 5;
  Int.HealthIco_Y := 445 - 6;
  Int.HealthIco_Rotate := 0;
  Int.AmmoIco_X := 285 - 10;
  Int.AmmoIco_Y := 445 - 6;
  Int.AmmoIco_Rotate := 0;
  Int.JetIco_X := 480;
  Int.JetIco_Y := 445 - 6;
  Int.JetIco_Rotate := 0;
  Int.HealthBar_X := 45;
  Int.HealthBar_Y := 455 - 6;
  Int.AmmoBar_X := 352;
  Int.AmmoBar_Y := 455 - 6;
  Int.Bullets_X := 348;
  Int.Bullets_Y := 451;
  Int.JetBar_X := 520;
  Int.JetBar_Y := 455 - 6;
  Int.FireBar_X := 402;
  Int.FireBar_Y := 464;
  Int.FireBar_Rotate := 0;
  Int.FireIco_X := 409;
  Int.FireIco_Y := 464;
  Int.FireIco_Rotate := 0;
  Int.Nades_X := 305 - 7 + 10;
  Int.Nades_Y := 468 - 6;
  Int.Nades_Height := 10;
  Int.Nades_Width := 10;
  Int.Nades_Pos := HORIZONTAL;
  Int.VestBar_X := 45;
  Int.VestBar_Y := 465 - 6;
  Int.TeamBox_X := 575;
  Int.TeamBox_Y := 330;
  Int.Status_X := 575;
  Int.Status_Y := 421;
  Int.Ping_X := 600;
  Int.Ping_Y := 18;
  Int.Weapon_X := 285;
  Int.Weapon_Y := 454;

  relinfo.HealthBar_Rel_X := Int.HealthIco_X;
  relinfo.HealthBar_Rel_Y := Int.HealthIco_Y;
  relinfo.JetBar_Rel_X := Int.JetIco_X;
  relinfo.JetBar_Rel_Y := Int.JetIco_Y;
  relinfo.AmmoBar_Rel_X := Int.AmmoIco_X;
  relinfo.AmmoBar_Rel_Y := Int.AmmoIco_Y;
  relinfo.FireBar_Rel_X := Int.AmmoIco_X;
  relinfo.FireBar_Rel_Y := Int.AmmoIco_Y;
  relinfo.NadesBar_Rel_X := Int.AmmoIco_X;
  relinfo.NadesBar_Rel_Y := Int.AmmoIco_Y;
end;

// result is true if it loaded a custom interface
function LoadInterfaceData(InterfaceName: string): Boolean;
var
  AddrFile: PHYSFS_Buffer;
  AddrRec: TInterface;
const
  CUSTOM_INTERFACE_DIR = 'custom-intercases/';
begin
  Result := False;
  IntAlign.Weapon    := 0;
  IntAlign.Bullets   := 0;
  IntAlign.HealthBar := 1;
  IntAlign.AmmoBar   := 1;
  IntAlign.ReloadBar := 0;
  IntAlign.FireBar   := 1;
  IntAlign.JetBar    := 1;
  IntAlign.VestBar   := 1;

  // not registered / default interface
  if IsDefaultInterface(InterfaceName) then
  begin
    LoadDefaultInterfaceData;
    Exit;
  end;

  if not PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/setup.sif')) then
  begin
    ShowMessage(_('Could not find setup.sif. Loading default interface instead.'));
    LoadDefaultInterfaceData;
    Exit;
  end;

  Result := True;

  AddrFile := PHYSFS_readBuffer(PChar(ModDir + CUSTOM_INTERFACE_DIR +
    InterfaceName + '/setup.sif'));

  AddrRec := PInterface(@AddrFile[0])^;
  Int := AddrRec;

  if PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/health.bmp')) then
  begin
    relinfo.HealthBar_Rel_X := Int.HealthIco_X;
    relinfo.HealthBar_Rel_Y := Int.HealthIco_Y;
    relinfo.JetBar_Rel_X := Int.HealthIco_X;
    relinfo.JetBar_Rel_Y := Int.HealthIco_Y;
    relinfo.AmmoBar_Rel_X := Int.HealthIco_X;
    relinfo.AmmoBar_Rel_Y := Int.HealthIco_Y;
    relinfo.FireBar_Rel_X := Int.HealthIco_X;
    relinfo.FireBar_Rel_Y := Int.HealthIco_Y;
    relinfo.NadesBar_Rel_X := Int.HealthIco_X;
    relinfo.NadesBar_Rel_Y := Int.HealthIco_Y;
  end;

  if PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/jet.bmp')) then
  begin
    relinfo.HealthBar_Rel_X := Int.JetIco_X;
    relinfo.HealthBar_Rel_Y := Int.JetIco_Y;
    relinfo.JetBar_Rel_X := Int.JetIco_X;
    relinfo.JetBar_Rel_Y := Int.JetIco_Y;
    relinfo.AmmoBar_Rel_X := Int.JetIco_X;
    relinfo.AmmoBar_Rel_Y := Int.JetIco_Y;
    relinfo.FireBar_Rel_X := Int.JetIco_X;
    relinfo.FireBar_Rel_Y := Int.JetIco_Y;
    relinfo.NadesBar_Rel_X := Int.JetIco_X;
    relinfo.NadesBar_Rel_Y := Int.JetIco_Y;
  end;

  if PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/ammo.bmp')) then
  begin
    relinfo.HealthBar_Rel_X := Int.AmmoIco_X;
    relinfo.HealthBar_Rel_Y := Int.AmmoIco_Y;
    relinfo.JetBar_Rel_X := Int.AmmoIco_X;
    relinfo.JetBar_Rel_Y := Int.AmmoIco_Y;
    relinfo.AmmoBar_Rel_X := Int.AmmoIco_X;
    relinfo.AmmoBar_Rel_Y := Int.AmmoIco_Y;
    relinfo.FireBar_Rel_X := Int.AmmoIco_X;
    relinfo.FireBar_Rel_Y := Int.AmmoIco_Y;
    relinfo.NadesBar_Rel_X := Int.AmmoIco_X;
    relinfo.NadesBar_Rel_Y := Int.AmmoIco_Y;
  end;

  if PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/health.bmp')) then
  begin
    relinfo.HealthBar_Rel_X := Int.HealthIco_X;
    relinfo.HealthBar_Rel_Y := Int.HealthIco_Y;
  end;

  if PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/jet.bmp')) then
  begin
    relinfo.JetBar_Rel_X := Int.JetIco_X;
    relinfo.JetBar_Rel_Y := Int.JetIco_Y;
  end;

  if PHYSFS_exists(PChar(ModDir + CUSTOM_INTERFACE_DIR + InterfaceName +
    '/ammo.bmp')) then
  begin
    relinfo.AmmoBar_Rel_X := Int.AmmoIco_X;
    relinfo.AmmoBar_Rel_Y := Int.AmmoIco_Y;
  end;
end;

// Does the HUD overlay belong to the player?
function IsInteractiveInterface: Boolean;
begin
  Result := Sprite[MySprite].IsNotSpectator or
    ((CameraFollowSprite > 0) and (sv_advancedspectator.Value));
end;

function PixelAlignX(x: Single): Single;
begin
  Result := PixelSize.x * Floor(x / PixelSize.x);
end;

function PixelAlignY(y: Single): Single;
begin
  Result := PixelSize.y * Floor(y / PixelSize.y);
end;

procedure DrawLine(x, y, w: Single; Color: TGfxColor);
var
  x0, y0, x1, y1: Single;
begin
  x0 := PixelAlignX(x);
  y0 := PixelAlignY(y);
  x1 := PixelAlignX(x0 + w);
  y1 := y0 + PixelSize.y;

  GfxDrawQuad(nil,
    GfxVertex(x0, y0, 0, 0, Color),
    GfxVertex(x1, y0, 0, 0, Color),
    GfxVertex(x1, y1, 0, 0, Color),
    GfxVertex(x0, y1, 0, 0, Color)
  );
end;

function ToMinimap(const Pos: TVector2; Scale: Single = 1): TVector2;
begin
  Result := Default(TVector2);
  WorldToMinimap(Pos.x, Pos.y, Result.x, Result.y);

  Scale := Scale * Textures[GFX_INTERFACE_SMALLDOT].Scale;

  Result.x := PixelAlignX(ui_minimap_posx.Value * _rscala.x + Result.x -
    Scale * Textures[GFX_INTERFACE_SMALLDOT].Width / 2);

  Result.y := PixelAlignY(ui_minimap_posy.Value + Result.y -
    Scale * Textures[GFX_INTERFACE_SMALLDOT].Height / 2);
end;

procedure RenderBar(t: Integer; PosType: Byte; x, rx, y, ry, w, h, r: Integer;
  p: Single; LeftAlign: Boolean = True);
var
  px, py: Single;
  rc: TGfxRect;
begin
  if PosType = TEXTSTYLE then
    Exit;

  p := Max(0, Min(1, p));
  w := Textures[t].Width;
  h := Textures[t].Height;

  px := PixelAlignX(rx * _iscala.x) + (x - rx);
  py := PixelAlignY(ry * _iscala.y) + (y - ry);
  rc.Top := 0;
  rc.Bottom := h;

  if LeftAlign then
  begin
    rc.Left := 0;
    rc.Right := w * p;

    if PosType = VERTICAL then
    begin
      rc.Right := w;
      rc.Top := h * (1 - p);
      py := py + rc.Top * Textures[t].Scale;
    end;
  end
  else
  begin
    rc.Left := w * (1 - p);
    rc.Right := w;

    if PosType = VERTICAL then
    begin
      rc.Left := 0;
      rc.Bottom := h * p;
      py := py + (h * (1 - p)) * Textures[t].Scale;
    end;
  end;

  GfxDrawSprite(Textures[t], px, py, 0, 0, DegToRad(r), RGBA($FFFFFF, Int.Alpha), rc);
end;

type
  TAttr = record
    Cur: Single;
    Def: Single;
    Des: WideString;
  end;

procedure GetWeaponAttribs(i: Integer; var Attrs: array of TAttr);
var
  CurGun, DefGun: ^TGun;
begin
  CurGun := @Guns[i];
  DefGun := @DefaultGuns[i];

  Attrs[0].Cur := CurGun.HitMultiply *
   (CurGun.ModifierLegs + CurGun.ModifierChest + CurGun.ModifierHead)/3;
  Attrs[0].Def := DefGun.HitMultiply *
   (DefGun.ModifierLegs + DefGun.ModifierChest + DefGun.ModifierHead)/3;
  Attrs[0].Des := _('Damage');

  Attrs[1].Cur := CurGun.Ammo;
  Attrs[1].Def := DefGun.Ammo;
  Attrs[1].Des := _('Ammo');

  Attrs[2].Cur := CurGun.ReloadTime;
  Attrs[2].Def := DefGun.ReloadTime;
  Attrs[2].Des := _('Reload');

  Attrs[3].Cur := CurGun.Speed;
  Attrs[3].Def := DefGun.Speed;
  Attrs[3].Des := _('Speed');

  Attrs[4].Cur := CurGun.FireInterval;
  Attrs[4].Def := DefGun.FireInterval;
  Attrs[4].Des := _('Rate');

  Attrs[5].Cur := CurGun.MovementAcc;
  Attrs[5].Def := DefGun.MovementAcc;
  Attrs[5].Des := _('Acc.');

  Attrs[6].Cur := CurGun.Bink;
  Attrs[6].Def := DefGun.Bink;
  Attrs[6].Des := _('Bink');

  Attrs[7].Cur := CurGun.StartUpTime;
  Attrs[7].Def := DefGun.StartUpTime;
  Attrs[7].Des := _('Delay');

  Attrs[8].Cur := CurGun.BulletSpread;
  Attrs[8].Def := DefGun.BulletSpread;
  Attrs[8].Des := _('Spread');

  Attrs[9].Cur := CurGun.Recoil;
  Attrs[9].Def := DefGun.Recoil;
  Attrs[9].Des := _('Recoil');

  Attrs[10].Cur := CurGun.Push;
  Attrs[10].Def := DefGun.Push;
  Attrs[10].Des := _('Push');

  Attrs[11].Cur := CurGun.BulletStyle;
  Attrs[11].Def := DefGun.BulletStyle;
  Attrs[11].Des := _('Style');

  Attrs[12].Cur := CurGun.InheritedVelocity;
  Attrs[12].Def := DefGun.InheritedVelocity;
  Attrs[12].Des := _('Inh. Speed');
end;

function GetWeaponAttribDesc(var Attr: TAttr): WideString;
begin
  Result := '    |-' + Attr.Des + ' : ' +
    iif(Attr.Def <> 0, IntToStr(Round(Attr.Cur / Attr.Def * 100)) + '%', 'NEW') + ' (' +
    FormatFloat('0.####', Attr.Cur) + '/' +
    FormatFloat('0.####', Attr.Def) + ')';
end;

procedure RenderWeaponMenuText;
var
  i, CursorOnIndex: Integer;
  x, y, TipY: Single;
  Btn: ^TGameButton;
  Attrs: array[0..12] of TAttr;
  Str: WideString = '';
begin
  for i := Low(Attrs) to High(Attrs) do
    Attrs[i] := Default(TAttr);
  CursorOnIndex := 0;

  SetFontStyle(FONT_SMALL);
  GfxTextShadow(1, 1, RGBA(0));

  GfxTextColor(RGBA(234, 234, 234, 255));
  GfxDrawText(_('Primary Weapon:'), 65, 142);

  GfxTextVerticalAlign(GFX_BASELINE);
  GfxTextColor(RGBA(214, 214, 214, 255));
  GfxDrawText(_('Secondary Weapon:'), 65, 349);

  if LoadedWMChecksum <> DefaultWMChecksum then
  begin
    GfxTextColor(RGBA(204, 94, 94, 205));
    GfxDrawText(45 + 252 - RectWidth(GfxTextMetrics(_('Weapons Mod'))), 139);
  end;

  GfxTextVerticalAlign(GFX_TOP);

  for i := Low(LimboMenu.Button) to High(LimboMenu.Button) do
  begin
    Btn := @LimboMenu.Button[i];

    if Btn.Active then
    begin
      if Btn = HoveredButton then
        CursorOnIndex := i;

      x := Btn.x1 + 85;
      y := Btn.y1 + (Btn.y2 - Btn.y1) / 2 - 2;

      GfxTextColor(RGBA($FFFFFF, 230));

      if ((i + 1) = Sprite[MySprite].SelWeapon) or ((i + 1) = 11 + cl_player_secwep.Value) then
      begin
        if Btn = HoveredButton then
          GfxTextColor(RGBA(85, 105, 55, 230))
        else
          GfxTextColor(RGBA(55, 165, 55, 230));
      end
      else if Btn = HoveredButton then
      begin
        x := x + 1;
        y := y - 1;
      end;

      GfxDrawText(Btn.Caption, x, y);
    end;
  end;

  SetFontStyle(FONT_WEAPONS_MENU);

  if CursorOnIndex >= 0 then
  begin
    Btn := @LimboMenu.Button[CursorOnIndex];
    x := Btn.x1;
    TipY := Btn.y1 + (Btn.y2 - Btn.y1) / 2;

    Btn := @LimboMenu.Button[Min(9, CursorOnIndex)];
    y := Btn.y1 + (Btn.y2 - Btn.y1) / 2;

    if LoadedWMChecksum <> DefaultWMChecksum then
    begin
      TipY := y - 26;

      GetWeaponAttribs(CursorOnIndex + 1, Attrs);
      GfxTextColor(RGBA(215, 215, 155, 230));

      Str := LimboMenu.Button[CursorOnIndex].Caption + #10 + _('   Settings      : change% (present/default)') + #10;

      for i := Low(Attrs) to High(Attrs) do
      begin
        if Attrs[i].Cur <> Attrs[i].Def then
          Str := Str + GetWeaponAttribDesc(Attrs[i]);

        Str := Str + #10;
      end;

      GfxDrawText(Str, x + 245, y - 16);
    end;

    if cl_runs.Value < 4 then
    begin
      case CursorOnIndex + 1 of
        8:   Str := _('Hold fire to shoot, inaccurate while moving');
        12:  Str := _('Can be thrown by holding throw weapon button');
        14:  Str := _('Hold fire to shoot, while crouching or prone');
        else i := -1;
      end;

      if i <> -1 then
      begin
        GfxTextColor(RGBA(225, 195, 195, 250));
        GfxDrawText(Str, x + 245, TipY - 2);
      end;
    end;
  end;
end;

procedure RenderEscMenuText(w, h: Single);
var
  i: Integer;
  x, y, sx, sy, dx, dy: Single;
  Btn: ^TGameButton;
begin
  sx := EscMenu.w / BACKGROUND_WIDTH;
  sy := EscMenu.h / BACKGROUND_WIDTH;

  dx := (w / 2 - (EscMenu.w / 2)) - EscMenu.x;
  dy := (h / 2 - (EscMenu.h / 2)) - EscMenu.y;

  GfxDrawSprite(Textures[GFX_INTERFACE_BACK], EscMenu.x + dx, EscMenu.y + dy,
    sx, sy, RGBA($FFFFFF, ui_status_transparency.Value * 0.56));

  SetFontStyle(FONT_SMALL);
  GfxTextShadow(1, 1, RGBA(0));

  GfxTextColor(RGBA(250, 245, 255, 240));
  GfxDrawText(_('ESC - return to game'), EscMenu.x + dx + 20,
    EscMenu.y + EscMenu.h + dy - 45);

  GfxTextColor(RGBA(230, 235, 255, 190));
  GfxTextVerticalAlign(GFX_BOTTOM);
  GfxDrawText(EscMenu.x + EscMenu.w + dx - 2 -
    RectWidth(GfxTextMetrics('Soldat ' + SOLDAT_VERSION)),
    EscMenu.y + EscMenu.h + dy);
  GfxTextVerticalAlign(GFX_TOP);

  SetFontStyle(FONT_MENU);
  GfxTextColor(RGBA($FFFFFF, 250));
  for i := Low(EscMenu.Button) to High(EscMenu.Button) do
  begin
    Btn := @EscMenu.Button[i];

    if Btn.Active then
    begin
      x := Btn.x1 + dx + Ord(Btn = HoveredButton) + 10;
      y := Btn.y1 + dy - Ord(Btn = HoveredButton) + (Btn.y2 - Btn.y1) / 2 -
        RectHeight(GfxTextMetrics(Btn.Caption)) / 2;

      GfxDrawText(x, y);
    end;
  end;
end;

procedure RenderTeamMenuText;
var
  i: Integer;
  Alpha: Byte;
  x, y: Single;
  Btn: ^TGameButton;
  Colors: array[0..5,0..1] of TGfxColor;
begin
  if FragsMenuShow or StatsMenuShow then
    Alpha := 80
  else
    Alpha := 255;

  Colors[0][0] := RGBA(255, 255, 255, Alpha);  // DM, etc.
  Colors[0][1] := RGBA(255, 255, 255,   250);
  Colors[1][0] := RGBA(210,  15,   5, Alpha);  // Alpha
  Colors[1][1] := RGBA(210,  15,   5,   250);
  Colors[2][0] := RGBA(  5,  15, 205, Alpha);  // Bravo
  Colors[2][1] := RGBA(  5,  15, 205,   250);
  Colors[3][0] := RGBA(210, 210,   5, Alpha);  // Charlie
  Colors[3][1] := RGBA(210, 210,   5,   250);
  Colors[4][0] := RGBA(  5, 210,   5, Alpha);  // Delta
  Colors[4][1] := RGBA(  5, 210,   5,   250);
  Colors[5][0] := RGBA(210, 210, 105, Alpha);  // Spectator
  Colors[5][1] := RGBA(210, 210, 105,   250);

  SetFontStyle(FONT_MENU);
  GfxTextShadow(1, 1, RGBA(0));
  GfxTextColor(RGBA(234, 234, 234, Alpha));
  GfxDrawText(_('Select Team:'), 55, 165);

  for i := Low(TeamMenu.Button) to High(TeamMenu.Button) do
  begin
    Btn := @TeamMenu.Button[i];

    if Btn.Active then
    begin
      if i = 2 then
        GfxTextShadow(1, 1, RGBA($333333))
      else
        GfxTextShadow(1, 1, RGBA(0));

      GfxTextColor(Colors[i][Ord(Btn = HoveredButton)]);

      x := Btn.x1 + 10 + Ord(Btn = HoveredButton);
      y := Btn.y1 - Ord(Btn = HoveredButton) + (Btn.y2 - Btn.y1) / 2 -
        RectHeight(GfxTextMetrics(Btn.Caption)) / 2;

      GfxDrawText(x, y);

      x := 269 + Ord(Btn = HoveredButton);

      if (i > 0) and (i < 5) then
        GfxDrawText('(' + IntToStr(PlayersTeamNum[i]) + ')', x, y);
    end;
  end;
end;

procedure RenderKickWindowText;
var
  i: Integer;
  x, y: Single;
  Btn: ^TGameButton;
begin
  GfxDrawSprite(Textures[GFX_INTERFACE_BACK], KickMenu.x, KickMenu.y,
    KickMenu.w / BACKGROUND_WIDTH, KickMenu.h / BACKGROUND_WIDTH,
    RGBA($FFFFFF, ui_status_transparency.Value * 0.56));

  SetFontStyle(FONT_MENU);
  GfxTextShadow(1, 1, RGBA(0));

  if (KickMenuIndex > 0) and (KickMenuIndex < MAX_SPRITES + 1) then
  begin
    if Sprite[KickMenuIndex].Active then
    begin
      Btn := @KickMenu.Button[0];
      GfxTextColor(ARGB(Sprite[KickMenuIndex].Player.ShirtColor));
      GfxDrawText(Sprite[KickMenuIndex].Player.Name, Btn.x1, Btn.y1 - 15);
    end;
  end;

  GfxTextColor(RGBA($FFFFFF, 250));

  for i := Low(KickMenu.Button) to High(KickMenu.Button) do
  begin
    Btn := @KickMenu.Button[i];

    if Btn.Active then
    begin
      x := Btn.x1 + 10 + Ord(Btn = HoveredButton);
      y := Btn.y1 + (Btn.y2 - Btn.y1) / 2 - Ord(Btn = HoveredButton) -
        RectHeight(GfxTextMetrics(Btn.Caption)) / 2;

      GfxDrawText(x, y);
    end;
  end;
end;

procedure RenderMapWindowText;
var
  i: Integer;
  x, y: Single;
  Str: string;
  Btn: ^TGameButton;
begin
  GfxDrawSprite(Textures[GFX_INTERFACE_BACK], MapMenu.x, MapMenu.y,
    MapMenu.w / BACKGROUND_WIDTH, MapMenu.h / BACKGROUND_WIDTH,
    RGBA($FFFFFF, ui_status_transparency.Value * 0.56));

  Str := VoteMapName;

  SetFontStyle(FONT_MENU);
  GfxTextShadow(1, 1, RGBA(0));

  if (MapMenuIndex > -1) then
  begin
    Btn := @MapMenu.Button[0];
    GfxTextColor(RGBA(135, 235, 135, 230));
    GfxDrawText(Str, Btn.x1, Btn.y1 - 15);
  end;

  GfxTextColor(RGBA($FFFFFF, 250));

  for i := Low(MapMenu.Button) to High(MapMenu.Button) do
  begin
    Btn := @MapMenu.Button[i];

    if Btn.Active then
    begin
      x := Btn.x1 + 10 + Ord(Btn = HoveredButton);
      y := Btn.y1 + (Btn.y2 - Btn.y1) / 2 - Ord(Btn = HoveredButton) -
        RectHeight(GfxTextMetrics(Btn.Caption)) / 2;

      GfxDrawText(x, y);
    end;
  end;
end;

procedure RenderGameMenuTexts(w, h: Single);
begin
  if LimboMenu.Active then
    RenderWeaponMenuText;

  if EscMenu.Active then
    RenderEscMenuText(w, h);

  if TeamMenu.Active then
    RenderTeamMenuText;

  if KickMenu.Active then
    RenderKickWindowText;

  if MapMenu.Active then
    RenderMapWindowText;
end;

procedure RenderPlayerInterfaceTexts(PlayerIndex: Integer);
var
  Me: ^TSprite;
  i, Pos: Integer;
  x, y, t: Single;
  Str: WideString;
begin
  Me := @Sprite[PlayerIndex];

  if not Me.DeadMeat then
  begin
    SetFontStyle(FONT_MENU);
    GfxTextColor(RGBA($FFFFFF, Int.Alpha));

    // health
    if Int.Health and (Int.HealthBar_Pos = TEXTSTYLE) then
    begin
      x := RelInfo.HealthBar_Rel_X * _iscala.x +
        (Int.HealthBar_X - RelInfo.HealthBar_Rel_X);
      y := RelInfo.HealthBar_Rel_Y * _iscala.y +
        (Int.HealthBar_Y - RelInfo.HealthBar_Rel_Y);

      t := Me.Health / STARTHEALTH;
      GfxDrawText(IntToStr(Trunc(t * 100)) + '%', x, y);
    end;

    // weapon reload
    if Int.Ammo and (Int.AmmoBar_Pos = TEXTSTYLE) and
      (Me.Weapon.AmmoCount = 0) and
      (Me.Weapon.Num <> Guns[SPAS12].Num) then
    begin
      x := RelInfo.AmmoBar_Rel_X * _iscala.x +
        (Int.AmmoBar_X - RelInfo.AmmoBar_Rel_X);
      y := RelInfo.AmmoBar_Rel_Y * _iscala.y +
        (Int.AmmoBar_Y - RelInfo.AmmoBar_Rel_Y);

      t := Me.Weapon.ReloadTimeCount / Me.Weapon.ReloadTime;
      GfxDrawText(IntToStr(Trunc(100 - t * 100)) + '%', x, y);
    end;

    // jet
    if Int.Jet and (Int.JetBar_Pos = TEXTSTYLE) and (Map.StartJet > 0) then
    begin
      x := RelInfo.JetBar_Rel_X * _iscala.x +
        (Int.JetBar_X - RelInfo.JetBar_Rel_X);
      y := RelInfo.JetBar_Rel_Y * _iscala.y +
        (Int.JetBar_Y - RelInfo.JetBar_Rel_Y);

      t := Me.JetsCount / Map.StartJet;
      GfxDrawText(IntToStr(Trunc(t * 100)) + '%', x, y);
    end;

    // vest
    if Int.Vest and (Int.VestBar_Pos = TEXTSTYLE) and (Me.Vest > 0) then
    begin
      x := RelInfo.HealthBar_Rel_X * _iscala.x +
        (Int.VestBar_X - RelInfo.HealthBar_Rel_X);
      y := RelInfo.HealthBar_Rel_Y * _iscala.y +
        (Int.VestBar_Y - RelInfo.HealthBar_Rel_Y);

      t := Me.Vest / DEFAULTVEST;
      GfxDrawText(IntToStr(Trunc(t * 100)) + '%', x, y);
    end;

    // nades
    if Int.Nades and (Int.Nades_Pos = TEXTSTYLE) then
    begin
      x := RelInfo.NadesBar_Rel_X * _iscala.x +
        (Int.Nades_X - RelInfo.NadesBar_Rel_X);
      y := RelInfo.NadesBar_Rel_Y * _iscala.y +
        (Int.Nades_Y - RelInfo.NadesBar_Rel_Y);

      GfxDrawText(IntToStr(Me.TertiaryWeapon.AmmoCount), x, y);
    end;

    // bullets
    if Int.Bullets then
    begin
      x := RelInfo.AmmoBar_Rel_X * _iscala.x +
        (Int.Bullets_X - RelInfo.AmmoBar_Rel_X);
      y := RelInfo.AmmoBar_Rel_Y * _iscala.y +
        (Int.Bullets_Y - RelInfo.AmmoBar_Rel_Y);

      GfxTextColor(RGBA(242, 244, 40, Int.Alpha));

      if IntAlign.Bullets = 1 then
        GfxDrawText(x - RectWidth(GfxTextMetrics(WideString(IntToStr(Me.Weapon.AmmoCount)))), y)
      else
        GfxDrawText(IntToStr(Me.Weapon.AmmoCount), x, y);
    end;

    // weapon
    if Int.Weapon and
      IsExtendedWeaponIndex(WeaponNumToIndex(Me.Weapon.Num)) then
    begin
      x := RelInfo.AmmoBar_Rel_X * _iscala.x +
        (Int.Weapon_X - RelInfo.AmmoBar_Rel_X);
      y := RelInfo.AmmoBar_Rel_Y * _iscala.y +
        (Int.Weapon_Y - RelInfo.AmmoBar_Rel_Y);

      SetFontStyle(FONT_WEAPONS_MENU);
      GfxTextColor(RGBA(255, 245, 177, Int.Alpha));

      if IntAlign.Weapon = 1 then
        GfxDrawText(x - RectWidth(GfxTextMetrics(WideString(GunDisplayName[Me.Weapon.Num]))), y)
      else
        GfxDrawText(GunDisplayName[Me.Weapon.Num], x, y);
    end;
  end;  // not DeadMeat

  // kills
  if Int.Status then
  begin
    SetFontStyle(FONT_SMALL);

    x := Int.Status_X * _iscala.x;
    y := Int.Status_Y * _iscala.y;

    Pos := 0;

    for i := 1 to PlayersNum do
    begin
      if SortedPlayers[i].PlayerNum = PlayerIndex then
      begin
        Pos := i;
        Break;
      end;
    end;

    if (Pos > 0) and (Pos <= (PlayersNum - SpectatorsNum)) then
    begin
      Str := WideString(IntToStr(Pos)) + '/' + WideString(IntToStr(PlayersNum - SpectatorsNum));
      GfxTextColor(RGBA(88, 255, 90, Int.Alpha));
      GfxDrawText(Str, x, y);
    end;

    GfxTextColor(RGBA(255, 55, 50, Int.Alpha));

    if (Pos = 1) and ((PlayersNum - SpectatorsNum) > 1) then
    begin
      i := Me.Player.Kills - SortedPlayers[2].Kills;
      Str := WideString(iif(i > 0, '+', ''));
      Str := WideFormat('%d (%s%d)', [Me.Player.Kills, Str, i]);
      GfxDrawText(Str, x, y + 10);
    end
    else
    begin
      i := Me.Player.Kills - SortedPlayers[1].Kills;
      Str := WideString(IntToStr(Me.Player.Kills)) + ' (' + WideString(IntToStr(i)) + ')';
      GfxDrawText(Str, x, y + 10);
    end;

    GfxTextColor(RGBA(114, 120, 255, Int.Alpha));
    GfxDrawText(IntToStr(sv_killlimit.Value), x, y + 20);
  end;

  // bonus
  Str := '';

  case Me.BonusStyle of
    BONUS_FLAMEGOD:  Str := _('Flame God');
    BONUS_PREDATOR:  Str := _('Predator');
    BONUS_BERSERKER: Str := _('Berserker');
  end;

  if Str <> '' then
  begin
    Str := Str + ' - ' + WideString(FloatToStrF(Me.BonusTime / 60, ffFixed, 7, 1));

    SetFontStyle(FONT_MENU);
    GfxTextColor(RGBA(245, 40, 50));
    GfxDrawText(Str, 190 * _iscala.x, 435 * _iscala.y);
  end;
end;

procedure RenderTeamScoreTexts;
var
  i, TeamCount, Spacing: Integer;
  x, y: Single;
begin
  SetFontStyle(FONT_MENU);

  x := Int.TeamBox_X * _iscala.x + 2;
  y := Int.TeamBox_Y * _iscala.y + 25;

  TeamCount := 2;
  Spacing := 40;

  if sv_gamemode.Value = GAMESTYLE_TEAMMATCH then
  begin
    TeamCount := 4;
    Spacing := 24;
    y := y - 25;
  end;

  if (sv_gamemode.Value = GAMESTYLE_CTF) or (sv_gamemode.Value = GAMESTYLE_INF) or
    (sv_gamemode.Value = GAMESTYLE_HTF) or (sv_gamemode.Value = GAMESTYLE_TEAMMATCH) then
  begin
    for i := 1 to TeamCount do
    begin
      GfxTextColor(ARGB(SortedTeamScore[i].Color));
      GfxDrawText(IntToStr(SortedTeamScore[i].Kills), x, y + Spacing * (i - 1));
    end;
  end;
end;

procedure RenderEndGameTexts(FragMenuBottom: Single);
var
  i: Integer;
  y: Single;
begin
  i := SortedPlayers[1].PlayerNum;

  if IsTeamGame then
  begin
    GfxTextVerticalAlign(GFX_BOTTOM);

    y := FragMenuBottom + fragy - (FragsScrollLev * 20);

    if SortedTeamScore[1].Kills = SortedTeamScore[2].Kills then
    begin
      // tie
      GfxTextColor(RGBA(245, 245, 245));
      GfxDrawText(_('It''s a tie'), fragx + 137, y);
    end
    else
    begin
      // team wins
      i := SortedTeamScore[1].PlayerNum;

      case i of
        1: GfxTextColor(RGBA(210,  15,   5));
        2: GfxTextColor(RGBA(  5,  15, 205));
        3: GfxTextColor(RGBA(210, 210,   5));
        4: GfxTextColor(RGBA(  5, 210,   5));
      end;

      case i of
        1: GfxDrawText(_('Alpha team wins'), fragx + 50, y);
        2: GfxDrawText(_('Bravo team wins'), fragx + 50, y);
        3: GfxDrawText(_('Charlie team wins'), fragx + 50, y);
        4: GfxDrawText(_('Delta team wins'), fragx + 50, y);
      end;

    end;

    GfxTextVerticalAlign(GFX_TOP);
  end
  else if Sprite[i].Player.Kills > 0 then
  begin
    // player wins
    GfxTextColor(RGBA(185, 250, 138));
    GfxDrawText(WideFormat(_('%s wins'), [Sprite[i].Player.Name]),
      fragx + 107, fragy + 24);
  end;
end;

procedure RenderWeaponStatsTexts;
var
  i, j: Integer;
  Stat: ^TWeaponStat;
begin
  SetFontStyle(FONT_SMALL);
  GfxTextColor(RGBA(170, 160, 200, 230));
  GfxDrawText(_('% = Accuracy'), fragx + 465, fragy + 15);  // % = Accuracy
  GfxDrawText(_('HS = Headshots'), fragx + 465, fragy + 25);  // HS = Headshots

  SetFontStyle(FONT_MENU);
  GfxTextColor(RGBA(255, 255, 230));
  GfxDrawText(_('Weapon:'), fragx +  70, fragy + 40);  // Weapon:
  GfxDrawText(_(' %'), fragx + 240, fragy + 40);  // %
  GfxDrawText(_('Shots:'), fragx + 290, fragy + 40);  // Shots:
  GfxDrawText(_('Hits:'), fragx + 390, fragy + 40);  // Hits:
  GfxDrawText(_('Kills (HS):'), fragx + 470, fragy + 40);  // Kills (HS):

  SetFontStyle(FONT_SMALL);

  j := 0;
  GfxTextColor(RGBA($FFFFFF));

  for i := 0 to 20 do
  begin
    Stat := @WepStats[i];

    if Stat.Shots > 0 then
    begin
      Inc(j);

      GfxDrawText(Stat.Name, fragx +  90, fragy + j * 20 + 50);
      GfxDrawText(IntToStr(Round((Stat.Hits * 100) / Stat.Shots)) + '%',
        fragx + 245, fragy + j * 20 + 50);
      GfxDrawText(NumberFormat(Stat.Shots), fragx + 295, fragy + j * 20 + 50);
      GfxDrawText(NumberFormat(Stat.Hits), fragx + 395, fragy + j * 20 + 50);
      GfxDrawText(IntToStr(Stat.Kills) + ' (' + IntToStr(Stat.Headshots) + ')',
        fragx + 475, fragy + j * 20 + 50);
    end;
  end;

  GfxTextColor(RGBA(255, 255, 230, 100));
  GfxDrawText(_('(Updated every 10 seconds)'), fragx + 230, fragy + (j + 1) * 20 + 50);
end;

procedure RenderFragsMenuTexts(FragMenuBottom: Single);
var
  Color: TGfxColor;
  x, y, py: Single;
  i, j, k, z, NextItemStep: Integer;
  IDs: array[0..5] of Integer = (0, 0, 0, 0, 0, 0);
  TotalTeamKills: array[0..5] of Integer = (0, 0, 0, 0, 0, 0);
  Lines: array[0..5] of TVector2;
  Str: WideString;
begin
  for i := Low(Lines) to High(Lines) do
    Lines[i] := Default(TVector2);
  x := fragx;
  y := fragy - (FragsScrollLev * 20);
  Color := Default(TGfxColor);

  // team lines
  if IsTeamGame then
  begin
    NextItemStep := 0;
    k := 0;

    for j := 1 to 6 do
    begin
      // iteration order for i: 1,2,3,4,0,5
      // i=5 means spectators
      // i=0 means TEAM_NONE but goes after real teams

      i := iif(j < 6, j mod 5, 5);
      if (ui_hidespectators.Value) and (i = 5) then
        z := 0
      else if i = 5 then
        z := SpectatorsNum
      else
        z := TeamPlayersNum[i];

      if z > 0 then
      begin
        Lines[i].x := x + 35;
        Lines[i].y := y + 50 + NextItemStep + k * FRAGSMENU_PLAYER_HEIGHT;
        Inc(NextItemStep, 20);
        Inc(k, z);

        case i of
          0: Color := ARGB(ENTER_MESSAGE_COLOR);
          1: Color := RGBA(255, 0, 0);
          2: Color := RGBA(0, 0, 255);
          3: Color := ARGB(CHARLIEJ_MESSAGE_COLOR);
          4: Color := ARGB(DELTAJ_MESSAGE_COLOR);
          5: Color := RGBA(129, 52, 118);
        end;

        DrawLine(Lines[i].x, Lines[i].y + 15, 565, Color);
      end;
    end;
  end
  else
  begin
    Lines[0].y := y + 40 + FRAGSMENU_PLAYER_HEIGHT;
    Lines[5].y := y + 40 + (PlayersNum - SpectatorsNum + 1) *
      FRAGSMENU_PLAYER_HEIGHT;
  end;

  // columns
  if (sv_gamemode.Value = GAMESTYLE_DEATHMATCH) or (sv_gamemode.Value = GAMESTYLE_TEAMMATCH) then
    Str := _('Kills:')
  else
    Str := _('Points:');

  j := iif(Length(Str) > 7, 80, 0);

  SetFontStyle(FONT_MENU);
  GfxTextColor(RGBA(255, 255, 230));
  GfxDrawText(Str, x + 280 - j, y + 40);
  GfxDrawText(_('Deaths:'), x + 390, y + 40);
  GfxDrawText(_('Ping:'), x + 530, y + 40);

  // server name
  SetFontStyle(FONT_SMALL_BOLD);
  GfxTextColor(RGBA(233, 180, 12));
  GfxDrawText(sv_hostname.Value, x + 30, y + 15);

  // time left & computer time
  Str := WideFormat('%s %.2d:%.2d', [_('Time'), TimeLeftMin, TimeLeftSec]);
  SetFontStyle(FONT_SMALL);
  GfxTextColor(RGBA(170, 160, 200, 230));
  GfxDrawText(Str, x + 485, y + 15);
  GfxDrawText(FormatDateTime('h:nn:ss ampm', Time), x + 485, y + 30);

  // server info message
  GfxTextColor(RGBA(200, 150, 0));
  GfxDrawText(sv_info.Value, x + 30, y + 30);

  // demo name
  if DemoRecorder.Active then
  begin
    GfxTextColor(RGBA(0, 128, 0, Abs(Round(Sin(SinusCounter / 2) * 255))));
    GfxDrawText(DemoRecorder.Name, x + 280, y + FragMenuBottom - 10);
  end;

  // players count
  GfxTextColor(RGBA(200, 190, 180, 240));
  GfxDrawText(_('Players'), x + 330, y + 15);

  if IsTeamGame then
  begin
    j := iif(sv_gamemode.Value = GAMESTYLE_TEAMMATCH, 4, 2);

    for i := 1 to j do
    begin
      case i of
        1: GfxTextColor(RGBA(233,   0,   0, 240));
        2: GfxTextColor(RGBA(  0,   0, 233, 240));
        3: GfxTextColor(RGBA(233, 233,   0, 240));
        4: GfxTextColor(RGBA(  0, 233,   0, 240));
      end;

      GfxDrawText(IntToStr(TeamPlayersNum[i]),
        x + 440 + 20 * ((i - 1) div 2),
        y +  10 + 10 * ((i - 1) mod 2));
    end;
  end
  else
  begin
    GfxDrawText(IntToStr(PlayersNum), x + 450, y + 15);
  end;

  // players
  FillChar(IDs, sizeof(IDs), 0);
  FillChar(TotalTeamKills, sizeof(TotalTeamKills), 0);

  for j := 1 to PlayersNum do
  begin
    k := 0;
    i := SortedPlayers[j].PlayerNum;

    if i <= 0 then
      Continue;

    if ui_hidespectators.Value and Sprite[i].IsSpectator then
      Continue;

    if Sprite[i].IsSpectator then
      k := 5
    else if IsTeamGame then
      k := Sprite[i].Player.Team;

    if k = 5 then
      GfxTextColor(RGBA(220, 50, 200, 113))
    else
      GfxTextColor(RGBA(Sprite[i].Player.ShirtColor, 255));

    py := Lines[k].y + 20 + FRAGSMENU_PLAYER_HEIGHT * IDs[k];

    GfxDrawText(Sprite[i].Player.Name, x + 44, py);
    GfxDrawText(IntToStr(Sprite[i].Player.Kills), x + 284, py);
    GfxDrawText(IntToStr(Sprite[i].Player.Deaths), x + 394, py);

    if Sprite[i].Player.Flags > 0 then
      GfxDrawText('x' + IntToStr(Sprite[i].Player.Flags), x + 348, py);

    if (Sprite[i].Player.JetColor and $FF000000) <> COLOR_TRANSPARENCY_BOT then
      GfxDrawText(IntToStr(Sprite[i].Player.RealPing), x + 534, py);

    if (ChatText <> '') and (ChatText[1] = '/') then
    begin
      GfxTextColor(RGBA(245, 255, 230, 155));
      GfxDrawText(x + 20 - RectWidth(GfxTextMetrics(WideString(IntToStr(Sprite[i].Num)))), py);
    end;

    Inc(IDs[k]);
    Inc(TotalTeamKills[k], Sprite[i].Player.Kills);
  end;

  // team captions
  if IsTeamGame then
  begin
    for j := 1 to 6 do
    begin
      // see above ("team lines") to know what's up with this
      i := iif(j < 6, j mod 5, 5);
      if i = 5 then
        z := SpectatorsNum
      else
        z := TeamPlayersNum[i];

      if z > 0 then
      begin
        case i of
          0: GfxTextColor(ARGB(ENTER_MESSAGE_COLOR));
          1: GfxTextColor(RGBA(255, 0, 0));
          2: GfxTextColor(RGBA(0, 0, 255));
          3: GfxTextColor(ARGB(CHARLIEJ_MESSAGE_COLOR));
          4: GfxTextColor(ARGB(DELTAJ_MESSAGE_COLOR));
          5: GfxTextColor(RGBA(129, 52, 118));
        end;

        SetFontStyle(FONT_SMALL_BOLD);

        case i of
          0: GfxDrawText(_('Player'), Lines[i].x, Lines[i].y);
          1: GfxDrawText(_('Alpha'), Lines[i].x, Lines[i].y);
          2: GfxDrawText(_('Bravo'), Lines[i].x, Lines[i].y);
          3: GfxDrawText(_('Charlie'), Lines[i].x, Lines[i].y);
          4: GfxDrawText(_('Delta'), Lines[i].x, Lines[i].y);
          5: GfxDrawText(_('Spectator'), Lines[i].x, Lines[i].y);
        end;


        if j < 5 then
        begin
          case i of
            1: GfxTextColor(RGBA($D20F05, $DD));
            2: GfxTextColor(RGBA($151FD9, $DD));
            3: GfxTextColor(RGBA($D2D205, $DD));
            4: GfxTextColor(RGBA($05D205, $DD));
          end;

          SetFontStyle(FONT_SMALL);
          GfxDrawText(IntToStr(TotalTeamKills[i]), x + 284, Lines[i].y + 3);
        end;
      end;
    end;
  end;
end;

procedure RenderConsoleTexts(w: Single);
var
  i: Integer;
  L: Single;
  Alpha: Byte;
  Console: ^TConsole;
  Tiny: Boolean;
begin
  SetFontStyle(FONT_SMALL);

  if ChatText <> '' then
    Console := @BigConsole
  else
    Console := @MainConsole;

  L := font_consolelineheight.Value * PixelSize.y * FontStyleSize(FONT_SMALL);
  Alpha := 255;
  Tiny := False;

  if FragsMenuShow or StatsMenuShow or TeamMenu.Active or
    ((Console = @BigConsole) and LimboMenu.Active) or
    ((Console = @MainConsole) and EscMenu.Active and NoobShow) then
    Alpha := 60;

  for i := 1 to Console.Count do
  begin
    if Console.TextMessage[i] = '' then
      Continue;

    GfxTextColor(RGBA(Console.TextMessageColor[i], Alpha));

    if (RectWidth(GfxTextMetrics(Console.TextMessage[i])) > (w - 10)) <> Tiny then
    begin
      Tiny := not Tiny;

      if Tiny then
        SetFontStyle(FONT_SMALLEST)
      else
        SetFontStyle(FONT_SMALL);

      GfxDrawText(Console.TextMessage[i], 5, 1 + (i - 1) * L);
    end
    else
      GfxDrawText(5, 1 + (i - 1) * L);
  end;
end;

procedure RenderKillConsoleTexts(w: Single);
var
  i: Integer;
  Alpha: Byte;
  Tiny: Boolean;
  x, y, dy: Single;
begin
  Alpha := 245;
  Tiny := False;
  dy := 0;

  SetFontStyle(FONT_WEAPONS_MENU);

  if w < 1024 then
  begin
    if FragsMenuShow or StatsMenuShow then
      Alpha := 80;

    if Length(ChatText) > 0 then
      Alpha := 180;
  end;

  for i := 1 to KillConsole.Count do
  begin
    if KillConsole.TextMessage[i] = '' then
      Continue;

    if KillConsole.NumMessage[i] > -255 then
      dy := dy + KILLCONSOLE_SEPARATE_HEIGHT;

    if (Length(KillConsole.TextMessage[i]) > 14) <> Tiny then
    begin
      Tiny := not Tiny;

      if Tiny then
        SetFontStyle(FONT_SMALLEST)
      else
        SetFontStyle(FONT_WEAPONS_MENU);
    end;

    x := 595 * _iscala.x - RectWidth(GfxTextMetrics(KillConsole.TextMessage[i]));
    y := 60 + (i - 1) * (font_weaponmenusize.Value + 2) + dy;

    GfxTextColor(RGBA(KillConsole.TextMessageColor[i], Alpha));
    GfxDrawText(x, y);
  end;
end;

procedure RenderChatTexts;
var
  i: Integer;
  x, y, dx, dy: Single;
  Hide: Boolean;
  Str: WideString;
begin
  SetFontStyle(FONT_SMALL);
  GfxTextVerticalAlign(GFX_BOTTOM);

  for i := 1 to MAX_SPRITES do
  begin
    if (not Sprite[i].Typing) and (ChatDelay[i] <= 0) then
      Continue;

    Hide := (sv_realisticmode.Value) and (Sprite[i].Visible = 0) and
       Sprite[MySprite].IsNotInSameTeam(Sprite[i]) and
       Sprite[MySprite].IsNotSpectator;

    x  := (Sprite[i].Skeleton.Pos[12].x - CameraX + 0.5 * GameWidth) * _rscala.x;
    y  := (Sprite[i].Skeleton.Pos[12].y - CameraY + 0.5 * GameHeight) * _rscala.y;
    dy := -25 * _rscala.y;

    if Sprite[i].Typing and not Hide then
    begin
      dx := -RectWidth(GfxTextMetrics('...')) / 2;
      Str := WideString(Copy('...', 1, MainTickCounter div 30 mod 3 + 1));

      GfxTextColor(RGBA(ABOVECHAT_MESSAGE_COLOR));
      GfxDrawText(Str, x + dx, y + dy);

      dy := dy - 15 * _rscala.y;
    end;

    if (ChatDelay[i] > 0) and (Length(ChatMessage[i]) < MORECHATTEXT) and
      not (Hide and ChatTeam[i]) then
    begin
      dx := -RectWidth(GfxTextMetrics(ChatMessage[i])) / 2;

      GfxTextColor(RGBA(ABOVECHAT_MESSAGE_COLOR, Max(0, Min(255, 9 * ChatDelay[i]))));
      GfxDrawText(x + dx, y + dy);
    end;
  end;

  GfxTextVerticalAlign(GFX_TOP);
end;

procedure RenderChatInput(w, h: Single; t: Extended);
var
  Str: WideString = '';
  rc: TGfxRect;
  StrHalf: WideString;
  x, y: Single;
begin
  if ChatType = MSGTYPE_PUB then
    Str := 'Say:'
  else if ChatType = MSGTYPE_TEAM then
    Str := 'Team Say:'
  else if ChatType = MSGTYPE_CMD then
    Str := 'Cmd:';

  if Str <> '' then
  begin
    SetFontStyle(FONT_SMALL);

    if ChatType = MSGTYPE_PUB then
      GfxTextColor(RGBA(CHAT_MESSAGE_COLOR))
    else if ChatType = MSGTYPE_TEAM then
      GfxTextColor(RGBA(TEAMCHAT_MESSAGE_COLOR))
    else if ChatType = MSGTYPE_CMD then
      GfxTextColor(RGBA(ENTER_MESSAGE_COLOR));

    if ChatChanged then
    begin
      ChatInputTime := t;
      ChatChanged := False;
    end;

    t := t - ChatInputTime;

    Str := Str + iif(ChatText[Length(ChatText)] = ' ', ChatText + ' ', ChatText);
    rc := GfxTextMetrics(Str);

    if RectWidth(rc) >= (w - 80) then
      SetFontStyle(FONT_SMALLEST);

    GfxTextVerticalAlign(GFX_BASELINE);
    GfxDrawText(Str, 5, 420 * _iscala.y);
    StrHalf := Str;

    if CursorPosition < Length(ChatText) then
      SetLength(StrHalf, CursorPosition + 4 + Ord(ChatText[1] = '/'));

    x := RectWidth(GfxTextMetrics(StrHalf));

    if (t - Floor(t)) <= 0.5 then
    begin
      x := PixelAlignX(5 + x) + 2 * PixelSize.x;
      y := PixelAlignY(420 * _iscala.y - 1.2 * RectHeight(rc));
      w := PixelSize.x;
      h := PixelAlignY(1.2 * 1.2 * RectHeight(rc));

      GfxDrawQuad(nil,
        GfxVertex(x + 0, y + 0, 0, 0, RGBA(255, 230, 170)),
        GfxVertex(x + w, y + 0, 0, 0, RGBA(255, 230, 170)),
        GfxVertex(x + w, y + h, 0, 0, RGBA(255, 230, 170)),
        GfxVertex(x + 0, y + h, 0, 0, RGBA(255, 230, 170))
      );
    end;

    GfxTextVerticalAlign(GFX_TOP);
  end;
end;

{$IFDEF STEAM}
procedure RenderVoiceChatTexts;
var
  i: Byte;
  Color: TGfxColor;
  sx, sy: Single;
begin
  Color := RGBA($FFFFFF, ui_status_transparency.Value * 0.56);
  for i := 1 to MAX_SPRITES do
  begin
    if Sprite[i].Active then
    begin
      if Sprite[i].Player.LastReceiveVoiceTime > MainTickCounter then
      begin
        sx := 10;
        sy := 240 + fragy + (10 * i);

        case Sprite[i].Player.Team of
          0: Color := ARGB(ENTER_MESSAGE_COLOR);
          1: Color := RGBA(255, 0, 0);
          2: Color := RGBA(0, 0, 255);
          3: Color := ARGB(CHARLIEJ_MESSAGE_COLOR);
          4: Color := ARGB(DELTAJ_MESSAGE_COLOR);
          5: Color := RGBA(129, 52, 118);
        end;

        GfxDrawSprite(Textures[GFX_INTERFACE_MIC],
          PixelAlignX(sx), PixelAlignY(sy), RGBA(255,255,255));
        GfxTextColor(Color);
        GfxDrawText(Sprite[i].Player.Name, sx + 15, sy - 2);
      end;
    end;
  end;
end;
{$ENDIF}

procedure RenderRespawnAndSurvivalTexts;
var
  Me: ^TSprite;
  p: Single;
  Str: WideString = '';
begin
  Me := @Sprite[MySprite];

  if Me.IsNotSpectator then
  begin
    if Me.DeadMeat or SurvivalEndRound then
    begin
      GfxDrawSprite(Textures[GFX_INTERFACE_BACK], 180 * _iscala.x, _iscala.y,
        300 / BACKGROUND_WIDTH, 22 / BACKGROUND_WIDTH,
        RGBA($FFFFFF, ui_status_transparency.Value * 0.56));
    end;

    if (not sv_survivalmode.Value) and (Me.RespawnCounter > 0) then
    begin
      p := Me.RespawnCounter / 60;
      Str := WideFormat(_('Respawn in... %s'), [FloatToStrF(p, ffFixed, 7, 1)]);
      GfxTextColor(RGBA(255, 65, 55));
    end
    else if (sv_survivalmode.Value) and Me.DeadMeat and not SurvivalEndRound then
    begin
      GfxTextColor(RGBA(115, 255, 100));

      if (not IsTeamGame) then
        Str := WideString(IntToStr(AliveNum)) + ' ' + _('players left')
      else
        Str := WideString(IntToStr(TeamAliveNum[Me.Player.Team])) + ' ' + _('team players left');
    end
    else if SurvivalEndRound then
    begin
      if Me.DeadMeat then
      begin
        p := Me.RespawnCounter / 60;
        Str := _('End of round...') + WideString(FloatToStrF(p, ffFixed, 7, 1));
        GfxTextColor(RGBA(115, 255, 100));
      end
      else
      begin
        Str := _('You have survived');
        GfxTextColor(RGBA(155, 245, 100));
      end;
    end;

    SetFontStyle(FONT_MENU);
    GfxDrawText(Str, 200 * _iscala.x, 4 * _iscala.y);
  end
  else if SurvivalEndRound then
  begin
    SetFontStyle(FONT_MENU);
    GfxTextColor(RGBA(115, 255, 100));
    GfxDrawText(_('End of round...'), 240 * _iscala.x, 400 * _iscala.y);
  end;
end;

procedure RenderRadioMenuTexts;
const
  RADIO_GAMESTYLES = [GAMESTYLE_CTF, GAMESTYLE_INF, GAMESTYLE_HTF];
var
  s: string;
  Alpha: Byte;
  sx, sy: Single;
  Color: array[0..1] of TGfxColor;
begin
  if not (sv_gamemode.Value in RADIO_GAMESTYLES) then
    Exit;

  Color[0] := RGBA($FFFFFF, ui_status_transparency.Value * 0.56);
  sx := 180 / BACKGROUND_WIDTH;
  sy := 80 / BACKGROUND_WIDTH;

  GfxDrawSprite(Textures[GFX_INTERFACE_BACK], 5, 250, sx, sy, Color[0]);

  if RMenuState[0] <> ' ' then
    GfxDrawSprite(Textures[GFX_INTERFACE_BACK], 185, 250, sx, sy, Color[0]);

  Alpha := iif(FragsMenuShow or StatsMenuShow, 80, 230);

  SetFontStyle(FONT_MENU);
  GfxTextColor(RGBA($FFFFFF, Alpha));
  GfxDrawText('Radio:', 10, 252);

  SetFontStyle(FONT_SMALL);
  Color[0] := RGBA(200, 200, 200, Alpha);
  Color[1] := RGBA(210, 210, 5, Alpha);

  GfxTextColor(Color[Integer(RMenuState[0] = '1')]);
  GfxDrawText('1: ' + RadioMenu.Values['Menu1EFC'], 10, 270);
  GfxTextColor(Color[Integer(RMenuState[0] = '2')]);
  GfxDrawText('2: ' + RadioMenu.Values['Menu1FFC'], 10, 282);
  GfxTextColor(Color[Integer(RMenuState[0] = '3')]);
  GfxDrawText('3: ' + RadioMenu.Values['Menu1ES'], 10, 294);

  if RMenuState[0] <> ' ' then
  begin
    s := Choose(StrToInt(RMenuState[0]) - 1, ['EFC', 'FFC', 'ES']);
    GfxTextColor(Color[0]);
    GfxDrawText('1: ' + RadioMenu.Values['Menu2' + s + 'U'], 190, 270);
    GfxDrawText('2: ' + RadioMenu.Values['Menu2' + s + 'M'], 190, 282);
    GfxDrawText('3: ' + RadioMenu.Values['Menu2' + s + 'D'], 190, 294);
  end;
end;

procedure RenderVoteMenuTexts;
var
  i: Integer;
  x, y: Single;
  Str: array[0..1] of WideString;
begin
  if VoteActive then
  begin
    SetFontStyle(FONT_WEAPONS_MENU);

    x := 45 * _iscala.x;
    y := 400 * _iscala.y;
    if VoteType = VOTE_KICK then
      Str[0] := _('Kick')
    else
      Str[0] := _('Map');

    Str[1] := WideString(VoteTarget);

    if VoteType = VOTE_KICK then
    begin
      i := StrToInt(VoteTarget);

      if (i > 0) and (i <= MAX_SPRITES) then
        Str[1] := WideString(Sprite[i].Player.Name);
    end;

    GfxTextColor(RGBA(254, 104, 104, 225));
    GfxDrawText(Str[0], x + 30, y);

    GfxTextColor(RGBA(244, 244, 244, 225));
    GfxDrawText(Str[1], x + 65, y);

    GfxTextColor(RGBA(224, 218, 244, 205));
    GfxDrawText(_('Voter:') + ' ' + WideString(VoteStarter), x + 10, y + 11);
    GfxDrawText(_('Reason:') + WideString(VoteReason), x + 10, y + 20);

    GfxTextColor(RGBA(234, 234, 114, 205));
    GfxDrawText(_('F12 - Yes   F11 - No'), x + 50, y + 31);
  end;

  if VoteKickReasonType then
  begin
    SetFontStyle(FONT_SMALL);
    GfxTextColor(RGBA(254, 124, 124));
    GfxDrawText(_('Type reason for vote:'), 5, 390 * _iscala.y);
  end;
end;

procedure RenderPlayerName(Width, Height: Single; i: Integer; OnlyOffscreen: Boolean);
var
  Alpha: Byte;
  rc: TGfxRect;
  x, y, w, h, dx, dy: Single;
begin
  dy := iif(OnlyOffscreen, -10, 5) + 15;
  rc := GfxTextMetrics(WideString(Sprite[i].Player.Name));
  w  := RectWidth(rc);
  h  := RectHeight(rc);
  x  := (Sprite[i].Skeleton.Pos[7].x - CameraX + 0.5 * GameWidth) * _rscala.x;
  y  := (Sprite[i].Skeleton.Pos[7].y - CameraY + 0.5 * GameHeight + dy) * _rscala.y;

  if not OnlyOffscreen or (x < 0) or (x > Width) or (y < 0) or (y > Height) then
  begin
    x := Max(0, Min(Width - w, x - w / 2));
    y := Max(0, Min(Height - h, y - Integer(not OnlyOffscreen) * h / 2));

    dx := Abs(Sprite[MySprite].Skeleton.Pos[7].x - Sprite[i].Skeleton.Pos[7].x);
    dy := Abs(Sprite[MySprite].Skeleton.Pos[7].y - Sprite[i].Skeleton.Pos[7].y);

    Alpha := Min(255, 50 + Round(100000 / (dx + dy / 2)));

    if (Sprite[i].HoldedThing > 0) and (Thing[Sprite[i].HoldedThing].Style < 4) then
      GfxTextColor(RGBA(OUTOFSCREENFLAG_MESSAGE_COLOR, Alpha))
    else if Sprite[i].DeadMeat then
      GfxTextColor(RGBA(OUTOFSCREENDEAD_MESSAGE_COLOR, Alpha))
    else
      GfxTextColor(RGBA(OUTOFSCREEN_MESSAGE_COLOR, Alpha));

    GfxDrawText(x, y);
  end;
end;

procedure RenderPlayerNames(Width, Height: Single);
var
  i: Integer;
begin
  SetFontStyle(FONT_WEAPONS_MENU);

  if Sprite[MySprite].IsSpectator then
  begin
    if not DemoPlayer.Active then
    begin
      for i := 1 to MAX_SPRITES do
      begin
        if Sprite[i].Active and Sprite[i].IsInTeam and
          not ((sv_realisticmode.Value) and (Sprite[i].Visible = 0)) then
          RenderPlayerName(Width, Height, i, False);
      end;
    end;
  end
  else if Sprite[MySprite].IsInTeam then
  begin
    for i := 1 to MAX_SPRITES do
    begin
      if Sprite[i].Active and (i <> MySprite) and
        Sprite[i].IsInSameTeam(Sprite[MySprite]) then
        RenderPlayerName(Width, Height, i, True);
    end;
  end;
end;

procedure RenderCeaseFireCounter;
var
  x, y: Single;
begin
  x := Sprite[MySprite].Skeleton.Pos[9].x - 2;
  y := Sprite[MySprite].Skeleton.Pos[9].y - 15;
  x := (x - CameraX + 0.5 * GameWidth) * _rscala.x;
  y := (y - CameraY + 0.5 * GameHeight) * _rscala.y;

  SetFontStyle(FONT_SMALL);
  GfxTextColor(RGBA(GAME_MESSAGE_COLOR));
  GfxDrawText(IntToStr(Sprite[MySprite].CeaseFireCounter div 60 + 1), x, y);
end;

procedure RenderActionSnapText(t: Extended);
var
  Str: WideString;
begin
  Str := '[[ ' + _('Press F4 to Save Screen Cap') + ' ]]     [[ ' + _('Press F5 to Cancel') + ' ]]';

  SetFontStyle(FONT_SMALL);
  GfxTextColor(RGBA(230, 65, 60, 150 + Abs(Round(Sin(5.1 * t) * 100))));
  GfxDrawText(Str, 30 * _iscala.x, 412 * _iscala.y);
end;

procedure RenderInterface(TimeElapsed: Single; Width, Height: Single);
var
  T: ^TGfxSpriteArray;
  i, j, k, z, L, L2: Integer;
  SpectNumber: Integer = 0;
  p, _Scala: TVector2;
  Scale, MaxSize, Roto, dx, dy: Single;
  x: Single = 0;
  y: Single = 0;
  FragMenuBottom: Single = 0;
  Inaccuracy: Single;
  CursorSize: TVector2;
  CursorScale: Single;
  CursorScaledOffset: TVector2;
  CursorBinkScale: Single;
  CursorColor: Integer;
  Alfa: Integer;
  CharacterOffset: TVector2;
  IndicatorOffset: TVector2;
  DotColor: DWORD;
  f1, f2: Integer;
  IDs: array[0..5] of Integer;
  NextItemStep: Word;
  TeamPosStep: array[0..5] of Word = (0,0,0,0,0,0);
  Moveacc: Single;
  SpriteMe: ^TSprite;
  Color: TGfxColor;
  Weapon: ^TGun;
  Spr: PGfxSprite;
  WideScreenCut: Boolean;
  Str: WideString;
  NetworkStats: SteamNetworkingQuickConnectionStatus;
  SniperLine: Boolean;
begin
  SpriteMe := NIL;
  T := @Textures;

  PixelSize.x := Width / RenderWidth;
  PixelSize.y := Height / RenderHeight;

  GfxTextPixelRatio(PixelSize);

  {$IF DEFINED(TESTING) or DEFINED(RELEASE_CANDIDATE)}
  SetFontStyle(FONT_SMALL);
  GfxTextColor(RGBA(250, 245, 255, 150));
  GfxDrawText(SOLDAT_VERSION_LONG, 565 * _iscala.x, 465 * _iscala.y);
  {$IFEND}

  if MySprite > 0 then
    SpriteMe := @Sprite[MySprite];

  WideScreenCut := (sv_bullettime.Value) and (NoTexts = 0) and
    (GOALTICKS < DEFAULT_GOALTICKS) and (MapChangeCounter < 0);

  // Big messages
  if NoTexts = 0 then
  begin
    MaxSize := 0.8 * Npot(RenderHeight div 2);

    for i := 0 to MAX_BIG_MESSAGES do
    begin
      if BigDelay[i] > 0 then
      begin
        dy := 0;
        alfa := BigColor[i] shr 24;
        // somebody might have defined color as $RRGGBB not $AARRGGBB
        // effectively leaving AA component 0
        if alfa = 0 then
          alfa := 255;
        alfa := Max(Min(3 * BigDelay[i] + 25, alfa), 0);
        Scale := BigScale[i] * (RenderHeight / 480) * 4.8;

        if Scale * FontStyleSize(FONT_BIG) > MaxSize then
        begin
          y := Scale;
          Scale := MaxSize / FontStyleSize(FONT_BIG);
          GfxTextScale(y / Scale);
        end;

        if i = 1 then
        begin
          GfxTextVerticalAlign(GFX_BASELINE);

          if WideScreenCut then
            dy := -30 * _iscala.y;
        end;

        SetFontStyle(FONT_BIG, Scale);
        GfxTextColor(RGBA(BigColor[i], alfa));
        GfxTextShadow(1, 1, RGBA(0, Power(alfa / 255, 4) * alfa));
        GfxDrawText(BigText[i], BigPosX[i], BigPosY[i] + dy);
        GfxTextVerticalAlign(GFX_TOP);
        GfxTextScale(1);
      end;

      if WorldDelay[i] > 0 then
      begin
        alfa := WorldColor[i] shr 24;
        // somebody might have defined color as $RRGGBB not $AARRGGBB
        // effectively leaving AA component 0
        if alfa = 0 then
          alfa := 255;
        alfa := Max(Min(3 * WorldDelay[i] + 25, alfa), 0);
        x := WorldPosX[i] + (0.5 * GameWidth - CameraX) * _rscala.x;
        y := WorldPosY[i] + (0.5 * GameHeight - CameraY) * _rscala.y;

        Scale := WorldScale[i];

        if WorldScale[i] * FontStyleSize(FONT_WORLD) > MaxSize then
          Scale := MaxSize / FontStyleSize(FONT_WORLD);

        if Scale <> WorldScale[i] then
          GfxTextScale(WorldScale[i] / Scale);

        SetFontStyle(FONT_WORLD, Scale);
        GfxTextColor(RGBA(WorldColor[i], alfa));
        GfxTextShadow(1, 1, RGBA(0, Power(alfa / 255, 4) * alfa));
        GfxDrawText(WorldText[i], x, y);
        GfxTextScale(1);
      end;
    end;
  end;

  if (MySprite > 0) and (NoTexts = 0) then
  begin
    if Sprite[MySprite].IsSpectator and (CameraFollowSprite > 0) and
       (sv_advancedspectator.Value) then
    begin
      SpectNumber := MySprite;
      MySprite := CameraFollowSprite;
      SpriteMe := @Sprite[MySprite];
    end;

    // Bonus all colored
    if ui_bonuscolors.Value then
    begin
      Color.a := 0;

      case SpriteMe.BonusStyle of
        BONUS_FLAMEGOD:  Color := RGBA($FFFF00, 62);
        BONUS_PREDATOR:  Color := RGBA($FE00DC, 82);
        BONUS_BERSERKER: Color := RGBA($FE0000, 82);
      end;

      if Color.a > 0 then
      begin
        _Scala.x := T^[GFX_INTERFACE_OVERLAY].Scale;
        _Scala.y := T^[GFX_INTERFACE_OVERLAY].Scale;
        _Scala.x := Width / (T^[GFX_INTERFACE_OVERLAY].Width * _Scala.x);
        _Scala.y := Height / (T^[GFX_INTERFACE_OVERLAY].Height * _Scala.y);
        GfxDrawSprite(T^[GFX_INTERFACE_OVERLAY], 0, 0, _Scala.x, _Scala.y, Color);
      end;
    end;

    Color := RGBA($FFFFFF, Int.Alpha);
    Weapon := @SpriteMe.Weapon;

    if IsInteractiveInterface then
    begin
      if Int.Health then
      begin
        x := PixelAlignX(Int.HealthIco_X * _iscala.x);
        y := PixelAlignY(Int.HealthIco_Y * _iscala.y);

        GfxDrawSprite(T^[GFX_INTERFACE_HEALTH], x, y, 0, 0,
          DegToRad(Int.HealthIco_Rotate), Color);

        RenderBar(
          GFX_INTERFACE_HEALTH_BAR, Int.HealthBar_Pos,
          Int.HealthBar_X, RelInfo.HealthBar_Rel_X,
          Int.HealthBar_Y, RelInfo.HealthBar_Rel_Y,
          Int.HealthBar_Width, Int.HealthBar_Height,
          Int.HealthBar_Rotate, SpriteMe.Health / STARTHEALTH,
          IntAlign.HealthBar = 0
        );
      end;

      if Int.Vest and (SpriteMe.Vest > 0) then
      begin
        RenderBar(
          GFX_INTERFACE_VEST_BAR, Int.VestBar_Pos,
          Int.VestBar_X, RelInfo.HealthBar_Rel_X,
          Int.VestBar_Y, RelInfo.HealthBar_Rel_Y,
          Int.VestBar_Width, Int.VestBar_Height,
          Int.VestBar_Rotate, SpriteMe.Vest / DEFAULTVEST,
          IntAlign.VestBar = 0
        );
      end;

      if Int.Ammo then
      begin
        x := PixelAlignX(Int.AmmoIco_X * _iscala.x);
        y := PixelAlignY(Int.AmmoIco_Y * _iscala.y);

        GfxDrawSprite(T^[GFX_INTERFACE_AMMO], x, y, 0, 0,
          DegToRad(Int.AmmoIco_Rotate), Color);

        if (Weapon.AmmoCount = 0) and (Weapon.Num <> Guns[SPAS12].Num) then
        begin
          RenderBar(
            GFX_INTERFACE_RELOAD_BAR, Int.AmmoBar_Pos,
            Int.AmmoBar_X, RelInfo.AmmoBar_Rel_X,
            Int.AmmoBar_Y, RelInfo.AmmoBar_Rel_Y,
            Int.AmmoBar_Width, Int.AmmoBar_Height,
            Int.AmmoBar_Rotate, 1 - Weapon.ReloadTimeReal / Weapon.ReloadTime,
            IntAlign.ReloadBar = 0
          );
        end
        else if Weapon.AmmoCount > 0 then
        begin
          RenderBar(
            GFX_INTERFACE_RELOAD_BAR, Int.AmmoBar_Pos,
            Int.AmmoBar_X, RelInfo.AmmoBar_Rel_X,
            Int.AmmoBar_Y, RelInfo.AmmoBar_Rel_Y,
            Int.AmmoBar_Width, Int.AmmoBar_Height,
            Int.AmmoBar_Rotate, Weapon.AmmoCount / Weapon.Ammo,
            IntAlign.AmmoBar = 0
          );
        end;
      end;

      if Int.Fire then
      begin
        x := PixelAlignX(RelInfo.FireBar_Rel_X * _iscala.x +
          (Int.FireBar_X - RelInfo.FireBar_Rel_X));

        y := PixelAlignY(RelInfo.FireBar_Rel_Y * _iscala.y +
          (Int.FireBar_Y - RelInfo.FireBar_Rel_Y));

        GfxDrawSprite(T^[GFX_INTERFACE_FIRE_BAR_R], x, y, 0, 0,
          DegToRad(Int.FireBar_Rotate), Color);

        RenderBar(
          GFX_INTERFACE_FIRE_BAR, Int.FireBar_Pos,
          Int.FireIco_X, RelInfo.FireBar_Rel_X,
          Int.FireIco_Y, RelInfo.FireBar_Rel_Y,
          Int.FireBar_Width, Int.FireBar_Height,
          Int.FireIco_Rotate, Weapon.FireIntervalReal / Weapon.FireInterval,
          IntAlign.FireBar = 0
        );
      end;

      if Int.Jet then
      begin
        x := PixelAlignX(Int.JetIco_X * _iscala.x);
        y := PixelAlignY(Int.JetIco_Y * _iscala.y);

        GfxDrawSprite(T^[GFX_INTERFACE_JET], x, y, 0, 0,
          DegToRad(Int.JetIco_Rotate), Color);

        if Map.StartJet > 0 then
        begin
          RenderBar(
            GFX_INTERFACE_JET_BAR, Int.JetBar_Pos,
            Int.JetBar_X, RelInfo.JetBar_Rel_X,
            Int.JetBar_Y, RelInfo.JetBar_Rel_Y,
            Int.JetBar_Width, Int.JetBar_Height,
            Int.JetBar_Rotate, SpriteMe.JetsCountReal / Map.StartJet,
            IntAlign.JetBar = 0
          );
        end;
      end;

      if Int.Nades and (Int.Nades_Pos <> TEXTSTYLE) then
      begin
        i := 0;

        if SpriteMe.TertiaryWeapon.Num = Guns[FRAGGRENADE].Num then
          i := GFX_INTERFACE_NADE
        else if SpriteMe.TertiaryWeapon.Num = Guns[CLUSTERGRENADE].Num then
          i := GFX_INTERFACE_CLUSTER_NADE;

        if i <> 0 then
        begin
          dx := T^[i].Width * T^[i].Scale;
          dy := T^[i].Height * T^[i].Scale;

          for j := 1 to SpriteMe.TertiaryWeapon.AmmoCount do
          begin
            if Int.Nades_Pos = HORIZONTAL then
            begin
              x := PixelAlignX(RelInfo.NadesBar_Rel_X * _iscala.x +
                dx * j + (Int.Nades_X - RelInfo.NadesBar_Rel_X));
              y := PixelAlignY(RelInfo.NadesBar_Rel_Y * _iscala.y +
                (Int.Nades_Y - RelInfo.NadesBar_Rel_Y));
            end
            else if Int.Nades_Pos = VERTICAL then
            begin
              x := PixelAlignX(RelInfo.NadesBar_Rel_X * _iscala.x +
                (Int.Nades_X - RelInfo.NadesBar_Rel_X));
              y := PixelAlignY(RelInfo.NadesBar_Rel_Y * _iscala.y +
                (Int.Nades_Y - RelInfo.NadesBar_Rel_Y) -
                dy * j + dy * 6);
            end;

            GfxDrawSprite(T^[i], x, y, Color);
          end;
        end;
      end;
    end;

    // Aim cursor
    if not (LimboMenu.Active or TeamMenu.Active or EscMenu.Active) and not SpriteMe.DeadMeat
      and ((MapChangeCounter < 0) or (MapChangeCounter = 999999999))
      and not (DemoPlayer.Active and (not demo_showcrosshair.Value))
      and not ((SpectNumber > 0) and (SpectNumber <= 32) and (Sprite[SpectNumber].Player.DemoPlayer = False)) then
    begin
      SniperLine := ui_sniperline.Value and sv_sniperline.Value;

      // Set base scale for the crosshair
      if SniperLine then
        CursorScale := 0.5
      else
        CursorScale := 1;

      CursorSize.x := T^[GFX_INTERFACE_CURSOR].Width * T^[GFX_INTERFACE_CURSOR].Scale;
      CursorSize.y := T^[GFX_INTERFACE_CURSOR].Height * T^[GFX_INTERFACE_CURSOR].Scale;

      Moveacc := SpriteMe.GetMoveacc;
      Inaccuracy := HitSprayCounter + Moveacc * 100;

      // Embiggen the crosshair when binked
      if Inaccuracy > 0 then
      begin
        CursorBinkScale := Power(Inaccuracy, 0.6) / 20 * CursorScale;
        CursorScale := CursorScale + CursorBinkScale;
      end;

      // Scale crosshair from its center
      CursorScaledOffset.x := CursorSize.x / 2 * CursorScale / _rscala.x;
      CursorScaledOffset.y := CursorSize.y / 2 * CursorScale / _rscala.y;

      // Color and alpha for crosshair
      if CursorTextLength > 0 then
      begin
        Alfa := ui_status_transparency.Value - 50;

        if CursorFriendly then
          CursorColor := $33FF33
        else
          CursorColor := $FF3333;
      end
      else
      begin
        if SniperLine then
          Alfa := ui_status_transparency.Value div 2
        else
          Alfa := ui_status_transparency.Value;

        CursorColor := $FFFFFF;
      end;

      if SniperLine then
      begin
        CharacterOffset.x := GameWidthHalf - CameraX + SpriteMe.Skeleton.Pos[15].x;
        CharacterOffset.y := GameHeightHalf - CameraY + SpriteMe.Skeleton.Pos[15].y;

        Roto := Vec2Length(Vec2Subtract(Vector2(mx, my), CharacterOffset));

        if Roto < 1200 then
        begin
          x := PixelAlignX(CharacterOffset.x * _rscala.x);
          y := PixelAlignY(CharacterOffset.y * _rscala.y);

          GfxDrawSprite(T^[GFX_INTERFACE_SIGHT], x - 1, y - 1,
            (Roto / 240) * _rscala.x, (Roto / 480) * _rscala.y, 1, 1,
            -Angle2Points(Vector2(x, y), Vector2(mx * _rscala.x, my * _rscala.y)),
            RGBA($FFFFFF, Round((Roto / 240) * _rscala.x * 32)));
        end;
      end;

      if not DemoPlayer.Active then
      begin
        x := PixelAlignX((mx - CursorScaledOffset.x) * _rscala.x);
        y := PixelAlignY((my - CursorScaledOffset.y) * _rscala.y);
      end else
      begin
        x := PixelAlignX((GameWidthHalf  - camerax) * _rscala.x + SpriteMe.Control.MouseAimX);
        y := PixelAlignY((GameHeightHalf - cameray) * _rscala.y + SpriteMe.Control.MouseAimY);
      end;

      GfxDrawSprite(T^[GFX_INTERFACE_CURSOR], x, y, CursorScale,
        RGBA(CursorColor, Alfa));

      {$IFDEF DEBUGCURSORS}
      for i := 1 to 32 do
      begin
         // debug cursors
         if (Sprite[i].Active) and not (Sprite[i].DeadMeat) then
         begin
          x := (GameWidthHalf  - camerax) * _rscala.x + Sprite[i].Control.MouseAimX;
          y := (GameHeightHalf - cameray) * _rscala.y + Sprite[i].Control.MouseAimY;

          GfxDrawSprite(T^[GFX_INTERFACE_CURSOR], x, y, _rscala.x, _rscala.y,
            RGBA($00FF00FF, Alfa));
        end;
      end;
      {$ENDIF}
    end;

    // Player indicator
    if ui_playerindicator.Value and SpriteMe.IsNotSpectator then
    begin
      CharacterOffset.x := GameWidthHalf  - camerax + SpriteMe.Skeleton.Pos[12].x;
      CharacterOffset.y := GameHeightHalf - cameray + SpriteMe.Skeleton.Pos[12].y;

      x := T^[GFX_INTERFACE_ARROW].Width * T^[GFX_INTERFACE_ARROW].Scale;
      y := T^[GFX_INTERFACE_ARROW].Height * T^[GFX_INTERFACE_ARROW].Scale;

      IndicatorOffset.x := x / 2 / _rscala.x;
      IndicatorOffset.y := y / 2 / _rscala.y;

      x := CharacterOffset.x - IndicatorOffset.x;
      y := CharacterOffset.y - IndicatorOffset.y - 15;

      if (SpriteMe.Alpha < 255) and (not sv_survivalmode.Value) then
        Alfa := SpriteMe.CeaseFireCounter * 2 + 75
      else
      begin
        Alfa := 100;
        y := y + 2 * Sin(5.1 * TimeElapsed);
      end;

      x := x * _rscala.x;
      y := y * _rscala.y;

      GfxDrawSprite(T^[GFX_INTERFACE_ARROW], x, y, RGBA($FFFFFF, Alfa));
    end;

    if (SpectNumber > 0) and (SpectNumber <= 32) and Sprite[SpectNumber].IsSpectator and
          (sv_advancedspectator.Value) then
    begin
      MySprite := SpectNumber;
      SpriteMe := @Sprite[MySprite];
    end;

    // Ping dot
    if Int.Ping and PlayerNamesShow then
    begin
      x := Int.Ping_X * _iscala.x;
      y := Int.Ping_Y * _iscala.y;
      _Scala.X := 0.5 + SpriteMe.Player.RealPing / 600;
      _Scala.Y := 0.45 + SpriteMe.Player.RealPing / 600;

      if SpriteMe.Player.RealPing <= 50 then
        DotColor := $00FF00
      else if SpriteMe.Player.RealPing <= 100 then
        DotColor := $22FF00
      else if SpriteMe.Player.RealPing <= 150 then
        DotColor := $54C700
      else if SpriteMe.Player.RealPing <= 200 then
        DotColor := $76A700
      else if SpriteMe.Player.RealPing <= 250 then
        DotColor := $938800
      else if SpriteMe.Player.RealPing <= 300 then
        DotColor := $A17700
      else if SpriteMe.Player.RealPing <= 350 then
        DotColor := $CC4800
      else
        DotColor := $FF0000;

      if SpriteMe.Player.RealPing > 255 then
        Alfa := 255
      else
        Alfa := SpriteMe.Player.RealPing;

      GfxDrawSprite(T^[GFX_INTERFACE_DOT], x, y, _Scala.x, _Scala.y,
        RGBA(DotColor, Alfa));
    end;
  end;  // (MySprite > 0) and (NoTexts = 0)

  // Kill console weapons
  if ui_killconsole.Value then
  begin
    if NoTexts = 0 then
    begin
      Alfa := 255;
      if RenderWidth < 1024 then
      begin
        if FragsMenuShow or StatsMenuShow then
          Alfa := 50;
        if Length(ChatText) > 0 then
          Alfa := 150;
      end;

      L2 := 0;
      for J := 1 to KillConsole.Count do
      begin
        if KillConsole.TextMessage[j] > '' then
        begin
          if KillConsole.NumMessage[j] > -255 then
          begin
            x := 605;
            y := (j - 1) * (font_weaponmenusize.Value + 2) + 59;

            L2 := L2 + KILLCONSOLE_SEPARATE_HEIGHT;

            x := x * _iscala.x;
            y := y + L2;
            _Scala.x := 0.8;
            _scala.y := 0.8;

            GfxDrawSprite(T^[KillConsole.NumMessage[j]], x, y,
              _Scala.x, _Scala.y, RGBA($FFFFFF, Alfa));
          end;
        end;
      end;
    end;
  end;

  // Minimap

  if MiniMapShow then
    RenderMinimap(PixelAlignX(ui_minimap_posx.Value * _rscala.x),
      PixelAlignY(ui_minimap_posy.Value), Round(ui_status_transparency.Value * 0.85));

  if MiniMapShow and (not sv_minimap.Value) then
  begin
    Alfa := ui_minimap_transparency.Value;

    f1 := TeamFlag[1];
    f2 := TeamFlag[2];

    if (f1 > 0) and (f2 > 0) and ((sv_gamemode.Value = GAMESTYLE_CTF) or
      (sv_gamemode.Value = GAMESTYLE_INF)) then
    begin
      if (Thing[f1].InBase) and (Thing[f1].HoldingSprite = 0) then
      begin
        p := ToMinimap(Thing[f1].Skeleton.Pos[1]);
        GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, RGBA($FF0000, Alfa));
      end;

      if (Thing[f2].InBase) and (Thing[f2].HoldingSprite = 0) then
      begin
        p := ToMinimap(Thing[f2].Skeleton.Pos[1]);
        GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, RGBA($1313FF, Alfa));
      end;
    end;

    if (f1 > 0) and (sv_gamemode.Value = GAMESTYLE_HTF) and (Thing[f1].HoldingSprite = 0) then
    begin
      p := ToMinimap(Thing[f1].Skeleton.Pos[1]);
      GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, RGBA($FFFF00, Alfa));
    end;

    if (GameThingTarget > 0) and (sv_gamemode.Value = GAMESTYLE_RAMBO) and
      (Thing[GameThingTarget].HoldingSprite = 0) then
    begin
      p := ToMinimap(Thing[GameThingTarget].Skeleton.Pos[1]);
      GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, RGBA($FFFFFF, Alfa));
    end;

    if MySprite > 0 then
    begin
      for j := 1 to MAX_SPRITES do
      begin
        if (not Sprite[j].Active) or Sprite[j].IsSpectator or
          (SpriteMe.IsNotSpectator and not SpriteMe.IsInSameTeam(Sprite[j])) then
          Continue;

        if (Sprite[j].HoldedThing > 0) and (Thing[Sprite[j].HoldedThing].Style < 4) then
        begin
          p := ToMinimap(Sprite[j].Skeleton.Pos[7]);
          GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, RGBA($FFFF00, Alfa));
        end
        else if ((j = CameraFollowSprite) and SpriteMe.IsSpectator) or
          (j = MySprite) then
        begin
          p := ToMinimap(Sprite[j].Skeleton.Pos[7], 0.8);
          GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, 0.8,
            RGBA($FFFFFF, Alfa));
        end
        else if not Sprite[j].IsSolo and (j <> MySprite) then
        begin
          Color := RGBA(0);
          p := ToMinimap(Sprite[j].Skeleton.Pos[7], 0.65);

          if not Sprite[j].DeadMeat then
          begin
            case Sprite[j].Player.Team of
              TEAM_ALPHA:   Color := RGBA($FF0000, Alfa);
              TEAM_BRAVO:   Color := RGBA($1313FF, Alfa);
              TEAM_CHARLIE: Color := RGBA($FFFF00, Alfa);
              TEAM_DELTA:   Color := RGBA($00FF00, Alfa);
            end;
          end;

          GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, 0.65, Color);

          // Chat indicator
          if ChatDelay[j] > 0 then
          begin
            p.x := Sprite[j].Skeleton.Pos[7].x;
            p.y := Sprite[j].Skeleton.Pos[7].y - 40;
            p := ToMinimap(p, 0.5);
            GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], p.x, p.y, 0.5,
              RGBA($FFFFFF, Alfa));
          end;
        end;
      end;
    end;
  end;

  // Background for self Weapon Stats
  if StatsMenuShow and not FragsMenuShow then
  begin
    _Scala.X := 590 / BACKGROUND_WIDTH;
    _Scala.Y := ((WepStatsNum * 20) + 85) / BACKGROUND_WIDTH;
    x := 25 + fragx;
    y := 5 + fragy;

    GfxDrawSprite(T^[GFX_INTERFACE_BACK], x, y, _Scala.x, _Scala.y,
      RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.56)));

    z := 0;

    for j := 0 to ORIGINAL_WEAPONS do
    begin
      if (WepStats[j].Shots > 0) then
      begin
        // Draw the weapons image
        Inc(z);
        x := 30 + fragx;
        y := ((z * 20) + 50) + fragy;

        GfxDrawSprite(T^[WepStats[j].TextureID], x, y);
      end;
    end;


    WepStatsNum := z;
  end;

  // Background For Frags Stats
  if FragsMenuShow then
  begin
    if NoTexts = 0 then
    begin
      x := 25 + fragx;
      y := 5 + fragy;
      i := 0;

      if TeamPlayersNum[1] > 0 then
        i := i + 15;
      if TeamPlayersNum[2] > 0 then
        i := i + 15;
      if TeamPlayersNum[3] > 0 then
        i := i + 15;
      if TeamPlayersNum[4] > 0 then
        i := i + 15;
      if TeamPlayersNum[0] > 0 then
        i := i + 15;
      if SpectatorsNum > 0 then
        i := i + 15;

      if ui_hidespectators.Value then
        FragMenuBottom := 70 + ((PlayersNum - SpectatorsNum + 1) * FRAGSMENU_PLAYER_HEIGHT) + i
      else
        FragMenuBottom := 70 + ((PlayersNum + 1) * FRAGSMENU_PLAYER_HEIGHT) + i;

      _Scala.X := 590 / BACKGROUND_WIDTH;
      _Scala.Y := FragMenuBottom / BACKGROUND_WIDTH;
      y := y - (FragsScrollLev * 20);

      GfxDrawSprite(T^[GFX_INTERFACE_BACK], x, y, _Scala.x, _Scala.y,
        RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.56)));

      if (_Scala.y * BACKGROUND_WIDTH) > Height - 80 then
        FragsScrollMax := Round((_Scala.y * BACKGROUND_WIDTH - Height +
          80) / 20)
      else
        FragsScrollMax := 0;

      if FragsScrollMax <> 0 then
      begin
        x := 580 + fragx;
        y := Height / 2;
        GfxDrawSprite(T^[GFX_INTERFACE_SCROLL], x, y,
          RGBA($FFFFFF, Abs(Round(Sin(5.1 * TimeElapsed) * 255))));
      end;

      NextItemStep := 0;
      IDs[0] := 0;
      IDs[1] := 0;
      IDs[2] := 0;
      IDs[3] := 0;
      IDs[4] := 0;
      IDs[5] := 0;

      if TeamPlayersNum[1] > 0 then
      begin
        TeamPosStep[1] := NextItemStep;
        NextItemStep := NextItemStep + 20;
      end;
      if TeamPlayersNum[2] > 0 then
      begin
        TeamPosStep[2] := NextItemStep;
        NextItemStep := NextItemStep + 20;
      end;
      if TeamPlayersNum[3] > 0 then
      begin
        TeamPosStep[3] := NextItemStep;
        NextItemStep := NextItemStep + 20;
      end;
      if TeamPlayersNum[4] > 0 then
      begin
        TeamPosStep[4] := NextItemStep;
        NextItemStep := NextItemStep + 20;
      end;
      if TeamPlayersNum[0] > 0 then
      begin
        TeamPosStep[0] := NextItemStep;
        NextItemStep := NextItemStep + 20;
      end;
      if SpectatorsNum > 0 then
      begin
        TeamPosStep[5] := NextItemStep;
      end;

      for j := 1 to PlayersNum do
      begin
        if SortedPlayers[j].PlayerNum > 0 then
        begin
          if not Sprite[SortedPlayers[j].PlayerNum].Player.DemoPlayer then
          begin
            x := 32 + fragx;
            y := 61 + j * FRAGSMENU_PLAYER_HEIGHT + fragy;

            if ui_hidespectators.Value and Sprite[SortedPlayers[j].PlayerNum].IsSpectator then
              Continue;

            if IsTeamGame then
            begin
              // New team based score board
              if Sprite[SortedPlayers[j].PlayerNum].Player.Team = TEAM_ALPHA then
              begin
                y := 70 + (IDs[1] * 15) + TeamPosStep[1] + fragy;
                IDs[1] := IDs[1] + 1;
              end
              else if Sprite[SortedPlayers[j].PlayerNum].Player.Team = TEAM_BRAVO then
              begin
                y := 70 + TeamPlayersNum[1] * FRAGSMENU_PLAYER_HEIGHT +
                  TeamPosStep[2] + fragy + (IDs[2] * 15);
                IDs[2] := IDs[2] + 1;
              end
              // if sv_gamemode.IntValue = GAMESTYLE_TEAMMATCH then
              // begin
              else if Sprite[SortedPlayers[j].PlayerNum].Player.Team = TEAM_CHARLIE then
              begin
                y := 70 + (TeamPlayersNum[1] + TeamPlayersNum[2]) *
                  FRAGSMENU_PLAYER_HEIGHT + TeamPosStep[3] + fragy +
                  (IDs[3] * 15);
                IDs[3] := IDs[3] + 1;
              end
              else if Sprite[SortedPlayers[j].PlayerNum].Player.Team = TEAM_DELTA then
              begin
                y := 70 + (TeamPlayersNum[1] + TeamPlayersNum[2] +
                  TeamPlayersNum[3]) * FRAGSMENU_PLAYER_HEIGHT +
                  TeamPosStep[4] + fragy + (IDs[4] * 15);
                IDs[4] := IDs[4] + 1;
              end
              // end;
              else if Sprite[SortedPlayers[j].PlayerNum].Player.Team = TEAM_NONE then
              begin
                y := 70 + (TeamPlayersNum[1] + TeamPlayersNum[2] +
                  TeamPlayersNum[3] + TeamPlayersNum[4]) *
                  FRAGSMENU_PLAYER_HEIGHT + TeamPosStep[0] + fragy +
                  (IDs[0] * 15);
                IDs[0] := IDs[0] + 1;
              end
              else if Sprite[SortedPlayers[j].PlayerNum].Player.Team = TEAM_SPECTATOR then
              begin
                y := 70 + (TeamPlayersNum[1] + TeamPlayersNum[2] +
                  TeamPlayersNum[3] + TeamPlayersNum[4] + TeamPlayersNum[0]) *
                  FRAGSMENU_PLAYER_HEIGHT + TeamPosStep[5] + fragy +
                  (IDs[5] * 15);
                IDs[5] := IDs[5] + 1;
              end;
            end;
            y := y - (FragsScrollLev * 20);

            if Sprite[SortedPlayers[j].PlayerNum].DeadMeat and
               Sprite[SortedPlayers[j].PlayerNum].IsNotSpectator then
              GfxDrawSprite(T^[GFX_INTERFACE_DEADDOT], PixelAlignX(x),
                PixelAlignY(y + 1), RGBA($FFFFFF, ui_status_transparency.Value));

            x := 31 + fragx;

            if SortedPlayers[j].PlayerNum = MySprite then
              GfxDrawSprite(T^[GFX_INTERFACE_SMALLDOT], PixelAlignX(x),
                PixelAlignY(y + 1), RGBA($FFFFFF, ui_status_transparency.Value));

            x := 30 + fragx;
            {$IFDEF STEAM}
            // Steam Friend
            if not Sprite[SortedPlayers[j].PlayerNum].Player.SteamFriend then
              GfxDrawSprite(T^[GFX_INTERFACE_FRIEND], PixelAlignX(fragx + 240),
                PixelAlignY(y), Color);
            {$ENDIF}

            // reg star
            L := 0;
            if Sprite[SortedPlayers[j].PlayerNum].Player.JetColor and $FF000000 =
              COLOR_TRANSPARENCY_REGISTERED then
              L := GFX_INTERFACE_STAR
            else if Sprite[SortedPlayers[j].PlayerNum].Player.JetColor and $FF000000 =
              COLOR_TRANSPARENCY_SPECIAL then
              L := GFX_INTERFACE_PROT;

            Color := RGBA($FFFFFF, ui_status_transparency.Value);

            if L <> 0 then
              GfxDrawSprite(T^[L], PixelAlignX(fragx + 259),
                PixelAlignY(y - 1), Color);

            // flag icon
            if (Sprite[SortedPlayers[j].PlayerNum].Player.Flags > 0) and
               Sprite[SortedPlayers[j].PlayerNum].IsNotSpectator then
              GfxDrawSprite(T^[GFX_INTERFACE_FLAG], PixelAlignX(fragx + 337),
                PixelAlignY(y - 1), Color);

            // mute sign
            if Sprite[SortedPlayers[j].PlayerNum].Muted or MuteAll then
              GfxDrawSprite(T^[GFX_INTERFACE_MUTE], PixelAlignX(fragx + 246),
                PixelAlignY(y - 1), Color);

            // bot icon
            if Sprite[SortedPlayers[j].PlayerNum].Player.JetColor and $FF000000 =
              COLOR_TRANSPARENCY_BOT then
              GfxDrawSprite(T^[GFX_INTERFACE_BOT], PixelAlignX(fragx + 534),
                PixelAlignY(y), Color);


            GfxDrawSprite(T^[GFX_INTERFACE_CONNECTION], PixelAlignX(fragx + 520),
              PixelAlignY(y + 2),
              RGBA(
                Byte(((255 * (100 - Sprite[SortedPlayers[j].PlayerNum].Player.ConnectionQuality)) div 100)),
                Byte((255 * Sprite[SortedPlayers[j].PlayerNum].Player.ConnectionQuality) div 100),
                0,
                ui_status_transparency.Value)
              );
          end;
        end;
      end;
    end;
  end;

  if TeamMenu.Active then
    GfxDrawSprite(T^[GFX_INTERFACE_BACK], 45, 140, 262 / BACKGROUND_WIDTH,
      250 / BACKGROUND_WIDTH, RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.56)));

  if LimboMenu.Active then
  begin
    // draw weapon sprites in weapons menu
    _Scala.X := 252 / BACKGROUND_WIDTH;

    GfxDrawSprite(T^[GFX_INTERFACE_BACK], 45, 140, _Scala.x, 210 / BACKGROUND_WIDTH,
      RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.56)));

    GfxDrawSprite(T^[GFX_INTERFACE_BACK], 45, 350, _Scala.x, 80 / BACKGROUND_WIDTH,
      RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.56)));

    // draw guns on limbo menu
    x := PixelAlignX(55);
    y := 157;

    for k := 1 to PRIMARY_WEAPONS do
    begin
      if WeaponActive[k] = 1 then
      begin
        Spr := T^[GFX_INTERFACE_GUNS_DEAGLES + k - 1];
        dy := Max(0, 18 - Spr.Height * Spr.Scale) / 2;
        GfxDrawSprite(Spr, x, PixelAlignY(y + 18 * (k - 1) + dy),
          RGBA($FFFFFF, ui_status_transparency.Value));
      end;
    end;

    for k := PRIMARY_WEAPONS + 1 to MAIN_WEAPONS do
    begin
      if WeaponActive[k] = 1 then
      begin
        i := k - PRIMARY_WEAPONS - 1;
        Spr := T^[GFX_INTERFACE_GUNS_SOCOM + i];
        dy := Max(0, 18 - Spr.Height * Spr.Scale) / 2;

        if cl_player_secwep.Value = i then
          GfxDrawSprite(Spr, x, PixelAlignY(y + k * 18 + dy),
            RGBA($FFFFFF, ui_status_transparency.Value))
        else
          GfxDrawSprite(Spr, x, PixelAlignY(y + k * 18 + dy),
            RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.5)));
      end;
    end;
  end;

  // vote on
  if VoteActive then
  begin
    GfxDrawSprite(T^[GFX_INTERFACE_BACK], 45 * _iscala.x, 400 * _iscala.y,
      252 / BACKGROUND_WIDTH, 40 / BACKGROUND_WIDTH,
      RGBA($FFFFFF, Round(ui_status_transparency.Value * 0.36)));
  end;

  // Team Box
  if Int.Team and not DemoPlayer.Active and IsTeamGame then
  begin
    x := Int.TeamBox_X * _iscala.x;
    y := Int.TeamBox_Y * _iscala.y;

    GfxDrawSprite(T^[GFX_INTERFACE_BACK], x, y, 57 / BACKGROUND_WIDTH,
      88 / BACKGROUND_WIDTH, RGBA($FFFFFF, Round(Int.Alpha * 0.56)));

    // Draw captured flags in Team Box
    if (TeamFlag[1] > 0) and (TeamFlag[2] > 0) then
    begin
      if sv_gamemode.Value = GAMESTYLE_CTF then
      begin
        x := PixelAlignX((Int.TeamBox_X + 4) * _iscala.x);
        y := PixelAlignY((Int.TeamBox_Y + 5) * _iscala.y);

        if not Thing[TeamFlag[1]].InBase then
          GfxDrawSprite(T^[GFX_INTERFACE_NOFLAG], x, y,
            RGBA($FF0000, Round(Int.Alpha)));

        x := PixelAlignX(x + 31);

        if not Thing[TeamFlag[2]].InBase then
          GfxDrawSprite(T^[GFX_INTERFACE_NOFLAG], x, y,
            RGBA($0000FF, Round(Int.Alpha)));
      end
      else if sv_gamemode.Value = GAMESTYLE_INF then
      begin
        if not Thing[TeamFlag[2]].InBase then
        begin
          x := PixelAlignX((Int.TeamBox_X + 19) * _iscala.x);
          y := PixelAlignY((Int.TeamBox_Y + 3) * _iscala.y);

          GfxDrawSprite(T^[GFX_INTERFACE_NOFLAG], x, y,
            RGBA($0000FF, Round(Int.Alpha)));
        end;
      end;
    end
    else if (TeamFlag[1] > 0) and (sv_gamemode.Value = GAMESTYLE_HTF) then
    begin
      if Thing[TeamFlag[1]].HoldingSprite > 0 then
      begin
        if Sprite[Thing[TeamFlag[1]].HoldingSprite].Player.Team = TEAM_ALPHA then
        begin
          x := PixelAlignX((Int.TeamBox_X + 19) * _iscala.x);
          y := PixelAlignY((Int.TeamBox_Y + 3) * _iscala.y);

          GfxDrawSprite(T^[GFX_INTERFACE_NOFLAG], x, y,
            RGBA($FF0000, Round(Int.Alpha)));
        end else
        begin
          x := PixelAlignX((Int.TeamBox_X + 19) * _iscala.x);
          y := PixelAlignY((Int.TeamBox_Y + 3) * _iscala.y);

          GfxDrawSprite(T^[GFX_INTERFACE_NOFLAG], x, y,
            RGBA($0000FF, Round(Int.Alpha)));
        end;
      end;
    end;
  end;

  // text
  GfxTextShadow(1, 1, RGBA(0));

  if NoTexts = 0 then
  begin
    if MySprite > 0 then
    begin
      if Sprite[MySprite].IsSpectator and (CameraFollowSprite > 0) and
        (sv_advancedspectator.Value) then
        RenderPlayerInterfaceTexts(CameraFollowSprite)
      else
        RenderPlayerInterfaceTexts(MySprite);
    end;

    if Int.Team then
      RenderTeamScoreTexts;

    if MapChangeCounter > 0 then
    begin
      if FragsMenuShow and (PlayersNum > 1) and (MapChangeCounter < 999999999) then
        RenderEndGameTexts(FragMenuBottom);

      if MapChangeCounter > 99999999 then
      begin
        // game paused
        GfxTextColor(RGBA(185, 250, 138));
        GfxDrawText(_('Game paused'), 197 + fragx, 24 + fragy);
      end;
    end;

    if StatsMenuShow then
      RenderWeaponStatsTexts;

    if FragsMenuShow then
      RenderFragsMenuTexts(FragMenuBottom);

    if ui_console.Value then
      RenderConsoleTexts(Width);

    if MySprite > 0 then
      RenderRespawnAndSurvivalTexts;

    RenderVoteMenuTexts;

    if ShowRadioMenu and (sv_radio.Value) and not EscMenu.Active then
      RenderRadioMenuTexts;

    if ChatText <> '' then
      RenderChatInput(Width, Height, TimeElapsed);

    if ui_killconsole.Value then
      RenderKillConsoleTexts(Width);

    {$IFDEF STEAM}
    if cl_voicechat.Value then
      RenderVoiceChatTexts;
    {$ENDIF}
  end;

  if MySprite > 0 then
  begin
    RenderChatTexts;

    if PlayerNamesShow then
      RenderPlayerNames(Width, Height);

    if (sv_survivalmode.Value) and Sprite[MySprite].Active and
      (Sprite[MySprite].CeaseFireCounter > 0) then
      RenderCeaseFireCounter;
  end;

  if NoTexts = 0 then
  begin
    SetFontStyle(FONT_SMALL);

    // cursor text
    if (CursorTextLength > 0) and (MapChangeCounter < 0) and not TeamMenu.Active and
      not EscMenu.Active and not DemoPlayer.Active then
    begin
      x := mx * _rscala.x - 0.5 * RectWidth(GfxTextMetrics(WideString(CursorText)));
      y := (my + 10) * _rscala.y;

      GfxTextColor(RGBA($FFFFFF, $77));
      GfxDrawText(x, y);
    end;

    // free camera / following player
    if CameraFollowSprite = 0 then
    begin
      x := (Width - RectWidth(GfxTextMetrics(_('Free Camera')))) / 2;
      GfxTextColor(RGBA(205, 205, 205));
      GfxDrawText(x, 430 * _iscala.y);
    end
    else if (CameraFollowSprite > 0) and (CameraFollowSprite <= MAX_SPRITES) and
      (CameraFollowSprite <> MySprite) then
    begin
      i := Integer(Sprite[CameraFollowSprite].DeadMeat);
      x := (Width - RectWidth(GfxTextMetrics(_('Following') + ' ' +
        WideString(Sprite[CameraFollowSprite].Player.Name)))) / 2;

      GfxTextColor(RGBA(205, 205 - i * 105, 205 - i * 105));
      GfxDrawText(x, 430 * _iscala.y);
    end;

    // FPS & connection info
    if ConInfoShow then
    begin
      GfxTextColor(RGBA(239, 170, 200));

      x := _iscala.x;
      y := _iscala.y;

      GfxDrawText('FPS: ' + IntToStr(GetGameFps), 460 * x, 10 * y);

      if (MySprite > 0) then
        GfxDrawText('Ping: ' + IntToStr(Sprite[MySprite].Player.RealPing),
          550 * x, 10 * y);

      if DemoPlayer.Active then
      begin
        GfxDrawText(
          Format('Demo: %.2d:%.2d / %.2d:%.2d (%d / %d)', [
            Round((MainTickCounter div 60) div 60),
            Round((MainTickCounter div 60) mod 60),
            Round((DemoPlayer.Header.TicksNum div 60) div 60),
            Round((DemoPlayer.Header.TicksNum div 60) mod 60),
            MainTickCounter,
            DemoPlayer.Header.TicksNum]), 460 * x, 80 * y);
      end else
      begin
        NetworkStats := UDP.GetQuickConnectionStatus(UDP.Peer);
        SetFontStyle(FONT_SMALLEST);
        GfxDrawText('Ping: ' + NetworkStats.m_nPing.ToString, 460 * x, 40 * y);
        GfxDrawText('Quality: Local ' + Single(NetworkStats.m_flConnectionQualityLocal * 100).ToString(ffFixed, 7, 0) +
          '% Remote -  ' + Single(NetworkStats.m_flConnectionQualityRemote * 100).ToString(ffFixed, 7, 0) + ' %', 460 * x, 50 * y);
        GfxDrawText('Traffic Out: ' + NetworkStats.m_flOutPacketsPerSec.ToString(ffFixed, 7, 1) + ' pkt/s ' + NetworkStats.m_flOutBytesPerSec.ToString(ffFixed, 7, 1) + ' B/s', 460 * x, 60 * y);
        GfxDrawText('Traffic In: ' + NetworkStats.m_flInPacketsPerSec.ToString(ffFixed, 7, 1) + ' pkt/s ' + NetworkStats.m_flInBytesPerSec.ToString(ffFixed, 7, 1) + ' B/s', 460 * x, 70 * y);
        GfxDrawText('Max Send Rate: ' + NetworkStats.m_nSendRateBytesPerSecond.ToString + ' B/s', 460 * x, 80 * y);
        GfxDrawText('Pending Packets: ' + NetworkStats.m_cbPendingUnreliable.ToString + ' / ' + NetworkStats.m_cbPendingUnreliable.ToString, 460 * x, 90 * y);
        GfxDrawText('Queue Time: ' + NetworkStats.m_usecQueueTime.ToString + ' ms', 460 * x, 100 * y);

        SetFontStyle(FONT_SMALLEST);
        GfxDrawText(UDP.GetDetailedConnectionStatus(UDP.Peer), 100 * x, 10 * y);
        SetFontStyle(FONT_SMALL);
      end;
    end;

    // REC
    if DemoRecorder.Active then
    begin
      GfxTextColor(RGBA(195, 0, 0, Abs(Sin(5.1 * TimeElapsed / 2) * 255)));
      GfxDrawText('REC', 612 * _iscala.x, 1 * _iscala.y);
    end;

    // default keys help
    if NoobShow and EscMenu.Active and (ChatText = '') then
    begin
      SetFontStyle(FONT_SMALLEST);
      GfxTextColor(RGBA(250, 90, 95));
      GfxDrawText(_('Default keys (shown for first 3 game runs)'), 30 * _rscala.x, 28 * _rscala.y);
      SetFontStyle(FONT_SMALL);

      for i := 1 to 8 do
      begin
        GfxTextColor(RGBA(230, 232 - 2 * i, 255));
        case i of
        1: GfxDrawText(_('[A]/[D] move left/right'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        2: GfxDrawText(_('[W]/[S]/[X] jump / crouch / lie down'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        3: GfxDrawText(_('[Left Mouse] fire!'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        4: GfxDrawText(_('[Right Mouse] jet boots'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        5: GfxDrawText(_('hold [E] to toss grenade'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        6: GfxDrawText(_('[R] reloads weapon'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        7: GfxDrawText(_('[Q] change weapon / [F] throw weapon'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        8: GfxDrawText(_('[T] chat / [Y] team chat'), 30 * _rscala.x, (28 + 12 * i) * _rscala.y);
        end;
      end;
    end;

    // action snap
    if (ScreenCounter < 255) and (ShowScreen = False) and (cl_actionsnap.Value) then
    begin
      GfxTextColor(RGBA(230, 65, 60, 150 + Abs(Round(Sin(5.1 * TimeElapsed) * 100))));
      GfxDrawText('[[ ' + _('Press F5 to View Screen Cap') + ' ]]', 30 * _iscala.x, 412 * _iscala.y);
    end;

    // shot distance
    if ShotDistanceShow > 0 then
    begin
      GfxTextColor(RGBA(230, 65, 60, 150 + Abs(Round(Sin(5.1 * TimeElapsed) * 100))));

      Str := 'DISTANCE: ' + WideString(FloatToStrF(ShotDistance, ffFixed, 12, 2)) + 'm';
      GfxDrawText(Str, 390 * _iscala.x, 431 * _iscala.y);

      Str := 'AIRTIME: ' + WideString(FloatToStrF(ShotLife, ffFixed, 12, 2)) + 's';
      GfxDrawText(Str, 228 * _iscala.x, 431 * _iscala.y);

      if ShotRicochet > 0 then
      begin
        Str := 'RICOCHETS: ' + WideString(IntToStr(ShotRicochet));
        GfxDrawText(Str, 62 * _iscala.x, 431 * _iscala.y);
      end;
    end;
  end;

  // Bullet time cut to wide screen
  if WideScreenCut then
  begin
    GfxDrawQuad(nil,
      GfxVertex(    0,              0, 0, 0, RGBA(0)),
      GfxVertex(Width,              0, 0, 0, RGBA(0)),
      GfxVertex(Width, 80 * _rscala.y, 0, 0, RGBA(0)),
      GfxVertex(    0, 80 * _rscala.y, 0, 0, RGBA(0))
    );

    GfxDrawQuad(nil,
      GfxVertex(    0, Height - 80 * _rscala.y, 0, 0, RGBA(0)),
      GfxVertex(Width, Height - 80 * _rscala.y, 0, 0, RGBA(0)),
      GfxVertex(Width,                  Height, 0, 0, RGBA(0)),
      GfxVertex(    0,                  Height, 0, 0, RGBA(0))
    );
  end;

  RenderGameMenuTexts(Width, Height);

  // Menu cursor
  alfa := MySprite;
  if alfa < 1 then
    alfa := MAX_PLAYERS;
  if EscMenu.Active or LimboMenu.Active or TeamMenu.Active or Sprite[alfa].DeadMeat then
  begin
    if not DemoPlayer.Active or EscMenu.Active then
    begin
      x := PixelAlignX(mx * _RScala.x);
      y := PixelAlignY(my * _RScala.y);

      GfxDrawSprite(T^[GFX_INTERFACE_MENUCURSOR], x, y,
        RGBA($FFFFFF, Round(ui_status_transparency.Value)));
    end;
  end;
end;

end.
