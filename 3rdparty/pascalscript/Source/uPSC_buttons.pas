{ Compiletime Buttons support }
unit uPSC_buttons;
{$I PascalScript.inc}
interface
uses
  uPSCompiler, uPSUtils;

{
  Will register files from:
    Buttons
 
  Requires
      STD, classes, controls and graphics and StdCtrls
}
procedure SIRegister_Buttons_TypesAndConsts(Cl: TPSPascalCompiler);

procedure SIRegisterTSPEEDBUTTON(Cl: TPSPascalCompiler);
procedure SIRegisterTBITBTN(Cl: TPSPascalCompiler);

procedure SIRegister_Buttons(Cl: TPSPascalCompiler);

implementation

procedure SIRegisterTSPEEDBUTTON(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TGraphicControl'), 'TSpeedButton') do
  begin
    RegisterProperty('AllowAllUp', 'Boolean', iptrw);
    {$IFDEF DELPHI4UP}
    RegisterProperty('Anchors', 'TAnchors', iptrw);
    {$ENDIF}
    RegisterProperty('GroupIndex', 'Integer', iptrw);
    RegisterProperty('Down', 'Boolean', iptrw);
    RegisterProperty('Caption', 'string', iptrw);
    RegisterProperty('Font', 'TFont', iptrw);
    RegisterProperty('Glyph', 'TBitmap', iptrw);
    RegisterProperty('Layout', 'TButtonLayout', iptrw);
    RegisterProperty('Margin', 'Integer', iptrw);
    RegisterProperty('NumGlyphs', 'Byte', iptrw);
    RegisterProperty('ParentFont', 'Boolean', iptrw);
    RegisterProperty('ParentShowHint', 'Boolean', iptrw);
    RegisterProperty('Spacing', 'Integer', iptrw);
    RegisterProperty('OnClick', 'TNotifyEvent', iptrw);
    RegisterProperty('OnDblClick', 'TNotifyEvent', iptrw);
    RegisterProperty('OnMouseDown', 'TMouseEvent', iptrw);
    RegisterProperty('OnMouseMove', 'TMouseMoveEvent', iptrw);
    RegisterProperty('OnMouseUp', 'TMouseEvent', iptrw);
  end;
end;

procedure SIRegisterTBITBTN(Cl: TPSPascalCompiler);
begin
  with Cl.AddClassN(cl.FindClass('TButton'), 'TBitBtn') do
  begin
    {$IFDEF DELPHI4UP}
    RegisterProperty('Anchors', 'TAnchors', iptrw);
    {$ENDIF}
    RegisterProperty('Glyph', 'TBitmap', iptrw);
    RegisterProperty('Kind', 'TBitBtnKind', iptrw);
    RegisterProperty('Layout', 'TButtonLayout', iptrw);
    RegisterProperty('Margin', 'Integer', iptrw);
    RegisterProperty('NumGlyphs', 'Byte', iptrw);
    RegisterProperty('Style', 'TButtonStyle', iptrw);
    RegisterProperty('Spacing', 'Integer', iptrw);
  end;
end;



procedure SIRegister_Buttons_TypesAndConsts(Cl: TPSPascalCompiler);
begin
  Cl.AddTypeS('TButtonLayout', '(blGlyphLeft, blGlyphRight, blGlyphTop, blGlyphBottom)');
  Cl.AddTypeS('TButtonState', '(bsUp, bsDisabled, bsDown, bsExclusive)');
  Cl.AddTypeS('TButtonStyle', '(bsAutoDetect, bsWin31, bsNew)');
  Cl.AddTypeS('TBitBtnKind', '(bkCustom, bkOK, bkCancel, bkHelp, bkYes, bkNo, bkClose, bkAbort, bkRetry, bkIgnore, bkAll)');

end;

procedure SIRegister_Buttons(Cl: TPSPascalCompiler);
begin
  SIRegister_Buttons_TypesAndConsts(cl);
  SIRegisterTSPEEDBUTTON(cl);
  SIRegisterTBITBTN(cl);
end;

// PS_MINIVCL changes by Martijn Laan (mlaan at wintax _dot_ nl)


end.




