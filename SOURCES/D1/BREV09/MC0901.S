lea.l	jump,a1
move.l	$68,2(a1)

moveq	#100,d0

moveq	#1,d1
swap	d1
move.l	$4,a6
jsr	-198(a6)

move.l	d0,a1
move.l	d0,d7

lea.l	interrupt,a0
moveq	#24,d0

copyloop:
move.l	(a0)+,(a1)+
dbra	d0,copyloop

move.w	#$4000,$dff09a
move.l	d7,$68
move.w	#$c000,$dff09a

rts

interrupt:
move.l	d0,-(a7)
move.b	$bfec01,d0
not.b	d0
ror.b	#1,d0

cmp.b	#$59,d0
bne.s	wrongkey

bchg	#1,$bfe001

wrongkey:
move.l	(a7)+,d0

jump:
jmp	$0


