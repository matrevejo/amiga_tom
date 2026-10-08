move.w	#$4000,$dff09a

or.b	#%10000000,$bfd100
and.b	#%10000111,$bfd100

move.w	#$01a0,$dff096

move.w	#$5200,$dff100
move.w	#$0000,$dff102
move.w	#$0000,$dff104
move.w	#0,$dff108
move.w	#0,$dff10a
move.w	#$2c81,$dff08e
move.w	#$f4c1,$dff090
move.w	#$38c1,$dff090
move.w	#$0038,$dff092
move.w	#$00d0,$dff094

lea.l	screen,a1
move.l	#$dff180,a2
moveq	#31,d0

colorloop:
move.w	(a1)+,(a2)+
dbra	d0,colorloop

lea.l	bplcop,a2
addq.l	#2,a2
move.l	a1,d1
moveq	#4,d0

bplcoploop:
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
add.l	#10240,d1
dbra	d0,bplcoploop

lea.l	copper,a1
move.l	a1,$dff080
move.w	$dff088,d0

move.w	#$8580,$dff096

bsr	readmouse
bsr	storeback

mainloop:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#300,d0
bne	mainloop

bsr	recallback
bsr	readmouse
bsr	storeback
bsr	shiftblit
bsr	blitin

btst	#6,$bfe001
bne	mainloop

move.w	#$0080,$dff096

move.l	$4,a6
move.l	156(a6),a6
move.l	38(a6),$dff080

move.w	#$80a0,$dff096
move.w	#$0400,$dff096

move.w	#$c000,$dff09a
rts

blitin:
lea.l	maskbuffer,a1
lea.l	backbuffer,a3
lea.l	figbuffer,a2
lea.l	screen,a4
add.l	#64,a4

lea.l	mousex,a0
move.l	(a0),d0
lea.l	mousey,a0
move.l	(a0),d1

lsr.l	#4,d0
lsl.l	#1,d0
mulu	#40,d1
add.l	d0,a4
add.l	d1,a4

moveq	#4,d7

blitinloop:
btst	#6,$dff002
bne	blitinloop

move.l	a4,$dff054
move.l	a1,$dff050
move.l	a2,$dff04c
move.l	a3,$dff048
move.w	#32,$dff066
move.w	#0,$dff064
move.w	#0,$dff062
move.w	#0,$dff060
move.l	#$ffffffff,$dff044
move.w	#$0fca,$dff040
move.w	#$0000,$dff042
move.w	#$0b44,$dff058

add.l	#360,a2
add.l	#360,a3
add.l	#10240,a4

dbra	d7,blitinloop
rts

shiftblit:
lea.l	fig,a1
lea.l	figbuffer,a2

lea.l	mousex,a0
move.l	(a0),d1

andi.l	#$f,d1
lsl.l	#8,d1
lsl.l	#4,d1
add.w	#$09f0,d1

moveq	#4,d7

shiftfigloop:
btst	#6,$dff002
bne	shiftfigloop

move.l	a2,$dff054
move.l	a1,$dff050
move.w	#0,$dff066
move.w	#0,$dff064
move.l	#$ffffffff,$dff044
move.w	d1,$dff040
move.w	#$0000,$dff042
move.w	#$0b44,$dff058

add.l	#360,a1
add.l	#360,a2

dbra	d7,shiftfigloop

lea.l	mask,a1
lea.l	maskbuffer,a2

shiftmaskloop:
btst	#6,$dff002
bne	shiftmaskloop

move.l	a2,$dff054
move.l	a1,$dff050
move.w	#0,$dff066
move.w	#0,$dff064
move.l	#$ffffffff,$dff044
move.w	d1,$dff040
move.w	#$0000,$dff042
move.w	#$0b44,$dff058

rts

readmouse:
move.w	$dff00a,d0
move.l	d0,d1
lsr.w	#8,d1
andi.l	#$ff,d0
andi.l	#$ff,d1

lea.l	mousex,a1
move.l	d0,(a1)
lea.l	mousey,a1
move.l	d1,(a1)

rts

storeback:
lea.l	screen,a1
add.l	#64,a1
lea.l	backbuffer,a2

lea.l	mousex,a0
move.l	(a0),d0
lea.l	mousey,a0
move.l	(a0),d1

lsr.l	#4,d0
lsl.l	#1,d0
mulu	#40,d1
add.l	d0,a1
add.l	d1,a1

moveq	#4,d7

storebackloop:
btst	#6,$dff002
bne	storebackloop

move.l	a2,$dff054
move.l	a1,$dff050
move.w	#0,$dff066
move.w	#32,$dff064
move.l	#$ffffffff,$dff044
move.w	#$09f0,$dff040
move.w	#$0000,$dff042
move.w	#$0b44,$dff058

add.l	#10240,a1
add.l	#360,a2

dbra	d7,storebackloop
rts

recallback:
lea.l	screen,a1
add.l	#64,a1
lea.l	backbuffer,a2

lea.l	mousex,a0
move.l	(a0),d0
lea.l	mousey,a0
move.l	(a0),d1

lsr.l	#4,d0
lsl.l	#1,d0
mulu	#40,d1
add.l	d0,a1
add.l	d1,a1

moveq	#4,d7

recallbackloop:
btst	#6,$dff002
bne	recallbackloop

move.l	a1,$dff054
move.l	a2,$dff050
move.w	#32,$dff066
move.w	#0,$dff064
move.l	#$ffffffff,$dff044
move.w	#$09f0,$dff040
move.w	#$0000,$dff042
move.w	#$0b44,$dff058

add.l	#10240,a1
add.l	#360,a2

dbra	d7,recallbackloop
rts

copper:
dc.w	$2c01,$fffe
dc.w	$0100,$5200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000
dc.w	$00e4,$0000
dc.w	$00e6,$0000
dc.w	$00e8,$0000
dc.w	$00ea,$0000
dc.w	$00ec,$0000
dc.w	$00ee,$0000
dc.w	$00f0,$0000
dc.w	$00f2,$0000

dc.w	$ffdf,$fffe
dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

screen:
blk.l	12816,0

fig:
blk.l	450,0

mask:
blk.l	90,0

figbuffer:
blk.l	450,0

maskbuffer:
blk.l	90,0

backbuffer:
blk.l	450,0

mousex:
dc.l	0
mousey:
dc.l	0

