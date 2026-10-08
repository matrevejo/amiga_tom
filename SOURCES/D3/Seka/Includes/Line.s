* Linietegningsrutiner.						*
*
* Indeholder rutinerne
*
* 1) init_line  -> Sætter blitterregsitrene sådan at blitteren er klar
*		   til linietegning. Sætter A5=$dff000
*
* 2) draw_line  -> Tegner en linie fra (d0,d1) til (d2,d3) i bitplanet, som
*		   A3 peger på. Linien er af typen udfyld-linie, dvs 1 pixel
*		   pr horisontal linie.
*
* 3) draw_xline -> Som draw_line, men tegner linien uden den første pixel.
*
* Ødelægger  A0,D0-D4 og D6-D7
* Bruger ca 320 cycles på at tegne linien! (+ tiden som blitteren bruger!)
* På en almindelig Amiga vil det sige: ca 46µs pr linie + blitter-tid
* Blitteren bruger ca 1,2µs pr pixel i linien.

* Parametre for draw_line og draw_xline:

* A3=Startadressen på bitplanet
* d0=x1,d1=y1
* d2=x2,d2=y2	;I basic: Line (d0,d1)-(d2,d3)
*
* Kald "init_line" op før du begynder at tegne linier!
* init_line sætter:
*	bltafwm til $ffff
*	bltalwm	til $ffff
*	bltadat	til $8000
*	bltbdat	til $ffff
*	a5 til $dff000
*	bltcmod	til #line_lnmod
*	bltdmod	til #line_lnmod
*
* Hvis bare nogle af disse værdier forandres (men ikke alle), er det nok
* at sætte dem til de værdier, som er vist ovenfor.
*
* Bredden på skærmen skal være defineret som 'line_lnmod=xxx'
* Programmet skal bruge en makro, som hedder "line_LnModMul", der ganger ?1 med
* moduloen. ?2 kan ødelægges til formålet.
* SVARET SKAL KOMME UD I ?1!
*
* Eksempel på line_LnModMul, som ganger med 40:
* line_LnModMul	macro
*	lsl.w	#3,?1	;*8		12 cycles
*	move.w	?1,?2	;?2=?1*8	 4   "
*	add.w	?2,?2	;?2=?1*16	 4   "
*	add.w	?2,?2	;?2-?1*32	 4   "
*	add.w	?2,?1	;?1=?1*40	 4   "
*	endm		TILSAMMEN:	28 cycles! (ca halvdelen af MULU!)
*
* Eksempel på line_LnModMul, som ganger med 48:
* line_LnModMul	macro
*	lsl.w	#4,?1	;*16		14 cycles
*	move.w	?1,?2	;?2=?1*16	 4 cycles
*	add.w	?2,?2	;?2=?1*32	 4 cycles
*	add.w	?2,?1	;?1=?1*48	 4 cycles
*	endm		TILSAMMEN:	26 cycles!
 
	bra	line_end ;Således at filen kan inkluderes hvor som helst i prog.
init_line:
	lea.l	$dff000,a5
	moveq	#-1,d0
	move.l	d0,bltafwm(a5)
	move.w	d0,bltbdat(a5)
	move.w	#$8000,bltadat(a5)
	move.w	#line_lnmod,bltcmod(a5)
	move.w	#line_lnmod,bltdmod(a5)
	rts

xgty:	macro
	add.w	d3,d3
	move.w	d3,d0
	sub.w	d2,d0
	bgt.s	xgty_nslack?0
	bset	#6,d6
xgty_nslack?0:
	IF	line_waitblit-OFF
	btst	#6,dmaconr(a5)
	bne.s	xgty_nslack?0
	ENDIF
	move.w	d0,bltaptl(a5)		
	sub.w	d2,d0
	add.w	d0,d0
	move.w	d0,bltamod(a5)		
	add.w	d3,d3
	move.w	d3,bltbmod(a5)	
	addq.w	#1,d2
	lsl.w	#6,d2
	addq.w	#2,d2
	swap	d4
	move.w	d4,bltcon0(a5)	
	move.w	d6,bltcon1(a5)	
	move.l	a0,bltcpth(a5)
	move.l	a0,bltdpth(a5)
	move.w	d2,bltsize(a5)	
	rts
	endm
 
ygtx:	macro
	add.w	d2,d2
	move.w	d2,d0
	sub.w	d3,d0
	bgt.s	ygtx_nslack?0
	bset	#6,d6
ygtx_nslack?0:
	IF	line_waitblit-OFF
	btst	#6,dmaconr(a5)
	bne.s	ygtx_nslack?0
	ENDIF
	move.w	d0,bltaptl(a5)		
	sub.w	d3,d0
	add.w	d0,d0
	move.w	d0,bltamod(a5)		
	add.w	d2,d2
	move.w	d2,bltbmod(a5)	
	addq.w	#1,d3
	lsl.w	#6,d3
	addq.w	#2,d3
	swap	d4
	move.w	d4,bltcon0(a5)	
	move.w	d6,bltcon1(a5)	
	move.l	a0,bltcpth(a5)
	move.l	a0,bltdpth(a5)
	move.w	d3,bltsize(a5)	
	rts
	endm
	
draw_line:
	move.w	#$b5a0,d4	
	swap	d4
	neg	d0	;bliver kun kaldt op fra draw_poly, og der har alle
			;hele linier negativ x1....
	move.w	d0,d4
	ror.l	#4,d4
	add.w	d4,d4
	move.w	d1,d7
	line_LnModMul	d7,d6
	add.w	d4,d7
	lea.l	0(a3,d7.w),a0
	sub.w	d0,d2
	bge	xpos
