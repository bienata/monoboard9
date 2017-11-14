		.cr	6809
		.tf	timer1.bin,BIN
		.lf	timer1.lst
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	monoboard9.inc
		;
divider		.eq	CLK2FREQ/2/500

main_prog:	
		lds	#USER_STACK

		lda 	#PB7OUT+PB0OUT
		sta 	VIA1+DDRB
		lda 	#$00
		sta 	VIA1+ORB
		
		lda	#divider	; lo
		sta	VIA1+T1CL
		
		lda	/divider	; hi
		sta	VIA1+T1CH
		
		lda	#$c0		;ACR_T1CR3
		sta	VIA1+ACR
		;
		bra	$		; while(1);
		;
		; system jump table, must be in this particular order
		>DEF_SYS_JUMP RESERVED, UNDEFINED
		>DEF_SYS_JUMP SWI3____, main_prog
		>DEF_SYS_JUMP SWI2____, main_prog
		>DEF_SYS_JUMP FIRQ____, main_prog
		>DEF_SYS_JUMP IRQ_____, main_prog
		>DEF_SYS_JUMP SWI_____, main_prog
		>DEF_SYS_JUMP NMI_____, main_prog
		>DEF_SYS_JUMP RESET___, main_prog
                ;
                ; :-)