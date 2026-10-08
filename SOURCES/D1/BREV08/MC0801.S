move.w	#$0001,$dff096

lea.l	sample,a1
move.l	a1,$dff0a0
move.w	#48452,$dff0a4
move.w	#700,$dff0a6
move.w	#0,$dff0a8

move.w	#$8001,$dff096

moveq	#0,d1
move.l	#700,d2
moveq	#64,d7

up:
bsr	wait
bsr	wait
move.w	d1,$dff0a8
move.w	d2,$dff0a6
addq.l	#1,d1
subq.l	#8,d2
dbra	d7,up

waitmouse:
btst	#6,$bfe001
bne	waitmouse

moveq	#64,d7

down:
bsr	wait
bsr	wait
move.w	d1,$dff0a8
move.w	d2,$dff0a6
subq.l	#1,d1
addq.l	#8,d2
dbra	d7,down

move.w	#$0001,$dff096

rts

wait:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#200,d0
bne	wait

wait2:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#201,d0
bne	wait2

rts

sample:
blk.w	48452,0

