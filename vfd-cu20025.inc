		.co
		░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
		░ Itron CU20025 VFD module basic routines by tasza                     ░
		░ display in 8-bit mode, connected to PA/PB port of VIA1               ░
		░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
		.ec
		;
VFD_LINE_1		.eq	0
VFD_LINE_2		.eq $40
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdClearDisplay:
		lda		#$01
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdCursorHome:
		lda		#$02
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdEntryModeSet:
		lda		#$04|1<<2		; I/D = 1, S = 0
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdDisplayOn:
		lda		#$08|$04		; D=1, C=0, B=0
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdDisplayOff:
		lda		#$08		; D=0 (!!), C=0, B=0
		jsr		vfdCommand
		jsr		vfdDelay
		rts		; 
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
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
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdData:
		; D0-7, E^, RS=1
		; 
		sta 	VIA2+ORB
		lda #$03
		sta 	VIA2+ORA	; E=1, RS=1
		nop
		lda #$00	
		sta 	VIA2+ORA	; E=0, RS=0
		rts		; of vfdData
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdCommand:
		; D0-7, E^, RS=0
		; 
		sta 	VIA2+ORB
		lda #$01
		sta 	VIA2+ORA	; E=1, RS=0
		nop
		lda #$00	
		sta 	VIA2+ORA	; E=0, RS=0
		nop
		rts					; of vfdCommand
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
vfdPrint:
		; X - address of null terminated string
.vfdPr	lda		,x+					; *msg++
		beq		.vfdPrintExit		; if char == 0 then exit		
		jsr		vfdData				; else print 
		jmp		.vfdPr
.vfdPrintExit
		rts
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		;
		.co
according to the HD44780 driver specification:
in case of 2x20 display DDRAM start addresses are: $00 for the first line
and $40 for the second one
▶ http://irtfweb.ifa.hawaii.edu/~tcs3/tcs3/vendor_info/Technologic_systems/embeddedx86/HD44780_LCD/lcd0.shtml.htm
		.ec
vfdSetPos: 				; aka Set DDRAM Address / code $80
		adda	#$80	; also set bit 7 = 1 
		jsr		vfdCommand	
		rts
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
		;
		;━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		; ☕ ♫ ♪
		;
