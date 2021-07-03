{*******************************************************}
{                                                       }
{       Gfx Unit for SOLDAT                             }
{                                                       }
{       Copyright (c) 2015 Mariano Cuatrin              }
{                                                       }
{*******************************************************}

unit Gfx;

interface

uses
  Vector, Classes;

const
  GFX_MONOCHROME = 1;

type
  TGfxTextureWrap = (GFX_CLAMP, GFX_REPEAT);
  TGfxVerticalAlign = (GFX_TOP, GFX_BASELINE, GFX_BOTTOM);

  TGfxTextureFilter = (
    GFX_LINEAR,
    GFX_NEAREST,
    GFX_MIPMAP_LINEAR,
    GFX_MIPMAP_NEAREST
  );

  PGfxMat3 = ^TGfxMat3;
  TGfxMat3 = array[0..8] of Single;

  PGfxColor = ^TGfxColor;
  TGfxColor = record
    case Integer of
      0: (r, g, b, a: Byte);
      1: (rgba: LongWord);
  end;

  PGfxVertex = ^TGfxVertex;
  TGfxVertex = record
    x, y: Single;
    u, v: Single;
    Color: TGfxColor;
  end;

  PGfxRect = ^TGfxRect;
  TGfxRect = record
    Left, Right: Single;
    Top, Bottom: Single;
  end;

  TGfxFont = Pointer;

  TGfxImage = class
  private
    FData: PByte;
    FWidth: Integer;
    FHeight: Integer;
    FComponents: Integer;
    FNumFrames: Integer;
    FDelays: PInteger;
    FLoadedFromFile: Boolean;
  public
    constructor Create(Filename: string; ColorKey: TGfxColor); overload;
    constructor Create(Width, Height: Integer; Comp: Integer = 4); overload;
    destructor Destroy; override;
    function GetImageData(Frame: Integer = 0): PByte;
    function GetFrameDelay(Frame: Integer = 0): Word;
    procedure Update(x, y, w, h: Integer; Data: PByte; Frame: Integer = 0);
    procedure Premultiply;
    procedure Resize(w, h: Integer);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Components: Integer read FComponents;
    property NumFrames: Integer read FNumFrames;
  end;

  TGfxTexture = class
  private
    FHandle: Integer;
    FFboHandle: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FComponents: Integer;
    FSamples: Integer;
    FPixel: record
      x, y: Integer;
      Color: TGfxColor;
    end;
    procedure Update(x, y, w, h: Integer; Data: PByte);
    procedure SetWrap(s, t: TGfxTextureWrap);
    procedure SetFilter(Min, Mag: TGfxTextureFilter);
  public
    constructor Create(Width, Height: Integer; Comp: Integer; Rt, Msaa: Boolean; Data: PByte);
    destructor Destroy; override;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Components: Integer read FComponents;
    property Samples: Integer read FSamples;
  end;

  TGfxVertexBuffer = class
  private
    FHandle: Integer;
    FCapacity: Integer;
    procedure Update(Offset, Count: Integer; Data: PGfxVertex);
  public
    constructor Create(Cap: Integer; Static: Boolean; Data: PGfxVertex);
    destructor Destroy; override;
    property Capacity: Integer read FCapacity;
  end;

  TGfxIndexBuffer = class
  private
    FHandle: Integer;
    FCapacity: Integer;
    procedure Update(Offset, Count: Integer; Data: PWord);
  public
    constructor Create(Cap: Integer; Static: Boolean; Data: PWord);
    destructor Destroy; override;
    property Capacity: Integer read FCapacity;
  end;

  PGfxSprite = ^TGfxSprite;
  TGfxSprite = record
    x, y: Integer;
    Width, Height: Integer;
    Scale: Single;
    Delay: Integer;
    TexCoords: TGfxRect;
    Texture: TGfxTexture;
    Next: PGfxSprite;
  end;

  TGfxSpriteArray = array of PGfxSprite;

  TGfxSpritesheet = class
  private
    FTextures: array of TGfxTexture;
    FSprites: array of TGfxSprite;
    FAdditionalSprites: array of TGfxSprite;
    FLoadData: Pointer;
    function GetSprite(Index: Integer): PGfxSprite;
    function GetTexture(Index: Integer): TGfxTexture;
    function GetSpriteCount: Integer;
    function GetTextureCount: Integer;
    function IsLoading: Boolean;
    procedure LoadNextImage;
    procedure PackRects;
    procedure UpdateNextSprite;
    procedure UpdateTexture;
    procedure CleanUp;
  public
    constructor Create(Count: Integer);
    destructor Destroy; override;
    procedure AddImage(Path: string; ColorKey: TGfxColor; TargetScale: Single); overload;
    procedure AddImage(Path: string; ColorKey: TGfxColor; TargetSize: TVector2); overload;
    procedure AddImage(Image: TGfxImage); overload;
    procedure Load;
    procedure StartLoading;
    procedure ContinueLoading;
    procedure FinishLoading;
    property SpriteCount: Integer read GetSpriteCount;
    property TextureCount: Integer read GetTextureCount;
    property Sprites[Index: Integer]: PGfxSprite read GetSprite; default;
    property Texture[Index: Integer]: TGfxTexture read GetTexture;
    property Loading: Boolean read IsLoading;
  end;

  PGfxDrawCommand = ^TGfxDrawCommand;
  TGfxDrawCommand = record
    Texture: TGfxTexture;
    Offset: Integer;
    Count: Integer;
  end;

// general
function GfxFramebufferSupported(): Boolean;
function GfxInitContext(Wnd: Pointer; Dithering, FixedPipeline: Boolean): Boolean;
procedure GfxDestroyContext;
procedure GfxPresent(Finish: Boolean);
procedure GfxTarget(RenderTarget: TGfxTexture);
procedure GfxBlit(Src, Dst: TGfxTexture; SrcRect, DstRect: TRect; filter: TGfxTextureFilter);
procedure GfxClear(r, g, b, a: Byte); overload;
procedure GfxClear(c: TGfxColor); overload;
procedure GfxDraw(Buffer: TGfxVertexBuffer; Offset, Count: Integer); overload;
procedure GfxDraw(Buffer: TGfxVertexBuffer; IndexBuffer: TGfxIndexBuffer; Offset,
  Count: Integer); overload;
procedure GfxDraw(Buffer: TGfxVertexBuffer; Cmds: PGfxDrawCommand;
  CmdCount: Integer); overload;
procedure GfxDraw(Buffer: TGfxVertexBuffer; IndexBuffer: TGfxIndexBuffer;
  Cmds: PGfxDrawCommand; CmdCount: Integer); overload;
procedure GfxViewport(x, y, w, h: Integer);
procedure GfxTransform(const t: TGfxMat3);
procedure GfxSpriteVertices(s: PGfxSprite; x, y, w, h, sx, sy, cx, cy, r: Single;
  Color: TGfxColor; v: PGfxVertex);
procedure GfxSaveScreen(Filename: string; x, y, w, h: Integer; Async: Boolean = True);
procedure GfxSetMipmapBias(Bias: Single);

// pseudo constructors
function ARGB(argb: LongWord): TGfxColor; overload;
function RGBA(r, g, b, a: Byte): TGfxColor; overload;
function RGBA(r, g, b: Byte): TGfxColor; overload;
function RGBA(rgba: LongWord): TGfxColor; overload;
function RGBA(r, g, b: Byte; a: Extended): TGfxColor; overload;
function RGBA(rgb: LongWord; a: Single): TGfxColor; overload;
function GfxVertex(x, y, u, v: Single; c: TGfxColor): TGfxVertex;

// texture
function GfxCreateTexture(w, h: Integer; c: Integer = 4; Data: PByte = 0): TGfxTexture;
function GfxCreateRenderTarget(w, h: Integer; c: Integer = 4; Msaa: Boolean = False): TGfxTexture;
procedure GfxBindTexture(Texture: TGfxTexture);
procedure GfxTextureWrap(Texture: TGfxTexture; s, t: TGfxTextureWrap);
procedure GfxTextureFilter(Texture: TGfxTexture; Min, Mag: TGfxTextureFilter);
procedure GfxUpdateTexture(Texture: TGfxTexture; x, y, w, h: Integer; Data: PByte);
procedure GfxGenerateMipmap(Texture: TGfxTexture);
procedure GfxDeleteTexture(var Texture: TGfxTexture);

// vertex buffer
function GfxCreateBuffer(Capacity: Integer; Static: Boolean = False;
  Data: PGfxVertex = nil): TGfxVertexBuffer;
procedure GfxUpdateBuffer(b: TGfxVertexBuffer; i, n: Integer; Data: PGfxVertex);
procedure GfxDeleteBuffer(var b: TGfxVertexBuffer);

// index buffer
function GfxCreateIndexBuffer(Capacity: Integer; Static: Boolean = False;
  Data: PWord = nil): TGfxIndexBuffer;
procedure GfxUpdateIndexBuffer(b: TGfxIndexBuffer; i, n: Integer; Data: PWord);
procedure GfxDeleteIndexBuffer(var b: TGfxIndexBuffer);

// fonts
function GfxCreateFont(Filename: string; w: Integer = 512; h: Integer = 512): TGfxFont;
procedure GfxDeleteFont(var Font: TGfxFont);
function GfxSetFont(Font: TGfxFont; FontSize: Single; Flags: LongWord;
  Stretch: Single = 1): Integer;
procedure GfxSetFontTable(Font: TGfxFont; TableIndex: Integer);
procedure GfxTextPixelRatio(PixelRatio: TVector2);
procedure GfxTextScale(s: Single);
procedure GfxTextColor(Color: TGfxColor);
procedure GfxTextShadow(dx, dy: Single; Color: TGfxColor);
procedure GfxTextVerticalAlign(Align: TGfxVerticalAlign);
function GfxTextMetrics: TGfxRect; overload;
function GfxTextMetrics(const Text: WideString): TGfxRect; overload;
procedure GfxDrawText(x, y: Single); overload;
procedure GfxDrawText(const Text: WideString; x, y: Single); overload;
  procedure GfxDrawText(const Text: AnsiString; x, y: Single); overload;

// batching
procedure GfxBegin;
procedure GfxEnd;
procedure GfxDrawQuad(Texture: TGfxTexture; const Vertices: array of TGfxVertex); overload;
procedure GfxDrawQuad(Texture: TGfxTexture; const a, b, c, d: TGfxVertex); overload;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single); overload;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single; rc: TGfxRect); overload;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single; Color: TGfxColor); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single; Color: TGfxColor); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single; Color: TGfxColor); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single; Color: TGfxColor); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single; Color: TGfxColor); overload;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single; Color: TGfxColor; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single; Color: TGfxColor; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single; Color: TGfxColor; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single; Color: TGfxColor; rc: TGfxRect); overload;
procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single; Color: TGfxColor; rc: TGfxRect); overload;

// matrix
function GfxMat3Rot(r: Single): TGfxMat3;
function GfxMat3Ortho(l, r, t, b: Single): TGfxMat3;
function GfxMat3Transform(tx, ty, sx, sy, cx, cy, r: Single): TGfxMat3;
function GfxMat3Mul(const m: TGfxMat3; x, y: Single): TVector2;

// other
function Npot(x: Integer): Integer;  // next power of two
function RectWidth(const Rect: TGfxRect): Single;
function RectHeight(const Rect: TGfxRect): Single;

var
  GfxLog: procedure(s: string);

implementation

uses
  SysUtils, Math, dglOpenGL,
  {$IFDEF MSWINDOWS}Windows, {$ENDIF}
  BinPack, stb, FreeType, SDL2, Input, PhysFS;

{******************************************************************************}
{*                              Helper functions                              *}
{******************************************************************************}

function Join(const List: array of string; const Separator: string): string;
var
  i: Integer;
begin
  Result := '';

  for i := Low(List) to High(List) - 1 do
    Result := Result + List[i] + Separator;

  Result := Result + List[High(List)];
end;

function Npot(x: LongInt): Integer;
begin
  Dec(x);
  x := x or (x shr 1);
  x := x or (x shr 2);
  x := x or (x shr 4);
  x := x or (x shr 8);
  x := x or (x shr 16);
  Result := Max(2, x + 1);
end;

function RectWidth(const Rect: TGfxRect): Single;
begin
  Result := Abs(Rect.Right - Rect.Left);
end;

function RectHeight(const Rect: TGfxRect): Single;
begin
  Result := Abs(Rect.Bottom - Rect.Top);
