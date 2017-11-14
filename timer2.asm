		.cr	6809
		.tf	timer2.bin,BIN
		.lf	timer2.lst
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	monoboard9.inc
		;
		; vars, 0-page?
temp		.eq	$10 	; (10,11)	
		;
FREQ		.ma
		.dw	CLK2FREQ/2/]1
		.em
		
freqArray:	>FREQ 10
		>FREQ 20
		>FREQ 40
		>FREQ 50
		>FREQ 100
		>FREQ 200
		>FREQ 300
		>FREQ 400		
		>FREQ 500
		>FREQ 600
		>FREQ 700		
		>FREQ 800
		>FREQ 900
		>FREQ 1000		
		>FREQ 1500
		>FREQ 2000
freqArrayEnd:	


main_prog:	
		lds	#USER_STACK

		; PA setup
		lda	#PA3OUT+PA2OUT+PA1OUT+PA0OUT
		sta	VIA1+DDRA
		
		; PB setup
		lda 	#PB7OUT+PB0OUT
		sta 	VIA1+DDRB
		lda 	#$00
		sta 	VIA1+ORB
		

		lda	#$c0		;ACR_T1CR3
		sta	VIA1+ACR

fistFreq:	
		ldb	#$0		; B := 0
		ldx	#freqArray		
nextFreq:		
		stb	VIA1+ORA	; display
		incb			; b++
		
		lda	,x		; A := *freqArray		
		sta	VIA1+T1CH	; as HI
		inx			; x++
		lda	,x		; A := *freqArray		
		sta	VIA1+T1CL	; as LO	
		inx			; x++		
		;
		jsr	delay		 		
		;
		cmpx 	#freqArrayEnd	; not CPX (?!!!!) $8C opcode
		bne	nextFreq	; continue if != end
		
		jmp	fistFreq	; repeat all
		
		
		;
delay:		stx	temp		; save X in temp
		pshb			; stack B
		ldb	#10		; outer loop - 10x
.delay1:		
		ldx	#60000		; inner loop 60K
.delay2:	dex			; x--
		nop
		bne	.delay2		; until x != 0
		decb			; b--
		bne	.delay1		; until b != 0
		pulb			; unstack B		
		ldx	temp		; restore		
		rts		
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