move.w	#$4000,$dff09a

move.w	#$01a0,$dff096

lea.l	screen(pc),a1
lea.l	bplcop(pc),a2
move.l	a1,d1
move.w	d1,6(a2)
swap	d1
move.w	d1,2(a2)

lea.l	copper(pc),a1
move.l	a1,$dff080

move.w	#$8180,$dff096

wait:
move.l	$dff004,d0
asr.l	#8,d0
andi.w	#$1ff,d0
bne.s	wait

bsr.s	clear
bsr	star
bsr.s	rotate
bsr.s	swapscr

btst	#6,$bfe001
bne.s	wait

move.l	4.w,a6
move.l	156(a6),a6
move.l	38(a6),$dff080

move.w	#$8020,$dff096
rts

scr:
dc.w	0

swapscr:
lea.l	scr(pc),a1
addq.w	#1,(a1)
move.w	(a1),d1
andi.w	#1,d1
mulu	#10240,d1
lea.l	screen(pc),a1
lea.l	bplcop(pc),a2
add.l	a1,d1
move.w	d1,6(a2)
swap	d1
move.w	d1,2(a2)
rts

rotate:
lea.l	stars(pc),a1
move.w	#255,d0
rotloop:
addq.w	#3,(a1)
addq.l	#4,a1
dbra	d0,rotloop
rts

clear:
btst	#6,$dff002
bne.s	clear
lea.l	screen(pc),a1
lea.l	scr(pc),a2
move.w	(a2),d1
not.w	d1
andi.w	#1,d1
mulu	#10240,d1
add.l	d1,a1
move.l	a1,$dff054
clr.w	$dff066
move.l	#$01000000,$dff040
move.w	#$4014,$dff058
cl2:
btst	#6,$dff002
bne.s	cl2
rts

star:
lea.l	screen(pc),a0
lea.l	scr(pc),a1
move.w	(a1),d1
not.w	d1
andi.w	#1,d1
mulu	#10240,d1
add.l	d1,a0
lea.l	sin(pc),a1
lea.l	sin+512(pc),a2
lea.l	stars(pc),a3
lea.l	acc(pc),a4
move.w	#255,d7
starloop:
move.w	(a3)+,d2
andi.w	#$7fe,d2
move.w	(a1,d2.w),d0
move.w	(a2,d2.w),d1
addq.w	#4,(a3)
move.w	(a3)+,d2
andi.w	#$03fe,d2
muls	(a4,d2.w),d0
swap	d0
add.w	#160,d0
muls	(a4,d2.w),d1
swap	d1
add.w	#128,d1
lsl.w	#3,d1
move.w	d1,d3
lsl.w	#2,d3
add.w	d3,d1
move.w	d0,d2
lsr.w	#3,d0
add.w	d1,d0
not.b	d2
bset	d2,(a0,d0.w)
dbra	d7,starloop
rts

copper:
dc.w	$2001,$fffe
dc.w	$0102,$0000
dc.w	$0104,$0000
dc.w	$0108,$0000
dc.w	$010a,$0000
dc.w	$008e,$2c81
dc.w	$0090,$f4c1
dc.w	$0090,$38c1
dc.w	$0092,$0038
dc.w	$0094,$00d0
dc.w	$0180,$0000
dc.w	$0182,$0f8f

dc.w	$2c01,$fffe
dc.w	$0100,$1200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000

dc.w	$ffdf,$fffe
dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

stars:
blk.l	256,0

sin:
blk.w	1280,0

acc:
blk.w	512,0

screen:
blk.w	10240,0


