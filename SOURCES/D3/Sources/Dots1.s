* Dots1.s
* bygger på "Skeleton.s" og "rotate.s"
*
* Viser en "kube" bestående af 8 prikker på skærmen.
* Styring med joysticket:
*
* Højre/Venstre: Rotation om Y-aksen
* Op/Ned: Rotation om X-aksen
* Højre/Venstre m/skydeknap nede: Rotation om Z-aksen
*
* Det kan være at du bliver nødt til at skrue op for lyset på skærmen for
* at kunne se prikkerne ordentligt.

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
	
	bsr	wait_mouse

	IFEQ	debug-OFF
	move.l	gfxbase,a6
	jsr	_LVODisownBlitter(a6)
	
	move.l	4.w,a6
	jsr	_LVOPermit(a6)
	ENDC
	bsr	restore_copperlist
	bsr	remove_interrupts
	bsr	dealloc_mem	
	
	move	#$8020,dmacon+$dff000	;På med spritene igen!
Exit:
	moveq	#0,d0
	rts

rotate:
* Roterer koordinatet (d0,d1,d2)
* Returnerer endeligt med perspektiv i (d0,d1), z-værdi i d2!
* Rotation givet ved d3,d4,d5, der d3=rx, d4=ry og d5=rz
	
	pea	(a3)
	pea	(a4)
	
	lea	SinusTable(pc),a4
	lea	CosinusTable(pc),a3

* Disse linier skal selvfølgelig fixes på.
 
	move	(a3,d3.w),cosx(a6)
	move	(a4,d3.w),sinx(a6)
	move	(a3,d4.w),cosy(a6)
	move	(a4,d4.w),siny(a6)
	move	(a3,d5.w),cosz(a6)
	move	(a4,d5.w),sinz(a6)
	
*	x1=x*cosz - y*sinz
*	y1=x*sinz + y*cosz

	move	sinz(a6),d6
	move	cosz(a6),d5
	move	d5,d3	;d3=cosz
	muls	d0,d3	;d3=x*cosz
	move	d6,d4	;d4=sinz
	muls	d1,d4	;d4=y*sinz
	sub.l	d4,d3	;d3=x*cosz - y*sinz (*16384)
	asl.l	#2,d3
	swap	d3
	muls	d6,d0	;d0=x*sinz
	muls	d5,d1	;d1=y*cosz
	add.l	d0,d1	;d1=x*sinz + y*cosz
	asl.l	#2,d1
	swap	d1		;d1=y1, d2=z, d3=x1
	
*	x2=x1*cosy + z*siny
*	z2=-x1*siny + z*cosy

	move	siny(a6),d6
	move	cosy(a6),d5
	move	d5,d0	;d0=cosy
	muls	d3,d0	;d0=x1*cosy
	move	d6,d4	;d4=siny
	muls	d2,d4	;d4=z*siny
	add.l	d4,d0	;d0=x1*cosy+z*siny (*16384)
	asl.l	#2,d0
	swap	d0
	muls	d5,d2	;d2=z*cosy
	muls	d6,d3	;d3=x1*siny
	sub.l	d3,d2	;d2=-x1*siny+z*cosy
	asl.l	#2,d2
	swap	d2		;x2=d0, y1=d1, z2=d2
	
	
*	y3=y1*cosx - z2*sinx
*	z3=y1*sinx + z2*cosx

	move	sinx(a6),d6
	move	cosx(a6),d5
	move	d5,d3
	muls	d1,d3	;d3=y1*cosx
	move	d6,d4
	muls	d2,d4	;d4=z2*sinx
 	sub.l	d4,d3	;d3=y1*cosx-z2*sinx
	asl.l	#2,d3
	swap	d3
	muls	d6,d1	;d1=y1*sinx
	muls	d5,d2	;d2=z2*cosx
	add.l	d1,d2
	asl.l	#2,d2
	swap	d2		;d0=x, d2=z, d3=y

* Dette er et godt tidspunkt at lægge offset-værdierne til på...

*	p=oyep/(oyep+z3), hvor z3 er positiv ind i skærmen
*	x=x3*p+sx
*	y=y3*p+sy
*	RETURN
*
oyep=1000
oyep2=1000*65536>>2 ;Deler tallet med 4 (For at det ikke skal blive for stort)
	
	move	#oyep,d6
	add	d2,d6	;d6=1000+z (Positiv Z = ind i skærmen)
	move.l	#oyep2,d1
	divu	d6,d1
	muls	d1,d0	;=x
	swap	d0
	muls	d3,d1	;=y
	swap	d1
	add.w	#159,d0	;Centrerer koordinatene...
	add.w	#127,d1 ;--------- " ----------
