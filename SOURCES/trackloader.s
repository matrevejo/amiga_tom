ADKCON		equ $9E
ADKCONR		equ $10
BPL1MOD		equ $108
BPL1PTH		equ $E0
BPL1PTL		equ $E2
BPL2PTH		equ $E4
BPL2PTL		equ $E6
BPL3PTH		equ $E8
BPL3PTL		equ $EA
BPL4PTH		equ $EC
BPL4PTL		equ $EE
BPL5PTH		equ $F0
BPL5PTL		equ $F2
BPLCON0		equ $100
BPLCON1		equ $102
BPLCON2		equ $104
COLOR00		equ $180
COLOR01		equ $182
COLOR02		equ $184
COLOR03		equ $186
COLOR04		equ $188
COLOR05		equ $18A
COLOR06		equ $18C
COLOR07		equ $18E
COLOR16		equ $1A0
COLOR17		equ $1A2
COLOR18		equ $1A4
COLOR19		equ $1A6
COP1LCH		equ $80
COPJMP1		equ $88
DDFSTOP		equ $94
DDFSTRT		equ $92
DIWSTOP		equ $90
DIWSTRT		equ $8E
DMACON		equ $96
DMACONR		equ $02
DSKPTH		equ $20
DSKLEN		equ $24
DSKSYNC		equ $7E
INTENA		equ $9A
INTENAR		equ $1C
INTREQ		equ $9C
INTREQR		equ $1E
SPR0PTH		equ $120
SPR0PTL		equ $122
SPR1PTH		equ $124
SPR1PTL		equ $126
SPR2PTH		equ $128
SPR2PTL		equ $12A
SPR3PTH		equ $12C
SPR3PTL		equ $12E
SPR4PTH		equ $130
SPR4PTL		equ $132
SPR5PTH		equ $134
SPR5PTL		equ $136
SPR6PTH		equ $138
SPR6PTL		equ $13A
SPR7PTH		equ $13C
SPR7PTL		equ $13E

CIAAPRA		equ $BFE001

CIABPRA		equ $BFD000
CIABPRB		equ $BFD100
CIABTLO		equ $BFD400
CIABTHI		equ $BFD500
CIABICR		equ $BFDD00
CIABCRA		equ $BFDE00

CHIP_MEM	equ 2
EXEC_BASE	equ $4
CUSTOM_CHIPS	equ $DFF000
COPPER_LIST1	equ $26
COPPER_INT_VECT	equ $6c

forbid		equ -132
permit		equ -138
openLibrary	equ -552
closeLibrary	equ -414
allocMem	equ -198
freeMem		equ -210

; ------------------------------

	section code,code

start:
	MOVEM.l	d1-a6,-(SP)

	BSR.s	enter	
	BSR.s	main
	BSR.w	leave
	
	MOVEM.l	(SP)+,d1-a6
	MOVEQ	#0,d0
	RTS

; ------------------------------

main:
	MOVE.w	#$83A0,DMACON(a5)	; Enable DMA
;	MOVE.w	#$C010,INTENA(a5)	; Enable Copper IRQ

	BSR	TLInit

	LEA	DecodeBuffer,a0
	LEA	MFMBuffer,a1
	MOVE.b	#0,d0			; start at track 0	
	MOVE.b	#2,d1			; read 2 tracks
	BSR	TLLoad

_mainLoop:
;	BTST	#6,CIAAPRA		; Test for left mouse button click
;	BNE.s	_mainLoop	

	RTS

; ------------------------------

copperInterrupt:
	MOVEM.l	d0-a6,-(SP)

; Is it a copper interrupt?
	LEA	CUSTOM_CHIPS,a5
	MOVE.w	INTREQR(A5),d0
	AND.w	#$0010,d0		
	BEQ.s	_copperInterruptEnd	

; Yes it is 
	NOP

_copperInterruptEnd:
	MOVE.w	#$0010,INTREQ(a5)	; Clear Copper interrupt bit	
	MOVEM.l	(SP)+,d0-a6
	RTE

