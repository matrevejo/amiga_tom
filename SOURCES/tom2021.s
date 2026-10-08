; Tom the Sprite
; version alfa 1.1
; Written by Colpasus 1990-2017
; Principal Programmer Colpasus
; Junior Programmer SuperIvanSpain
; Assistant Tester Carla (MegaStation64)
;
; Added stage control.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; v1.2 06/09/2017
; Including Demo Presentation
; v1.60 08/09/2017
; Including reverse scroll movement
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; v1.65 Including text
; Ok finished
; 11/09/2017
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; v2.0 Including popcorn music
; Ok finished
; 13/08/2019
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; v1.65 Including text
; Ok finished
; 11/09/2017
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	INCLUDE	"hardware/cia.i"
	INCLUDE	"hardware/custom.i"
	INCLUDE	"hardware/dmabits.i"
	INCLUDE	"hardware/intbits.i"
	INCLUDE "p6109.i"

	
	SECTION mydemo,CODE_C
	
	

PUSH_ALL MACRO
	movem.l d0-d7/a0-a6,-(sp)
	ENDM
		
POP_ALL MACRO
	movem.l (sp)+,d0-d7/a0-a6
	ENDM

	
DEBUG=0
DUST=1
COLLISIONSPRITE=1

w	=320
h	=256
bplsize	=w*h/8
os	=4  ; Offset of blocks

;$dff098	_CLXCON	Write Sprite collision control bits
;$dff00e	_CLXDAT	Poll (read and clear) sprite collision state

;Mode 0 (Normal game)
;Mode 1 (Superjump game)
;Mode 2 (Flying game)


_custom		equ	$dff000
_ciaa		equ	$bfe001

_CLXCON         equ    $dff098
_CLXDAT         equ     $dff00e
_BPLCON0	    equ     $dff100
_BPLCON1	    equ     $dff102
_BPLCON2	    equ     $dff104

TomPosInit      equ     $6c607c80
TomPosYInit		equ		$006c


PictureW	=640
PictureH	=256
PictureBpl	=PictureW/8		;80 Bytes per line
WindowW		=320
WindowH		=256
BitPlanes	=3
PictureBWid	=PictureBpl*BitPlanes	;80X3=240 bytes per 3 bit planes
ModW		=PictureBWid-(PictureBpl/2)		;Module is 200

PictureMargin	=(640-PictureW)/2

tomX		=100
tomY		=50
TomSize		=72*2 ; 2 times 1 sprite

FinalStagePosition			equ	700
FinalStageMessagePosition	equ	736

;ControlDebug
;FinalStagePosition			equ	20
;FinalStageMessagePosition	equ	56	


StartBlinding				equ	625
FirstCharacter				equ 32
NumLives					equ 20

KEYCODE_SPACE	= $40
KEYCODE_ESC	= $45
KEYCODE_CURSORDOWN	= $4D
KEYCODE_CURSORUP	= $4C
KEYCODE_CURSORRIGHT	= $4E
KEYCODE_CURSORLEFT	= $4F




;-----------------------------------------------------------------------------
;	RSRESET
screen:		rs.l	1
copper:		rs.l	1
oldStack:	rs.l	1
oldView:	rs.l	1
oldIntena:	rs.w	1
oldDma:		rs.w	1
gfxBase:	rs.l	1
vbrBase:	rs.l	1
oldIntPorts:	rs.l	1
keys:		rs.b	$80
dt_SIZEOF:	rs.b	0
;-----------------------------------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init:
	
	jsr DoVariables
	
	
	
	move.l 4.w,a6		;execbase
	clr.l d0
	move.l #gfxname,a1
	jsr -408(a6)		;oldopenlibrary()
	move.l d0,a1
	move.l 38(a1),d4	;original copper ptr

	jsr -414(a6)		;closelibrary()

	move.w #$ac,d7		;start y position
	moveq #1,d6		;y add
	move.w $dff01c,d5
	move.w $dff002,d3
	
	movem.l d0-d7/a0-a6,-(sp)

	move.w #$138,d0		;wait for EOFrame
	bsr.w WaitRaster


**********************************************************************
	ifeq DEBUG
		move.w #$7fff,$dff09a	;disable all bits in INTENT
		move.w #$7fff,$dff09c	;disable all bits in INTRE
		move.w #$7fff,$dff09c	;disable all bits in INTREQ;	
		move.w #$7fff,$dff096	;disable all bits in DMACON
		move.w #$87e0,$dff096
	endc
**********************************************************************

;Fixing glitch, only first time ever.
	move.w #%0000000101000101,_CLXCON	
	



**********************************************************************
	ifeq DEBUG
*****************************************************************
;Activate copper	
		move.l #MyCopper,$dff080


;;    ---  Call P61_Init  ---
	lea Module1,a0
	sub.l a1,a1
	sub.l a2,a2
	moveq #0,d0
;	lea p61coppoke+3,a4		;only used in P61mode >=3
	jsr P61_Init

;	lea	$dff000,a6	
;	move.l	#p61copper,$80(a6)	

;	move	#$7f3,$180(a6)
	jsr P61_Music			;and call the playroutine manually.
;	move	#$003,$180(a6)


	endc
	
	jsr InitGame
	jsr ResetLevel
	jsr InitEngine	

	lea dt,a6	

;backup ints pointers (PORTS)
	move.l	vbrBase(a6),a0
	move.l	$68(a0),oldIntPorts(a6)	
	
	
	ifeq DEBUG
	
	jsr MyInit 
	
	endc

	jsr main
	
;<-----------------------------------
	lea dt,a6

;restore ints pointers (PORTS)
	move.l	vbrBase(a6),a0
	move.l	oldIntPorts(a6),$68(a0)


;<-----------------------------------
	
	
	jsr P61_End	
	
	
	movem.l (sp)+,d0-d7/a0-a6

	move.w #$7fff,$dff096
	or.w #$8200,d3
	move.w d3,$dff096
	move.l d4,$dff080
	or #$c000,d5
	move d5,$dff09a
	
	move.l	dt+oldStack(pc),a7	;restore old stack	

	
	rts
	
;-----------------------------------------------------------------------------
;
;in
;	a5 - custom
;
StopDmaAndIntsAtVBlank:
		bsr.w WaitRaster
		lea _custom,a5
		move.w	#$7fff,d0
		move.w	d0,dmacon(a5)	;dma off
		move.w	d0,intena(a5)	;disable ints
		move.w	d0,intreq(a5)	;clear pending ints
		rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	

;-----------------------------------------------------------------------------
; in
;a5 - custom
; out
;a6 - dt variables
;
MyInit:
	;set up PORTS int
		lea dt,a6
		lea _custom,a5
		lea	IntLvlTwoPorts(pc),a0
		move.l	vbrBase(a6),a1
		move.l	a0,$68(a1) 

	;allow ports interrupt
		move.w	#INTF_SETCLR!INTF_INTEN!INTF_PORTS,intena(a5)


		rts

IntLvlTwoPorts:
		movem.l	d0-d1/a0-a2,-(a7)

		lea	_custom,a0
		moveq	#INTF_PORTS,d0

	;check if is it level 2 interrupt
		move.w	intreqr(a0),d1
		and.w	d0,d1
		beq.b	.end

	;check if SP cause interrupt, hopefully CIAICRF_SP = 8
		lea	_ciaa,a1 
		move.b	ciaicr(a1),d1
		and.b	d0,d1
		beq.b	.end

		move.b	ciasdr(a1),d1			;get keycode
		or.b	#CIACRAF_SPMODE,ciacra(a1)	;start SP handshaking

		lea	dt+keys(pc),a2
		not.b	d1
		lsr.b	#1,d1
		scc	(a2,d1.w)

	;handshake
		moveq	#3-1,d1
.wait1		move.b	vhposr(a0),d0
.wait2		cmp.b	vhposr(a0),d0
		beq.b	.wait2
		dbf	d1,.wait1

	;set input mode
		and.b	#~(CIACRAF_SPMODE),ciacra(a1)

.end		move.w	#INTF_PORTS,intreq(a0)
		tst.w	intreqr(a0)
		movem.l	(a7)+,d0-d1/a0-a2
		rte

	
*************************************************************************************************************	
*************************************************************************************************************
*************************************************************************************************************
*****                                                                                                   *****
*****                                                                                                   *****
*****                                        INITIAL LOOP                                               *****
*****                                                                                                   *****
*****                                                                                                   *****
*************************************************************************************************************
*************************************************************************************************************
*************************************************************************************************************

;;;;;;;;;;;;;;;;;;;;;	move.w #0,IntroPos


main:

	move.b #1,Intro

.mainloop


	jsr FrameWait



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Just for bugs debuging;;;;;;;;
	move.w ControlCounter,d0
	cmp.w #8000,d0
	bgt exit
	add #1,ControlCounter
;;;;;;;;;;;;;;;End;;;;;;;;;;;


; Intro subroutine
	cmp.b #1,Intro
	bne .NoIntro
	
	jsr IntroSubroutine
	
.NoIntro


	cmp.w #StartBlinding,StageWindowPointer
	blt .NoBlinding
	add.b #1,Bitplane1_pallete+19 ; COLOR 3
	add.b #1,Bitplane1_pallete+15
.NoBlinding



	move.b v_DeathInProgress,d0
	cmp.b #1,d0
	
	bne .NoDeathInProgress
	bsr DeathInProgressRoutine
	jmp .Sigue02
	
.NoDeathInProgress
	bsr KeyControl	

	
; EndStage CONTROL
	move.b vEndReached,d0
	cmp.b #1,d0
	bne.w .NoEndReached
**********************************************************************************************************************************
; If here, process End Reached animation	
;	move.b #1,vEXIT
	jmp .AvoidParallaxFinalStage
**********************************************************************************************************************************
.NoEndReached	

	bsr Parallax
	


	

	
.AvoidParallaxFinalStage

	move.w StageWindowPointer,d0
;Check final of stage
	cmp.w #15+FinalStagePosition,d0;  Flag position, 15+FlagPosition
	blt .NoFinalStage
;;;; OK	move.b #1,vEXIT
	move.b #1,vEndReached

	
	add.b #3,TomPos_old+1	
	add.b #3,TomPos+1

	
; Endreached END ANIMATION AND NEW STAGE


	move.b TomPos+1,d0
	cmpi.b #175,d0
	bls .NoEndAnimation

;Slowly viewing the final stage message

	move.b #175,TomPos+1
	move.b #175,TomPos_old+1
	move.b #2,PowerSpeed2
	bsr Parallax

	move.w StageWindowPointer,d0
;Check final of stage
	cmp.w #15+FinalStageMessagePosition,d0;  Flag position, 15+FlagPosition
	blt .NoEndAnimation

	bsr Wait_seconds
	; Forward 1 to stage ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	add.l #4,current_stage
	add.b #1,my_stage

	
	move.b #4,PowerSpeed2
	jsr RestartAll
	
	jmp .Sigue02
	
.NoEndAnimation
	
.NoFinalStage	

	
	cmp.w #15,d0
;	cmp.w #515,d0
	bgt .NoStarting
	
	move.b #8,PowerSpeed2
	move.w _CLXDAT,d0 ; Avoid false collisions <--- ??? 
	
	jmp .Sigue01
.NoStarting

	bsr CollisionDetectionControl
	
	move.b v_DeathInProgress,d0
	cmp.b #1,d0
	beq .Sigue02	
	
	
	bsr GravityControl
	move.b #4,PowerSpeed2


	
.Sigue01
	bsr WritePosition
	bsr BreathControl
	bsr DustControl
	bsr MoveSprite

.Sigue02	

	btst #6,$bfe001
	bne.w .siguexxx 
	move.b #1,vExit
.siguexxx	

	move.b vEXIT,d0
	cmp.b #1,d0
	bne.w .mainloop
**************************
exit:


	rts

******************************************************************************************************************************************************************
******************************************************************************************************************************************************************
******************************************************************************************************************************************************************
******************************************************************************************************************************************************************



Wait_seconds:

	move.l #$ffff,d0
.loop_principal
	move.l #7,d1
	
.loop_raster
	sub.l #1,d1
	cmp.l #0,d1
	bne .loop_raster

	sub.l #1,d0
	cmp.l #0,d0
	bne .loop_principal

   rts

***********************************************************************
Wait_breathing:
***********************************************************************



	move.w #70,d0
.loop_wait_b

	jsr IntroKeyControl
	cmp.b #0,IntroKeyPressed
	bne.b .AbortLoop

	PUSH_ALL
	jsr FrameWait
	jsr Parallax	
	bsr WritePosition
	bsr BreathControl
	bsr MoveSprite
	POP_ALL
	
	sub.w #1,d0
	cmp.w #0,d0
	bne.b .loop_wait_b

.AbortLoop
	rts
   
   
   
RestartAll:

	bsr ResetLevel		
	bsr MoveSprite	
	bsr BreathControl	
	bsr DustControl	
	jsr InitEngine	


	rts


********** ROUTINES **********

WaitRaster:		;wait for rasterline d0.w. Modifies d0-d2/a0.
	move.l #$1ff00,d2
	lsl.l #8,d0
	and.l d2,d0
	lea $dff004,a0
.wr:	move.l (a0),d1
	and.l d2,d1
	cmp.l d1,d0
	bne.s .wr
	RTS


BlitWait:
	tst DMACONR(a6)
.waitblit:
	btst #6,DMACONR(a6)
	bne.s .waitblit
	rts


WritePattern:
	rts

	
WriteMap:

;	Erase column before write blocks

	move.w #13,d2

.loop_erase
	
	move.l  #(16*80*3),d1
	mulu    d2,d1
	
	add.w #2,d1
	add.w Scroll2,d1
	move.l d1,Offset
	bsr WriteBlack	   ; Erase!!!!
	
	add.l #40,Offset
	bsr WriteBlack	   ; Erase!!!!
	
	sub.w #1,d2
	cmp #1,d2
	bgt .loop_erase
	
;	End erase

