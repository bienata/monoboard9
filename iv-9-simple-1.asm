		.cr	6809
		.tf	iv-9-simple-1.bin,BIN
		.lf	iv-9-simple-1.lst
		;
		.in 	monoboard9.inc		; system stuff
		;
		.sm     RAM
        .or     $0000
		; vars and temps here
display	.bs 4
cntr	.bs 2
		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;
		.in 	vfd-cu20025.inc		; cute VFD glass, must be in ROM seg.
		;

; note:
; VIA2.PA4 => STROBE  
; VIA2.PA5 => CLK	  
; VIA2.PA6 => DATA	  

CD4094_STROBE_HI	.eq	%0001.0000
CD4094_STROBE_LO	.eq	%1110.1111

CD4094_CLK_HI		.eq	%0010.0000
CD4094_CLK_LO		.eq	%1101.1111

CD4094_DATA_HI		.eq	%0100.0000
CD4094_DATA_LO		.eq	%1011.1111


SEG_A		.eq		1<<0
SEG_B		.eq		1<<1
SEG_C		.eq		1<<2
SEG_D		.eq		1<<3
SEG_E		.eq		1<<4
SEG_F		.eq		1<<5
SEG_G		.eq		1<<6

DIG_0		.eq		SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F
DIG_1		.eq		SEG_B|SEG_C
DIG_2		.eq		SEG_A|SEG_B|SEG_D|SEG_E|SEG_G
DIG_3		.eq		SEG_A|SEG_B|SEG_C|SEG_D|SEG_G
DIG_4		.eq		SEG_F|SEG_G|SEG_B|SEG_C
DIG_5		.eq		SEG_A|SEG_F|SEG_G|SEG_C|SEG_D
DIG_6		.eq		SEG_A|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G
DIG_7		.eq		SEG_A|SEG_B|SEG_C
DIG_8		.eq		SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G
DIG_9		.eq		SEG_A|SEG_B|SEG_C|SEG_D|SEG_F|SEG_G
DIG_A		.eq		SEG_A|SEG_B|SEG_C|SEG_E|SEG_F|SEG_G
DIG_B		.eq		SEG_C|SEG_D|SEG_E|SEG_F|SEG_G
DIG_C		.eq		SEG_A|SEG_D|SEG_E|SEG_F
DIG_D		.eq		SEG_B|SEG_C|SEG_D|SEG_E|SEG_G
DIG_E		.eq		SEG_A|SEG_D|SEG_E|SEG_F|SEG_G
DIG_F		.eq		SEG_A|SEG_E|SEG_F|SEG_G


byte2sevenSeg:		
		pshu	x,y,b			; uses y,b then save
		pshu	a
		ldy		#.b2sevenDat	; table of 7-seg
		exg		b,a			; input in b
		lsrb
		lsrb
		lsrb
		lsrb				; >> 4
		andb	#$0f		; first 4 bits
		lda		b,y			; a := ascii [ b ]
		sta		0,x+		; msb
		pulu	a
		exg		b,a			; input in b again
		andb	#$0f		; first 4 bits
		lda		b,y			; a := ascii [ b ]
		sta		0,x			; lsb
		pulu 	x,y,b		; gimme back
		rts
.b2sevenDat
		.db		DIG_0,DIG_1,DIG_2,DIG_3,DIG_4,DIG_5,DIG_6,DIG_7
		.db		DIG_8,DIG_9,DIG_A,DIG_B,DIG_C,DIG_D,DIG_E,DIG_F


word2sevenSeg:
		pshu	d,x		; ab,x protection
		jsr	byte2sevenSeg	; msb as is
		leax	2,x		; x += 2, next 2 chars
		tfr		b,a		; lsb from b
		jsr	byte2sevenSeg	; msb as is
		pulu	d,x		; 
		rts


commitDisplay:
		; finally strobe 
		lda		#CD4094_STROBE_HI
		ora		VIA2+ORA
		sta		VIA2+ORA
		lda		#CD4094_STROBE_LO
		anda	VIA2+ORA
		sta		VIA2+ORA
		rts


		; acc - byte to set
postByte:			
		ldx		#8
.pb:
		pshu	b		; save on stack 
		andb	#%1000.0000
		beq		.skipIfZero
		;set data pin
		lda		#CD4094_DATA_HI
		sta		VIA2+ORA
.skipIfZero:
		pulu	b		; restore for a moment
		lslb			; >> next incoming bit
		pshu	b		; save back
		lda		#CD4094_CLK_HI
		ora		VIA2+ORA
		sta		VIA2+ORA
		lda		#0
		sta		VIA2+ORA
		dex
		bne		.pb
		pulu	b		; just for stack balance
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

		jsr		vfdInit
		jsr 	delay	

		ldx		#0000
		stx		cntr


.here:
		ldx		#display
		ldd		cntr
		jsr 	word2sevenSeg

		ldb		display+3
		jsr		postByte		;1

		ldb		display+2
		jsr		postByte		;10

		ldb		display+1
		jsr		postByte		;100

		jsr		commitDisplay

		;cntr++
		ldx		cntr
		inx
		stx		cntr

		jsr		vfdClearDisplay

		lda		#VFD_LINE_1
		jsr		vfdSetPos

		ldx		#message1
		jsr		vfdPrint

		lda		#VFD_LINE_2+20-4
		jsr		vfdSetPos

		ldx		#message2
		jsr		vfdPrint

		jsr 	delay

		jsr		vfdClearDisplay

		lda		#VFD_LINE_2
		jsr		vfdSetPos

		ldx		#message2
		jsr		vfdPrint

		lda		#VFD_LINE_1+20-4
		jsr		vfdSetPos

		ldx		#message3
		jsr		vfdPrint

		jsr 	delay

		jmp 	.here		; while(1);

               ;|12345678901234567890|		
message1	.az	/1234/
message2	.az	/abcd/
message3	.az	/efgh/
message4	.az	/5678/
 

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