; ------------------------------

enter:
	MOVE.l	EXEC_BASE,a6
	LEA	CUSTOM_CHIPS,a5
	JSR	forbid(a6)

; Save system INTENA
	LEA	systemVars(PC),a4
	MOVE.w	INTENAR(a5),d0
	OR.w	#$8000,d0
	MOVE.w	d0,(a4)

; Save system DMACON
	MOVE.w	DMACONR(a5),d0
	OR.w	#$8000,d0
	MOVE.w	d0,2(a4)

; Save system Copper list
	LEA	graphicsLib(PC),a1
	MOVEQ	#0,d0
	JSR	openLibrary(a6)
	MOVE.l	d0,a1
	MOVE.l	COPPER_LIST1(a1),4(a4)
	JSR	closeLibrary(a6)	

; Disable interrupts and DMACON
	MOVE.w	#$7FFF,INTENA(a5)
	MOVE.w	#$7FFF,DMACON(a5)	

; Save system Copper interrupt vector and install own
	MOVE.l	COPPER_INT_VECT,8(a4)
	LEA	copperInterrupt(PC),a3
	MOVE.l	a3,COPPER_INT_VECT
	RTS

; ------------------------------

leave:
; Disable interrupts and DMACON
	MOVE.w	#$7FFF,INTENA(a5)
	MOVE.w	#$7FFF,DMACON(a5)

; Restore system INTENA, DMACON, Copper list and interrupt vector
	LEA	systemVars(PC),a4
	MOVE.l	4(a4),COP1LCH(a5)
	MOVE.l	8(a4),COPPER_INT_VECT
	MOVE.w	(a4),INTENA(a5)
	MOVE.w	2(a4),DMACON(a5)
	
	JSR	permit(a6)
	RTS

; ------------------------------

systemVars:	dc.w	0	; INTENA
		dc.w	0	; DMACON
		dc.l	0	; Copperlist
		dc.l	0	; Level 3 interrupt vector

graphicsLib:	dc.b "graphics.library",0

		even

; ------------------------------
; --  Track loader routines  ---
; ------------------------------

TLInit:
	; Call this routine once to initialize track loader
	; Leaves all registers unharmed
	
	MOVE.l	d0,-(SP)
	MOVE.w	#$8210,DMACON(a5)	; Enable disk DMA
	BSR.w	_TLMotorOn
	BSR.w	_TLMoveToCylinder0
	BSR.w	_TLMotorOff
	MOVE.l	(SP)+,d0
	RTS

; ------------------------------

TLLoad:
	; d0 = start track (0 - 159) (no check for illegal tracks)
	; d1 = Number of tracks to read (no check for illegal count,
	;      d1 = 0 moves head to right track).
	; a0 = data buffer, must be at least 11 * 512 * d1 bytes large
	; a1 = decode buffer, must be $3200 bytes large
	; Leaves all registers unharmed

	CMP.b	#$FF,TLCurrentCylinder	; Initialized?
	BNE.s	_TLLoad
	RTS

_TLLoad:
	MOVEM.l	d0-a6,-(SP)
	BSR.w	_TLMotorOn
	MOVE.b	d0,d2			; move start track in d2

_TLLoadDo:
	MOVE.b	d2,d0			; current track in d0
	AND.b	#1,d0			; even/odd determines disk side
	BSR.w	_TLSelectSide

	MOVE.b	d2,d0
	LSR.b	#1,d0			; track / 2 for cylinder
	BSR.w	_TLMoveToCylinder

	CMP.b	#0,d1			; all tracks done?
	BEQ.s	_TLLoadDone

	BSR.s	_TLLoadTrack
	BSR.w	_TLLoadDecode

	ADDA.l	#$1600,a0		; adjust offset for next track data
	ADDQ.b	#1,d2			; next track
	SUBQ.b	#1,d1			; one track less to do
	BRA.s	_TLLoadDo

