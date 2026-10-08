move.w	#$4000,$dff09a
move.w	#$03a0,$dff096
loop:
move.w	$dff006,$dff180
btst	#6,$bfe001
bne	loop
move.w	#$83a0,$dff096
move.w	#$c000,$dff09a
rts

