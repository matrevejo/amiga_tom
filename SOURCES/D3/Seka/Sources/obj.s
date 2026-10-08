* Obj.s
* Alle vektorrutiner som har hovedobjekter og underobjekter
* bruger rutinerne i dette program.

* Her er definitionerne på elementnavnene, som er i de forskellige
* objekt-strukturer:

objStatus=0
objMinX=2
objMinY=4
objMaxX=6
objMaxY=8
objX=10
objY=12
objZ=14
objRX=16
objRY=18
objRZ=20
objNoCrd=22
objCrd=24
objClCrd=28
objPlCrd=32
objSubs=36
objNoSubs=40

subStatus=0
subNoPoly=2
subPolys=4

polyStatus=0
polyFCol=2
polyBCol=3
polySame=4
polyNoFrn=8
polyFrnTb=10
polyNoCrd=14
polyCords=16



init_triplebuf:
* Sætter pointerne, som bruges til triple-buffering.
* OBS! Du skal have sat noof_screens til 3 for at kunne bruge triple-buffering!

	lea	bitplane_table(a6),a0
	move.l	a0,show_bitplanes_table(a6)
	lea	[4*[noof_bitplanes+1]]+bitplane_table(a6),a0
	move.l	a0,draw_bitplanes_table(a6)
	lea	bitplane_table+[8*[noof_bitplanes+1]](a6),a0
	move.l	a0,visibl_bitplanes_table(a6)

* Det var bitplane-pointerne.
* Så må vi også ordne delete-tabellerne således at
* restore/delete rutinerne ikke prøver at slette noget før
* der er noget at slette:
	
	move	#0,draw_minx(a6)
	move	#0,draw_miny(a6)
	move	#319,draw_maxx(a6)
	move	#255,draw_maxy(a6)	;Sørger for baggrundsgrafikken
					;bliver kopieret ind.
	move	#0,show_minx(a6)
	move	#0,show_miny(a6)
	move	#319,show_maxx(a6)
	move	#255,show_maxy(a6)	;Sørger for baggrundsgrafikken
					;bliver kopieret ind.
	move	#0,visibl_minx(a6)
	move	#0,visibl_miny(a6)
	move	#319,visibl_maxx(a6)
	move	#255,visibl_maxy(a6)	;Sørger for at baggrundsgrafikken
					;bliver kopieret ind.
	rts

draw_mainobj:
* Tager sig af det meste.
* Initialiserer poly_minx, miny, maxx og maxy.
* Roterer koordinaterne i hovedobjektet.
* "Sorterer" underobjekterne med sædvanlig metode.
* Tegner objektet fuldstændigt.
* Lagrer delete/recover-information
* (i draw_minx, draw_miny osv...)
* Kaldes op med adressen på hovedobjektet i A0

	move.l	a0,current_mainobj(a6)
	
	moveq	#-1,d0
	move	d0,poly_maxx(a6)
	move	d0,poly_maxy(a6)
	move	#2000,poly_minx(a6)
	move	#2000,poly_miny(a6)
	
	move	objRX(a0),d3
	move	objRY(a0),d4
	move	objRZ(a0),d5
	
	bsr	rotate_mainobj	;Tager sig af rotationen.

* Så initialiserer vi underobjekterne og polygonerne.
* Samtidig kan vi foretage synligheds-kontrollen af polygonerne:

	move.l	objPlCrd(a0),a3	;a3=adresse på plotcoords-tabellen
 	move	objNoSubs(a0),d1	;d1=antal underobjekter -1
	move.l	objSubs(a0),a1	;a1=Tabel over underobjekt..
dm_initsubs_loop:
	swap	d1		;gemmer d1.w til senere brug
	move.l	(a1)+,a2
	move	#0,(a2)+	;Nulstiller status-wordet i underobjektet.
* Nu kan vi checke "synligheden" af hvert enkelt polygon, som hører til
* dette underobjekt.
	move	(a2)+,d7	;d7=antal polygoner -1.
	swap	d0		;Gemmer indholdet af d0.w
