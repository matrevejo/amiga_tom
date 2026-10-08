bsr	opendos

moveq	#40,d0
lea.l	input,a0
bsr	readchar

addq.l	#7,d0
lea.l	output,a0
bsr	writechar
rts

output:
dc.b	"Hallo, "

input:
blk.b	40,0
even


readchar:
movem.l	d1-d7/a0-a6,-(a7)
move.l	a0,a5
move.l	d0,d5
lea.l	txt_dosbase,a0
move.l	(a0),a6
jsr	-54(a6)
move.l	d0,d1
move.l	a5,d2
move.l	d5,d3
jsr	-42(a6)
movem.l	(a7)+,d1-d7/a0-a6
rts

writechar:
movem.l	d1-d7/a0-a6,-(a7)
move.l	a0,a5
move.l	d0,d5
lea.l	txt_dosbase,a0
move.l	(a0),a6
jsr	-60(a6)
move.l	d0,d1
move.l	a5,d2
move.l	d5,d3
jsr	-48(a6)
movem.l	(a7)+,d1-d7/a0-a6
rts

opendos:
movem.l	d0-d7/a0-a6,-(a7)
clr.l	d0
move.l	$4,a6
lea.l	txt_dosname,a1
jsr	-408(a6)
lea.l	txt_dosbase,a1
move.l	d0,(a1)
movem.l	(a7)+,d0-d7/a0-a6
rts

txt_dosname:
dc.b	"dos.library",0
txt_dosbase:
dc.l	$0

