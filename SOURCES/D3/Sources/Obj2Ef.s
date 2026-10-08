* Obj2Ef.
* bygger på "kube1.s", men er lidt mindre.
* Så er man garanteret helt jævne bevægelser.

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
	
* Her indsættes hovedprogrammet..

	bsr	init_triplebuf
	
	lea	var,a6	
main_loop:
	bsr	delete_oldpolys	;Skal vente på klar-signal!
				;checker om draw_ready(a6) er 0. Da er
				;det klart...
	bsr	draw_polys
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
	bsr	dealloc_mem	
	
	move	#$0400,dmacon+$dff000	;Slukker for blitter nasty.
	move	#$8020,dmacon+$dff000	;Tænder for sprites igen!
Exit:
	moveq	#0,d0
	rts


draw_polys:
* Først kaldes joystick_move op for at få rotations-bevægelsen.
* Så roteres alle koordinaterne
* Til sidst tegnes de SYNLIGE polygoner op i tilfældig rækkefølge,
 * eftersom kuben er et konvekst objekt.
* Synlighedskontrollen foregår i "Clockwise"-rutinen.
	bsr	joystick_move
	bsr	rotate_coords
	move	#400,poly_minx(a6)
	move	#400,poly_miny(a6)
	move	#0,poly_maxx(a6)
	move	#0,poly_maxy(a6)
	bsr	plot_polys
	
	move	poly_minx(a6),draw_minx(a6)
	move	poly_miny(a6),draw_miny(a6)
	move	poly_maxx(a6),draw_maxx(a6)
	move	poly_maxy(a6),draw_maxy(a6)

	rts

plot_polys:
* Gennemgår polygonerne i tabellen et for et.
* Bygger en liste i poly_koords, og sender en pointer til 
* "clockwise"-rutinen's liste.
* Hvis den er synlig, optegnes polygonet.
* Hvis ikke, hoppes der til det næste.
	lea	poly0,a4
	lea	kube_plotcoords,a3
	move	#5,-(sp)	;Antal sideflater -1.
	move	#0,poly_color(a6)
plpols_loop:
	addq	#1,poly_color(a6)
	lea	poly_coords,a1
	move	(a4)+,d0
	move.l	0(a3,d0.w),(a1)+
	move	(a4)+,d0
	move.l	0(a3,d0.w),(a1)+
	move	(a4)+,d0
	move.l	0(a3,d0.w),(a1)+
	move	(a4)+,d0
	move.l	0(a3,d0.w),(a1)
	lea	-12(a1),a1	;a1 peger nu på det første koordinat
	bsr	clockwise	;checker om polygonet er synligt eller ej.
	bmi.s	plpl_notvisible
	
	lea	dest_coords(a6),a0
	moveq	#4,d6
	moveq	#2,d7
	pea	(a4)
	pea	(a3)
	bsr	draw_poly
	move.l	(sp)+,a3
	move.l	(sp)+,a4
	
plpl_notvisible:
	subq	#1,(sp)
	bpl.s	plpols_loop
	addq.l	#2,sp
	rts
* Nu er alle de synlige polygoner tegnet.

clockwise:
* koordinaterne ligger i (a1)+...
	move	(a1)+,d4
	move	(a1)+,d5
	move	(a1)+,d0
	move	(a1)+,d1
	move	(a1)+,d2
	move	(a1)+,d3
	lea	-12(a1),a1
	
	sub	d0,d2	;d2=1->2 vektor, x-komponent
	sub	d1,d3	;d3=1->2 vektor, y-komponent
	sub	d4,d0	;d0=0->1 vektor, x-komponent
	sub	d5,d1 	;d1=0->1 vektor, y-komponent

	muls	d0,d3
	muls	d1,d2
	sub.l	d2,d3
	rts	d3>=0: synlig, d3<0:usynlig.

rotcnt:	ds.w	1
rotate_coords:
	lea	kube_coords,a0
	lea	kube_plotcoords,a1
	lea	rotcnt(pc),a2
	move	#7,(a2)