;Write a column of blocks in a static position ;Assume you write at least one block.
.loopwb

	move.w StageMemoryPointer,d1   ; Offset position to pointer	


	lea stage1_address,a1
	add.l	current_stage,a1
	move.l (a1),d0
	
	move.l d0,a0
	
	
	add d1,a0                      ; Add offset to a0	
	move.l (a0),d0                   ; Get current map pointer into d0

	move.w StageWindowPointer,d1   ; Get current window position into d1
	                               ;d0= position(1w)|blocktype(1b)|row(1b)
	swap d0                        ;d0= blocktype(1b)|row(1b)|position(1w)
	cmp.w d1,d0                      


	
	
	bne .GoOut
	                     ; If not equal, out of the loop. End of column.

;If here, Write a block in the current column


	add.w #4,StageMemoryPointer    ;sum 4 positions (4 words) to StageMemoryPointer


	jsr Sub_WriteBlock
	
	jmp .loopwb

.GoOut
	add.w #1,StageWindowPointer    ;sum 1 to StageWindowPointer always. Assume  write at least one block (next time)
	
;End of program at 40/4 writes

	clr.l d1
	move.w StageWindowPointer,d1   ; Offset position to pointer	
	cmp.w #8000,d1
	bgt EndLoop
	
	rts

EndLoop:
	

	move #0,StageWindowPointer
	move #0,StageMemoryPointer
	
	rts
	


;;;;;;;;;;;;;;;;;SUBROUTINE TO WRITE A BLOCK;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;d0 column number
;d2 row and block type
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sub_WriteBlock:

	swap d0
	move.b d0,myblock
	and.l #$0000ff00,d0
	lsr #8,d0
	move.l d0,d1
	
	;displace 1 blocks down
	add #1,d1
	
;using scroll2 to set the block

.noStartScroll2:

	
	mulu  #(16*80*3),d1	
	move.w Scroll2,d2
	mulu #1,d2
	add.w d2,d1


	add.w #2,d1
	
	move.l d1,Offset
	bsr WriteBlock	

	add.l #40,Offset
	bsr WriteBlock	
	
	rts
	
	

;;;;;;;;;;;WRITEBLOCK;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;EFFECTIVE SUBROUTINE TO USE DMA TO WRITE BLOCK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteBlock:

;Blitter control to copy Pieces to bitplane

	lea $dff000,a6
	bsr BlitWait ; Wait for blitter ---------------------------------

	move.w Offset,d0

stop:
	move.l #$09f00000,BLTCON0(a6)
	move.l #$ffffffff,BLTAFWM(a6)
	
	move.w #0+os,BLTAMOD(a6)
	move.w #238,BLTDMOD(a6)
	
	clr.l    d1
	clr.l    d2
	lea  Pieces,a5
	move.l a5,d1
	move.b myblock,d2
	mulu #96,d2
	add  d2,d1
	move.l d1,bltapt(a6)

	move.l #Foreground,d1
	add.l Offset,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

	bsr BlitWait ; Wait for blitter ---------------------------------
	
	clr.l    d1
	clr.l    d2
	lea  Pieces+2,a5
	move.l a5,d1
	move.b myblock,d2
	mulu #96,d2
	add  d2,d1
	move.l d1,bltapt(a6)

	move.l #Foreground,d1
	add.l Offset,d1	
	add.l #80,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

	bsr BlitWait ; Wait for blitter ---------------------------------	

	clr.l    d1
	clr.l    d2
	lea  Pieces+4,a5
	move.l a5,d1
	move.b myblock,d2
	mulu #96,d2
	add  d2,d1
	move.l d1,bltapt(a6)
	
	
	move.l #Foreground,d1
	add.l Offset,d1		
	add.l #160,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

	rts
	

	
	
WriteBlack:

;Blitter control to copy Pieces to bitplane

	movem.l d0-d7/a0-a6,-(sp)

	lea $dff000,a6
;	bsr BlitWait	

	move.w Offset,d0

	move.l #$09f00000,BLTCON0(a6)
	move.l #$ffffffff,BLTAFWM(a6)

	move.w #0+os,BLTAMOD(a6)
	move.w #238,BLTDMOD(a6)
	move.l #Black,bltapt(a6)

	move.l #Foreground,d1
	add.l Offset,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

;	bsr BlitWait
	move.l #Black+2,bltapt(a6)
	add.l #80,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

;	bsr BlitWait	
	move.l #Black+4,bltapt(a6)
	add.l #80,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)
	
	movem.l (sp)+,d0-d7/a0-a6

	rts	
	

ResetLevel:

	
	move.b #0,GameMode
	move.b #0,Jumping
	move.b #0,SpacePressed	
	
	move.b my_stage,d0
	cmp.b #1,d0 ;;;; LEVEL 1
	bne.b .NoLevel1
	move.b #1,GameMode
	
.NoLevel1

	cmp.b #2,d0 ;;;; LEVEL 2
	bne.b .NoLevel2
	move.b #2,GameMode
	
.NoLevel2


;;;;;;;;;	move.b #0,GameMode ;;;; For testing only


;Bitplane 1 reset colors


	move.b #8,d0
	lea Bitplane1_pallete,a0
	lea Bitplane1_pallete_orig,a1
	
	jsr CopyColors


;Bitplane 2 GAME reset colors

	move.b #8,d0
	lea PiecesColors,a0
	lea GameColors,a1

	jsr CopyColors
	
	move.l #1,Time
	move.l #1,Time2
	move.l #0,Offset
	move.b #$0f,DelayS1
	move.b #$0f,DelayS2
	move.l #0,Scroll
	move.l #0,Scroll2
	move.w #1,StageWindowPointer
	move.w #0,StageMemoryPointer
;	move.w #503,StageWindowPointer
;	move.w #5960,StageMemoryPointer
	move.b #0,Speed
	move.b #0,JumpSleep
;	move.b #0,vEXIT
	move.b #0,vEndReached
	move.b #0,GravityForce
	move.b #0,OnPlatform
	move.b #0,v_YouAreDeath
	move.b #0,v_DeathInProgress
	move.b #0,ControlCounter
	
	move.l #TomPosInit,TomPos
	move.l #TomPosInit,TomPos_old



	move.w #%0001000101000101,_CLXCON	
	move.w _CLXDAT,d0


xxx:
	move.w #TomPosYInit,TomPosY
	move.w #TomPosYInit,TomPosY_old
		

			
;d0=initial column
;d1=final column
	move.w #0,d0
	move.w #80,d1
	jsr EraseBackground
	

;Change Delay register

Change:
	move.b DelayS1,d0
	move.b DelayS2,d1
	rol.b #4,d0
	add.b d1,d0
	
	lea Delay,a0
	move.b d0,3(a0)
	move.b #0,2(a0)

	jsr EraseDust
	
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitEngine:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	move.w #%0000000101000101,_CLXCON	
	move.w _CLXDAT,d0

	


	
;;;;; Define Tom attached sprite Tom_1/Tom_2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ifeq COLLISIONSPRITE
		move.l #CollisionYES,d0
		swap d0
		move.w d0,SprP3a+2
		swap d0
		move.w d0,SprP3b+2
	endc

	

	lea Foreground,a0	;ptr to first bitplan of logo
	lea CopBplP,a1	;where to poke the bitplane pointer words
	move #3-1,d0
.bpll:
	move.l	a0,d1
	swap d1
	move.w d1,2(a1) 
	swap d1
	move.w d1,6(a1)

	add	#16,a1		;point to next bpl to poke in copper
	lea PictureBpl(a0),a0
	dbf d0,.bpll



	lea Background,a0	;ptr to first bitplan of Background
	lea CopBplP,a1	;where to poke the bitplane pointer words
	addq	#8,a1		;point to next bpl to poke in copper
	move #3-1,d0
.bpll2:
	move.l	a0,d1
	swap d1
	move.w d1,2(a1) 
	swap d1
	move.w d1,6(a1)

	add	#16,a1		;point to next bpl to poke in copper
	lea PictureBpl(a0),a0
	dbf d0,.bpll2



	move.b #0,TomCustome ;Restart Tom Custome
	move.l TomPos,Tom_1
	move.l TomPos,Tom_2	

	clr.l 	Time
	

	
	rts
	

****************************************************************************
;WritePosition 
****************************************************************************

WritePosition:

	and.b #%11111001,TomPos+3
	and.b #%11111001,TomPos_old+3


;;;;;;;;;;;;; FEET ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
;TomPos Position control under $ff	
	move.w  TomPosY,d1
	
	cmp.w #$012c,d1   ; MaxLimit
	blt   .Visible	
	move.w #$002c,TomPosY
	move.w #$002c,d1  ; MinLimit
	
.Visible:
;	cmp.w	#$00f0,d1
	cmp.w	#$00ea,d1 ; Maxlimit -6 
	blt     .NoUnderLimitStop
	or.b #%00000010,TomPos+3	
	
	
.NoUnderLimitStop

	cmp.w	#$0100,d1
	blt     .NoUnderLimitStart
	or.b #%00000100,TomPos+3	
.NoUnderLimitStart



	move.b v_DeathInProgress,d1
	cmp.b #1,d1
	beq .IMDeath ; Just one time
	
	move.w TomPosY,d1
	cmp.w	#$0f7,d1
	blt  .IMDeath
	jsr DeathRoutine
	rts
.IMDeath




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;; HEAD ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;TomPos_old Position control under $ff	
	move.w  TomPosY_old,d1
	
	cmp.w #$012c,d1   ; MaxLimit
	blt   .Visible_old	
	move.w #$002c,TomPosY_old
	move.w #$002c,d1  ; MinLimit
	
.Visible_old:
	cmp.w	#$00f0,d1
	blt     .NoUnderLimitStop_old
	or.b #%00000010,TomPos_old+3	
.NoUnderLimitStop_old

	cmp.w	#$00100,d1
	blt     .NoUnderLimitStart_old
	or.b #%00000100,TomPos_old+3	
.NoUnderLimitStart_old


	move.b	TomPosY+1,TomPos
	move.b	TomPosY+1,TomPos+2
	add.b	#$16,TomPos+2
	
	move.b	TomPosY_old+1,TomPos_old
	move.b	TomPosY_old+1,TomPos_old+2
	add.b	#$10,TomPos_old+2


	
	rts


	

*********************************************************************
CollisionDetectionControl:
************************************************************************
	
	move.b #0,OnPlatform
	
;	move.w TomPosY,d0
;	cmp.w #$4c,d0
;	blt .DeathDetected
;	cmp.w #$f0,d0
;	bgt .DeathDetected
	
	
	move.w ControlCounter,d0	
	btst #0,d0
	bne .GoFeetCollisionControl

	jsr HeadCollisionControl
	move.w #%0001000101000101,_CLXCON	
	rts

;	jmp .EndCollisionControl
	
.GoFeetCollisionControl
	jsr FeetCollisionControl
	move.w #%0101010101010101,_CLXCON
	
.EndCollisionControl:

	rts

	move.w ControlCounter,d0	
	btst #0,d0
	bne .ExitCollision2

;Platform;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	move.w #%0001000101000101,_CLXCON	
	rts
.ExitCollision2

;Death;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	move.w #%0101010101010101,_CLXCON
	rts


.DeathDetected

	jsr DeathRoutine
	move #$1,vEXIT
	rts
	
	

	
FeetCollisionControl:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;Sprite alarm;;;;;;;;;;;;;;;;
;EmptySprite
	move.l #EmptySprite,d0
	swap d0
	move.w d0,SprP4a+2
	swap d0
	move.w d0,SprP4b+2
	swap d0
	move.w d0,SprP3a+2
	swap d0
	move.w d0,SprP3b+2
	ifeq COLLISIONSPRITE
		move.l #PlatformNO,d0
		swap d0
		move.w d0,SprP4a+2
		swap d0
		move.w d0,SprP4b+2
	endc
	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;Platform Detection;;;;;;;;;;;;;;
**********************************************************
	;;;;;;;;;XXXXAAAAAABBBBBB
;	move.w #%0001000101000101,_CLXCON
	move.w _CLXDAT,d0	
	btst #3,d0

	beq	ContinueFeetCollision
**********************************************************		

;Set on platform to true


	move.b #1,OnPlatform

;;;;;;;;;;;;;;Sprite alarm;;;;;;;;;;;;;;;;
	ifeq COLLISIONSPRITE
		move.l #PlatformYES,d0
		swap d0
		move.w d0,SprP4a+2
		swap d0
		move.w d0,SprP4b+2
	endc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WF:
	move.w TomPosY,d0
	sub.w #8,d0
	and.w #%1111111111111100,d0
	or.b  #%0000000000001100,d0
	move.w d0,TomPosY
	move.w d0,TomPosY_old
	


;	move.b d0,TomPos
;	move.b d0,TomPos+2
;	add.b #$10,TomPos+2
	
;	move.l TomPos,d0
;	move.l d0,TomPos_old	
	
	move #0,GravityForce
	
	jmp ExitCollisionFeet

	
	
ContinueFeetCollision:


;Platform Detection TOM ;;;;;;;;;;;;;;
**********************************************************
	;;;;;;;;;XXXXAAAAAABBBBBB
;	move.w #%0001000101000101,_CLXCON
	move.w _CLXDAT,d0	
	btst #1,d0

	beq	.ContinueFeetCollision2
**********************************************************		

;Set on platform to true


	move.b #1,OnPlatform

;;;;;;;;;;;;;;Sprite alarm;;;;;;;;;;;;;;;;
	ifeq COLLISIONSPRITE
		move.l #PlatformYES,d0
		swap d0
		move.w d0,SprP4a+2
		swap d0
		move.w d0,SprP4b+2
	endc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
	move.b TomPos_old,d0
	sub.b #5,d0
	and.b #%11111100,d0
	or.b  #%00001100,d0


	move.b d0,TomPos_old
	move.b d0,TomPos_old+2
	add.b #$10,TomPos_old+2
	
	
	
	move #0,GravityForce
	
	jmp ExitCollisionFeet

.ContinueFeetCollision2


;	move.l TomPos,d0
;	move.l d0,TomPos_old

	move.w TomPosY,d0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	move.w d0,TomPosY_old
	
	ifeq COLLISIONSPRITE	
		move.l #CollisionNO,d0
		swap d0
		move.w d0,SprP3a+2
		swap d0
		move.w d0,SprP3b+2
	endc

ExitCollisionFeet:
	rts	
	
	
	

