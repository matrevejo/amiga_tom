	code
* Obj1Nb.s
* Viser et komplet hovedobjekt på skærmen, ensfarvet baggrund.
* bygger på "Kube1.s"
*
* Styring med joysticket:
*
* Højre/Venstre: Rotation om Y-aksen
* Op/Ned: Rotation om X-aksen
* Højre/Venstre m/skydeknap nede: Rotation om Z-aksen


copperlist_pointer=0 ;offset 4
tempplane_pointer=4 ;offset 4
show_bitplanes_table=8 ;offset 4
bitplane_table_pointer=12 ;offset 0
draw_bitplanes_table=12 ;offset 4
visibl_bitplanes_table=16 ;offset 4
show_minx=20 ;offset 2
show_miny=22 ;offset 2
show_maxx=24 ;offset 2
show_maxy=26 ;offset 2
draw_minx=28 ;offset 2
draw_miny=30 ;offset 2
draw_maxx=32 ;offset 2
draw_maxy=34 ;offset 2
visibl_minx=36 ;offset 2
visibl_miny=38 ;offset 2
visibl_maxx=40 ;offset 2
visibl_maxy=42 ;offset 2

newscreen_flag=44 ;offset 2
poly_minx=46 ;offset 2	;poly_minx, miny, maxx og maxy skal
poly_miny=48 ;offset 2	;stå lige efter hinanden!
poly_maxx=50 ;offset 2	;ellers vil poly-rutinerne ikke fungere
poly_maxy=52 ;offset 2	;ordentligt!!!
anim_minx=54 ;offset 2
anim_miny=56 ;offset 2
anim_maxx=58 ;offset 2
anim_maxy=60 ;offset 2
	
rx=62 ;offset 2
ry=64 ;offset 2
rz=66 ;offset 2
rxl=68 ;offset 4
ryl=72 ;offset 4
rzl=76 ;offset 4
rxs=80 ;offset 4
rys=84 ;offset 4
rzs=88 ;offset 4
cosx=92 ;offset 2
sinx=94 ;offset 2
cosy=96 ;offset 2
siny=98 ;offset 2
cosz=100 ;offset 2
sinz=102 ;offset 2
	
old_dot_offsets=104 ;offset 16
	
draw_ready=120 ;offset 2

del_height=122 ;offset 2
del_width=124 ;offset 2
fill_width=126 ;offset 2
copy_width=128 ;offset 2
fill_offset=130 ;offset 2
fill_height=132 ;offset 2
copy_srcoffset=134 ;offset 2
colors_pointer=136 ;offset 4
backgr_bitplanes_table=140 ;20: ;Max 5 bitplanes!
bitplane_table=160 ;offset 80: ;Max 5 bitplanes, 3 screens!
copy_destoffset=240 ;offset 2
poly_color=242 ;offset 2
objline_table=244 ;offset 200
current_mainobj=444 ;offset 4
old_intena=448 ;offset 2
old_int3handler=450 ;offset 4
dest_coords=454 ;offset 900	
set_to_minus1=1354 ;offset 4
line_table=1358 ;offset 400	;dvs maks 50 hjørner i et polygon.
				;Hvis du behøver flere, skal du lave dette
				;array længere.
hardware_fake=1758 ;offset 400
var_size=2158 ;offset 0


lnmod=40
line_lnmod=64
line_waitblit=-1	;Check altid om blitteren er færdig!

line_LnModMul:	macro
	lsl	#6,?1	;* 64, Aldrig negative koordinater
	endm

	
OFF=0
ON=-1
debug=OFF
mouse_wait=OFF

LnModMul:	MACRO	;Ganger ?1 med 40
	asl	#3,?1	;?1=x*8
	move	?1,?2	;?2=x*8
	add	?1,?1	;?1=x*16
	add	?1,?1	;?1=x*32
	add	?2,?1	;?1=x*32+x*8=x*40
	ENDM
	bra	start
	

	include	VektorProgAmiga:Includes/custom.i
	include	VektorProgAmiga:Includes/line.s
	include	VektorProgAmiga:sources/poly.s
	include	VektorProgAmiga:sources/obj.s


