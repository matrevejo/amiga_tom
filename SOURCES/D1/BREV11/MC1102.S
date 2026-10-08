lea.l	buffer,a0

move.w	#$4000,$dff09a
bsr	print
move.w	#$c000,$dff09a

rts

buffer:
dc.b	"Dette er en test av en printer-rutine.",10
dc.b	0


print:
move.b	#$ff,$bfe301

wait:
move.b	$bfd000,d0
andi.b	#%111,d0
cmp.b	#%100,d0
beq.s	ready
cmp.b	#%001,d0
beq.s	offline
cmp.b	#%111,d0
beq.s	poweroff
cmp.b	#%001,d0
beq.s	wait
cmp.b	#%011,d0
beq.s	paperout
bra.s	wait

ready:
move.b	(a0)+,d0
cmp.b	#0,d0
beq.s	stop
move.b	d0,$bfe101
bra.s	wait

stop:
moveq	#0,d0
rts

poweroff:
moveq	#1,d0
rts

offline:
moveq	#2,d0
rts

paperout:
moveq	#3,d0
rts

