move.w	#$01a0,$dff096

move.w	#$1200,$dff100
move.w	#0,$dff102
move.w	#0,$dff104
move.w	#0,$dff108
move.w	#0,$dff10a

move.w	#$2c81,$dff08e
move.w	#$f4c1,$dff090
move.w	#$38c1,$dff090

move.w	#$0038,$dff092
move.w	#$00d0,$dff094

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
dc.w	$2c01,$fffe
dc.w	$0100,$1200

dc.w	$00e0,$0000
dc.w	$00e2,$0000

dc.w	$0180,$0000
dc.w	$0182,$0ff0

dc.w	$ffdf,$fffe

dc.w	$2c01,$fffe

dc.w	$0100,$0200

dc.w	$ffff,$fffe