rt_crds_loop:
	move	(a0)+,d0
	move	(a0)+,d1
	move	(a0)+,d2
	move	rx(a6),d3
	move	ry(a6),d4
	move	rz(a6),d5
	bsr	rotate
	move	d0,(a1)+
	move	d1,(a1)+
	subq	#1,(a2)
	bpl.s	rt_crds_loop
	rts
		
init_triplebuf:
* Sætter pointerne, som bruges til triple-buffering.
* OBS! Du SKAL have sat noof_screens til 3 for at kunne bruge rutinen!
	lea	bitplane_table(a6),a0
	move.l	a0,show_bitplanes_table(a6)
	lea	4*(noof_bitplanes+1)+bitplane_table(a6),a0
	move.l	a0,draw_bitplanes_table(a6)
 	lea	bitplane_table+8*(noof_bitplanes+1)(a6),a0
	move.l	a0,visibl_bitplanes_table(a6)
* Det var bitplane-pointerne.
* Så skal også lave delete-tabellerne.
* I dette program er det bare et spørsmål om at huske, hvor stor en firkant
* kuben optog, og så slette det område fra bitplanerne...
	move.l	#-1,visibl_minx(a6)
	move.l	#-1,draw_minx(a6)
	move.l	#-1,show_minx(a6)
	rts

triplebuf:
* Her ordnes triple-bufferingen, dvs slette-informationen og
* bitplane-adresse-tabellerne roteres.
	move.l	show_minx(a6),d0
	move.l	show_maxx(a6),d1
	move.l	draw_minx(a6),show_minx(a6)		
	move.l	draw_maxx(a6),show_maxx(a6)
	move.l	visibl_minx(a6),draw_minx(a6)
	move.l	visibl_maxx(a6),draw_maxx(a6)
	move.l	d0,visibl_minx(a6)
	move.l	d1,visibl_maxx(a6)
	
	move.l	show_bitplanes_table(a6),d0
	move.l	 draw_bitplanes_table(a6),show_bitplanes_table(a6)	
	move.l	 visibl_bitplanes_table(a6),draw_bitplanes_table(a6)
	move.l	d0,visibl_bitplanes_table(a6)

* Så skal der signaleres til int3_handler, at en ny skærm er klar til
* visning, når blitteren er færdig:

trplbuf_waitblt:
	btst	#6,dmaconr(a5)
	bne.s	trplbuf_waitblt

	clr	newscreen_flag(a6)
	rts

delete_oldpolys:
	tst	draw_ready(a6)
	bne.s	delete_oldpolys
	not	draw_ready(a6)	;Sørger for at der går mindst en skærm-
				;opdatering før næste bitplan bliver
				;slettet.
	move	draw_minx(a6),d0
	bmi	oops_delop_none	;1., 2. eller 3. gang
				;rutinen kaldes er der
				;ingenting at slette.
 	move	draw_miny(a6),d1
	move	draw_maxx(a6),d2
	move	draw_maxy(a6),d3
	
* Vi skal nu slette firkanten givet ved (d0,d1)-(d2,d3)
* i alle bitplanerne.
* Vi må omregne til startadresse, bltsize og modulo...

	lsr	#4,d0	;d0=minx/16	
	lsr	#4,d2	;d2=maxx/16
	addq	#1,d2	;+1
	sub	d0,d2	;d2=Antal words i bredden
	add	d0,d0	;d0=start-offset i x-retning
	sub	d1,d3	
	addq	#1,d3	;d3=antal linier i y-retning
	mulu	#40,d1	;d1=y-offset
	add	d0,d1	;d1=start-adresse-offset for sletningen.	
	
	lsl	#6,d3
	or	d2,d3	;d3=bltsize
	add	d2,d2
	neg	d2
	add	#40,d2	;d2=bltdmod
* Nu er det bare at arbejde sig igennem alle bitplanerne.
	moveq	#noof_bitplanes-1,d7
	move.l	draw_bitplanes_table(a6),a1
del_bpls_loop:
	move.l	(a1)+,a0	;Adressen på bitplanet i a0