end;

{******************************************************************************}
{*                                    Gfx                                     *}
{******************************************************************************}

const
  BATCH_MIN = 2048;
  GLYPH_POOL_SIZE = 64;

type
  TBatchBuffer = record
    Data: PGfxVertex;
    Size: Integer;
    Capacity: Integer;
  end;

  TBatch = record
    VertexBuffer: TGfxVertexBuffer;
    Buffers: array of TBatchBuffer;
    Commands: array of TGfxDrawCommand;
    CommandsSize: Integer;
  end;

  PGlyph = ^TGlyph;
  PPGlyph = ^PGlyph;
  TGlyph = record
    GlyphIndex: Integer;
    Page: Integer;
    Advance: Single;
    Bounds: TGfxRect;
    TexCoords: TGfxRect;
  end;

  PGlyphTable = ^TGlyphTable;
  TGlyphTable = record
    FontSize: Integer;
    Stretch: Integer;
    Flags: LongWord;
    VSpace: Single;
    Ascent: Single;
    Descent: Single;
    Size: Integer;
    Capacity: Integer;
    Glyphs: PPGlyph;
  end;

  PFontNode = ^TFontNode;
  TFontNode = record
    x, y, w: Integer;
  end;

  PComputedGlyph = ^TComputedGlyph;
  TComputedGlyph = record
    x, y: Single;
    Glyph: PGlyph;
  end;

  PFont = ^TFont;
  TFont = record
    Handle: FT_Face;
    Width: Integer;
    Height: Integer;
    Buffer: PByte;
    BufferSize: Integer;
    NodesSize: Integer;
    Nodes: array of TFontNode;
    Pages: array of TGfxTexture;
    Tables: array of TGlyphTable;
    Pool: array of PGlyph;
    PoolIndex: Integer;
  end;

  TScreenshotThread = class(TThread)
  private
    FName: string;
    FWidth: Integer;
    FHeight: Integer;
    FData: PByte;
  public
    constructor Create(Filename: string; w, h: Integer; Data: PByte);
    procedure Execute(); override;
  end;

var
  GfxContext: record
    MajorVersion: Integer;
    ShaderProgram: GLuint;
    MatrixLoc: GLint;
    Batch: TBatch;
    RenderTarget: TGfxTexture;
    WhiteTexture: TGfxTexture;
    BoundBuffer: TGfxVertexBuffer;
    DitheringTexture: GLuint;
    MaxTextureSize: GLint;
    MsaaSamples: GLint;
    FTLibrary: FT_Library;
    Font: PFont;
    GlyphTable: PGlyphTable;
    TextPixelRatio: TVector2;
    TextScale: Single;
    TextColor: TGfxColor;
    TextShadowOffset: TVector2;
    TextShadowColor: TGfxColor;
    TextVerticalAlign: TGfxVerticalAlign;
    TextIndexStr: PInteger;
    TextGlyphStr: PPGlyph;
    TextComputedStr: PComputedGlyph;
    TextStrSize: Integer;
    TextComputedCount: Integer;
  end;

function CreateShader(ShaderType: GLenum; const ShaderSource: string): GLuint;
var
  Source: AnsiString;
  SourcePtr, Info: PGLChar;
  Status: GLint;
  Len, Dummy: GLsizei;
begin
  Source := AnsiString(ShaderSource);
  SourcePtr := PGLChar(Source);

  Result := glCreateShader(ShaderType);
  glShaderSource(Result, 1, @SourcePtr, NIL);
  glCompileShader(Result);
  glGetShaderiv(Result, GL_COMPILE_STATUS, @Status);

  if Status = GLint(GL_FALSE) then
  begin
    Dummy := 0;
    glGetShaderiv(Result, GL_INFO_LOG_LENGTH, @Len);
    GetMem(Info, Len + 1);
    glGetShaderInfoLog(Result, Len, @Dummy, Info);
    GfxLog('-- Shader compilation failure --' + #10 + string(Info) + #10);
    FreeMem(Info);

    glDeleteShader(Result);
    Result := 0;
  end;
end;

procedure SetupVertexAttributes(Buffer: TGfxVertexBuffer);
begin
  if GfxContext.BoundBuffer <> Buffer then
  begin
    glBindBuffer(GL_ARRAY_BUFFER, Buffer.FHandle);

    if GfxContext.ShaderProgram <> 0 then
    begin
      glVertexAttribPointer(0, 2, GL_FLOAT, False, sizeof(TGfxVertex), Pointer(0));
      glVertexAttribPointer(1, 2, GL_FLOAT, False, sizeof(TGfxVertex), Pointer(8));
      // Workaround for MESA 20.1+ breakage: Pass ByteBool(1) instead of True
      glVertexAttribPointer(2, 4, GL_UNSIGNED_BYTE, ByteBool(1), sizeof(TGfxVertex), Pointer(16));
    end
    else
    begin
      glVertexPointer(2, GL_FLOAT, sizeof(TGfxVertex), Pointer(0));
      glTexCoordPointer(2, GL_FLOAT, sizeof(TGfxVertex), Pointer(8));
      glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(TGfxVertex), Pointer(16));
    end;

    GfxContext.BoundBuffer := Buffer;
  end;
end;

function GfxFramebufferSupported(): Boolean;
begin
  Result := Assigned(glGenFramebuffers) and Assigned(glBlitFramebuffer);
end;

function InitShaderProgram(Dithering: Boolean): Boolean;
const
  VERT_SOURCE: array[0..12] of string = (
    '#version 120',
    'uniform mat3 mvp;',
    'attribute vec4 in_position;',
    'attribute vec2 in_texcoords;',
    'attribute vec4 in_color;',
    'varying vec2 texcoords;',
    'varying vec4 color;',
    'void main() {',
    '  color = vec4(in_color.rgb * in_color.a, in_color.a);',
    '  texcoords = in_texcoords;',
    '  gl_Position.xyw = mvp * in_position.xyw;',
    '  gl_Position.z = 0.00;',
    '}'
  );

  FRAG_SOURCE: array[0..11] of string = (
    '#version 120',
    '#define DITHERING 1',
    'varying vec2 texcoords;',
    'varying vec4 color;',
    'uniform sampler2D sampler;',
    'uniform sampler2D dither;',
    'void main() {',
    '  gl_FragColor = texture2D(sampler, texcoords) * color;',
    '#if DITHERING',
    '  gl_FragColor.rgb += vec3(texture2D(dither, gl_FragCoord.xy / 8.0).a / 32.0 - 1.0/128.0);',
    '#endif',
    '}'
  );

  DITHER: array[1..8*8] of Byte = (
     0, 32,  8, 40,  2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
     3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21
  );
var
  FragShader, VertShader: GLuint;
  FragSrc, VertSrc: string;
  Status: GLint;
  Info: PGLChar;
  Len: GLsizei;
  Dummy: PGLsizei;
  RequiredFunctions: Boolean;
begin
  Result := False;

  RequiredFunctions :=
    Assigned(glCreateShader)            and
    Assigned(glShaderSource)            and
    Assigned(glCompileShader)           and
    Assigned(glGetShaderiv)             and
    Assigned(glGetShaderInfoLog)        and
    Assigned(glDeleteShader)            and
    Assigned(glAttachShader)            and
    Assigned(glDetachShader)            and
    Assigned(glLinkProgram)             and
    Assigned(glGetProgramiv)            and
    Assigned(glGetProgramInfoLog)       and
    Assigned(glUseProgram)              and
    Assigned(glGetUniformLocation)      and
    Assigned(glUniform1i)               and
    Assigned(glUniformMatrix3fv)        and
    Assigned(glEnableVertexAttribArray) and
    Assigned(glVertexAttribPointer)     and
    Assigned(glBindAttribLocation)      and
    Assigned(glActiveTexture);

  if not RequiredFunctions then
    Exit;

  VertSrc := Join(VERT_SOURCE, #10);
  FragSrc := Join(FRAG_SOURCE, #10);

  if not Dithering then
    FragSrc := StringReplace(FragSrc, '#define DITHERING 1', '#define DITHERING 0', []);

  VertShader := CreateShader(GL_VERTEX_SHADER, VertSrc);
  FragShader := CreateShader(GL_FRAGMENT_SHADER, FragSrc);

  if (VertShader = 0) or (FragShader = 0) then
  begin
    if VertShader <> 0 then glDeleteShader(VertShader);
    if FragShader <> 0 then glDeleteShader(FragShader);
    Exit;
  end;

  GfxContext.ShaderProgram := glCreateProgram;

  glBindAttribLocation(GfxContext.ShaderProgram, 0, 'in_position');
  glBindAttribLocation(GfxContext.ShaderProgram, 1, 'in_texcoords');
  glBindAttribLocation(GfxContext.ShaderProgram, 2, 'in_color');

  glAttachShader(GfxContext.ShaderProgram, VertShader);
  glAttachShader(GfxContext.ShaderProgram, FragShader);

  glLinkProgram(GfxContext.ShaderProgram);
  glGetProgramiv(GfxContext.ShaderProgram, GL_LINK_STATUS, @Status);

  if Status = GLint(GL_FALSE) then
  begin
    Dummy := nil;
    glGetProgramiv(GfxContext.ShaderProgram, GL_INFO_LOG_LENGTH, @Len);
    GetMem(Info, Len + 1);
    glGetProgramInfoLog(GfxContext.ShaderProgram, Len, Dummy, Info);
    {$IFDEF DEVELOPMENT}
    WriteLn('-- Program linking failure --' + #10 + string(Info) + #10);
    {$ENDIF}
    FreeMem(Info);
  end;

  glDetachShader(GfxContext.ShaderProgram, VertShader);
  glDetachShader(GfxContext.ShaderProgram, FragShader);
  glDeleteShader(VertShader);
  glDeleteShader(FragShader);

  if Status = GLint(GL_FALSE) then
  begin
    glDeleteProgram(GfxContext.ShaderProgram);
    GfxContext.ShaderProgram := 0;
    Exit;
  end;

  Result := True;

  glUseProgram(GfxContext.ShaderProgram);
  glUniform1i(glGetUniformLocation(GfxContext.ShaderProgram, PGLchar('dither')), 1);
  GfxContext.MatrixLoc := glGetUniformLocation(GfxContext.ShaderProgram, PGLchar('mvp'));

  glEnableVertexAttribArray(0);
  glEnableVertexAttribArray(1);
  glEnableVertexAttribArray(2);

  // dithering texture

  if Dithering then
  begin
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, @GfxContext.DitheringTexture);
    glBindTexture(GL_TEXTURE_2D, GfxContext.DitheringTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, 8, 8, 0, GL_ALPHA, GL_UNSIGNED_BYTE, @DITHER[1]);
    glActiveTexture(GL_TEXTURE0);
  end;
end;

function GfxInitContext(Wnd: Pointer; Dithering, FixedPipeline: Boolean): Boolean;
var
  i: Integer;
  Color: TGfxColor;
  Version: string;
  RequiredFunctions: Boolean;
begin
  Result := True;

  GameGLContext := SDL_GL_CreateContext(Wnd);
  InitOpenGL();
  ReadImplementationProperties();
  ReadExtensions();
  SDL_GL_MakeCurrent(GameWindow, GameGLContext);
  Version := glGetString(GL_VERSION);
  i := Pos('.', Version);
  //FIXME: Not compatible with opengl ES
  GfxContext.MajorVersion := StrToInt(Copy(Version, 1, i - 1));
  GfxLog('OpenGL version: ' + Version);

  if not Assigned(glGenFramebuffers) then
  begin
    if Assigned(glGenFramebuffersEXT) then
    begin
      @glGenFramebuffers      := @glGenFramebuffersEXT;
      @glDeleteFramebuffers   := @glDeleteFramebuffersEXT;
      @glBindFramebuffer      := @glBindFramebufferEXT;
      @glFramebufferTexture2D := @glFramebufferTexture2DEXT;
      @glGenerateMipmap       := @glGenerateMipmapEXT;
    end;
  end;

  RequiredFunctions :=
    Assigned(glBindBuffer)     and  // vertex/index buffers
    Assigned(glGenBuffers)     and
    Assigned(glBufferData)     and
    Assigned(glDeleteBuffers)  and
    Assigned(glBufferSubData)  and
    Assigned(glGenTextures)    and  // textures
    Assigned(glBindTexture)    and
    Assigned(glDeleteTextures) and
    Assigned(glTexParameteri)  and
    Assigned(glTexImage2D)     and
    Assigned(glTexSubImage2D)  and
    Assigned(glEnable)         and  // general
    Assigned(glDisable)        and
    Assigned(glBlendFunc)      and
    Assigned(glPixelStorei)    and
    Assigned(glViewport)       and
    Assigned(glClearColor)     and
    Assigned(glClear)          and
    Assigned(glDrawArrays)     and
    Assigned(glDrawElements)   and
    Assigned(glReadPixels)     and
    Assigned(glTexEnvf)        and
    Assigned(glGetIntegerv);

  if not RequiredFunctions then
  begin
    Result := False;
    GfxDestroyContext;
    Exit;
  end;

  if not FixedPipeline then
  begin
    if InitShaderProgram(Dithering) = False then
    begin
      GfxLog('Falling back to OpenGL fixed pipeline.');
      FixedPipeline := True;
    end;
  end;

  if FixedPipeline then
  begin
    RequiredFunctions :=
      Assigned(glEnableClientState) and
      Assigned(glVertexPointer)     and
      Assigned(glTexCoordPointer)   and
      Assigned(glColorPointer)      and
      Assigned(glLoadMatrixf);

    if not RequiredFunctions then
    begin
      Result := False;
      GfxDestroyContext;
      Exit;
    end;

    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);

    if Dithering then
      glEnable(GL_DITHER)
    else
      glDisable(GL_DITHER);
  end;

  // create a default white texture

  Color.rgba := $FFFFFFFF;
  GfxContext.WhiteTexture := GfxCreateTexture(1, 1, 4, @Color);

  // setup some state

  glEnable(GL_BLEND);
  glEnable(GL_MULTISAMPLE);
  glDisable(GL_DEPTH_TEST);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glPixelStorei(GL_PACK_ALIGNMENT, 1);
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, @GfxContext.MaxTextureSize);
  glGetIntegerv(GL_SAMPLES, @GfxContext.MsaaSamples);

  // text rendering

  FT_Init_FreeType(@GfxContext.FTLibrary);

  GfxContext.TextPixelRatio := Vector2(1, 1);
  GfxContext.TextScale := 1;
  GfxContext.TextColor := RGBA(0);
  GfxContext.TextShadowColor := RGBA(0);
  GfxContext.TextVerticalAlign := GFX_TOP;
