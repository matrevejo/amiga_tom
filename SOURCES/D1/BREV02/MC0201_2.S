move.w	#$01a0,$dff096
lea.l	copperlist,a1
move.l	a1,$dff080
move.w	#$8080,$dff096

wait:
btst	#6,$bfe001
bne	wait

move.w	#$0080,$dff096
move.l	$04,a6
move.l	156(a6),a1
move.l	38(a1),$dff080
move.w	#$81a0,$dff096
rts

copperlist:
dc.w	$9001,$fffe
dc.w	$0180,$0f00
dc.w	$a001,$fffe
dc.w	$0180,$0fff
dc.w	$a401,$fffe
dc.w	$0180,$000f
dc.w	$aa01,$fffe
dc.w	$0180,$0fff
dc.w	$ae01,$fffe
dc.w	$0180,$0f00
dc.w	$be01,$fffe
dc.w	$0180,$0000
dc.w	$ffff,$fffe