* Returnerer endeligt roteret koordinat i (d0,d1)
	
	move.l	(sp)+,a4
	move.l	(sp)+,a3
	
	rts


init_interrupts:
* Slukker for alle level 3 interrupts bortset fra COPPER-interruptet.
* Tæander så for COPPER-interruptet...
	IFEQ	debug-OFF
	move.l	$6c.w,old_int3handler(a6)
	move	intenar(a5),old_intena(a6)
	move	#$3fff,intena(a5)	;Slukker for vertical bl+copper intr.
	move.l	#int3_handler,$6c.w	;Lægger interrupthandleren ind
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
* Deallokerer al hukommelsen, som blev allokeret i starten af programmet.
	
	move.l	4.w,a6	;A6=Exec-base

	move.l	copperlist_pointer+var,a1
	move.l	#copperlist_size,d0
	jsr	_LVOFreeMem(a6)
	
dealloc_screenmem:	;her havner du hvis allokering af copperlisthukommelsen
			;ikke går godt.
	move.l	#tempplane_size,d0
	move.l	tempplane_pointer+var,a1
	subq.l	#2,a1
	jsr	_LVOFreeMem(a6)

	lea	bitplane_table+var,a4
	
	moveq	#noof_bitplanes*noof_screens-1,d7
dealloc_bitplmem_loop:
	move.l	#bitplane_size,d0
	move.l	(a4)+,a1
	jsr	_LVOFreeMem(a6)
	dbra	d7,dealloc_bitplmem_loop
	rts

restore_copperlist:
* Henter copperlisten frem, som bruges af Intuition-systemet
* i Amigaen, således at den sædvanlige CLI/Workbench-skærm kommer til syne igen.

	move.l	4.w,a0
	move.l	156(a0),a0
	move.l	38(a0),cop1lch+$dff000
	move	copjmp1+$dff000,d0	;Og copperlisten er tilbage igen.
	rts

int3_handler:
* Interrupt level 3.
 
	movem.l	d0-d7/a0-a6,-(sp)

	move	#$0010,intena+$dff000
	
	lea	var,a6

	clr	draw_ready(a6)
	tst	newscreen_flag(a6)
	bne.s	int3_no_new_screen
	
	not	newscreen_flag(a6)

* Her lægges der nogle nye skærmadresser ind i copperlisten.
* De tages fra bitplane-tabellen, som der peges på af show_bitplanes_pointer.
* Double- og triple-bufferingsrutinerne sørger for indstillingen af
* denne pointer.

	move.l	showbitplanes_table(a6),a5
	move.l	copperlist_pointer(a6),a6
	
	addq.l	#2,a6
	move	#noof_bitplanes-1,d7
int3_newaddrs_loop:
	move	(a5)+,(a6)
	move	(a5)+,4(a6)
	addq.l	#8,a6
	dbra	d7,int3_newaddrs_loop
int3_no_new_screen:

	lea	var,a6	
	
	bsr	joystick_move
	
	bsr	calc_dots
	
	move	#$3fff,intreq+$dff000	;Slukker for interrup-requesten igen.

	move	#$8010,intena+$dff000
	movem.l	(sp)+,d0-d7/a0-a6	;For en sikkerheds skyld
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

* Vi har nu ordnet det sådan at:
* bit 0 = 1: bagover/nedover
* bit 1 = 1: højre
* bit 8 = 1: fremover/opover
* bit 9 = 1: venstre
* Vi checker så om skydeknappen er trykket ned..

* Her kommer så rotationen om x-aksen, som styres ved hjælp af joysticket op/ned.


	btst	#0,d0
	beq.s	not_bck
	
	add.l	#$8000,rxs(a6)
	bra.s	not_fwd
not_bck:
	btst	#8,d0
	beq.s	not_fwd
	
	sub.l	#$8000,rxs(a6)
not_fwd:


* Nu skal vi først checke skydeknappen før vi kan behandle
* venstre/højre bevægelsen.
* Hvis skydeknappen er nede, skal det medføre rotation om Z-aksen,
* men hvis den er oppe, skal det medføre rotation om Y-aksen.

	btst	#7,$bfe001
	beq.s	joy_button_pressed

