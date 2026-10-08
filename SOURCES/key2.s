;
; Keyboard and Screen. 
;
;-----------------------------------------------------------------------------

;	INCDIR	"includes:"
	INCLUDE	"hardware/cia.i"
	INCLUDE	"hardware/custom.i"
	INCLUDE	"hardware/dmabits.i"
	INCLUDE	"hardware/intbits.i"



_custom		equ	$dff000
_ciaa		equ	$bfe001


KEYCODE_SPACE	= $40
KEYCODE_ESC	= $45
KEYCODE_CURSORDOWN	= $4D
KEYCODE_CURSORUP	= $4C

;-----------------------------------------------------------------------------
;
;in
;	a5 - _custom
;
WAIT_BEAM:	MACRO
		lea	vposr(a5),a0
.1\@		moveq	#1,d0
		and.w	(a0),d0
		bne.b	.1\@
.2\@		moveq	#1,d0
		and.w	(a0),d0
		beq.b	.2\@
	ENDM

;-----------------------------------------------------------------------------
;RSRESET
screen:		rs.l	1
copper:		rs.l	1
oldStack:	rs.l	1
oldView:	rs.l	1
oldIntena:	rs.w	1
oldDma:		rs.w	1
gfxBase:	rs.l	1
vbrBase:	rs.l	1
oldIntPorts:	rs.l	1

keys:		rs.b	$80

dt_SIZEOF:	rs.b	0

;-----------------------------------------------------------------------------

Program:
		bsr.b	DoVariables
		bsr.w	OpenLibsAndGetVbr
		beq.b	Exit
		bsr.b	DisableOs
		bsr.b	Main           ; <-------------------------
Quit:		bsr.w	EnableOs
Exit:		bsr.w	CloseGraphicsLibrary
		move.l	dt+oldStack(pc),a7	;restore old stack
		rts

;-----------------------------------------------------------------------------
Main:
		bsr.w	Init

Loop:		
		WAIT_BEAM

		tst.b	keys+KEYCODE_SPACE(a6)
;		tst.b	keys+KEYCODE_ESC(a6)
		bne.b	Quit

.checkLmb
		btst	#6,_ciaa
		bne.b	Loop
		rts

;-----------------------------------------------------------------------------
;
;out
;a6	dt
;
DoVariables:
;		lea	dt(pc),a6
		lea dt,a6
		

	;clear dt
		move.l	a6,a0
		moveq	#0,d0
		move.w	#dt_SIZEOF/4-1,d1
.clear		move.l	d0,(a0)+
		dbf	d1,.clear


	;store old stack pointer
		lea	4(a7),a0
		move.l	a0,oldStack(a6)

		rts

;-----------------------------------------------------------------------------
;in
;a6	dt
;
;out
;a5	_custom
;
DisableOs:
	;save old view
		move.l	gfxBase(a6),a5
		move.l	$22(a5),oldView(a6)
		exg	a5,a6

	;set no view 
		sub.l	a1,a1
		bsr.b	LoadView

	;takeover the blitter
		jsr	-456(a6)	;gfx OwnBlitter
		jsr	-228(a6)	;gfx WaitBlit

		move.l	a5,a6

	;store hardware registers
		lea	_custom,a5
		move.w	#$c000,d1

		move.w	intenar(a5),d0
		or.w	d1,d0
		move.w	d0,oldIntena(a6)

		add.w	d1,d1
		move.w	dmaconr(a5),d0
		or.w	d1,d0
		move.w	d0,oldDma(a6)

		bsr.b	StopDmaAndIntsAtVBlank
	;store old PORTS 
		move.l	vbrBase(a6),a0
		move.l	$68(a0),oldIntPorts(a6)
		rts


;-----------------------------------------------------------------------------
;in
;	a6 - gfx base
;	a1 - view
LoadView:
		jsr	-222(a6)	;gfx LoadView(view)
		jsr	-270(a6)	;gfx WaitTOF()
		jmp	-270(a6)	;gfx WaitTOF()

;-----------------------------------------------------------------------------
;
;in
;	a5 - custom
;
StopDmaAndIntsAtVBlank:
		WAIT_BEAM
		move.w	#$7fff,d0
		move.w	d0,dmacon(a5)	;dma off
		move.w	d0,intena(a5)	;disable ints
		move.w	d0,intreq(a5)	;clear pending ints
		rts