HeadCollisionControl:
;Head Death Detection;;;;;;;;;;;;;;
**********************************************************
	;;;;;;;;;XXXXAAAAAABBBBBB
;	move.w #%0001010101010101,_CLXCON	
	move.w _CLXDAT,d0
	
		
	btst #1,d0
	beq .NoTomDeath

	jsr DeathRoutine
	jmp .ExitHeadCollision

	
.NoTomDeath:
;;; No Death detection sprite TOM. Now I have to look for feet collision death. 	
	btst #3,d0
;	jmp .ExitHeadCollision

	beq  .ExitHeadCollision
	
	add.b #1,v_YouAreDeath
	move.b v_YouAreDeath,d0
	cmp.b #2,d0
	bne .ExitHeadCollisionWarning
	
;If here, I have a feet death detection.	
	
	jsr DeathRoutine
	jmp .ExitHeadCollisionWarning
;	move.b #1,vEXIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.ExitHeadCollision:
	move.b #0,v_YouAreDeath
	
;If here, collision possible
.ExitHeadCollisionWarning:
	rts



DeathRoutine:

*********************************:*************************		
;If here, I have a Tom head death detection.	

	move #-10,GravityForce
	move.b #1,v_DeathInProgress
	jsr EraseDust
	
	rts

	
	
WriteDeathSprite:

*********************************:*************************		
;If here, I have a Tom head death detection.	


;;;; Rotate colors 
	add.b #1,Bitplane1_pallete+19 ; COLOR 3
	add.b #1,Bitplane1_pallete+15


	move.l #Death_1,d0
	move.l d0,a3
	move.l TomPos_old,(a3)
	

	swap d0
	move.w d0,SprP1a+2
	swap d0
	move.w d0,SprP1b+2

	move.l #Death_2,d0
	move.l d0,a3
	move.l TomPos_old,(a3)

	swap d0
	move.w d0,SprP2a+2
	swap d0
	move.w d0,SprP2b+2


	ifeq COLLISIONSPRITE	
		move.l #CollisionYES,d0
		swap d0
		move.w d0,SprP3a+2
		swap d0
		move.w d0,SprP3b+2
	endc

	move.l #$3ffff,d0
	



	rts



DeathInProgressRoutine:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Death routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





	move.w	TomPosY,TomPosY_old
	add.w	#2,TomPosY                
	bsr GravityControl
	bsr WritePosition
	bsr WriteDeathSprite
	
	move.l #FeetSpr,d0
	move.l d0,a3
	
	move.l TomPos,(a3)

	
	swap d0
	move.w d0,SprP5a+2
	swap d0
	move.w d0,SprP5b+2
	
	
	move.w TomPosY_old,d1
	cmp.w	#$127,d1	
	blt   .NoEnd
	

	move.w #0,d0
	move.w #80,d1
	
	
;	move.w #$0000,Activate_bitplanes+2 ;  Hide bitplanes	
	jsr FrameWait
;	jsr CleanBitplane






.muere


;;;;Activate_bitplanes


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	bsr ResetLevel
	bsr WritePosition
	move.w #$0,TomPosY
	move.w #$0,TomPosY_old
	move.b #1,ScrollDirection1
	move.b #1,ScrollDirection2	
	move.b #2,PowerSpeed1
	move.b #16,PowerSpeed2	
	move #0,Scroll
	move #0,Scroll2

;	move.w #$0,TomPosY
;	move.b #0,TomPos_old
;	move.w #$0,d1
	jsr FrameWait
	jsr Parallax
	
	
	bsr WritePosition
	bsr BreathControl
	
	bsr MoveSprite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	

	move.b #8,d0
	lea Bitplane1_pallete,a0
	lea Bitplane1_pallete_alt,a1	
	jsr CopyColors

	jsr FrameWait
	
	clr.l d0
;	move.w Scroll2,d0
	add.l  #16,d0
	move.l #7,d1
	lea Text_Die,a0	
	bsr WriteText   	
      



	sub.b #1,Lives
	jsr PaintScore

	clr.l d0
;	move.w Scroll2,d0
	add.l  #34,d0
	move.l #13,d1
	lea LivesAscii,a0	
	bsr WriteText   	


	clr.l d0
;	move.w Scroll2,d0
	add.l  #22,d0
	move.l #13,d1
	lea Text_lives,a0	
	bsr WriteText   	

;;;;;;;;;; Write Progress on screen	
	
	clr.l d1
	clr.l d0
	move.w StageWindowPointer,d0
	move.b #4,d1
	lea ProgressAscii,a0
	bsr PaintAnyAscii
	
	clr.l d0
;	move.w Scroll2,d0
	add.l  #20,d0
	move.l #10,d1
	lea ProgressAscii,a0	
	bsr WriteText   	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	jsr FrameWait
	

;	move.w #$6600,Activate_bitplanes+2 ; Show bitplanes
	bsr Wait_seconds
	


	cmp.b #0,Lives
	bgt.b .Alive

	bsr Wait_seconds

	clr.l d0
;	move.w Scroll2,d0
	add.l  #14,d0
	move.l #7,d1
	lea GameOver,a0	
	bsr WriteText   	
	
	bsr Wait_seconds
	bsr Wait_seconds

	
.Alive	

	move.b #%00001111,vLoadImages
	bsr LoadImages
	

	
	
	jsr RestartAll
	
	cmp.b #0,Lives
	bgt.b .NoEnd
	
;	move.b #1,vExit
	move.b #1,Intro
	
	
.NoEnd
	rts	

	
	
	
	
BreathControl:
****************************************************************************************
;;;;;;;;;;;;;;;;;;;BREATHING CONTROL;;;;;;;;;;;;;;;;;;;;;;;
****************************************************************************************
	
	

	
	add.w #1,BreathSleep
	move.w BreathSleep,d1
	cmp #5,BreathSleep
	cmp #5,BreathSleep
	bne.w .sigue4   ; EXIT JUMPING ->>>>>>>>>>>>>>>>>>
	move.w #0,BreathSleep



;	Breath Custom Control

	move.w TomCustomeBreath,d0
	move.w TomCustomeBreathDirection,d1

	cmp.b #1,d0
	beq .nochangedirection


;ChangeDirection
	
	
	mulu.w #-1,d1
	move.w d1,TomCustomeBreathDirection

.nochangedirection:	   ; Here if not change direction

	
	add.w d1,TomCustomeBreath
	
	
	
;;;;;;;;;;;;;;;;;;;END BREATHING CONTROL;;;;;;;;;;;;;;;;;;;

.sigue4:

	rts
	
	
	
	
	
DustControl:
****************************************************************************************
;;;;;;;;;;;;;;;;;;;DUST CONTROL;;;;;;;;;;;;;;;;;;;;;;;
****************************************************************************************
	
	
	add.w #1,DustSleep
	move.w DustSleep,d1
	cmp #6,DustSleep
	bne.w .sigue4Dust   ; EXIT JUMPING ->>>>>>>>>>>>>>>>>>
	move.w #0,DustSleep


	

;	Breath Custom Control

	move.w TomCustomeDust,d0


	cmp.b #5,d0
	blt .NoLimitDust
	
	move #0,TomCustomeDust


	
.NoLimitDust:	   ; Here if not change direction

	
	add.w #1,TomCustomeDust
	
	
	
;;;;;;;;;;;;;;;;;;;END BREATHING CONTROL;;;;;;;;;;;;;;;;;;;

.sigue4Dust:

	rts
	
	
	
****************************************************************************************
****************************************************************************************	
MoveSprite:
****************************************************************************************
****************************************************************************************

	PUSH_ALL

	move.l  #TomSize,d0
	move.w TomCustomeBreath,d1
	muls d1,d0
	add.l #Tom_1,d0
	move.l d0,a3
	
	cmp.b #1,IMDOWN
	bne.b NODown1
	lea.l Bended_1,a3
	move.l #Bended_1,d0
NoDown1:


	move.l TomPos_old,(a3)
	swap d0
	move.w d0,SprP1a+2
	swap d0
	move.w d0,SprP1b+2

	
	
	move.l  #TomSize,d0
	move.w TomCustomeBreath,d1
	muls d1,d0
	add.l #Tom_2,d0
	move.l d0,a3
	
	cmp.b #1,IMDOWN
	bne.b NODown2
	lea.l Bended_2,a3	
	move.l #Bended_2,d0
NoDown2:



	move.l TomPos_old,(a3)
	swap d0
	move.w d0,SprP2a+2
	swap d0
	move.w d0,SprP2b+2
	
	
;Write feet

	move.l #FeetSpr,d0
	move.l d0,a3
	
	move.l TomPos,(a3)

	
	swap d0
	move.w d0,SprP5a+2
	swap d0
	move.w d0,SprP5b+2


;Write dust if platform;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;Check if On Platform
	move.b OnPlatform,d1
	cmp.b #1,d1
	bne.w .NoPlatformNoDust   ; NO PLATFORM NO DUST
	
;part 1
	move.l  #TomSize,d0
	move.w TomCustomeDust,d1
	muls d1,d0
	add.l #Dust_1a,d0
	move.l d0,a3

	sub.b #8,TomPos_old+1
	move.l TomPos_old,(a3)
	add.b #8,TomPos_old+1
	swap d0
	move.w d0,SprP3a+2
	swap d0
	move.w d0,SprP3b+2
;part 2
	move.l  #TomSize,d0
	move.w TomCustomeDust,d1
	muls d1,d0
	add.l #Dust_1b,d0
	move.l d0,a3

	sub.b #8,TomPos_old+1
	move.l TomPos_old,(a3)
	add.b #8,TomPos_old+1
	swap d0
	move.w d0,SprP4a+2
	swap d0
	move.w d0,SprP4b+2
	
	jmp .exit_MoveSprite

	
.NoPlatformNoDust

; If here and mode 1 or 2, controling if jumping is on.

; Lets see if jump is pressed
	
	cmp.b #1,SpacePressed
	bne.b .NoMode1or2   ;;; If no SpacePressed then go out
	
	

	cmp.b #0,GameMode
	beq .NoMode1or2  ; No special jump, just dust on platform
	
	cmp.b #1,GameMode
	bne.b .NoMode1
	jsr FireSuperjump
;	jsr FireFlying

	jmp .NoMode1or2

.NoMode1

	jsr FireFlying
;	jsr FireSuperjump
		
.NoMode1or2

	jmp .exit_MoveSprite
	
	
;EmptySprite
	jsr EraseDust

.exit_MoveSprite

	POP_ALL
	rts
	

****************************************************************************************
****************************************************************************************	
FireSuperjump:
****************************************************************************************
****************************************************************************************
;part 1
	move.l  #TomSize,d0
	move.w TomCustomeDust,d1
	muls d1,d0
	add.l #Jump_1a,d0
	move.l d0,a3

	add.b #16,TomPos_old
	add.b #16,TomPos_old+2
	
	move.l TomPos_old,(a3)
	sub.b #16,TomPos_old
	sub.b #16,TomPos_old+2

	swap d0
	move.w d0,SprP3a+2
	swap d0
	move.w d0,SprP3b+2
;part 2
	move.l  #TomSize,d0
	move.w TomCustomeDust,d1
	muls d1,d0
	add.l #Jump_1b,d0
	move.l d0,a3

	add.b #16,TomPos_old
	add.b #16,TomPos_old+2
	move.l TomPos_old,(a3)
	sub.b #16,TomPos_old
	sub.b #16,TomPos_old+2
	
	
	swap d0
	move.w d0,SprP4a+2
	swap d0
	move.w d0,SprP4b+2


	rts

****************************************************************************************
****************************************************************************************	
FireFlying:
****************************************************************************************
****************************************************************************************
;part 1
	move.l  #TomSize,d0
	move.w TomCustomeDust,d1
	muls d1,d0
	add.l #Flying_1a,d0
	move.l d0,a3

	add.b #16,TomPos_old
	add.b #16,TomPos_old+2
	
	move.l TomPos_old,(a3)
	sub.b #16,TomPos_old
	sub.b #16,TomPos_old+2

	swap d0
	move.w d0,SprP3a+2
	swap d0
	move.w d0,SprP3b+2
	
	
;part 2
	move.l  #TomSize,d0
	move.w TomCustomeDust,d1
	muls d1,d0
	add.l #Flying_1b,d0
	move.l d0,a3

	add.b #16,TomPos_old
	add.b #16,TomPos_old+2
	move.l TomPos_old,(a3)
	sub.b #16,TomPos_old
	sub.b #16,TomPos_old+2
	
	
	swap d0
	move.w d0,SprP4a+2
	swap d0
	move.w d0,SprP4b+2


	rts



************************************************************
EraseDust:

;EmptySprite

	PUSH_ALL

	move.l #EmptySprite,d0
	swap d0
	move.w d0,SprP4a+2
	swap d0
	move.w d0,SprP4b+2
	swap d0
	move.w d0,SprP3a+2
	swap d0
	move.w d0,SprP3b+2

	POP_ALL
	
	rts
	

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	
	
	
	
********************************************************************************************
;  GRAVITY Control
GravityControl:
****************************************************************************************
;;;;;;;;;;;;;;;;;;;;;;;Jump loop control;;;;;;;;;;;;;;;;;;;;;;;;;;;;
****************************************************************************************
;Check if no platform (NO GRAVITY IF TOUCHING PLATFORM)
;	move.b Jumping,d1
;	cmp.b #1,d1
;	bne.w .ExitGravity   ; NO GRAVITY

;Gravity in progress

;Check if On Platform
	move.b OnPlatform,d1
	cmp.b #1,d1
	beq.w .ExitGravity   ; NO GRAVITY TOUCHING PLATFORM


	add.w #1,GravitySleep
	move.w GravitySleep,d1
	cmp #1,GravitySleep
	bne.w .ExitGravity   ; EXIT GRAVITY->>>>>>>>>>>>>>>>>>

	move.w #0,GravitySleep


	
	add.w #1,GravityForce
	move.w GravityForce,d1
	cmp.b #4,d1
	blt .sigue41	
	move.w #3,GravityForce
	
;	add.b #3,GravityForce
	move.w GravityForce,d1 ; Always 2....

.sigue41	

