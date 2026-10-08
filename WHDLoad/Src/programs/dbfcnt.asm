;*---------------------------------------------------------------------------
;  :Program.	dbfcnt.asm
;		count how many cycles of a loop are perfomed in one rasterline
;		doesn't work with moved vbr!
;	empty dbf:    1x=49=$31 8x=394=$18A vhpos=6434-6D2D
;	empty dbf:    1x=49=$31 8x=397=$18D vhpos=6423-6D2A
;	empty dbf:    1x=49=$31 8x=396=$18C vhpos=6429-6D2A
;	c-style long: 1x= 8=$ 8 8x= 69=$ 45 vhpos=6429-6D32
;	c-style long: 1x= 8=$ 8 8x= 69=$ 45 vhpos=6429-6D32
;	c-style long: 1x= 8=$ 8 8x= 69=$ 45 vhpos=6429-6D32
;	nop dbf:      1x=35=$23 8x=283=$11B vhpos=642F-6D2D
;	nop dbf:      1x=35=$23 8x=284=$11C vhpos=6423-6D2A
;	nop dbf:      1x=35=$23 8x=284=$11C vhpos=6423-6D2A
;	long tst bne: 1x=22=$16 8x=181=$ B5 vhpos=6429-6D2C
;	long tst bne: 1x=22=$16 8x=180=$ B4 vhpos=642F-6D2D
;	long tst bne: 1x=22=$16 8x=180=$ B4 vhpos=642F-6D2D
;  :Author.	Bert Jahn
;  :EMail.	wepl@whdload.de
;  :Version.	$Id: dbfcnt.asm 1.4 2014/06/10 01:20:06 wepl Exp wepl $
;  :History.	09.06.14 created
;  :Copyright.	Private
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.117
;---------------------------------------------------------------------------*
;####################################################################

	;OUTPUT	awart:workbench13/data-132/dbfcnt
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODc-			;disable mul's optimize
	BOPT	ODd-			;disable mul's optimize
	BOPT	wo-			;disable optimize warnings
	;BOPT	sa+			;create symbol hunk
	BOPT	w4-			;64k warnings
	SUPER

	INCDIR	Includes:
	INCLUDE	lvo/dos.i
	INCLUDE lvo/exec.i
	INCLUDE	exec/types.i
	INCLUDE	graphics/gfxbase.i
	INCLUDE	hardware/custom.i
	INCLUDE	hardware/intbits.i

	INCLUDE	macros/ntypes.i
	INCLUDE	whdmacros.i

GL	EQUR	A4		;a4 ptr to Globals
LOC	EQUR	A5		;a5 for local vars

BUFLEN=100

	NSTRUCTURE	Globals,0
		NAPTR	gl_execbase
		NAPTR	gl_dosbase
		NAPTR	gl_gfxbase
		NLONG	gl_data
		NLONG	gl_vpos_s
		NLONG	gl_vpos_e
		NSTRUCT	gl_buf,BUFLEN
		NLABEL	gl_SIZEOF

;####################################################################

	SECTION	"",CODE,CHIP

		bra	_Start
		dc.b	"$Id: dbfcnt.asm 1.4 2014/06/10 01:20:06 wepl Exp wepl $",0
		EVEN

_Start		link	GL,#gl_SIZEOF			;a5 = global vars
		moveq	#20,d7				;d7 = rc
		moveq	#34,d0
		lea	(_dosname),a1
		move.l	(4),a6
		move.l	a6,(gl_execbase,GL)
		jsr	(_LVOOpenLibrary,a6)
		move.l	d0,(gl_dosbase,GL)
		beq	.quit
		
		lea	_gfxname,a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,(gl_gfxbase,GL)

		bsr	_main
		move.l	d0,d7

		move.l	(gl_dosbase,GL),a1
		move.l	(gl_execbase,GL),a6
		jsr	(_LVOCloseLibrary,a6)
.quit		unlk	GL
		move.l	d7,d0
		rts

;----------------------------------------

_main	lea	$dff000,a3

CNT	MACRO
	lea	_c\1n,a0
	bsr	_p
	bsr	_c\1i		;init
	lea	_c\1,a0
	bsr	_waitstrt
	tst.l	d7
	beq	.r\@
	lea	_ov,a0
	bra	.p\@
