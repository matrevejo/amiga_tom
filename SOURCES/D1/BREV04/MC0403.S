move.w	#$01a0,$dff096

move.w	#$5200,$dff100
move.w	#0,$dff102
move.w	#0,$dff104
move.w	#0,$dff108
move.w	#0,$dff10a

move.w	#$1c71,$dff08e
move.w	#$f4d1,$dff090
move.w	#$48d1,$dff090

move.w	#$0030,$dff092
move.w	#$00d8,$dff094

lea.l	screen,a1
move.l	#$dff180,a2
moveq	#31,d0
colorloop:
move.w	(a1)+,(a2)+
dbra	d0,colorloop

move.l	a1,d1
lea.l	bplcop,a2
addq.l	#2,a2
moveq	#4,d0

bplloop:
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
add.l	#12320,d1
dbra	d0,bplloop

lea.l	copper,a1
move.l	a1,$dff080

move.w	#$8180,$dff096

wait:
btst	#6,$bfe001
bne	wait

move.w	#$0080,$dff096

move.l	$4,a6
move.l	156(a6),a1
move.l	38(a1),$dff080

move.w	#$80a0,$dff096

rts

copper:
dc.w	$1c01,$fffe
dc.w	$0100,$5200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000
dc.w	$00e4,$0000
dc.w	$00e6,$0000
dc.w	$00e8,$0000
dc.w	$00ea,$0000
dc.w	$00ec,$0000
dc.w	$00ee,$0000
dc.w	$00f0,$0000
dc.w	$00f2,$0000

dc.w	$ffdf,$fffe

dc.w	$3401,$fffe

dc.w	$0100,$0200

dc.w	$ffff,$fffe

screen:
blk.l	$3c38,0