dbpl_waitblit:
	IFEQ	line_waitblit+1
	btst	#6,dmaconr(a5)
	bne.s	dbpl_waitblit
	ENDC
	lea	0(a0,d1.w),a0	;a0 = startadresse for sletningen
	move.l	a0,bltdpth(a5)
	move	d2,bltdmod(a5)
	move	#$0100,bltcon0(a5)	;D=0.
	move	#0,bltcon1(a5)
	move	d3,bltsize(a5)	;Starter sletningen
	dbra	d7,del_bpls_loop

* Nu er området slettet.

oops_delop_none:
	rts
	
rotate:
* Roterer koordinatet (d0,d1,d2)
* Returnerer med perspektiv i (d0,d1), z-værdi i d2!
* Rotation givet ved d3,d4,d5, hvor d3=rx, d4=ry og d5=rz
* Ødelægger alle dataregistrene, ingen adresseregistre.

	pea	(a3)
 	pea	(a4)
	
	lea	SinusTable(pc),a4
	lea	CosinusTable(pc),a3

	move	(a3,d3.w),cosx(a6)
	move	(a4,d3.w),sinx(a6)
	move	(a3,d4.w),cosy(a6)
	move	(a4,d4.w),siny(a6)
	move	(a3,d5.w),cosz(a6)
	move	(a4,d5.w),sinz(a6)
	
;	x1=x*cosz - y*sinz
;	y1=x*sinz + y*cosz

	move	sinz(a6),d6
	move	cosz(a6),d5
	move	d5,d3	d3=cosz
	muls	d0,d3	d3=x*cosz
	move	d6,d4	d4=sinz
	muls	d1,d4	d4=y*sinz
	sub.l	d4,d3	d3=x*cosz - y*sinz (*16384)
	asl.l	#2,d3
	swap	d3
	muls	d6,d0	d0=x*sinz
	muls	d5,d1	d1=y*cosz
	add.l	d0,d1	d1=x*sinz + y*cosz
	asl.l	#2,d1
	swap	d1		d1=y1, d2=z, d3=x1
	
*	x2=x1*cosy + z*siny
*	z2=-x1*siny + z*cosy

	move	siny(a6),d6
	move	cosy(a6),d5
	move	d5,d0	d0=cosy
	muls	d3,d0	d0=x1*cosy
	move	d6,d4	d4=siny
	muls	d2,d4	d4=z*siny
	add.l	d4,d0	d0=x1*cosy+z*siny (*16384)
	asl.l	#2,d0
	swap	d0
	muls	d5,d2	d2=z*cosy
	muls	d6,d3	d3=x1*siny
	sub.l	d3,d2	d2=-x1*siny+z*cosy
	asl.l	#2,d2
	swap	d2		x2=d0, y1=d1, z2=d2
	
	
*	y3=y1*cosx - z2*sinx
*	z3=y1*sinx + z2*cosx

	move	sinx(a6),d6
	move	cosx(a6),d5
 	move	d5,d3
	muls	d1,d3	d3=y1*cosx
	move	d6,d4
	muls	d2,d4	d4=z2*sinx
	sub.l	d4,d3	d3=y1*cosx-z2*sinx
	asl.l	#2,d3
	swap	d3
	muls	d6,d1	d1=y1*sinx
	muls	d5,d2	d2=z2*cosx
	add.l	d1,d2
	asl.l	#2,d2
	swap	d2		d0=x, d2=z, d3=y
* Dette er et godt tidspunkt at lægge offset-værdierne til på...

*	p=oyep/(oyep+z3), hvor z3 er positiv ind i skærmen
*	x=x3*p+sx
*	y=y3*p+sy
*	RETURN
*
oyep=1000
oyep2=1000*65536>>2 Deler tallet med 4 (For at det ikke skal blive for stort)
	
	move	#oyep,d6
	add	d2,d6	d6=1000+z (Positiv Z = ind i skærmen)
	move.l	#oyep2,d1
	divu	d6,d1
	muls	d1,d0	=x
	swap	d0
	muls	d3,d1	=y
	swap	d1
	add.w	#159,d0	;Centrerer koordinatene...
	add.w	#127,d1 ;--------- " ----------
