		.cr	6809
		.tf	serial-2.bin,BIN
		.lf	serial-2.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
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
		
.here:
		ldx	#message1
		jsr	serialSendText

		jsr 	delay

		ldx	#message2
		jsr	serialSendText

		jsr 	delay

		jmp 	.here		; while(1);

		; 
		; T - 54h to AD2 capture
message1:	
		.az /Tasza was here/,#$d,#$a


		; A - 41h to AD2 capture
message2:
		.az /Antonina has a cat :) /,#$d,#$a

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