dm_init_polys_loop:
	move.l	(a2)+,a4	;a4=adressen på dette polygon
	move	#1,(a4)	;vi "antager" at det er synligt. Det forandres senere hvis
			;usynligt.
	lea	16(a4),a4	;a4=adresse på første koordinat-indeks.
	
	move	(a4)+,d0
	move	0(a3,d0.w),d4
	move	2(a3,d0.w),d5
	move	(a4)+,d2
	move	0(a3,d2.w),d0
	move	2(a3,d2.w),d1
	move	(a4)+,d3
	move	0(a3,d3.w),d2
	move	2(a3,d3.w),d3
	sub	d0,d2
	sub	d1,d3
	sub	d4,d0
	sub	d5,d1
	muls	d0,d3
	muls	d1,d2
	sub.l	d2,d3	;d3<0: Usynlig, d3>=0: synlig.
	bpl.s	dm_ipl_visible
	neg	-22(a4)	;-22(a4) er starten på poly-strukturen.
dm_ipl_visible:
	dbra	d7,dm_init_polys_loop
	swap	d1
	dbra	d1,dm_initsubs_loop
	
* Nu er synligheden af alle sideflader testet.
* Nu mangler hovedobjektet bare at blive optegnet.
* Det gøres således:
*
* Vi kalder draw_firstsub op med underobjekt0 som parameter.
* ALLE de andre underobjekter i hovedobjektet tegnes derfra.
* underobjekter, som ligger på forsiden/ydersiden af en usynlig side, skal
* tegnes før underobjekt 0, og resten skal tegnes derefter...
 	
* For resten af underobjekterne gælder at kun underobjekter, som skal
* tegnes op FØR disse, tegnes derfra.

	move.l	objSubs(a0),a0
	move.l	(a0),a0	;a0 er nu i starten af underobjekt 0,
			;som skal tegnes op med en draw_firstsub
	bsr	draw_firstsub
* Og det er det.
* Resten tager draw_firstsub sig af.
 	move	poly_minx(a6),draw_minx(a6)
 	move	poly_maxx(a6),draw_maxx(a6)
 	move	poly_miny(a6),draw_miny(a6)
 	move	poly_maxy(a6),draw_maxy(a6)
 	rts
draw_firstsub:
* Først gennemgås alle polygonerne i underobjektet.
* Hvis der er nogle, som er "usynlige", skal alle underobjekterne,
* som er på forsiden af det polygon, tegnes.
* Derefter skal dette underobjekt tegnes - først de "usynlige" flader
* (Hvis nogle af dem skulle have en anden farve end -1), og så de
* synlige.
* Til sidst skal alle underobjekter, som er foran de SYNLIGE
* flader tegnes. OBS! Dette gælder kun for draw_firstsub, ikke for
* draw_sub!

* Adressen på underobjektet ligger i A0
	
	move	#1,(a0)+	;Status = optegnet (sådan at den ikke
				;bliver tegnet flere gange)
	pea	(a0)
	move	(a0)+,d0	;Antal koordinater -1
dfsub_loop1:
	move	d0,-(sp)
	move.l	(a0)+,a1	;a1 = et af polygonerne
	tst	(a1)
	bpl.s	fd_sb1l_notb
; Her er en potentiel usynlig - sidefladen er i det mindste usynlig
	tst	polyNoFrn(a1)
	bmi.s	fd_sb1l_notb
; Her har vi en sideflade, som har "bagsiden frem" og som derudover
; har et eller flere underobjekter foran sig. Så er det bare at tegne dem:
 	pea	(a0)
	move	polyNoFrn(a1),d1	;d1=antal underobjekter foran -1
	move.l	polyFrnTb(a1),a1	;Underobjekterne er i a1!
dfsub_l1_frloop:
	move.l	(a1)+,a0
	tst	(a0)
	bne.s	dfl1fr_alr_drawn
	move	d1,-(sp)
	pea	(a1)
	bsr	draw_sub
	move.l	(sp)+,a1
	move	(sp)+,d1
dfl1fr_alr_drawn:
	dbra	d1,dfsub_l1_frloop
	move.l	(sp)+,a0
