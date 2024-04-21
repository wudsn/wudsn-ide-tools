/*
   Przyklad uzycia dyrektywy .REPT (repeat), .R (repeat_counter), .ENDR (end_repeat)
   oraz odpowiednika dyrektywy .R czyli znaku hash #

   po wartości określającej liczbę powtórzeń pętli możliwe jest podanie dodatkowych parametrów które zostaną
   najpierw obliczone a ich wynik podstawiony w sposób podobny jak w makrach, czyli
   :1 (parametr pierwszy), :2 (parametr drugi) itd.
   w ten sposoób możliwe jest jak w n/w przykładzie zdefiniowanie etykiet, np.: label0, label1, label2 ... label127
*/

	org $2000
 
	lda #"A"
 
	.rept 128,#
label:1
	sta $bc40+#
	sta $bc40+$100+#

	.endr

	lda #"B"*

	:128 sta $bc40+$80+#
	jmp *
