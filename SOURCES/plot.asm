    *** MiniWrapper by Photon ***
		xref Demo

Start:	move.l 4.w,a6			;Exec library base address in a6
	sub.l a4,a4
	btst #0,297(a6)			;68000 CPU?
	beq.s .yes68k
	lea .GetVBR(PC),a5		;else fetch vector base address to a4:
	jsr -30(a6)			;enter Supervisor mode

    *--- save view+coppers ---*

.yes68k:lea .GfxLib(PC),a1		;either way return to here and open
	jsr -408(a6)			;graphics library
	tst.l d0			;if not OK,
	beq.s .quit			;exit program.
	move.l d0,a5			;a5=gfxbase

	move.l a5,a6
	move.l 34(a6),-(sp)
	sub.l a1,a1			;blank screen to trigger screen switch
	jsr -222(a6)			;on Amigas with graphics cards

    *--- save int+dma ---*

	lea $dff000,a6
	bsr.s WaitEOF			;wait out the current frame
	move.l $1c(a6),-(sp)		;save intena+intreq
	move.w 2(a6),-(sp)		;and dma
	move.l $6c(a4),-(sp)		;and also the VB int vector for sport.
	bsr.s AllOff			;turn off all interrupts+DMA

    *--- call demo ---*

	movem.l a4-a6,-(sp)
	bsr.w Demo			;call our demo \o/
	movem.l (sp)+,a4-a6

    *--- restore all ---*

	bsr.s WaitEOF			;wait out the demo's last frame
	bsr.s AllOff			;turn off all interrupts+DMA
	move.l (sp)+,$6c(a4)		;restore VB vector
	move.l 38(a5),$80(a6)		;and copper pointers
	move.l 50(a5),$84(a6)
	addq.w #1,d2			;$7fff->$8000 = master enable bit
	or.w d2,(sp)
	move.w (sp)+,$96(a6)		;restore DMA
	or.w d2,(sp)
	move.w (sp)+,$9a(a6)		;restore interrupt mask
	or.w (sp)+,d2
	bsr.s IntReqD2			;restore interrupt requests

	move.l a5,a6
	move.l (sp)+,a1
	jsr -222(a6)			;restore OS screen

    *--- close lib+exit ---*

	move.l a6,a1			;close graphics library
	move.l 4.w,a6
	jsr -414(a6)
.quit:	moveq #0,d0			;clear error return code to OS
	rts				;back to AmigaDOS/Workbench.

.GetVBR:dc.w $4e7a,$c801		;hex for "movec VBR,a4"
	rte				;return from Supervisor mode

.GfxLib:dc.b "graphics.library",0,0

WaitEOF:				;wait for end of frame
	bsr.s WaitBlitter
	move.w #$138,d0
WaitRaster:				;Wait for scanline d0. Trashes d1.
.l:	move.l 4(a6),d1
	lsr.l #1,d1
	lsr.w #7,d1
	cmp.w d0,d1
	bne.s .l			;wait until it matches (eq)
	rts

AllOff:	move.w #$7fff,d2		;clear all bits
	move.w d2,$96(a6)		;in DMACON,
	move.w d2,$9a(a6)		;INTENA,
IntReqD2:
	move.w d2,$9c(a6)		;and INTREQ
	move.w d2,$9c(a6)		;twice for A4000 compatibility
	rts

WaitBlitter:				;wait until blitter is finished
	tst.w (a6)			;for compatibility with A1000
.loop:	btst #6,2(a6)
	bne.s .loop
	rts

********** Demo **********		;Demo-specific non-startup code below.

w	=320				;screen width, height, depth
h	=256
bpls	=3				;handy values:
bpl	=w/16*2				;byte-width of 1 bitplane line
bwid	=bpls*bpl			;byte-width of 1 pixel line (all bpls)

Demo:					;a4=VBR, a6=Custom Registers Base addr
    *--- init ---*
	move.l #VBint,$6c(a4)		;Set our new VERTB vector,
	move.w #$c020,$9a(a6)		;and enable the interrupt.
	move.w #$87c0,$96(a6)		;Enable Blitter, Bitplane, Copper DMA

	lea Screen,a0			;pointer start addr
	moveq #bpl,d0			;pointer addr increment
	lea BplPtrs+2,a1		;start position to poke in copper
	moveq #bpls-1,d1		;pointer count-1
	bsr.s PokePtrs			;poke bitplane ptrs into copper list.

	move.l #Copper,$80(a6)		;Now set our initalized copper.
    *--- main loop ---*
MainLoop:
	lea Screen,a1			;Then, the screen
	bsr.s ClearScreen		;clear, Yoda pls.
	bsr.s WaitBlitter		;Wait out blit: we plot to same area

	moveq #18,d0			;Read 18
	lea Points(PC),a0		;points from the source data,
	lea Screen,a1			;and to the destination screen
	bsr.s PlotPoints		;plot points, Yoda pls.
	move.w #$111,$180(a6)		;(Optional: shows rastertime left)

	move.w #$12c,d0			;No buffering, so wait until raster
	bsr.w WaitRaster		;is below the Display Window.

	btst #6,$bfe001			;Left mouse button not pressed?
	bne.s MainLoop			;then loop
    *--- exit ---*
	rts				;else exit demo

