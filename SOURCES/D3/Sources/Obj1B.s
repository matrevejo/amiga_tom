* Obj1B.s
* Viser et komplet hovedobjekt på skærmen, 32 farvers baggrund.
* bygger på "obj1nb.s"
*
* Styring med joysticket:
*
* Højre/Venstre: Rotation om Y-aksen
* Op/Ned: Rotation om X-aksen
* Højre/Venstre m/skydeknap nede: Rotation om Z-aksen

lnmod=40
line_lnmod=64
line_waitblit=-1	;Check altid om blitteren er færdig!

line_LnModMul:	macro
	lsl	#6,\1	;* 64, Aldrig negative koordinater
	endm

	include	VektorProgAmiga:Includes/custom.i
	include	VektorProgAmiga:Includes/line.s
	
OFF=0
ON=-1
debug	set	OFF
mouse_wait	set 	OFF

LnModMul:	MACRO	;Ganger \1 med 40
	asl	#3,\1	;\1=x*8
	move	\1,\2	;\2=x*8
	add	\1,\1	;\1=x*16
	add	\1,\1	;\1=x*32
	add	\2,\1	;\1=x*32+x*8=x*40
	ENDM


* Nogle konstanter fra EXEC og GRAPHICS - bibliotekerne:

* Fra Exec library:
_LVOOpenLibrary=-552
_LVOAllocMem=-198
_LVOFreeMem=-210
_LVOForbid=-132
_LVOPermit=-138

* Fra memory.i:
MEMF_PUBLIC=1
MEMF_CHIP=2
MEMF_CLEAR=65536

* Fra Graphics library:
_LVOWaitBlit=-228
_LVOOwnBlitter=-456
_LVODisownBlitter=-462
 
* Fra DOS library:
MODE_OLDFILE=1005
_LVOOpen=-30
_LVORead=-42
_LVOClose=-36

	bsr	init_background

	IFEQ	debug-OFF
	move.l	$4.w,a6
	lea	gfxname,a1
	moveq	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,gfxbase

	move.l	d0,a6
	jsr	_LVOWaitBlit(a6)
	jsr	_LVOOwnBlitter(a6)
	
	move.l	$4.w,a6
	jsr	_LVOForbid(a6)

	ENDC
	bsr	init_bitplanes
	bsr	init_copper
	bsr	init_vars
	bsr	init_blitter
	bsr	init_interrupts
	
* Her indsættes hovedprogrammet..

	bsr	init_triplebuf
	
	lea	var,a6	
main_loop:
	bsr	restore_oldpolys	;Skal vente på klar-signal!
				;checker om draw_ready(a6) er 0. Da er
				;det klart...
	bsr	joystick_move
	lea	object,a0
	move	rx(a6),objRX(a0)
	move	ry(a6),objRY(a0)
	move	rz(a6),objRZ(a0)
	bsr	draw_mainobj	;roterer og tegner hovedobjektet
	bsr	triplebuf
	btst	#6,$bfe001
	bne.s	main_loop

	IFEQ	debug-OFF
	move.l	gfxbase,a6
	jsr	_LVODisownBlitter(a6)
	
 	move.l	4.w,a6
	jsr	_LVOPermit(a6)
	ENDC
	bsr	restore_copperlist
	bsr	remove_interrupts
	bsr	remove_background
	bsr	dealloc_mem	
	
	move	#$0400,dmacon+$dff000	;Slukker for blitter nasty.
	move	#$8020,dmacon+$dff000	;Tænder for sprites igen!
Exit:
	moveq	#0,d0
	rts

shame_nobck_mem:
	addq.l	#4,sp
	moveq	#-100,d0
	rts	;returnerer UD AF programmet pga for lidt chip-hukommelse.

remove_background:
* reallokerer hukommelsen, som blev brugt af baggrundsgrafikken.
	move.l	4.w,a6
	move.l	colors_pointer+var,a1
	move.l	#51264,d0
	jsr	_LVOFreeMem(a6)
	rts

