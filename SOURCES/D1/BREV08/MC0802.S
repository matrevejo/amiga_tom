move.w	#$0001,$dff096

lea.l	sample,a1
move.l	a1,$dff0a0
move.w	#8,$dff0a4
move.w	#0,$dff0a6
move.w	#0,$dff0a8

move.w	#$8001,$dff096

lea.l	music,a1

mainloop:
bsr	wait

move.w	(a1)+,d1
move.w	d1,$dff0a6
move.w	(a1)+,d2
move.w	d2,$dff0a8

cmp.w	#0,d1
bne	mainloop
cmp.w	#0,d2
bne	mainloop

move.w	#$0001,$dff096
rts

wait:
moveq	#4,d1

wait2:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#200,d0
bne	wait2

wait3:
move.l	$dff004,d0
asr.l	#8,d0
andi.l	#$1ff,d0
cmp.w	#201,d0
bne	wait3

dbra	d1,wait2

rts

sample:
dc.b	0,40,90,110,127,110,90,40,0,-40,-90,-110,-127,-110,-90,-40

music:
dc.w	428,64,428,64
dc.w	428,0
dc.w	381,64,381,64
dc.w	381,0
dc.w	339,64,339,64
dc.w	339,0
dc.w	320,64,320,64
dc.w	320,0
dc.w	285,64,285,64
dc.w	285,0
dc.w	254,64,254,64
dc.w	254,0
dc.w	226,64,226,64
dc.w	226,0
dc.w	214,64,214,64,214,64
dc.w	214,0,214,0,214,0

dc.w	214,64
dc.w	226,64
dc.w	254,64
dc.w	285,64
dc.w	320,64
dc.w	339,64
dc.w	381,64
dc.w	428,64,428,64,428,64

dc.w	428,0,428,0,428,0
dc.w	865,64,865,64,865,64

dc.w	0,0

