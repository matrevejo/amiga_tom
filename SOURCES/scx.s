ASMONE	=1	;set to 0 to at least skip the PRINT* commands.

AGA	=1
lovol	=46
TriSize	=32
FINAL	=0	;remove org manually for final=0
MEASURE	=0	;rastertime
;ALWAYS AO regardless of mode!!!
endcheck	=0	;set to 0 last.
;endcheck verified not needed!

MONO	=0	;stealth mode to ward off curious bastards!!! I plan ahead. ;)
_ECHO	=0

	*********************************
	*				*
	*    sCooP3x    ///		*
	*     	       /// 	 	*
	*    	    \\X//   bLoCKb00t	*
	*    	     \X/		*
	*	     			*
	*	  by Photon/SCX		*
	*  (c) 2013 Henrik Erlandsson	*
	*				*
	*********************************

addr	=$68000

	INCDIR ""	;set AsmOne includes relative to current dir.
	JUMPPTR B
;	SECTION SCX,CODE_C			;@put in _p last to test
	ORG addr
	LOAD addr
;	INCLUDE "A:I/Symbols.S"	;@and also for polybuf not eating chipmem!
;---------------------symbols.s-----------------
;some entries added in gfxlib, add to Symbols-Documented as well.
_RW=1004
_Old=1005
_New=1006
_Any=0
_Public=1
_Chip=2
_Fast=4
_Clear=$10000
_Largest=$20000
_AccR=-2
_AccW=-1
ESuperVisor=-30
EException=-66
EFindResident=-96
EInitResident=-102
EDisable=-120
EEnable=-126
EForbid=-132
EPermit=-138
ESetSR=-144
ESuperState=-150
EUserState=-156
ESetIntVector=-162
EAddIntServer=-168
ERemIntServer=-174
ECauseInt=-180
EAlloc=-186
EDeAlloc=-192
EAllocMem=-198
EAllocAbs=-204
EFreeMem=-210
EAvailMem=-216
EAllocEntry=-222
EFreeEntry=-228
EAddTask=-282
ERemTask=-288
EFindTask=-294
ESetTaskPri=-300
EWait=-318
EAddPort=-354
ERemPort=-360
EPutMsg=-366
EGetMsg=-372
EReplyMsg=-378
EWaitPort=-384
EFindPort=-390
EOldOpen=-408
ECloseLib=-414
ESetFunction=-420
ESumLib=-426
EAddDev=-432
ERemDev=-438
EOpenDev=-444
ECloseDev=-450
EDoIO=-456
ESendIO=-462
ECheckIO=-462
EWaitIO=-462
EAbortIO=-462
ETypeOfMem=-534
EOpenLib=-552

DOpen=-30
DClose=-36
DRead=-42
DWrite=-48
DInput=-54
DOutput=-60
DSeek=-66
DDelete=-72
DRename=-78
DLock=-84
DUnlock=-90
DDupLock=-96
DExamine=-102
DExNext=-108
DInfo=-114
DCreateDir=-120
DCurrDir=-126
DIOerr=-132
DExit=-144
DLoadSeg=-150
DUnLoadSeg=-156
DGetPacket=-162
DQueuepacket=-168
DDevProc=-174
DSetComment=-180
DSetProtect=-186
DDateStamp=-192
DDelay=-198
DWaitChar=-204
DParentDir=-210
DExecute=-222

CRawKeyConv=-48

IOpenInt=-30
IAddGadget=-42
IClrMenuStr=-54
IClrPtr=-60
ICloseScr=-66
ICloseWW=-72
ICloseWB=-78
ICurrentTime=-84
IDisplayAlert=-90
IDisplayBeep=-96
IDoubleClick=-102
IDrawBorder=-108
IEndReq=-120
IInitReq=-138
IItemAddr=-144
IMoveScr=-162
IMoveWW=-168
IOffGadget=-174
IOffMenu=-180
IOnGadget=-186
IOnMenu=-192
IOpenScr=-198
IOpenWW=-204
IOpenWB=-210
IRefreshGadgets=-222
IRemoveGadgets=-228
IReq=-240
IScrToBack=-246
IScrToFront=-252
ISetMenuStr=-264
ISetPtr=-270
ISetWWTitles=-276
IShowTitle=-282
ISizeWW=-288
IViewAddr=-294
IVPAddr=-300
IWWToBack=-306
IWWToFront=-312
IWWLimits=-318
ISetPrefs=-324
IAutoReq=-348
IBeginRefresh=-354
IEndRefresh=-360
IMakeScr=-378
IReMakeDisplay=-384
IReThinkDisplay=-390
IAlohaWB=-402
GClrScr=-42
GText=-60
GSetFont=-66
GOpenFont=-72
GCloseFont=-78
GLoadRGB4=-192
GInitRport=-198
GInitVport=-204
GWaitBlit=-228
GSetRast=-234
GMove=-240
GDraw=-246
GAreaMove=-252
GAreaDraw=-258
GAreaEnd=-264
GWaitTOF=-270
GAreaInit=-282
GSetRGB4=-288
GBlitClr=-300
GRectFill=-306
GReadPxl=-318
GWritePxl=-324
GFlood=-330
GPolyDraw=-336
GSetAPen=-342
GSetBPen=-348
GSetDrawMode=-354
GVBeamPos=-384
GInitBitMap=-390
GOwnBlit=-456
GDisOwnBlit=-462
GInitTmpRas=-468
GAddFont=-480
GRemFont=-486
GAllocRaster=-492
GFreeRaster=-498
GAndRectRegion=-504
GOrRectRegion=-510

