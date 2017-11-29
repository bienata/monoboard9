		.co
		------------------------------------------------------------------------
		- conversion and other memory utilities
		------------------------------------------------------------------------
		.ec
		
		;-----------------------------------------------------------------------
		; byte2hex - converts one byte from A to two ASCII chars pointer by X
		;
		; in: 	a - byte to convert
		;		x - 2 char buff for result, reg stays unchanged
byte2hex:		
		pshu	x,y,b			; uses y,b then save
		pshu	a
		ldy		#.b2hexDat	; table of chars
		exg		b,a			; input in b
		lsrb
		lsrb
		lsrb
		lsrb				; >> 4
		andb	#$0f		; first 4 bits
		lda		b,y			; a := ascii [ b ]
		sta		0,x+		; msb
		pulu	a
		exg		b,a			; input in b again
		andb	#$0f		; first 4 bits
		lda		b,y			; a := ascii [ b ]
		sta		0,x			; lsb
		pulu 	x,y,b		; gimme back
		rts
.b2hexDat
		.as '0123456789ABCDEF'
		
		
		;-----------------------------------------------------------------------
		; word2hex - converts word from D(A|B) to four ASCII chars pointer by X		
		;
		; in: 	d - word to convert (a-msb,b-lsb)
		;		x - 4 char buff for result, stays unchanged
word2hex:
		pshu	d,x		; ab,x protection
		jsr	byte2hex	; msb as is
		leax	2,x		; x += 2, next 2 chars
		tfr		b,a		; lsb from b
		jsr	byte2hex	; msb as is
		pulu	d,x		; 
		rts

		
		;-----------------------------------------------------------------------
		; memZero - clears given by A number of bytes starting from X
		;
		; a - num. bytes to fill
		; x - start ptr
memZero:
		pshu	x,d
		clrb
.memZero
		stb		,x+		; *ptr++ = 0x00
		deca
		bne		.memZero
		pulu	x,d
		rts