init_background:
* Indlæser filen "background.raw" fra programdisketten og lægger den
* bag objektet.
	move.l	4.w,a6
	move.l	#51264,d0
	move.l	#MEMF_CHIP+MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,colors_pointer+var
	beq.s	shame_nobck_mem

	lea	backgr_bitplanes_table+var,a0
	add.l	#64,d0
	moveq	#4,d1
inbck_loop:
	move.l	d0,(a0)+
	add.l	#10240,d0
	dbra	d1,inbck_loop
	
	lea	dosname(pc),a1
	moveq	#0,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,a6
	
	move.l	#gfxfile,d1
	move.l	#MODE_OLDFILE,d2
 	jsr	_LVOOpen(a6)
	move.l	d0,d7	;d7=file-handle
	beq	shame_nosuchfile
	
	move.l	d7,d1
	move.l	colors_pointer+var,d2
	move.l	#51264,d3
	jsr	_LVORead(a6)
	
	move.l	d7,d1
	jsr	_LVOClose(a6)
	
	rts
shame_nosuchfile:
	bsr	remove_background
	addq.l	#4,sp
	moveq	#-50,d0
	rts	returnerer UD af programmet.

	
dosname:	dc.b	"dos.library",0
	even
gfxfile:	dc.b	"VektorProgAmiga:Background.raw",0
	even
	
init_interrupts:
* Slukker for alle level 3 interrupts bortset fra COPPER-interruptet.
* tænder så for COPPER-interruptet...
	IFEQ	debug-OFF
	move.l	$6c.w,old_int3handler(a6)
	move	intenar(a5),old_intena(a6)
	move	#$3fff,intena(a5)	;Slukker for vertical bl+copper intr.
	move.l	#int3_handler,$6c.w	;Indsætter interrupthandleren
	move	#$c010,intena(a5)	;Tænder for copper-interrupt.
	ENDC
	rts

remove_interrupts:
* Lægger de gamle level 3 interrupt tilbage...
	IFEQ	debug-OFF
	move	old_intena+var,d0
	or	#$c000,d0
	move	#$0030,intena(a5)
	move.l	old_int3handler+var,$6c.w
	move	d0,intena(a5)
	ENDC
	rts

dealloc_mem:
* Reallokerer al hukommelsen, som blev allokeret i starten af programmet.
 	
	move.l	4.w,a6	;A6=Exec-base

	move.l	copperlist_pointer+var,a1
	move.l	#copperlist_size,d0
	jsr	_LVOFreeMem(a6)
	
dealloc_screenmem:	;hopper her til hvis allokeringen af copperlisthukommelsen
			;ikke går godt.
	move.l	#tempplane_size,d0
	move.l	tempplane_pointer+var,a1
	subq.l	#2,a1
	jsr	_LVOFreeMem(a6)

	lea	bitplane_table+var,a4
	
	moveq	#noof_bitplanes*noof_screens-1,d7
dealloc_bitplmem_loop:
	move.l	#bitplane_size,d0
dal_bpm:
	move.l	(a4)+,d1
	bmi.s	dal_bpm	;Vi har lagt nogle -1 ind...
	move.l	d1,a1	
	jsr	_LVOFreeMem(a6)
	dbra	d7,dealloc_bitplmem_loop
	rts

restore_copperlist:
* Henter copperlisten, som bliver brugt af Intuition-systemet
* i Amigaen, frem, sådan at den sædvanlige CLI/Workbench-skærmen bliver synlig igen.

	move.l	4.w,a0
	move.l	156(a0),a0
	move.l	38(a0),cop1lch+$dff000
	move	copjmp1+$dff000,d0	;Og copperlisten er tilbage igen.
	rts
	
int3_handler:
* Interrupt level 3.
	pea	(a6)
	pea	(a5)
	move	d7,-(sp)
	
	move	#$0010,intena+$dff000

	lea	var,a6

	clr	draw_ready(a6)
	tst	newscreen_flag(a6)
	bne.s	int3_no_new_screen
 	not	newscreen_flag(a6)

* Her lægges nye skærmadresser ind i copperlisten.
* De tages fra bitplane-tabellen, hvorpå show_bitplanes_pointer'en peger.
* Double- og triple-bufferingsrutinerne sørger for indstillingen af
* denne pointer.

	move.l	show_bitplanes_table(a6),a5
	move.l	copperlist_pointer(a6),a6
	
	addq.l	#2,a6
	move	#noof_bitplanes-1,d7