fd_sb1l_notb:
	move	(sp)+,d0
	dbra	d0,dfsub_loop1

* Ok. Det var første fase.
* Fase 2 består i at tegne alle de polygoner, der har bagsiden frem.

	move.l	(sp),a0	;a0 peger nu direkte på subNoPoly
	move	(a0)+,d0	;d0=antal igen
dfsub_loop2:
	move.l	(a0)+,a1
	tst	(a1)
	bpl.s	dfsl2_skip
	move.b	3(a1),d1
	bmi.s	dfsl2_skip
* Ok. Nu har vi en bagside, der skal plottes ud
	move	d0,-(sp)
	pea	(a0)
	bsr	draw_back	;Tegner en "anti-clockwise" figur,
			;med pointer til polygonstrukturen i a1
			;og farven i d1.b
	move.l	(sp)+,a0
	move	(sp)+,d0
dfsl2_skip:
	dbra	d0,dfsub_loop2

* Nu er alle sidefladerne på "bagsiden" tegnet.
* Så er det forsidens tur:

	move.l	(sp),a0	;a0 peger nu direkte på subNoPoly
	move	(a0)+,d0
dfsub_loop3:
	move.l	(a0)+,a1
	tst	(a1)
	bmi.s	dfsl3_skip
	move.b	2(a1),d1
	bmi.s	dfsl3_skip
* OK. nu har vi en forside, som skal plottes ud
	move	d0,-(sp)
	pea	(a0)
	bsr	draw_front	;Tegner en "clockwise" figur,
			;med pointer til polygonstrukturen i a1
			;og farven i d1.b
	move.l	(sp)+,a0
	move	(sp)+,d0
dfsl3_skip:
	dbra	d0,dfsub_loop3

	move.l	(sp)+,a0
	move	(a0)+,d0	;Antal koordinater -1
dfsub_loop4:
	move	d0,-(sp)
	move.l	(a0)+,a1	;a1 = et af polygonerne
	tst	(a1)
	bmi.s	fd_sb4l_notf
; Her er en potentiel synlig - sidefladen er i det mindste synlig
	tst	polyNoFrn(a1)
	bmi.s	fd_sb4l_notf
; Her har vi en sideflade, som vises, og som derudover
; har et eller flere underobjekter foran sig. Så er det bare at tegne dem:

	pea	(a0)
	move	polyNoFrn(a1),d1	;d1 = antal underobjekter foran -1
	move.l	polyFrnTb(a1),a1	;Underobjekterne er i a1!
dfsub_l4_frloop:
	move.l	(a1)+,a0
	tst	(a0)
	bne.s	dfl4fr_alr_drawn
	move	d1,-(sp)
	pea	(a1)
	bsr	draw_sub
	move.l	(sp)+,a1
	move	(sp)+,d1
dfl4fr_alr_drawn:
	dbra	d1,dfsub_l4_frloop
	move.l	(sp)+,a0
fd_sb4l_notf:
	move	(sp)+,d0
	dbra	d0,dfsub_loop4

* Nu er vi færdige!
	rts

draw_front:
* fargenr i d1
* poly-structur i a1
* current_mainobj(a6) = adressen på det aktuelle hovedobjekt.
 
	move	d1,poly_color(a6)
	lea	objline_table(a6),a2	;(a2)+=DEST.
	move.l	current_mainobj(a6),a0	;a0=object
	move.l	objPlCrd(a0),a0	 ;a0=plot-koordinat-tabellen
	move	polyNoCrd(a1),d6	;d6=antal koordinater-1
	move	d6,d7	;d6 og d7 = antal koordinater -1
	lea	polyCords(a1),a1	;a1=koordinat-indeks
					;(i urets retning)
* Så kopierer vi koordinaterne ind i rækkefølge.

drwf_loop:
	move	(a1)+,d0	;d0=koordinatindeks osv...
	move	0(a0,d0.w),(a2)+
	move	2(a0,d0.w),(a2)+
	dbra	d7,drwf_loop
	
	move	d6,d7
	subq	#1,d7
	addq	#1,d6
	lea	dest_coords(a6),a0
	lea	objline_table(a6),a1
	bra	draw_poly