_TLLoadDone:
	BSR.w	_TLMotorOff
	MOVEM.l (SP)+,d0-a6
	RTS	

_TLLoadTrack:
	MOVE.w	#$4000,DSKLEN(a5)	; disable disk stuff
	MOVE.l	a1,DSKPTH(a5)
	MOVE.w	#$7F00,ADKCON(a5)	; clear all disk related controls
	MOVE.w	#$9500,ADKCON(a5)	; MFM precomp, word sync/fast clock on
	MOVE.w	#$8210,DMACON(a5)	; disk dma enable
	MOVE.w	#$4489,DSKSYNC(a5)	; magic MFM number in disk sync
	MOVE.w	#2,INTREQ(a5)		; Clear DISKBLK flag
	MOVE.w	#$9900,DSKLEN(a5)	; Read 6400 words of mfm data
	MOVE.w	#$9900,DSKLEN(a5)	; write twice to start read

_TLLoadTrackWaitDone:
	BTST	#1,INTREQR+1(a5)
	BEQ.s	_TLLoadTrackWaitDone

	MOVE.w	#$4000,DSKLEN(a5)	; disable disk stuff
	RTS

_TLLoadDecode:
	MOVEQ	#10,d3			; 11 sectors
	MOVE.l	a1,a2			; copy of MFM Buffer in a2
	MOVE.l	a0,a3			; copy of decode buffer to a3
	MOVE.l	#$55555555,d7		; MFM Mask

_TLLoadDecodeFindDiskSync:
	CMP.w	#$4489,(a2)+		; Found magic number?
	BNE.s	_TLLoadDecodeFindDiskSync	

	CMP.w	#$4489,(a2)		; test for 2nd occurence
	BEQ.s	_TLLoadDecodeFindDiskSync

	MOVE.l	(a2)+,d5	; odd header info bits to d5
	MOVE.l	(a2)+,d6	; even header info bits to d6
	BSR.s	_TLMFMDecode
	AND.l	#$0000ff00,d4	; Sector number only
	LSL.l	#1,d4		; * 2 to get block offset in bytes
	ADDA.l	d4,a3		; add to beginning of data buffer

	ADDA.l	#48,a2		; skip rest of header stuff (no guts no glory!)
	MOVE.l	#127,d4		; 128 * sizeof(long) = 512 bytes
	
_TLLoadDecodeDataLoop:
	MOVE.l	512(a2),d6	; even bits have offset of 512 bytes
	MOVE.l	(a2)+,d5
	BSR.s	_TLMFMDecodeToBuffer
	DBF	d4,_TLLoadDecodeDataLoop

	MOVE.l	a0,a3		; restore start of decode buffer in a3
	DBF	d3,_TLLoadDecodeFindDiskSync	

	RTS

; ------------------------------

_TLMFMDecode:
	; d5 = Odd bits (long)
	; d6 = Even bits (long)
	; d7 = Decode Mask
	; Returns decoded long in d4

	AND.l	d7,d5
	AND.l	d7,d6
	LSL.l	#1,d5
	MOVE.l	d5,d4
	OR.l	d6,d4
	RTS

; ------------------------------

_TLMFMDecodeToBuffer:
	; d5 = Odd bits (long)
	; d6 = Even bits (long)
	; d7 = Decode Mask
	; a3 = Buffer

	AND.l	d7,d5
	AND.l	d7,d6
	LSL.l	#1,d5
	MOVE.l	d5,(a3)
	OR.l	d6,(a3)+
	RTS

; ------------------------------

_TLMotorOn:
	AND.b	#$7F,CIABPRB	; disk motor bit (7) low (on)
	AND.b	#$F7,CIABPRB	; select df0:

_TLMotorOnTestDiskReady:	
	BTST	#5,CIAAPRA
	BNE.s	_TLMotorOnTestDiskReady	
	RTS

; ------------------------------