int3_newaddrs_loop:
	move	(a5)+,(a6)
	move	(a5)+,4(a6)
	addq.l	#8,a6
	dbra	d7,int3_newaddrs_loop
int3_no_new_screen:

	
	move	#$3fff,intreq+$dff000	;Slukker for interrupt-requesten igen.
	move	#$8010,intena+$dff000

	move	(sp)+,d7
	move.l	(sp)+,a5
	move.l	(sp)+,a6
	rte	;returnerer fra interruptet.

joystick_move:
	move	$dff000+joy1dat,d0
	
	btst	#1,d0
	beq.s	jm_b1_ns	
	bchg	#0,d0
jm_b1_ns:
	btst	#9,d0
	beq.s	jm_b2_ns
	bchg	#8,d0
jm_b2_ns:

* Vi har nu lavet det ssådan at:
* bit 0 = 1: bagover/nedad
* bit 1 = 1: højre
* bit 8 = 1: fremad/opefter
* bit 9 = 1: venstre
* Vi checker så om skydeknappen er trykket ned..

* Først tager vi rotation om x-aksen, som styres af joystick op/ned.


 	btst	#0,d0
	beq.s	not_bck
	
	add.l	#$8000,rxs(a6)
	bra.s	not_fwd
not_bck:
	btst	#8,d0
	beq.s	not_fwd
	
	sub.l	#$8000,rxs(a6)
not_fwd:


* Så skal vi først checke skydeknappen før vi kan behandle
* venstre/højre bevægelsen.
* Hvis skydeknappen er nede, skal det give en rotation rundt om Z-aksen,
* men hvis den er oppe, skal det give rotation rundt om Y-aksen.

	btst	#7,$bfe001
	beq.s	joy_button_pressed

* Ok. Joystick-knappen er ikke nede. Så en eventuel rotation er rundt om Y-aksen

	btst	#1,d0
	beq.s	not_rig
	sub.l	#$8000,rys(a6)
	bra.s	not_lft
not_rig:
	btst	#9,d0
	beq.s	not_lft
	add.l	#$8000,rys(a6)
not_lft:

	bra.s	brake	;rutine som simulerer luftmodstand


joy_button_pressed:
	btst	#1,d0
	beq.s	bnot_rig
	add.l	#$8000,rzs(a6)
	bra.s	bnot_lft
bnot_rig:
	btst	#9,d0
	beq.s	bnot_lft
	sub.l	#$8000,rzs(a6)
bnot_lft:
brake:
	
	move.l	rxs(a6),d0
	add.l	d0,rxl(a6)
	asr.l	#5,d0
	sub.l	d0,rxs(a6)
 	
	move.l	rys(a6),d0
	add.l	d0,ryl(a6)
	asr.l	#5,d0
	sub.l	d0,rys(a6)
	
	move.l	rzs(a6),d0
	add.l	d0,rzl(a6)
	asr.l	#5,d0
	sub.l	d0,rzs(a6)
	
	move.w	#2046,d0
	
	move	rxl(a6),rx(a6)
	and	d0,rx(a6)
	move	ryl(a6),ry(a6)
	and	d0,ry(a6)
	move	rzl(a6),rz(a6)
	and	d0,rz(a6)
	rts

init_vars:
	lea	var,a6
	moveq	#-1,d0
	move.l	d0,set_to_minus1(a6)
	move	#$ff,poly_color(a6)
	rts

init_bitplanes:

noof_bitplanes=5	;antal bitplanes
noof_screens=3		;antal skærme (3 giver triple-buffering)
bitplane_size=320*256/8		;Giver bitplanstørrelsen 320x256 pixels.
tempplane_size=512*512/8	;temp_plane størrelse 512x512 pixels

	move.l	4.w,a6	;A6=Exec-base

	move.l	#tempplane_size,d0
	move.l	#MEMF_CHIP+MEMF_CLEAR+MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	beq	disaster_no_tempplanemem
	addq.l	#2,d0
	move.l	d0,tempplane_pointer+var

	lea	bitplane_table+var,a4
	
	moveq	#noof_screens-1,d7