;-----------------------------------------------------------------------------
;in
;a5	custom
;a6	dt
;
EnableOs:
		move.l	a6,a4

		move.l	gfxBase(a4),a6
		jsr	-228(a6)	;gfx WaitBlit()

		bsr.b	StopDmaAndIntsAtVBlank

	;restore ints pointers (PORTS)
		move.l	vbrBase(a4),a0
		move.l	oldIntPorts(a4),$68(a0)

	;restore hardware regs
		move.w	oldIntena(a4),intena(a5)
		move.w	oldDma(a4),dmacon(a5)

		jsr	-462(a6)	;gfx DisownBlitter()

	;load old view
		move.l	oldView(a4),a1
		bsr.b	LoadView

		move.l	$26(a6),cop1lc(a5)

		move.l	a4,a6
		rts

;-----------------------------------------------------------------------------
;
;in
;a6	dt
;
;out
;d0	zero mean some library do not open 
;	non zero everything were ok
;
OpenLibsAndGetVbr:

		move.l	a6,a4

	;get vbr
		move.l	4.w,a6		;exec base
		moveq	#0,d1		;on 68000 VBR base is 0
		btst.b	#0,$129(a6)	;test bit AFB_68010 on AttnFlags+1
		beq.b	.mc68000

		lea	.getvbr(pc),a5
		jsr	-30(a6)		;exec Supervisor

.mc68000	move.l	d1,vbrBase(a4)	;store VBR base

		lea	.gfxName(pc),a1	;library name
		jsr	-408(a6)	;exec OldOpenLibrary()

		move.l	a4,a6
		move.l	d0,gfxBase(a6)	;store result of opening
		rts
		
		
		

.getvbr		dc.w	$4e7a,$1801	;movec	vbr,d1
		rte

.gfxName:	dc.b	'graphics.library',0,0

;-----------------------------------------------------------------------------
;
;in
;a6	dt
;
;out
;a6	exec base
;
CloseGraphicsLibrary:
		move.l	gfxBase(a6),a1	;library base
		move.l	4.w,a6		;exec base
		move.l	a1,d0		;trick to check if lib base is zero
		beq.b	.exit
		jsr	-414(a6)	;exec CloseLibrary
.exit		rts

;-----------------------------------------------------------------------------

IntLvlTwoPorts:
		movem.l	d0-d1/a0-a2,-(a7)

		lea	_custom,a0
		moveq	#INTF_PORTS,d0

	;check if is it level 2 interrupt
		move.w	intreqr(a0),d1
		and.w	d0,d1
		beq.b	.end

	;check if SP cause interrupt, hopefully CIAICRF_SP = 8
		lea	_ciaa,a1 
		move.b	ciaicr(a1),d1
		and.b	d0,d1
		beq.b	.end

		move.b	ciasdr(a1),d1			;get keycode
		or.b	#CIACRAF_SPMODE,ciacra(a1)	;start SP handshaking

		lea	dt+keys(pc),a2
		not.b	d1
		lsr.b	#1,d1
		scc	(a2,d1.w)

	;handshake
		moveq	#3-1,d1
.wait1		move.b	vhposr(a0),d0
.wait2		cmp.b	vhposr(a0),d0
		beq.b	.wait2
		dbf	d1,.wait1

	;set input mode
		and.b	#~(CIACRAF_SPMODE),ciacra(a1)

.end		move.w	#INTF_PORTS,intreq(a0)
		tst.w	intreqr(a0)
		movem.l	(a7)+,d0-d1/a0-a2
		rte

		
		
		
		
		
;-----------------------------------------------------------------------------
; in
;a5 - custom
; out
;a6 - dt variables
;
Init:
	;set up PORTS int
		lea	IntLvlTwoPorts(pc),a0
		move.l	vbrBase(a6),a1
		move.l	a0,$68(a1) 

	;allow ports interrupt
		move.w	#INTF_SETCLR!INTF_INTEN!INTF_PORTS,intena(a5)


		rts


;-----------------------------------------------------------------------------

dt:		ds.b	dt_SIZEOF