;TomPosY modification
;	add.w	#$1,TomPosY
	move.w	TomPosY,TomPosY_old
	add.w	d1,TomPosY

;	add.b d1,TomPos
;	add.b d1,TomPos+2

.ExitGravity
	rts

	
	
	
	
	
KeyControl:
********************************************************************************************
;;;;;;;Keycontrol;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
********************************************************************************************

	move.b #0,IMDOWN

	lea dt,a6
	
	
;;;;;;;;;;;;;;;;;;;;;;	move.b  $bfec01,d0      ;Get 'encoded' key that pressed
;;;;;;;;;;;;;;;;;;;;;;    ror.b   #1,d0
;;;;;;;;;;;;;;;;;;;;;;    not.b   d0

	
;;;;; TEST

;;;;; FLYING	
	
;Check if On Platform

	move.b #0,SpacePressed	
	
	cmp.b #0,GameMode	
	bne.b .NoMode0  ;;;; Only control of jump in platform if Mode=0

	move.b OnPlatform,d1
	cmp.b #1,d1
	bne.w .noSpacePress   ; NO JUMP ->>>>>>>>>>>>>>>>>>

.NoMode0	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke space to jump
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	cmp.b   #$40,d0	        ;Check for $40 = Space key
;	bne.b .noSpacePress

	tst.b	keys+KEYCODE_SPACE(a6)
	beq	.noSpacePress

; If I am not jumping, JUMP!!!
	

	move.b #1,SpacePressed
	cmp.b #2,GameMode	
	beq.b .Mode2 ;   If GameMode2 then I can fly
		
	move.w GravityForce,d1
	cmp.b #0,d1
	bne.b .noSpacePress

.Mode2


	move.w #-5,GravityForce ; Modes 0 and 1
	move.w #0,GravitySleep
	


	sub.w #$6,TomPosY
	sub.w #$6,TomPosY_old
	
	
	cmp.b #2,GameMode
	bne.b .NoMode2
	
	cmp.b #1,OnPlatform
	bne.b .NoOnPlatform
	sub.w #$4,TomPosY      ;if on platform, add 2 + 4
	sub.w #$4,TomPosY_old

	
.NoOnPlatform
	add.w #$6,TomPosY      ;if not on platform just add 4
	add.w #$6,TomPosY_old
.NoMode2	


	
.noSpacePress:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke down arrow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	tst.b	keys+KEYCODE_CURSORDOWN(a6)
	beq	.noDownPress

;;;;;;;;;	cmp.b   #$4d,d0	        ;Check for $4D = Down Arrow
;;;;;;;;;	bne.b .noDownPress

	jsr .GoDown
.noDownPress:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke ESC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	tst.b	keys+KEYCODE_ESC(a6)
	beq	.noESCPress
	move.b #1,vEXIT
.noESCPress:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke RIGHT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	tst.b	keys+KEYCODE_CURSORRIGHT(a6)
	beq	.noRight
	add.b #1,PowerSpeed1
.noRight

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke LEFT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	tst.b	keys+KEYCODE_CURSORLEFT(a6)
	beq	.noLeft
	sub.b #1,PowerSpeed1
.noLeft



	rts


.GoDown

	move.b #1,IMDOWN
	rts
	
****************************************************************

****************************************************************
;Routine to restart the stages

InitGame:
	
	lea Stage1,a0
	move.l a0,stage1_address
	lea Stage2,a0
	move.l a0,stage2_address
	lea Stage3,a0
	move.l a0,stage3_address
	
	rts

	
********************************************************************************************************************************
********************************************************************************************************************************
	
IntroSubroutine:

;;;;;; NOINTRO, DEBUG
;	jmp .StartToPlay

;;;;;;;;;;	move.w #$0,TomPosY
;;;;;;;;;;	move.w #$0,TomPosY_old	
	bsr WritePosition
	bsr BreathControl
	bsr MoveSprite
	

	move.w #1,SpeedScroll1
	move.w #1,SpeedScroll2

	move.w #$0,TomPosY
	move.w #$0,TomPosY_old
    
	move.b #%00000011,vLoadImages
	bsr LoadImages

	move.b #%00001100,vLoadImages
	bsr LoadImages

	
;<------------------------------- (1)
;Intro 1. 2 Scroll right
	move.b #1,ScrollDirection1
	move.b #1,ScrollDirection2	
	move.b #2,PowerSpeed1
	move.b #16,PowerSpeed2	
	move #0,Scroll
	move #0,Scroll2

;d0=Loop steps
;d1=speed Tom
	move.w #80,d0
	move.w #$0,TomPosY
	move.b #0,TomPos_old
	move.w #$0,d1
	bsr Sub_IntroLoop_right	
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay
	
;<------------------------------- (2)
;Intro 1. 2 Scroll right
	move.b #1,ScrollDirection1
	move.b #1,ScrollDirection2	
	move.b #2,PowerSpeed1
	move.b #16,PowerSpeed2	

;d0=Loop steps
;d1=speed Tom
	move.w #100,d0
	move.w #$0,TomPosY
	move.b #0,TomPos_old
	move.w #$0,d1
	bsr Sub_IntroLoop_right_desc



;<------------------------------- (3)
	move.b #1,ScrollDirection1
	move.b #1,ScrollDirection2	

;d0=Loop steps
;d1=speed Tom
	move.w #80,d0
	move.w #$0,TomPosY
	move.b #0,TomPos_old
	move.w #$0,d1
	
	bsr Sub_IntroLoop_right
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay


.loop_x1
	jsr FrameWait
	jsr Parallax

	bsr WritePosition
	bsr BreathControl
	bsr MoveSprite

	
	cmp.w #0,Scroll2
	bne.b .loop_x1

;<<<<<<<<<<----------------------------------------
	

	move.b #8,d0
	lea PiecesColors,a0
	lea IntroColors,a1
	jsr CopyColors
	move.w #1,SpeedScroll1
	move.w #1,SpeedScroll2	

;;; Call to Sub_Paint	

;
; Example
; With x height x planes  (pixels)
; 272 x 128 x 3
; 34bx128x3
;  36b x 64 x 3  (bytes)
; Mod origen=36 + 36 + 36 - (36)  = 72
; Mod origen=34 + 34 + 34 - (34)  = 68

; Mod destino=80 + 80 + 80 - (34)
; Size=height*64 + width in words
; Size=height*64 (lines) + 34/2 (bytes/2  1plane)


; d0=x
; d1=y
; d2=mod_orig
; d3=mod_dest
; d4=layers
; d5=increment plane original
; d6=increment plane dest
; d7=size register
; a4=Origin plane 0 base address
; a5=Destination plane 0 base address



	move.l       #68,d2
	move.l #240-(34),d3
	move.l        #3,d4
	move.l 		 #34,d5
	move.l 		 #80,d6
	move.l #64*128+17,d7
	lea  		Presentation,a4
	lea  		Foreground,a5

	move.l        #40,d0
	move.l        #4,d1
	
	jsr Sub_Paint

	move.b #0,PowerSpeed1
	move.b #0,PowerSpeed2
	bsr Wait_breathing
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay	


;	move.w #0,d0
;	move.w #80,d1
;	jsr CleanBitplane


	move.b #4,PowerSpeed1
	move.b #1,PowerSpeed2
	move.b #-1,ScrollDirection1
	move.b #1,ScrollDirection2

	
;<<<<<<<<<<----------------------------------------	
	
.loop1
	jsr FrameWait
	jsr Parallax
	
	bsr WritePosition
	bsr BreathControl
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay
	
	bsr MoveSprite

	
	cmp.w #36,Scroll2
	bne.b .loop1

;<<<<<<<<<<----------------------------------------

	move.b #0,PowerSpeed1
	move.b #0,PowerSpeed2
	bsr Wait_breathing
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay
	
	move.w #0,d0
	move.w #80,d1
	

	jsr CleanBitplane	
	move.w #40,Scroll

	jsr WriteRanking

	move.b #6,PowerSpeed1
	move.b #6,PowerSpeed2	
	move.b #1,ScrollDirection1
	move.b #-1,ScrollDirection2	
;<<<<<<<<<<----------------------------------------

.loop_x2
	jsr FrameWait
	jsr Parallax

	bsr WritePosition
	bsr BreathControl

	
	bsr MoveSprite

	
	cmp.w #0,Scroll2
	bne.b .loop_x2

;<<<<<<<<<<----------------------------------------


	
	move.b #0,PowerSpeed1
	move.b #0,PowerSpeed2
	bsr Wait_breathing
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay
	
	bsr Wait_breathing	
	cmp.b #0,IntroKeyPressed
	bne.w .StartToPlay
	
	move.w #40,d0
	move.w #80,d1
	jsr EraseBackground
	
	


;
; Example
; With x height x planes  (pixels)
; 288 x 64 x 3
;  36b x 64 x 3  (bytes)
; Mod origen=36 + 36 + 36 - (36)  = 72
; Mod destino=80 + 80 + 80 - (36)
; Size=height*64 + width in words
; Size=height*64 (lines) + 36/2 (bytes/2  1plane)


	move.l       #72,d2
	move.l #240-(36),d3
	move.l        #3,d4
	move.l 		 #36,d5
	move.l 		 #80,d6
	move.l #64*48+18,d7
	lea  		CELogo,a4
	lea  		Foreground,a5

	move.l        #40,d0 ; logopos (X)
	move.l        #9,d1 ; logopos (Y)
	
	
	jsr Sub_Paint

	move.w #40,d0
	move.w #3,d1
	lea Text1,a0	
	jsr WriteText

	move.w #40,d0
	move.w #4,d1
	lea Text2,a0	
	jsr WriteText

	move.w #40,d0
	move.w #5,d1
	lea Text3,a0	
	jsr WriteText
	
	move.b #1,ScrollDirection1
	move.b #1,ScrollDirection2	
	move.b #6,PowerSpeed1
	move.b #6,PowerSpeed2

	
;<<<<<<<<<<----------------------------------------

.loop2
	jsr FrameWait
	jsr Parallax

	bsr WritePosition
	bsr BreathControl

	bsr MoveSprite

	
	cmp.w #36,Scroll2
	bne.b .loop2

.endloop

;<<<<<<<<<<----------------------------------------


	move.b #0,PowerSpeed1
	move.b #0,PowerSpeed2
	bsr Wait_breathing
	bsr Wait_breathing

	
	move.w #40,d0
	move.w #7,d1
	lea PressKey,a0	
	jsr WriteText

.UntilPressAnyKey	
	jsr IntroKeyControl
	cmp.b #0,IntroKeyPressed
	beq.b .UntilPressAnyKey

	
	
;.siguexxx	
;	btst #6,$bfe001
;	bne.w  .siguexxx
	
	
.StartToPlay
	
;d0=initial column
;d1=final column
	move.w #0,d0
	move.w #80,d1
	jsr EraseBackground
	
	move.w #40,Scroll

	move.b #1,ScrollDirection1
	move.b #1,ScrollDirection2		
	


;End Intro, reset all and intro off
	move.b #0,Intro

	move.b #%00001111,vLoadImages
	bsr LoadImages
	


	
	jsr RestartAll	
	



	move.b #2,PowerSpeed1
	move.b #4,PowerSpeed2
	move.w #1,SpeedScroll1
	move.w #1,SpeedScroll2		
	  

	move.b #NumLives,Lives	   	
	
	rts

		
	
	


	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sub_paint. Blitter, copy of a rectangle in "n" planes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sub_Paint:
; d0=x
; d1=y
; d2=mod_orig
; d3=mod_dest
; d4=layers
; d5=increment plane original
; d6=increment plane dest
; d7=size register
; a4=Origin plane 0 base address
; a5=Destination plane 0 base address


	PUSH_ALL

	movem.l d0-d7/a0-a6,-(sp)
;	move.l #0,d7
	

  
;	move.l #30,d0    ;x->d0
;	move.l #6,d1     ;y->d1
	
;Offset of the Dest layer
;Field is 80 blocks of 16 bites X 3 layers
	mulu   #(80*3*16),d1
	add.l  d0,d1
	move.l d1,Offset

	move.l #0,d0
	move.l #0,d1
	

	lea $dff000,a6

	move.l #$09f00000,BLTCON0(a6)
	move.l #$ffffffff,BLTAFWM(a6)
	move.w d2,BLTAMOD(a6)
	move.w d3,BLTDMOD(a6)	

	bsr BlitWait ; Wait for blitter ---------------------------------

	
.loop_planes



;;;;;;;	move.w Offset,d0


	move.l a4,d1
	add.l  d0,d1
	move.l d1,bltapt(a6)


	move.l a5,d1
	add.l Offset,d1
	move.l d1,bltdpt(a6)

;   write!!!!!	
;	move.w #64*64+18,BLTSIZE(a6)	  ; 64 lines X 64  (<--- desplace 6 bits) + 18 (height in words)
	move.w d7,BLTSIZE(a6)	  ; 64 lines X 64  (<--- desplace 6 bits) + 18 (height in words)

	sub.w #1,d4
	add.l  d6,Offset ;  Add displacement to Offset for the next layer	
	add.l d5,d0   ; Increment d7 by plane
	
	cmp.w #0,d4
	bne.w .loop_planes

	movem.l (sp)+,d0-d7/a0-a6
	
	
	POP_ALL
	
	rts
	
	
	
	
FrameWait:
wframe:
	btst #0,$dff005
	bne.b wframe
	cmp.b #$2a,$dff006
	bne.b wframe
wframe2:
	cmp.b #$2a,$dff006
	beq.b wframe2	
	rts
	




PaintLogo:

;x

	move.w #3,d5  ; Num of layers
	move.l #0,d4
	move.l #0,d3
	
.loop_planes
  
	move.l #30,d0    ;x->d0
	move.l #6,d1     ;y->d1
	
	mulu   #(80*3*16),d1
	add.l  d0,d1
	move.l d1,Offset
	add.l  d3,Offset



	lea $dff000,a6
	bsr BlitWait ; Wait for blitter ---------------------------------

	move.w Offset,d0


	move.l #$09f00000,BLTCON0(a6)
	move.l #$ffffffff,BLTAFWM(a6)
	
	move.w #72,BLTAMOD(a6)
	move.w #240-(36),BLTDMOD(a6)


	
	clr.l    d1
