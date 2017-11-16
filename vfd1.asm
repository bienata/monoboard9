		.cr	6809

		.tf	vfd1.bin,BIN
		.lf	vfd1.lst

		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	monoboard9.inc
		;

vfdClearDisplay:
		lda		#$01
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 

vfdCursorHome:
		lda		#$02
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 

vfdEntryModeSet:
		lda		#$04|1<<2		; I/D = 1, S = 0
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 

vfdDisplayOn:
		lda		#$08|$04		; D=1, C=0, B=0
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 

vfdDisplayOff:
		lda		#$08		; D=0 (!!), C=0, B=0
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 

vfdInit:
		lda		#$30
		jsr		vfdCommand
		lda		#$30
		jsr		vfdCommand
		lda		#$30
		jsr		vfdCommand	
		jsr		vfdEntryModeSet
		jsr		vfdDisplayOn
		rts

vfdData:
		; D0-7, E^, RS=1
		; 
		sta 	VIA1+ORA
		lda #$03
		sta 	VIA1+ORB	; E=1, RS=1
		nop
		lda #$00	
		sta 	VIA1+ORB	; E=0, RS=0
		rts		; of vfdData

vfdCommand:
		; D0-7, E^, RS=0
		; 
		sta 	VIA1+ORA
		lda #$01
		sta 	VIA1+ORB	; E=1, RS=0
		nop
		lda #$00	
		sta 	VIA1+ORB	; E=0, RS=0
		nop
		rts					; of vfdCommand


vfdPrint:
		; X - address of null terminated string
.vfdPr	lda		,x+					; *msg++
		beq		.vfdPrintExit		; if char == 0 then exit		
		jsr		vfdData				; else print 
		jmp		.vfdPr
.vfdPrintExit
		rts


main_prog:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; PA setup - all out, D0..D7 of CU20025
		lda	#PA7OUT+PA6OUT+PA5OUT+PA4OUT+PA3OUT+PA2OUT+PA1OUT+PA0OUT
		sta	VIA1+DDRA
		
		; PB setup, outs: PB0 - E, PB1 - RS
		lda 	#PB0OUT+PB1OUT
		sta 	VIA1+DDRB
		clra
		sta 	VIA1+ORA
		sta 	VIA1+ORB

		jsr		vfdInit
		jsr 	delay	

.here:
		jsr		vfdClearDisplay
		jsr		vfdCursorHome
		ldx		#message1
		jsr		vfdPrint

		jsr 	delay

		jsr		vfdClearDisplay
		jsr		vfdCursorHome
		ldx		#message2
		jsr		vfdPrint

		jsr 	delay	

		jmp 	.here		; while(1);

               ;|12345678901234567890|		
message1	.az	/tasza was here/
message2	.az	/MONOBOARD6809 by EKF/
 
		;
vfdDelay:
		pshu	A
		lda		#$ff
.vfdDel1:
		deca
		nop
		bne		.vfdDel1
		pulu 	A
		rts


delay:		
		pshu	X,B		; save X & B
		ldb	#10		; outer loop 
.delay1:		
		ldx	#5000		; inner loop 
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