.r\@	bsr	_c\1o
	move.l	(gl_vpos_e,GL),-(a7)
	bclr	#7,(a7)
	move.l	(gl_vpos_s,GL),-(a7)
	bclr	#7,(a7)
	move.l	d1,-(a7)
	move.l	d1,-(a7)
	lsr.l	#3,d1
	move.l	d1,-(a7)
	move.l	d1,-(a7)
	lea	_res,a0		;format
	move.l	a7,a1		;argarray
	lea	(gl_buf,GL),a2
	move.l	#BUFLEN,d0
	bsr	_FormatString
	add.w	#24,a7
	lea	(gl_buf,GL),a0
.p\@	bsr	_p
	ENDM

	CNT	1
	CNT	1
	CNT	1
	CNT	2
	CNT	2
	CNT	2
	CNT	3
	CNT	3
	CNT	3
	CNT	4
	CNT	4
	CNT	4
	moveq	#0,d7
	rts

_waitstrt
	move.w	(intenar,a3),d5
	move.w	#INTF_BLIT|INTF_VERTB|INTF_COPER,(intena,a3)
	;move.w	#$7fff,(intena,a3)
	move.l	$6c,d6
	lea	.3,a1
	move.l	a1,$6c
.1	move.l	(vposr,a3),d1
	lsr.l	#8,d1
	cmp.w	#100,d1
	bls	.1
	lea	_cl,a1
	move.l	a1,(cop1lc,a3)
	move.w	#INTF_COPER,(intreq,a3)
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_COPER,(intena,a3)
	moveq	#0,d7		;overflow indicator
.2	move.l	(vposr,a3),d1
	lsr.l	#8,d1
	cmp.w	#100,d1
	bne	.2
	move.l	(vposr,a3),(gl_vpos_s,GL)
	jsr	(a0)
	move.w	#INTF_COPER,(intena,a3)
	move.l	d6,$6c
	or.w	#INTF_SETCLR,d5
	move.w	d5,(intena,a3)
	move.l	(gl_gfxbase,GL),a0
	move.l	(gb_copinit,a0),(cop1lc,a3)
.r	rts

.3	move.l	(vposr,a3),(gl_vpos_e,GL)
	move.w	#INTF_COPER,(intreq,a3)
	tst.w	(intreqr,a3)
	lea	.r,a1
	move.l	a1,(2,a7)
	rte

_cl	dc.b	109,1,255,254	;cwait
	dc.w	intreq,INTF_SETCLR|INTF_COPER
	dc.l	-2

_c1i	moveq	#0,d0
	subq.w	#1,d0
	rts
_c1	dbf	d0,_c1
	moveq	#-1,d7		;overflow
	rts
_c1o	move.l	#$ffff,d1
	sub.l	d0,d1
	rts

_c2i	clr.l	(gl_data,GL)
	rts
_c2	addq.l	#1,(gl_data,GL)
	cmpi.l	#$7fffffff,(gl_data,GL)
	ble.b	_c2
	moveq	#-1,d7		;overflow
	rts
_c2o	move.l	(gl_data,GL),d1
	rts

_c3i	moveq	#0,d0
	subq.w	#1,d0
	rts
_c3	nop
	dbf	d0,_c3
	moveq	#-1,d7		;overflow
	rts
_c3o	move.l	#$ffff,d1
	sub.l	d0,d1
	rts

_c4i	moveq	#0,d0
	rts
_c4	addq.l	#1,d0
	tst.l	d0
	bne.b	_c4
	moveq	#-1,d7		;overflow
	rts
_c4o	move.l	d0,d1
	rts

_p	move.l	a0,d2
	bsr	_StrLen
	move.l	d0,d3
	move.l	(gl_dosbase,GL),a6
	jsr	(_LVOOutput,a6)
	move.l	d0,d1
	move.l	d2,a0
	jmp	(_LVOWrite,a6)

;####################################################################

	INCDIR	Sources:
	INCLUDE	strings.i
		FormatString
		StrLen

;####################################################################

_c1n		dc.b	"empty dbf:    ",0
_c2n		dc.b	"c-style long: ",0
_c3n		dc.b	"nop dbf:      ",0
_c4n		dc.b	"long tst bne: ",0
_ov		dc.b	"overflow!",10,0
_res		dc.b	"1x=%2ld=$%2lx 8x=%3ld=$%3lx vhpos=%lx-%lx",10,0
_dosname	dc.b	"dos.library",0
_gfxname	dc.b	"graphics.library",0

;####################################################################

	END

