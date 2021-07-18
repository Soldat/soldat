{ implementation of the arm procedure call standard for function calls in pascal script
  Copyright (c) 2008 by Henry Vermaak (henry.vermaak@gmail.com)

  Support for EABI baseline and EABI hardfloat (c) 2015
    modulo7 ( https://github.com/modulo7 )
    Peter Michael Green ( plugwash@p10link.net )

  todo: add wince support

  notes:

  most arm cpus don't allow unaligned access.  by default (?) the linux kernel
  is set up to try and correct unaligned access, which can lead to strange behaviour.
  to turn this off, try (as root):

  echo 4 > /proc/cpu/alignment

  if you have an alignment problem, you will now get a crash with a backtrace like this:
  (make sure you compile with -O- -gl)

  An unhandled exception occurred at $0006C014 :
  EBusError : Bus error or misaligned data access
    $0006C014  PROCESSREPEAT,  line 9670 of upscompiler.pas
    $00068AAC  TPSPASCALCOMPILER__PROCESSSUB,  line 10459 of upscompiler.pas
    $0007D0B4  TPSPASCALCOMPILER__COMPILE,  line 11704 of upscompiler.pas

  you can fix this by using the "unaligned" keyword around the pointer operation.
  search for occurrences of "unaligned" to see how this is done,
  (use $ifdef FPC_REQUIRES_PROPER_ALIGNMENT).

  for more information, visit:

  http://www.aleph1.co.uk/oldsite/armlinux/book/afaq.html
}

const
  rtINT = 0;
  rtINT64 = 1;
  rtFLOAT = 2;

type
  Trint = array[1..4] of dword;
{$IFDEF FPC_abi_eabihf}
  Trfloat = record case byte of
          1:(s:array[0..15] of single);
          2:(d:array[0..7] of double);
          end;
{$ELSE}
  Trfloat = array[1..4] of double;
{$ENDIF}
{$goto on}
{ define labels }
label
  stack_loop,
  load_regs,
  asmcall_end,
  int_result,
  int64_result,
  float_result;

{ call a function from a pointer }
{ resulttype: 0 = int, 1 = int64, 2 = float }
function armasmcall(constref rint: Trint;constref rfloat: Trfloat; proc, stack: pointer; stacksize, resulttype: integer): int64; assembler; nostackframe;
asm
	mov	r12, r13
	stmfd	r13!, {r4, r5, r6, r7, r8, r9, r10, r11, r12, r14, r15}
	sub	r11, r12, #4
	mov	r4, #80			(* space for preserved registers and parameters *)
	ldr	r5, [r11, #4]		(* stacksize we need for subroutine *)
	add	r4, r4, r5
	sub	r13, r13, r4		(* create stack space *)

{$ifdef FPC_abi_eabi}
	(* EABI requires 8 byte aligned stack pointer for procedure calls, ensure alignment. *)
	bic	r13, r13, #7
{$endif}

	(* store parameters on stack *)
	str	r0, [r11, #-44]		(* rint *)
	str	r1, [r11, #-48]		(* rfloat *)
	str	r2, [r11, #-52]		(* proc *)
	str	r3, [r11, #-56] 	(* stack *)
	ldr	r0, [r11, #4]
	str	r0, [r11, #-60]		(* stacksize *)
	ldr	r0, [r11, #8]		
	str	r0, [r11, #-64]		(* resulttype *)

	(* store params for sub-routine that don't fit into r0-r3 at start of stack *)
	ldr	r0, [r11, #-60]		(* stacksize *)
	cmp	r0, #0
	beq	load_regs		(* skip if no stack *)
	mov	r1, r13			(* this points to the bottom now *)
	ldr	r2, [r11, #-56]		(* stack pointer *)
stack_loop:
	ldmia	r2!, {r4}		(* get stack + update pos *)
	stmia	r1!, {r4}		(* store stack + update pos *)
	subs	r0, r0, #4
	bne	stack_loop

load_regs:
	(* load general regs *)
	ldr	r4, [r11, #-44]	(* rint *)
	ldr	r0, [r4]
	ldr	r1, [r4, #4]
	ldr	r2, [r4, #8]
	ldr	r3, [r4, #12]

{$ifdef FPUFPA}
	(* load float regs *)
	ldr	r4, [r11, #-48]	(* rfloat *)
	ldfd	f0, [r4]
	ldfd	f1, [r4, #8]
	ldfd	f2, [r4, #16]
	ldfd	f3, [r4, #24]
{$endif}
{$ifdef FPC_abi_eabihf}
	(* load float regs *)
	ldr	r4, [r11, #-48]	(* rfloat *)
	fldmiad r4, {d0,d1,d2,d3,d4,d5,d6,d7}
{$endif}

	(* branch to the proc pointer *)
	ldr	r4, [r11, #-52]

{$ifdef FPC_abi_eabi}
	blx	r4
{$else}
	mov	r14, r15
	mov	r15, r4
{$endif}

	ldr	r4, [r11, #-64]		(* get resulttype *)
	cmp	r4, #1

	ble     asmcall_end
{$ifdef FPUFPA}
	stfd f0, [r11, #-72]
	ldr r0, [r11, #-72]
	ldr r1, [r11, #-68]
{$endif}
{$IFDEF FPC_abi_eabihf}
	fmrrd    r0, r1, d0
{$endif}


asmcall_end:
	ldmea	r11,{r4,r5,r6,r7,r8,r9,r10,r11,r13,r15}
end;

function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
var
  rint: Trint;			{ registers r0 to r3 }
  rfloat: Trfloat;		{ registers f0 to f3 }
  st: packed array of byte;	{ stack }
  i, j, rindex, findex, stindex,sindex: integer;
  fvar: PPSVariantIFC;
  IsConstructor: Boolean;

  { add a dword to stack }
  procedure addstackdword(value: dword);
  begin
    setlength(st, stindex+4);
    pdword(@st[stindex])^ := value;
    inc(stindex, 4);
  end;

  { add a qword to stack }
  procedure addstackqword(value: qword);
  begin
    if (stindex and 4)<>0 then inc(stindex, 4);
    setlength(st, stindex+8);
    pqword(@st[stindex])^ := value;
    inc(stindex, 8);
  end;
  { add a float to stack }
  procedure addstackfloat(value: pointer; size: integer);
  begin
    setlength(st, stindex + (size * 4));
    if size = 1
      then psingle(@st[stindex])^ := single(value^)
      else pdouble(@st[stindex])^ := double(value^);
    inc(stindex, size*4);
  end;

  { add to the general registers or overflow to stack }
  procedure addgen(value: dword);
  begin
    if rindex <= 4
      then begin
        rint[rindex] := value;
        inc(rindex);
      end
      else begin
        addstackdword(value);
      end;
  end;

  { add to the general registers or overflow to stack }
  procedure addgend(value: qword);
  begin
    if (rindex and 1)=0 then inc(rindex);
    if rindex <= 4
      then begin
        rint[rindex] := lo(value);
        inc(rindex);
        rint[rindex] := hi(value);
        inc(rindex);
      end
      else begin
        addstackqword(value);
      end;
  end;
  { add to the float registers or overflow to stack }
  { size = 1 for single, 2 for double }
  procedure addfloat(value: pointer; size: integer);
  begin
{$IFDEF FPC_abi_eabihf}
    if (findex <= 7) or ((size = 1) and (sindex >= 0))
      then begin
        if size = 1
          then if sindex>=0 then begin

             rfloat.s[sindex] := single(value^);
             sindex:=-1;
          end else begin

             rfloat.s[findex*2] := single(value^);
             sindex:=findex*2+1;
             inc(findex);
          end
          else begin rfloat.d[findex] := double(value^);
             inc(findex);
          end;
      end
      else begin
        sindex := -1;
        if size = 1
          then addstackdword(pdword(value)^)
          else addstackqword(pqword(value)^);

      end;

{$ELSE}
    if findex <= 4
      then begin
        if size = 1
          then rfloat[findex] := single(value^)
          else rfloat[findex] := double(value^);
        inc(findex);
      end
      else begin
        addstackfloat(value, size);
      end;
{$ENDIF}
  end;
var
  tempdw : dword;
  tempqw : qword;
begin
  if (Integer(CallingConv) and 64) <> 0 then begin
    IsConstructor := true;
    CAllingConv := TPSCallingConvention(Integer(CallingConv) and not 64);
  end else IsConstructor := false;

  rindex := 1;
{$IFDEF FPC_abi_eabihf}
  findex := 0;
  sindex := -1;
{$ELSE}
  findex := 1;
{$ENDIF}
  stindex := 0;
  setlength(st, stindex);
  Result := False;

  { the pointer of the result needs to be passed first in the case of some result types }
  if assigned(res)
    then begin
      case res.atype.basetype of
        btStaticArray, btRecord,btString: addgen(dword(res.dta));
      end;
    end;

  { process all parameters }
  for i := 0 to Params.Count-1 do begin
    if Params[i] = nil
      then Exit;
    fvar := Params[i];

    { cook dynamic arrays - fpc stores size-1 at @array-4 }
    if (fvar.aType.BaseType = btArray)
      then dec(pdword(pointer(fvar.dta^)-4)^);

    if fvar.varparam
      then begin  { var param }
        case fvar.aType.BaseType of
          { add var params here }
          btArray, btVariant, btSet, btStaticArray, btRecord, btInterface, btClass, {$IFNDEF PS_NOWIDESTRING} btUnicodeString, btWideString, btWideChar, {$ENDIF}
          btU8, btS8, btU16, btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency
          {$IFNDEF PS_NOINT64}, bts64{$ENDIF}: addgen(dword(fvar.dta));
          else begin
            writeln(stderr, 'Parameter type not recognised!');
            Exit;
          end;
        end;  { case }
      end else begin  { not a var param }
        case fvar.aType.BaseType of
//          btArray, btVariant, btSet, btStaticArray, btRecord, btInterface, btClass, {$IFNDEF PS_NOWIDESTRING} btWideString, btWideChar, {$ENDIF}
//          btU8, btS8, btU16, btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency
//          {$IFNDEF PS_NOINT64}, bts64{$ENDIF}: writeln('normal param');

          { add normal params here }
          btString:                            addgen(dword(pstring(fvar.dta)^));
          btU8, btS8:                          addgen(dword(pbyte(fvar.dta)^));
          btU16, BtS16:                        addgen(dword(pword(fvar.dta)^));
          btU32, btS32:                        addgen(dword(pdword(fvar.dta)^));
          btSingle:                            {$if defined(FPUFPA) or defined(FPC_abi_eabihf)}
	                                         addfloat(fvar.dta, 1);
	                                       {$else}
					         addgen(dword(psingle(fvar.dta)^));
					       {$endif}
          btDouble{, btExtended}:              {$if defined(FPUFPA) or defined(FPC_abi_eabihf)}
	                                         addfloat(fvar.dta, 2);
	                                       {$else}
					         begin
					           {$IFDEF FPC_abi_eabi}
					           addgend(qword(pint64(fvar.dta)^));
					           {$ELSE}
					           addgen(lo(qword(pdouble(fvar.dta)^)));
					           addgen(hi(qword(pdouble(fvar.dta)^)));
					           {$ENDIF}
						 end;
					       {$endif}
          btPChar:                             addgen(dword(ppchar(fvar.dta)^));
          btChar:                              addgen(dword(pchar(fvar.dta)^));
          {$IFNDEF PS_NOINT64}bts64:{$ENDIF}   begin
                                                 {$IFDEF FPC_abi_eabi}
                                                 addgend(qword(pint64(fvar.dta)^));
                                                 {$ELSE}
                                                 addgen(dword(pint64(fvar.dta)^ and $ffffffff));
                                                 addgen(dword(pint64(fvar.dta)^ shr 32));
                                                 {$ENDIF}
                                               end;
          btStaticArray:                       addgen(dword(fvar.dta));
          btRecord:                            for j := 0 to (fvar.atype.realsize div 4)-1 do
                                                 addgen(pdword(fvar.dta + j*4)^);
          btArray:                             addstackdword(dword(fvar.dta^));  { this is a bit weird }

{          btVariant, btSet, btInterface, btClass  }

          else begin
            writeln(stderr, 'Parameter type not implemented!');
            Exit;
          end;
        end;  { case }
      end;  { else }
  end;  { for }

  if not assigned(res)
    then begin
      armasmcall(rint, rfloat, address, st, stindex, rtINT);  { ignore return }
    end
    else begin
      case res.atype.basetype of
        { add result types here }
        btU8, btS8, btChar:      pbyte(res.dta)^ := lo(lo(lo(armasmcall(rint, rfloat, address, st, stindex, rtINT))));
        btU16, btS16:            pword(res.dta)^ := lo(lo(armasmcall(rint, rfloat, address, st, stindex, rtINT)));
        btU32, btS32,btPChar:    pdword(res.dta)^ := lo(armasmcall(rint, rfloat, address, st, stindex, rtINT));
        btS64:                   pqword(res.dta)^ := armasmcall(rint, rfloat, address, st, stindex,rtINT);
{$IFDEF FPC_abi_eabi}
        btSingle:                pdword(res.dta)^ := lo(armasmcall(rint, rfloat, address, st, stindex, rtFLOAT));
{$ELSE}
        btSingle:                begin
                                   tempqw := armasmcall(rint, rfloat, address, st, stindex, rtFLOAT);
                                   psingle(res.dta)^ := pdouble(@tempqw)^;
                                 end;
{$ENDIF}
        btArray:                 begin
                                    tempdw := armasmcall(rint, rfloat, address, st, stindex, rtINT);
                                    //FIXME menory leak
                                    pdword(res.dta)^:=tempdw;
                                 end;
        btDouble:pqword(res.dta)^ := armasmcall(rint, rfloat, address, st, stindex, rtFLOAT);
        btStaticArray, btRecord,btString: armasmcall(rint, rfloat, address, st, stindex, rtINT);
        else begin
          writeln(stderr, 'Result type not implemented!');
          exit;
        end;  { else }
      end;  { case }
    end;

  { cook dynamic arrays - fpc stores size-1 at @array-4 }
  for i := 0 to Params.Count-1 do begin
    fvar := Params[i];
    if (fvar.aType.BaseType = btArray)
      then inc(pdword(pointer(fvar.dta^)-4)^);
   end;

  Result := True;
end;