end;

procedure GfxDestroyContext;
var
  i: Integer;
  Batch: ^TBatch;
begin
  Batch := @GfxContext.Batch;

  if Batch.VertexBuffer <> nil then
    GfxDeleteBuffer(Batch.VertexBuffer);

  for i := Low(Batch.Buffers) to High(Batch.Buffers) do
    FreeMem(Batch.Buffers[i].Data);

  Batch.Buffers := nil;
  Batch.Commands := nil;

  if GfxContext.WhiteTexture <> nil then
    GfxDeleteTexture(GfxContext.WhiteTexture);

  if GfxContext.DitheringTexture <> 0 then
    glDeleteTextures(1, @GfxContext.DitheringTexture);

  if GfxContext.TextStrSize > 0 then
  begin
    FreeMem(GfxContext.TextIndexStr);
    FreeMem(GfxContext.TextGlyphStr);
    FreeMem(GfxContext.TextComputedStr);
  end;

  if GfxContext.FTLibrary <> nil then
    FT_Done_FreeType(GfxContext.FTLibrary);

  FillChar(GfxContext, sizeof(GfxContext), 0);
end;

procedure GfxTarget(RenderTarget: TGfxTexture);
begin
  if Assigned(glBindFramebuffer) then
  begin
    if (RenderTarget <> nil) and (RenderTarget.FFboHandle <> 0) then
      glBindFramebuffer(GL_FRAMEBUFFER, RenderTarget.FFboHandle)
    else
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
  end;
end;

procedure GfxBlit(Src, Dst: TGfxTexture; SrcRect, DstRect: TRect; Filter: TGfxTextureFilter);
var
  FilterGl: GLenum;
begin
  FilterGl := GL_NEAREST;

  if Filter = GFX_LINEAR then
    FilterGl := GL_LINEAR;

  glBindFramebuffer(GL_READ_FRAMEBUFFER, Src.FFboHandle);

  if Dst <> nil then
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, Dst.FFboHandle)
  else
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

  glBlitFramebuffer(
    SrcRect.Left, SrcRect.Bottom, SrcRect.Right, SrcRect.Top,
    DstRect.Left, DstRect.Bottom, DstRect.Right, DstRect.Top,
    GL_COLOR_BUFFER_BIT, FilterGl
  );
end;

procedure GfxViewport(x, y, w, h: Integer);
begin
  glViewport(x, y, w, h);
end;

procedure GfxTransform(const t: TGfxMat3);
var
  m: array[0..15] of Single = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
begin
  if GfxContext.ShaderProgram <> 0 then
  begin
    glUniformMatrix3fv(GfxContext.MatrixLoc, 1, False, @t[0]);
  end
  else
  begin
    FillChar(m[0], sizeof(m), 0);

    m[0] := t[0]; m[4] := t[3]; m[ 8] := 0; m[12] := t[6];
    m[1] := t[1]; m[5] := t[4]; m[ 9] := 0; m[13] := t[7];
    m[2] := t[2]; m[6] := t[5]; m[10] := 1; m[14] :=    0;
    m[3] :=    0; m[7] :=    0; m[11] := 0; m[15] :=    1;

    glLoadMatrixf(@m[0]);
  end;
end;

procedure GfxClear(r, g, b, a: Byte);
begin
  glClearColor(r / 255, g / 255, b / 255, a / 255);
  glClear(GL_COLOR_BUFFER_BIT);
end;

procedure GfxClear(c: TGfxColor);
begin
  GfxClear(c.r, c.g, c.b, c.a);
end;

procedure GfxDraw(Buffer: TGfxVertexBuffer; Offset, Count: Integer);
begin
  SetupVertexAttributes(Buffer);
  glDrawArrays(GL_TRIANGLES, Offset, Count);
end;
{$push}
{$warn 4055 off}

procedure GfxDraw(Buffer: TGfxVertexBuffer; IndexBuffer: TGfxIndexBuffer; Offset,
  Count: Integer);
begin
  SetupVertexAttributes(Buffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IndexBuffer.FHandle);
  glDrawElements(GL_TRIANGLES, Count, GL_UNSIGNED_SHORT, Pointer(sizeof(Word) * Offset));
end;

procedure GfxDraw(Buffer: TGfxVertexBuffer; Cmds: PGfxDrawCommand; CmdCount: Integer);
var
  i: Integer;
begin
  SetupVertexAttributes(Buffer);

  for i := 1 to CmdCount do
  begin
    GfxBindTexture(Cmds.Texture);
    glDrawArrays(GL_TRIANGLES, Cmds.Offset, Cmds.Count);
    Inc(Cmds);
  end;
end;

procedure GfxDraw(Buffer: TGfxVertexBuffer; IndexBuffer: TGfxIndexBuffer;
  Cmds: PGfxDrawCommand; CmdCount: Integer);
var
  i: Integer;
begin
  SetupVertexAttributes(Buffer);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, IndexBuffer.FHandle);

  for i := 1 to CmdCount do
  begin
    GfxBindTexture(Cmds.Texture);
    glDrawElements(GL_TRIANGLES, Cmds.Count, GL_UNSIGNED_SHORT,
      Pointer(sizeof(Word) * Cmds.Offset));
    Inc(Cmds);
  end;
end;

{$pop}

procedure GfxPresent(Finish: Boolean);
begin
  if Finish then
    glFinish;

  SDL_GL_SwapWindow(GameWindow);
end;

procedure GfxSetMipmapBias(Bias: Single);
begin
  glTexEnvf(GL_TEXTURE_FILTER_CONTROL, GL_TEXTURE_LOD_BIAS, Bias);
end;

constructor TScreenshotThread.Create(Filename: string; w, h: Integer; Data: PByte);
begin
  inherited Create(True);
  FName := Filename;
  FWidth := w;
  FHeight := h;
  FData := Data;
end;

procedure TScreenshotThread.Execute();
var
  Src, Dst: PByte;
  Stride, y: Integer;
begin
  Stride := 4 * FWidth;

  Src := FData;
  Dst := FData;

  Inc(Src, Stride * FHeight);
  Inc(Dst, Stride * (FHeight - 1));

  for y := 1 to FHeight do
  begin
    Move(Src^, Dst^, Stride);
    Inc(Src, Stride);
    Dec(Dst, Stride);
  end;

  stbi_write_png(PAnsiChar(FName), FWidth, FHeight, 4, FData, Stride);
  FreeMem(FData);
end;

procedure GfxSaveScreen(Filename: string; x, y, w, h: Integer; Async: Boolean = True);
var
  Data, Src: PByte;
  ScreenThread: TScreenshotThread;
begin
  GetMem(Data, 2 * w * h * 4);

  Src := Data;
  Inc(Src, w * h * 4);
  glReadPixels(x, y, w, h, GL_RGBA, GL_UNSIGNED_BYTE, Src);

  ScreenThread := TScreenshotThread.Create(Filename, w, h, Data);
  ScreenThread.FreeOnTerminate := True;
  ScreenThread.Start;

  if not Async then
    ScreenThread.WaitFor;
end;

function ARGB(argb: LongWord): TGfxColor; overload;
begin
  Result := RGBA(argb, argb shr 24);
end;
// FIXME: Please find better way to do it.
{$IFDEF FPC}
function Min(a, b: Single): Single; overload;
begin
  if a < b then
   Result := a
 else
   Result := b;
end;
function Max(a, b: Single): Single; overload;
begin
  if a > b then
   Result := a
 else
   Result := b;
end;
{$ENDIF}
function RGBA(r, g, b, a: Byte): TGfxColor;
begin
  Result.r := r;
  Result.g := g;
  Result.b := b;
  Result.a := a;
end;
function RGBA(r, g, b: Byte): TGfxColor;
begin
  Result.r := r;
  Result.g := g;
  Result.b := b;
  Result.a := 255;
end;
function RGBA(rgba: LongWord): TGfxColor;
begin
  Result.a := 255;
  Result.r := (rgba and $00FF0000) shr 16;
  Result.g := (rgba and $0000FF00) shr 8;
  Result.b := (rgba and $000000FF);
end;

function RGBA(r, g, b: Byte; a: Extended): TGfxColor; overload;
begin
  Result.r := r;
  Result.g := g;
  Result.b := b;
  Result.a := Byte(Trunc(a));
end;

function RGBA(rgb: LongWord; a: Single): TGfxColor; overload;
begin
  Result.r := (rgb and $FF0000) shr 16;
  Result.g := (rgb and $00FF00) shr 8;
  Result.b := (rgb and $0000FF);
  Result.a := Byte(Trunc(a));
end;

function GfxVertex(x, y, u, v: Single; c: TGfxColor): TGfxVertex;
begin
  Result.x := x;
  Result.y := y;
  Result.u := u;
  Result.v := v;
  Result.Color := c;
end;

procedure GfxBindTexture(Texture: TGfxTexture);
begin
  if Texture <> nil then
    glBindTexture(GL_TEXTURE_2D, Texture.FHandle)
  else
    glBindTexture(GL_TEXTURE_2D, GfxContext.WhiteTexture.FHandle);
end;

function GfxCreateTexture(w, h: Integer; c: Integer = 4; Data: PByte = 0): TGfxTexture;
begin
  Result := TGfxTexture.Create(w, h, c, False, False, Data);
end;

function GfxCreateRenderTarget(w, h: Integer; c: Integer = 4; Msaa: Boolean = False): TGfxTexture;
begin
  Result := nil;

  if GfxFramebufferSupported then
    Result := TGfxTexture.Create(w, h, c, True, Msaa, nil);
end;

procedure GfxUpdateTexture(Texture: TGfxTexture; x, y, w, h: Integer; Data: PByte);
begin
  Texture.Update(x, y, w, h, Data);
end;

procedure GfxTextureWrap(Texture: TGfxTexture; s, t: TGfxTextureWrap);
begin
  Texture.SetWrap(s, t);
end;

procedure GfxTextureFilter(Texture: TGfxTexture; Min, Mag: TGfxTextureFilter);
begin
  Texture.SetFilter(Min, Mag);
end;

procedure GfxGenerateMipmap(Texture: TGfxTexture);
const
  F: array[1..4] of Integer = (GL_ALPHA, GL_LUMINANCE_ALPHA, GL_RGB, GL_RGBA);