* Nogle konstanter fra EXEC og GRAPHICS - bibliotekerne:

* Fra Exec library:
LVOOpenLibrary=-552
LVOAllocMem=-198
LVOFreeMem=-210
LVOForbid=-132
LVOPermit=-138

* Fra memory.i:
MEMF_PUBLIC=1
MEMF_CHIP=2
MEMF_CLEAR=65536

* Fra Graphics library:
LVOWaitBlit=-228
LVOOwnBlitter=-456
LVODisownBlitter=-462
start:
	IF	debug-ON
	move.l	$4.w,a6
	lea	gfxname,a1
	moveq	#0,d0
	jsr	LVOOpenLibrary(a6)
	move.l	d0,gfxbase

	move.l	d0,a6
	jsr	LVOWaitBlit(a6)
	jsr	LVOOwnBlitter(a6)
	
	move.l	$4.w,a6
	jsr	LVOForbid(a6)

	ENDIF
	bsr	init_bitplanes
	bsr	init_copper
	bsr	init_vars
	bsr	init_blitter
	bsr	init_interrupts
	
* Her indsættes hovedprogrammet..

	bsr	init_triplebuf
	
	lea	var,a6	
main_loop:
	bsr	delete_oldpolys	;Skal vente på klar-signal!
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

	IF	debug-ON
	move.l	gfxbase,a6
	jsr	LVODisownBlitter(a6)
	
	move.l	4.w,a6
	jsr	LVOPermit(a6)
	ENDIF
	bsr	restore_copperlist
	bsr	remove_interrupts
	bsr	dealloc_mem	
	
	move	#$0400,dmacon+$dff000	;Slukker for blitter nasty.
 	move	#$8020,dmacon+$dff000	;Tænder for sprites igen!
Exit:
	moveq	#0,d0
	rts

init_interrupts:
* Slukker for alle level 3 interrupts bortset fra COPPER-interruptet.
* Tænder så for COPPER-interruptet...
	IF	debug-ON
	move.l	$6c.w,old_int3handler(a6)
	move	intenar(a5),old_intena(a6)
	move	#$3fff,intena(a5)	;Slukker for vertical bl+copper intr.
	move.l	#int3_handler,$6c.w	;Lægger interrupthandleren ind
	move	#$c010,intena(a5)	;Tænder for copper-interrupt.
	ENDIF
	rts

remove_interrupts:
* Lægger de gamle level 3 interrupt tilbage...
	IF	debug-ON
	move	old_intena+var,d0
	or	#$c000,d0
	move	#$0030,intena(a5)
	move.l	old_int3handler+var,$6c.w
	move	d0,intena(a5)
	ENDIF
	rts

dealloc_mem:
* Reallokerer al hukommelsen, som blev allokeret i starten af programmet.
	
	move.l	4.w,a6	;A6=Exec-base

	move.l	copperlist_pointer+var,a1
	move.l	#copperlist_size,d0
	jsr	LVOFreeMem(a6)
	
dealloc_screenmem:	;hopper her til, hvis allokeringen af copperlisthukommelsen
			;ikke går godt.
	move.l	#tempplane_size,d0
	move.l	tempplane_pointer+var,a1
	subq.l	#2,a1
	jsr	LVOFreeMem(a6)

	lea	bitplane_table+var,a4
	
	moveq	#noof_bitplanes*noof_screens-1,d7
dealloc_bitplmem_loop:
	move.l	#bitplane_size,d0
dal_bpm:
	move.l	(a4)+,d1
	bmi.s	dal_bpm	;Vi har lagt nogle -1 ind...
	move.l	d1,a1	
	jsr	LVOFreeMem(a6)
	dbra	d7,dealloc_bitplmem_loop
	rts
restore_copperlist:
* Henter copperlisten, som bliver brugt af Intuition-systemet
* i Amigaen, frem, sådan at den sædvanlige CLI/Workbench-skærm kommer til syne igen.

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

* Her lægger vi nye skærmadresser ind i copperlisten.
* De tages fra bitplane-tabellen, hvorpå show_bitplanes_pointer'en peger.
* Double- og triple-bufferingsrutinerne sørger for af indstillingen af
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

