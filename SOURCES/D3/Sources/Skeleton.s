*************************************************************************
*									*
*				SKELETON				*
*				~~~~~~~~				*
*	Et "skelet"-program, der ligger til grund for alle demo-	*
*	programmerne på disketten.					*
*									*
*									*
*************************************************************************


* Dette programmet indeholder:
*
* 1) Nødvendige opkald til Exec og Graphics bibliotekerne for at programmet
*    skal kunne køre uforstyrret.
* 2) Allokering af bitplan-hukommelse.
* 3) Alt som skal til for at gå ud af programmet igen på en måde som
*    ikke "crasher" maskinen.


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
* Denne bør ALTID STÅ SÅDAN!
* Dersom mouse_wait = ON, vil poly-rutinen vente på et tryk på museknappen for
* hver eneste linie, den skal tegne. Det er kun ment som en debugging.

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
	
	IFEQ	debug-OFF
	bsr	init_blitter
	bsr	init_interrupts
	ENDC


	
* Her setter du inn ditt hovedprogram!



	IFEQ	debug-OFF
	move.l	gfxbase,a6
	jsr	_LVODisownBlitter(a6)
	
	move.l	4.w,a6
	jsr	_LVOPermit(a6)
 	
	bsr	restore_copperlist
	bsr	remove_interrupts
	ENDC
	
	bsr	dealloc_mem	
	
Exit:
	moveq	#0,d0
	rts

init_interrupts:
* Slukker for alle level 3 interrupts bortset fra COPPER-interruptet.
* Tænder så for COPPER-interruptet...
	move.l	$6c.w,old_int3handler(a6)
	move	intenar(a5),old_intena(a6)
	move	#$3fff,intena(a5)	;Slukker for vertical bl+copper intr.
	move.l	#int3_handler,$6c.w	;Lægger interrupthandleren ind
	move	#$c010,intena(a5)	;Tænder for copper-interrupt.
	rts

remove_interrupts:
* Lægger de gamle level 3 interrupt tilbage...
	move	old_intena+var,d0
	or	#$c000,d0
	move	#$0030,intena(a5)
	move.l	old_int3handler+var,$6c.w
	move	d0,intena(a5)
	rts

dealloc_mem:
* Reallokerer al hukommelsen, som blev allokeret i starten af programmet.
	
	move.l	4.w,a6	;A6=Exec-base

	move.l	copperlist_pointer+var,a1
	move.l	#copperlist_size,d0
	jsr	_LVOFreeMem(a6)
	
dealloc_screenmem:	;hopper her til, hvis allokeringen af copperlisthukommelse
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
* Henter copperlisten, som bliver brugt af Intuition-systemet
* i Amigaen, frem, sådan at den sædvanlige CLI/Workbench-skærm kommer til syne igen.

	move.l	4.w,a0
	move.l	156(a0),a0
	move.l	38(a0),cop1lch+$dff000
	move	copjmp1(a5),d0	;Og copperlisten er tilbage igen.
	rts

int3_handler:
* Interrupt level 3.
* Vi tillader kun copper-interruptet af level 3 interruptsene,
* så hvis denne rutine kaldes op, SKAL det være pga af copper-interrupt.
* Denne rutine kan IKKE ødelægge nogen registre! OBS!
* Det vil garanteret forårsage et grimt nedbrud af maskinen!

	move	#$0010,intena+$dff000
	pea	(a6)
	pea	(a5)
	move	d7,-(sp)
	
	lea	var,a6
	clr	draw_ready(a6)
	tst	newscreen_flag(a6)
	bne.s	int3_no_new_screen
	
	not	newscreen_flag(a6)

* Her lægges nye skærmadresser ind i copperlisten.
* De tages fra bitplane-tabellen, hvorpå show_bitplanes_pointer'en peger.
* Double- og triple-bufferingsrutinerne tager sig af indstillingen af
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
	move	#$3fff,intreq+$dff000	;Slukker for interrupt-requesten igen.

	move	(sp)+,d7
	move.l	(sp)+,a5
	move.l	(sp)+,a6
	