;
	clr.l    d2
	lea  CELogo,a5
	move.l a5,d1
	add.l  d4,d1
	move.l d1,bltapt(a6)

	move.l #Foreground,d1
	add.l Offset,d1
	move.l d1,bltdpt(a6)
	move.w #64*64+18,BLTSIZE(a6)	  ; 64 lines X 64  (<--- desplace 6 bits) + 18 (height in words)

	sub.w #1,d5
	add.l #80,d3
	add.l #36,d4	
	cmp.w #0,d5
	bne.w .loop_planes
	
	rts

****************************************************************************
;Parallax  movement subroutine 
****************************************************************************

Parallax:
;	jmp .NoMoveField
****************************************************************************
;Parallax  BITPLANE 1 BACKGROUND
****************************************************************************
;Delay loop bitplane 1

	add.w	#1,Time
	move.w	Time,d1
	cmp.w	SpeedScroll1,d1
	bne.w .NoMoveField

	clr.l 	Time
	
	
	
	cmp.b #1,ScrollDirection1
	bne .LeftDirection
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.RightDirection	

	move.b PowerSpeed1,d1
	sub.b  d1,DelayS1
	move.b DelayS1,d0
	cmp.b #$20,d0
	bcs .enddelay		; Branch if less unsigned
	add.b #$10,DelayS1

;Move Scroll by n

	add.w	#2,Scroll

	move.w  Scroll,d0
	cmp.b	#38,d0
	bne.b	.noStartScroll

	move.w	#-2,Scroll
	
	jmp .noStartScroll
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.LeftDirection	

	move.b PowerSpeed1,d1
	add.b  d1,DelayS1
	move.b DelayS1,d0
	cmp.b #$10,d0
	blt .enddelay		; Branch if less unsigned
	sub.b #$10,DelayS1

;Move Scroll by n

	sub.w	#2,Scroll

	move.w  Scroll,d0
	cmp.w	#-2,d0
	bne.b	.noStartScroll

	move.w	#38,Scroll
	
	jmp .noStartScroll
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	

.noStartScroll:

	
	lea Background,a0	;ptr to first bitplan of Background
	lea CopBplP,a1	;where to poke the bitplane pointer words
	addq	#8,a1		;point to next bpl to poke in copper
	move #3-1,d0
.bpll:
	move.l	a0,d1
	add.w	Scroll,d1
	swap d1
	move.w d1,2(a1) 
	swap d1
	move.w d1,6(a1)

	add	#16,a1		;point to next bpl to poke in copper
	lea PictureBpl(a0),a0
	dbf d0,.bpll

.enddelay	

;Change Delay register

	move.b DelayS1,d0
	move.b DelayS2,d1
	rol.b #4,d0
	add.b d1,d0
	
	lea Delay,a0
	move.b d0,3(a0)
	move.b #0,2(a0)


.NoMoveField
;End Scroll Bitplane 1
**************************************************************************


****************************************************************************
;Parallax  BITPLANE 2 FRONT !!!!
****************************************************************************
;Delay loop bitplane 2

	add.w	#1,Time2
	move.w	Time2,d1
	cmp.w	SpeedScroll2,d1
	bne.w .NoMoveField2

	clr.l 	Time2
	
	

	cmp.b #1,ScrollDirection2
	bne .LeftDirection2
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.RightDirection2	

	move.b PowerSpeed2,d1
	sub.b  d1,DelayS2
	move.b DelayS2,d0
	cmp.b #$20,d0
	bcs .enddelay2		; Branch if less unsigned
	add.b #$10,DelayS2

;Move Scroll by n

	cmp.b #1,Intro
	beq .Intro_NoWriteMap
	
;Write hide 16bits block right
	jsr WriteMap
	
	
.Intro_NoWriteMap

	add.w	#2,Scroll2

	move.w  Scroll2,d0
	cmp.b	#38,d0
	bne.b	.noStartScroll2

	move.w	#-2,Scroll2
	
	jmp .noStartScroll2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.LeftDirection2	

	move.b PowerSpeed2,d1
	add.b  d1,DelayS2
	move.b DelayS2,d0
	cmp.b #$10,d0
	blt .enddelay2		; Branch if less unsigned
	sub.b #$10,DelayS2

;Move Scroll by n

	cmp.b #1,Intro
	beq .Intro_NoWriteMap2
	
;Write hide 16bits block right
	jsr WriteMap
	
	
.Intro_NoWriteMap2

	sub.w	#2,Scroll2

	move.w  Scroll2,d0
	cmp.w	#-2,d0
	bne.b	.noStartScroll2

	move.w	#38,Scroll2
	
	jmp .noStartScroll2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	
.noStartScroll2:

	lea Foreground,a0	;ptr to first bitplan of logo
	lea CopBplP,a1	;where to poke the bitplane pointer words
	move #3-1,d0
.bpll2:
	move.l	a0,d1
	add.w	Scroll2,d1
	swap d1
	move.w d1,2(a1) 
	swap d1
	move.w d1,6(a1)

	add	#16,a1		;point to next bpl to poke in copper
	lea PictureBpl(a0),a0
	dbf d0,.bpll2

.enddelay2

;Change Delay register

	move.b DelayS1,d0
	move.b DelayS2,d1
	rol.b #4,d0
	add.b d1,d0
	
	lea Delay,a0
	move.b d0,3(a0)
	move.b #0,2(a0)


.NoMoveField2
;End Scroll Bitplane 2

	rts
******************************************************************************************************
******************************************************************************************************
******************************************************************************************************	
	
CopyColors:
	
.loop_reset_color
	move.l (a1),(a0)
	add.l #4,a0
	add.l #4,a1

	sub.b #1,d0
	cmp.b #0,d0
	bne .loop_reset_color	
	
	rts
	
****************************************************************************************
****************************************************************************************	
;d0=initial column
;d1=final column
EraseBackground:
****************************************************************************************

	
	move.w d1,d6

.loop_erase_columns
		
	move.w #13,d2

.loop_erase_rows
	

	move.l  #(16*80*3),d1
	mulu    d2,d1
	add d6,d1
	
;	add.w #1,d1
;	add.w Scroll2,d1
	move.l d1,Offset
	bsr WriteBlack	   ; Erase!!!!
	
;	add.l #40,Offset
;	bsr WriteBlack	   ; Erase!!!!
	
	sub.w #1,d2
	cmp #1,d2
	bgt .loop_erase_rows
	
	
	sub.w #1,d6
	cmp d0,d6
	bgt .loop_erase_columns
	
	rts
	

****************************************************************************************	
	
;d0=x
;d1=y
;a0=text direction
	
WriteText:
****************************************************************************************	

	PUSH_ALL
.Charloop

	clr.l d2
	move.b (a0),d2
	cmp.b #0,d2
	beq.b .endtext
	jsr WriteChar
	add #1,a0
	add #2,d0
	jmp .Charloop

.endtext
	
	POP_ALL
	rts

****************************************************************************************	
	
;d0=x
;d1=y
;d2=character
WriteChar:

	PUSH_ALL

	
; Example
; With x height x planes  (pixels)  
; 256 x 64 x 3
;  32b x 64 x 3  (bytes)
;;;;;;; Mod origen=16 + 16 + 16 - (16)  = 32
;Mod origen=30 + 32 + 32  = 94
; Mod destino=80 + 80 + 80 - (2)
; Increment plane = 32
; Size=height*64 + width in words
; Size=16*64 (lines) + 2/2 (bytes/2  1plane)	
	


; d0=x
; d1=y
; d2=mod_orig
; d3=mod_dest
; d4=layers
; d5=increment plane original
; d6=increment plane dest
; d7=size register
; a4=Origin plane 0 base address
; a5=Destination plane 0 base address


;d2=character code

	sub.b #FirstCharacter,d2
	
	
	lea  		Fonts,a4
	lea  		Foreground,a5

	
	movem.l d0-d7,-(sp)
	
;<------------------------------------

	clr.l d0
	clr.l d1

	
	divu.w #16,d2
	
	move.w d2,d1
	swap d2
	move.w d2,d0
	
	muls #32*16*3,d1
	muls #2,d0
	add.w d1,d0

	add.l 		d0,a4
;<------------------------------------
	
	movem.l (sp)+,d0-d7
	
	
	move.l      #32+32+32-2,d2
	move.l      #80+80+80-2,d3
	move.l      #3,d4
	move.l 		#32,d5
	move.l 		#80,d6
	move.l 		#64*16+1,d7




;d0 and d1 are defined


	jsr Sub_Paint

	POP_ALL

	rts
****************************************************************************************	
	
WriteRanking:

;	move.w #6,d0
;	move.w #3,d1
;	lea Text1,a0	
;	jsr WriteText	
	
	move.b #10,d7
	
	lea Ranking,a0
	move.l #3,d1  ;  (y)
	
.loop_rank
	move.l #4,d0  ; (x)

	PUSH_ALL
	jsr WriteText
	POP_ALL
	
	add.l #18,a0 ; Set to next line in buffer
	add.w #1,d1 ; Next line in screen
	sub.w #1,d7 ; Principal loop
	
	cmp.b #0,d7
	bne .loop_rank
	
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LoadImages
; d0=1111 BACKGROUND LEFT/RIGHT FOREGROUND LEFT/RIGHT


	
LoadImages:

; Example
; With x height x planes  (pixels)
; 320 x 256 x 3
; 40b x 256 x 3
; 40b x 256 x 3  (bytes)
; Mod origen=40 + 40 + 40 - (40)  = 80

; Mod destino=80 + 80 + 80 - (40)
; Size=height*64 + width in words
; Size=256*64 (lines) + 40/2 (bytes/2  1plane)


; d0=x
; d1=y
; d2=mod_orig
; d3=mod_dest
; d4=layers
; d5=increment plane original
; d6=increment plane dest
; d7=size register
; a4=Origin plane 0 base address
; a5=Destination plane 0 base address



	move.l       #80,d2
	move.l #240-(40),d3
	move.l        #3,d4
	move.l 		 #40,d5
	move.l 		 #80,d6
	move.l #64*256+20,d7
	lea  		Background_load,a4
	lea  		Background,a5

	
	move.l        #0,d0
	move.l        #0,d1	
	
	btst #0,vLoadImages
	beq.b .s1
	jsr Sub_Paint
.s1


	move.l        #40,d0
	
	btst #1,vLoadImages
	beq.b .s2
	jsr Sub_Paint
.s2

	
	lea  		Foreground_load,a4
	lea  		Foreground,a5

	move.l        #0,d0
	move.l        #0,d1	

	btst #2,vLoadImages
	beq.b .s3
	jsr Sub_Paint
.s3	
	

	move.l        #40,d0
	btst #3,vLoadImages
	beq.b .s4
	jsr Sub_Paint
.s4

	rts
	
****************************************************************************************	
;d0=initial column
;d1=final column
CleanBitplane:
****************************************************************************************

	
	move.w d1,d6

.loop_erase_columns
		
	move.w #15,d2

.loop_erase_rows
	

	move.l  #(16*80*3),d1
	mulu    d2,d1
	add d6,d1
	

	move.l d1,Offset
	bsr WriteBlackBackground	   ; Erase!!!!

	
	sub.w #1,d2
	cmp #-1,d2
	bgt .loop_erase_rows
	
	
	sub.w #1,d6
	cmp d0,d6
	bgt .loop_erase_columns
	
	rts

	
WriteBlackBackground:

;Blitter control to copy Pieces to bitplane

	movem.l d0-d7/a0-a6,-(sp)

	lea $dff000,a6
	bsr BlitWait	

	move.w Offset,d0

	move.l #$09f00000,BLTCON0(a6)
	move.l #$ffffffff,BLTAFWM(a6)

	move.w #0+os,BLTAMOD(a6)
	move.w #238,BLTDMOD(a6)
	move.l #Black,bltapt(a6)

	move.l #Background,d1
	add.l Offset,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

	bsr BlitWait
	move.l #Black+2,bltapt(a6)
	add.l #80,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)

	bsr BlitWait	
	move.l #Black+4,bltapt(a6)
	add.l #80,d1
	move.l d1,bltdpt(a6)
	move.w #1+16*64,BLTSIZE(a6)
	
	movem.l (sp)+,d0-d7/a0-a6

	rts		
	

****************************************************************************************	
****************************************************************************************	
PaintScore:
****************************************************************************************	
****************************************************************************************
	
	clr d0
	move.b Lives,d0
	
	divu #10,d0
	
	move.b d0,LivesAscii
	add.b  #48,LivesAscii
	
	swap d0

	move.b d0,LivesAscii+1
	add.b  #48,LivesAscii+1

	
	
	rts

****************************************************************************************	


****************************************************************************************	
****************************************************************************************	
PaintAnyAscii:
****************************************************************************************	
; word d0=integer
; byte d1=positions
; a0=position ascii
****************************************************************************************

	add d1,a0
	sub #1,a0
	
.loop
	
	divu.w #10,d0
	swap d0
	move.b d0,(a0)
	add.b  #48,(a0)

	clr.w d0	
	swap d0

	sub.w #1,a0

	sub.b #1,d1
	cmp.b #0,d1

	bne .loop
	
	rts





Sub_IntroLoop_right:
.loop1

	
	jsr IntroKeyControl
	cmp.b #0,IntroKeyPressed
	bne.b .AbortLoop
	
	PUSH_ALL	
	jsr FrameWait
	jsr Parallax
	
	
	bsr WritePosition
	bsr BreathControl
	
	bsr MoveSprite

	POP_ALL

	add.b d1,TomPos_old+1	
	sub.w #1,d0
	cmp.w #0,d0
	bne.b .loop1

.AbortLoop
	rts
****************************************************************************************	
****************************************************************************************	
Sub_IntroLoop_right_desc:
.loop1

	jsr IntroKeyControl
	cmp.b #0,IntroKeyPressed
	bne.b .AbortLoop


	PUSH_ALL
	jsr FrameWait
	jsr Parallax
	
	
	bsr WritePosition
	bsr BreathControl
	bsr MoveSprite
	POP_ALL
	
	move.l #0,d3
	move.w d0,d3
	divu.w #10,d3
	swap d3
	cmp.w #0,d3
	bne.b .NoMod
	
