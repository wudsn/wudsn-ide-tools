// x0F Disk Initializer v1.1

uses crt, siodisk;

const

 xdos_S: array [0..383] of byte = (
    $46, $03, $eb, $07, $09, $09, $8d, $05, $03, $a9, $5c, $8d, $e7, $02, $a9, $09,
    $8d, $e8, $02, $a2, $44, $a8, $20, $86, $e4, $20, $8c, $08, $30, $56, $20, $e8,
    $08, $30, $43, $85, $44, $20, $e8, $08, $30, $4a, $85, $45, $c9, $ff, $b0, $ee,
    $20, $e8, $08, $30, $3f, $85, $46, $20, $e8, $08, $30, $38, $85, $47, $a9, $09,
    $8d, $e2, $02, $8d, $e3, $02, $20, $e8, $08, $30, $29, $a0, $00, $91, $44, $a4,
    $44, $a5, $45, $e6, $44, $d0, $02, $e6, $45, $c4, $46, $e5, $47, $90, $e7, $a9,
    $08, $48, $48, $6c, $e2, $02, $6c, $e0, $02, $a5, $22, $c9, $28, $d0, $05, $20,
    $61, $08, $10, $a5, $38, $60, $a2, $00, $86, $43, $a9, $3a, $a0, $01, $d1, $24,
    $f0, $01, $c8, $c8, $b1, $24, $c9, $60, $b0, $0c, $c9, $30, $b0, $0b, $c9, $2e,
    $d0, $04, $e0, $08, $f0, $ed, $88, $a9, $20, $9d, $51, $09, $e8, $e0, $0b, $90,
    $e2, $a0, $69, $a9, $01, $a2, $52, $20, $3a, $09, $30, $3a, $a2, $0b, $bd, $f5,
    $06, $f0, $69, $29, $df, $c9, $42, $d0, $2e, $a0, $0b, $bd, $04, $07, $d9, $50,
    $09, $d0, $24, $ca, $88, $d0, $f4, $bd, $03, $07, $8d, $7e, $07, $a5, $43, $0a,
    $0a, $5d, $04, $07, $8d, $7d, $07, $8c, $7f, $07, $8c, $e9, $08, $a0, $7d, $99,
    $ff, $06, $88, $d0, $fa, $c8, $60, $e6, $43, $8a, $29, $f0, $18, $69, $1b, $aa,
    $10, $bc, $ee, $0a, $03, $a2, $52, $20, $4b, $09, $10, $b0, $60, $a0, $00, $cc,
    $7f, $07, $90, $0e, $a2, $52, $20, $2c, $09, $30, $13, $ac, $7f, $07, $f0, $1a,
    $a0, $00, $b9, $00, $07, $c8, $8c, $e9, $08, $a0, $01, $60, $a0, $aa, $60, $08,
    $23, $09, $e7, $08, $17, $09, $08, $09, $53, $08, $a0, $88, $60, $ac, $7f, $07,
    $ee, $7f, $07, $99, $00, $07, $a0, $01, $60, $a5, $2a, $c9, $08, $d0, $f7, $a2,
    $57, $ad, $7d, $07, $29, $03, $ac, $7e, $07, $d0, $04, $c9, $00, $f0, $db, $8c,
    $0a, $03, $8d, $0b, $03, $4d, $7d, $07, $8d, $7d, $07, $a9, $00, $8d, $7e, $07,
    $8e, $02, $03, $4c, $53, $e4, $41, $55, $54, $4f, $52, $55, $4e, $20, $20, $20,
    $20, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
);

 xdos_D: array [0..383] of byte = (
    $46, $03, $e1, $07, $09, $09, $a0, $00, $8c, $d5, $02, $a0, $01, $8c, $d6, $02,
    $8d, $05, $03, $a9, $5c, $8d, $e7, $02, $a9, $09, $8d, $e8, $02, $a2, $44, $a8,
    $20, $86, $e4, $20, $8c, $08, $30, $56, $20, $e8, $08, $30, $43, $85, $44, $20,
    $e8, $08, $30, $4a, $85, $45, $c9, $ff, $b0, $ee, $20, $e8, $08, $30, $3f, $85,
    $46, $20, $e8, $08, $30, $38, $85, $47, $a9, $09, $8d, $e2, $02, $8d, $e3, $02,
    $20, $e8, $08, $30, $29, $a0, $00, $91, $44, $a4, $44, $a5, $45, $e6, $44, $d0,
    $02, $e6, $45, $c4, $46, $e5, $47, $90, $e7, $a9, $08, $48, $48, $6c, $e2, $02,
    $6c, $e0, $02, $a5, $22, $c9, $28, $d0, $05, $20, $61, $08, $10, $a5, $38, $60,
    $a2, $00, $86, $43, $a9, $3a, $a0, $01, $d1, $24, $f0, $01, $c8, $c8, $b1, $24,
    $c9, $60, $b0, $0c, $c9, $30, $b0, $0b, $c9, $2e, $d0, $04, $e0, $08, $f0, $ed,
    $88, $a9, $20, $9d, $51, $09, $e8, $e0, $0b, $90, $e2, $a0, $69, $a9, $01, $a2,
    $52, $20, $3a, $09, $30, $3a, $a2, $0b, $bd, $f5, $06, $f0, $69, $29, $df, $c9,
    $42, $d0, $2e, $a0, $0b, $bd, $04, $07, $d9, $50, $09, $d0, $24, $ca, $88, $d0,
    $f4, $bd, $03, $07, $8d, $fe, $07, $a5, $43, $0a, $0a, $5d, $04, $07, $8d, $fd,
    $07, $8c, $ff, $07, $8c, $e9, $08, $a0, $fd, $99, $ff, $06, $88, $d0, $fa, $c8,
    $60, $e6, $43, $8a, $29, $f0, $18, $69, $1b, $aa, $10, $bc, $ee, $0a, $03, $a2,
    $52, $20, $4b, $09, $10, $b0, $60, $a0, $00, $cc, $ff, $07, $90, $0e, $a2, $52,
    $20, $2c, $09, $30, $13, $ac, $ff, $07, $f0, $1a, $a0, $00, $b9, $00, $07, $c8,
    $8c, $e9, $08, $a0, $01, $60, $a0, $aa, $60, $08, $23, $09, $e7, $08, $17, $09,
    $08, $09, $53, $08, $a0, $88, $60, $ac, $ff, $07, $ee, $ff, $07, $99, $00, $07,
    $a0, $01, $60, $a5, $2a, $c9, $08, $d0, $f7, $a2, $57, $ad, $fd, $07, $29, $03,
    $ac, $fe, $07, $d0, $04, $c9, $00, $f0, $db, $8c, $0a, $03, $8d, $0b, $03, $4d,
    $fd, $07, $8d, $fd, $07, $a9, $00, $8d, $fe, $07, $8e, $02, $03, $4c, $53, $e4,
    $41, $55, $54, $4f, $52, $55, $4e, $20, $20, $20, $20, $00, $00, $00, $00, $00
);

var

 density, drv: byte;
 ch: char;

 ok: Boolean;

 label again;


begin

 writeln('x0F Dos Initializer ',{$I %DATE%},eol);

again:

 ok:=false;

 repeat

 write('Select drive (1-8): ');
 readln(ch);

 case ch of
  '1'..'8': ok:=true;
 else
  ok:=false;
 end;

 until ok;

 drv:=byte(ch) - ord('0');

 density := ReadConfig(drv) and %00100000;	// if <> 0 then 'Double Densisty' (D)

 if IOResult > 127 then begin
  writeln('Error: ', IOResult,eol);
  goto again;
 end;

 write('D', drv, ': ');

 if density <> 0 then
  write('Double')
 else
  write('Single/Enhanced');

 writeln(' density', eol);

 write('Write x0F Dos (Y/N)');
 readln(ch);

 if UpCase(ch) = 'Y' then begin

  if density <> 0 then
   WriteBoot(drv, xdos_D)
  else
   WriteBoot(drv, xdos_S);

 end;

 if IOResult > 127 then begin
  writeln('Error: ', IOResult,eol);
  goto again;
 end;

 writeln('Again (Y/N)? ');
 readln(ch);

 if UpCase(ch) = 'Y' then goto again;

end.
