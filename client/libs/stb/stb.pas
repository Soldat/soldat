{*******************************************************}
{                                                       }
{       stb Unit for SOLDAT                             }
{                                                       }
{       Copyright (c) 2015 Mariano Cuatrin              }
{                                                       }
{*******************************************************}

unit stb;

interface

type
  PPInteger = ^PInteger;

const
 {$IFDEF MSWINDOWS}
  STBLIB = 'stb.dll';
 {$ELSE}
  STBLIB = 'stb.so';
 {$ENDIF}

// stb_image
function stbi_xload_file(filename: PAnsiChar; w, h, f: PInteger; delays: PPInteger): PByte;
  cdecl; external STBLIB;

function stbi_xload_mem(buffer: PByte; len: Integer; w, h, f: PInteger; delays: PPInteger): PByte;
  cdecl; external STBLIB;

function stbi_load(filename: PAnsiChar; w, h, c: PInteger; req_comp: Integer): PByte;
  cdecl; external STBLIB;

procedure stbi_image_free(data: Pointer);
  cdecl; external STBLIB;

function stbi_load_from_memory(buffer: Pointer; len: Integer; w, h, c: PInteger; req_comp: Integer): PByte;
  cdecl; external STBLIB;


// stb_image_write
function stbi_write_png(filename: PAnsiChar; w, h, comp: Integer; data: Pointer; stride: Integer): Integer;
  cdecl; external STBLIB;

function stbi_write_bmp(filename: PAnsiChar; w, h, comp: Integer; data: Pointer): Integer;
  cdecl; external STBLIB;

function stbi_write_tga(filename: PAnsiChar; w, h, comp: Integer; data: Pointer): Integer;
  cdecl; external STBLIB;

function stbi_write_hdr(filename: PAnsiChar; w, h, comp: Integer; data: Pointer): Integer;
  cdecl; external STBLIB;

function stbir_resize_uint8(in_data: PByte; in_w, in_h, in_stride: Integer;
  out_data: PByte; out_w, out_h, out_stride, num_channels: Integer): Integer;
  cdecl; external STBLIB;

implementation

end.