;---------------------symbols.s end -----------------

EQS	=0		;0 is also an option. a boring one.
ENDPATPATCH=1

songl	=32

;	INCLUDE "S1K-options.S"
;;    ---  1KLång options  ---
_offsbits	=10	;11=2K notes=huge in my format (loses 1 octave)
_vib		=0	;1=song has vibrato commands and you want to hear them
;;    ---  optimization flags  ---
_hifi		=0	;smoother interpolation of "envelopes" (inaudible?)
_bounds		=0	;bounds check of volslide up (0 is for pros only)
_dprd		=0	;0=vol only. 1=also allow modifying period (vib,porta)
;;    ---  instr flags  ---
_ipslide	=0	;period slide in instruments (set _dprd=1 to hear)
_isample	=0	;0=waves only else provide ptr,len.

instdeflen:	set 2
	IF _ipslide=1
instdeflen:	set instdeflen+2
	ENDC
	IF _isample=1
instdeflen:	set instdeflen+6
	ENDC

_baseC	=54229
_baseA	=64489



_octBase=_baseC		;_baseA to reach the full top octave

;compression ideas: coppercrunch,  move instruction firstword in copper as byte
;how flag it tho? could also be generic. any even # 0-$1fe.
;$2xxx/3xxx/4xxx overrepresented in code (move commands), also 6xxx (branches)

;;    ---  screen buffer dimensions  ---
K	=1024		;bet you knew
debuggerints	=$380
C	=2
DEBUG	=0
PAUSE	=0
;;    ---  screen  ---
bpls	=4
w	=352	;20	;384*2	;320
xtrah	=0			;increase to allow for boing
h	=xtrah+64+(256+16)	;enough to start above screen & travel 256 to floor.
bpl	=w/8
bwid	=bpls*bpl

********** MACROS **********
;;    ---  save bra.w's  ---
BRANIBL:MACRO
	JMP (A6)
	ENDM
********** BOOT INTRO START **********
Boot:	
	IF FINAL=1
	dc.l $444f5300,0,880		;the famous 12 bytes
	ENDC
B:
	lea $dff000+C,a6

INIT:
	IF FINAL=0
	move.l 4.w,a6		;execbase
	clr.l d0
	lea gfxname(PC),a1
	jsr -408(a6)		;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1),d4
	jsr -414(a6)		;closelibrary()

	lea $dff000+C,a6
	move.w $1c-C(A6),d5
	move.w 2-C(A6),d3
	move.w #$7fff-(debuggerints*DEBUG),$9a-C(A6)
	move.w #$7fff,$9c-C(A6)
	move.w #$7fff,$9c-C(A6)
	MOVEM.L D0-A6,-(SP)
	ELSE
;	move.w #$7fff,$9a-C(A6)		;@opti
	ENDC
INITE:

;;    ---  copy to chip  ---
	IF FINAL=1
CopyC:		;22b as predicted.
	lea CODE(PC),a0
	lea $7ffe.w,a1			;try $7ffe.w
	move.l a1,a2
;	move.w #(BootE-CODE)/2-1,d7
	move.w #511,d7
.l:	move.w (a0)+,(a1)+
	DBF d7,.l
	JMP (a2)
CopyCE:
	ENDC


CODE:
	lea R(PC),a5			;a single (PC) reference and no more
;do not put anything using BSS before this init and bss clear
;;    ---  init music, clr bss  ---
	lea S1K_Samples-R(A5),a1
	move.w #(BSSEND-BSSCLRSTART)/4-1,d0	;clr BSS before(!) and after S1K_Data
