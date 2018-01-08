		.cr	6809
		.tf	serial-bcd-1.bin,BIN
		.lf	serial-bcd-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
binValue16			.bs	2					; 2 bytes 
bcdValue8			.bs	4					; 4 bytes / 8 digits

hexString		.bs	5				; for bin->ascii hex conv
hexStringLen	.eq	$-hexString

		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	convert.inc		; utils & helpers
		;
main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; text send

		; ACIA init
		; 9600,8,N,1
		lda	#$0E
		sta	ACIA+CTLREG
		lda	#$08
		sta	ACIA+CMDREG

		; oryginal HEX
		ldx	#$FFff
		stx	binValue16
		
.here:


		lda #4
		ldx	#bcdValue8
		jsr	memZero	

		lda #hexStringLen
		ldx	#hexString
		jsr	memZero	

		ldd	binValue16			; get 16 cntr to view
		ldx #hexString
		jsr	word2hex
		ldx	#hexString
		jsr	serialSendText

		ldx	#spc
		jsr	serialSendText		; separator

		ldy #binValue16			; y - point to bin
		ldx	#bcdValue8+1		; x - point to BCD dest, but skip one byte
		jsr binToBcd

		ldd	bcdValue8			; bytes 0,1 (digits 8765)
		ldx #hexString
		jsr	word2hex
	
		ldx	#hexString
		jsr	serialSendText

		ldd	bcdValue8+2			; bytes 2,3 (digits 4321)
		ldx #hexString
		jsr	word2hex

		ldx	#hexString
		jsr	serialSendText

		ldx	#eol
		jsr	serialSendText

		ldx	binValue16
		inx
		stx	binValue16

		jsr 	delay

		jmp 	.here		; while(1);

		;----------------
spc:	.az '  '
eol:	.az #10



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




serialSendText:
		; X - address of null terminated string
.ser1:
		lda		,x+					; *msg++
		beq		.serExit			; if char == 0 then exit		
		jsr		serialPutChar		; send 1 char
		jmp		.ser1
.serExit
		rts		
		
		;------

serialPutChar:
		; sends one character given in A
		; waits until Transmit Data Register Empty == 1 (transm. done)
		sta		ACIA+TDR		; put to send
.wait:
		lda		ACIA+STATR		; get status
		anda	#$10			; check bit 4 - TDR Empty
		beq		.wait			; wait for 1	
		rts

		;-----------------------------------------------------------------------

delay:		
		pshu	X,B		; save X & B
		ldb	#10		; outer loop 
.delay1:		
		ldx	#1000		; inner loop 
.delay2:	
		dex			; x--
		bne	.delay2		; until x != 0
		decb			; b--
		bne	.delay1		; until b != 0
		pulu	X,B		; restore
		rts		
		;
		
		; system jump table, must be in this particular order
		>DEF_SYS_JUMP RESERVED, UNDEFINED
		>DEF_SYS_JUMP SWI3____, UNDEFINED
		>DEF_SYS_JUMP SWI2____, UNDEFINED
		>DEF_SYS_JUMP FIRQ____, UNDEFINED
		>DEF_SYS_JUMP IRQ_____, UNDEFINED
		>DEF_SYS_JUMP SWI_____, UNDEFINED
		>DEF_SYS_JUMP NMI_____, UNDEFINED
		>DEF_SYS_JUMP RESET___, main
                ;
                ; :-)
