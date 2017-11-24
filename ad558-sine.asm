		.cr	6809
		.tf	ad558-sine.bin,BIN
		.lf	ad558-sine.lst
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

.init
		ldx	#SINE_WAVE_256
.gen		
		lda	,x+
		sta	VIA1+ORA
		cmpx #SINE_WAVE_256+$FF		; $100 produces a sample gap :)
		bne	.gen
		bra .init
		;
		; sine pattern
		.in waves.inc
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