_TLMotorOff:
	OR.b	#$8,CIABPRB	; deselect df0:
	OR.b	#$80,CIABPRB	; disk motor bit high (off)
	AND.b	#$F7,CIABPRB	; by selecting df0: with motor of it's motor
				; turns off.
	OR.b	#$8,CIABPRB	; deselect df0:
	RTS

; ------------------------------

_TLSelectSide:
	; d0 = side. 1 = up, 0 = down

	CMP.b	#1,d0
	BEQ.s	_TLSelectSideUp
	OR.b	#$4,CIABPRB
	RTS
	
_TLSelectSideUp:
	AND.b	#$FB,CIABPRB
	RTS
	
; ------------------------------

_TLSelectDir:
	; d0 = direction. 0 = towards center, 1 = outwards

	MOVE.l	d0,-(SP)
	MOVE.w	#12886,d0	; Wait 18 ms, just in case _TLSelectDir is
	BSR.w	_TLDelay	; called after a disk step (lazy coding :) )
	MOVE.l	(SP)+,d0

	CMP.b	#0,d0
	BEQ.s	_TLSelectDirCenter
	OR.b	#$2,CIABPRB
	RTS
	
_TLSelectDirCenter:
	AND.b	#$FD,CIABPRB
	RTS

; ------------------------------

_TLMoveToCylinder0:
	MOVE.b	#0,TLCurrentCylinder

	BTST	#4,CIAAPRA
	BNE.s	_TLMoveToCylinder0Setup
	RTS

_TLMoveToCylinder0Setup:
 	MOVEQ	#0,d0
	BSR.s	_TLSelectSide
	MOVEQ	#1,d0
	BSR.s	_TLSelectDir

_TLMoveToCylinder0Step:
	BSR.s	_TLStep
	BTST	#4,CIAAPRA		; track zero detect bit low?
	BNE.s	_TLMoveToCylinder0Step
	RTS

; ------------------------------

_TLMoveToCylinder:
	; d0 = cylinder number
	; Trashes d0,d6 and d7

	MOVE.b	d0,d6
	MOVE.b	TLCurrentCylinder,d7

_TLMoveToCylinderTest:
	CMP.b	d6,d7
	BEQ.s	_TLMoveToCylinderDone
	BMI.s	_TLMoveToCylinderStepCenter

	MOVEQ	#1,d0	
	BSR.s	_TLSelectDir
	BSR.s	_TLStep
	SUBQ.b	#1,d7
	MOVE.b	d7,TLCurrentCylinder
	BRA.s	_TLMoveToCylinderTest

_TLMoveToCylinderStepCenter:
	MOVEQ	#0,d0
	BSR.s	_TLSelectDir
	BSR.s	_TLStep
	ADDQ.b	#1,d7
	MOVE.b	d7,TLCurrentCylinder
	BRA.s	_TLMoveToCylinderTest

_TLMoveToCylinderDone:
	RTS

; ------------------------------

_TLStep:
	AND.b	#$FE,CIABPRB
	OR.b	#1,CIABPRB

	MOVE.w	#2148,d0	; 3 ms before stable
	BSR.s	_TLDelay
	RTS

; ------------------------------

_TLDelay:
	MOVE.l	d1,-(SP)
	MOVE.b	CIABCRA,d1
	AND.b	#$c0,d1		; Leave bit 6 - 7 unharmed
	OR.b	#$8,d1		; One shot mode
	MOVE.b	d1,CIABCRA
	MOVE.l	(SP)+,d1

	MOVE.b	#$7f,CIABICR	; Clear interrupts

	MOVE.b	d0,CIABTLO
	LSR.w	#8,d0
	MOVE.b	d0,CIABTHI	; write to THI starts timer!

_TLDelayWaitDone:
	BTST	#0,CIABICR
	BEQ.s	_TLDelayWaitDone	

	RTS

; ------------------------------

TLCurrentCylinder:	dc.b	$FF

	even

; ------------------------------

	section MFMBuffer,data_c

MFMBuffer:		dcb.b	12800," "
DecodeBuffer:		dcb.b	2*11*512," "
