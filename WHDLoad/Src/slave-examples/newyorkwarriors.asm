;*---------------------------------------------------------------------------
;  :Program.	newyorkwarriors.asm
;  :Contents.	Slave for "New York Warriors" from Arcadia Systems
;  :Author.	Wepl
;  :Original	v1 sascha steinert
;		v2 chris vella
;  :Version.	$Id: newyorkwarriors.asm 1.7 2014/01/05 21:28:23 wepl Exp wepl $
;  :History.	30.08.01 started
;		09.09.01 support for v2 added
;		21.11.01 more bugs fixed
;		22.11.01 finished
;		04.10.09 new style kickemu
;			 decruncher moved to slave
;		13.10.09 finally located missing blitwait pre intermission.ani
;		05.01.14 fixed address error on 68000 (Don Adan)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"wart:n/newyorkwarriors/NewYorkWarriors.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

_allocmem = $124

;============================================================================
; free mem with chip=fast=$100000 iocache=1024:
;	v1	v2
; chip	$8c580	$7e168
; fast	$ebdf8	$80cc0

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
;FONTHEIGHT     = 8
HDINIT
;HRTMON
IOCACHE		= 1024
;MEMFREE	= $130
;NEEDFPU
;POINTERTICKS   = 1
;SETPATCH
;STACKSIZE	= 6000
;TRDCHANGEDISK

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $59	;F10

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"New York Warriors",0
slv_copy	dc.b	"1990 Arcadia Systems",0
slv_info	dc.b	"adapted and fixed by Wepl",10
		dc.b	"Version 1.3 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_main		dc.b	"z",0
_highs		dc.b	"highs",0
_disk1		dc.b	"NYW2",0		;for Assign
	EVEN

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required, this will never called if booted from a diskimage, only
; works in conjunction with the virtual filesystem of HDINIT
; this routine replaces the loading and executing of the startup-sequence

