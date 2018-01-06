		.cr	6809
		.tf	ad574-mux-serial-2.bin,BIN
		.lf	ad574-mux-serial-2.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
text:	.bs 5	; storage for hex string
textLen	.eq	*-text

txBuffer		.bs 32	; can for vfd messages
txBufferLen		.eq	*-txBuffer

rxBuffer	.bs 32	; receive buff
rxBufferLen	.eq	*-rxBuffer

rxBufferPtr	.bs 2	; receive buff pointer

displayBuff		.bs 32	; vfd
displayBuffLen	.eq	*-displayBuff

currentChannel	.bs	1	
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		.in		convert.inc	
		;

irqHandler
		; confirm irq reading stat
		lda		ACIA+STATR		
		; get char from RX
		lda		ACIA+RDR

		; check if LF (end of frame) then copy buffers
		cmpa	#10
		bne		.doStoreRxChar
		; play with received frame
		; clear dest buffer
		ldx		#displayBuff
		lda		#displayBuffLen
		jsr		memZero
		; copy from rx buffer to vfd 
		ldy		#rxBuffer
		ldx		#displayBuff
		jsr		strcpy
		; zero rx buffer for sure
		ldx		#rxBuffer
		lda		#rxBufferLen
		jsr		memZero	
		bra		.doReinitRx		; kindly exit from here		

.doStoreRxChar:
		; otherwise store char in buff
		ldx		rxBufferPtr
		sta		,x+			; save char
		stx		rxBufferPtr	; save prt
		clra	
		sta		,x+			; save NULL after
		; check against buff end
		cmpx	#rxBuffer+rxBufferLen			
		bne		.hasEnoughSpace
.doReinitRx:
		; reinit rx buff
		ldx		#rxBuffer
		stx		rxBufferPtr
.hasEnoughSpace
		rti



		;------------- 
		; ACC - channel
		; 0 - 421 10Vref, 
		; 1 - MCP9700 outdoor
		; 2 - LM35 on CPU
		; 3 - LM35 indoor
getADC:
		; set channel on MAC24A (VIA1.PB7/PB6)
		lsla
		lsla
		lsla
		lsla
		lsla
		lsla			<< 6
		anda	#%11000000
		; update bits
		sta		VIA1+ORB

		; dummy read/conv first
		lda		#$04	
		sta		VIA2+ORA
		nop
		lda		#$0
		sta		VIA2+ORA
		ldb		#40
.getADCdel
		decb
		bne		.getADCdel

		;
		; prepare to read real data 
		lda		#$04	
		sta		VIA2+ORA

		; MSB (4bits)
		lda		VIA1+IRB
		anda	#$0F
		; LSB (8bits)
		ldb		VIA1+IRA
		pshu	a,b
		; and start next conversion cycle		
		lda		#$0
		sta		VIA2+ORA

		pulu	a,b
		rts



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

		;via-1 - all as in
		clra
		sta 	VIA1+DDRA		; D0..D7 

		lda		#%11000000		; OUT b7,6 - A1,A0 of MAX24A
		sta 	VIA1+DDRB		; IN D8..D11 of AD574


		; init rxBufferPrt = &rxBuffer
		ldx		#rxBuffer
		stx		rxBufferPtr	
		; ACIA init
		; 9600,8,N,1
		; soft reset
		sta	ACIA+PRESET
		lda	#$09
		sta	ACIA+CMDREG
		lda	#$1E
		sta	ACIA+CTLREG





		jsr		vfdInit
		jsr 	delay	

		cli		; go on with IRQ

.here:
		jsr		vfdClearDisplay

		lda		#VFD_LINE_1
		jsr		vfdSetPos

		lda		#0
		sta		currentChannel

		; clear transmission buffer
		ldx		#txBuffer
		lda		#txBufferLen
		jsr		memZero

		ldx		#txBuffer
		ldy		#frameStart		; add frame start ^
		jsr		strcat

.doNext
		lda		#textLen
		ldx		#text
		jsr		memZero
		
		lda		currentChannel
		jsr		getADC
		ldx		#text
		jsr		word2hex

		; add hex val from ADC
		ldx		#txBuffer
		ldy		#text		; nnnn
		jsr		strcat

		; check if last item, add `:` when not
		lda		currentChannel
		cmpa		#3
		beq		.skipFrameSep
			ldx		#txBuffer
			ldy		#frameSep		; :
			jsr		strcat
.skipFrameSep:

		ldx		#text
		jsr		vfdPrint
		lda		#' '
		jsr		vfdData

		inc		currentChannel
		lda		currentChannel
		cmpa	#4
		bne		.doNext

		; finalise frame
		ldx		#txBuffer
		ldy		#frameEnd		; \LF		
		jsr		strcat

		; and send...
		ldx		#txBuffer
		jsr		serialSendText

		lda		#VFD_LINE_2
		jsr		vfdSetPos

		;ldx		#caption
		;ldx		#txBuffer
		ldx		#displayBuff
		jsr		vfdPrint


		jsr 	delay

		jmp 	.here		; while(1);

                ;12345678901234567890
caption:	.az '+10V OUTD CPU  INDR ' 

frameStart:	.az '^' 
frameSep:	.az ':'
frameEnd:	.az #10		; LF!  

strcpy:
	; Y - str from
	; X - str to (dest)
	; copies chars until zero in src
.doCopy:
	lda	,y+
	sta	,x+
	bne	.doCopy
	rts



strcat:
		; X - dest string being expaned, must be long enough and 0-ended
		; Y - src string to add		
.doFindEnd:
		; scroll to end of dest(X) string
		lda		,x+
		bne		.doFindEnd
		; one char back! 
		dex
.doCopy:
		lda		,y+		
		sta		,x+
		bne		.doCopy
		rts


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
		>DEF_SYS_JUMP IRQ_____, irqHandler
		>DEF_SYS_JUMP SWI_____, UNDEFINED
		>DEF_SYS_JUMP NMI_____, UNDEFINED
		>DEF_SYS_JUMP RESET___, main
                ;
                ; :-)
