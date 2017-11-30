		.cr	6809
		.tf	sin-irq-1.bin,BIN
		.lf	sin-irq-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here

samplePtr:	.bs	2

hexBuff:	.bs 5	; storage for hex string

aCounter	.bs 2	; 16 bit value as a counter
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		.in		waves.inc			; sine pattern
		.in		convert.inc			; first aid foo-s
		;
		;************************************************
		;
irqHandler:
		lda		#$ff
		sta		VIA1+IFR
		jsr		getNextSample
		rti
		;
		;************************************************
		;

divider		.eq	CLK2FREQ/25/256

main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; counter
		ldx		#00
		stx		aCounter

		; VFD
		; PB setup - all out, D0..D7 of CU20025
		; PA setup, outs: PA0 - E, PA1 - RS
		lda	#$ff
		sta		VIA2+DDRB		
		sta 	VIA2+DDRA
		clra
		sta 	VIA2+ORA
		sta 	VIA2+ORB

		; AD558
		lda	#$ff
		sta		VIA1+DDRA		
		clra
		sta 	VIA1+ORA			; = 0V

		jsr		vfdInit
		jsr 	delay	

		; sin gen init
		ldx		#SINE_WAVE_256
		stx		samplePtr


		; setup for timer 1/via1
		lda	#divider	; lo
		sta	VIA1+T1CL		
		lda	/divider	; hi
		sta	VIA1+T1CH
		lda	#$c0		;ACR_T1CR3
		sta	VIA1+ACR

		lda	#$c0		;IER
		sta	VIA1+IER

		cli			;    enable irq


.loop:
		jsr		vfdClearDisplay

		lda		#5				; clear text buff
		ldx		#hexBuff
		jsr		memZero

		ldx		aCounter		; counter++
		lda		,x+				; inc x :-)
		stx		aCounter		

		tfr		x,d

		ldx		#hexBuff		; to hex
		jsr		word2hex

		jsr		vfdPrint		; display
		
		jsr 	delay
		

		jmp 	.loop		; while(1);

		; gets next sample for D/A
getNextSample:
	;	pshu	x,a
		lda	[samplePtr]			; get sample at samplePtr
		sta	VIA1+ORA			; set voltage
		ldx	samplePtr			; get samplePtr itself
		inx						; ++
		cmpx #SINE_WAVE_256+$FF ; end?
		bne	getNextSampleExit	; if not skip ptr init
		ldx #SINE_WAVE_256		; reset ptr
getNextSampleExit:
		stx	samplePtr			; save samplePtr 
	;	pulu	x,a
		rts

 
delay:		
		pshu	X,B		; save X & B
		ldb	#10		; outer loop 
.delay1:		
		ldx	#1000		; inner loop 
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
		>DEF_SYS_JUMP IRQ_____, irqHandler
		>DEF_SYS_JUMP SWI_____, UNDEFINED
		>DEF_SYS_JUMP NMI_____, UNDEFINED
		>DEF_SYS_JUMP RESET___, main
                ;
                ; :-)