draw_back:
* farvenr i d1
* poly-struktur i a1
* current_mainobj(a6) = adressen på det aktuelle hovedobjekt.

	move	d1,poly_color(a6)
	lea	objline_table+200(a6),a2	;-(a2)=DEST.
	move.l	current_mainobj(a6),a0	;a0=object
	move.l	objPlCrd(a0),a0	;a0=plot-koordinat-tabellen
	move	polyNoCrd(a1),d6	;d6=antal koordinater-1
	move	d6,d7	;d6 og d7 = antal koordinater -1
	lea	polyCords(a1),a1	;a1=koordinat-indeks
					;(mod uret)
* Så kopierer vi koordinaterne ind i modsat rækkefølge:

drwb_loop:
	move	(a1)+,d0	;d0=koordinatindeks osv...
	move	2(a0,d0.w),-(a2)
	move	0(a0,d0.w),-(a2)
	dbra	d7,drwb_loop
	
	move	d6,d7
	subq	#1,d7
	addq	#1,d6
	lea	dest_coords(a6),a0
	lea	(a2),a1
	bra	draw_poly
	
draw_sub:
* Her er kun de tre første dele af draw_firstsub med!
* Adressen på underobjektet ligger i A0
	
	move	#1,(a0)+	;Status = optegnet (så at den ikke
				;tegnes flere gange)
	pea	(a0)
	move	(a0)+,d0	;Antal koordinater -1
dsub_loop1:
	move	d0,-(sp)
	move.l	(a0)+,a1	;a1=et af polygonerne
	tst	(a1)
	bpl.s	d_sb1l_notb
; Her er en potentiel usynlig - sidefladen er i det mindste usynlig
	tst	polyNoFrn(a1)
	bmi.s	d_sb1l_notb
; Her har vi en sideflade, som har "bagsiden frem" og som i derudover
; har et eller flere underobjekter foran sig. Så er det bare at tegne dem:
	pea	(a0)
	move	polyNoFrn(a1),d1	;d1=antal underobjekter foran -1
	move.l	polyFrnTb(a1),a1	;Underobjekterne er i a1!
dsub_l1_frloop:
	move.l	(a1)+,a0
	tst	(a0)
	bne.s	dl1fr_alr_drawn
	move	d1,-(sp)
	pea	(a1)
	bsr	draw_sub
	move.l	(sp)+,a1
	move	(sp)+,d1
dl1fr_alr_drawn:
	dbra	d1,dsub_l1_frloop
	move.l	(sp)+,a0
d_sb1l_notb:
	move	(sp)+,d0
	dbra	d0,dsub_loop1

* Ok. Nu er første fase færdig.
* Fase 2 består i at tegne alle de polygoner som har bagsiden frem.

	move.l	(sp),a0	;a0 peger nu direkte på subNoPoly
	move	(a0)+,d0	;d0=antal igen
dsub_loop2:
	move.l	(a0)+,a1
	tst	(a1)
	bpl.s	dsl2_skip
	move.b	3(a1),d1
	bmi.s	dsl2_skip
* Ok. Nu har vi en bagside som skal plottes ud
 	move	d0,-(sp)
	pea	(a0)
	bsr	draw_back	;Tegner en "anti-clockwise" figur,
			;med pointer til polygonstrukturen i a1
			;og farven i d1.b
	move.l	(sp)+,a0
	move	(sp)+,d0
dsl2_skip:
	dbra	d0,dsub_loop2

* Nu er alle sidefladerne på "bagsiden" tegnet.
* Så er det forsidens tur:

	move.l	(sp)+,a0	;a0 peger nu direkte på subNoPoly
	move	(a0)+,d0
dsub_loop3:
	move.l	(a0)+,a1
	tst	(a1)
	bmi.s	dsl3_skip
	move.b	2(a1),d1
	bmi.s	dsl3_skip
