		.cr	6809
		.tf	via-irq-test-1.bin,BIN
		.lf	via-irq-test-1.lst
		;
		.in 	monoboard9.inc		; system stuff

IRQFREQ		.eq	CLK2FREQ/5000		; 5kHz

VOUT_MAIN		.eq	100
VOUT_IRQ_ENTER	.eq	150
VOUT_IRQ_BODY	.eq	200
VOUT_IRQ_EXIT	.eq	250


		;
		.sm     RAM
        .or     $0000

		;
		.sm     CODE	
		.or 	$E000
		.bs	$1000, $FF
		;

		
		
irqHandler:
		lda		#VOUT_IRQ_ENTER
		sta		VIA1+ORA		
		
		lda		#$C0
		sta		VIA1+IFR	; clear Irq flag (!!!!)

		lda		#VOUT_IRQ_BODY
		sta		VIA1+ORA		
		
		lda		#10		
.loop
		deca
		bne		.loop

		lda		#VOUT_IRQ_EXIT
		sta		VIA1+ORA				

		rti		

main:	
		lds	#SYSTEM_STACK
		ldu	#USER_STACK

		lda	#$ff
		sta		VIA1+DDRA		

		; setup for timer 1/via1
		lda	#IRQFREQ	; lo
		sta	VIA1+T1CL		
		lda	/IRQFREQ	; hi
		sta	VIA1+T1CH
		lda	#$c0		;ACR_T1CR3
		sta	VIA1+ACR
		lda	#$c0		;IER
		sta	VIA1+IER
		cli		;    enable irq
		
		lda	#VOUT_MAIN
.loop		
		sta 	VIA1+ORA			; all 1
		bra		.loop
		
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