**********  **********
S1K_Init:	;a5=S1K_Data,a4=$dff002,a1=samples,d0=longs to clear-1
;this takes 16b, so even with a 16b wave, you lose 4b.
	move.l a1,a0
	moveq #0,d1

	moveq #TriSize-1,d7
.tril:
	move.b d1,(a1)+
	addq.b #4,d1
	DBF d7,.tril
;;    ---  start sounds  ---
	lea $a0-C(a6),a2

	moveq #4-1,d7
.chanl:
	move.l a0,(a2)+
	move.w #TriSize/2,(a2)+
	clr.l (a2)+			;prd+vol
	addq.w #6,a2
	DBF d7,.chanl
S1K_MinInit:			;this is the minimum init code
;	lea E-R(A5),a1
********** Clear Routine for use by anyone **********
CLRLONGS:	;d0.w=#longs-1,a1=dst
	clr.l (a1)+
	DBF d0,CLRLONGS

**********  **********

	subq.l #8,(A5)			;start songpos-1
	move.w #songl,_songlen-R(A5)
	move.w #$17,(a5)
	lea S1K_ChanData+_mvols+2-R(A5),a1
	move.w #14<<8,(a1)+		;chan0 set by code.
	move.l #62<<24+25<<8,(a1)+

********** [ FRAME LOOP ] **********
	lea Cop0-R(a5),a4
	move.l a4,$80-C(A6)		;MUST be directly after above wait.
FLOOP:
.pausel:
	move.w #$135,d0
	bsr WaitRaster
	move.w #$136,d0
	bsr WaitRaster
	lea scr-R(A5),a0
	lea $e0-C(A6),a1
	lea Pal-R(A5),a3		;@opti copysubroutine?

	moveq #8-1,d7
.bpll:	move.l (a3)+,$180-$e0(a1)
	move.l a0,(a1)+
	lea bpl(a0),a0
	DBF d7,.bpll

	move.w #$87c0,$96-C(A6)
;;    ---  check boing trigger  ---
	moveq #$29,d1
	lea ScrY-R(A5),a0
	subq.b #1,(a0)
	bpl.s .ok9
	clr.b (a0)
.ok9:
	add.b (a0),d1
	move.b d1,Diw0+2-R(A5)

	IF PAUSE=1
	IF FINAL=0
	btst #10,$16-C(A6)
	beq.s .pausel
	ENDC
	ENDC

.PlayIt:
;;    ---  music  ---
	lea $a6-C(A6),a4
	lea Song-R(A5),a1
	lea Song+songl-R(A5),a0
**********  **********
.S1K_Music:	;a5=R=S1K_Data,a4=$dff0a6,a0=Notes,a1=song
	MOVE.L A6,-(SP)
	move.l a5,a2
	MOVEM.W (A2)+,D1-D6		;tempo,songpos,songlen,0,tempoctr,stepctr

	addq.w #1,d5			;tempoctr
	cmp.w d1,d5			;tempo=0 on first call=trig
	blo.s .nostep1

	moveq #0,d5
;;    ---  next piece every 8 steps  ---
	moveq #lovol,d7
	moveq #7,d0
	and.w d6,d0
	bne.s .noboost
	moveq #64,d7
.noboost:
	move.b d7,S1K_ChanData+_mvols-R(A5)

	subq.w #3,d0
	bne.s .nonextp
	addq.b #1,PieceCtr-R(A5)
	addq.l #8,PieceAcc-R(A5)
.nonextp:
	subq.w #1,d6				;stepctr, 15..0
	bpl.s .nopos
;;    ---  inc tempo  ---
	cmp.w #$f,d1
	bgt.s .faster
	not.b Flag-R(A5)
	beq.s .nofaster
.faster:subq.w #2,d1				;increase tempo!
.nofaster:
	IF endcheck=1
	cmp.w #4,d1
	bge.s .ok
	moveq #4,d1
.ok:
	ENDC
;;    ---    ---
	moveq #$f,d6
	moveq #1,d0
	move.l d0,_noteoctrs(a2)		;reset 4 noteoffsctrs
	move.l d0,_noteoctrs+4(a2)
	addq.w #8,d2
	cmp.w d3,d2
	blt.s .nowrap
	moveq #0,d2
	subq.b #1,Wraps-R(A5)
	bpl.s .nodemoend
	subq.w #8,(a5)
	lea Insts-R(A5),a3
	clr.l (a3)+
	clr.l (a3)+
.nodemoend:

.nowrap:
.nopos:
.nostep1:
	MOVEM.W D1-D6,(A5)
	add.w d2,a1

;;========  fetch new notedata, set chandata  ========

	moveq #4-1,d7
