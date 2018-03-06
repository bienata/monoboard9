		.cr	6809
		.tf	dac0808-2.bin,BIN
		.lf	dac0808-2.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
xPos	.bs		1
yPos	.bs		1
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		;

irqHandler
		; confirm irq reading stat
		lda		ACIA+STATR		
		; get char from RX
		lda		ACIA+RDR
		sta		ACIA+RDR	; do echo
		;
		; change settings according to given letter

		cmpa #'X'
		beq incrementXpos

		cmpa #'x'
		beq decrementXpos

		cmpa #'Y'
		beq incrementYpos

		cmpa #'y'
		beq decrementYpos

		rti

incrementXpos:
		inc xPos
		inc xPos
		inc xPos
		inc xPos
		rti

decrementXpos:
		dec xPos
		dec xPos
		dec xPos
		dec xPos
		rti

incrementYpos:
		inc yPos
		inc yPos
		inc yPos
		inc yPos
		rti

decrementYpos:
		dec yPos
		dec yPos
		dec yPos
		dec yPos
		rti

main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; text send

		; ACIA init
		; 9600,8,N,1
		; soft reset
		sta	ACIA+PRESET
		lda	#$09
		sta	ACIA+CMDREG
		lda	#$1E
		sta	ACIA+CTLREG



		; via-1 init
		lda	#$ff
		; PA,PB setup - all out
		sta		VIA1+DDRA		
		sta 	VIA1+DDRB

		; init cursors, grid
		lda	#$80		; 1/2 of screen
		sta xPos
		sta yPos

		cli

doAll:
		; pass 1 - sine + time base 
		ldy	#SINE_WAVE_256
		lda #0
		sta VIA1+ORB	
doSine:
		; do wave
		lda	,y+
		sta VIA1+ORA	
		; do timebase 
		inc VIA1+ORB

		cmpy	#SINE_WAVE_256+$FE
		bne	doSine


		; pass 2 - scale + timebase
		lda #0
		sta VIA1+ORB
		lda #0
		sta VIA1+ORA		
		ldx	#0
doAxis:
		; tick
		lda	#$85
		sta VIA1+ORA		
doTick:
		dec VIA1+ORA		
		lda VIA1+IRA		
		cmpa #$75
		bne doTick
		; continue with X axis
		lda VIA1+IRB
		adda #$10
		sta VIA1+ORB
		bne doAxis

		
		; pass 3 - draw vertical cursor
		; set cursor pos
		lda xPos
		sta VIA1+ORB

		; tick
		lda	#$F0
		sta VIA1+ORA		
doVcursor:
		dec VIA1+ORA		
		lda VIA1+IRA		
		cmpa #$10
		bne doVcursor
		

		; pass 4 - draw horizontal cursor
		; set cursor pos
		lda yPos
		sta VIA1+ORA

		; tick
		lda	#$F0
		sta VIA1+ORB		
doHcursor:
		dec VIA1+ORB		
		lda VIA1+IRB		
		cmpa #$10
		bne doHcursor


		jmp  doAll

		.in waves.inc

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