begin
  if Texture.FHandle = 0 then
    Exit;

  glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
  glBindTexture(GL_TEXTURE_2D, Texture.FHandle);
  glEnable(GL_TEXTURE_2D);  // ati driver fuckery

  if Assigned(glGenerateMipmap) then
  begin
    glGenerateMipmap(GL_TEXTURE_2D);
  end
  else
  begin
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GLint(GL_TRUE));
    glTexSubImage2D(GL_TEXTURE_2D, 0, Texture.FPixel.x, Texture.FPixel.y, 1, 1,
      F[Texture.FComponents], GL_UNSIGNED_BYTE, @Texture.FPixel.Color);
    glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GLint(GL_FALSE));
  end;
end;

procedure GfxDeleteTexture(var Texture: TGfxTexture);
begin
  FreeAndNil(Texture);
end;

procedure PremultiplyColor(v: PGfxVertex; n: Integer);
var
  i: Integer;
  a: Single;
begin
  for i := 0 to n - 1 do
  begin
    a := v.Color.a / 255;
    v.Color.r := Round(v.Color.r * a);
    v.Color.g := Round(v.Color.g * a);
    v.Color.b := Round(v.Color.b * a);
    Inc(v);
  end;
end;

function GfxCreateBuffer(Capacity: Integer; Static: Boolean = False;
  Data: PGfxVertex = nil): TGfxVertexBuffer;
begin
  if (Data <> nil) and (GfxContext.ShaderProgram = 0) then
    PremultiplyColor(Data, Capacity);

  Result := TGfxVertexBuffer.Create(Capacity, Static, Data);
end;

procedure GfxUpdateBuffer(b: TGfxVertexBuffer; i, n: Integer; Data: PGfxVertex);
begin
  if GfxContext.ShaderProgram = 0 then
    PremultiplyColor(Data, n);

  b.Update(i, n, Data);
end;

procedure GfxDeleteBuffer(var b: TGfxVertexBuffer);
begin
  FreeAndNil(b);
end;

function GfxCreateIndexBuffer(Capacity: Integer; Static: Boolean = False;
  Data: System.PWord = nil): TGfxIndexBuffer;
begin
  Result := TGfxIndexBuffer.Create(Capacity, Static, Data);
end;

procedure GfxUpdateIndexBuffer(b: TGfxIndexBuffer; i, n: Integer; Data: System.PWord);
begin
  b.Update(i, n, Data);
end;

procedure GfxDeleteIndexBuffer(var b: TGfxIndexBuffer);
begin
  FreeAndNil(b);
end;

procedure GfxBegin;
var
  i: Integer;
  Batch: ^TBatch;
begin
  Batch := @GfxContext.Batch;

  if Length(Batch.Buffers) = 0 then
  begin
    SetLength(Batch.Buffers, 1);
    Batch.Buffers[0].Size := 0;
    Batch.Buffers[0].Capacity := 6 * BATCH_MIN;
    GetMem(Batch.Buffers[0].Data, Batch.Buffers[0].Capacity * sizeof(TGfxVertex));
  end
  else if Length(Batch.Buffers) > 1 then
  begin
    for i := Low(Batch.Buffers) to High(Batch.Buffers) - 1 do
      FreeMem(Batch.Buffers[i].Data);

    Batch.Buffers[0] := Batch.Buffers[High(Batch.Buffers)];
    SetLength(Batch.Buffers, 1);
  end;

  Batch.Buffers[0].Size := 0;
  Batch.CommandsSize := 0;
end;

procedure GfxEnd;
var
  i, n, Total: Integer;
  Batch: ^TBatch;
begin
  Batch := @GfxContext.Batch;
  Total := 0;
  n := Batch.CommandsSize;

  if n > 0 then
    Total := Batch.Commands[n - 1].Offset + Batch.Commands[n - 1].Count;

  if Total = 0 then
    Exit;

  if Batch.VertexBuffer = nil then
  begin
    n := 1;

    while n < Total do
      n := 2 * n;

    Batch.VertexBuffer := GfxCreateBuffer(Max(n, 6 * BATCH_MIN));
  end
  else if Batch.VertexBuffer.Capacity < Total then
  begin
    n := Batch.VertexBuffer.Capacity;

    while n < Total do
      n := 2 * n;

    GfxDeleteBuffer(Batch.VertexBuffer);
    Batch.VertexBuffer := GfxCreateBuffer(n);
  end;

  n := 0;

  for i := Low(Batch.Buffers) to High(Batch.Buffers) do
  begin
    GfxUpdateBuffer(Batch.VertexBuffer, n, Batch.Buffers[i].Size, Batch.Buffers[i].Data);
    Inc(n, Batch.Buffers[i].Size);
  end;

  GfxDraw(Batch.VertexBuffer, @Batch.Commands[0], Batch.CommandsSize);
end;

procedure GfxDrawQuad(Texture: TGfxTexture; const Vertices: array of TGfxVertex);
var
  b: ^TBatch;
  Buf: ^TBatchBuffer;
  v: PGfxVertex;
  CurTex: TGfxTexture;
  n: Integer;
begin
  b := @GfxContext.Batch;

  // update commands list

  CurTex := nil;
  n := b.CommandsSize;

  if n > 0 then
    CurTex := b.Commands[n - 1].Texture;

  if Texture = nil then
    Texture := GfxContext.WhiteTexture;

  if CurTex <> Texture then
  begin
    if Length(b.Commands) < (n + 1) then
      SetLength(b.Commands, Max(2 * Length(b.Commands), 32));

    b.Commands[n].Texture := Texture;
    b.Commands[n].Offset := 0;
    b.Commands[n].Count := 0;

    if n > 0 then
      b.Commands[n].Offset := b.Commands[n - 1].Offset + b.Commands[n - 1].Count;

    Inc(b.CommandsSize);
    n := b.CommandsSize;
  end;

  Inc(b.Commands[n - 1].Count, 6);

  // update buffer

  n := Length(b.Buffers);
  Buf := @b.Buffers[n - 1];

  if (Buf.Size + 6) > Buf.Capacity then
  begin
    Inc(n);
    SetLength(b.Buffers, n);
    Buf := @b.Buffers[n - 1];
    Buf.Size := 0;
    Buf.Capacity := 2 * b.Buffers[n - 2].Capacity;
    GetMem(Buf.Data, Buf.Capacity * sizeof(TGfxVertex));
  end;

  v := Buf.Data;
  Inc(v, Buf.Size);

  v^ := Vertices[0]; Inc(v);
  v^ := Vertices[1]; Inc(v);
  v^ := Vertices[2]; Inc(v);
  v^ := Vertices[2]; Inc(v);
  v^ := Vertices[3]; Inc(v);
  v^ := Vertices[0];

  Inc(Buf.Size, 6);
end;

procedure GfxDrawQuad(Texture: TGfxTexture; const a, b, c, d: TGfxVertex);
var
  v: array[0..3] of TGfxVertex;
begin
  v[0] := a;
  v[1] := b;
  v[2] := c;
  v[3] := d;

  GfxDrawQuad(Texture, v);
end;

procedure GfxSpriteVertices(s: PGfxSprite; x, y, w, h, sx, sy, cx, cy, r: Single;
  Color: TGfxColor; v: PGfxVertex);
var
  m: TGfxMat3;
  p: TVector2;
begin
  m := GfxMat3Transform(x, y, sx * s.Scale, sy * s.Scale, cx, cy, r);

  p := GfxMat3Mul(m, 0, 0);
  v.x := p.x;
  v.y := p.y;
  v.u := s.TexCoords.Left;
  v.v := s.TexCoords.Top;
  v.Color := Color;

  Inc(v);

  p := GfxMat3Mul(m, w, 0);
  v.x := p.x;
  v.y := p.y;
  v.u := s.TexCoords.Right;
  v.v := s.TexCoords.Top;
  v.Color := Color;

  Inc(v);

  p := GfxMat3Mul(m, w, h);
  v.x := p.x;
  v.y := p.y;
  v.u := s.TexCoords.Right;
  v.v := s.TexCoords.Bottom;
  v.Color := Color;

  Inc(v);

  p := GfxMat3Mul(m, 0, h);
  v.x := p.x;
  v.y := p.y;
  v.u := s.TexCoords.Left;
  v.v := s.TexCoords.Bottom;
  v.Color := Color;
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single);
begin
  GfxDrawSprite(s, x, y, 1, 1, 0, 0, 0, RGBA($FFFFFF));
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single);
begin
  GfxDrawSprite(s, x, y, scale, scale, 0, 0, 0, RGBA($FFFFFF));
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single);
begin
  GfxDrawSprite(s, x, y, sx, sy, 0, 0, 0, RGBA($FFFFFF));
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single);
begin
  GfxDrawSprite(s, x, y, 1, 1, rx, ry, r, RGBA($FFFFFF));
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single);
begin
  GfxDrawSprite(s, x, y, sx, sy, rx, ry, r, RGBA($FFFFFF));
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, 1, 1, 0, 0, 0, RGBA($FFFFFF), rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, scale, scale, 0, 0, 0, RGBA($FFFFFF), rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, sx, sy, 0, 0, 0, RGBA($FFFFFF), rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, 1, 1, rx, ry, r, RGBA($FFFFFF), rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, sx, sy, rx, ry, r, RGBA($FFFFFF), rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single; Color: TGfxColor);
begin
  GfxDrawSprite(s, x, y, 1, 1, 0, 0, 0, Color);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single; Color: TGfxColor);
begin
  GfxDrawSprite(s, x, y, scale, scale, 0, 0, 0, Color);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single; Color: TGfxColor);
begin
  GfxDrawSprite(s, x, y, sx, sy, 0, 0, 0, Color);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single; Color: TGfxColor);
begin
  GfxDrawSprite(s, x, y, 1, 1, rx, ry, r, Color);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y: Single; Color: TGfxColor; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, 1, 1, 0, 0, 0, Color, rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, scale: Single; Color: TGfxColor; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, scale, scale, 0, 0, 0, Color, rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy: Single; Color: TGfxColor; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, sx, sy, 0, 0, 0, Color, rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, rx, ry, r: Single; Color: TGfxColor; rc: TGfxRect);
begin
  GfxDrawSprite(s, x, y, 1, 1, rx, ry, r, Color, rc);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single; Color: TGfxColor);
var
  v: array[0..3] of TGfxVertex;
begin
  GfxSpriteVertices(s, x, y, s.Width, s.Height, sx, sy, rx, ry, -r, Color, @v[0]);
  GfxDrawQuad(s.Texture, v);
end;

procedure GfxDrawSprite(s: PGfxSprite; x, y, sx, sy, rx, ry, r: Single; Color: TGfxColor;
  rc: TGfxRect);
var
  w, h: Single;
  v: array[0..3] of TGfxVertex;
  Rect: TGfxRect;
  tc: PGfxRect;
begin
  w := Min(rc.Right - rc.Left, s.Width);
  h := Min(rc.Bottom - rc.Top, s.Height);
  tc := @s.TexCoords;

  GfxSpriteVertices(s, x, y, w, h, sx, sy, rx, ry, -r, Color, @v[0]);

  Rect.Left   := (s.x + rc.Left) / s.Texture.Width;
  Rect.Top    := (s.y + rc.Top) / s.Texture.Height;
  Rect.Right  := (s.x + rc.Right) / s.Texture.Width;
  Rect.Bottom := (s.y + rc.Bottom) / s.Texture.Height;

  Rect.Left   := Max(Min(Rect.Left, tc.Right), tc.Left);
  Rect.Top    := Max(Min(Rect.Top, tc.Bottom), tc.Top);
  Rect.Right  := Max(Min(Rect.Right, tc.Right), tc.Left);
  Rect.Bottom := Max(Min(Rect.Bottom, tc.Bottom), tc.Top);

  v[0].u := Rect.Left;   v[0].v := Rect.Top;
  v[1].u := Rect.Right;  v[1].v := Rect.Top;
  v[2].u := Rect.Right;  v[2].v := Rect.Bottom;
  v[3].u := Rect.Left;   v[3].v := Rect.Bottom;

  GfxDrawQuad(s.Texture, v);
end;

{******************************************************************************}
{*                              Font (internal)                               *}
{******************************************************************************}