* Her er masser af plads til at lægge musik ind, hvis du kunne tænke dig det.
* Ex.:
* 	movem.l	d0-d7/a0-a6,-(sp)
*	jsr	play_music
*	movem.l	(sp)+,d0-d7/a0-a6
*
* Her er play_music en rutine, som skal kaldes op 50 gange i sekundet
* for at spille musikken.
* Sådanne rutiner følger med de fleste musik-programmer, som er egnede
* til demo-brug (f.eks. Soundtracker, Protracker etc..)
	
	move	#$8010,intena+$dff000
	rte	;returnerer fra interruptet.
	
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
* Uha da. Denne rutine tager sig af det problemet, som kan opstå hvis
* programmet køres på en maskine med for lidt CHIP-MEM.
* Så skal vi reallokere alle bitplanerne, som blev allokeret før vi går
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
* Det burde være nok i de fleste tilfælde, men hvis du behøver mere,
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
	
* Så er den første del af copperlisten færdig - nemlig den del, som sætter
* bitplane-adresse-registrene.

*
** OBS! Hvis du vil have mere med i copperlisten skal du tage det med her.
*

* De næste 6 linier (kommentarlinierne skal ikke tælles med)
* SKAL være med for at int3_handler skal kunne fungere...

	move.l	#$ffdffffe,(a0)+ ;Venter helt til sidst på linie 256
	move.l	#$2c09fffe,(a0)+
	move.l	#$2c09fffe,(a0)+

* Venter på linien nedenunder den nederste linie, som vises...
* Laver interrupt (copper interrupt), som udnyttes af int3_handler...

	move	#intreq,(a0)+
	move	#$8010,(a0)+	;copper interrupt...
	move.l	#$fffffffe,(a0)+	;Afslutter copperlisten.
	
 	IFEQ	debug-OFF
	lea	$dff000,a5
	move	#$0380,dmacon(a5)	;Slukker for alle DMA..	
	
	move	#$200+noof_bitplanes*$1000,bplcon0(a5)	
	move	#0,bpl1mod(a5)
	move	#0,bpl2mod(a5)

	move	#$0038,ddfstrt(a5)
	move	#$00d0,ddfstop(a5)
	move	#$2c81,diwstrt(a5)
	move	#$2cc1,diwstop(a5)

	move.l	d7,cop1lch(a5)	;d7 er starten på copperlisten.
	move.w	copjmp1(a5),d0
	
	move	#$8380,dmacon(a5)	;Tænder for DMA igen.
	ENDC
	rts
	
init_blitter:
	bsr	init_line
	move.l	#-1,bltafwm(a5)
	rts
	
wait_mouse:
	move	#10000,d0
wm1_loop:
	btst	#6,$bfe001
	dbeq	d0,wm1_loop
	beq.s	wait_mouse
* OK. Så har museknappen været "oppe" i nogle ms
wm2_loop:
	btst	#6,$bfe001
	bne.s	wm2_loop
* Nu er der blevet trykket på knappen...
wm3_redo:
	move	#10000,d0
wm3_loop:
	btst	#6,$bfe001
	dbeq	d0,wm3_loop
	beq.s	wm3_redo	;Og den har været oppe igen nogle ms...
	rts

gfxbase:	ds.l	1
gfxname:	dc.b	"graphics.library",0
	even

	include	VektorProgAmiga:sources/poly.s
	

ofsreset:	macro
ofs_ofs	SET	0
	endm
	
ofs:	macro
\1=ofs_ofs
ofs_ofs	SET	ofs_ofs+\2
	endm
	
* ofs og ofsreset får her samme funktion som rs og rsreset i DEVPAC...
* ofs og ofsreset fungerer imidlertid på alle assemblere (ikke SEKA).

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
	ofs set_to_minus1,4	;-1 Skal stå lige før line_table!
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