* Vi har nu lavet det sådan at:
* bit 0 = 1: bagover/nedad
* bit 1 = 1: højre
* bit 8 = 1: fremad/opefter
* bit 9 = 1: venstre
* Vi checker så om skydeknappen er trykket ned..

* Først tager vi en rotation rundt om x-aksen, som styres af joystick op/ned.


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
* Hvis skydeknappen er nede, skal det give rotation rundt om Z-aksen,
* men hvis den er oppe, skal det give rotation om Y-aksen.

	btst	#7,$bfe001
 	beq.s	joy_button_pressed

* Ok. Joystick-knappen er ikke nede. Så er en eventuel rotation rundt om Y-aksen

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
	jsr	LVOAllocMem(a6)
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
	jsr	LVOAllocMem(a6)
	move.l	d0,(a4)+
	beq	disaster_no_bitplanemem
	dbra	d6,alloc_bitplmem_loop2
	move.l	#-1,(a4)+
	dbra	d7,alloc_bitplmem_loop1

	move.l	#bitplane_table+var,show_bitplanes_table+var
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
	jsr	LVOFreeMem(a6)
	bra.s	dealloc_nobplm_loop
nobplm_deallocated:
	move.l	tempplane_pointer+var,a1
	subq.l	#2,a1
	move.l	#tempplane_size,d0
	jsr	LVOFreeMem(a6)
disaster_no_tempplanemem:
	moveq	#-100,d0
	addq.l	#4,sp	;Vi returnerer direkte tilbage
	rts

init_copper:
copperlist_size=200
* Maksimal længde på copperlisten er her sat til 200 bytes.
* Det burde være nok i de fleste tilfælde, men hvis du behøver mere
* skal du bare ændre det.

	move.l	$4.w,a6
	move.l	#MEMF_CHIP+MEMF_PUBLIC+MEMF_CLEAR,d1
	move.l	#copperlist_size,d0
	jsr	LVOAllocMem(a6)
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
	
* Så er den første del af copperlisten færdig - nemlig den del, som sætter
* bitplane-adresse-registrene.
* Farve 0 ligger på copperlist+8*noof_planes...

	move.l	#$0180000c,(a0)+	;Farverne lægges ind her.
	
	move.l	#$01940f00,(a0)+	;Farverne på kuben
	move.l	#$01960d00,(a0)+	;Forskellige røde farver
	move.l	#$01980b00,(a0)+
	move.l	#$019a0e66,(a0)+
	move.l	#$019c0900,(a0)+
	move.l	#$019e0a60,(a0)+
	
	move.l	#$01a0088f,(a0)+	;Farverne på pyramiden
	move.l	#$01a20808,(a0)+	;Forskellige blå-violette farver
	move.l	#$01a40f9f,(a0)+
	move.l	#$01a60e0e,(a0)+
	move.l	#$01a8080f,(a0)+
		
	move	#spr0ctl,(a0)+
	move	d2,(a0)+
	move	#spr1ctl,(a0)+
	move	d2,(a0)+	;Fjerner eventuelle sprite-rester...
	
* De næste 6 linier (kommentarlinierne skal ikke tælles med)
* SKAL være med for at int3_handler skal kunne fungere...

	move.l	#$ffdffffe,(a0)+ ;Venter helt til sidst på linie 256
	move.l	#$3509fffe,(a0)+
	move.l	#$3509fffe,(a0)+

* Venter på linien nendeunder den nederste linie som vises...
* Laver interrupt (copper interrupt), som udnyttes af int3_handler...

	move	#intreq,(a0)+
	move	#$8010,(a0)+	;copper interrupt...
	move.l	#$fffffffe,(a0)+	;Afslutter copperlisten.
	
	IF	debug-ON
	lea	$dff000,a5
	move	#$07a0,dmacon(a5)	;Slukker for alle DMA, copper og sprites..	
			;Slukker for blitter nasty, hvis den skulle være tændt.
 	move	#$200+[noof_bitplanes*$1000],bplcon0(a5)	
	move	#0,bpl1mod(a5)
	move	#0,bpl2mod(a5)

	move	#$0038,ddfstrt(a5)
	move	#$00d0,ddfstop(a5)
	move	#$2c81,diwstrt(a5)
	move	#$2cc1,diwstop(a5)

	move.l	d7,cop1lch(a5)	;d7 er starten af copperlisten.
	move.w	copjmp1(a5),d0
	
	move	#$8380,dmacon(a5)	;Tænder igen for DMA og copper,
					;men ikke sprites.
