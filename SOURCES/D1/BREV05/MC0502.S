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

lea.l	s1,a1
lea.l	copper,a2
add.l	#2,a2
move.l	a1,d1
move.l	#7,d0

sprcoploop:
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
swap	d1
move.w	d1,(a2)
addq.l	#4,a2
add.l	#68,d1
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

bsr	movesprite

btst	#6,$bfe001
bne	wait

move.w	#$0080,$dff096

move.l	$04,a6
move.l	156(a6),a6
move.l	38(a6),$dff080

move.w	#$8080,$dff096

move.w	#$c000,$dff09a
rts

movecount:
dc.w	$0000

movesprite:
lea.l	movecount,a5
move.w	(a5),d5
add.w	#4,(a5)

cmp.w	#12000,d5
blt	notend

clr.l	d5
clr.w	(a5)

notend:
clr.l	d1
clr.l	d2
lea.l	movetable,a5
move.l	#15,d3

move.w	(a5,d5.w),d1
move.w	2(a5,d5.w),d2
lea.l	s8,a1
bsr	setspr

move.w	16(a5,d5.w),d1
move.w	18(a5,d5.w),d2
lea.l	s7,a1
bsr	setspr

move.w	32(a5,d5.w),d1
move.w	34(a5,d5.w),d2
lea.l	s6,a1
bsr	setspr

move.w	48(a5,d5.w),d1
move.w	50(a5,d5.w),d2
lea.l	s5,a1
bsr	setspr

move.w	64(a5,d5.w),d1
move.w	66(a5,d5.w),d2
lea.l	s4,a1
bsr	setspr

move.w	80(a5,d5.w),d1
move.w	82(a5,d5.w),d2
lea.l	s3,a1
bsr	setspr

move.w	96(a5,d5.w),d1
move.w	98(a5,d5.w),d2
lea.l	s2,a1
bsr	setspr

move.w	112(a5,d5.w),d1
move.w	114(a5,d5.w),d2
lea.l	s1,a1
bsr	setspr
rts

setspr:
movem.l	d0-d5,-(a7)
add.w	#$81,d1
add.w	#$2c,d2
clr.l	d5
move.b	d2,(a1)
move.l	d2,d4
lsr.w	#8,d4
lsl.w	#2,d4
add.w	d4,d5
add.w	d3,d2
move.b	d2,2(a1)
move.l	d2,d4
lsr.w	#8,d4
lsl.w	#1,d4
add.w	d4,d5
move.l	d1,d3
andi.l	#1,d1
add.w	d1,d5
move.b	d5,3(a1)
lsr.l	#1,d3
move.b	d3,1(a1)
movem.l	(a7)+,d0-d5
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
dc.w	$0182,$00ff

dc.w	$01a2,$0f00
dc.w	$01a4,$0fff
dc.w	$01a6,$000b

dc.w	$01aa,$0f00
dc.w	$01ac,$0fff
dc.w	$01ae,$000b

dc.w	$01b2,$0f00
dc.w	$01b4,$0fff
dc.w	$01b6,$000b

dc.w	$01ba,$0f00
dc.w	$01bc,$0fff
dc.w	$01be,$000b

dc.w	$ffdf,$fffe
dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

screen:
blk.l	2560,0

s1:
dc.w $0000,$0000
dc.w $FF00,$0000
dc.w $FF80,$0000
dc.w $FFC0,$0000
dc.w $FFC0,$0020
dc.w $03C0,$7C20
dc.w $03C0,$0020
dc.w $FF80,$0060
dc.w $FF00,$00C0
dc.w $F380,$0C00
dc.w $F3C0,$0800
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $FF80,$0060
dc.w $FF00,$00C0
dc.w $0000,$7F80
dc.w $0000,$0000

s2:
dc.w $0000,$0000
dc.w $FF00,$0000
dc.w $FF80,$0000
dc.w $FFC0,$0000
dc.w $FFC0,$0020
dc.w $03C0,$7C20
dc.w $03C0,$0020
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $FF00,$00E0
dc.w $FF80,$0000
dc.w $F7C0,$0800
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $0000,$79E0
dc.w $0000,$0000

s3:
dc.w $0000,$0000
dc.w $FFC0,$0000
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $0000,$7FE0
dc.w $0000,$0000
dc.w $FF00,$0000
dc.w $FF00,$0080
dc.w $F000,$0F80
dc.w $F000,$0800
dc.w $FFC0,$0000
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $0000,$7FE0
dc.w $0000,$0000

s4:
dc.w $0000,$0000
dc.w $F3C0,$0000
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $7F80,$0060
dc.w $3F00,$00C0
dc.w $1E00,$0180
dc.w $0C00,$0300
dc.w $0000,$0600
dc.w $0000,$0000

s5:
dc.w $0000,$0000
dc.w $F3C0,$0000
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $03C0,$7820
dc.w $03C0,$0020
dc.w $FF00,$00E0
dc.w $FF80,$0000
dc.w $F3C0,$0C00
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $0000,$79E0
dc.w $0000,$0000

s6:
dc.w $0000,$0000
dc.w $F3C0,$0000
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $7F80,$0060
dc.w $3F00,$00C0
dc.w $0000,$1F80
dc.w $0000,$0000

s7:
dc.w $0000,$0000
dc.w $FF00,$0000
dc.w $FF80,$0000
dc.w $FFC0,$0000
dc.w $FFC0,$0020
dc.w $03C0,$7C20
dc.w $03C0,$0020
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $FF00,$00E0
dc.w $FF80,$0000
dc.w $F7C0,$0800
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $F3C0,$0820
dc.w $0000,$79E0
dc.w $0000,$0000

s8:
dc.w $0000,$0000
dc.w $3FC0,$0000
dc.w $7FC0,$0020
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $0000,$7FE0
dc.w $0000,$0000
dc.w $3F00,$0000
dc.w $3F80,$0000
dc.w $03C0,$1C00
dc.w $03C0,$0020
dc.w $FFC0,$0020
dc.w $FFC0,$0020
dc.w $FF80,$0060
dc.w $FF00,$00C0
dc.w $0000,$7F80
dc.w $0000,$0000
dc.w $0000,$0000

movetable:
blk.l	3100,0