.chanl1:

	moveq #64,d2			;default instscale (echo)
	lea _delays(a2),a3
	moveq #$f,d1

	move.w _noteoctrs(a2),d6	;d6=noteoffsctr
	cmp.b (a3),d5			;delay match? else don't read data
	bne.s .nxt

;;    ---  nibble loop  --- 		;repeat until note non-command
.nibl:
	lea .nibl-R(A5),a6
	bsr.s .GetNibble


********** Fy/FExy:special command+value **********

;;    ---  1-byte command  ---
.spec:
	blt.s .note
	bsr.s .GetNibble
	bgt.s .endpat
.setinst:				;$F0-FD=set instr 0-13
	move.w d3,_instdata(a2)
	BRANIBL

.GetNibble:	;d6=note offs ctr,a0=notes -> d3=nib;d6++
	move.w d6,d3
	asr.w #1,d3
	add.w (a1),d3			;pattoffs
	and.w #1<<_offsbits-1,d3
	move.b (a0,d3.w),d3

	btst d4,d6			;odd? then don't shift. d4=0.
	bne.s .nosh
	lsr.b #4,d3
.nosh:
	addq.w #1,d6			;and increase
	and.l d1,d3			;only .w should be ok
	cmp.b #$e,d3
	RTS

.endpat:
	subq.w #2,d6
	IF ENDPATPATCH=0
	bra.s .next2
	ENDC
.nxt:	bra.s .next			;read no more, puts d6 in noteoctr

.note:
	subq.b #1,d3			;note1..d=C to C=0..12
	bmi.s .next
	add.w (a3),d3			;@won't affect. only byte taken below.
	move.b (a1),d1			;transpose
	lsr.b #2+_offsbits-10,d1
	add.b d3,d1			;add note to transpose
	divu #12,d1
;;    ---  calc note prd  ---	;or use a table if you have 10 bytes to waste.
	move.w #_octBase,d0
	swap d1
	bra.s .jmpin
.octl2:
	mulu #61858,d0			;exponential: 1/(2^(1/12))*65536
	swap d0
.jmpin:	DBF d1,.octl2
	swap d1				;!hi word NOT clear. d1=octave

	addq.w #4,d1			;shift 4 more (prec)
	lsr.w d1,d0			;shift down by #octaves.
	move.w d0,_prds(a2)		;prd

.next2:					;"no note but read on"
	IF instdeflen=2
	move.w _instdata(a2),d0
	add.w d0,d0			;@time-opti ONLY
	ELSE
	moveq #instdeflen,d0
	mulu _instdata(a2),d0
	ENDC
	IF _ipslide=1
	move.l Insts-R(A5,d0.w),d0
	move.w d0,_dprds(a2)
	swap d0
	ELSE
	move.w Insts-R(A5,d0.w),d0
	ENDC
;;    ---  echo handling  ---
	IF _ECHO=1
	move.b d0,d3

	mulu d2,d0
	IF _hifi=1
	addq.l #8,d0			;kinda rounding, kinda.
	ENDC
	lsr.l #6,d0

	mulu d2,d3
	IF _hifi=1
	addq.l #8,d3			;kinda rounding, kinda.
	ENDC
	lsr.l #6,d3

	move.b d3,d0
	ENDC
	move.w d0,(a2)
.next:					;all roads -> Rome -> No roam.
	move.w d6,_noteoctrs(a2)
;;=======  read curr chandata, set soundregs  =======
;prd
;;    ---  [period]  ---
	IF _dprd=1
	move.w _prds(a2),d0
	lsl.w #4,d0			;shift by octave instead? (from lsr above)
	add.w _dprds(a2),d0
	lsr.w #4,d0
	move.w d0,_prds(a2)
	ELSE
	move.w _prds(a2),(a4)+
	ENDC
;;    ---  mastervol  ---
	move.w _mvols(a2),d0
	move.b (a2),d1			;vol 0-255
	mulu d0,d1			;scale vol
	swap d1
	IF EQS=1
	move.w d1,_eqs(a2)
	ENDC
	move.w d1,(a4)+
;;    ---  volslide AFTER  ---
	move.b (a2)+,d1			;vol 0-255
	sub.b (a2)+,d1			;neg volspeed (decay)
	bcc.s .nowr			;@also maxcheck? nah, sounds crap.
	clr.b d1
.nowr:
	move.b d1,-2(a2)		;"vol x4"
;;    ---  slide mastervol  ---
	add.w _mdvols-2(a2),d0
	bpl.s .non2
	clr.w d0
.non2:
	IF _bounds=1
	cmp.w #64<<8,d0			;@poss lsr.w #8,d2.
	ble.s .nomax
	move.w #64<<8,d0