* OK. nu har vi en forside som skal plottes ud
	move	d0,-(sp)
	pea	(a0)
	bsr	draw_front	;Tegner en "clockwise" figur,
			;med pointer til polygonstrukturen i a1
			;og farven i d1.b
	move.l	(sp)+,a0
	move	(sp)+,d0
dsl3_skip:
	dbra	d0,dsub_loop3
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
	move.l	draw_bitplanes_table(a6),show_bitplanes_table(a6)	
	move.l	visibl_bitplanes_table(a6),draw_bitplanes_table(a6)
	move.l	d0,visibl_bitplanes_table(a6)

* Nu skal der signaleres til int3_handler, at en ny skærm er klar til
* at blive vist, når blitteren er færdig:

trplbuf_waitblt:
	btst	#6,dmaconr(a5)
	bne.s	trplbuf_waitblt

	clr	newscreen_flag(a6)
	rts

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
	rts	;d3>=0: synlig, d3<0:usynlig.


rotate_mainobj:

* Roterer koordinatet (d0,d1,d2)
* Returnerer med perspektiv i (d0,d1), z-værdi i d2!
* Rotation givet ved d3,d4,d5, hvor d3=rx, d4=ry og d5=rz
* Ødelægger alle dataregistrene, ingen adresseregistre.

* Adressen på hovedobjektet opgives i a0!

	lea	SinusTable(pc),a4
	lea	CosinusTable(pc),a2

	move	(a2,d3.w),cosx(a6)
	move	(a4,d3.w),sinx(a6)
	move	(a2,d4.w),cosy(a6)
	move	(a4,d4.w),siny(a6)
	move	(a2,d5.w),cosz(a6)
	move	(a4,d5.w),sinz(a6)
	
	move	objNoCrd(a0),d7	;d7=antal koordinater -1
	move.l	objCrd(a0),a1	;a1=koordinattabellen  (source..)
	move.l	objClCrd(a0),a2	;a2=udregningskoordinattabellen
	move.l	objPlCrd(a0),a3	;a3=optegningskoordinattabellen.

rot_main_loop:
	move	(a1)+,d0	;d0=x
	move	(a1)+,d1	;d1=y
	move	(a1)+,d2	;d2=z
	
	
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

	add	objX(a0),d0
	add	objY(a0),d3
	add	objZ(a0),d2

	move	d0,(a2)+
	move	d3,(a2)+
	move	d2,(a2)+	;Lagrer værdierne i udregnings-k.tabellen

*	p=oyep/(oyep+z3), hvor z3 er positiv ind i skærmen
*	x=x3*p+sx
*	y=y3*p+sy
*	RETURN
*
oyep=1000
oyep2=1000*65536/4 ;Deler tallet med 4 (For at det ikke skal blive for stort)
	
	move	#oyep,d6
	add	d2,d6	;d6=1000+z (Positiv Z = ind i skærmen)
	move.l	#oyep2,d1
	divu	d6,d1
	muls	d1,d0	;d0=x
	swap	d0
	muls	d3,d1	;d1=y
	swap	d1
	add.w	#159,d0	;Centrerer koordinatene...
	add.w	#127,d1 ;--------- " ----------

	move	d0,(a3)+
	move	d1,(a3)+
	
	dbra	d7,rot_main_loop
	rts

delete_oldpolys:
	IF	debug-OFF
	rts
	ENDIF
	tst	draw_ready(a6)
	bne.s	delete_oldpolys
 	not	draw_ready(a6)	;Sørger for at der går mindst en skærm-
				;opdatering før næste bitplan slettes
	move	draw_minx(a6),d0
	bmi	oops_delop_none	;1., 2. eller 3. gang
				;rutinen kaldes er der
				;ingenting at slette.
	move	draw_miny(a6),d1
	move	draw_maxx(a6),d2
	move	draw_maxy(a6),d3
	