procedure AddFontPage(f: PFont);
begin
  FillChar(f.Buffer^, 2 * f.Width * f.Height, 0);

  SetLength(f.Pages, Length(f.Pages) + 1);
  f.Pages[High(f.Pages)] := GfxCreateTexture(f.Width, f.Height, 2, f.Buffer);
  GfxTextureFilter(f.Pages[High(f.Pages)], GFX_NEAREST, GFX_NEAREST);

  f.NodesSize := 1;
  f.Nodes[0].x := 1;
  f.Nodes[0].y := 1;
  f.Nodes[0].w := f.Width - 1;
end;

procedure RequestFontSize(f: PFont; FontSize, Stretch: Integer);
var
  FontSizef: Single;
  SizeReq: FT_Size_RequestRec;
begin
  FontSizef := (FontSize / 1000) * (96 / 72);

  SizeReq.typ := FT_SIZE_REQUEST_TYPE_NOMINAL;
  SizeReq.width := Round(64 * FontSizef * (Stretch / 1000));
  SizeReq.height := Round(64 * FontSizef);
  SizeReq.horiResolution := 0;
  SizeReq.vertResolution := 0;

  FT_Request_Size(f.Handle, @SizeReq);
end;

function AddGlyphTable(f: PFont; FontSize, Stretch: Integer;
  Flags: LongWord): Integer;
var
  i: Integer;
begin
  i := Length(f.Tables);
  SetLength(f.Tables, i + 1);

  f.Tables[i].FontSize := FontSize;
  f.Tables[i].Stretch := Stretch;
  f.Tables[i].Flags := Flags;
  f.Tables[i].VSpace := f.Handle.size.metrics.height / 64;
  f.Tables[i].Ascent := Abs(f.Handle.size.metrics.ascender) / 64;
  f.Tables[i].Descent := Abs(f.Handle.size.metrics.descender) / 64;
  f.Tables[i].Size := 0;
  f.Tables[i].Capacity := GLYPH_POOL_SIZE;

  GetMem(f.Tables[i].Glyphs, sizeof(PGlyph) * GLYPH_POOL_SIZE);

  Result := i;
end;

function FindGlyphTable(f: PFont; FontSize, Stretch: Integer;
  Flags: LongWord): Integer;
begin
  RequestFontSize(f, FontSize, Stretch);
  Result := 0;
  for Result := 0 to High(f.Tables) do
  begin
    if (f.Tables[Result].FontSize = FontSize) and
      (f.Tables[Result].Stretch = Stretch) and
      (f.Tables[Result].Flags = Flags) then
      Exit;
  end;

  Result := AddGlyphTable(f, FontSize, Stretch, Flags);
end;

procedure InsertNode(f: PFont; i, x, y, w: Integer);
begin
  if f.NodesSize = Length(f.Nodes) then
    SetLength(f.Nodes, 2 * Length(f.Nodes));

  Move(f.Nodes[i], f.Nodes[i + 1], (f.NodesSize - i) * sizeof(TFontNode));
  Inc(f.NodesSize);

  f.Nodes[i].x := x;
  f.Nodes[i].y := y;
  f.Nodes[i].w := w;
end;

procedure RemoveNode(f: PFont; i: Integer);
begin
  Dec(f.NodesSize);
  Move(f.Nodes[i + 1], f.Nodes[i], (f.NodesSize - i) * sizeof(TFontNode));
end;

function RegionFits(f: PFont; i, w, h: Integer; var y: Integer): Boolean;
var
  x, wLeft: Integer;
begin
  Result := False;
  x := f.Nodes[i].x;

  if (x + w) > f.Width then
    Exit;

  y := f.Nodes[i].y;
  wLeft := w;

  while wLeft > 0 do
  begin
    if f.Nodes[i].y > y then
      y := f.Nodes[i].y;

    if (y + h) > f.Height then
      Exit;

    Dec(wLeft, f.Nodes[i].w);
    Inc(i);
  end;

  Result := True;
end;

function FindRegion(f: PFont; w, h: Integer; var xout, yout: Integer): Boolean;
var
  y: Integer = 0;
  i, iBest, wBest, hBest, Shrink: Integer;
  Node, Prev: PFontNode;
begin
  Result := False;
  xout := 0;
  yout := 0;
  iBest := -1;
  wBest := MaxInt;
  hBest := MaxInt;

  for i := 0 to f.NodesSize - 1 do
  begin
    if RegionFits(f, i, w, h, y) then
    begin
      if ((y + h) < hBest) or (((y + h) = hBest) and (f.Nodes[i].w < wBest)) then
      begin
        iBest := i;
        wBest := f.Nodes[i].w;
        hBest := y + h;
        xout := f.Nodes[i].x;
        yout := y;
      end;
    end;
  end;

  if iBest = -1 then
    Exit;

  InsertNode(f, iBest, xout, yout + h, w);

  i := iBest + 1;

  while i < f.NodesSize do
  begin
    Node := @f.Nodes[i];
    Prev := @f.Nodes[i - 1];

    if Node.x >= (Prev.x + Prev.w) then
      Break;

    Shrink := Prev.x + Prev.w - Node.x;
    Inc(Node.x, Shrink);
    Dec(Node.w, Shrink);

    if Node.w > 0 then
      Break;

    RemoveNode(f, i);
  end;

  i := 0;

  while i < (f.NodesSize - 1) do
  begin
    if f.Nodes[i].y = f.Nodes[i + 1].y then
    begin
      Inc(f.Nodes[i].w, f.Nodes[i + 1].w);
      RemoveNode(f, i + 1);
      Dec(i);
    end;

    Inc(i);
  end;

  Result := True;
end;

function AllocGlyph(f: PFont): PGlyph;
begin
  if f.PoolIndex = GLYPH_POOL_SIZE then
  begin
    f.PoolIndex := 0;
    SetLength(f.Pool, Length(f.Pool) + 1);
    f.Pool[High(f.Pool)] := f.Pool[0];
    GetMem(f.Pool[0], GLYPH_POOL_SIZE * sizeof(TGlyph));
  end;

  Result := f.Pool[0];
  Inc(Result, f.PoolIndex);
  Inc(f.PoolIndex);
end;

procedure LoadGlyphBitmap(f: PFont; Table: PGlyphTable; Glyph: PGlyph);
var
  Pixel: Byte;
  SrcRow, Src, Dst: PByte;
  i, j, k, w, h, wb, wr, BufSize: Integer;
  x: Integer = 0;
  y: Integer = 0;
begin
  w := Round(Glyph.Bounds.Right - Glyph.Bounds.Left);
  h := Round(Glyph.Bounds.Bottom - Glyph.Bounds.Top);
  BufSize := 2 * w * h;

  if not FindRegion(f, w + 1, h + 1, x, y) then
  begin
    AddFontPage(f);
    FindRegion(f, w + 1, h + 1, x, y);
  end;

  Glyph.Page := High(f.Pages);
  Glyph.TexCoords.Left   := x / f.Width;
  Glyph.TexCoords.Top    := y / f.Height;
  Glyph.TexCoords.Right  := (x + w) / f.Width;
  Glyph.TexCoords.Bottom := (y + h) / f.Height;

  if f.BufferSize < BufSize then
  begin
    FreeMem(f.Buffer);
    f.BufferSize := Npot(BufSize);
    GetMem(f.Buffer, f.BufferSize);
  end;

  SrcRow := f.Handle.glyph.bitmap.buffer;
  Dst := f.Buffer;

  if (Table.Flags and GFX_MONOCHROME) = 0 then
  begin
    for j := 1 to h do
    begin
      Src := SrcRow;

      for i := 1 to w do
      begin
        Dst^ := Src^; Inc(Dst);
        Dst^ := Src^; Inc(Dst);
        Inc(Src);
      end;

      Inc(SrcRow, f.Handle.glyph.bitmap.pitch);
    end;
  end
  else
  begin
    wb := w div 8;
    wr := 8 - (w mod 8);

    for j := 1 to h do
    begin
      Src := SrcRow;

      // unpack full bytes
      for i := 1 to wb do
      begin
        for k := 7 downto 0 do
        begin
          Pixel := $FF and ($FF00 shr (((Src^ shr k) and 1) shl 3));
          Dst^ := Pixel; Inc(Dst);
          Dst^ := Pixel; Inc(Dst);
        end;

        Inc(Src);
      end;

      // unpack bits from leftover byte if any
      for k := 7 downto wr do
      begin
        Pixel := $FF and ($FF00 shr (((Src^ shr k) and 1) shl 3));
        Dst^ := Pixel; Inc(Dst);
        Dst^ := Pixel; Inc(Dst);
      end;

      Inc(SrcRow, f.Handle.glyph.bitmap.pitch);
    end;
  end;

  GfxUpdateTexture(f.Pages[Glyph.Page], x, y, w, h, f.Buffer);
end;

function LoadGlyph(f: PFont; Table: PGlyphTable; GlyphIndex: Integer): PGlyph;
var
  w, h: Integer;
begin
  if (Table.Flags and GFX_MONOCHROME) = 0 then
    FT_Load_Glyph(f.Handle, GlyphIndex, FT_LOAD_RENDER or FT_LOAD_FORCE_AUTOHINT)
  else
    FT_Load_Glyph(f.Handle, GlyphIndex, FT_LOAD_RENDER or FT_LOAD_TARGET_MONO);

  w := f.Handle.glyph.bitmap.width;
  h := f.Handle.glyph.bitmap.rows;

  Result                 :=  AllocGlyph(f);
  Result.GlyphIndex      :=  GlyphIndex;
  Result.Page            :=  -2;
  Result.Advance         :=  f.Handle.glyph.advance.x / 64;
  Result.Bounds.Left     :=  f.Handle.glyph.bitmap_left;
  Result.Bounds.Top      := -f.Handle.glyph.bitmap_top;
  Result.Bounds.Right    :=  Result.Bounds.Left + w;
  Result.Bounds.Bottom   :=  Result.Bounds.Top + h;

  if (w = 0) or (h = 0) or (w > (f.Width - 2)) or (h > (f.Height - 2)) then
  begin
    Result.Page := -1;
    FillChar(Result.Bounds, sizeof(TGfxRect), 0);
  end
  else
  begin
    LoadGlyphBitmap(f, Table, Result);
  end;
end;

procedure InsertGlyph(Table: PGlyphTable; Index: Integer; Glyph: PGlyph);
var
  Glyphs, Src, Dst: PPGlyph;
begin
  if Table.Capacity = Table.Size then
  begin
    GetMem(Glyphs, 2 * sizeof(PGlyph) * Table.Capacity);
    Move(Table.Glyphs^, Glyphs^, sizeof(PGlyph) * Table.Capacity);
    FreeMem(Table.Glyphs);
    Table.Glyphs := Glyphs;
    Table.Capacity := 2 * Table.Capacity;
  end;

  Src := Table.Glyphs;
  Dst := Table.Glyphs;
  Inc(Src, Index);
  Inc(Dst, Index + 1);
  Move(Src^, Dst^, (Table.Size - Index) * sizeof(PGlyph));
  Inc(Table.Size);
  Src^ := Glyph;
end;

function FindGlyph(f: PFont; Table: PGlyphTable; GlyphIndex: Integer): PGlyph;
var
  lo, hi, mi: Integer;
  g: PPGlyph;
begin
  lo := 0;
  hi := Table.Size;

  while lo < hi do
  begin
    mi := lo + ((hi - lo) shr 1);
    g := Table.Glyphs;
    Inc(g, mi);

    if GlyphIndex < g^^.GlyphIndex then
      hi := mi
    else if GlyphIndex > g^^.GlyphIndex then
      lo := mi + 1
    else
    begin
      Result := g^;
      Exit;
    end;
  end;

  Result := LoadGlyph(f, Table, GlyphIndex);
  InsertGlyph(Table, lo, Result);
end;

