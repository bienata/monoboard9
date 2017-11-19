		.cr	6809
		.tf	serial-1.bin,BIN
		.lf	serial-1.lst
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

		; the simplest possible char outgoing transmission

		; ACIA init
		; 9600,8,N,1
		lda	#$0E
		sta	ACIA+CTLREG

		lda	#$08
		sta	ACIA+CMDREG
		
.here:
		lda	#'Q'
		sta	ACIA+TDR

		jsr 	delay

		jmp 	.here		; while(1);

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
