		.cr	6809
		.tf	vfd-test-1.bin,BIN
		.lf	vfd-test-1.lst
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
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		;
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

		jsr		vfdInit
		jsr 	delay	


.here:
		jsr		vfdClearDisplay

		lda		#VFD_LINE_1
		jsr		vfdSetPos

		ldx		#message1
		jsr		vfdPrint

		lda		#VFD_LINE_2+20-4
		jsr		vfdSetPos

		ldx		#message2
		jsr		vfdPrint

		jsr 	delay

		jsr		vfdClearDisplay

		lda		#VFD_LINE_2
		jsr		vfdSetPos

		ldx		#message2
		jsr		vfdPrint

		lda		#VFD_LINE_1+20-4
		jsr		vfdSetPos

		ldx		#message3
		jsr		vfdPrint

		jsr 	delay

		jmp 	.here		; while(1);

               ;|12345678901234567890|		
message1	.az	/1234/
message2	.az	/abcd/
message3	.az	/efgh/
message4	.az	/5678/
 

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
