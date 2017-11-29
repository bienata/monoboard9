		.cr	6809
		.tf	serial-3.bin,BIN
		.lf	serial-3.lst
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
		;
main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		; text send

		; ACIA init
		; 9600,8,N,1
		lda	#$0E
		sta	ACIA+CTLREG
		lda	#$08
		sta	ACIA+CMDREG
		
.here:
		ldx	#vt100reset
		jsr	serialSendText

		ldx	#vt100blue
		jsr	serialSendText
		ldx	#vt100bold
		jsr	serialSendText

		ldx	#message1a
		jsr	serialSendText

		ldx	#vt100reset
		jsr	serialSendText

		ldx	#message1b
		jsr	serialSendText

		jsr 	delay

		ldx	#vt100green
		jsr	serialSendText
		ldx	#vt100bold
		jsr	serialSendText

		ldx	#message2a
		jsr	serialSendText

		ldx	#vt100reset
		jsr	serialSendText

		ldx	#message2b
		jsr	serialSendText

		ldx	#vt100reverse
		jsr	serialSendText

		ldx	#message2c
		jsr	serialSendText

		ldx	#vt100reset
		jsr	serialSendText

		ldx	#message2d
		jsr	serialSendText

		jsr 	delay

		jmp 	.here		; while(1);

		; 
		.co
http://wiki.bash-hackers.org/scripting/terminalcodes
https://misc.flogisoft.com/bash/tip_colors_and_formatting
		.ec
message1a:	
		.az /Tasza/
message1b:	
		.az / was here/,#$d,#$a

message2a
		.az /Antonina/
message2b
		.az / has a /
message2c
		.az /cat/
message2d:
		.az / :) /,#$d,#$a

vt100reset:
		.az #$1B,/[0m/
vt100bold:
		.az #$1B,/[1m/
vt100reverse:
		.az #$1B,/[7m/

vt100green:
		.az #$1B,/[32m/
vt100blue:
		.az #$1B,/[34m/
vt100cyan:
		.az #$1B,/[36m/
vt100default:
		.az #$1B,/[39m/

		;----------------

serialSendText:
		; X - address of null terminated string
.ser1:
		lda		,x+					; *msg++
		beq		.serExit			; if char == 0 then exit		
		jsr		serialPutChar		; send 1 char
		jmp		.ser1
.serExit
		rts		
		
		;------

serialPutChar:
		; sends one character given in A
		; waits until Transmit Data Register Empty == 1 (transm. done)
		sta		ACIA+TDR		; put to send
.wait:
		lda		ACIA+STATR		; get status
		anda	#$10			; check bit 4 - TDR Empty
		beq		.wait			; wait for 1	
		rts

		;-----------------------------------------------------------------------

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
