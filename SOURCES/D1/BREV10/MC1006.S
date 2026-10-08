lea.l	buffer,a0
move.l	#0,d0
move.l	#0,d1
move.l	#195,d2
move.l	#1,d3

bsr	sector
rts


sector:
movem.l	d0-d7/a0-a6,-(a7)
lsl.l	#8,d1
add.l	d1,d1
lsl.l	#8,d2
add.l	d2,d2
move.l	d1,-(a7)
move.l	d2,-(a7)
move.l	a0,-(a7)
move.l	d0,-(a7)
move.l	$4,a6
lea.l	ws_diskport,a2
moveq	#-1,d0  
jsr	-330(a6)   
moveq	#-1,d1
move.b	d0,15(a2)
clr.b	14(a2)
move.b	#4,8(a2)
move.b	#120,9(a2)
sub.l	a1,a1
jsr	-294(a6)
move.l	d0,16(a2)
lea.l	20(a2),a0
move.l	a0,(a0)
addq.l	#4,(a0)
clr.l	4(a0)
move.l	a0,8(a0)
lea.l	ws_diskreq,a1
move.b	#$05,8(a1)
move.l	a2,14(a1)
lea.l	ws_devicename,a0
move.l	(a7)+,d0
clr.l	d1
jsr	-444(a6)
move.l	(a7)+,40(a1)
andi.l	#3,d3
addq.w	#1,d3
move.w	d3,28(a1)
move.l	(a7)+,36(a1)
move.l	(a7)+,44(a1)
jsr	-456(a6)
move.l	d0,d7
move.l	#0,36(a1)
move.w	#$9,28(a1)
jsr	-456(a6)
movem.l	(a7)+,d0-d7/a0-a6
rts
ws_diskport:
blk.l	100,0
ws_diskreq:
blk.l	15,0
ws_devicename:
dc.b	"trackdisk.device",0,0


buffer:
blk.w	49920,0

