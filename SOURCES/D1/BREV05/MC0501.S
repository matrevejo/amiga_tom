move.w	#$4000,$dff09a

or.b	#%10000000,$bfd100
and.b	#%10000111,$bfd100

move.w	#$01a0,$dff096

move.w	#$1200,$dff100
move.w	#$0000,$dff102
move.w	#$003f,$dff104
move.w	#0,$dff108
move.w	#0,$dff10a
move.w	#$2c81,$dff08e
move.w	#$f4c1,$dff090
move.w	#$38c1,$dff090
move.w	#$0038,$dff092
move.w	#$00d0,$dff094

lea.l	sprite,a1
lea.l	copper,a2
move.l	a1,d1
move.w	d1,6(a2)
swap	d1
move.w	d1,2(a2)

lea.l	blanksprite,a1
lea.l	copper,a2
add.l	#10,a2
move.l	a1,d1
moveq	#6,d0

sprcoploop:
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
dbra	d0,sprcoploop

lea.l	screen,a1
lea.l	bplcop,a2
move.l	a1,d1
move.w	d1,6(a2)
swap	d1
move.w	d1,2(a2)

lea.l	copper,a1
move.l	a1,$dff080
move.w	$dff088,d0
move.w	#$81a0,$dff096

wait:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#0,d0
bne	wait

wait2:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#1,d0
bne	wait2

bsr	movesprite

btst	#6,$bfe001
bne	wait

move.w	#$0080,$dff096

move.l	$04,a6
move.l	156(a6),a1
move.l	38(a1),$dff080

move.w	#$8080,$dff096

move.w	#$c000,$dff09a
rts

movesprite:
lea.l	sprite,a1
cmp.b	#250,2(a1)
bne	notbottom

move.b	#30,(a1)
move.b	#44,2(a1)

notbottom:
add.b	#1,(a1)
add.b	#1,2(a1)
rts

copper:
dc.w	$0120,$0000
dc.w	$0122,$0000
dc.w	$0124,$0000
dc.w	$0126,$0000
dc.w	$0128,$0000
dc.w	$012a,$0000
dc.w	$012c,$0000
dc.w	$012e,$0000
dc.w	$0130,$0000
dc.w	$0132,$0000
dc.w	$0134,$0000
dc.w	$0136,$0000
dc.w	$0138,$0000
dc.w	$013a,$0000
dc.w	$013c,$0000
dc.w	$013e,$0000

dc.w	$2c01,$fffe
dc.w	$0100,$1200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000

dc.w	$0180,$0000
dc.w	$0182,$0ff0
dc.w	$01a2,$0f00
dc.w	$01a4,$0fff
dc.w	$01a6,$000b

dc.w	$ffdf,$fffe
dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

screen:
blk.b	10240,0

sprite:
dc.w	$1e8c,$2c00
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$0300,$FFFF
dc.w	$FFFF,$FFFF
dc.w	$FFFF,$FFFF
dc.w	$0300,$FFFF
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$FB7F,$0780
dc.w	$0000,$0000
dc.w	$0000,$0000

blanksprite:
dc.w	$0000,$0000