.nomax:
	ENDC
	move.w d0,_mvols-2(a2)		;add volfade to mastervol

	lea 12(a4),a4			;next hardware chan
	addq.w #2,a1
	DBF d7,.chanl1
	move.w #$820f,$96-$e6(A4)
.S1K_Skip:
	MOVE.L (SP)+,A6
.S1K_MusicE:
**********  **********



********** [ effects ] **********
;;2
	lea PieceCtr-R(A5),a2
	moveq #0,d2
	move.w #16*$17,d2
	divu (a5),d2
;	ext.l d2
	moveq #$17*2+2,d3
	divu (a5),d3
	add.w d3,d2	
;	addq.w #2,d2
	mulu d2,d2		;256 and increasing
;	addq.w #2,(a2)+		;frame# * 2 opti nec?

	moveq #0,d4
	move.b (a2)+,d4
	cmp.b (a2)+,d4
	beq.s .nonewp
	move.b d4,-1(a2)
	move.l d2,(a2)+		;reset curve
	clr.l (a2)+
	clr.l (a2)
	subq.w #8,a2
.nonewp:

	cmp.b #TheBootE-TheBoot,d4	;this will be true when music ended
	bge.b .noacc
	tst.l (a2)
	beq.b .noacc

	add.l d2,(a2)		;acc
	move.l (a2)+,d2
	add.l d2,(a2)		;spd
	move.l (a2)+,d2
	add.l d2,(a2)		;pos
	move.w (a2),d2
	cmp.w LastPieceY-PieceY(a2),d2		;moved? else don't bother
	beq.s .noacc

.getpiece:
	moveq #0,d3
	move.b TheBoot-PieceY(a2,d4.w),d3
	moveq #$f,d0
	and.w d3,d0		;low x
	move.w d4,d1
	lsr.w #3,d4
	btst d1,TheBootBits-PieceY(a2,d4.w)
	beq.s .noadd
	bset #4,d0
.noadd:
	add.w d0,d0
	lsr.b #4,d3		;piece#
	add.w d3,d3

.tryagain:
	moveq #$3f,d1
	add.w (a2),d1
	cmp.w #256+$3f,d1
	bgt.s .coll

	mulu #bwid,d1
	add.w d0,d1
	lea Buff0+2-R(A5),a0		;+2=center.
	add.l d1,a0			;dest lea Buff0-R(a5,d1.l),a0		;dst

	moveq #-1,d6			;don't draw, just check

	bsr.b DrawPiece			;test-draw (just check)

	beq.s .nocoll
.coll:
	moveq #-$10,d2
	and.w (a2),d2
	cmp.w (a2),d2			;prohibit infinite loop
	beq.s .nocoll			;done
	move.w d2,(a2)
	clr.l -8(a2)			;flag no more dropping
;;    ---  trig boing  ---
	addq.b #8,ScrY-R(A5)
	bra.s .tryagain			;once more (to save recalc only)
	
.nocoll:
	moveq #0,d6			;draw (and check)

	bsr.b DrawPiece

	IF MEASURE=1
	clr.w $180-C(A6)		;@opti weg
	tst.b 5-C(A6)
	bne.s .nomax
	move.b $6-C(A6),d0
	cmp.b Max-R(A5),d0
	blo.s .nomax
	move.b d0,Max-R(A5)
.nomax:
	ENDC
	move.w (a2),LastPieceY-PieceY(a2)		;last y!
.noacc:
********** [ effects end ] **********


	IF FINAL=0
	BRA.W EXIT			;for det ar det ju
	ELSE
	bra.w FLOOP
	ENDC
FLOOPE:
********** [ FRAME LOOP END ] **********
Max:	dc.w 0
********** ROUTINES **********

;;1
DrawPiece:	;d2-d3,d6,a0=revcol,Piece# *2,drawmode (0 to draw!),dst
	MOVEM.L D0-D6/A0-A6,-(SP)
	moveq #0,d7		;or-result of precheck
	move.w Pieces(PC,d3.w),d3
	move.w d3,d2
	and.w #$fff8,d3
	sub.w d3,d2
	lsl.b #4,d2
.xl:
	moveq #4-1,d5		;4x4 grid from bottom LEFT RIGHTward.
	bset #31,d5		;zero flag - only check bottommost 1-bit.
.yl:
	add.w d3,d3
	bcc.s .yskip		;skip 0 bits in grid

	move.l a0,a1		;@opti fux up if removed but should be poss
;@check if earlyexit poss, move these 3 lines below.
	bclr #31,d5
	beq.s .noor
