
/*
 v2.0 - najwolniejsza, najkrótsza, udostępnia ShapeWidth = 5 (czyli 32 pixle trybu F ANTIC-a, 16 pixle trybu E ANTIC-a)

 Silnik dla duchów programowych zapożyczony z gry MARIO BROS. (disasemblacja i modyfikacje Tebe/Madteam, 11.09.2007)

 Silnik ten działa na zasadzie EOR-owania obrazu, wykorzystuje tylko 1 bufor obrazu, zajmuje bardzo mało pamięci, nie
 ma potrzeby zapamiętywania ani odświeżania zawartości ekranu po wyświetleniu ducha.

 *** !!! Dokonywane jest przesunięcie dwóch bitmap ducha (z pozycji poprzedniej i aktualnej) !!! ***

 !!! Maksymalna wysokość przetwarzanych duchów wynosi 128/ShapeWidth !!!

 !!! Minimalna szerokość duchów ShapeWidth = 2..5 !!!

 Cały silnik składa się z dwóch procedur PutShape i MoveShapeToBuffer.

 PutShape		właściwa procedura realizująca przesuwanie bitów bitmapy ducha i umieszczanie
 			ich w odpowiednim obszarze pamięci (obszarze pamięci obrazu)

 MoveShapeToBuffer	procedura kopiująca dane bitmapy ducha do jednego z dwóch buforów pomocniczych
 			ShapeBuffer0 i ShapeBuffer1

 SCHEMAT DZIAŁANIA:

 0. duch0_enabled=false		; duch o współrzędnych poprzednich (gdy startujemy nie mamy danych o takim duchu)
    duch1_enabled=true		; duch o współrzędnych aktualnych

 1. IF duch0_enabled THEN
	przepisz_bitmape_dla_ducha0_i_przesuń_jej_pixle
    ELSE
	zapisz_zerową_bitmape_dla_ducha0_nie_przesuwaj_pixli
    ENDIF
 
 2. IF duch1_enabled THEN
	przepisz_bitmape_dla_ducha1_i_przesuń_jej_pixle
    ELSE
	zapisz_zerową_bitmape_dla_ducha1_nie_przesuwaj_pixli
    ENDIF

 3. duch0 EOR dane_obrazu_o_współrzędnych_dla_ducha0
    duch1 EOR dane_obrazu_o_współrzędnych_dla_ducha1

 4. przepisz dane opisujące ducha1 do ducha0

 5. goto 1

*/


; $55 linii skaningowych (maksymalna prędkość silnika dla ducha o rozmiarze 32x16 pixli Hires)
; $45 linii skaningowych (maksymalna prędkość silnika dla ducha o rozmiarze 24x16 pixli Hires)
; $34 linii skaningowych (maksymalna prędkość silnika dla ducha o rozmiarze 16x16 pixli Hires)
; $24 linii skaningowych (maksymalna prędkość silnika dla ducha o rozmiarze 8x16 pixli Hires)


Screen		= $a010		; adres pamięci obrazu

ScreenWidth	= 40		; szerokość obrazu

ShapeWidth	= 4		; width+1, szerokość przetwarzanych duchów w bajtach (+1 dodatkowy bajt)

	ert ShapeWidth<2||ShapeWidth>5

* -------------------------------------------------------------------

	org $80

height		.ds 1		; parametry ducha
positionX	.ds 1
positionY	.ds 1
type		.ds 1
enabled		.ds 1
collision	.ds 1

height_old	.ds 1		; kopia parametrów ducha
positionX_old	.ds 1
positionY_old	.ds 1
type_old	.ds 1
enabled_old	.ds 1
collision_old	.ds 1

temp		.ds 1		; zmienne pomocnicze

ScreenAdr0	.ds 2
ScreenAdr1	.ds 2

	ert *>$ff

* -------------------------------------------------------------------

	org $2000

ShapeBuffer	.ds 256
ShapeBuffer0	= ShapeBuffer		; bufor pomocniczy dla ducha #0 (koniecznie w obszarze strony pamięci)
ShapeBuffer1	= ShapeBuffer+128	; bufor pomocniczy dla ducha #1 (koniecznie w obszarze strony pamięci)

