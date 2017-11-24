		.cr	6809
		.tf	ad558-saw.bin,BIN
		.lf	ad558-saw.lst
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	monoboard9.inc
		;

main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; PA setup OUT
		lda	#$FF
		sta	VIA1+DDRA

		lda	#$00
		sta	VIA1+ORA
.loop:		
		inc	VIA1+ORA
		bra .loop
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