;	sub.b #1,PowerSpeed1  
	sub.b #1,PowerSpeed2

  

.NoMod

	add.b d1,TomPos_old+1	
	sub.w #1,d0
	cmp.w #0,d0
	bne.b .loop1

.AbortLoop
	rts
	
	
****************************************************************************************	
IntroKeyControl:
********************************************************************************************
	
	PUSH_ALL
	move.b #0,IntroKeyPressed

	move.b  $bfec01,d0      ;Get 'encoded' key that pressed
    ror.b   #1,d0
    not.b   d0

	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke space to jump
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp.b   #$40,d0	        ;Check for $40 = Space key
	bne.b .noSpacePress
	move.b #1,IntroKeyPressed
.noSpacePress
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Detect Keystroke ESC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp.b   #$45,d0	        ;Check for $45 = ESC
	bne.b .noESCPress
	move.b #1,IntroKeyPressed	
	move.b #1,vEXIT
.noESCPress:

	POP_ALL
	rts

	
	
;aqui	
	
;-----------------------------------------------------------------------------
;
;out
;a6	dt
;
DoVariables:
;		lea	dt(pc),a6
		lea dt,a6
		

	;clear dt
		move.l	a6,a0
		moveq	#0,d0
		move.w	#dt_SIZEOF/4-1,d1
.clear		move.l	d0,(a0)+
		dbf	d1,.clear


	;store old stack pointer
		lea	4(a7),a0
		move.l	a0,oldStack(a6)

		rts	
	
	
Playrtn:
	include "P6109-Play.i"	
	
	
	
	
	
****************************************************************************************
********** DATASECTION **********	
****************************************************************************************


dt:		ds.b	dt_SIZEOF

	section	"CHIPDATA",data_c


IntroKeyPressed:
	dc.b	0,0

stage1_address:
	dc.l	0
stage2_address:
	dc.l	0
stage3_address:
	dc.l	0
;current_stage:
;	dc.l	0
;my_stage:
;	dc.b	0,0
	
;testing
current_stage:
	dc.l	0   ;  4=stage1
my_stage: 
	dc.b	0,0 ; 1,1=stage 1
	
	
	
PowerSpeed1:
	dc.b 1,0
PowerSpeed2:
	dc.b 4,0,0,0,0,0

SpeedScroll1:	
	dc.w 1
SpeedScroll2:
	dc.w 1
	
	
vEXIT:
	dc.b 0,0
vEndReached:
	dc.b 0,0
	
vLoadImages:
	dc.b 0,0
	
	
Speed:
	dc.b 0
Jumping:
	dc.b 0
JumpStart:
	dc.b  -8
JumpEnd:
	dc.b 7
JumpSleep:
	dc.w  0
BreathSleep:
	dc.w  0
DustSleep:
	dc.w  0
Time:	
	dc.l 1
Time2:	
	dc.l 1
Offset:
	dc.l 0

DelayS1:
	dc.b $0f,0
DelayS2:
	dc.b $0f,0

GravityForce:
	dc.b $0,$0

GravitySleep:
	dc.b $0,$0

IMDOWN:
	dc.b $0,$0
	
	
Scroll:
	dc.w 0,0,0,0
Scroll2:
	dc.w 0,0,0,0

myblock:
	dc.b 15,0	

;Exit when ControlCounter > value
ControlCounter:
	dc.w 0
	
OnPlatform:
	dc.b 0,0
	
Intro:
	dc.b 1,0
IntroLoop:
	dc.b 1,0
IntroPos:
	dc.b 1,0
ScrollDirection1:
	dc.b 1,0
ScrollDirection2:
	dc.b 1,0
	
gfxname:
	dc.b "graphics.library",0

	EVEN

CollisionControl:
FeetSpr:
	dc.w $0050,$0000	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH

	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %1111111111111111,%1111111111111111
	dc.w %1111111111111111,%1111111111111111
	dc.w %1111111111111111,%1111111111111111
	dc.w %1111111111111111,%1111111111111111
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000000000000000
	dc.w 0,0


Spr2:
	dc.w $5c58,$6c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0110011111001100,%0001100000110000
	dc.w %1110011111001110,%0001100000110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0000000000000000
	dc.w %1111111111111110,%0000011111000000
	dc.w %1111111111111110,%0001100000110000
	dc.w %0111111111111100,%0011000000011000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w 0,0


CollisionYES:
	dc.w $5c48,$6c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w 0,0	
	
CollisionNO:
	dc.w $5c48,$6c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000000000000000,%0000011111000000
	dc.w %0000000000000000,%0001111111110000
	dc.w %0000000000000000,%0011111111111000
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%0011111111111000
	dc.w %0000000000000000,%0001111111110000
	dc.w %0000000000000000,%0000011111000000
	dc.w 0,0	

PlatformNO:
	dc.w $5c50,$6c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w 0,0	
	
PlatformYES:
	dc.w $5c50,$6c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %1111111111111111,%1111111111111111
	dc.w %0000000000000000,%0000011111000000
	dc.w %0000000000000000,%0001111111110000
	dc.w %0000000000000000,%0011111111111000
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%1111111111111110
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%0111111111111100
	dc.w %0000000000000000,%0011111111111000
	dc.w %0000000000000000,%0001111111110000
	dc.w %1111111111111111,%1111111111111111
	dc.w 0,0	
	
	
	
	
;CollisionControl:
SprCollision:
	dc.w $5c88,$6c00	;Vstart.b,Hstart/2.b,Vstop.b,%A0000SEH
	dc.w %0000000000000000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0001111111110000
	dc.w %1111111111111110,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0111111111111100,%0000000000000000
	dc.w %0011111111111000,%0000000000000000
	dc.w %0001111111110000,%0000000000000000
	dc.w %0000011111000000,%0000000000000000
	dc.w 0,0	

	
v_YouAreDeath:
	dc.b 0,0
v_DeathInProgress:
	dc.b 0,0

TomPos:
;	dc.w $8c60,$9c80
	dc.l TomPosInit
TomPos_old:
	dc.l TomPosInit
TomPosY:
	dc.w $0
TomPosY_old:
	dc.w $0
	
	
TomCustome:
	dc.w	$0
TomCustomeBreath:
	dc.w	$1
TomCustomeBreathDirection:
	dc.w    $1
TomCustomeDust:
	dc.w	$3
TomCustomeDustDirection:
	dc.w    $1
	
GameMode:
	dc.w    $0
	
SpacePressed:
	dc.w    $0
	
Tom:


;	dc.w $5080,$6006 <--- Position high
;	dc.w $d060,$e000
	dc.w $0000,$0000
	dc.w $0000,$ffff,$0000,$ffff,$1ffe,$e001,$3ffe,$c001
	dc.w $3ffe,$c319,$7ffe,$8319,$7ffe,$8001,$5ffe,$a009
	dc.w $1ffe,$e211,$1ffe,$e221,$1ffe,$e1c1,$1ffe,$e001
	dc.w $1ffe,$e001,$0000,$ffff,$0000,$ffff,$0000,$ffff
	dc.w 0,0

Tom2:
	dc.w $0000,$0000
	dc.w $0000,$ffff,$00e0,$ff1f,$0078,$ff87,$1ffc,$e003
	dc.w $1ffc,$e003,$1ffc,$e003,$1ffc,$e333,$1ffc,$e433
	dc.w $1ffc,$e403,$1ffc,$e403,$1ffc,$e203,$1ffc,$e133
	dc.w $1ffc,$e0b3,$1ffc,$e003,$1ffc,$e003,$0000,$ffff
	dc.w 0,0

Tom3:
	dc.w $0000,$0000
	dc.w $0000,$ffff,$0000,$ffff,$0000,$ffff,$7ff8,$8007
	dc.w $7ff8,$8007,$7ff8,$8387,$7ff8,$8447,$7ff8,$8847
	dc.w $7ffa,$9005,$7ffe,$8001,$7ffe,$98c1,$7ffc,$98c3
	dc.w $7ffc,$8003,$7ff8,$8007,$0000,$ffff,$0000,$ffff
	dc.w 0,0

Tom4:
	dc.w $0000,$0000
	dc.w $0000,$ffff,$3ff8,$c007,$3ff8,$c007,$3ff8,$cd07
	dc.w $3ff8,$cc87,$3ff8,$c047,$3ff8,$c027,$3ff8,$c027
	dc.w $3ff8,$cc27,$3ff8,$ccc7,$3ff8,$c007,$3ff8,$c007
	dc.w $3ff8,$c007,$1e00,$e1ff,$0700,$f8ff,$0000,$ffff
	dc.w 0,0


Bitplane1_pallete_orig:
	dc.w $0190,$0000,$0192,$0fff,$0194,$0fff,$0196,$0c0c
	dc.w $0198,$0808,$019a,$0fff,$019c,$0000,$019e,$0fff


Bitplane1_pallete_alt:
	dc.w $0190,$0000,$0192,$0111,$0194,$0222,$0196,$0333
	dc.w $0198,$0444,$019a,$0555,$019c,$0666,$019e,$0777
	
	
NullSpr:
	dc.w $2a20,$2b00
	dc.w 0,0
	dc.w 0,0




MyCopper:
	dc.w $1fc,0			;slow fetch mode, AGA compatibility
	dc.w $92,$28
	dc.w $94,$d0

;Start Stop Window
	dc.w $8e,$2c91
	dc.w $90,$2ca1

	dc.w $108,196
	dc.w $10a,196

Delay:
	dc.w $102,$ff


	
	
;	Sprites colors Tom

	dc.w $01a0,$0000,$01a2,$0f00,$01a4,$0555,$01a6,$0ff0
	dc.w $01a8,$0090,$01aa,$03f1,$01ac,$000f,$01ae,$02cd	
	dc.w $01b0,$0ef7,$01b2,$0740,$01b4,$0950,$01b6,$0b60	
	dc.w $01b8,$0f80,$01ba,$0fa0,$01bc,$0888,$01be,$06bb

	
;	dc.w $01c0,$0000,$01c2,$0f00,$01c4,$0555,$01c6,$0ff0	
;	dc.w $01c8,$0090,$01ca,$03f1,$01cc,$000f,$01ce,$02cd	
;	dc.w $01d0,$0ef7,$01d2,$0740,$01d4,$0950,$01d6,$0b60	
;	dc.w $01d8,$0f80,$01da,$0fa0,$01dc,$0888,$01de,$06bb

;	dc.w $0180,$0000,$0182,$0420,$0184,$0740,$0186,$0530          ;;;; DUST COLORS
;	dc.w $0180,$0000,$0182,$0420,$0184,$0740,$0186,$0530
;	dc.w $0180,$0000,$0182,$0420,$0184,$0740,$0186,$0530
;	dc.w $0180,$0000,$0182,$0420,$0184,$0740,$0186,$0530


;	dc.w $0180,$0000,$0182,$0420,$0184,$0740,$0186,$0530

	
SprP1a:	dc.w $120,0
SprP1b:	dc.w $122,0
SprP2a:	dc.w $124,0
SprP2b:	dc.w $126,0
SprP3a:	dc.w $128,0
Sprp3b:	dc.w $12a,0
SprP4a:	dc.w $12c,0
Sprp4b:	dc.w $12e,0
SprP5a:	dc.w $130,0
Sprp5b:	dc.w $132,0
SprP6a:	dc.w $134,0
Sprp6b:	dc.w $136,0
SprP7a:	dc.w $138,0
Sprp7b:	dc.w $13a,0
SprP8a:	dc.w $13c,0
Sprp8b:	dc.w $13e,0






CopBplP:
	dc.w $e0,0
	dc.w $e2,0
	dc.w $e4,0
	dc.w $e6,0
	dc.w $e8,0
	dc.w $ea,0

	dc.w $ec,0
	dc.w $ee,0
	dc.w $f0,0
	dc.w $f2,0
	dc.w $f4,0
	dc.w $f6,0
		
	dc.w $180,$349
	dc.w $2b01,$fffe
	dc.w $180,$56c
	dc.w $2c01,$fffe

LogoPal:


;	dc.w $0180,$0000,$0182,$0fff,$0184,$0fff,$0186,$00f0
;	dc.w $0188,$0808,$018a,$0fff,$018c,$0000,$018e,$0fff

Bitplane1_pallete:
	dc.w $0190,$0000,$0192,$0fff,$0194,$0fff,$0196,$0c0c
	dc.w $0198,$0808,$019a,$0fff,$019c,$0000,$019e,$0fff


;Top window
Bitplane2_pallete:
	dc.w $0180,$0000,$0182,$0fff,$0184,$0ddd,$0186,$0aaa
	dc.w $0188,$0777,$018a,$0444,$018c,$0333,$018e,$0111




;Definition of 3 bitplanes 8 colors
;$100 is _BPLCON0

;	2 Playfields with 3 bitplanes each
;	dc.w $100,$6600
;	dc.w $100,$6600

Activate_bitplanes:
;	dc.w $100,$6600
	dc.w $100,$6600

;             0110 0110 0000 0000	
	
;Priority
;             %xxxxyyyyaaaabbbb
;	dc.w $104,%0000000000110000   

;	dc.w $104,%0000000000001000  ; Correct sprites
;   dc.w $104,%0000000000011000  ; Debug sprites
;	dc.w $104,%0000000000011100  ; Debug sprites 2  (sprites priority over playfields)

	dc.w $104,%0000000000010000  ; Debug sprites
	
	


	dc.w $4c07,$fffe


;Medium window
PiecesColors:
;	dc.w $0180,$0000,$0182,$007c,$0184,$0b9d,$0186,$022f
;	dc.w $0188,$000f,$018a,$000c,$018c,$0009,$018e,$0006

	dc.w $0180,$0fff,$0182,$004a,$0184,$0e22,$0186,$036b
	dc.w $0188,$079c,$018a,$0faa,$018c,$0abd,$018e,$0ff4

;	dc.w $0180,$0fff,$0182,$004a,$0184,$079c,$0186,$036b
;	dc.w $0188,$0e22,$018a,$0faa,$018c,$0abd,$018e,$0ff4