lAdrLine	:256 dta l(Screen+#*ScreenWidth)	; młodsze bajty adresu linii obrazu
hAdrLine	:256 dta h(Screen+#*ScreenWidth)	; starsze bajty adresu linii obrazu

mulTab		:128/ShapeWidth dta #*ShapeWidth	; pomocnicza tablica mnożenia (oszczędzamy dzięki niej pare cykli)


dlist	dta d'ppp'		; program dla ANTIC-a
	dta $4e,a(screen)
	:101 dta $e
	dta $4e,0,h(screen+$1000)
	:101 dta $e
	dta $41,a(dlist)
	

main	lda:cmp:req 20

	mwa #dlist 560

	lda #$ff		; zezwolenie na ducha #1
	sta enabled

	lda #0			; blokada ducha #0, silnik zaczyna działanie od wyświetlenie od ducha #1
	sta enabled_old

	lda #16
	sta height

	lda #100
	sta positionX

	lda #60
	sta positionY

	lda #0
	sta type


loop
;	lda:cmp:req 20
	lda:rne $d40b
	

	mva #$0f $d01a

	jsr putShape

	inc positionX

	inc positionY
	lda positionY
	cmp #204-32
	scc
	lda #0

	sta positionY

	mva #$00 $d01a

	lda $d40b
	cmp $100
	scc
	sta $100	

	jmp loop


* -------------------------------------------------------------------
* ---	WYŚWIETLENIE DUCHÓW PROGRAMOWYCH W POLU GRY
* ---	PRZETWARZANE SĄ DWA DUCHY, ShapeBuffer0 (#0) i ShapeBuffer1 (#1)
* ---	DUCH NA POZYCJI POPRZEDNIEJ ORAZ DUCH NA POZYCJI AKTUALNEJ
* ---	NIE MA POTRZEBY ODŚWIEŻANIA POLA GRY STARĄ ZAWARTOŚĆIĄ
* -------------------------------------------------------------------
.proc	PutShape
	mva #0 collision		; !!! ZNACZNIK KOLIZJI !!!

	lda enabled_old			; czy zerować bufor ducha #0
	bne E_9568

	lda #$00			; zerowanie obszaru ducha #0 (84 bajty), duch ma wysokość max 21 linii
	ldx #$53
	sta:rpl ShapeBuffer0,x-
	bmi E_957f

E_9568	ldy type_old

	ldx	<ShapeBuffer0
	jsr	moveShapeToBuffer

E_957f	lda enabled			; czy zerować bufor ducha #1
	bne E_958f

	lda #$00			; zerowanie obszaru ducha #1 (84 bajty), duch ma wysokość max 21 linii
	ldx #$53
	sta:rpl ShapeBuffer1,x-
	bmi E_95a6

E_958f	ldy type

	ldx	<ShapeBuffer1
	jsr	moveShapeToBuffer

E_95a6	lda positionX_old		; pozycja pozioma ducha #0
	and #$03
	beq E_95d4

	sta temp

E_95ae	ldy height_old			; wysokość ducha
	dey
E_95b1	ldx mulTab,y

	.rept 2
	lsr ShapeBuffer0,x

	ift ShapeWidth>1
	ror ShapeBuffer0+1,x
	eif
	
	ift ShapeWidth>2
	ror ShapeBuffer0+2,x
	eif
	
	ift ShapeWidth>3
	ror ShapeBuffer0+3,x
	eif

	ift ShapeWidth>4
	ror ShapeBuffer0+4,x
	eif
	.endr

	dey
	bpl E_95b1

	dec temp
	bne E_95ae

E_95d4	lda positionX			; pozycja pozioma ducha #1
	and #$03
	beq E_9602

	sta temp

E_95dc	ldy height			; wysokość ducha
	dey
E_95df	ldx mulTab,y

	.rept 2
	lsr ShapeBuffer1,x

	ift ShapeWidth>1
	ror ShapeBuffer1+1,x
	eif
	
	ift ShapeWidth>2
	ror ShapeBuffer1+2,x
	eif
	
	ift ShapeWidth>3
	ror ShapeBuffer1+3,x
	eif

	ift ShapeWidth>4
	ror ShapeBuffer1+4,x
	eif
	.endr

	dey
	bpl E_95df

	dec temp
	bne E_95dc

E_9602	ldy height

	ldx mulTab,y
	dex				; wysokość ducha*ShapeWidth-1 = długość danych ducha (!!! regX !!!)

	lda positionY_old		; pozycja pionowa ducha #0
	clc
	adc height			; wysokość ducha
	tay

	lda positionX_old		; pozycja pozioma ducha #0
	:2 lsr @
	clc
	adc ladrLine,y
	sta ScreenAdr0
	lda #$00
	adc hadrLine,y
	sta ScreenAdr0+1		; adres pierwszego bajtu ekranu dla ducha #0


	lda positionY			; pozycja pionowa ducha #1
	clc
	adc height			; wysokość ducha 
	tay

	lda positionX			; pozycja pozioma ducha #1
	:2 lsr @
	clc
	adc ladrLine,y
	sta ScreenAdr1
	lda #$00
	adc hadrLine,y
	sta ScreenAdr1+1		; adres pierwszego bajtu ekranu dla ducha #1


E_9656	ldy #ShapeWidth-1		; przenosimy duchy od dołu do góry (pewnie w celu zminimalizowania mrugania)

	.rept ShapeWidth
	lda ShapeBuffer0-#,x
	eor (ScreenAdr0),y
	sta (ScreenAdr0),y

	lda (ScreenAdr1),y		; jeśli bajt tła to nie ma kolizji

	seq				; !!!!!!!!!!!!!!!! DETEKCJA KOLIZJI !!!!!!!!!!!!!!!!!
	sta collision			; !!!!!!!!!!! BANALNA W SWEJ PROSTOCIE !!!!!!!!!!!!!!

	eor ShapeBuffer1-#,x
	sta (ScreenAdr1),y
	
	ift #<>ShapeWidth-1
	dey
	eif
	.endr

	sec

	lda ScreenAdr0
	sbc #ScreenWidth
	sta ScreenAdr0
	bcs _skp0
	dec ScreenAdr0+1
	sec

_skp0	lda ScreenAdr1
	sbc #ScreenWidth
	sta ScreenAdr1
	bcs _skp1
	dec ScreenAdr1+1
	sec
_skp1
	txa
	sbc #ShapeWidth
	tax

	bpl E_9656

	mva	positionX	positionX_old
	mva	positionY	positionY_old
	mva	type		type_old
	mva	height		height_old
	mva	enabled		enabled_old
	mva	collision	collision_old

	rts
.endp


* -------------------------------------------------------------------
* ---	KOPIOWANIE DUCHA DO BUFORA, DUCHY MAJĄ SZEROKOŚĆ 3 BAJTÓW
* ---	JEDNAK BUFOR WYPEŁNIANY JEST 4 BAJTAMI, 4 BAJT JEST ZEROWANY
* -------------------------------------------------------------------
.proc	MoveShapeToBuffer

	mva	lAdrShape,y	ScreenAdr1
	mva	hAdrShape,y	ScreenAdr1+1

	ldy height			; wysokość ducha

	txa
	add mulTab,y
	sta max				; wysokość ducha*ShapeWidth+<ShapeBuffer

	ldy #0

moveShp
	.rept ShapeWidth
	ift #<>ShapeWidth-1
	lda (ScreenAdr1),y		; przenosimy do bufora bitmape ducha
	sta ShapeBuffer+#,x
	iny
	els
	lda #0
	sta ShapeBuffer+#,x		; ostatni bajt jest zerowany
	eif
	.endr

;	clc
	txa
	adc #ShapeWidth
	tax

	cpx #0
max	equ *-1
	bne moveShp
	rts
.endp


* ---------------------------------

lAdrShape	dta l(krab)
hadrShape	dta h(krab)

	.get 'crab.mic'

krab	@@CutMIC 0 0 ShapeWidth-1 16

* ---------------------------------

	run main

	.print 'PROC PutShape length: ',.len PutShape
	.print 'PROC MoveShapeToBuffer length: ',.len MoveShapeToBuffer

	opt l-
	icl '@@cutmic.mac'