;	or.w (a1),d7
;	or.w bpl(a1),d7	
;	or.w bpl*2(a1),d7	;3bpls is enough, rest is just hilight.
	or.w bwid*4+bpl*3(a1),d7
.noor:
	tst.w d6		;@opti, maybe not poss.
	bne.s .yskip

;DrawTile:	;drawmode, 0 to draw (-1)
	not.w d6
	move.b d2,d4
	bsr.s DrawBlock
	not.w d6		
	moveq #0,d4
	bsr.s DrawBlock

.yskip:	lea -bwid*16(a0),a0	;up
	DBF d5,.yl
	lea bwid*16*4+2(a0),a0	;@RIGHTward
	tst.w d3
	bne.s .xl
	MOVEM.L (SP)+,D0-D6/A0-A6
	tst.w d7
	RTS

DrawBlock:
	lea BplWords+6-R(A5),a4
	moveq #3-1,d1
.bpll:	add.b d4,d4
	smi d0
	ext.w d0
	move.w d0,-(a4)
	dbf d1,.bpll

	moveq #16-1,d1
.linl:
	move.w d6,bwid*4+bpl*3(a1)
	move.w (a4)+,bpl*2(a1)
	move.w (a4)+,bpl(a1)
	move.w (a4)+,(a1)
	subq.w #6,a4
	lea -bwid(a1),a1
	DBF d1,.linl
	RTS

********** DATA **********
;;3
CODEE:

y	=16	;shift.
r1	=%100
r2	=%010
r3	=%110
r4	=%001
r5	=%101
r6	=%011
r7	=%111
r9	=%1000+r1
f	=16