;Bottom window
;	dc.w $ff07,$fffe
	dc.w $ffdf,$fffe

	dc.w $0c07,$fffe
	dc.w $0180,$0000,$0182,$0f00,$0184,$0d00,$0186,$0b00
	dc.w $0188,$0900,$018a,$0700,$018c,$0400,$018e,$0100



	dc.w $2c07,$fffe
	dc.w $180,$56c
	dc.w $2d07,$fffe
	dc.w $180,$349
 
	dc.w $ffff,$fffe

	CNOP 0,4
Background:
	blk.b 640/8*256*3,0
	CNOP 0,4
Foreground:
	blk.b 640/8*256*3,0


	CNOP 0,4  
Background_load:
	INCBIN "fondo_320x256x3.blit"

	CNOP 0,4
Foreground_load:
	INCBIN "front_320x256x3.blit"	
	
	
	CNOP 0,4
;Pieces:
	INCBIN "patterns.outline"

Black:
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	dc.w $0000,$0000,$0000
	
;Window position of the stage to write
StageWindowPointer:
		dc.w $1

;Memory position of the stage to read
StageMemoryPointer:
		dc.w $0
		
BlockType dc.b $0,$0
		

		
;;;;; test only
Stage1:
	INCLUDE "stage_0001.dat"
Stage2:
	INCLUDE "stage_0002.dat"
Stage3:
	INCLUDE "stage_0003.dat"


Tom_1:
	dc.w $0000,$0000
	dc.w $fb00,$04ff,$a01f,$5fff,$4fff,$bfff,$9e00,$7e00
	dc.w $1084,$f000,$9000,$7000,$7000,$b000,$b020,$7020
	dc.w $c020,$0020,$4000,$0000,$43fe,$0000,$51fc,$0000
	dc.w $a0f0,$0000,$10e0,$0000,$28e1,$0000,$0003,$0000
	dc.w 0,0

Tom_2:
	dc.w $0000,$0000
	dc.w $0000,$ffff,$0000,$ffff,$0000,$ffff,$01ff,$ffff
	dc.w $0e73,$ff7b,$0e73,$ffff,$0fff,$ffff,$0fdf,$ffff
	dc.w $ffdf,$ffff,$ffff,$ffff,$fc01,$ffff,$fe03,$ff07
	dc.w $ff0f,$ff8f,$ff1f,$ff1f,$ff1f,$ff1f,$ffff,$ffff
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$f000,$0000,$a01f,$5fff
	dc.w $4fff,$bfff,$9e00,$7e00,$108c,$f008,$900c,$700c
	dc.w $7000,$b000,$b020,$7020,$c020,$0020,$4020,$0000
	dc.w $a0fc,$0000,$107c,$0000,$2809,$0000,$0003,$0000
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$f000,$0000,$ffff
	dc.w $0000,$ffff,$01ff,$ffff,$0e7b,$ff7b,$0e7f,$ffff
	dc.w $0fff,$ffff,$0fdf,$ffff,$ffdf,$ffff,$ffdf,$ffff
	dc.w $ff03,$ff83,$ff83,$ffc3,$fff7,$fff7,$ffff,$ffff
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$bfff,$4000,$a000,$5fff,$403f,$bfff
	dc.w $9e00,$7e00,$9084,$7000,$7000,$b000,$b020,$7020
	dc.w $c020,$0020,$1018,$0000,$28f1,$0000,$0003,$0000
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$ffff,$0000,$ffff,$0000,$ffff
	dc.w $01ff,$ffff,$0e73,$ff7b,$0fff,$ffff,$0fdf,$ffff
	dc.w $ffdf,$ffff,$ffe7,$ffff,$ff0f,$ffff,$ffff,$ffff
	dc.w 0,0

	
Death_1:
	dc.w $0000,$0000
	dc.w $8ff8,$7007,$0ff8,$f007,$07fc,$f803,$07ff,$f800
	dc.w $0fff,$f000,$0fff,$f000,$0fff,$f000,$0fff,$f000
	dc.w $7fff,$0000,$37ff,$0000,$3fff,$0000,$2bfb,$0404
	dc.w $3bfb,$0404,$5fff,$0000,$5fff,$0000,$2fff,$0000
	dc.w 0,0

Death_2:	
	dc.w $0000,$0000
	dc.w $0ff8,$f007,$0ff8,$f007,$07fc,$f803,$07ff,$f800
	dc.w $0fff,$f000,$0f77,$f000,$0e23,$f002,$0f77,$f000
	dc.w $ffff,$0000,$ffff,$0000,$fc07,$03f8,$f9f3,$060e
	dc.w $fbf3,$040c,$ffff,$0000,$ffff,$0840,$ffff,$0000
	dc.w 0,0

;;;;;;;;;;;;;;;;;;;;; 4 Sprites for jumping ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,

Tom_1_Jumping:
	dc.w $0000,$0000
	dc.w $fd80,$027f,$d00f,$2fff,$27ff,$dfff,$cf00,$3f00
	dc.w $08c6,$f884,$c8c6,$38c6,$3800,$d800,$d810,$3810
	dc.w $e010,$0010,$2000,$0000,$21ff,$01ff,$28fe,$0082
	dc.w $d07e,$0040,$081e,$0000,$1404,$0000,$8001,$0000
	dc.w 0,0

Tom_2_Jumping:
	dc.w $0000,$0000
	dc.w $0000,$ffff,$0000,$ffff,$0000,$ffff,$00ff,$ffff
	dc.w $07bd,$ffbd,$07ff,$ffff,$07ff,$ffff,$07ef,$ffff
	dc.w $ffef,$ffff,$ffff,$ffff,$fe00,$ffff,$ff01,$ff83
	dc.w $ff81,$ffc1,$ffe1,$ffe1,$fffb,$fffb,$7fff,$ffff
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $08d5,$002a,$11ab,$0054,$0f45,$00ba,$50c3,$00fc
	dc.w $28f9,$00fe,$400d,$000e,$000c,$000f,$040d,$040e
	dc.w $0c35,$0c36,$1c34,$1427,$1c04,$0407,$3d84,$0587
	dc.w $3c06,$0407,$7c36,$0437,$3c36,$0c27,$0406,$0407
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $ff80,$ffff,$ff00,$ffff,$ff00,$ffff,$ff00,$ffff
	dc.w $ff00,$ffff,$fff0,$ffff,$fff0,$ffff,$fbf0,$ffff
	dc.w $f3f8,$ffff,$e3e8,$f7ef,$e3f8,$e7ff,$c278,$c7ff
	dc.w $c3f8,$c7ff,$83f8,$87ff,$c3e8,$cfef,$fbf8,$ffff
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $6000,$0000,$c000,$0000,$9014,$0000,$3c08,$0000
	dc.w $3f05,$0100,$3f8a,$2080,$7fc2,$7fc0,$0002,$0000
	dc.w $0403,$0400,$040d,$040e,$000e,$000d,$3189,$318e
	dc.w $3188,$108f,$0079,$007e,$fff2,$fffd,$f805,$fffa
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $ffff,$ffff,$ffff,$ffff,$efff,$efff,$c3ff,$c3ff
	dc.w $c0ff,$c1ff,$c07f,$e0ff,$803f,$ffff,$ffff,$ffff
	dc.w $fbff,$ffff,$fbf0,$ffff,$fff0,$ffff,$fff0,$ffff
	dc.w $def0,$deff,$ff80,$ffff,$0000,$ffff,$0000,$fff
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $b001,$7000,$6003,$e000,$e021,$6020,$6c3c,$e430
	dc.w $ec3e,$6c20,$e03c,$6020,$a1bc,$61a0,$a038,$6020
	dc.w $6c38,$a428,$ac30,$6c30,$b020,$7020,$3000,$f000
	dc.w $b002,$7000,$9f14,$7f00,$c30a,$3f00,$a2f0,$5d00
	dc.w 0,0

	dc.w $0000,$0000
	dc.w $0fff,$ffff,$1fff,$ffff,$1fdf,$ffff,$17c3,$f7f3
	dc.w $1fc1,$ffe1,$1fc3,$ffe3,$1e43,$ffe3,$1fc7,$ffe7
	dc.w $17c7,$f7ef,$1fcf,$ffff,$0fdf,$ffff,$0fff,$ffff
	dc.w $0fff,$ffff,$00ff,$ffff,$00ff,$ffff,$00ff,$ffff
	dc.w 0,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;Pieces:
	dc.w $8000,$7fff,$c001,$bffe,$e003,$dffc,$f007,$eff8
	dc.w $f80f,$f7f0,$fc1f,$fbe0,$fe3f,$fdc0,$ff7f,$fe80
	dc.w $ffff,$ff00,$ff7f,$fe00,$fe3f,$fc00,$fc1f,$f800
	dc.w $f80f,$f000,$f007,$e000,$e003,$c000,$c001,$8000

	dc.w $8000,$0000,$4001,$0000,$2002,$0000,$1004,$0000
	dc.w $0808,$0000,$0410,$0000,$0220,$0000,$0140,$0000
	dc.w $0080,$0000,$01c0,$0000,$03e0,$0000,$07f0,$0000
	dc.w $0ff8,$0000,$1ffc,$0000,$3ffe,$0000,$7fff,$0000

	dc.w $ffff,$ffff,$8001,$ffff,$a001,$dfff,$b005,$effb
	dc.w $b80d,$f7f3,$bc1d,$fbe3,$be3d,$fdc3,$bf7d,$fe83
	dc.w $bffd,$ff03,$bf7d,$fe03,$be3d,$fc03,$bc1d,$f803
	dc.w $b80d,$f003,$b005,$e003,$8001,$ffff,$ffff,$ffff

	dc.w $ffff,$0000,$ffff,$0000,$e003,$0000,$d007,$0000
	dc.w $c80b,$0000,$c413,$0000,$c223,$0000,$c143,$0000
	dc.w $c083,$0000,$c1c3,$0000,$c3e3,$0000,$c7f3,$0000
	dc.w $cffb,$0000,$dfff,$0000,$ffff,$0000,$ffff,$0000

	dc.w $0180,$0180,$0000,$0180,$0240,$03c0,$0000,$03c0
	dc.w $0420,$07e0,$0000,$07e0,$0a10,$0df0,$0740,$0eb0
	dc.w $1788,$1f78,$1748,$1e38,$2e24,$3c1c,$2c14,$380c
	dc.w $580a,$7006,$5002,$6006,$a001,$c003,$8001,$c003

	dc.w $0180,$0000,$0180,$0000,$03c0,$0000,$0240,$0000
	dc.w $0660,$0000,$0420,$0000,$0e30,$0000,$0950,$0000
	dc.w $1898,$0000,$19d8,$0000,$33ec,$0000,$37fc,$0000
	dc.w $6ffe,$0000,$7ffe,$0000,$ffff,$0000,$ffff,$0000

	dc.w $c000,$4000,$a000,$e000,$d000,$b000,$e800,$d800
	dc.w $d400,$cc00,$ea00,$e600,$f500,$f300,$fa80,$f980
	dc.w $fdc0,$fc40,$fe60,$fe20,$fe30,$ff90,$fc18,$ffc8
	dc.w $f80c,$ffe4,$f006,$fff2,$e003,$fff9,$c000,$ffff

	dc.w $c000,$0000,$6000,$0000,$7000,$0000,$3800,$0000
	dc.w $3c00,$0000,$1e00,$0000,$0f00,$0000,$0780,$0000
	dc.w $03c0,$0000,$01e0,$0000,$03f0,$0000,$07f8,$0000
	dc.w $0ffc,$0000,$1ffe,$0000,$3fff,$0000,$7fff,$0000

	dc.w $0003,$0002,$0005,$0007,$000b,$000d,$0017,$001b
	dc.w $002b,$0033,$0057,$0067,$00af,$00cf,$015f,$019f
	dc.w $03bf,$023f,$067f,$047f,$0c7f,$09ff,$183f,$13ff
	dc.w $301f,$27ff,$600f,$4fff,$c007,$9fff,$0003,$ffff

	dc.w $0003,$0000,$0006,$0000,$000e,$0000,$001c,$0000
	dc.w $003c,$0000,$0078,$0000,$00f0,$0000,$01e0,$0000
	dc.w $03c0,$0000,$0780,$0000,$0fc0,$0000,$1fe0,$0000
	dc.w $3ff0,$0000,$7ff8,$0000,$fffc,$0000,$fffe,$0000

	dc.w $4000,$0000,$2001,$4001,$5003,$6002,$2807,$3004
	dc.w $140f,$1808,$0a1f,$0c10,$053f,$0620,$02ff,$0340
	dc.w $017f,$0180,$00bf,$00c0,$005f,$0060,$002f,$0030
	dc.w $0017,$0018,$000b,$000c,$0005,$0006,$0003,$0003

	dc.w $7fff,$0000,$7fff,$0000,$7fff,$0000,$3fff,$0000
	dc.w $1fff,$0000,$0fff,$0000,$07ff,$0000,$03ff,$0000
	dc.w $01ff,$0000,$00ff,$0000,$007f,$0000,$003f,$0000
	dc.w $001f,$0000,$000f,$0000,$0007,$0000,$0003,$0000

	dc.w $8002,$8001,$c005,$c003,$e00a,$e006,$f014,$f00c
	dc.w $f828,$f818,$fc50,$fc30,$fea0,$fe60,$fd40,$fcc0
	dc.w $fa80,$f980,$f500,$f300,$ea00,$e600,$d400,$cc00
	dc.w $a800,$9800,$5000,$3000,$a000,$6000,$c000,$c000

	dc.w $ffff,$0000,$7fff,$0000,$3ffe,$0000,$1ffc,$0000
	dc.w $0ff8,$0000,$07f0,$0000,$03e0,$0000,$03c0,$0000
	dc.w $0780,$0000,$0f00,$0000,$1e00,$0000,$3c00,$0000
	dc.w $7800,$0000,$f000,$0000,$e000,$0000,$c000,$0000

	dc.w $8001,$c003,$a001,$c003,$5002,$6006,$580a,$7006
	dc.w $2c14,$380c,$2e24,$3c1c,$1748,$1e38,$1788,$1f78
	dc.w $0740,$0eb0,$0a10,$0df0,$0000,$07e0,$0420,$07e0
	dc.w $0000,$03c0,$0240,$03c0,$0000,$0180,$0180,$0180

	dc.w $ffff,$0000,$ffff,$0000,$7ffe,$0000,$6ffe,$0000
	dc.w $37fc,$0000,$33ec,$0000,$19d8,$0000,$1898,$0000
	dc.w $0950,$0000,$0e30,$0000,$0420,$0000,$0660,$0000
	dc.w $0240,$0000,$03c0,$0000,$0180,$0000,$0180,$0000

	dc.w $0003,$0003,$000c,$000f,$0032,$003c,$00cc,$00f8
	dc.w $0238,$03f0,$09f0,$0fe0,$23e0,$3dc0,$81c0,$fe80
	dc.w $8080,$ff00,$2140,$3e80,$0820,$0fc0,$0210,$03e0
	dc.w $00c8,$00f0,$0030,$003c,$000c,$000f,$0003,$0003

	dc.w $0003,$0000,$000f,$0000,$003f,$0000,$00f7,$0000
	dc.w $03cf,$0000,$0e1f,$0000,$3a3f,$0000,$e17f,$0000
	dc.w $e0ff,$0000,$397f,$0000,$0e3f,$0000,$03df,$0000
	dc.w $00ff,$0000,$003f,$0000,$000f,$0000,$0003,$0000

	dc.w $c000,$c000,$3000,$f000,$4c00,$3c00,$3300,$1f00
	dc.w $1c40,$0fc0,$0f90,$07f0,$07c4,$03bc,$0381,$017f
	dc.w $0101,$00ff,$0284,$017c,$0410,$03f0,$0840,$07c0
	dc.w $1300,$0f00,$0c00,$3c00,$3000,$f000,$c000,$c000

	dc.w $c000,$0000,$f000,$0000,$fc00,$0000,$ef00,$0000
	dc.w $f3c0,$0000,$f870,$0000,$fc5c,$0000,$fe87,$0000
	dc.w $ff07,$0000,$fe9c,$0000,$fc70,$0000,$fbc0,$0000
	dc.w $ff00,$0000,$fc00,$0000,$f000,$0000,$c000,$0000

	dc.w $0180,$0180,$0340,$03c0,$0720,$07e0,$0f10,$0ff0
	dc.w $1f08,$1ff8,$3f04,$3ffc,$7f02,$7ffe,$ff01,$ffff
	dc.w $80ff,$8001,$40fe,$4002,$20fc,$2004,$10f8,$1008
	dc.w $08f0,$0810,$04e0,$0420,$02c0,$0240,$0180,$0180

	dc.w $0180,$0000,$02c0,$0000,$04e0,$0000,$08f0,$0000
	dc.w $10f8,$0000,$20fc,$0000,$40fe,$0000,$80ff,$0000
	dc.w $ffff,$0000,$7ffe,$0000,$3ffc,$0000,$1ff8,$0000
	dc.w $0ff0,$0000,$07e0,$0000,$03c0,$0000,$0180,$0000

	dc.w $ffff,$ffff,$8081,$8001,$8081,$8001,$8081,$8001
	dc.w $8081,$8001,$8081,$8001,$8081,$8001,$80ff,$8001
	dc.w $ff01,$ffff,$8101,$8181,$8101,$8181,$8101,$8181
	dc.w $8101,$8181,$8101,$8181,$8101,$8181,$ffff,$ffff

	dc.w $ffff,$0000,$8181,$0000,$8181,$0000,$8181,$0000
	dc.w $8181,$0000,$8181,$0000,$8181,$0000,$ffff,$0000
	dc.w $80ff,$0000,$8081,$0000,$8081,$0000,$8081,$0000
	dc.w $8081,$0000,$8081,$0000,$8081,$0000,$ffff,$0000

	dc.w $ffff,$ffff,$c001,$ffff,$ffff,$e003,$f007,$f005
	dc.w $f80f,$f809,$fc1f,$8411,$8221,$fe3f,$ffff,$ffff
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

	dc.w $ffff,$0000,$ffff,$0000,$bfff,$0000,$9fff,$0000
	dc.w $8fff,$0000,$ffff,$0000,$ffff,$0000,$ffff,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0180,$0180,$0340,$03c0,$06a0,$0760,$0d50,$0e30
	dc.w $1aa8,$1c98,$3554,$39cc,$6aaa,$7366,$d5d5,$e633

	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0180,$0000,$03c0,$0000,$07e0,$0000,$0ff0,$0000
	dc.w $1f78,$0000,$3e3c,$0000,$7c1e,$0000,$f80f,$0000

	dc.w $a0a0,$0208,$4141,$0410,$a082,$8220,$5005,$4141
	dc.w $2808,$a082,$1410,$5005,$8a22,$2808,$4405,$1410
	dc.w $0882,$a808,$1140,$5005,$a2a0,$a082,$4551,$4141
	dc.w $0aa8,$0220,$1554,$0410,$aaaa,$0808,$4141,$0410

	dc.w $a802,$0000,$5005,$0000,$280a,$0000,$1414,$0000
	dc.w $0a28,$0000,$0550,$0000,$02a0,$0000,$0140,$0000
	dc.w $02a0,$0000,$0550,$0000,$0a28,$0000,$1414,$0000
	dc.w $a80a,$0000,$5005,$0000,$a002,$0000,$5005,$0000

	dc.w $ffff,$ffff,$9089,$8001,$a895,$9009,$c4a3,$b81d
	dc.w $a895,$9009,$9089,$8001,$8081,$8001,$80ff,$8001
	dc.w $ff01,$ffff,$8101,$8181,$9109,$8181,$a915,$9189
	dc.w $c523,$b99d,$a915,$9189,$9109,$8181,$ffff,$ffff

	dc.w $ffff,$0000,$8181,$0000,$8181,$0000,$8181,$0000
	dc.w $8181,$0000,$8181,$0000,$8181,$0000,$ffff,$0000
	dc.w $80ff,$0000,$8081,$0000,$8081,$0000,$8081,$0000
	dc.w $8081,$0000,$8081,$0000,$8081,$0000,$ffff,$0000

