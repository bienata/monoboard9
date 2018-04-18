		.cr	6809
		.tf	tm1638-1.bin,BIN
		.lf	tm1638-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
temp	.bs		1
dispos	.bs		1
hexString		.bs	5				; for bin->ascii hex conv
hexStringLen	.eq	$-hexString
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;

		.in 7-seg.inc
		.in 	convert.inc		; utils & helpers

PORT_TM1638	.eq		VIA2+ORB
DAT_TM1638	.eq		1
CLK_TM1638	.eq		2
STB_TM1638	.eq		4





		; A - byte to send in raw form		
tm1638_postbyte:
		pshu a,b,x
		ldx		#8
		sta		temp	; save input
.loop:
		; dt=0; ck=0, stb - bez zmian
		anda	#%0000.0001
		beq		.skipZero
		;set data pin H
		ldb		#DAT_TM1638
		stb		PORT_TM1638
.skipZero:
		; ck pulse
		; __/--
		ldb		#CLK_TM1638
		orb		PORT_TM1638
		stb		PORT_TM1638
		; --\__
		ldb		#0
		stb		PORT_TM1638
		lda temp		; restore for a moment
		lsra			; >> next incoming bit
		sta temp		; save back
		dex				; next byte
		bne		.loop
		pulu	a,b,x		
		rts




		; A - command to execute
tm1638_command:
		pshu a,b
		ldb #0	; strobe=0, dt=0, ck=0
		stb PORT_TM1638
		jsr tm1638_postbyte
		ldb #STB_TM1638		; strobe=1, dt=0, ck=0
		stb PORT_TM1638
		pulu a,b
		rts



		; A - 7-seg code to set
		; B - display position (left 0..7 right)
tm1638_writeat:
		pshu a,b,x
		tfr d,x		; save a,b in x
		lslb			; << 1 
		addb	#$C0	; digits
		lda #0	; strobe=0, dt=0, ck=0
		sta PORT_TM1638
		tfr b,a			; put add. in B and send
		jsr tm1638_postbyte
		tfr x,d			; restore input
		jsr tm1638_postbyte
		ldb #STB_TM1638		; strobe=1, dt=0, ck=0
		stb PORT_TM1638
		pulu a,b,x
		rts


		; A - 7-seg code to set
		; B - display position (left 0..7 right)
tm1638_led:
		pshu a,b,x
		tfr d,x		; save a,b in x
		lslb			; << 1 
		addb	#$C1	; free leds
		lda #0	; strobe=0, dt=0, ck=0
		sta PORT_TM1638
		tfr b,a			; put add. in B and send
		jsr tm1638_postbyte
		tfr x,d			; restore input
		jsr tm1638_postbyte
		ldb #STB_TM1638		; strobe=1, dt=0, ck=0
		stb PORT_TM1638
		pulu a,b,x
		rts


		; --- 
main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; ACIA init
		; 9600,8,N,1
		lda	#$0E
		sta	ACIA+CTLREG
		lda	#$08
		sta	ACIA+CMDREG

		; via-2 init
		lda	#$ff
		; PA all out
		sta	VIA2+DDRB		
		lda #STB_TM1638		; stb=H !!, reszta L
		sta	VIA2+ORB
		

		lda #$8F
		jsr tm1638_command

.here:

		ldb #0
		ldx	#digits
.loop
		lda ,x+
		jsr tm1638_writeat
		incb
		cmpb #8
		bne .loop

		ldb #0
.loop1
		lda #1
		jsr tm1638_led
		jsr delay
		incb
		cmpb #8
		bne .loop1


		ldb #7
.bright
		tfr b,a
		adda #$88
		jsr tm1638_command
		jsr delay
		decb
		bne .bright

		ldb #0
.bright1
		tfr b,a
		adda #$88
		jsr tm1638_command
		jsr delay
		incb
		cmpb #8
		bne .bright1



		ldb #0
		ldx	#digits+8
.loop3
		lda ,x+
		jsr tm1638_writeat
		incb
		cmpb #8
		bne .loop3


		ldb #0
.loop2
		lda #0
		jsr tm1638_led
		jsr delay
		incb
		cmpb #8
		bne .loop2


		jmp .here

digits:	.db DIG_0,DIG_1,DIG_2,DIG_3
		.db DIG_4,DIG_5,DIG_6,DIG_7
		.db DIG_8,DIG_9,DIG_A,DIG_B
		.db DIG_C,DIG_D,DIG_E,DIG_F

aliveMsg:	
		.az /kuciak/,#$d,#$a
eol:	
		.az #$d,#$a

		;----------------

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
		ldx	#3000		; inner loop 
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
				;
