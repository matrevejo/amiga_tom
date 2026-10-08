	ORG $20000
	LOAD $20000
	JUMPPTR init

w	=320
h	=256
bplsize	=w*h/8

screen	=$60000

init:
	move.l 4.w,a6		;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr -408(a6)		;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1),d4	;original copper ptr

	jsr -414(a6)		;closelibrary()

	move.w #$ac,d7		;start y position
	moveq #1,d6		;y add
	move.w $dff01c,d5
	move.w $dff002,d3

	move.w #$138,d0		;wait for EOFrame
	bsr.w WaitRaster
	move.w #$7fff,$dff09a	;disable all bits in INTENA
	move.w #$7fff,$dff09c	;disable all bits in INTREQ
	move.w #$7fff,$dff09c	;disable all bits in INTREQ
	move.w #$7fff,$dff096	;disable all bits in DMACON
	move.w #$87e0,$dff096
hwinit:
	lea Screen,a1
	move.w #bplsize-1,d0
.l:	move.b $dff007,(a1)+
	dbf d0,.l
	
	move.l #copper,$dff080
**************************
mainloop:
wframe:
	btst #0,$dff005
	bne.b wframe
	cmp.b #$2a,$dff006
	bne.b wframe
wframe2:
	cmp.b #$2a,$dff006
	beq.b wframe2

;-----frame loop start---
	add.b #1,Spr+1

	add d6,d7		;add "1" to y position

	cmp #$f0,d7		;bottom check
	blo.b ok1
	neg d6			;change direction
ok1:

	cmp.b #$40,d7
	bhi.b ok2
	neg d6			;change direction
ok2:

	move.l #waitras1,a0
	move d7,d0
	moveq #6-1,d1
.l:
	move.b d0,(a0)
	add.w #1,d0
	add.w #8,a0
	DBF d1,.l

;-----frame loop end---

	btst #6,$bfe001
	bne.b mainloop
**************************
exit:
	move.w #$7fff,$dff096
	or.w #$8200,d3
	move.w d3,$dff096
	move.l d4,$dff080
	or #$c000,d5
	move d5,$dff09a
	rts

********** ROUTINES **********

WaitRaster:		;wait for rasterline d0.w. Modifies d0-d2/a0.
	move.l #$1ff00,d2
	lsl.l #8,d0
	and.l d2,d0
	lea $dff004,a0
.wr:	move.l (a0),d1
	and.l d2,d1
	cmp.l d1,d0
	bne.s .wr
	RTS

********** DATA **********

gfxname:
	dc.b "graphics.library",0

	EVEN

Spr:
	dc.w $2c40,$3c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0110011111001100,%0001100000110000
	dc.w %1110011111001110,%0001100000110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0010000000001000
	dc.w %1111111111111110,%0001100000110000
	dc.w %0111111111111100,%0000011111000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w 0,0

NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0

Copper:
	dc.w $1fc,0			;slow fetch mode, AGA compatibility
	dc.w $100,$0200
	dc.w $8e,$2c81
	dc.w $90,$2cc1
	dc.w $92,$38
	dc.w $94,$d0
	dc.w $108,0
	dc.w $10a,0
	dc.w $102,0

	dc.w $1a2,$e22
	dc.w $1a4,$ff0
	dc.w $1a6,$fff
SprP:
	dc.w $120,(Spr>>16)&$ffff
	dc.w $122,(Spr)&$ffff

	dc.w $124,(NullSpr>>16)&$ffff
	dc.w $126,(NullSpr)&$ffff
	dc.w $128,(NullSpr>>16)&$ffff
	dc.w $12a,(NullSpr)&$ffff
	dc.w $12c,(NullSpr>>16)&$ffff
	dc.w $12e,(NullSpr)&$ffff
	dc.w $130,(NullSpr>>16)&$ffff
	dc.w $132,(NullSpr)&$ffff
	dc.w $134,(NullSpr>>16)&$ffff
	dc.w $136,(NullSpr)&$ffff
	dc.w $138,(NullSpr>>16)&$ffff
	dc.w $13a,(NullSpr)&$ffff
	dc.w $13c,(NullSpr>>16)&$ffff
	dc.w $13e,(NullSpr)&$ffff

CopBplP:
	dc.w $e0,(Screen>>16)&$ffff
	dc.w $e2,(Screen)&$ffff
		
	dc.w $180,$349
	dc.w $2b07,$fffe
	dc.w $180,$56c
	dc.w $2c07,$fffe

LogoPal:
	dc.w $0180,$0667,$0182,$0ddd,$0184,$0833,$0186,$0334
	dc.w $0188,$0a88,$018a,$099a,$018c,$0556,$018e,$0633

	dc.w $100,$1200
	dc.w $182,$379
waitras1:
	dc.w $8007,$fffe
	dc.w $180,$055
waitras2:
	dc.w $8107,$fffe
	dc.w $180,$0aa
waitras3:
	dc.w $8207,$fffe
	dc.w $180,$0ff
waitras4:
	dc.w $8307,$fffe
	dc.w $180,$0aa
waitras5:
	dc.w $8407,$fffe
	dc.w $180,$055
waitras6:
	dc.w $8507,$fffe
	dc.w $180,$113

	dc.w $ffdf,$fffe
	dc.w $2c07,$fffe
	dc.w $180,$56c
	dc.w $2d07,$fffe
	dc.w $180,$349

	dc.w $ffff,$fffe