* Ok. Joystick-knappen er ikke nede. Så er der en eventuel rotation om Y-aksen

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

calc_dots:
* Kan ødelægge alle registrene bortset fra A6.
* (A6 = var)
* 1. Fjerner eventuelle gamle pixles på skærmen
* 2. Roterer koordinaterne med de nye vinkler rx,ry og rz.
* 3. Skriver prikkerne ud, og lagrer offsetene der hvor de skal.

	lea	old_dot_offsets(a6),a1
	moveq	#7,d7
clcd_removedots:
	move	(a1)+,d0	;d0=offset til gammel prik..
	beq	oops_first_time	;Ingen prikker at slette i første omgang.

* Sletter pixelen med BYTEoffset D0 i starten af bitplanerne:
	lea	bitplane_table(a6),a0
	moveq	#noof_bitplanes-1,d1
	moveq	#0,d2
clcd_deld_loop:
 	move.l	(a0)+,a2
	move.b	d2,0(a2,d0.w)
	dbra	d1,clcd_deld_loop
* Da er pixelen slettet.
	dbra	d7,clcd_removedots

oops_first_time:

	lea	dot_coords,a5
	lea	clcd_counter(pc),a0
	lea	old_dot_offsets(a6),a4
	move	#7,(a0)
clcd_loop:
	move	(a5)+,d0	;x-koordinat
	move	(a5)+,d1	;y-koordinat
	move	(a5)+,d2	;z-koordinat
	
	move	rx(a6),d3	;x-rotation
	move	ry(a6),d4	;y-rotation
	move	rz(a6),d5	;z-rotation
		
	bsr	rotate	;Giver plot-koordinat (d0,d1), og z-værdi i d2.
	
* Tegner pixelen med koordinaterne (d0,d1), z-værdi d2 (kan bruges til gråtone):
* minz: -350
* maxz: 350
	
	sub	#351,d2	;d2 ligger nu mellem -1 og -701
	neg	d2	;d2 ligger nu mellem 1 og 701
			;701 skal give farve 15, 0 skal give farve 0.
	mulu	#1399,d2
	swap	d2	
	addq	#1,d2	;d2 er nu farvenr 1-15..
	move	d2,d4	;d4 = farvenr...
	
	LnModMul	d1,d2	;d1=d1*lnmod (40 i dette program)
	move	d0,d2
	lsr	#3,d2
	add	d2,d1	;d1=BYTE-offset til denne pixel!
	move	d1,(a4)+
	not	d0	;d0=bitnr som skal sættes/slettes...
	lea	bitplane_table(a6),a3
	moveq	#noof_bitplanes-1,d7
clcd_plot_loop:
	move.l	(a3)+,a2
	ror	#1,d4
	bpl.s	clcd_skipit
	bset	d0,0(a2,d1.w)	;/Her skal vi fikse lidt farver etc..
clcd_skipit:
	dbra	d7,clcd_plot_loop
 
	subq	#1,(a0)
	bpl.s	clcd_loop
	rts

clcd_counter:	dc.w	0


init_vars:
	lea	var,a6
	moveq	#-1,d0
	move.l	d0,set_to_minus1(a6)
	move	#$ff,poly_color(a6)	;vel...
	rts

init_bitplanes:
* Her allokeres hukommelse til bitplanerne!

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
	
	moveq	#noof_bitplanes*noof_screens-1,d7
alloc_bitplmem_loop:
	move.l	#bitplane_size,d0
	move.l	#MEMF_CHIP+MEMF_CLEAR+MEMF_PUBLIC,d1
	jsr	_LVOAllocMem(a6)
	move.l	d0,(a4)+
	beq	disaster_no_bitplanemem
	dbra	d7,alloc_bitplmem_loop
	
	move.l	#bitplane_table+var,showbitplanes_table+var
	rts

disaster_no_bitplanemem:
* Uha da. Denne rutine løser det problem som kan opstå, hvis
* programmet køres på en maskine med for lidt CHIP-MEM.
 * Så må vi deallokere alle bitplanerne, som blev allokeret før vi går
* ud af programmet.

	lea	bitplane_table+var,a4
dealloc_nobplm_loop:
	move.l	(a4)+,d1
	beq	nobplm_deallocated
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
	rts

