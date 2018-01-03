		.cr	6809
		.tf	ad574-mux-1.bin,BIN
		.lf	ad574-mux-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
txtBuff:	.bs 5	; storage for hex string
currentChannel	.bs	1	
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		.in		convert.inc	
		;

		;------------- 
		; ACC - channel
		; 0 - 421 10Vref, 
		; 1 - MCP9700 outdoor
		; 2 - LM35 on CPU
		; 3 - LM35 indoor
getADC:
		; set channel on MAC24A (VIA1.PB7/PB6)
		lsla
		lsla
		lsla
		lsla
		lsla
		lsla			<< 6
		anda	#%11000000
		; update bits
		sta		VIA1+ORB

		; dummy read/conv first
		lda		#$04	
		sta		VIA2+ORA
		nop
		lda		#$0
		sta		VIA2+ORA
		ldb		#40
.getADCdel
		decb
		bne		.getADCdel

		;
		; prepare to read real data 
		lda		#$04	
		sta		VIA2+ORA

		; MSB (4bits)
		lda		VIA1+IRB
		anda	#$0F
		; LSB (8bits)
		ldb		VIA1+IRA
		pshu	a,b
		; and start next conversion cycle		
		lda		#$0
		sta		VIA2+ORA

		pulu	a,b
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

		;via-1 - all as in
		clra
		sta 	VIA1+DDRA		; D0..D7 

		lda		#%11000000		; OUT b7,6 - A1,A0 of MAX24A
		sta 	VIA1+DDRB		; IN D8..D11 of AD574

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
caption:	.az '+10V OUTD CPU  INDR ' 

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