* Returnerer færdig-roteret koordinat i (d0,d1)
	
	move.l	(sp)+,a4
	move.l	(sp)+,a3
	
	rts


init_interrupts:
* Slukker for alle level 3 interrupts bortset fra COPPER-interruptet.
* Tænder så for COPPER-interruptet...
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
* Reallokerer al hukommelsen, som blev allokeret i starten af programmet.
	
	move.l	4.w,a6	;A6=Exec-base

	move.l	copperlist_pointer+var,a1
	move.l	#copperlist_size,d0
	jsr	_LVOFreeMem(a6)
	
dealloc_screenmem:	;hopper her til, hvis allokeringen af copperlisthukommelsen
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
* Hvis skydeknappen er nede, skal det give en rotation om Z-aksen,
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

noof_bitplanes=3	;antal bitplanes
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
	rts

disaster_no_bitplanemem:
* Uha da. Denne rutin tager sig af det problem, som kan opstå, hvis
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
	rts

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
	addq	#2,d1	;d1=neste bplxpth
	dbra	d0,crcl_loop1
	
* Nu er den første del af copperlisten færdig - nemlig den del, som sætter
* bitplane-adresse-registrene.
* Farve 0 ligger på copperlist+8*noof_planes...

	move.l	#$0180000c,(a0)+	;Farvene lægges ind her.
	move.l	#$01820f00,(a0)+
	move.l	#$01840d00,(a0)+
	move.l	#$01860b00,(a0)+
	move.l	#$01880e66,(a0)+
	move.l	#$018a0900,(a0)+
	move.l	#$018c0a55,(a0)+
	move.l	#$018e0777,(a0)+

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
	
	move	#$8380,dmacon(a5)	;Tænder igen for DMA og copper,
					;men ikke sprites.
* Tænder også for blitter nasty.
* Det får programmet til at køre en del hurtigere, eftersom rutinerne
* ikke er lagt ind på interrupt (blitteren kan indstilles til at
* lave interrupt, når den er færdig med et "blit")


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
* Og nu er der blevet trykket på knappen...
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

kube_coords:
	dc.w	-100,-100,-100	;Dette er de samme koordinater, som
	dc.w	100,-100,-100	;i kube1.s, men her har vi delt alle
	dc.w	100,100,-100	;sammen med 2.
	dc.w	-100,100,-100	;Objektet bliver da mindre, og det kan
	dc.w	-100,-100,100	;bevæges hurtigere. Da kube1 næsten
	dc.w	100,-100,100	;klarer at kunne opdateres ca 50 gange i
	dc.w	100,100,100	;sekundet, vil denne klare det uden
	dc.w	-100,100,100	;problemer.

poly_coords:
	ds.w	8

kube_plotcoords:
	ds.w	2*8
	
poly0:	dc.w	0*4,1*4,2*4,3*4	;Disse 6 skal ligge LIGE efter hinanden
poly1:	dc.w	5*4,4*4,7*4,6*4	;i dette program.
poly2:	dc.w	0*4,4*4,5*4,1*4
poly3:	dc.w	3*4,2*4,6*4,7*4
poly4:	dc.w	1*4,5*4,6*4,2*4
poly5:	dc.w	4*4,0*4,3*4,7*4

	include	VektorProgAmiga:sources/poly.s

ofsreset:	macro
ofs_ofs:	SET	0
	endm
	
ofs:	macro
\1=ofs_ofs
ofs_ofs:	SET	ofs_ofs+\2
	endm
	
* ofs og ofsreset får her samme funktion som rs og rsreset i DEVPAC...
* ofs og ofsreset fungerer imidlertid på alle assemblere.

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
	ofs bitplane_table,4*noof_bitplanes*(noof_screens+1) ;Sæt -1 ind efter hver!
	ofs copy_destoffset,2
	ofs poly_color,2
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
