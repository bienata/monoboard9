		.cr	6809
		.tf	timer3.bin,BIN
		.lf	timer3.lst
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	monoboard9.inc
		;
FREQ	.ma
		.dw	CLK2FREQ/2/]1
		.em
		
freqArray:	
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
freqArrayEnd:	


main_prog:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

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

firstFreq:	
		clrb		; B := 0
		ldx	#freqArray		
.next1:		
		stb	VIA1+ORA	; display
		incb			; b++
		
		lda	,x+			; A := *(freqArray++)		
		sta	VIA1+T1CH	; as HI
		lda	,x+			; A := *(freqArray++)		
		sta	VIA1+T1CL	; as LO	
		;
		jsr	delay	
		;	 		
		cmpx 	#freqArrayEnd	
		bne	.next1		; continue if != end
		;
		; using D reg (A|B) pair
		;
		clrb			; B := 0
		ldx	#freqArray		
.next2:		
		stb	VIA1+ORA	; display
		incb			; b++

		pshu	B		; save B
		ldd	,x++		; A := *freq, B := *(freq+1), freq +=2 
		sta	VIA1+T1CH	; set HI from A
		stb	VIA1+T1CL	; and LO from B
		pulu 	B		; recover B
		;
		jsr	delay	
		;	 		
		cmpx 	#freqArrayEnd	
		bne	.next2		; continue if != end
		;
		
		jmp	firstFreq	; repeat all
		
		
		;
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
		>DEF_SYS_JUMP SWI3____, main_prog
		>DEF_SYS_JUMP SWI2____, main_prog
		>DEF_SYS_JUMP FIRQ____, main_prog
		>DEF_SYS_JUMP IRQ_____, main_prog
		>DEF_SYS_JUMP SWI_____, main_prog
		>DEF_SYS_JUMP NMI_____, main_prog
		>DEF_SYS_JUMP RESET___, main_prog
                ;
                ; :-)