init_copper:
copperlist_size=200
* Maksimal længde på copperlisten er her sat til 200 bytes.
* Det burde være nok i de fleste tilfælder, men hvis du behøver mere
* er det bare at ændre det.

	move.l	$4.w,a6
	move.l	#MEMF_CHIP+MEMF_PUBLIC+MEMF_CLEAR,d1
	move.l	#copperlist_size,d0
	jsr	_LVOAllocMem(a6)
	move.l	d0,copperlist_pointer+var
	bne.s	ic_clm_alloc_ok
	
* Uha da. Ikke nok hukommelse til en copperliste!
* (Og det kan lade sig gøre..._)
	
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

	move.l	#$01800000,(a0)+	;Lægger svagt øgende
	move.l	#$01820111,(a0)+	;gråtoner ind for at få
	move.l	#$01840222,(a0)+	;"dybde"-effekt
	move.l	#$01860333,(a0)+	;med prikkerne...
	move.l	#$01880444,(a0)+
	move.l	#$018a0555,(a0)+
	move.l	#$018c0666,(a0)+
	move.l	#$018e0777,(a0)+
	move.l	#$01900888,(a0)+
	move.l	#$01920999,(a0)+
	move.l	#$01940aaa,(a0)+
	move.l	#$01960bbb,(a0)+
	move.l	#$01980ccc,(a0)+
	move.l	#$019a0ddd,(a0)+
	move.l	#$019c0eee,(a0)+
	move.l	#$019e0fff,(a0)+
	

	move	#spr0ctl,(a0)+
	move	d2,(a0)+
	move	#spr1ctl,(a0)+
	move	d2,(a0)+	;Fjerner eventuelle sprite-rester...
	
* De 6 efterfølgende linier (kommentarlinierne skal ikke tælles med)
* SKAL være med for at int3_handler skal kunne fungere...

	move.l	#$ffdffffe,(a0)+ ;Venter helt til sidst på linie 256
	move.l	#$2c09fffe,(a0)+
	move.l	#$2c09fffe,(a0)+

* Venter på linien under den nederste af de linier som vises...
* Laver interrupt (copper interrupt), som udnyttes af int3_handler...

	move	#intreq,(a0)+
	move	#$8010,(a0)+	;copper interrupt...
	move.l	#$fffffffe,(a0)+	;Afslutter copperlisten.
	
	IFEQ	debug-OFF
	lea	$dff000,a5
	move	#$03a0,dmacon(a5)	;Slukker for alle DMA, copper og sprites..	
	
	move	#$200+noof_bitplanes*$1000,bplcon0(a5)	
	move	#0,bpl1mod(a5)
	move	#0,bpl2mod(a5)

	move	#$0038,ddfstrt(a5)
	move	#$00d0,ddfstop(a5)
	move	#$2c81,diwstrt(a5)
	move	#$2cc1,diwstop(a5)

	move.l	d7,cop1lch(a5)	;d7 er starten af copperlisten.
	move.w	copjmp1(a5),d0
	
	move	#$8380,dmacon(a5)	;Tænder igen for DMA og copper
					;men ikke for sprites.
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
* OK. Knappen har været "oppe" i nogle ms
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

dot_coords:
	dc.w	-200,-200,-200
	dc.w	200,-200,-200
	dc.w	200,200,-200
	dc.w	-200,200,-200
	dc.w	-200,-200,200
	dc.w	200,-200,200
	dc.w	200,200,200
	dc.w	-200,200,200

	include	VektorProgAmiga:sources/poly.s
	

ofsreset:	macro
ofs_ofs	SET	0
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
	ofs bitplane_table_pointer,4
	ofs showbitplanes_table,4

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
	ofs bitplane_table,4*noof_bitplanes*noof_screens
	ofs copy_destoffset,2
	ofs poly_color,2
	ofs old_intena,2
	ofs old_int3handler,4
	ofs dest_coords,900	
	ofs set_to_minus1,4	;-1 skal stå lige før line_table!
				;Linietegningsrutine som tegner linier bagfra
				;indtil den kommer til et negativt tal.
	ofs line_table,400	;dvs maks 50 hjørner i et polygon.
				;Hvis du behøver flere, skal lave dette
				;array længere.
	ofs hardware_fake,400
	ofs var_size,0

	section	buffer,bss
var:	
	ds.b	var_size
