		.co
		------------------------------------------------------------------------
		- conversion and other memory utilities
		------------------------------------------------------------------------
		.ec
		

		.sm RAM
		.co
		|     BCD      | HI BIN LO |
		| +0 | +1 | +2 | +0  |  +1 |
		            <--|<==
		.ec
b2bcd_BCD:	.bs	3
b2bcd_BIN:	.bs	2
		.sm CODE
		;----------------
		; y - addr of src bin value (two bytes)
		; x - addr of dest BCD buffer (3 bytes for 65535)
binToBcd:
		pshu	x				; save dest BCD prt for later
		;clear BCD buffer
		clr		b2bcd_BCD+0
		clr		b2bcd_BCD+1
		clr		b2bcd_BCD+2
		; copy bin to working mem
		lda		0,y
		sta		b2bcd_BIN		; HI byte
		lda		1,y
		sta		b2bcd_BIN+1		; LO byte

		ldb		#16			; 16 bits to scroll
.nextBit
		pshu	b		
		; first << on bin LO
		lsl		b2bcd_BIN+1
		; rest via C marker, do << x 4
		rol		b2bcd_BIN+0
		rol		b2bcd_BCD+2
		rol		b2bcd_BCD+1
		rol		b2bcd_BCD+0
		; mem rotated, do correction if != last bit
		cmpb	#1
		beq		.skipLastCorrection
		ldb		#3
		ldx		#b2bcd_BCD
		jsr		binToBcdCorrect
.skipLastCorrection:
		pulu	b
		decb
		bne		.nextBit
		;copy result from working var
		pulu	x		; get original BCD bag
		lda		b2bcd_BCD+0
		sta		0,x
		lda		b2bcd_BCD+1
		sta		1,x
		lda		b2bcd_BCD+2
		sta		2,x
		rts
		;
		;-----
		; bcd correction on n bytes 
		; b - number of bytes  
		; x - ptr to bcd buff
binToBcdCorrect:
.corrNext:
		lda		,x
		pshu	a			; save for later
		anda 	#$F0		; high nibble
		cmpa	#$50		; >= 5?
		bcs		.hidone		; skip if not
		adda	#$30		; +30
.hidone:
		sta		,x			; save hi nibble
		pulu	a			; get accu again
		anda	#$0F		; low nibble
		cmpa	#$05		; >= 5?
		bcs		.lodone		; skip if not
		adda	#$03		; +03
.lodone
		ora		,x		  	; hi|lo
		sta		,x			; save result @ 
		inx
		decb
		bne		.corrNext
		rts


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


		;-----------------------------------------------------------------------
		; strCpy - copies one string to another until src is 0
		;
		; y - ptr of source string, must be NULL-ended
		; x - ptr of destination string
strCpy:
.next:
		lda	,y+
		sta	,x+
		bne	.next
		rts


		;-----------------------------------------------------------------------
		; strCat - copies one string to another until src is 0
		;
		; Y - src string to add		
		; X - dest string being expaned, must be long enough and 0-ended
strCat:
.findEnd:
		; scroll to end of dest(X) string
		lda		,x+
		bne		.findEnd
		; one char back! 
		dex
.next:
		lda		,y+		
		sta		,x+
		bne		.next
		rts





