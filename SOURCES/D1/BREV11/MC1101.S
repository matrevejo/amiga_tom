main:
bsr	mouse

lea.l	mousex,a1
lea.l	mousey,a2

move.w	(a1),d1
move.w	(a2),d2



btst	#6,$bfe001
bne	main
rts


mouse:
movem.l	d0-d7/a0-a6,-(a7)
move.w	$dff00a,d0
andi.l	#255,d0
moveq	#0,d2
move.l	#639,d3
lea.l	oldx,a1
lea.l	mousex,a2
bsr.s	calcmouse
move.w	$dff00a,d0
lsr.w	#8,d0
andi.l	#255,d0
moveq	#0,d2
move.l	#511,d3
lea.l	oldy,a1
lea.l	mousey,a2
bsr.s	calcmouse
movem.l	(a7)+,d0-d7/a0-a6
rts
calcmouse:
moveq	#0,d1
move.w	(a1),d1
move.w	d0,(a1)
move.l	d0,d5
move.l	d1,d6
sub.w	d0,d1
cmp.w	#-128,d1
blt.s	mc_less
cmp.w	#127,d1
bgt.s	mc_more
cmp.w	#0,d1
blt.s	mc_chk2
mc_chk1:
cmp.w	d5,d6
bge.s	mc_chk1ok
neg.w	d1
mc_chk1ok:
bra.s	mc_storem
mc_chk2:
cmp.w	d5,d6
ble.s	mc_chk2ok
neg.w	d1
mc_chk2ok:
bra.s	mc_storem
mc_less:
add.w	#256,d1
bra.s	mc_storem
mc_more:
sub.w	#256,d1
mc_storem:
neg.w	d1
add.w	d1,(a2)
move.w	(a2),d0
cmp.w	d2,d0
blt.s	mc_toosmall
cmp.w	d3,d0
bgt.s	mc_toolarge
rts
mc_toosmall:
move.w	d2,(a2)
rts
mc_toolarge:
move.w	d3,(a2)
rts
oldx:
dc.l	$0000
oldy:
dc.l	$0000
mousex:
dc.w	$0000
mousey:
dc.w	$0000