* Vi skal nu slette firkanten givet ved (d0,d1)-(d2,d3)
* i alle bitplanerne.
* Vi skal omregne til startadresse, bltsize og modulo...

	lsr	#4,d0	;d0=minx/16	
	lsr	#4,d2	;d2=maxx/16
	addq	#1,d2	;+1
	sub	d0,d2	;d2=Antal words i bredden
	add	d0,d0	;d0=start-offset i x-retning
	sub	d1,d3	
	addq	#1,d3	;d3=antal linier i y-retning
	LnModMul	d1,d4	;d1=y-offset, d4 ødelægges.
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
	IF	line_waitblit-OFF
	btst	#6,dmaconr(a5)
	bne.s	dbpl_waitblit
	ENDIF
	lea	0(a0,d1.w),a0	;a0 = startadresse for sletningen
	move.l	a0,bltdpth(a5)
	move	d2,bltdmod(a5)
	move	#$0100,bltcon0(a5)	;D=0.
	move	#0,bltcon1(a5)
	move	d3,bltsize(a5)	;Starter sletningen
	dbra	d7,del_bpls_loop

* Så er området slettet.

oops_delop_none:
	rts
 

restore_oldpolys:
* Bruges i stedet for delete_oldpolys når du har baggrundsgrafik.
* I stedet for at slette området, som vektorobjektet brugte, kopierer
* denne rutine baggrundsgrafikken ind igen.
* Baggrundsgrafikken skal i denne rutinen have lige så mange bitplan, som
* der er på skærmen.
* Bredden i bytes pr linie skal være ens på baggrundsbilledet og på
* skærmen, dvs. "lmmod" bytes pr linie.
* Baggrundsbilledet skal også være lige så højt som skærmen,
* almindeligvis 256 linier.

	tst	draw_ready(a6)
	bne.s	restore_oldpolys
	not	draw_ready(a6)	;Sørger for at der går mindt en skærm-
				;opdatering før næste bitplan slettes
	move	draw_minx(a6),d0
	bmi	oops_rslop_none	;1., 2. eller 3. gang
				;rutinen kaldes er der
				;ingenting at slette.
	move	draw_miny(a6),d1
	move	draw_maxx(a6),d2
	move	draw_maxy(a6),d3
	
* Vi skal nu slette firkanten givet ved (d0,d1)-(d2,d3)
* i alle bitplanerne.
* Vi skal omregne til startadresse, bltsize og modulo...

	lsr	#4,d0	;d0=minx/16	
	lsr	#4,d2	;d2=maxx/16
	addq	#1,d2	;+1
	sub	d0,d2	;d2=Antal words i bredden
	add	d0,d0	;d0=start-offset i x-retning 
	sub	d1,d3	
	addq	#1,d3	;d3=antal linier i y-retning
	LnModMul	d1,d4	;d1=y-offset, d4 ødelægges.
	add	d0,d1	;d1=start-adresse-offset for sletningen.	
	
	lsl	#6,d3
	or	d2,d3	;d3=bltsize
	add	d2,d2
	neg	d2
	add	#40,d2	;d2=bltdmod
* Nu er det bare at arbejde sig igennem alle bitplanerne.
	moveq	#noof_bitplanes-1,d7
	move.l	draw_bitplanes_table(a6),a1
 	lea	backgr_bitplanes_table(a6),a3
rest_bpls_loop:
	move.l	(a1)+,a0	;Adressen på bitplanet i a0
	move.l	(a3)+,a2	;a2=source-bitplan (baggrundsgrafik)
rdpl_waitblit:
	IF	line_waitblit-OFF
	btst	#6,dmaconr(a5)
	bne.s	rdpl_waitblit
	ENDIF
	lea	0(a0,d1.w),a0	;a0 = dest. adresse for kopieringen
	lea	0(a2,d1.w),a2	;a2 = source adresse for kopieringen
	move.l	a0,bltdpth(a5)
	move.l	a2,bltapth(a5)
	move	d2,bltdmod(a5)
	move	d2,bltamod(a5)
	move	#$09f0,bltcon0(a5)	;D=A, brug A&D
	move	#0,bltcon1(a5)
	move	d3,bltsize(a5)	;Starter kopieringen
	dbra	d7,rest_bpls_loop

* Nu er området kopieret.
oops_rslop_none:
	rts