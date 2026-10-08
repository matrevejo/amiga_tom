move.w	#$4000,$dff09a

move.w	#$01a0,$dff096

lea.l	screen(pc),a1
move.l	#$dff180,a2
moveq	#3,d0
colloop:
move.w	(a1)+,(a2)+
dbra	d0,colloop

lea.l	bplcop+2(pc),a2
move.l	a1,d1
moveq	#1,d0
bplloop:
swap	d1
move.w	d1,(a2)
swap	d1
move.w	d1,4(a2)
addq.l	#8,a2
add.l	#10240,d1
dbra	d0,bplloop

bsr.s	initcop

lea.l	copper(pc),a1
move.l	a1,$dff080

move.w	#$8180,$dff096

wait:
move.l	$dff004,d0
asr.l	#8,d0
andi.w	#$1ff,d0
cmp.w	#280,d0
bne.s	wait

bsr.s	wave

btst	#6,$bfe001
bne.s	wait

move.l	$04.w,a6
move.l	156(a6),a6
move.l	38(a6),$dff080

move.w	#$8020,$dff096
rts

initcop:
lea.l	wavecop(pc),a1
move.w	#$4adf,d1
move.w	#199,d0
initcoploop:
move.w	d1,(a1)+
move.w	#$fffe,(a1)+
move.l	#$01020000,(a1)+
add.w	#$100,d1
dbra	d0,initcoploop
rts

cont:
dc.w	0

wave:
lea.l	cont(pc),a1
move.w	(a1),d1
addq.w	#2,(a1)
andi.w	#$fe,d1
lea.l	sin(pc),a1
add.w	d1,a1
lea.l	wavecop+6(pc),a2
move.w	#199,d0
waveloop:
move.w	(a1)+,(a2)
addq.l	#8,a2
dbra	d0,waveloop
rts

copper:
dc.w	$2001,$fffe
dc.w	$0104,$0000
dc.w	$0108,$0000
dc.w	$010a,$0000
dc.w	$008e,$2c81
dc.w	$0090,$f4c1
dc.w	$0090,$38c1
dc.w	$0092,$0038
dc.w	$0094,$00d0

dc.w	$2c01,$fffe
dc.w	$0100,$2200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000
dc.w	$00e4,$0000
dc.w	$00e6,$0000

wavecop:
blk.w	1600/2,0

dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

sin:
blk.w	656/2,0

screen:
blk.w	20488/2,0

