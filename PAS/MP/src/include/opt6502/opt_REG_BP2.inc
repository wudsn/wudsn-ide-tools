// -------------------------------------------------------------------------- //
//				     REG BP2.
// -------------------------------------------------------------------------- //

  Rebuild;

  i:=0;
  k:=0;

  while i < l do begin

//   if listing[i]<>'' then
    if mwy_bp2(i)							// mwy a bp2				; 0

       or

       ( lda_a(i) and							// lda TEXT_BUF				; 0
         add(i+1) and (add_stack(i+1) = false) and			// add R				; 1
	 sta_bp2(i+2) and						// sta :bp2				; 2
	 (listing[i+3] = listing[i] + '+1') and				// lda TEXT_BUF+1			; 3
	 adc(i+4) and							// adc R+1				; 4
	 sta_bp2_1(i+5) )						// sta :bp2+1				; 5

       or

       ( lda_a(i) and (lda_stack(i) = false) and			// lda P+1				; 0
         sta_stack(i+1) and 						// sta :STACKORIGIN+STACKWIDTH		; 1
	 lda_a(i+2) and (listing[i] = listing[i+2] + '+1') and		// lda P				; 2
	 asl_a(i+3) and							// asl @				; 3
	 rol_stack(i+4) and						// rol :STACKORIGIN+STACKWIDTH		; 4
	 add(i+5) and (add_stack(i+5) = false) and			// add RSON				; 5
	 sta_bp2(i+6) and						// sta :bp2				; 6
	 lda_a(i+7) and							// lda RSON+1				; 7
	 adc_stack(i+8) and						// adc :STACKORIGIN+STACKWIDTH		; 8
	 sta_bp2_1(i+9) and						// sta :bp2+1				; 9
         (copy(listing[i+7], 6, 256) = copy(listing[i+5], 6, 256) + '+1') and
         (copy(listing[i+1], 6, 256) = copy(listing[i+4], 6, 256)) and
	 (copy(listing[i+1], 6, 256) = copy(listing[i+8], 6, 256)) )

       or

       ( lda_a(i) and (lda_stack(i) = false) and			// lda P				; 0
         sta_stack(i+1) and 						// sta :STACKORIGIN			; 1
	 lda_a(i+2) and (listing[i+2] = listing[i] + '+1') and		// lda P+1				; 2
	 asl_stack(i+3) and						// asl :STACKORIGIN			; 3
	 rol_a(i+4) and							// rol @				; 4
	 sta_stack(i+5) and						// sta :STACKORIGIN+STACKWIDTH		; 5
	 lda_a(i+6) and							// lda RSON				; 6
	 add_stack(i+7) and						// add :STACKORIGIN			; 7
	 sta_bp2(i+8) and						// sta :bp2				; 8
	 lda_a(i+9) and							// lda RSON+1				; 9
	 adc_stack(i+10) and						// adc :STACKORIGIN+STACKWIDTH		; 10
	 sta_bp2_1(i+11) and						// sta :bp2+1				; 11
         (copy(listing[i+9], 6, 256) = copy(listing[i+6], 6, 256) + '+1') and
         (copy(listing[i+1], 6, 256) = copy(listing[i+3], 6, 256)) and
	 (copy(listing[i+1], 6, 256) = copy(listing[i+7], 6, 256)) and
	 (copy(listing[i+5], 6, 256) = copy(listing[i+10], 6, 256)) )

        then begin


	if asl_stack(i+3) and rol_a(i+4) then begin
	 arg0:='&;'+GetString(i)+';'+GetString(i+2)+';'+GetString(i+6)+';'+GetString(i+9)+';';
	 k:=12;
	end else
	if asl_a(i+3) and rol_stack(i+4) then begin
	 arg0:='%;'+GetString(i)+';'+GetString(i+2)+';'+GetString(i+5)+';'+GetString(i+7)+';';
	 k:=10;
	end else
        if lda_a(i) then begin
	 arg0:='+;'+GetString(i)+';'+GetString(i+1)+';'+GetString(i+3)+';'+GetString(i+4)+';';
	 k:=6;
	end else begin
	 arg0:=listing[i]; arg0[4]:='?';
	 k:=1;
	end;


	if arg0 = optyBP2 then begin

	 if arg0[1] = '&' then begin
	  listing[i]   := '';
	  listing[i+1] := '';
	  listing[i+2] := '';
	  listing[i+3] := '';
	  listing[i+4] := '';
	  listing[i+5] := '';
	  listing[i+6] := '';
	  listing[i+7] := '';
	  listing[i+8] := '';
	  listing[i+9] := '';
	  listing[i+10]:= '';
	  listing[i+11]:= '';
         end else
	 if arg0[1] = '%' then begin
	  listing[i]   := '';
	  listing[i+1] := '';
	  listing[i+2] := '';
	  listing[i+3] := '';
	  listing[i+4] := '';
	  listing[i+5] := '';
	  listing[i+6] := '';
	  listing[i+7] := '';
	  listing[i+8] := '';
	  listing[i+9] := '';
	 end else
	 if arg0[1] = '+' then begin
	  listing[i]   := '';
	  listing[i+1] := '';
	  listing[i+2] := '';
	  listing[i+3] := '';
	  listing[i+4] := '';
	  listing[i+5] := '';
	 end else
	  listing[i] := '';

	end;

	optyBP2 := arg0;

	inc(i, k);

    end else begin

     if (optyBP2 <> '') and (sta_a(i) or sty(i) or asl(i) or rol(i) or lsr(i) or ror(i) or inc_(i) or dec_(i)) then
      if (pos('? '+copy(listing[i], 6, 256)+' ', optyBP2) > 0) or (pos(';'+copy(listing[i], 6, 256)+';', optyBP2) > 0) then optyBP2:='';

     if sta_bp2(i) or sta_bp2_1(i) or jsr(i) or
        (pos('l_', listing[i]) = 1) or (pos('b_', listing[i]) = 1) or (pos('c_', listing[i]) = 1) then optyBP2:='';

     inc(i);

    end;

  end;