alloc_bitplmem_loop1:
	moveq	#noof_bitplanes-1,d6
alloc_bitplmem_loop2:
 	move.l	#bitplane_size,d0
	move.l	#MEMF_CHIP+MEMF_CLEAR+MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,(a4)+
	beq	disaster_no_bitplanemem
	dbra	d6,alloc_bitplmem_loop2
	move.l	#-1,(a4)+
	dbra	d7,alloc_bitplmem_loop1

	move.l	#bitplane_table+var,show_bitplanes_table+var
	
* Så er det på tide at kopiere baggrundsgrafikken ind:
	rts

disaster_no_bitplanemem:
* Uha da. Denne rutine tager sig af det problem, som kan opstå, hvis
* programmet køres på en maskine med for lidt CHIP-MEM.
* Så skal vi reallokere alle bitplanerne, som blev allokeret før vi går
* ud af programmet.

	lea	bitplane_table+var,a4
dealloc_nobplm_loop:
	move.l	(a4)+,d1
	beq	nobplm_deallocated
	bmi.s	dealloc_nobplm_loop	;Vi har lagt nogle -1 ind i listen.
	move.l	d1,a0
	move.l	#bitplane_size,d0
	jsr	_LVOFreeMem(a6)
	bra.s	dealloc_nobplm_loop
nobplm_deallocated:
	move.l	tempplane_pointer+var,a1
	subq.l	#2,a1
	move.l	#tempplane_size,d0
	jsr	_LVOFreeMem(a6)
disaster_no_tempplanemem:
	moveq	#-100,d0
	addq.l	#4,sp	;Vi returnerer direkte tilbage
	bra	remove_background

init_copper:
copperlist_size=200
* Maksimal længde på copperlisten er her sat til 200 bytes.
* Det burde være nok i de fleste tilfælde, men hvis du behøver mere
* skal du bare ændre det.

	move.l	$4.w,a6
	move.l	#MEMF_CHIP+MEMF_PUBLIC+MEMF_CLEAR,d1
	move.l	#copperlist_size,d0
	jsr	_LVOAllocMem(a6)
 	move.l	d0,copperlist_pointer+var
	bne.s	ic_clm_alloc_ok
	
* Uha da. Ikke nok hukommelse til en copperliste!
* (Og det kan godt lade sig gøre..._)
	
	bsr	dealloc_screenmem
	addq.l	#4,sp
	bra	Exit
	
ic_clm_alloc_ok:
 	move.l	d0,a0	;a0=copperlist-start
 	move.l	d0,d7	;Lagrer i d7 til brug længere nede...
 	
 	move	#bpl1pth,d1
 	moveq	#noof_bitplanes-1,d0
 	moveq	#0,d2
crcl_loop1:
	move	d1,(a0)+
	move	d2,(a0)+
	addq	#2,d1	;d1=bplxptl
	move	d1,(a0)+
	move	d2,(a0)+
	addq	#2,d1	;d1=næste bplxpth
	dbra	d0,crcl_loop1
	
* Nu er den første del af copperlisten færdig - nemlig den del, som sætter
* bitplane-adresse-registrene.

* Vi sætter farverne i init_copper - rutinen

	move	#spr0ctl,(a0)+
	move	d2,(a0)+
	move	#spr1ctl,(a0)+
	move	d2,(a0)+	;Fjerner eventuelle sprite-rester...
	
* De næste 6 linier (kommentarlinierne skal ikke tælles med)
* SKAL være med for at int3_handler skal kunne fungere...

	move.l	#$ffdffffe,(a0)+ ;Venter helt til sidst på linie 256
	move.l	#$3509fffe,(a0)+
	move.l	#$3509fffe,(a0)+

