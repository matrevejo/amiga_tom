move.w	#$4000,$dff09a

or.b	#%10000000,$bfd100
and.b	#%10000111,$bfd100

move.w	#$01a0,$dff096

move.w	#$1200,$dff100
move.w	#0,$dff102
move.w	#0,$dff104
move.w	#2,$dff108
move.w	#2,$dff10a
move.w	#$2c71,$dff08e
move.w	#$f4d1,$dff090
move.w	#$38d1,$dff090
move.w	#$0030,$dff092
move.w	#$00d8,$dff094

lea.l	screen,a1
lea.l	bplcop,a2
move.l	a1,d1
swap	d1
move.w	d1,2(a2)
swap	d1
move.w	d1,6(a2)

lea.l	copper,a1
move.l	a1,$dff080
move.w	#$8180,$dff096

mainloop:
move.l	$dff004,d0
asr.l	#8,d0
and.l	#$1ff,d0
cmp.w	#300,d0
bne	mainloop

bsr	scroll

bsr	cycle

btst	#6,$bfe001
bne	mainloop

move.w	#$0080,$dff096

move.l	$04,a6
move.l	156(a6),a1
move.l	38(a1),$dff080

move.w	#$80a0,$dff096

move.w	#$c000,$dff09a
rts

scrollcnt:
dc.w	$0000

charcnt:
dc.w	$0000

scroll:
lea.l	scrollcnt,a1
cmp.w	#8,(a1)
bne	nochar

clr.w	(a1)

lea.l	charcnt,a1
move.w	(a1),d1
addq.w	#1,(a1)

lea.l	text,a2
clr.l	d2
move.b	(a2,d1.w),d2

cmp.b	#42,d2
bne	notend

clr.w	(a1)
move.b	#32,d2

notend:
lea.l	convtab,a1
move.b	(a1,d2.b),d2
asl.w	#1,d2

lea.l	font,a1
add.l	d2,a1

lea.l	screen,a2
add.l	#6944,a2

moveq	#19,d0

putcharloop:
move.w	(a1),(a2)
add.l	#64,a1
add.l	#46,a2
dbra	d0,putcharloop

nochar:
btst	#6,$dff002
bne	nochar

lea.l	screen,a1
add.l	#7820,a1

move.l	a1,$dff050
move.l	a1,$dff054
move.w	#0,$dff064
move.w	#0,$dff066
move.l	#$ffffffff,$dff044
move.w	#$29f0,$dff040
move.w	#$0002,$dff042
move.w	#$0523,$dff058

lea.l	scrollcnt,a1
addq.w	#1,(a1)

rts

cyclecnt:
dc.w	$0000

cycle:
lea.l	cyclecnt,a1
move.w	(a1),d1

addq.w	#2,(a1)

cmp.w	#96,d1
bne	notround

clr.w	(a1)
clr.w	d1

notround:
lea.l	cycletable,a2
lea.l	cyclecop,a3

moveq	#19,d0

cycleloop:
move.w	(a2,d1.w),6(a3)
addq.w	#2,d1
addq.l	#8,a3
dbra	d0,cycleloop

rts

copper:
dc.w	$2c01,$fffe
dc.w	$0100,$1200

bplcop:
dc.w	$00e0,$0000
dc.w	$00e2,$0000

dc.w	$0180,$0000
dc.w	$0182,$0ff0

cyclecop:
dc.w	$c201,$fffe
dc.w	$0182,$0000
dc.w	$c301,$fffe
dc.w	$0182,$0000
dc.w	$c401,$fffe
dc.w	$0182,$0000
dc.w	$c501,$fffe
dc.w	$0182,$0000
dc.w	$c601,$fffe
dc.w	$0182,$0000
dc.w	$c701,$fffe
dc.w	$0182,$0000
dc.w	$c801,$fffe
dc.w	$0182,$0000
dc.w	$c901,$fffe
dc.w	$0182,$0000
dc.w	$ca01,$fffe
dc.w	$0182,$0000
dc.w	$cb01,$fffe
dc.w	$0182,$0000
dc.w	$cc01,$fffe
dc.w	$0182,$0000
dc.w	$cd01,$fffe
dc.w	$0182,$0000
dc.w	$ce01,$fffe
dc.w	$0182,$0000
dc.w	$cf01,$fffe
dc.w	$0182,$0000
dc.w	$d001,$fffe
dc.w	$0182,$0000
dc.w	$d101,$fffe
dc.w	$0182,$0000
dc.w	$d201,$fffe
dc.w	$0182,$0000
dc.w	$d301,$fffe
dc.w	$0182,$0000
dc.w	$d401,$fffe
dc.w	$0182,$0000
dc.w	$d501,$fffe
dc.w	$0182,$0000

dc.w	$ffdf,$fffe
dc.w	$2c01,$fffe
dc.w	$0100,$0200
dc.w	$ffff,$fffe

screen:
blk.l	$b80,0

font:
blk.l	$140,0

convtab:
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$1f ;" "
dc.b	$00
dc.b	$00
dc.b	$1b ;Ø
dc.b	$1c ;Å
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$1d ;,
dc.b	$00 ;-
dc.b	$1e ;.
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$00
dc.b	$1a ;Æ
dc.b	$00 ;A
dc.b	$01 ;B
dc.b	$02 ;C
dc.b	$03 ;...
dc.b	$04
dc.b	$05
dc.b	$06
dc.b	$07
dc.b	$08
dc.b	$09
dc.b	$0a
dc.b	$0b
dc.b	$0c
dc.b	$0d
dc.b	$0e
dc.b	$0f
dc.b	$10
dc.b	$11
dc.b	$12
dc.b	$13
dc.b	$14
dc.b	$15
dc.b	$16 ;....
dc.b	$17 ;X
dc.b	$18 ;Y
dc.b	$19 ;Z
dc.b	$00
dc.b	$00
dc.b	$00

cycletable:
dc.w	$0f00,$0e01,$0d02,$0c03,$0b04,$0a05,$0906,$0807
dc.w	$0708,$0609,$050a,$040b,$030c,$020d,$010e,$000f
dc.w	$000f,$011e,$022d,$033c,$044b,$055a,$0669,$0778
dc.w	$0887,$0996,$0aa5,$0bb4,$0cc3,$0dd2,$0ee1,$0ff0
dc.w	$0ff0,$0fe0,$0fd0,$0fc0,$0fb0,$0fa0,$0f90,$0f80
dc.w	$0f70,$0f60,$0f50,$0f40,$0f30,$0f20,$0f10,$0f00

dc.w	$0f00,$0e01,$0d02,$0c03,$0b04,$0a05,$0906,$0807
dc.w	$0708,$0609,$050a,$040b,$030c,$020d,$010e,$000f
dc.w	$000f,$011e,$022d,$033c

text:
dc.b	"DETTE ER EN TEST AV EN SCROLL MED"
dc.b	" COLORCYCLING P$ AMIGA....    *"