Bended_1:

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $403f,$bfff,$9e00,$7e00,$9088,$7000,$7000,$b000
	dc.w $b208,$7000,$0000,$0000,$00a0,$0000,$00e0,$0000
	dc.w 0,0

Bended_2:
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$ffff,$01ff,$ffff,$0e67,$ff77,$0fff,$ffff
	dc.w $0fff,$ffff,$ffff,$ffff,$ff5f,$ffff,$ff1f,$ffff
	dc.w 0,0

;;;; DUST AND FIRE	
	
	
Dust_1a:	
		
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0060,$0000
	dc.w $0070,$003c,$0028,$001a,$0056,$000e,$000b,$001f
	dc.w $0000,$0000

Dust_1b:
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$1000,$0000
	dc.w $1400,$0000,$0800,$0000,$16d0,$0010,$0728,$03f8
	dc.w $02d0,$01bc,$056c,$00fe,$00b6,$01fe,$000b,$001f
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $2000,$0000,$6c00,$0000,$5000,$0000,$39a0,$0020
	dc.w $5e70,$0350,$1de0,$0b38,$1ad8,$05bc,$157c,$03ec
	dc.w $02f4,$07dc,$01ac,$003c,$0014,$001c,$0000,$0010
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $2000,$0000,$6800,$0000,$5000,$0000,$3c00,$0000
	dc.w $4e00,$1600,$1d00,$0b00,$1a80,$0580,$0500,$1380
	dc.w $0280,$0780,$0500,$0000,$0000,$0100,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$1000,$0000
	dc.w $1400,$0000,$0880,$0000,$1600,$0000,$0740,$0180
	dc.w $0280,$0100,$0500,$0080,$0080,$0180,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$4000,$0000
	dc.w $2800,$0000,$1400,$0800,$1000,$0400,$1400,$0800
	dc.w $0800,$0400,$0001,$0003,$0003,$0006,$0002,$0003
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	

	
;;;; FIRE OF SUPERJUMP
Jump_1a:	
	dc.w $0000,$0000
	dc.w $0040,$0040,$00f0,$00b0,$0080,$0000,$0020,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
Jump_1b:	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	
	dc.w $0000,$0000
	dc.w $0040,$00c0,$00a0,$01f0,$03b0,$0370,$03e0,$0080
	dc.w $00e0,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	
	dc.w $0000,$0000
	dc.w $0100,$0700,$0ec0,$0fc0,$0ac0,$0d80,$1b60,$06e0
	dc.w $07e0,$1d00,$1980,$1780,$07c0,$0000,$0cc0,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$1c60,$1fc0
	dc.w $0378,$1df8,$2b70,$17b0,$243c,$1bf0,$3bfc,$00b0
	dc.w $1f9c,$0430,$1cfc,$0030,$07f8,$01e0,$03e0,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0100,$0000,$0b80,$0000,$1d80,$0040,$0850
	dc.w $1ca0,$3df0,$3a68,$1be0,$56fc,$2b60,$0eb8,$1f60
	dc.w $1ca8,$0940,$07f0,$0340,$03e0,$0080,$0000,$0000
	dc.w 0,0 
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$02a0,$1aa0
	dc.w $2040,$0ffc,$5809,$4ffb,$7a6b,$220e,$1152,$0003
	dc.w 0,0 
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	
	
;;;; FIRE OF FLYING
	
Flying_1a:	

	dc.w $0000,$0000
	dc.w $0180,$0080,$0080,$0000,$0100,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 

Flying_1b:	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0100,$0100,$0180,$0000,$03c0,$0180,$0080,$0000
	dc.w $0100,$0100,$0080,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0100,$0380,$0180,$0200,$0340,$0180,$03c0,$0100
	dc.w $02c0,$0140,$0130,$00a0,$02c0,$0000,$0400,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0140,$03e0,$0160,$0280,$0350,$01a0,$03b0,$0160
	dc.w $02a0,$0140,$0160,$00c0,$01e0,$0000,$02e0,$0000
	dc.w $0240,$0000,$0198,$0000,$04a8,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0000,$00c0,$00c0,$0368,$00e0,$0300,$00a0,$03f0
	dc.w $02b0,$0140,$03a8,$02d0,$03d8,$00b0,$0350,$00a0
	dc.w $0698,$00e0,$16fe,$0000,$0566,$0020,$0f2a,$0308
	dc.w $00c0,$0000,$0110,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0 	

	dc.w $0000,$0000
	dc.w $0000,$0000,$0180,$04d0,$03c0,$0680,$0040,$04e0
	dc.w $0560,$0280,$0710,$05c0,$0180,$0300,$0020,$01c0
	dc.w $1100,$0100,$0500,$0400,$0600,$0400,$0270,$0210
	dc.w $1000,$0080,$0020,$0100,$0000,$0000,$0000,$0000
	dc.w 0,0 

	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w 0,0
	
	
	
	
	
	
EmptySprite:
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000
	
	
	dc.w $0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
	dc.w $0000,$0000

IntroColors:
;;;;;;;	dc.w $0180,$0000,$0182,$004a,$0184,$0e22,$0186,$036b
;;;;;;;	dc.w $0188,$079c,$018a,$0faa,$018c,$0abd,$018e,$0ff4
;;;;;	dc.w $0180,$0000,$0182,$000f,$0184,$0e22,$0186,$000d	
;;;;;	dc.w $0188,$0009,$018a,$0900,$018c,$0006,$018e,$0ff4

	dc.w $0180,$0000,$0182,$004f,$0184,$0e22,$0186,$004d
	dc.w $0188,$0049,$018a,$0900,$018c,$0026,$018e,$0ff4
	
	
GameColors:
	dc.w $0180,$0000,$0182,$007c,$0184,$0b9d,$0186,$022f
	dc.w $0188,$000f,$018a,$000c,$018c,$0009,$018e,$0006

Fonts:
;	INCBIN "fonts_16x16x3.blit"
	INCBIN "fonts2_16x16x3.blit"

Pieces:
	INCBIN "pat5.blit"
CELogo:
	INCBIN "logoce2.blit"
;Aries24:
;	INCBIN "aries24.blit"
Presentation:
	INCBIN "presentation3_272x128x3.blit"


Text1:
	dc.b " SPECIAL EDITION",0	
Text2:
	dc.b "  RETROSEMANA",0	
Text3:
	dc.b "THANX 4 PLAYING!",0	

	EVEN

Text_Die:
	dc.b "YOU DIED",0	
GameOver:
	dc.b "GAME OVER",0	
PressKey:
	dc.b "  PRESS SPACE",0
Text_lives:
	dc.b "LIVES",0
	
	
Lives:
	dc.b $0,$0,$0,$0,$0,$0,$0
LivesAscii:
	dc.b $0,$0,$0,$0,$0,$0,$0
	EVEN

;Progress:
;	dc.b $0,$0,$0,$0,$0,$0,$0
ProgressAscii:
	dc.b $0,$0,$0,$0,$0,$0,$0
	EVEN


	

Ranking:
	dc.b "     RANKING     ",0
	dc.b "-----------------",0
	dc.b "          LVL DTH",0
	dc.b " COLPASUS  6   0 ",0
	dc.b " MEGAST64  5  11 ",0
	dc.b " SUPIVANSP 5  21 ",0
	dc.b " CARISUKA  5  31 ",0
	dc.b " CARLA     4  41 ",0
	dc.b " TELEMAKO  3  53 ",0
	dc.b " NOOB      0  99 ",0
	dc.b " TOM#2     0  99 ",0

p61copper:
	dc	$100,$0200
	dc	$180,$003
	dc	$800f,$fffe		;The line to wait to
	dc	$09c,$8010		;Set Copper-bit in INTREQ

	dc	$8b0f,$fffe
p61coppoke:
	dc	$096,$8000		;sound DMA poke address (in P61mode>=3)
	dc.w	$ffff,$fffe
    
Module1:
;	incbin "P61.sowhat-intro"			;usecode $9410
;	incbin "P61.new_ditty"				;CIA, usecode $c00b43b
;	incbin "P61.Dolphins"	;CIA, usecode $1006bf5f	
	incbin "P61.POPCORN.MOD"
;	incbin "P61.wobble2"

	