* Venter på linien nedenunder den nederste linie som vises...
* Laver interrupt (copper interrupt), som udnyttes af int3_handler...

	move	#intreq,(a0)+
	move	#$8010,(a0)+	;copper interrupt...
	move.l	#$fffffffe,(a0)+	;Afslutter copperlisten.
 	
	IFEQ	debug-OFF
	lea	$dff000,a5
	move	#$07a0,dmacon(a5)	;Slukker for alle DMA, copper og sprites..	
			;Slukker for blitter nasty, hvis den skulle være tændt.
	move	#$200+noof_bitplanes*$1000,bplcon0(a5)	
	move	#0,bpl1mod(a5)
	move	#0,bpl2mod(a5)

	move	#$0038,ddfstrt(a5)
	move	#$00d0,ddfstop(a5)
	move	#$2c81,diwstrt(a5)
	move	#$2cc1,diwstop(a5)

	move.l	d7,cop1lch(a5)	;d7 er starten på copperlisten.
	move.w	copjmp1(a5),d0
	
	move	#$8380,dmacon(a5)	;Tænder igen for DMA copper,
					;men ikke sprites.
* Tænder også for blitter nasty.
* Det får programmet til at køre en del hurtigere, eftersom rutinerne
* ikke er lagt ind på interrupt (blitteren kan indstilles til at
* lave interrupt, når den er færdig med et "blit")

	moveq	#31,d0
	lea	$dff180,a0
	move.l	colors_pointer+var,a1
colors_loop:
	move	(a1)+,(a0)+
	dbra	d0,colors_loop

	ENDC
	rts
	
init_blitter:
	IFEQ	debug-OFF
	bsr	init_line
	move.l	#-1,bltafwm(a5)
	ENDC
	rts
	
wait_mouse:
	move	#10000,d0
wm1_loop:
	btst	#6,$bfe001
	dbeq	d0,wm1_loop
	beq.s	wait_mouse
* OK. Nu har knappen været "oppe" i nogle ms
wm2_loop:
 	btst	#6,$bfe001
	bne.s	wm2_loop
* Nu er der blevet trykket på knappen...
wm3_redo:
	move	#10000,d0
wm3_loop:
	btst	#6,$bfe001
	dbeq	d0,wm3_loop
	beq.s	wm3_redo	;Og den har været oppe igen i nogle ms...
	rts

SinusTable:
	include	VektorProgAmiga:Includes/SinCosTable.s
CosinusTable=SinusTable+512


gfxbase:	ds.l	1
gfxname:	dc.b	"graphics.library",0
	even

CoordTable:
	dc.w	-100*3,-50*3,-50*3
	dc.w	0,-50*3,-50*3
	dc.w	0,50*3,-50*3
	dc.w	-100*3,50*3,-50*3
	
	dc.w	-100*3,-50*3,50*3
	dc.w	0,-50*3,50*3
	dc.w	0,50*3,50*3
	dc.w	-100*3,50*3,50*3
	
	dc.w	50*3,-50*3,-50*3
	dc.w	50*3,-50*3,50*3
	dc.w	50*3,50*3,50*3
	dc.w	50*3,50*3,-50*3
	dc.w	100*3,0,0
CalcCoords:
	ds.w	13*3
DrawCoords:
	ds.l	13
	
object:
	dc.w	0,0,0,0,0
	dc.w	0,0,0,0,0,0
	dc.w	12
	dc.l	CoordTable
	dc.l	CalcCoords
	dc.l	DrawCoords
	dc.l	SubTable
	dc.w	1	;Antal underobjekter = 2
	
SubTable:
	dc.l	Cube,Pyramid

Cube:
	dc.w	0,5
	dc.l	poly0,poly1,poly2,poly3,poly4,poly5
	
Pyramid:
	dc.w	0,4
	dc.l	poly6,poly7,poly8,poly9,poly10
	
poly0:	dc.w	0
	dc.b	10,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	3
	dc.w	0,1*4,2*4,3*4

poly1:	dc.w	0
	dc.b	11,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	3
	dc.w	4*4,5*4,1*4,0

poly2:	dc.w	0
	dc.b	12,-1
	dc.l	0
	dc.w	0	;et underobjekt foran denne flade.
	dc.l	FrontPol2Table
	dc.w	3
	dc.w	1*4,5*4,6*4,2*4

FrontPol2Table:
	dc.l	Pyramid