Pieces:	;4x4 grid, y0y1y2y3 for rightmost column, and so on. from BR corner up.
	dc.w %100010001000*f+r9	;I	0 (special: 4th column needed.
	dc.w %100011100000*f+r2	;j	1
	dc.w %111010000000*f+r3	;l	2
	dc.w %110011000000*f+r4	;o	3
	dc.w %100011000100*f+r5	;s	4
	dc.w %010011000100*f+r6	;t	5
	dc.w %010011001000*f+r7	;z	6
	dc.w %110010001000*f+r2	;j4	8

	dc.w %100010001100*f+r3	;l4	7
	dc.w %111000100000*f+r2	;J	9
	dc.w %001011100000*f+r3	;L	a
	dc.w %011011000000*f+r5	;S	b
	dc.w %100011001000*f+r6	;T	c
	dc.w %010001001100*f+r2	;j3	e
	dc.w %110001000100*f+r3	;l3	f

********** exit moved to here **********

	IF FINAL=0
EXIT:
FLOOP2:
	btst #6,$bfe001
	bne.w FLOOP
EXIT3:
	MOVEM.L (SP)+,D0-A6
	move.w #$7fff,$96-C(A6)
	or.w #$8200,d3
	move.w d3,$96-C(A6)
	move.l d4,$80-C(A6)
	or #$c000,d5
	move d5,$9a-C(A6)
	moveq #0,d0
	RTS

gfxname:	dc.b "graphics.library",0
	EVEN
DBUG:	blk.l 16,0
EXITE:
	ENDC

**********  **********

Pal:
	IF MONO=1
	dc.w $eee
	blk.w 7,$fff
	dc.w $ccc
	blk.w 7,$eee
	ELSE
	dc.w $656,$fbb,$ddf,$fcb
	dc.w $feb,$dfd,$fde,$dff
	dc.w $545,$a33,$46a,$c64
	dc.w $ca4,$484,$a58,$699
	ENDC

WaitRaster:		;wait for rasterline d0.w. Modifies d0-d2/a0.
	MOVEM.L D0-A6,-(SP)
	move.l #$1ff00,d2
	lsl.l #8,d0
	and.l d2,d0
	lea $dff004,a0
.wr:	move.l (a0),d1
	and.l d2,d1
	cmp.l d1,d0
	bne.s .wr
	MOVEM.L (SP)+,D0-A6
	rts

Cop0:
	IF AGA=1
	dc.w $1fc,0
	ENDC
	dc.w $096,$0020
	dc.w $9a,$7fff
	dc.w $092,$30
	dc.w $094,$d8
	IF AGA=1
	dc.w $102,$00		;shift
	ENDC
;	dc.w $104,36		;sprite & playfield pri
	dc.w $108,BWid-bpl
	dc.w $10a,BWid-bpl
Diw0:
	dc.w $08e,$2971
	dc.w $090,$33d1
Pal0:

;Bpl0:
;	dc.w $0e0,(scr+bpl*0)>>16
;	dc.w $0e2,(scr+bpl*0)&$ffff
;	dc.w $0e4,(scr+bpl*1)>>16
;	dc.w $0e6,(scr+bpl*1)&$ffff
;	dc.w $0e8,(scr+bpl*2)>>16
;	dc.w $0ea,(scr+bpl*2)&$ffff
;	dc.w $0ec,(scr+bpl*3)>>16
;	dc.w $0ee,(scr+bpl*3)&$ffff
Ena0:
	dc.w $100,Bpls*$1000+$200
	dc.w $ffdf,$fffe
	dc.l -2
Cop0E:

;;6
;	INCLUDE "S1K-Player.S"

;;7    ---  songdata  ---

Song:
.o1	=12*K*1
.o2	=12*K*2
  dc.w .o1+16*K+.p0s0c0-.n,.o2+16*K+.p0s0c3i-.n,12*K-.o1+.p0s0c2i-.n,.o1+16*K+.p0s0c3i-.n
  dc.w .o1+16*K+.p0s1c0-.n,.o2+16*K+.p0s1c3i-.n,16*K-.o1+.p0s1c2-.n,.o1+16*K+.p0s1c3i-.n
  dc.w .o1+24*K+.p0s2c0-.n,.o2+24*K+.p0s2c3i-.n,24*K-.o1+.p0s2c2-.n,.o1+24*K+.p0s2c3i-.n
  dc.w .o1+16*K+.p0s1c0-.n,.o2+16*K+.p0s1c3i-.n,21*K-.o1+.p0s3c2-.n,.o1+16*K+.p0s1c3i-.n

.Notes:
.n:
.p0s0c3i:
	dc.b 0,$F3	;,$FE,$90,$00	;1 note chan delay
.p0s0c0:
  dc.b $d0,$89,$b0,$98,$60,$69,$d0,$b9
.p0s0c2i:
	dc.b $F1
.p0s0c2:
  dc.b $90,$50,$90,$50,$a0,$50,$a0,$50
;;    ---    ---
.p0s1c3i:
	dc.b 0	;;dc.b $FE,$90,$00
.p0s1c0:
  dc.b $80,$89,$b0,$d0,$90,$60,$60,$FF
;;    ---    ---
.p0s2c3i:
	dc.b 0	;dc.b $FE,$90,$00
.p0s2c0:
  dc.b $30,$36,$a0,$86,$50,$10,$50,$31
.p0s2c2:
  dc.b $60,$30,$60,$30	;continues
.p0s1c2:
  dc.b $50,$10,$50,$10,$F2,$60,$60,$F1,$68,$9D
;;    ---    ---
.p0s3c2:
  dc.b $F2,$64,$31,$34,$68,$F1,$d0,$10,$10,$FF
SongE:
NotesSize=SongE-Song-songl

	EVEN
TheBoot:
	dc.b s1+10,l3+8,t1+5,s2+3,z1+0,j3+0,i2+4,i2+8,i2+14,j1+18-16
	dc.b j3+12,o1+15,o1+17-16
	dc.b j2+0,l1+18-16,z1+11,t2+9,s2+11,t2+1,i2+6,i2+3
	dc.b j2+18-16,o1+18-16,o1+11,z1+10,o1+10,j1+18-16,l4+17-16,j4+10,z1+12
	dc.b s1+15	;la pjÄs de la resistance
TheBootE:	;31b
TheBootBits:
	dc.b %00000000
	dc.b %01010010
	dc.b %01100000
	dc.b %00001100

Wraps:	dc.b 3
	EVEN
Insts:
	dc.b 255,17	;inst 1 vol,volfade
	dc.b 255,10	;long bass
	dc.b 255,15	;short bass
	dc.b 255,22	;short bright
SongE2:
BootE:
nx	=1		;to swap nibbles, just swap factors.
np	=16


x0	=0*nx
x1	=1*nx
x3	=2*nx
x4	=3*nx
x5	=4*nx
x6	=5*nx
x8	=6*nx
x9	=7*nx
x10	=8*nx
x11	=9*nx
x12	=10*nx
x14	=11*nx
x15	=12*nx
x17	=13*nx
x18	=14*nx

i2	=0*np
j1	=1*np
l1	=2*np
o1	=3*np
s1	=4*np
t1	=5*np
z1	=6*np
j4	=7*np

l4	=8*np
j2	=9*np
l2	=$a*np
s2	=$b*np
t2	=$c*np
j3	=$d*np
l3	=$e*np

	EVEN

*------------------ END OF DATA ------*
BSSCLRSTART:

S1K_Samples:	ds.l TriSize/4		;@moved to before rest of bssclear.

LastPieceY:	ds.w 1		;only the integer part
;Frame:		ds.w 1
PieceCtr:	ds.b 1
OldPieceCtr:	ds.b 1
PieceAcc:	ds.l 1		;-1	;$2000	;make BSS
PieceSpeed:	ds.l 1
PieceY:		ds.l 1
ScrDY:		ds.b 1
ScrY:		ds.b 1
BplWords:	ds.w 3
Flag:		ds.b 1
;space for 1 byte
;;    ---  player BSS/DS  ---
	EVEN
E:
R:
S1K_Data:
_Tempo:		ds.w 1
_SongPos:	ds.w 1		;*8, will be incd to 0 on first call
_SongLen:	ds.w 1		;*8
_Zero:		ds.w 1		;must be 0 (save 2 bytes btst d4,d6)
_TempoCtr:	ds.w 1		;trig on first call (can also be=tempo)
_StepCtr:	ds.w 1		;15-0

S1K_ChanData:
_vols=0
		ds.w 4			;vol,volfade .b
_prds=8
		ds.w 4			;currprds
_dprds=16
		ds.w 4			;deltaprds (also do maxs and mins)
_noteoctrs=24
		ds.w 4			;noteoffsetctrs (NOT patternstepctr)
_mvols=32
		ds.w 4			;mastervols 0-64<<8
_mdvols=40
		ds.w 4			;mastervolfades -64/
_instdata=48
		ds.w 4			;curr instoffs/6 (option: banked)
_volroofs=56
		ds.w 4			;64 hardcoded right now. so sue me.
_vibwids=64
		ds.w 4			;vibrato widths
_vibspds=78
		ds.w 4			;vibrato speeds
_delays=80
		ds.w 4			;delays, transposeadd .b
	IF EQS=1
_eqs=88
		ds.w 4			;vol 0-64 out to Paula
	ENDC
	
	CNOP 0,4
S1K_DataE:
********** S1K DATA END **********
;put your own BSS data to clear here. Remember it's only pseudo-BSS to save
;space in abs-org'ed demos, if you WO the memory won't be alloc'd.
	ds.l bwid*16	;drawtrash margin
Buff0:		;screen
scr	=Buff0+bwid*64
	ds.l bwid*h/4
	ds.l bwid*16	;boing margin
BSSEND:

;Patterns are played for 16 notesteps. 
;Songdata consists of words pointing to "some notebytes" + transposevalue (to put it in the right octave).
;A note in Notedata is 1 nibble (hex char), so 16 nibbles + any effectnibbles is read. 
;Effectnibbles come before the notestep they apply to.
;So notedata for a patt can be 8 bytes or many bytes long depending on the number of effects. Or just 1 byte, $FF, if it's empty.
;Setting tempo must be done in chan0.
 
* Ex	set mastervolume of this notestep's instr trigger only (should clear volslides?)
* F0..D	set instr. (can have 2 banks if run out: bank0=chan0-1,bank1=chan2-3)
* FE0..7y	vibrato ampl 1/8..8/8 of 2 semitones, y=speed 0..15 frames (0=off)
; (y=calced (ampl+1)*1/8 note) possibly reset next trig?
* FE8y	transpose, 7=transpose nothing, 8=transpose up 1 semitone etc.
* FE9y	jump backward y BYTES (counted from right after these 2 bytes) **
* FEAy	jump forward y BYTES (counted from right after these 2 bytes) **
* FEBy	channel delay in frames. Must be < tempo. $f=some toggle ($e available for expansion)
* FECy	mastervol (should clear volslides?)
* FEDy	mastervolslide down (x1/tempo (of 128) per frame) tempo6=1/12 of 64 steps
* FEEy	mastervolslide up
* FEFy	set tempo (takes effect & sets delays for 4 chans next step)
* FF	end patt.**

** = optimization commands.

********** BOOT INTRO END, BSS **********
	IF ASMONE=1
	IF2
	IF FINAL=0
	PRINTT "MAIN CODE"
	PRINTV CodeE-Code-(PAUSE*8)
	PRINTT "PLAYER CODE"
;	PRINTV S1K_MusicE-S1K_Init
	PRINTT "COP"
	PRINTV Cop0E-Cop0
	PRINTT "Song"
	PRINTV SongE2-Song-1	;1 byte used
	PRINTT "TOTAL"
	PRINTV (BootE-Boot)-(InitE-Init)-(ExitE-Exit)-(PAUSE*8)+14
	ELSE
	PRINTV (BootE-Boot)
	ENDC
	ENDC

	ENDC

	END
********** END OF CODE **********