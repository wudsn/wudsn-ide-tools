
// -----------------------------------------------------------------------------
//				     IMUL_CX.
// -----------------------------------------------------------------------------

procedure opt_TEMP_IMUL_CX;
begin

    if IFDEF_MUL16(8) and			     	 					// .ifdef fmulinit	; 8
      												// fmulu_16		; 9
      												// els			; 10
												// imulCX		; 11
												// eif			; 12

       (pos('mva ', TemporaryBuf[0]) > 0) and (pos('mva :STACK', TemporaryBuf[0]) = 0) and	// mva .. X		; 0
       (TemporaryBuf[1] = #9'mva #$00 ' + copy(TemporaryBuf[5], 6, 256)) and 			// mva #$00 X+1		; 1
       lda(2) and										// lda X		; 2
       (TemporaryBuf[3] = #9'sta :ecx') and							// sta :ecx		; 3
       (TemporaryBuf[4] = #9'sta :eax') and							// sta :eax		; 4
       lda(5) and										// lda X+1		; 5
       (TemporaryBuf[6] = #9'sta :ecx+1') and							// sta :ecx+1		; 6
       (TemporaryBuf[7] = #9'sta :eax+1') then							// sta :eax+1		; 7
      begin
	TemporaryBuf[i+5] := '~';
	TemporaryBuf[i+6] := '~';
	TemporaryBuf[i+7] := '~';

	TemporaryBuf[i+9] := #9'fmulu_8';

	TemporaryBuf[i+11]:= #9'imulCL';
       end;


    if IFDEF_MUL16(8) and			     	 					// .ifdef fmulinit	; 8
      												// fmulu_16		; 9
      												// els			; 10
												// imulCX		; 11
												// eif			; 12

       (TemporaryBuf[0] = #9'lda #$00') and							// lda #$00		; 0
       sta(1) and										// sta X+1		; 1
       lda(2) and										// lda X		; 2
       (TemporaryBuf[3] = #9'sta :ecx') and							// sta :ecx		; 3
       (TemporaryBuf[4] = #9'sta :eax') and							// sta :eax		; 4
       lda(5) and										// lda X+1		; 5
       (TemporaryBuf[6] = #9'sta :ecx+1') and							// sta :ecx+1		; 6
       (TemporaryBuf[7] = #9'sta :eax+1') then							// sta :eax+1		; 7
     if copy(TemporaryBuf[1], 6, 256) = copy(TemporaryBuf[5], 6, 256) then
      begin
	TemporaryBuf[i+5] := '~';
	TemporaryBuf[i+6] := '~';
	TemporaryBuf[i+7] := '~';

	TemporaryBuf[i+9] := #9'fmulu_8';

	TemporaryBuf[i+11]:= #9'imulCL';
       end;

end;	// procedure
