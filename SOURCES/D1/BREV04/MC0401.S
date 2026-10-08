start:
move.l	#$00,d0
move.l	#$04,d1
lea.l	table,a0

loop01:
add.w	(a0)+,d0
dbra	d1,loop01

lea.l	result,a0
move.l	d0,(a0)

rts

result:
blk.l	1,0

table:
dc.w	2,4,6,8,10