function IsWhitespace(ch: WideChar): Boolean;
begin
  Result := (ch = #10) or (ch = #13);
end;

procedure StrToGlyphs(f: PFont; Table: PGlyphTable; const s: WideString);
var
  i: Integer;
  IndexStr: PInteger;
  GlyphStr: PPGlyph;
begin
  if GfxContext.TextStrSize < Length(s) then
  begin
    if GfxContext.TextStrSize > 0 then
    begin
      FreeMem(GfxContext.TextIndexStr);
      FreeMem(GfxContext.TextGlyphStr);
      FreeMem(GfxContext.TextComputedStr);
    end;

    i := Npot(Length(s));

    GfxContext.TextStrSize := i;
    GfxContext.TextComputedCount := 0;
    GetMem(GfxContext.TextIndexStr, i * sizeof(Integer));
    GetMem(GfxContext.TextGlyphStr, i * sizeof(PGlyph));
    GetMem(GfxContext.TextComputedStr, i * sizeof(TComputedGlyph));
  end;

  IndexStr := GfxContext.TextIndexStr;

  for i := 1 to Length(s) do
  begin
    IndexStr^ := 0;

    if not IsWhitespace(s[i]) then
      IndexStr^ := FT_Get_Char_Index(f.Handle, FT_ULong(s[i]));

    Inc(IndexStr);
  end;

  IndexStr := GfxContext.TextIndexStr;
  GlyphStr := GfxContext.TextGlyphStr;

  for i := 1 to Length(s) do
  begin
    GlyphStr^ := nil;

    if not IsWhitespace(s[i]) then
      GlyphStr^ := FindGlyph(f, Table, IndexStr^);

    Inc(IndexStr);
    Inc(GlyphStr);
  end;
end;

procedure ComputeGlyphs(f: PFont; Table: PGlyphTable; const s: WideString);
var
  i, Prev: Integer;
  x, y, VSpace: Single;
  Kerning: FT_Vector;
  IndexStr: PInteger;
  GlyphStr: PPGlyph;
  Computed: PComputedGlyph;
begin
  StrToGlyphs(f, Table, s);

  GfxContext.TextComputedCount := 0;
  IndexStr := GfxContext.TextIndexStr;
  GlyphStr := GfxContext.TextGlyphStr;
  Computed := GfxContext.TextComputedStr;

  x := 0;
  y := 0;
  VSpace := Table.VSpace;
  Prev := -1;

  for i := 1 to Length(s) do
  begin
    if s[i] = #10 then
    begin
      x := 0;
      y := y + VSpace;
      Prev := -1;
    end
    else if (s[i] <> #13) and (GlyphStr^ <> nil) then
    begin
      if Prev <> -1 then
      begin
        FT_Get_Kerning(f.Handle, Prev, IndexStr^, 0, @Kerning);
        x := x + Kerning.x / 64;
      end;

      Prev := IndexStr^;
      Computed.x := x;
      Computed.y := y;
      Computed.Glyph := GlyphStr^;
      x := x + GlyphStr^.Advance;

      Inc(Computed);
      Inc(GfxContext.TextComputedCount);
    end;

    Inc(IndexStr);
    Inc(GlyphStr);
  end;
end;

procedure DrawGlyph(f: PFont; g: PGlyph; x, y: Single; Color: TGfxColor);
var
  v: array[0..3] of TGfxVertex;
  Pxl: TVector2;
begin
  Pxl := GfxContext.TextPixelRatio;
  Pxl.x := Pxl.x * GfxContext.TextScale;
  Pxl.y := Pxl.y * GfxContext.TextScale;

  v[0].x := x + Pxl.x * g.Bounds.Left;
  v[0].y := y + Pxl.y * g.Bounds.Top;
  v[0].u := g.TexCoords.Left;
  v[0].v := g.TexCoords.Top;
  v[0].Color := Color;

  v[1].x := x + Pxl.x * g.Bounds.Right;
  v[1].y := y + Pxl.y * g.Bounds.Top;
  v[1].u := g.TexCoords.Right;
  v[1].v := g.TexCoords.Top;
  v[1].Color := Color;

  v[2].x := x + Pxl.x * g.Bounds.Right;
  v[2].y := y + Pxl.y * g.Bounds.Bottom;
  v[2].u := g.TexCoords.Right;
  v[2].v := g.TexCoords.Bottom;
  v[2].Color := Color;

  v[3].x := x + Pxl.x * g.Bounds.Left;
  v[3].y := y + Pxl.y * g.Bounds.Bottom;
  v[3].u := g.TexCoords.Left;
  v[3].v := g.TexCoords.Bottom;
  v[3].Color := Color;

  GfxDrawQuad(f.Pages[g.Page], v);
end;

{******************************************************************************}
{*                               Font (public)                                *}
{******************************************************************************}

function GfxCreateFont(Filename: string; w: Integer = 512; h: Integer = 512): TGfxFont;
var
  f: PFont;
  FontHandle: FT_Face;
begin
  Result := nil;

  GfxLog('Loading font (' + Filename + ')');

  if FT_New_Face(GfxContext.FTLibrary, PAnsiChar(Filename), 0, @FontHandle) <> 0 then
  begin
    GfxLog('Failed to load font (' + Filename + ')');
    Exit;
  end;

  if FT_Select_Charmap(FontHandle, FT_ENCODING_UNICODE) <> 0 then
  begin
    GfxLog('Font doesn''t support unicode (' + Filename + ')');
    FT_Done_Face(FontHandle);
    Exit;
  end;

  New(f);

  f.Handle := FontHandle;
  f.Width := w;
  f.Height := h;

  f.BufferSize := 2 * w * h;
  GetMem(f.Buffer, f.BufferSize);

  f.PoolIndex := 0;
  SetLength(f.Pool, 1);
  GetMem(f.Pool[0], GLYPH_POOL_SIZE * sizeof(TGlyph));

  SetLength(f.Nodes, 32);
  f.NodesSize := 1;
  f.Nodes[0].x := 0;
  f.Nodes[0].y := h;
  f.Nodes[0].w := w;

  Result := f;
end;

procedure GfxDeleteFont(var Font: TGfxFont);
var
  i: Integer;
  f: PFont;
begin
  f := Font;

  if f.Handle <> nil then
    FT_Done_Face(f.Handle);

  if f.Buffer <> nil then
    FreeMem(f.Buffer);

  for i := 0 to High(f.Pages) do
    GfxDeleteTexture(f.Pages[i]);

  for i := 0 to High(f.Tables) do
    FreeMem(f.Tables[i].Glyphs);

  for i := 0 to High(f.Pool) do
    FreeMem(f.Pool[i]);

  Dispose(f);
  Font := nil;
end;

function GfxSetFont(Font: TGfxFont; FontSize: Single; Flags: LongWord;
  Stretch: Single = 1): Integer;
begin
  Result := FindGlyphTable(Font, Trunc(FontSize * 1000),
    Trunc(Stretch * 1000), Flags);

  GfxContext.Font := Font;
  GfxContext.GlyphTable := @PFont(Font).Tables[Result];
  GfxContext.TextComputedCount := 0;
end;

procedure GfxSetFontTable(Font: TGfxFont; TableIndex: Integer);
begin
  GfxContext.Font := Font;
  GfxContext.GlyphTable := @PFont(Font).Tables[TableIndex];
  GfxContext.TextComputedCount := 0;

  RequestFontSize(Font, GfxContext.GlyphTable.FontSize,
    GfxContext.GlyphTable.Stretch);
end;

procedure GfxTextPixelRatio(PixelRatio: TVector2);
begin
  GfxContext.TextPixelRatio := PixelRatio;
end;

procedure GfxTextScale(s: Single);
begin
  GfxContext.TextScale := s;
end;

procedure GfxTextColor(Color: TGfxColor);
begin
  GfxContext.TextColor := Color;
end;

procedure GfxTextShadow(dx, dy: Single; Color: TGfxColor);
begin
  GfxContext.TextShadowOffset.x := dx;
  GfxContext.TextShadowOffset.y := dy;
  GfxContext.TextShadowColor := Color;
end;

procedure GfxTextVerticalAlign(Align: TGfxVerticalAlign);
begin
  GfxContext.TextVerticalAlign := Align;
end;

function GfxTextMetrics: TGfxRect;
var
  Comp: PComputedGlyph;
  i: Integer;
  Pxl: TVector2;
begin
  Result := Default(TGfxRect);
  Comp := GfxContext.TextComputedStr;
  Pxl := GfxContext.TextPixelRatio;
  Pxl.x := Pxl.x * GfxContext.TextScale;
  Pxl.y := Pxl.y * GfxContext.TextScale;

  for i := 1 to GfxContext.TextComputedCount do
  begin
    Result.Left   := Min(Result.Left,   Pxl.x * (Comp.x + Comp.Glyph.Bounds.Left));
    Result.Right  := Max(Result.Right,  Pxl.x * (Comp.x + Comp.Glyph.Bounds.Right));
    Result.Top    := Min(Result.Top,    Pxl.y * (Comp.y + Comp.Glyph.Bounds.Top));
    Result.Bottom := Max(Result.Bottom, Pxl.y * (Comp.y + Comp.Glyph.Bounds.Bottom));
    Inc(Comp);
  end;
end;

function GfxTextMetrics(const Text: WideString): TGfxRect;
begin
  ComputeGlyphs(GfxContext.Font, GfxContext.GlyphTable, Text);
  Result := GfxTextMetrics;
end;

procedure GfxDrawText(x, y: Single);
var
  f: PFont;
  Table: PGlyphTable;
  Comp: PComputedGlyph;
  i: Integer;
  s, dx, dy: Single;
  p, Pxl: TVector2;
  TextColor, ShadowColor: TGfxColor;
begin
  f := GfxContext.Font;
  Table := GfxContext.GlyphTable;
  Comp := GfxContext.TextComputedStr;
  TextColor := GfxContext.TextColor;
  ShadowColor := GfxContext.TextShadowColor;
  ShadowColor.a := Trunc(ShadowColor.a * (TextColor.a / 255));
  Pxl := GfxContext.TextPixelRatio;
  s := GfxContext.TextScale;
  dx := GfxContext.TextShadowOffset.x * Pxl.x;
  dy := GfxContext.TextShadowOffset.y * Pxl.y;

  case GfxContext.TextVerticalAlign of
    GFX_TOP:    y := y + Pxl.y * Table.Ascent * s;
    GFX_BOTTOM: y := y - Pxl.y * Table.Descent * s;
    GFX_BASELINE: y := y;
  end;

  x := Pxl.x * Floor(x / Pxl.x);
  y := Pxl.y * Floor(y / Pxl.y);

  Pxl.x := Pxl.x * s;
  Pxl.y := Pxl.y * s;

  for i := 1 to GfxContext.TextComputedCount do
  begin
    if Comp.Glyph.Page >= 0 then
    begin
      p.x := x + Pxl.x * Comp.x;
      p.y := y + Pxl.y * Comp.y;

      if ShadowColor.a > 0 then
        DrawGlyph(f, Comp.Glyph, p.x + dx, p.y + dy, ShadowColor);

      DrawGlyph(f, Comp.Glyph, p.x, p.y, TextColor);
    end;

    Inc(Comp);
  end;
end;

procedure GfxDrawText(const Text: WideString; x, y: Single);
begin
  ComputeGlyphs(GfxContext.Font, GfxContext.GlyphTable, Text);
  GfxDrawText(x, y);
end;

procedure GfxDrawText(const Text: AnsiString; x, y: Single);
begin
  ComputeGlyphs(GfxContext.Font, GfxContext.GlyphTable, WideString(Text));
  GfxDrawText(x, y);
end;
{******************************************************************************}
{*                                   Matrix                                   *}
{******************************************************************************}

function GfxMat3Rot(r: Single): TGfxMat3;
var
  m: PGfxMat3;
  c, s: Single;
begin
  c := Cos(r);
  s := Sin(r);
  m := @Result;

  m[0] := c;  m[3] := -s;  m[6] := 0;
  m[1] := s;  m[4] :=  c;  m[7] := 0;
  m[2] := 0;  m[5] :=  0;  m[8] := 1;
end;

function GfxMat3Ortho(l, r, t, b: Single): TGfxMat3;
var
  w, h: Single;
begin
  w := r - l;
  h := t - b;

  Result[0] := 2 / w;  Result[3] :=     0;  Result[6] := -(r + l) / w;
  Result[1] :=     0;  Result[4] := 2 / h;  Result[7] := -(t + b) / h;
  Result[2] :=     0;  Result[5] :=     0;  Result[8] :=            1;
end;

function GfxMat3Transform(tx, ty, sx, sy, cx, cy, r: Single): TGfxMat3;
var
  m: PGfxMat3;
  c, s: Single;
begin
  c := Cos(r);
  s := Sin(r);

  m := @Result;  // m = T(tx,ty) * T(cx,cy) * R(r) * T(-cx,-cy) * S(sx,sy)

  m[0] := c * sx;  m[3] := -s * sy;  m[6] := tx + cy * s - c * cx + cx;
  m[1] := s * sx;  m[4] :=  c * sy;  m[7] := ty - cx * s - c * cy + cy;
  m[2] :=      0;  m[5] :=       0;  m[8] :=                         1;
end;

function GfxMat3Mul(const m: TGfxMat3; x, y: Single): TVector2;
begin
  Result.x := m[0] * x + m[3] * y + m[6];
  Result.y := m[1] * x + m[4] * y + m[7];
end;

{******************************************************************************}
{*                                 TGfxImage                                  *}
{******************************************************************************}

procedure ApplyColorKey(Data: PByte; w, h: Integer; ColorKey: TGfxColor);
var
  i: Integer;
  p: PByte;
  c: TGfxColor;
begin
  p := Data;

  for i := 0 to (w * h) - 1 do
  begin
    c.r := p^; Inc(p);
    c.g := p^; Inc(p);
    c.b := p^; Inc(p);
    c.a := p^;

    if c.rgba = ColorKey.rgba then
      p^ := 0;

    Inc(p);
  end;
end;

constructor TGfxImage.Create(Filename: string; ColorKey: TGfxColor);
var
  FileBuffer: PHYSFS_Buffer;
  i: Integer;
begin
  FileBuffer := PhysFS_readBuffer(PChar(Filename));
  FDelays := Nil;
  if Length(FileBuffer) > 0 then begin
    FData := stbi_xload_mem(@FileBuffer[0], Length(FileBuffer), @FWidth, @FHeight, @FNumFrames, @FDelays);

    if FNumFrames > 1 then begin
      for i := 0 to FNumFrames - 1 do begin
        FDelays[i] := FDelays[i] div 10;
      end;
    end;
  end else
    FData := nil;

  if FData <> nil then
  begin
    FComponents := 4;
    FLoadedFromFile := True;
    if (FNumFrames = 1) and (ColorKey.rgba <> 0) then
      ApplyColorKey(FData, FWidth, FHeight, ColorKey);
  end
  else
  begin
    FWidth := 0;
    FHeight := 0;
    FNumFrames := 0;
    GfxLog('Failed to load image ' + Filename);
  end;
end;

constructor TGfxImage.Create(Width, Height: Integer; Comp: Integer = 4);
begin
  GetMem(FData, Width * Height * Comp);
  FillChar(FData^, Width * Height * Comp, 0);
  FWidth := Width;
  FHeight := Height;
  FComponents := Comp;
  FNumFrames := 1;
  FDelays := Nil;
  FLoadedFromFile := False;
end;

destructor TGfxImage.Destroy;
begin
  if FLoadedFromFile then begin
    stbi_image_free(FData);
    stbi_image_free(FDelays);
  end else if FData <> nil then
    FreeMem(FData);

  inherited;
end;

function TGfxImage.GetImageData(Frame: Integer = 0): PByte;
begin
  Result := FData + (FWidth * FHeight * FComponents * Frame);
end;

function TGfxImage.GetFrameDelay(Frame: Integer = 0): Word;
begin
  if FNumFrames > 1 then
    Result := FDelays[Frame]
  else
    Result := 0;
end;

procedure TGfxImage.Update(x, y, w, h: Integer; Data: PByte; Frame: Integer = 0);
var
  Src, Dst: PByte;
  i, SrcLine, DstLine: Integer;
begin
  // - number of components same on both buffers or gtfo
  // - update within bounds or gtfo

  SrcLine := FComponents * w;
  DstLine := FComponents * FWidth;

  Src := Data;
  Dst := FData;

  Inc(Dst, (DstLine * FHeight) * Frame + (DstLine * y + x * FComponents));

  for i := 0 to h - 1 do
  begin
    Move(Src^, Dst^, SrcLine);
    Inc(Src, SrcLine);
    Inc(Dst, DstLine);
  end;
end;

procedure TGfxImage.Premultiply;
var
  p: PByte;
  i, j: Integer;
  a: Single;
begin
  if FComponents <> 4 then
    Exit;

  p := FData;

  for i := 1 to FNumFrames do
  begin
    for j := 1 to FWidth * FHeight do
    begin
      Inc(p, 3);
      a := p^ / 255;
      Dec(p, 3);

      p^ := Round(p^ * a); Inc(p);
      p^ := Round(p^ * a); Inc(p);
      p^ := Round(p^ * a); Inc(p, 2);
    end;
  end;
end;

procedure TGfxImage.Resize(w, h: Integer);
var
  i, Size: Integer;
  Data, Dst: PByte;
begin
  if FData = nil then
    Exit;

  Size := w * h * FComponents;
  GetMem(Data, FNumFrames * Size);

  Dst := Data;

  for i := 0 to FNumFrames - 1 do
  begin
    stbir_resize_uint8(GetImageData(i), FWidth, FHeight, 0,
      Dst, w, h, 0, FComponents);

    Inc(Dst, Size);
  end;

  if FLoadedFromFile then
    stbi_image_free(FData)
  else
    FreeMem(FData);

  FWidth := w;
  FHeight := h;
  FData := Data;
  FLoadedFromFile := False;
end;

{******************************************************************************}
{*                                TGfxTexture                                 *}
{******************************************************************************}

constructor TGfxTexture.Create(Width, Height: Integer; Comp: Integer; Rt, Msaa: Boolean; Data: PByte);
const
  F: array[1..4] of Integer = (GL_ALPHA, GL_LUMINANCE_ALPHA, GL_RGB, GL_RGBA);
begin
  FWidth := Width;
  FHeight := Height;
  FComponents := Comp;
  FFboHandle := 0;
  FSamples := 0;
  FPixel.x := 0;
  FPixel.y := 0;
  FPixel.Color.rgba := 0;

  glGenTextures(1, @FHandle);

  if Msaa and (GfxContext.MsaaSamples > 0) then
  begin
    FSamples := GfxContext.MsaaSamples;

    glBindTexture(GL_TEXTURE_2D_MULTISAMPLE, FHandle);
    glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, GfxContext.MsaaSamples,
      F[Comp], Width, Height, True);

    glGenFramebuffers(1, @FFboHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, FFboHandle);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
      GL_TEXTURE_2D_MULTISAMPLE, FHandle, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  end else
  begin
    glBindTexture(GL_TEXTURE_2D, FHandle);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, F[Comp], Width, Height, 0, F[Comp],
      GL_UNSIGNED_BYTE, Data);

    if Rt then
    begin
      glGenFramebuffers(1, @FFboHandle);
      glBindFramebuffer(GL_FRAMEBUFFER, FFboHandle);
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
        GL_TEXTURE_2D, FHandle, 0);
      glBindFramebuffer(GL_FRAMEBUFFER, 0);
    end;
  end;

  if Data <> nil then
    Move(Data^, FPixel.Color, Comp);
