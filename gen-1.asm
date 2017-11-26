		.cr	6809
		.tf	gen-1.bin,BIN
		.lf	gen-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
samplePtr:	.bs	2
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		.in		waves.inc			; sine pattern
		;
main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

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


.resetMessages:
		ldy		#messages
.here:

		jsr		getNextSample

		jsr		vfdClearDisplay
		
		ldx		,y++
		jsr		vfdPrint
		jsr 	delay
		
		cmpy	#messages_
		beq		.resetMessages

		jmp 	.here		; while(1);


           ;|12345678901234567890|		
msg1	.az	/=                   /
msg2	.az	/==                  /
msg3	.az	/===                 /
msg4	.az	/====                /
msg5	.az	/=====               /
msg6	.az	/======              /
msg7	.az	/=======             /
msg8	.az	/========            /
msg9	.az	/=========           /
msg10	.az	/==========          /

messages .dw msg1,msg2,msg3,msg4,msg5,msg6,msg7,msg8,msg9,msg10
messages_

		; gets next sample for D/A
getNextSample:
		pshu	x,a
		lda	[samplePtr]			; get sample at samplePtr
		sta	VIA1+ORA			; set voltage
		ldx	samplePtr			; get samplePtr itself
		inx						; ++
		cmpx #SINE_WAVE_256+$FF ; end?
		bne	getNextSampleExit	; if not skip ptr init
		ldx #SINE_WAVE_256		; reset ptr
getNextSampleExit:
		stx	samplePtr			; save samplePtr 
		pulu	x,a
		rts

 
delay:		
		pshu	X,B		; save X & B
		ldb	#10		; outer loop 
.delay1:		
		ldx	#2000		; inner loop 
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