* Tænder også for blitter nasty.
* Det får programmet til at køre en del hurtigere, eftersom rutinerne
* ikke er lagt ind på interrupt (blitteren kan indstilles til at
* lave interrupt, når den er færdig med et "blit")


	ENDIF
	rts
	
init_blitter:
	IF	debug-ON
	bsr	init_line
	move.l	#-1,bltafwm(a5)
	ENDIF
	rts
	
wait_mouse:
	move	#10000,d0
wm1_loop:
	btst	#6,$bfe001
	dbeq	d0,wm1_loop
	beq.s	wait_mouse
* OK. Så har knappen været "oppe" i nogle ms
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


gfxbase:	blk.l	1
gfxname:	d.b	"graphics.library",0
	even

CoordTable:
	d.w	-100*3,-50*3,-50*3
	d.w	0,-50*3,-50*3
	d.w	0,50*3,-50*3
	d.w	-100*3,50*3,-50*3
	
	d.w	-100*3,-50*3,50*3
	d.w	0,-50*3,50*3
	d.w	0,50*3,50*3
	d.w	-100*3,50*3,50*3
	
	d.w	50*3,-50*3,-50*3
	d.w	50*3,-50*3,50*3
	d.w	50*3,50*3,50*3
	d.w	50*3,50*3,-50*3
	d.w	100*3,0,0
CalcCoords:
	blk.w	13*3
DrawCoords:
	blk.l	13
	
object:
	d.w	0,0,0,0,0
	d.w	0,0,0,0,0,0
	d.w	12
	d.l	CoordTable
	d.l	CalcCoords
	d.l	DrawCoords
	d.l	SubTable
	d.w	1	;Antal underobjekter = 2
	
SubTable:
	d.l	Cube,Pyramid

Cube:
	d.w	0,5
	d.l	poly0,poly1,poly2,poly3,poly4,poly5
	
Pyramid:
	d.w	0,4
	d.l	poly6,poly7,poly8,poly9,poly10
	
poly0:	d.w	0
	d.b	10,-1
	d.l	0
	d.w	-1
 	d.l	0
	d.w	3
	d.w	0,1*4,2*4,3*4

poly1:	d.w	0
	d.b	11,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	3
	d.w	4*4,5*4,1*4,0

poly2:	d.w	0
	d.b	12,-1
	d.l	0
	d.w	0	;et underobjekt foran denne flade.
	d.l	FrontPol2Table
	d.w	3
	d.w	1*4,5*4,6*4,2*4

FrontPol2Table:
	d.l	Pyramid

poly3:	d.w	0
	d.b	13,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	3
	d.w	5*4,4*4,7*4,6*4

poly4:	d.w	0
	d.b	14,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	3
	d.w	3*4,2*4,6*4,7*4
poly5:	d.w	0
	d.b	15,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	3
	d.w	4*4,0,3*4,7*4

poly6:	d.w	0
	d.b	16,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	2	;3 hjørner!
	d.w	8*4,12*4,11*4
 
poly7:	d.w	0
	d.b	17,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	2	;3 hjørner!
	d.w	9*4,12*4,8*4

poly8:	d.w	0
	d.b	18,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	2	;3 hjørner!
	d.w	12*4,9*4,10*4

poly9:	d.w	0
	d.b	19,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	2	;3 hjørner!
	d.w	11*4,12*4,10*4

poly10:	d.w	0
	d.b	20,-1
	d.l	0
	d.w	-1
	d.l	0
	d.w	3	;4 hjørner!
	d.w	9*4,8*4,11*4,10*4

	DATA
	
var:	
	blk.b	var_size
