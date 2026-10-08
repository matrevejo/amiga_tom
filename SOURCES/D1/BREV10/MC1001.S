move.l	#100000,d0
bsr	allocchip

cmp.l	#0,d0
beq	nomem

lea.l	buffer,a0
move.l	d0,(a0)



move.l	#100000,d0
lea.l	buffer,a0
move.l	(a0),a0
bsr	freemem
rts

nomem:
rts

buffer:
dc.l	0


allocdef:
movem.l	d1-d7/a0-a6,-(a7)
moveq	#1,d1
swap	d1
move.l	$4,a6
jsr	-198(a6)
movem.l	(a7)+,d1-d7/a0-a6
rts

allocchip:
movem.l	d1-d7/a0-a6,-(a7)
move.l	#$10002,d1
move.l	$4,a6
jsr	-198(a6)
movem.l	(a7)+,d1-d7/a0-a6
rts

allocfast:
movem.l	d1-d7/a0-a6,-(a7)
move.l	#$10004,d1
move.l	$4,a6
jsr	-198(a6)
movem.l	(a7)+,d1-d7/a0-a6
rts

freemem:
movem.l	d0-d7/a0-a6,-(a7)
move.l	a0,a1
move.l	$4,a6
jsr	-210(a6)
movem.l	(a7)+,d0-d7/a0-a6
rts