********** Demo Routines **********

PokePtrs:				;Generic, poke ptrs into copper list
.bpll:	move.l a0,d2
	swap d2
	move.w d2,(a1)			;high word of address
	move.w a0,4(a1)			;low word of address
	addq.w #8,a1			;skip two copper instructions
	add.l d0,a0			;next ptr
	dbf d1,.bpll
	rts

ClearScreen:				;a1=screen destination address to clear
	bsr.w WaitBlitter
	clr.w $66(a6)			;destination modulo
	move.l #$01000000,$40(a6)	;set operation type in BLTCON0/1
	move.l a1,$54(a6)		;destination address
	move.w #h*bpls*64+bpl/2,$58(a6)	;blitter operation size: 768x20 words
	rts

PlotPoints:				;a0=points, a1=screen, d0=count
	subq.w #1,d0			;Subtract 1 for dbf as is the custom.
.l:	movem.w (a0)+,d1-d3		;Just load the values for each dot,
	bsr.s Plot			;and call the generic Plot routine.
	dbf d0,.l			;Until all points drawn.
	rts

Plot:					;d1=x, d2=y, d3=color, a1=screen
	movem.l d1-d5/a1,-(sp)
	add.w ObjX(PC),d1		;Add position of the amazing
	add.w ObjY(PC),d2		;secret dot object!

	muls #bwid,d2			;Address offset for line
	move.w d1,d4			;left-to-right x position,
	not.w d4			;to bit 7-0 (other bits unused by bset)
	asr.w #3,d1			;Byte offset for x position
	ext.l d1			;(big offsets for large screens?)
	add.l d1,d2			;added to final address offset.

	moveq #bpls-1,d5		;Loop through bitplanes:
.l:	ror.b #1,d3			;color bit for bitplane set?
	bpl.s .noset
	bset d4,(a1,d2.l)		;then set bit.
.noset:	lea bpl(a1),a1			;go to next bitplane
	dbf d5,.l
	movem.l (sp)+,d1-d5/a1
	rts

VBint:					;Blank template VERTB interrupt
	movem.l d0/a6,-(sp)		;Save used registers, could have been
	lea $dff000,a6			;modified, so set custom base again.
	btst #5,$1f(a6)			;My level 3 interrupt?
	beq.s .notvb			;if not, skip
    *--- do stuff here ---*
	moveq #$20,d0			;VB interrupt bit
	move.w d0,$9c(a6)		;clear, Yoda pls.
	move.w d0,$9c(a6)		;twice, Yoda pls. (A4000 fix)
.notvb:	movem.l (sp)+,d0/a6
	rte

********** Fastmem Data **********

ObjX:	dc.w 160
ObjY:	dc.w 140			;Move it up to learn unbuffered gfx ;)

Points:					;x,y,color, x,y,color...
	dc.w -16,-8,1, -12,-10,2, -10,-14,3, -7,-15,4, -4,-14,5, -2,-10,6 
	dc.w -1,-6,1, 3,-8,2, 9,-8,3, 14,-5,4, 18,-6,5, 16,-1,6
	dc.w 11,2,1, 4,3,2, -4,2,3, -8,-2,4, -11,-6,5, -8,-11,7

*******************************************************************************
	SECTION ChipData,DATA_C		;declared data that must be in chipmem
*******************************************************************************

Copper:
	dc.w $1fc,0			;Slow fetch mode, remove if AGA demo.
	dc.w $8e,$2c81			;Standard display window top, left
	dc.w $90,$2cc1			;and bottom, right.
	dc.w $92,$38			;Standard bitplane dma fetch start
	dc.w $94,$d0			;and stop for standard screen.

	dc.w $108,bwid-bpl		;modulos
	dc.w $10a,bwid-bpl

	dc.w $102,0			;Scroll register (and playfield pri)

Palette:				;Palette from COLOR00 to COLOR07
	dc.w $180,$000			;black (red,green,blue=0,0,0)
	dc.w $182,$00f			;blue
	dc.w $184,$0f0			;green
	dc.w $186,$0ff			;cyan (=green+blue)
	dc.w $188,$f00			;red
	dc.w $18a,$f0f			;magenta (=red+blue)
	dc.w $18c,$ff0			;yellow (=red+green)
	dc.w $18e,$fff			;white (red,green,blue=15,15,15)

BplPtrs:
	dc.w $e0,0			;set high
	dc.w $e2,0			;and low word of bitplane ptr 1
	dc.w $e4,0			;same for bitplane 2
	dc.w $e6,0
	dc.w $e8,0			;and bitplane 3
	dc.w $ea,0
	dc.w $100,bpls*$1000+$200	;enable bitplanes

	dc.w $ffdf,$fffe		;allow VPOS>$ff
	dc.w $ffff,$fffe		;magic value, signals end of copperlist

*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
*******************************************************************************

Screen:	ds.b h*bwid			;Define storage to reserve for screen