poly3:	dc.w	0
	dc.b	13,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	3
	dc.w	5*4,4*4,7*4,6*4

poly4:	dc.w	0
	dc.b	14,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	3
	dc.w	3*4,2*4,6*4,7*4

poly5:	dc.w	0
	dc.b	15,-1
 	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	3
	dc.w	4*4,0,3*4,7*4

poly6:	dc.w	0
	dc.b	16,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	2	;3 hjørner!
	dc.w	8*4,12*4,11*4

poly7:	dc.w	0
	dc.b	17,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	2	;3 hjørner!
	dc.w	9*4,12*4,8*4

poly8:	dc.w	0
	dc.b	18,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	2	;3 hjørner!
	dc.w	12*4,9*4,10*4

poly9:	dc.w	0
	dc.b	19,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	2	;3 hjørner!
	dc.w	11*4,12*4,10*4
poly10:	dc.w	0
	dc.b	20,-1
	dc.l	0
	dc.w	-1
	dc.l	0
	dc.w	3	;4 hjørner!
	dc.w	9*4,8*4,11*4,10*4


	include	VektorProgAmiga:sources/obj.s
	include	VektorProgAmiga:sources/poly.s

ofsreset:	macro
ofs_ofs:	SET	0
	endm
	
ofs:	macro
\1=ofs_ofs
ofs_ofs	SET	ofs_ofs+\2
	endm
	
* ofs og ofsreset får her samme funktion som rs og rsreset i DEVPAC...
* ofs og ofsreset fungerer imidlertid på alle assemblere (ikke SEKA)

	ofsreset

	ofs copperlist_pointer,4
	ofs tempplane_pointer,4
	ofs show_bitplanes_table,4
	ofs bitplane_table_pointer,0	;Samme som show_bitplanes_table
	ofs draw_bitplanes_table,4
	ofs visibl_bitplanes_table,4
	ofs show_minx,2
	ofs show_miny,2
	ofs show_maxx,2
	ofs show_maxy,2
	ofs draw_minx,2
	ofs draw_miny,2
	ofs draw_maxx,2
	ofs draw_maxy,2
	ofs visibl_minx,2
	ofs visibl_miny,2
	ofs visibl_maxx,2
	ofs visibl_maxy,2
	
	ofs newscreen_flag,2
	ofs poly_minx,2	;poly_minx, miny, maxx og maxy skal
	ofs poly_miny,2	;stå lige efter hinanden!
	ofs poly_maxx,2	;ellers vil poly-rutinerne ikke fungere
	ofs poly_maxy,2	;ordentligt!!!

	ofs rx,2
	ofs ry,2
	ofs rz,2
	ofs rxl,4
	ofs ryl,4
	ofs rzl,4
	ofs rxs,4
	ofs rys,4
	ofs rzs,4
	ofs cosx,2
	ofs sinx,2
	ofs cosy,2
	ofs siny,2
	ofs cosz,2
	ofs sinz,2
	
 	ofs old_dot_offsets,16
	
	ofs draw_ready,2

	ofs del_height,2
	ofs del_width,2
	ofs fill_width,2
	ofs copy_width,2
	ofs fill_offset,2
	ofs fill_height,2
	ofs copy_srcoffset,2
	ofs colors_pointer,4
	ofs backgr_bitplanes_table,4*noof_bitplanes
	ofs bitplane_table,4*noof_bitplanes*(noof_screens+1) ;Sæt -1 ind efter hver!
	ofs copy_destoffset,2
	ofs poly_color,2
	ofs objline_table,200
	ofs current_mainobj,4
	ofs old_intena,2
	ofs old_int3handler,4
	ofs dest_coords,900	
	ofs set_to_minus1,4	;-1 skal stå lige før line_table!
				;Linietegningsrutinen tegner linier bagfra
				;indtil den kommer til et negativt tal.
	ofs line_table,400	;dvs maks 50 hjørner i et polygon.
				;Hvis du behøver flere, skal du lave
				;dette array længere.
	ofs hardware_fake,400
	ofs var_size,0

	section	buffer,bss
var:	
	ds.b	var_size
