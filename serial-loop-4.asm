		.cr	6809
		.tf	serial-loop-4.bin,BIN
		.lf	serial-loop-4.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
textMessage		.bs 10				; any text here
MSG_TEXT_LEN	.eq	*-textMessage	; compute length
rxBuffer		.bs 20				; buff for incoming stuff
RX_BUFF_LEN		.eq	*-rxBuffer		; compute length
counter			.bs 2	
rxBufferPtr		.bs 2	

		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		.in		convert.inc	
		;

irqHandler
		; confirm irq reading stat
		lda		ACIA+STATR		
		; get char from RX
		lda		ACIA+RDR

		sta		ACIA+RDR	; do echo

		; store char in buff
		ldx		rxBufferPtr
		sta		,x+			; save char
		stx		rxBufferPtr	; save prt
		clra	
		sta		,x+			; save NULL after
		; check against buff end
		cmpx	#rxBuffer+RX_BUFF_LEN
		bne		.hasEnoughSpace
		; reinit rx buff
		ldx		#rxBuffer
		stx		rxBufferPtr
.hasEnoughSpace
		rti



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
		sta 	VIA1+DDRB		; D8..D11 of AD574

		ldx		#0				; counter := 0000
		stx		counter

		; init rxBufferPrt = &rxBuffer
		ldx		#rxBuffer
		stx		rxBufferPtr	

		; ACIA init
		; 9600,8,N,1
		; soft reset
		sta	ACIA+PRESET

		lda	#$09
		sta	ACIA+CMDREG

		lda	#$1E
		sta	ACIA+CTLREG



		jsr		vfdInit
		jsr 	delay	

		lda		#RX_BUFF_LEN
		ldx		#rxBuffer
		jsr		memZero

		cli		; go on with IRQ

.here:
		jsr		vfdClearDisplay

		lda		#VFD_LINE_1
		jsr		vfdSetPos
		ldx		#rxBuffer
		jsr		vfdPrint

		lda		#VFD_LINE_2
		jsr		vfdSetPos


		; show live counter and buff ptr in next line
		lda		#MSG_TEXT_LEN
		ldx		#textMessage
		jsr		memZero

		ldd		counter
		pshu	d
		ldx		#textMessage
		jsr		word2hex
		ldx		#textMessage
		jsr		vfdPrint
		; counter++
		pulu	x
		inx
		stx		counter
		
		lda		#' '		
		jsr		vfdData		

		ldd		rxBufferPtr
		ldx		#textMessage
		jsr		word2hex
		ldx		#textMessage
		jsr		vfdPrint


		jsr		delay		

		jmp 	.here		; while(1);

 
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
		ldx	#10000		; inner loop 
.delay2:	
		dex			; x--
		bne	.delay2		; until x != 0
		decb			; b--
		bne	.delay1		; until b != 0
		pulu	X,B		; restore
		rts		
		;

msgFrameStart:	.az '^'
msgFrameSep:	.az ':'
msgFrameStop:	.az #$d,#$a



		; system jump table, must be in this particular order
		>DEF_SYS_JUMP RESERVED, UNDEFINED
		>DEF_SYS_JUMP SWI3____, UNDEFINED
		>DEF_SYS_JUMP SWI2____, UNDEFINED
		>DEF_SYS_JUMP FIRQ____, UNDEFINED
		>DEF_SYS_JUMP IRQ_____, irqHandler
		>DEF_SYS_JUMP SWI_____, UNDEFINED
		>DEF_SYS_JUMP NMI_____, UNDEFINED
		>DEF_SYS_JUMP RESET___, main
                ;
                ; :-)
