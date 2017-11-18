		; 
		; monoboard9.inc - definitions and consts for EKF 68xx MONOBOARD9 computer
		;                  related to 99-00 PAL version (see mb009.txt for details)
		;
		; by Natasza Biecek, 2017, http://bienata.waw.pl #slowanawiatr 
		;
		; internal CLK requency in Hz, we have 1MHz here
CLK2FREQ	.eq	1000000				
		;
		; address decoder
VIA1		.eq	$E000
VIA2		.eq	$E010
ACIA		.eq	$E020
		;
ROM_BEGIN	.eq	$E000
ROM_END		.eq	$FFFF

RAM_BEGIN	.eq	$0000
RAM_END		.eq	RAM_BEGIN+4*8192
		;
SYSTEM_STACK	.eq	RAM_END-1	; for procedures calls
USER_STACK	.eq	SYSTEM_STACK-1-512	; for user data
		;
		; VIA related stuff
		; registers as described on Fig.6 of p.5-24 
		; http://www.vectrex.co.uk/files/datasheets/6522AP.pdf
ORB		.eq 0
IRB		.eq 0
ORA		.eq 1
IRA		.eq 1
DDRB		.eq 2
DDRA		.eq 3
T1CL		.eq 4
T1CH		.eq 5
T1LL		.eq 6
T1LH		.eq 7
T2CL		.eq 8
T2CH		.eq 9
SR		.eq 10
ACR		.eq 11
PCR		.eq 12
IFR		.eq 13
		;
PB0OUT		.eq 	1<<0
PB1OUT		.eq 	1<<1
PB2OUT		.eq 	1<<2
PB3OUT		.eq 	1<<3
PB4OUT		.eq 	1<<4
PB5OUT		.eq 	1<<5
PB6OUT		.eq 	1<<6
PB7OUT		.eq 	1<<7
		;
PA0OUT		.eq 	1<<0
PA1OUT		.eq 	1<<1
PA2OUT		.eq 	1<<2
PA3OUT		.eq 	1<<3
PA4OUT		.eq 	1<<4
PA5OUT		.eq 	1<<5
PA6OUT		.eq 	1<<6
PA7OUT		.eq 	1<<7
		;
		; Fig 17. ACR bits description
		; Timer 1 Control (bits 7.6)
ACR_T1CR0		.eq	0	; timed interrupt each time T1 loaded, PB7 disabled
ACR_T1CR1		.eq	1<<6	; continuous interrupts, PB7 disabled		
ACR_T1CR2		.eq	2<<6	; timed interrupt each time T1 loaded, one shot PB7 output
ACR_T1CR3		.eq	3<<6	; continuous interrupts, PB7 square wave out
		; Timer 2 control (bit 5)
ACR_T2CR0		.eq	0	; timed interrupt
ACR_T2CR1		.eq	1<<5	; count down with pulses on PB6
		; Shift Register Control (bits 4.3.2)
ACR_SRC0		.eq	0	; disabled 		
ACR_SRC1		.eq 	1<<2	; shift in under control of T2
ACR_SRC2		.eq 	2<<2	; shift in under control of Φ2
ACR_SRC3		.eq 	3<<2	; shift in under control of external clk
ACR_SRC4		.eq 	4<<2	; shift out free running @ T2 rate
ACR_SRC5		.eq 	5<<2	; shift out under control of T2
ACR_SRC6		.eq 	6<<2	; shift out under control of Φ2
ACR_SRC7		.eq 	7<<2	; shift out under control of external clk
		; PA Latch Enable Disable (bit 0)
ACR_PALD		.eq	0	; latch disabled
ACR_PALE		.eq	1	; latch enabled
		; PB Latch Enable Disable (bit 1)
ACR_PBLD		.eq	0	; latch disabled
ACR_PBLE		.eq	2	; latch enabled
		;
		; helper & macros
		;
		; system jump table
UNDEFINED	.eq	ROM_END
		;
RESET___	.eq	ROM_END-1
NMI_____	.eq 	ROM_END-3		
SWI_____	.eq	ROM_END-5
IRQ_____	.eq	ROM_END-7
FIRQ____	.eq	ROM_END-9
SWI2____	.eq	ROM_END-11
SWI3____	.eq	ROM_END-13
RESERVED	.eq	ROM_END-15		
		;
DEF_SYS_JUMP	.ma	 
		.nO     ]1
                .da     ]2
		.em