end;

destructor TGfxTexture.Destroy;
begin
  if FFboHandle <> 0 then
    glDeleteFramebuffers(1, @FFboHandle);

  if FHandle <> 0 then
    glDeleteTextures(1, @FHandle);

  inherited;
end;

procedure TGfxTexture.Update(x, y, w, h: Integer; Data: PByte);
const
  F: array[1..4] of Integer = (GL_ALPHA, GL_LUMINANCE_ALPHA, GL_RGB, GL_RGBA);
begin
  if FHandle = 0 then
    Exit;

  glBindTexture(GL_TEXTURE_2D, FHandle);
  glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, F[FComponents], GL_UNSIGNED_BYTE, Data);

  FPixel.x := x;
  FPixel.y := y;
  Move(Data^, FPixel.Color, FComponents);
end;

procedure TGfxTexture.SetWrap(s, t: TGfxTextureWrap);
begin
  if FHandle = 0 then
    Exit;

  glBindTexture(GL_TEXTURE_2D, FHandle);

  case s of
    GFX_CLAMP: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    GFX_REPEAT: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  end;

  case t of
    GFX_CLAMP: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    GFX_REPEAT: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  end;
end;

procedure TGfxTexture.SetFilter(Min, Mag: TGfxTextureFilter);
begin
  if FHandle = 0 then
    Exit;

  glBindTexture(GL_TEXTURE_2D, FHandle);

  case Min of
    GFX_LINEAR: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    GFX_NEAREST: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    GFX_MIPMAP_LINEAR: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_LINEAR_MIPMAP_LINEAR);
    GFX_MIPMAP_NEAREST: glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST_MIPMAP_NEAREST);
  END;

  case Mag of
    GFX_LINEAR, GFX_MIPMAP_LINEAR:
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    GFX_NEAREST, GFX_MIPMAP_NEAREST:
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  END;
end;

{******************************************************************************}
{*                              TGfxVertexBuffer                              *}
{******************************************************************************}

constructor TGfxVertexBuffer.Create(Cap: Integer; Static: Boolean; Data: PGfxVertex);
var
  Hint: GLenum;
begin
  FCapacity := Cap;

  if Static then
    Hint := GL_STATIC_DRAW
  else
    Hint := GL_STREAM_DRAW;

  glGenBuffers(1, @FHandle);
  glBindBuffer(GL_ARRAY_BUFFER, FHandle);
  glBufferData(GL_ARRAY_BUFFER, sizeof(TGfxVertex) * Cap, Data, Hint);
end;

destructor TGfxVertexBuffer.Destroy;
begin
  if FHandle <> 0 then
    glDeleteBuffers(1, @FHandle);

  inherited;
end;

procedure TGfxVertexBuffer.Update(Offset, Count: Integer; Data: PGfxVertex);
const
  SIZE = sizeof(TGfxVertex);
begin
  glBindBuffer(GL_ARRAY_BUFFER, FHandle);
  glBufferSubData(GL_ARRAY_BUFFER, SIZE * Offset, SIZE * Count, Data);
end;

{******************************************************************************}
{*                              TGfxIndexBuffer                               *}
{******************************************************************************}

constructor TGfxIndexBuffer.Create(Cap: Integer; Static: Boolean; Data: System.PWord);
var
  Hint: GLenum;
begin
  FCapacity := Cap;

  if Static then
    Hint := GL_STATIC_DRAW
  else
    Hint := GL_STREAM_DRAW;

  glGenBuffers(1, @FHandle);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, FHandle);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Word) * Cap, Data, Hint);
end;

destructor TGfxIndexBuffer.Destroy;
begin
  if FHandle <> 0 then
    glDeleteBuffers(1, @FHandle);

  inherited;
end;

procedure TGfxIndexBuffer.Update(Offset, Count: Integer; Data: System.PWord);
const
  SIZE = sizeof(Word);
begin
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, FHandle);
  glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, SIZE * Offset, SIZE * Count, Data);
end;

{******************************************************************************}
{*                              TGfxSpritesheet                               *}
{******************************************************************************}

const
  PADDING = 8;

type
  TTextureArray = array of TGfxTexture;

  PRectInfo = ^TRectInfo;
  TRectInfo = record
    Image: Integer;
    Frame: Integer;
    Texture: Integer;
  end;

  TSheetLoadData = record
    AtlasImages: array of TGfxImage;
    Images: array of TGfxImage;
    ImagesKey: array of TGfxColor;
    ImagesPath: array of string;
    ImagesTargetSize: array of TVector2;
    ImagesTargetScale: array of Single;
    ImageIndex: Integer;
    Rects: TBPRectArray;
    RectInfo: array of TRectInfo;
    LoadingStage: Integer;
    LoadingIndex: Integer;
    AdditionalFrames: Integer;
  end;

constructor TGfxSpritesheet.Create(Count: Integer);
var
  ld: ^TSheetLoadData;
begin
  SetLength(FSprites, Count);
  FillChar(FSprites[0], sizeof(TGfxSprite) * Count, 0);

  New(ld);
  FLoadData := ld;

  ld.ImageIndex := 0;
  ld.LoadingStage := 0;
  ld.LoadingIndex := 0;
  ld.AdditionalFrames := 0;
  SetLength(ld.Images, Count);
  SetLength(ld.ImagesKey, Count);
  SetLength(ld.ImagesPath, Count);
  SetLength(ld.ImagesTargetSize, Count);
  SetLength(ld.ImagesTargetScale, Count);
end;

destructor TGfxSpritesheet.Destroy;
var
  i: Integer;
begin
  CleanUp;

  for i := Low(FTextures) to High(FTextures) do
  begin
    if FTextures[i] <> nil then
      FreeAndNil(FTextures[i]);
  end;

  inherited;
end;

function TGfxSpritesheet.GetSprite(Index: Integer): PGfxSprite;
begin
  Result := @FSprites[Index];
end;

function TGfxSpritesheet.GetTexture(Index: Integer): TGfxTexture;
begin
  Result := FTextures[Index];
