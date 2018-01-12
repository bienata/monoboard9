		.cr	6809
		.tf	adc0816-mux-1.bin,BIN
		.lf	adc0816-mux-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
txtBuff:	.bs 5	; storage for hex string
currentChannel	.bs	1	
binValue16			.bs	2					; 2 bytes 
bcdValue8			.bs	4					; 4 bytes / 8 digits

		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		.in		convert.inc	
		;

getADC:
		; mux: ALE = VIA1.PB4
		;		ADD_B = PB.1
		;		ADD_A = PB.0
		; 
		; adc:  D7..D0 - VIA1.PA7..PA0
		; 		START = VIA1.PB7

		; set channel
		anda	#%0000.0011
		sta		VIA1+ORB
		; ALE + START
		lda		#%1001.0000
		ora		VIA1+ORB
		sta		VIA1+ORB
		nop
		lda		#%0110.1111
		anda	VIA1+ORB
		sta		VIA1+ORB
		; wait a moment
		ldb		#$80
.omg:	decb
		bne		.omg
		; read data
		lda		#$00
		ldb		VIA1+IRA
		rts



main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		lda	#$ff
		; PB setup - all out, D0..D7 of CU20025
		sta		VIA2+DDRB		
		; PA setup, outs: PA0 - E, PA1 - RS
		sta 	VIA2+DDRA

		clra
		sta 	VIA2+ORA
		sta 	VIA2+ORB

		;via-1 - all PA as in
		;	 all PB as OUT

		lda		#$00
		sta 	VIA1+DDRA		; in, data from ADC

		lda		#$ff
		sta 	VIA1+DDRB		; out, mux ctrl

		jsr		vfdInit
		jsr 	delay	


.here:
		jsr		vfdClearDisplay

		lda		#VFD_LINE_1
		jsr		vfdSetPos

		lda		#0
		sta		currentChannel

.doNext
		lda		#5
		ldx		#txtBuff
		jsr		memZero
		
		lda		currentChannel
		jsr		getADC
		std		binValue16

		ldy 	#binValue16			
		ldx		#bcdValue8+1		
		jsr 	binToBcd

		ldd		bcdValue8+2
		ldx		#txtBuff
		jsr		word2hex

		ldx		#txtBuff
		jsr		vfdPrint
		lda		#' '
		jsr		vfdData

		inc		currentChannel
		lda		currentChannel
		cmpa	#4
		bne		.doNext

		lda		#VFD_LINE_2
		jsr		vfdSetPos
		ldx		#caption
		jsr		vfdPrint


		jsr 	delay

		jmp 	.here		; while(1);

                ;12345678901234567890
caption:	.az 'Uref OUTD CPU  INDR ' 

delay:		
		pshu	X,B		; save X & B
		ldb	#10		; outer loop 
.delay1:		
		ldx	#10000		; inner loop 
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
