unit saplzss;
(*
 @type: unit
 @author: Tomasz Biela (Tebe)
 @name: SAP-R LZSS Player
 @version: 1.3

   Version 1.1:
	- function Decode: Boolean; (TRUE = end of song)

   Version 1.2:
	- TLZSSPlay.Init(a: byte), add clear buffers

   Version 1.3:
	- TLZSSPlay.Init(a: byte), remove clear buffers
	- TLZSSPlay.Clear

 @description:
 <https://github.com/dmsc/lzss-sap>
*)


{

TLZSSPlay.Init
TLZSSPlay.Decode
TLZSSPlay.Play
TLZSSPlay.Stop

}

interface

type	TLZSSPlay = Object
(*
@description:
object for controling SAP-R LZSS Player
*)
	jmp: byte;			// dta $4c

	player: pointer;		// memory address of a player
	modul: pointer;			// memory address of a module

	// A = POKEY address (low byte), $00 -> $d200, $10 -> $d210

	procedure Init(a: byte); assembler;	// initialization
	procedure Clear; assembler;		// clear buffers
	function Decode: Boolean; assembler;	// decode stream
	procedure Play; assembler;		// play
	procedure Stop(a: byte); assembler;	// stops music

	end;


implementation


procedure TLZSSPlay.Init(a: byte); assembler;
(*
@description:
Initialize SAP-R LZSS player

player: lsb = $00 ; msb = $xx
*)
asm
	txa:pha

	mwa TLZSSPlay :bp2

	ldy #0
	lda #$4c	; JMP
	sta (:bp2),y

	ldy #2
	lda (:bp2),y	; msb player address
	sta adr+2

	ldy #4
	lda (:bp2),y
	tax		; hi byte of MPT module to Y reg
	dey
	lda (:bp2),y	; low byte of MPT module to X reg

	ldy a		; POKEY: $00 | $10 | ...

adr	jsr $ff06	; jsr player+6

	pla:tax
end;


procedure TLZSSPlay.Clear; assembler;
(*
@description:
Clear buffers, player + $0300..$BFF ($900 bytes)

*)
asm
	txa:pha

	mwa TLZSSPlay :bp2

	ldy #2
	lda (:bp2),y	; msb player address

	add #3		; clr = player+$300
	sta clr+2

	ldx #8		; clear buffers player+$0300..$bff ($900)
	ldy #0
	tya
clr	sta $ff00,y
	iny
	bne clr

	inc clr+2
	dex
	bpl clr

	pla:tax
end;


function TLZSSPlay.Decode: Boolean; assembler;
(*
@description:
Decode stream music
*)
asm
	txa:pha

	mwa TLZSSPlay ptr

	clc

	jsr $ff00		; jmp (TLZSSPlay)	6502 buggy indirect jump
ptr	equ *-2

	lda #0
	rol @
	sta Result		; C = 1	-> 	if TRUE then 'end of song'

	pla:tax
end;


procedure TLZSSPlay.Play; assembler;
(*
@description:
Play music
*)
asm
	txa:pha

	mwa TLZSSPlay ptr

	sec

	jsr $ff00		; jmp (TLZSSPlay)	6502 buggy indirect jump
ptr	equ *-2

	pla:tax
end;


procedure TLZSSPlay.Stop(a: byte); assembler;
(*
@description:
Reset POKEY
*)
asm
	ldy a		; POKEY: $00 | $10 | ...

	lda #0
	sta $d208,y
	lda #3
	sta $d20f,y

	lda #0
	sta $d200,y
	sta $d201,y
	sta $d202,y
	sta $d203,y
	sta $d204,y
	sta $d205,y
	sta $d206,y
	sta $d207,y
end;


initialization


end.