_bootdos	move.l	(_resload,pc),a2	;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		lea	(_dosbase,pc),a0
		move.l	d0,(a0)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	(_disk1,pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;check version
		lea	(_main,pc),a0
		move.l	a0,d1
		move.l	#MODE_OLDFILE,d2
		jsr	(_LVOOpen,a6)
		move.l	d0,d1
		beq	.program_err
		move.l	#300,d3
		sub.l	d3,a7
		move.l	a7,d2
		jsr	(_LVORead,a6)
		move.l	d3,d0
		move.l	a7,a0
		jsr	(resload_CRC16,a2)
		add.l	d3,a7

		lea	_plv1,a3
		cmp.w	#$c414,d0
		beq	.versionok
		lea	_plv2,a3
		cmp.w	#$d856,d0
		beq	.versionok
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)
.versionok

	;load exe
		lea	(_main,pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.program_err

	;patch
		move.l	a3,a0
		move.l	d7,a1
		jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;set flags for AllocMem
		move.l	(4),a0
		move.l	(_LVOAllocMem+2,a0),(_allocmem)
		pea	_allocfix
		move.l	(a7)+,(_LVOAllocMem+2,a0)

	;load highs
		lea	_highs,a0
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		beq	.nohighs
		lea	_highs,a0
		move.l	_hadr,a1
		jsr	(resload_LoadFileDecrunch,a2)
		bsr	_crypt
.nohighs
	;call
		move.l	d7,d1
		lsl.l	#2,d1
		move.l	d1,a3

		move.l	($2aa+4,a3),a4		;protection v1
		add.l	#$7ffe,a4		;protection v1

		sub.l	a0,a0			;cli argument string
		move.w	#0,d0			;start level? but does not work...

		jsr	(4,a3)

		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

.program_err	jsr	(_LVOIoErr,a6)
		pea	(_main,pc)
		move.l	d0,-(a7)
		pea	TDREASON_DOSREAD
		jmp	(resload_Abort,a2)

_plv1	PL_START
	PL_S	0,$2c2			;skip protection
	PL_I	$138			;invalid dos.Read
	PL_I	$164			;invalid dos.Read
	PL_S	$cae,$cc6-$cae		;cia accesses
	PL_PS	$11c6,_f4
	PL_PS	$169c,_f2
	PL_PS	$1e06,_f1v1
	PL_PS	$574a,_b2
	PL_PS	$5842,_b1
	PL_R	$6282			;insert disk 2
	PL_P	$6abe,_saveh
	PL_P	$8c82,decrunch_49d
	PL_GA	$af94,_hadr
	PL_END

_plv2	PL_START
	PL_S	$8,$20-$8		;always allocate MEMF_ANY
	PL_R	$efc			;cia access
	PL_PS	$143e,_f4
	PL_PS	$1976,_f2
	PL_PS	$210a,_f1v2
	PL_PS	$6180,_b2
	PL_PS	$63f8,_b1
	PL_R	$6e82			;insert disk 2
	PL_P	$76fc,_saveh
	PL_S	$8e2e,2			;dont reduce mem for instruments
	PL_P	$9870,decrunch_49d
	PL_GA	$bbd8,_hadr
	PL_END

	;game does not test return value correctly!
_allocfix	pea	.1
		move.l	(_allocmem),-(a7)
		rts
.1		tst.l	d0
		rts

	;blitter is still clearing the area where file 'intermission'
	;should be loaded
_f4		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
_bw		BLITWAIT
		rts

_f2		subq.w	#1,d0
.lp		move.w	(a1)+,(a0)+
		dbf	d0,.lp
		rts

_saveh		bsr	_crypt
		move.l	#$b00c-$af94,d0
		lea	_highs,a0
		move.l	_hadr,a1
		move.l	_resload,a2
		jsr	(resload_SaveFile,a2)
		bsr	_crypt
		movem.l	(a7)+,d2-d7/a2-a3/a5
		rts

_crypt		movem.l	d0/a1,-(a7)
		move.l	_hadr,a1
		move.l	#$b00c-$af94-1,d0
.lp		eor.b	d0,(a1)+
		dbf	d0,.lp
		movem.l	(a7)+,d0/a1
		rts

_b2		cmp.l	#$100000,(a0)
		bhs	.q
		move.l	(a0)+,(bltbpt,a3)
		cmp.l	#$100000,(a0)
		bhs	.q
		move.l	(a0)+,(bltcpt,a3)
		add.l	#2,(a7)
		rts
.q		jsr	(_LVODisownBlitter,a6)
		movem.l	(a7)+,d0/d2/d5-d6/a3-a6
		unlk	a5
		rts

_b1		bsr	_bw
		move.l	a1,(a5)
		move.l	d1,(a3)
		rts

_f1v1		cmp.l	#0,a5
		bne	.ok
.1		add.l	#$1e64-$1e06-6,(a7)
		rts
.ok		cmp.l	(-4,a5),a3
		bne	.1
		rts
_f1v2		cmp.l	#0,a5
		bne	.ok
.1		add.l	#$216c-$210a-6,(a7)
		rts
.ok		cmp.l	(-4,a5),a3
		bne	.1
		rts

;============================================================================

decrunch_49d
	movem.l	d2-d7/a1/a2,-(sp)
	addq.l	#2,a0
	moveq	#0,d2
	move.b	(1,a0),d2
	lsl.w	#8,d2
	move.b	(a0),d2
	addq.l	#2,a0
	moveq	#15,d3
	moveq	#7,d4
lbC008C98	move.b	(a0)+,d7
	subq.l	#1,d2
	moveq	#0,d6
lbC008C9E	btst	d6,d7
	beq.b	lbC008CB0
	move.b	(a0)+,(a1)+
	subq.l	#1,d2
	ble.b	lbC008CDE
lbC008CA8	addq.w	#1,d6
	cmp.w	d4,d6
	bls.b	lbC008C9E
	bra.b	lbC008C98

lbC008CB0	moveq	#0,d0
	moveq	#0,d1
	move.b	(a0)+,d1
	move.b	(a0)+,d0
	bne.b	lbC008CBE
	tst.b	d1
	beq.b	lbC008CDE
lbC008CBE	move.w	d0,d5
	and.w	#$F0,d0
	lsl.w	#4,d0
	clr.b	d0
	or.w	d0,d1
	neg.w	d1
	and.w	d3,d5
	addq.w	#2,d5
	lea	(a1,d1.w),a2
lbC008CD4	move.b	(a2)+,(a1)+
	dbra	d5,lbC008CD4
	subq.l	#2,d2
	bgt.b	lbC008CA8
lbC008CDE	move.l	a1,d1
	movem.l	(sp)+,d2-d7/a1/a2
	sub.l	a1,d1
	move.l	a1,d0
	rts

;============================================================================

_dosbase	dc.l	0
_hadr		dc.l	0

;============================================================================

	END
