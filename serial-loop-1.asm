		.cr	6809
		.tf	serial-loop-1.bin,BIN
		.lf	serial-loop-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
txtBuff:	.bs 5	; storage for hex string
txtCounter	.bs 5	; storage for hex string
rxBuff		.bs 32	; receive buff
frameCntr	.bs	2		

		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in		convert.inc	
		;
main:	
		lds	#SYSTEM_STACK

		; ACIA init
		; 9600,8,N,1
		; soft reset
		sta	ACIA+PRESET

		lda	#$0B
		sta	ACIA+CMDREG

		lda	#$1E
		sta	ACIA+CTLREG

.here:
		; wait for char
		jsr		serialGetChar

		suba	#32				; upcase

		; put it back 
		jsr		serialPutChar

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

serialGetString
		ldx		#rxBuff
.getNextChar:
		jsr 	serialGetChar
		cmpa	#$d			; enter?
		beq		.done
		sta		,x+
		clra
		sta		,x+
		bra		.getNextChar
.done:		
		rts


serialGetChar:
.waitChar:
		lda		ACIA+STATR
		anda	#$08
		beq		.waitChar
		lda		ACIA+RDR
		rts



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
		>DEF_SYS_JUMP IRQ_____, UNDEFINED
		>DEF_SYS_JUMP SWI_____, UNDEFINED
		>DEF_SYS_JUMP NMI_____, UNDEFINED
		>DEF_SYS_JUMP RESET___, main
                ;
                ; :-)