end;

function TGfxSpritesheet.GetSpriteCount: Integer;
begin
  Result := Length(FSprites);
end;

function TGfxSpritesheet.GetTextureCount: Integer;
begin
  Result := Length(FTextures);
end;

function TGfxSpritesheet.IsLoading: Boolean;
var
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;

  if ld = nil then
    Result := False
  else
    Result := ld.LoadingStage > 0;
end;

procedure TGfxSpritesheet.AddImage(Path: string; ColorKey: TGfxColor;
  TargetScale: Single);
var
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;

  if ld.ImageIndex < Length(ld.Images) then
  begin
    ld.ImagesPath[ld.ImageIndex] := Path;
    ld.ImagesKey[ld.ImageIndex] := ColorKey;
    ld.ImagesTargetSize[ld.ImageIndex].x := 0;
    ld.ImagesTargetSize[ld.ImageIndex].y := 0;
    ld.ImagesTargetScale[ld.ImageIndex] := Max(0, Min(1, TargetScale));
    Inc(ld.ImageIndex);
  end;
end;

procedure TGfxSpritesheet.AddImage(Path: string; ColorKey: TGfxColor;
  TargetSize: TVector2);
var
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;

  if ld.ImageIndex < Length(ld.Images) then
  begin
    ld.ImagesPath[ld.ImageIndex] := Path;
    ld.ImagesKey[ld.ImageIndex] := ColorKey;
    ld.ImagesTargetSize[ld.ImageIndex].x := TargetSize.x;
    ld.ImagesTargetSize[ld.ImageIndex].y := TargetSize.y;
    ld.ImagesTargetScale[ld.ImageIndex] := 0;
    Inc(ld.ImageIndex);
  end;
end;

procedure TGfxSpritesheet.AddImage(Image: TGfxImage);
var
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;

  if ld.ImageIndex < Length(ld.Images) then
  begin
    ld.Images[ld.ImageIndex] := Image;
    ld.ImagesTargetSize[ld.ImageIndex].x := 0;
    ld.ImagesTargetSize[ld.ImageIndex].y := 0;
    ld.ImagesTargetScale[ld.ImageIndex] := 1;
    Inc(ld.ImageIndex);
  end;
end;

procedure TGfxSpritesheet.Load;
begin
  Self.StartLoading;
  Self.FinishLoading;
end;

procedure TGfxSpritesheet.StartLoading;
var
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;

  if ld.LoadingStage = 0 then
    ld.LoadingStage := 1;
end;

procedure TGfxSpritesheet.ContinueLoading;
var
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;

  case ld.LoadingStage of
    1: Self.LoadNextImage;
    2: Self.PackRects;
    3: Self.UpdateNextSprite;
    4: Self.UpdateTexture;
  end;
end;

procedure TGfxSpritesheet.FinishLoading;
begin
  while Self.IsLoading do
    ContinueLoading;
end;

procedure GetTargetDimensions(Image: TGfxImage; Scale: Single; var w, h: Integer);
begin
  w := Image.Width;
  h := Image.Height;

  if Scale < 1 then
  begin
    h := Max(1, Round(Image.Height * Scale));
    w := Round(Image.Width * (h  / Image.Height));

    if w = 0 then
    begin
      w := 1;
      h := Round(Image.Height / Image.Width);
    end;
  end;

  if (w > GfxContext.MaxTextureSize) or (h > GfxContext.MaxTextureSize) then
  begin
    if w > h then
    begin
      w := GfxContext.MaxTextureSize;
      h := Max(1, Round(Image.Height * (w / Image.Width)));
    end
    else
    begin
      h := GfxContext.MaxTextureSize;
      w := Max(1, Round(Image.Width * (h / Image.Height)));
    end;
  end;
end;

procedure TGfxSpritesheet.LoadNextImage;
var
  i, j, k: Integer;
  w: Integer = 0;
  h: Integer = 0;
  Sprite: PGfxSprite;
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;
  i := ld.LoadingIndex;

  if ld.Images[i] = nil then
  begin
    ld.Images[i] := TGfxImage.Create(ld.ImagesPath[i], ld.ImagesKey[i]);
    ld.Images[i].Premultiply;

    if ld.Images[i].GetImageData = nil then
    begin
      FreeAndNil(ld.Images[i]);
      ld.Images[i] := TGfxImage.Create(16, 16);
      ld.ImagesTargetSize[i].x := 0;
      ld.ImagesTargetSize[i].y := 0;
      ld.ImagesTargetScale[i] := 1;
      FillChar(ld.Images[i].GetImageData()^, 16 * 16 * 4, 255);
    end;

    if ld.ImagesTargetScale[i] = 0 then
    begin
      ld.ImagesTargetScale[i] := Max(
        ld.ImagesTargetSize[i].x / ld.Images[i].Width,
        ld.ImagesTargetSize[i].y / ld.Images[i].Height
      );
    end;

    GetTargetDimensions(ld.Images[i], ld.ImagesTargetScale[i], w, h);

    if (w <> ld.Images[i].Width) or (h <> ld.Images[i].Height) then
    begin
      ld.ImagesTargetScale[i] := h / ld.Images[i].Height;
      ld.Images[i].Resize(w, h);
    end
    else
      ld.ImagesTargetScale[i] := 1;

    Inc(ld.AdditionalFrames, ld.Images[i].NumFrames - 1);
  end;

  Inc(ld.LoadingIndex);

  if ld.LoadingIndex = Length(ld.Images) then
  begin
    if ld.AdditionalFrames > 0 then
    begin
      k := 0;

      SetLength(FAdditionalSprites, ld.AdditionalFrames);
      FillChar(FAdditionalSprites[0], sizeof(TGfxSprite) * ld.AdditionalFrames, 0);

      for i := Low(ld.Images) to High(ld.Images) do
      begin
        Sprite := @FSprites[i];

        for j := 1 to ld.Images[i].NumFrames - 1 do
        begin
          Sprite.Next := @FAdditionalSprites[k];
          Sprite := Sprite.Next;
          Inc(k);
        end;
      end;
    end;

    Inc(ld.LoadingStage);
  end;
end;

procedure PackRectsRecursive(var Rects: TBPRectArray; var Textures: TTextureArray);
var
  i, n, w, h: Integer;
  a, aa: Int64;
  Rects1: TBPRectArray;
  Rects2: TBPRectArray;
begin
  if Length(Rects) = 1 then
  begin
    n := Length(Textures);
    SetLength(Textures, n + 1);
    w := Npot(Rects[0].w - PADDING);
    h := Npot(Rects[0].h - PADDING);
    Textures[n] := GfxCreateTexture(w, h, 4, NIL);
    PRectInfo(Rects[0].Data).Texture := n;
    Exit;
  end;

  a := 0;

  for i := 0 to High(Rects) do
    a := a + Int64(Rects[i].w) * Int64(Rects[i].h);

  w := Npot(Round(Ceil(Sqrt(a + 0.0))));
  h := w;

  while (w <= GfxContext.MaxTextureSize) and (h <= GfxContext.MaxTextureSize) and
    (BinPack.PackRects(w + PADDING, h + PADDING, Rects) <> Length(Rects)) do
  begin
    h := h shl Integer(h < w);
    w := w shl Integer(w <= h);
  end;

  if (w <= GfxContext.MaxTextureSize) and (h <= GfxContext.MaxTextureSize) then
  begin
    n := Length(Textures);
    SetLength(Textures, n + 1);
    Textures[n] := GfxCreateTexture(w, h, 4, NIL);

    for i := 0 to High(Rects) do
      PRectInfo(Rects[i].Data).Texture := n;
  end
  else
  begin
    i := 0;
    a := a div 2;
    aa := 0;

    while (aa < a) and (i < Length(Rects) - 1) do
    begin
      aa := aa + Int64(Rects[i].w) * Int64(Rects[i].h);
      Inc(i);
    end;

    SetLength(Rects1, i);
    SetLength(Rects2, Length(Rects) - i);

    Move(Rects[0], Rects1[0], sizeof(TBPRect) * Length(Rects1));
    Move(Rects[i], Rects2[0], sizeof(TBPRect) * Length(Rects2));

    PackRectsRecursive(Rects1, Textures);
    PackRectsRecursive(Rects2, Textures);

    Move(Rects1[0], Rects[0], sizeof(TBPRect) * Length(Rects1));
    Move(Rects2[0], Rects[i], sizeof(TBPRect) * Length(Rects2));
  end;
end;

procedure TGfxSpritesheet.PackRects;
var
  i, j, k, n: Integer;
  Textures: TTextureArray;
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;
  n := Length(FSprites) + Length(FAdditionalSprites);
  k := 0;

  SetLength(ld.Rects, n);
  SetLength(ld.RectInfo, n);

  for i := Low(ld.Images) to High(ld.Images) do
  begin
    for j := 0 to ld.Images[i].NumFrames - 1 do
    begin
      ld.RectInfo[k].Image := i;
      ld.RectInfo[k].Frame := j;
      ld.RectInfo[k].Texture := 0;

      ld.Rects[k].w := ld.Images[i].Width + PADDING;
      ld.Rects[k].h := ld.Images[i].Height + PADDING;
      ld.Rects[k].Data := @ld.RectInfo[k];

      Inc(k);
    end;
  end;

  Textures := Default(TTextureArray);
  PackRectsRecursive(ld.Rects, Textures);
  SetLength(FTextures, Length(Textures));
  SetLength(ld.AtlasImages, Length(Textures));

  for i := 0 to High(Textures) do
  begin
    FTextures[i] := Textures[i];
    ld.AtlasImages[i] := TGfxImage.Create(Textures[i].Width, Textures[i].Height);
  end;

  ld.LoadingIndex := 0;
  Inc(ld.LoadingStage);
end;

procedure TGfxSpritesheet.UpdateNextSprite;
var
  x, y, w, h: Integer;
  Sprite: PGfxSprite;
  ld: ^TSheetLoadData;
  Info: ^TRectInfo;
begin
  ld := FLoadData;
  Info := ld.Rects[ld.LoadingIndex].Data;

  x := ld.Rects[ld.LoadingIndex].x;
  y := ld.Rects[ld.LoadingIndex].y;
  w := ld.Rects[ld.LoadingIndex].w - PADDING;
  h := ld.Rects[ld.LoadingIndex].h - PADDING;

  ld.AtlasImages[Info.Texture].Update(x, y, w, h,
    ld.Images[Info.Image].GetImageData(Info.Frame));

  Sprite := @FSprites[Info.Image];

  if Info.Frame > 0 then
  begin
    Sprite := Sprite.Next;
    Inc(Sprite, Info.Frame - 1);
  end;

  Sprite.Texture := FTextures[Info.Texture];
  Sprite.Delay := ld.Images[Info.Image].GetFrameDelay(Info.Frame);

  Sprite.x := x;
  Sprite.y := y;
  Sprite.Width := w;
  Sprite.Height := h;
  Sprite.Scale := 1 / ld.ImagesTargetScale[Info.Image];

  Sprite.TexCoords.Left   := Sprite.x / Sprite.Texture.Width;
  Sprite.TexCoords.Top    := Sprite.y / Sprite.Texture.Height;
  Sprite.TexCoords.Right  := (Sprite.x + Sprite.Width) / Sprite.Texture.Width;
  Sprite.TexCoords.Bottom := (Sprite.y + Sprite.Height) / Sprite.Texture.Height;

  Inc(ld.LoadingIndex);

  if ld.LoadingIndex = Length(ld.Rects) then
    Inc(ld.LoadingStage);
end;


procedure TGfxSpritesheet.UpdateTexture;
var
  i: Integer;
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;
  for i := 0 to High(ld.AtlasImages) do
  begin
    GfxUpdateTexture(FTextures[i], 0, 0, ld.AtlasImages[i].Width,
      ld.AtlasImages[i].Height, ld.AtlasImages[i].GetImageData);
  end;
  Self.CleanUp;
end;


procedure TGfxSpritesheet.CleanUp;
var
  i: Integer;
  ld: ^TSheetLoadData;
begin
  ld := FLoadData;
  FLoadData := nil;

  if ld <> nil then
  begin
    for i := Low(ld.AtlasImages) to High(ld.AtlasImages) do
      FreeAndNil(ld.AtlasImages[i]);

    for i := Low(ld.Images) to High(ld.Images) do
      FreeAndNil(ld.Images[i]);

    Dispose(ld);
  end;
end;

end.
