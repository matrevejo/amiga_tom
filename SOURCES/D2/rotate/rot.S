move.w	#$4000,$dff09a

bsr	initcop
bsr	setcolor

move.w	#$01a0,$dff096

lea.l	copper(pc),a1
move.l	a1,$dff080

move.w	#$8180,$dff096

main:
lea.l	pos(pc),a1
addq.w	#7,(a1)

bsr	genrot

bpos:
move.l	$dff004,d0
asr.l	#8,d0
andi.w	#$1ff,d0
cmp.w	#300,d0
bne.s	bpos

bsr.s	genpt
bsr.s	gencop

btst	#6,$bfe001
bne.s	main

move.l	4.w,a6
move.l	156(a6),a6
move.l	38(a6),a6
move.l	a6,$dff080
move.w	#$8020,$dff096
rts

gencop:
lea.l	cop+6(pc),a1
lea.l	gentab(pc),a2
move.w	#255,d0
gencoploop:
move.w	(a2),(a1)
addq.l	#4,a1
move.w	(a2)+,(a1)
addq.l	#8,a1
dbra	d0,gencoploop
rts

genpt:
lea.l	pos(pc),a1
move.w	(a1),d1
andi.w	#$7fe,d1
lea.l	screen+16(pc),a1
cmp.w	#1024,d1
ble.s	genpt2
add.w	#10240,a1
genpt2:
lea.l	bplcop(pc),a2
move.l	a1,d1
moveq	#2,d0
bplcoploop:
swap	d1
move.w	d1,2(a2)
swap	d1
move.w	d1,6(a2)
addq.l	#8,a2
add.l	#10240,d1
dbra	d0,bplcoploop
rts

pos:
dc.w	0

genrot:
lea.l	pos(pc),a1
move.w	(a1),d1
andi.w	#$7fe,d1
cmp.w	#1024,d1
bgt.s	type2
lea.l	sin(pc),a1
moveq	#0,d2
move.w	(a1,d1.w),d2
move.l	d2,d3
move.l	d2,d5
lsr.w	#8,d2
andi.w	#255,d5
lsl.w	#8,d5
move.w	#256,d1
sub.w	d2,d1
lsr.w	#1,d1
add.w	d1,d2
moveq	#0,d0
lea.l	gentab(pc),a1
loop1:
cmp.w	d0,d1
beq.s	loop1ok
move.w	#-40,(a1)+
addq.w	#1,d0
bra.s	loop1
loop1ok:
moveq	#0,d4
sub.l	d5,d4
moveq	#0,d5
loop2:
cmp.w	d0,d2
beq.s	loop3
addq.w	#1,d0
moveq	#-1,d6
loop2x:
add.l	d3,d4
move.l	d4,d7
swap	d7
addq.w	#1,d6
cmp.w	d5,d7
ble.s	loop2x
move.w	d7,d5
mulu	#40,d6
move.w	d6,(a1)+
bra.s	loop2
loop3:
cmp.w	#256,d0
beq.s	loop3ok
move.w	#-40,(a1)+
addq.w	#1,d0
bra.s	loop3
loop3ok:
rts
type2:
lea.l	sin(pc),a1
moveq	#0,d2
move.w	(a1,d1.w),d2
move.l	d2,d3
move.l	d2,d5
lsr.w	#8,d2
andi.w	#255,d5
lsl.w	#8,d5
move.w	#256,d1
sub.w	d2,d1
lsr.w	#1,d1
add.w	d1,d2
moveq	#0,d0
lea.l	gentab(pc),a1
loop1b:
cmp.w	d0,d1
beq.s	loop1okb
move.w	#-40,(a1)+
addq.w	#1,d0
bra.s	loop1b
loop1okb:
moveq	#0,d4
sub.l	d5,d4
moveq	#0,d5
loop2b:
cmp.w	d0,d2
beq.s	loop3b
addq.w	#1,d0
moveq	#1,d6
loop2bx:
add.l	d3,d4
move.l	d4,d7
swap	d7
addq.w	#1,d6
cmp.w	d5,d7
ble.s	loop2bx
move.w	d7,d5
muls	#-40,d6
move.w	d6,(a1)+
bra.s	loop2b
loop3b:
cmp.w	#256,d0
beq.s	loop3okb
move.w	#-40,(a1)+
addq.w	#1,d0
bra.s	loop3b
loop3okb:
rts

initcop:
lea.l	cop(pc),a1
move.l	a1,a2
move.w	#255,d0
moveq	#$2c,d1
initcoploop:
move.b	d1,(a1)+
move.b	#$01,(a1)+
move.w	#$fffe,(a1)+
move.l	#$01080000,(a1)+
move.l	#$010a0000,(a1)+
addq.w	#1,d1
dbra	d0,initcoploop
move.w	#$ffdf,2544(a2)
rts

setcolor:
lea.l	screen(pc),a1
lea.l	colcop+2(pc),a2
moveq	#7,d0
colorloop:
move.w	(a1)+,(a2)
addq.l	#4,a2
dbra	d0,colorloop
rts

copper:
dc.w	$2001,$fffe
dc.w	$0100,$0200
dc.w	$008e,$2c81
dc.w	$0090,$f4c1
dc.w	$0090,$38c1
dc.w	$0092,$0038
dc.w	$0094,$00d0
dc.w	$0102,$0000
dc.w	$0104,$0000
dc.w	$0108,$0000
dc.w	$010a,$0000

colcop:
dc.w	$0180,$0000
dc.w	$0182,$0000
dc.w	$0184,$0000
dc.w	$0186,$0000
dc.w	$0188,$0000
dc.w	$018a,$0000
dc.w	$018c,$0000
dc.w	$018e,$0000

dc.w	$2b01,$fffe

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000
dc.w	$00e4,$0000
dc.w	$00e6,$0000
dc.w	$00e8,$0000
dc.w	$00ea,$0000

dc.w	$0100,$3200

cop:
blk.w	1536,0

dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

gentab:
blk.w	256,0

sin:
blk.w	1024,0

screen:
blk.w	15388,0