xneg:
	neg.w	d2
	sub.w	d1,d3
	bge	xneg_ypos
xneg_yneg:
	neg.w	d3
	cmp.w	d2,d3
	bge.s	octant3
octant7:
 	moveq	#[7*4]+3,d6	;+3 giver linie med 1 pixel pr horisontal linie.
	xgty
octant3:
	moveq	#[3*4]+3,d6
	ygtx
xneg_ypos:
	cmp.w	d2,d3
	bge.s	octant2
octant5:
	moveq	#[5*4]+3,d6
	xgty
octant2:
	moveq	#[2*4]+3,d6
	ygtx
xpos:
	sub.w	d1,d3
	bge	xpos_ypos
xpos_yneg:
	neg.w	d3
	cmp.w	d2,d3
	bge.s	octant1
octant6:
	moveq	#[6*4]+3,d6
	xgty
octant1:
	moveq	#[1*4]+3,d6
	ygtx
xpos_ypos:
	cmp.w	d2,d3
	bge.s	octant0
octant4:
	moveq	#[4*4]+3,d6
	xgty
octant0:
	moveq	#[0*4]+3,d6
	ygtx


xxgty:	macro
	add.w	d3,d3
	move.w	d3,d0
	sub.w	d2,d0
	bgt.s	xgty_nslack?0
	bset	#6,d6
xgty_nslack?0:
	IF	line_waitblit-OFF
	btst	#6,dmaconr(a5)
	bne.s	xgty_nslack?0
	ENDIF
	
	move	(a0),d4	;Blitteren må absolut ikke køre mens dette sker!
	bchg	d7,d4	;Disse 3 linier fjerner den første pixel i linien.
	move	d4,(a0)	;40 extra cycles for at fjerne den første bit!

	move.w	d0,bltaptl(a5)		
	sub.w	d2,d0
	add.w	d0,d0
	move.w	d0,bltamod(a5)		
	add.w	d3,d3
	move.w	d3,bltbmod(a5)	
	addq.w	#1,d2
	lsl.w	#6,d2
	addq.w	#2,d2
	swap	d4
	move.w	d4,bltcon0(a5)	
	move.w	d6,bltcon1(a5)	
	move.l	a0,bltcpth(a5)
	move.l	a0,bltdpth(a5)
	move.w	d2,bltsize(a5)	
	rts
	endm

xygtx:	macro
	add.w	d2,d2
	move.w	d2,d0
	sub.w	d3,d0
	bgt.s	ygtx_nslack?0
	bset	#6,d6
ygtx_nslack?0:
	IF	line_waitblit-OFF
	btst	#6,dmaconr(a5)
	bne.s	ygtx_nslack?0
	ENDIF
	
	move	(a0),d4	;blitteren må absolut ikke køre mens dette sker!
	bchg	d7,d4	;Disse tre linier fjerner den første pixel i linien.
	move	d4,(a0)	;40 extra cycles for at fjerne den første bit!
	
	move.w	d0,bltaptl(a5)		
	sub.w	d3,d0
	add.w	d0,d0
	move.w	d0,bltamod(a5)		
	add.w	d2,d2
	move.w	d2,bltbmod(a5)	
	addq.w	#1,d3
	lsl.w	#6,d3
	addq.w	#2,d3
	swap	d4
	move.w	d4,bltcon0(a5)	
	move.w	d6,bltcon1(a5)	
	move.l	a0,bltcpth(a5)
 	move.l	a0,bltdpth(a5)
	move.w	d3,bltsize(a5)	
	rts
	endm

draw_xline:
	move.w	#$b5a0,d4
	swap	d4
	move.w	d0,d4
	ror.l	#4,d4
	add.w	d4,d4
	move.w	d1,d7
	line_LnModMul	d7,d6
	add.w	d4,d7
	lea.l	0(a3,d7.w),a0
	
	move	d0,d7
	not	d7
	and	#$f,d7	;d7=negeret af 4 nederste bits i x-koordinatet.
			;dvs d7=15-(x&15)

	sub.w	d0,d2
	bge	xxpos
xxneg:
	neg.w	d2
	sub.w	d1,d3
	bge	xxneg_ypos
xxneg_yneg:
	neg.w	d3
	cmp.w	d2,d3
	bge.s	xoctant3
xoctant7:
	moveq	#[7*4]+3,d6
	xxgty
xoctant3:
	moveq	#[3*4]+3,d6
	xygtx
xxneg_ypos:
	cmp.w	d2,d3
	bge.s	xoctant2
xoctant5:
	moveq	#[5*4]+3,d6
	xxgty
xoctant2:
	moveq	#[2*4]+3,d6
	xygtx
xxpos:
	sub.w	d1,d3
	bge	xxpos_ypos
xxpos_yneg:
	neg.w	d3
	cmp.w	d2,d3
	bge.s	xoctant1
xoctant6:
	moveq	#[6*4]+3,d6
	xxgty
xoctant1:
	moveq	#[1*4]+3,d6
	xygtx
xxpos_ypos:
	cmp.w	d2,d3
	bge.s	xoctant0
xoctant4:
	moveq	#[4*4]+3,d6
	xxgty
xoctant0:
	moveq	#[0*4]+3,d6
	xygtx
line_end: