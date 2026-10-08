move.l	#24,d0
lea.l	filename,a0
lea.l	buffer,a1

bsr	readfile

cmp.l	#0,d0
beq	error

rts

error:
rts

filename:
dc.b	"Testfil",0

buffer:
blk.b	50,0


readfile:
movem.l	d1-d7/a0-a6,-(a7)
move.l	a0,a4
move.l	a1,a5
move.l	d0,d5
move.l	$4,a6
lea.l	r_dosname,a1
jsr	-408(a6)
move.l	d0,a6
move.l	#1005,d2
move.l	a4,d1
jsr	-30(a6)
cmp.l	#0,d0
beq	r_error
move.l	d0,d1
move.l	d0,d7
move.l	a5,d2
move.l	d5,d3
jsr	-42(a6)
move.l	d7,d1
move.l	d0,d7
jsr	-36(a6)
move.l	d7,d0
movem.l	(a7)+,d1-d7/a0-a6
rts
r_error:
clr.l	d0
movem.l	(a7)+,d1-d7/a0-a6
rts
r_dosname:
dc.b	"dos.library",0

