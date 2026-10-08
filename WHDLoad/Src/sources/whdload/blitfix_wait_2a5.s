;*---------------------------------------------------------------------------
;  :Modul.	blitfix_imm_58a5.s
;  :Contents.	routine to fix program that does not correctly wait for
;		blitter finish
;		the instruction which writes the "bltsize" register will be
;		patched with a routine which will wait for blitter finish
;		after writing "bltsize"
;  :Version.	$Id: blitfix_wait_2a5.s 1.1 2009/02/05 20:40:49 wepl Exp wepl $
;  :History.	15.05.08 created
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*
;
; this will patch the following instructions:
;		btst	#14,(2,a5)
;		bne.b	*-6
;
; IN:	A0 = APTR start of memory to patch
;	A1 = APTR end of memory to patch
;	A2 = APTR patchcount
; OUT:	D0-D1/A0-A1 unchanged
;	A2 = APTR points to the end of patchcount

_blitfix_wait_2a5
		movem.l	a0-a1,-(a7)

	IFD PATCHCOUNT
		clr.w	(a2)
	ENDC

		subq.l	#6,a1
.loop		cmp.w	#$82d,(a0)+		;move.w #xxxx,($xxxx,a5)
		bne	.next
		cmp.w	#14,(a0)+
		bne	.next
		cmp.w	#2,(a0)+
		bne	.next
		cmp.w	#$66f8,(a0)+		;bne.b *-6
		bne	.next
		subq.l	#8,a0
		move.l	#$4e714eb9,(a0)+	;nop, jsr x.l
		pea	.bw
		move.l	(a7)+,(a0)+

	IFD PATCHCOUNT
		addq.w	#1,(a2)
	ENDC

.next		cmp.l	a0,a1
		bhs	.loop

	IFD PATCHCOUNT
		addq.w	#2,a2
	ENDC

		movem.l	(a7)+,a0-a1
		rts

.bw		BLITWAIT a5
		rts

