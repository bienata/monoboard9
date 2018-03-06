		.cr	6809
		.tf	dac0808-3.bin,BIN
		.lf	dac0808-3.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
xPos		.bs		1
hasCursor	.bs		1
hasAxis		.bs		1
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

		cmpa #'z'
		beq moveXleft

		cmpa #'x'
		beq moveXright

		cmpa #'c'
		beq toggleCursor

		cmpa #'a'
		beq toggleAxis

		rti

moveXright:
		inc xPos
		inc xPos
		inc xPos
		inc xPos
		rti

moveXleft:
		dec xPos
		dec xPos
		dec xPos
		dec xPos
		rti

toggleCursor:
		lda	hasCursor
		beq .setCurOn
		lda #0
		sta hasCursor
		rti
.setCurOn
		lda #1
		sta hasCursor
		rti


toggleAxis:
		lda	hasAxis
		beq .setAxisOn
		lda #0
		sta hasAxis
		rti
.setAxisOn
		lda #1
		sta hasAxis
		rti


processWave:
		ldy	#SINE_WAVE_256
		lda #0
		sta VIA1+ORB	
.sine:
		; do wave
		lda	,y+
		sta VIA1+ORA	
		; do timebase 
		inc VIA1+ORB
		cmpy	#SINE_WAVE_256+$FE
		bne	.sine
		rts

		;-----------------

processScale:
		; return if disabled
		lda	hasAxis
		beq	.processScaleEnd

		lda #0
		sta VIA1+ORB
		lda #0
		sta VIA1+ORA		
		ldx	#0
.axis:	; one tick
		lda	#$85
		sta VIA1+ORA		
.tick:
		dec VIA1+ORA		
		lda VIA1+IRA		
		cmpa #$75
		bne .tick
		; continue with X axis
		lda VIA1+IRB
		adda #$10
		sta VIA1+ORB
		bne .axis
.processScaleEnd:
		rts


processCursor:
		; return if disabled
		lda	hasCursor
		beq	.processCursorEnd

		; set cursor pos
		lda xPos
		sta VIA1+ORB
		; tick
		lda	#$FF
		sta VIA1+ORA		
.vertline:
		dec VIA1+ORA		
		lda VIA1+IRA		
		bne .vertline
		
		; get sample @ cursor
		ldb xPos
		ldx	#SINE_WAVE_256
		abx		
		lda	,x		; has wave[xpos] :)
		
		sta VIA1+ORA	; draw horizontal
		; tick
		lda	#$FF
		sta VIA1+ORB		
.horizline:
		dec VIA1+ORB		
		lda VIA1+IRB		
		bne .horizline
.processCursorEnd:
		rts

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

		lda #0
		; no cursor
		sta hasCursor
		; no axis
		sta hasAxis

		cli

loop:
		jsr	processWave
		jsr processScale
		jsr processCursor

		jmp  loop

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
