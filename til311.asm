		.cr	6809
		
		.tf	til311.bin,BIN
		.lf	til311.lst
		
		; stuff related to MB09 hardware
		.in 	monoboard9.inc 
		
		.or 	$E000
		.bs	$1000, $FF
		
main_prog:	
		; stack setup
		lds	#$500		
		; PA @ VIA1 setup, 3..0 - out
		lda	#PA3OUT|PA2OUT|PA1OUT|PA0OUT ; 
		sta	VIA1+DDRA
		  
		lda	#$00		; a = 0
loop:		  
		sta	VIA1+ORA	; display 
		inca			; a++
		jsr	delay		; wait
		bra 	loop		; repeat
		
delay:		ldx	#30000		;x=duzo
delay1:		dex			;x--
		nop
		bne	delay1		;until != 0
		rts
				
		; system jump table, must be in this particular order
		>DEF_SYS_JUMP RESERVED, UNDEFINED
		>DEF_SYS_JUMP SWI3____, UNDEFINED
		>DEF_SYS_JUMP SWI2____, UNDEFINED
		>DEF_SYS_JUMP FIRQ____, UNDEFINED
		>DEF_SYS_JUMP IRQ_____, UNDEFINED
		>DEF_SYS_JUMP SWI_____, UNDEFINED
		>DEF_SYS_JUMP NMI_____, UNDEFINED
		>DEF_SYS_JUMP RESET___, main_prog
                ;
                ; end of folks