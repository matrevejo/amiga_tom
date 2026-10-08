cmp.w	#1,d0
ble	noarg

lea.l	argbuffer,a1
move.l	d0,d7

copyarg:
move.b	(a0)+,(a1)+
subq.w	#1,d0
cmp.w	#0,d0
bne	copyarg

bsr	opendos
move.l	d7,d0
lea.l	argbuffer,a0
bsr	writechar

rts

noarg:
rts

argbuffer:
blk.b	80,0

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
lea.l	txt_dosbase,a5
move.l	d0,(a5)
movem.l	(a7)+,d0-d7/a0-a6
rts

txt_dosname:
dc.b	"dos.library",0
txt_dosbase:
dc.l	$0

