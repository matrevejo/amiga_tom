move.w	#$4000,$dff09a

or.b	#%10000000,$bfd100
and.b	#%10000111,$bfd100

move.w	#$01a0,$dff096

move.w	#$1200,$dff100
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
lea.l	bplcop,a2
move.l	a1,d1
move.w	d1,6(a2)
swap	d1
move.w	d1,2(a2)

lea.l	copper,a1
move.l	a1,$dff080
move.w	#$8180,$dff096

mainloop:
move.l	$dff004,d0
asr.l	#8,d0
andi.l	#$1ff,d0
cmp.w	#300,d0
bne	mainloop

bsr	clear

bsr	blitin

btst	#6,$bfe001
bne	mainloop

move.w	#$0080,$dff096

move.l	$4,a6
move.l	156(a6),a6
move.l	38(a6),$dff080

move.w	#$80a0,$dff096

move.w	#$c000,$dff09a
rts

clear:
lea.l	screen,a1

waitblit1:
btst	#6,$dff002
bne	waitblit1

move.l	a1,$dff054
move.w	#0,$dff066
move.w	#$0100,$dff040
move.w	#$0000,$dff042
move.w	#$4014,$dff058
rts

pos:
dc.l	0

blitin:
lea.l	pos,a1
move.l	(a1),d1
addq.l	#1,(a1)

cmp.w	#216,d1
bne	notbottom

clr.l	d1
clr.l	(a1)

notbottom:
lea.l	screen,a1
mulu	#40,d1
add.l	d1,a1
add.l	#12,a1

lea.l	object,a2

waitblit2:
btst	#6,$dff002
bne	waitblit2

move.l	a1,$dff054
move.l	a2,$dff050
move.w	#24,$dff066
move.w	#0,$dff064
move.l	#$ffffffff,$dff044
move.w	#$09f0,$dff040
move.w	#$0000,$dff042
move.w	#$0a08,$dff058
rts

copper:
dc.w	$2c01,$fffe
dc.w	$0100,$1200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000

dc.w	$0180,$0000
dc.w	$0182,$00ff

dc.w	$ffdf,$fffe

dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

screen:
blk.l	2560,0

object:
blk.l	160,0

