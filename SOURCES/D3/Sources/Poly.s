* Polygon-rutiner...
* Først: Fjerner lige hjørner! Dvs reducerer antallet af hjørner så meget som muligt.
* Tegner fra side-punkterne og opad/nedad (Som på figuren i kurset).
* Husk at der altid skal tegnes to normale linier - en på hver
* side. Det ordnes på følgende måde:
* [For tegning på højresiden]
*  Hvis det næste punkt ligger længere mod højre, og punktet derefter
*  også ligger længere mod højre, så skal linien tegnes fra det nederste punkt og op
*  sammen med første pixel "Disabled".
*  Derefter er det eneste som du skal gøre, bare at checke om det NÆSTE punkt ligger til højre
*  eller venstre for punktet derefter igen. Hvis det viser sig, at det næste
*  punkt ligger længst til højre, så skal linien tegnes MED det første punkt.
*  Derefter skal alle linierne ned til bundunktet (hvis der er et) og tegnes
*  uden den første prik, og i retningen oppefra-og-ned.
* På venstresiden bliver det akkurat modsat - du skal gå nedefra og op og checke,
* hvilke af punkterne, som ligger til venstre for hinanden.

* For at Clipningen skal blive så enkel som mulig, gør vi det på følgende måde:
* Objektet skal altid tegnes sådan, at pixelen længst til venstre på objektet
* kommer i det andet wordet (pixel 16-31...). Det øverste punkt skal 
* altid være y=0.
* Og hvorfor nu det?
* JO: Clipping kommer til at gå som en leg, dvs, det er bare at klippe den rigtige firkant ud.
* Og man sparer en masse arbejde. Det er bare at trække fra og lægge til
* - lægge k1*16 til x, og trække miny fra y.
* Desuden bliver så temp_plane så lille som muligt!
* Derudover er der den fordel, at vi slipper for maset med
* shift-registrene i blitteren.

* Rutinen kaldes op med disse parametre:
* Antal kooordinater i d6
* antal koordinater -2 i d7
* Pointer til dest_coords i A0
* Pointer til koordinat-tabel i A1. Koordinaterne SKAL være clockwise!!!!

	
GetCoords:	macro
	move	(a1)+,\1
 	move	(a1)+,\2
	endm

draw_poly:
	
Compress:	;Her får vi lige hjørner...
	GetCoords	d0,d1	En makro som henter koordinater ud.
	move	d0,(a0)+
	move	d1,(a0)+
	
rc1_loop:
	GetCoords	d2,d3
	cmp	d0,d2
	bne.s	rc1l_dif
	cmp	d1,d3
	bne.s	rc1l_dif
rc1l_same:
	subq	#1,d6	;Lige hjørner findes - Antal af koordinater mindskes med 1
	bra.s	rc1l_same_jumpin
rc1l_dif:
	move	d2,(a0)+
	move	d3,(a0)+
rc1l_same_jumpin:
	dbra	d7,rc2_loop
	
	move	d6,d7
	add	d7,d7
	add	d7,d7
	neg	d7
	cmp	0(a0,d7.w),d2
	bne.s	compressed
	cmp	2(a0,d7.w),d3
	bne.s	compressed
rc1l_firsteqlast:
	subq	#1,d6
	bra.s	compressed
	
rc2_loop:
	GetCoords	d0,d1
	cmp	d0,d2
	bne.s	rc2l_dif
	cmp	d1,d3
	bne.s	rc2l_dif
rc2l_same:
	subq	#1,d6
	bra.s	rc2l_same_jumpin
rc2l_dif:
	move	d0,(a0)+
	move	d1,(a0)+
rc2l_same_jumpin:
	dbra	d7,rc1_loop
	
 	move	d6,d7
	add	d7,d7
	add	d7,d7
	neg	d7
	cmp	0(a0,d7.w),d0
	bne.s	compressed
	cmp	2(a0,d7.w),d1
	bne.s	compressed
rc2l_firsteqlast:
	subq	#1,d6
	subq.l	#4,a0
compressed:
	lea	(a0),a4	;a4=adressen på byten efter koordinattabellen.

* D6=Antal hjørner.
* De lige hjørner er nu væk...
* Så skal vi finde top, bund, venstre og højre..
* Venstre top skal lægges ind i : (d0,d1)
* Højre bund skal lægges ind i : (d2,d3)

	move.w	#-16384,2(a0) ;Definerer endepunktet i hjørne-listen.

	move	d6,d7
	subq	#1,d7	;d7=indekset til de forskellige koordinater etc.
	
	bmi	single_point	
	move	-(a0),d1
	move	d1,d3
	move	-(a0),d0
	move	d0,d2
	move	d7,d4	;d4=indeks til top-punktet
	move	d7,d5	;d5=indeks til bund-punktet
	subq	#1,d7
	
fpoints_loop:
	move	-(a0),a3
	move	-(a0),a2
	cmp	a2,d0
	blt.s	fpl_notleft
fpl_left:
	move	a2,d0
	bra.s	fpl_notright
fpl_notleft:
	cmp	a2,d2
	bgt.s	fpl_notright
fpl_right:
	move	a2,d2
fpl_notright:
	
	cmp	a3,d1
	blt.s	fpl_nottop
fpl_top:
	move	a3,d1
	move	d7,d4
	bra.s	fpl_notbottom
fpl_nottop:
	cmp	a3,d3
	bgt.s	fpl_notbottom
fpl_bottom:
	move	a3,d3
	move	d7,d5
fpl_notbottom:
	dbra	d7,fpoints_loop

* Ok. Så har vi fundet top- (d0,d1) og bund- (d2,d3) punkterne.
* d6=antal hjørner (efter en kompres), og d7=$xxxxffff.
* d4=indeks til top-punktet
* d5=indeks til bund-punktet
* d6=Antal hjørner..
* Vi skal gemme al informationen.
*
* Nu skal vi
*   1) Fixe koordinaterne til en tegning i TEMP-PLANE
*      Dvs miny=0, 16<=minx<=31, minx&15 = plotx&15...
*   2) Tegne figuren i temp-plane... Husk! Optegningen på venstre-siden
*      skal foregå et hak længere til venstre på grund af fyldningen!
*   3) Finde ud af hvor mange words temp-figuren skal flyttes, og
*      hvor mange linier ned... Finde bredden (i words) og højden
*      Husk clipping!
*   4) Kopiere den ind i bitplanerne...
*   5) Slette den igen..


	moveq	#31,d7
	sub	d0,d7	;d7=31-minx
	and	#$fff0,d7	;d7=(31-minx)&fff0
				;d7=dx
				;-d0=dy...

*	Pointen er, at d7 skal være et tal, som skal lægges til alle
*	x-koordinaterne. Det skal medføre at alle x-koordinaterne
*	kommer mellem 16 og 31, men eftersom den sidste prik kan komme et
*	hak længere til venstre kan hjørnet, der er længst til venstre havne i pixel
*	15. Dette ordnes imidlertid længere nede! (At trække 1 fra altså!!)
*	

 
	lea	(a0),a1
cordfix_loop:
	add	d7,(a1)+	;Fixer x-koordinat
	sub	d1,(a1)+	;Fixer y-koordinat
	bpl.s	cordfix_loop

* For at linien ovenfor skal kunne fungere  skal der lægges et negativ tal ind efter
* koordinaterne! Og ikke kun det! Hvis det skal fungere optimalt,
* bør det negative tal være noget i retning af -16384 (som det også er).

	swap	d7	;Holder styr på offseten (til klipningen)

	lea	(a0),a1

	move	d6,d7
	addq	#1,d7	;Bliver kopieret dobbelt op + 2 til.
fpl_cmc_loop:
	move.l	(a1)+,(a4)+	;Kopierer koordinaterne lidt mere end dobbelt
	move.l	(a1)+,(a4)+	;op. Så slipper vi for et kedeligt check senere
	dbra	d7,fpl_cmc_loop
	
	cmp	d4,d5
	bge.s	loindex_ok
	add	d6,d5
loindex_ok:
	
* Så er koordinaterne fixet. Alle er positive, ymin=0,
* mindste x er=(xmin+k*16 til positiv)+16
*   mellem 16 og 31..

* Så skal vi "Tegne" polygonet.
* Vi lægger linierne ind i en tabel.
* Negativ x-værdi <=> linie MED første punkt. OBS!

* Vi begynder øverst. Tager linierne i 2 grupper, først fra top til bund
* og så fra bund til top.

	swap	d3	;Skal swappes tilbage senere.
			;Nu har vi et ledigt register!
	lea	line_table(a6),a4
	move	d4,d3	d3 er en counter her (indeks..)
			;Når vi er nået til d3>d5 er vi gået forbi bunden...

* Det fungerer sådan: Så længe at det næste koordinat er til højre for
* dette, og koordinatet derefter igen er til højre for det næste koordinat,
* så skal linien tegnes fra det næste punkt til dette punkt
* UDEN den første prik sat.

glr_toptobottom:
	add	d3,d3
	add	d3,d3
	lea	0(a0,d3.w),a1
	
	lea	(a1),a0
	
	move	d4,d3
	lea	4(a1),a2
	cmp.l	(a1)+,(a2)+
	blt.s	glr_top_is_right
* Top-punktet var ikke længst til højre. Hvis pkt 3 er til højre
* for pkt 2 skal denne linia tegnes nedefra og op uden den første-prik
* x>=0 <==> Den første prik skal fjernes.

glr_ttb_findr:
	cmp.l	(a1)+,(a2)+
	blt.s	glr_ttb_rfound
;glr_ttb_notrighedgetyet:
	move.l	4(a0),(a4)+
	move.l	(a0)+,(a4)+ ;Linien skal tegnes nedefra og op uden første-prik
	addq	#1,d3
	cmp	d3,d5
	bgt.s	glr_ttb_findr
	bra	glr_bottomup
glr_ttb_rfound:
* OK. Vi har fundet det højre hjørne. Næste linie går fra højre-hjørne
* og opad - så skal linierne tegnes nedad...
	move.l	4(a0),(a4)+
	neg	-4(a4)	;Den første prik skal med
	move.l	(a0)+,(a4)+
	addq	#1,d3
	cmp	d3,d5
	ble.s	glr_bottomup
glr_ttb_rf_loop:
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+
	addq	#1,d3
	
	cmp	d3,d5
	ble.s	glr_bottomup
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+
	addq	#1,d3
	cmp	d3,d5
 	bgt.s	glr_ttb_rf_loop
	bra	glr_bottomup

glr_top_is_right:
	move.l	(a0)+,(a4)+
 	neg	-4(a4)	Negativ x-værdi vil sige linien MED førstepunkt
	move.l	(a0),(a4)+	;Vi tegner linien oppefra og ned.	
	addq	#1,d3
glr_tir_loop:
	cmp	d3,d5
	ble.s	glr_bottomup
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+	;Fremdeles oppefra og ned.
	addq	#1,d3
	
	cmp	d3,d5
	ble.s	glr_bottomup
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+
	addq	#1,d3
	bra.s	glr_tir_loop
	
glr_bottomup:
	lea	4(a0),a2
	lea	(a0),a1
	add	d6,d4	;d4=Top-indeks + antal hjørner
			;Sammenligne med d5 i stedet for d4 herefter!
	

	cmp.l	(a1)+,(a2)+
	bgt.s	glr_bottom_is_left
* Ok. Bund-punktet var ikke længst til venstre. Hvis pkt *+2 er til venstre
* for pkt *+1 skal denne linie tegnes oppefra og ned uden den første prik
* x>=0 <==> Den første prik skal fjernes.
* Med "pkt *" menes DETTE PUNKT. "pkt *+1" betyder næste punkt osv...

glr_btt_findl:
	cmp.l	(a1)+,(a2)+
	bgt.s	glr_btt_lfound
	move.l	4(a0),(a4)+
	move.l	(a0)+,(a4)+	;Tegner linien oppefra og ned uden den første prik
	subq	#1,-8(a4)
	subq	#1,-4(a4)	;Tegner linien en pixel til venstre...	
	addq	#1,d3
	cmp	d3,d4
	bgt.s	glr_btt_findl
	bra	glr_done
glr_btt_lfound:
 * OK. Vi har fundet det venstre hjørne. Næste linie går fra venstre-hjørne
* og opad, så skal linierne tegnes opad...

	move.l	4(a0),(a4)
	subq	#1,(a4)
	neg	(a4)	;Den første prik skal med
	addq.l	#4,a4
	move.l	(a0)+,(a4)+
	subq	#1,-4(a4)
	addq	#1,d3
	cmp	d3,d4
	ble.s	glr_done
glr_btt_lf_loop:
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+
	subq	#1,-8(a4)
	subq	#1,-4(a4)
	addq	#1,d3
	
	cmp	d3,d4
	ble.s	glr_done
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+
	subq	#1,-8(a4)
	subq	#1,-4(a4)
	addq	#1,d3
	cmp	d3,d4
	bgt.s	glr_btt_lf_loop
	bra	glr_done

glr_bottom_is_left:
	move.l	(a0)+,(a4)
	subq	#1,(a4)
	neg	(a4)		;Negativ x-værdi vil sige linie MED førstepunkt
	addq.l	#4,a4
	move.l	(a0),(a4)+	;Vi tegner linien nedefra og op
	subq	#1,-4(a4)
	addq	#1,d3
glr_bil_loop:
	cmp	d3,d4
	ble.s	glr_done
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+	;Fremdeles nedefra og op.
	subq	#1,-8(a4)
	subq	#1,-4(a4)
	addq	#1,d3

	cmp	d3,d4
	ble.s	glr_done
	move.l	(a0)+,(a4)+
	move.l	(a0),(a4)+
 	subq	#1,-8(a4)
	subq	#1,-4(a4)
	addq	#1,d3
	bra.s	glr_bil_loop

glr_done:

* Nu er linietegningstabellen færdig udregnet!
* Linjitabellen ligger i "line_table".

* Nå skal vi udregne clippingen.
* Vi klipper et word på den venstre side for hvert word, som figuren kommer
* ind i "negativ" Zone..
* Y-cuttingen er enkel og nem, klip (-miny) af linierne oven over.
* På samme måde klippes et eller flere word på den højre side, eftersom
* figuren kommer ind i et eller flere word til højre for skærmen,
* dvs til højre for clipx.
* Vi klipper (maxy-clipy) af linierne nedenunder.

* Værdiene i de forskellige registre er nu:
* D0.w=minx
* D1.w=miny
* D2.w=maxx
* d3.uw=maxy
* d6.w=Antal koordinater
* Linietegningskoordinaterne ligger i -(a4), og det er d6 stykker.
* d7.w=offset som blev lagt til alle koordinaterne for optegning i temp_plane.

* clip_miny og clip_minx skal altid være 0. Dette skulle ikke skabe
* nævneværdige problemer.
clipx=319	;Varierer størrelsen af området, som der kan tegnes i
clipy=255	;med disse to størrelser!

	swap	d3	d3.w=Maxy
	swap	d7	d7.w=Offset som blve lagt til i x-retningen for optegning...
	
* Ledige registre: d4,d5 og d6.

	lea	poly_minx(a6),a0
	
	cmp	(a0)+,d0
	bge.s	no_left_extreme
	move	d0,-2(a0)
no_left_extreme:

	cmp	(a0)+,d1
 	bge.s	no_top_extreme
	move	d1,-2(a0)
no_top_extreme:

	cmp	(a0)+,d2
	ble.s	no_right_extreme
	move	d2,-2(a0)
no_right_extreme:

	cmp	(a0)+,d3
	ble.s	no_bottom_extreme
	move	d3,-2(a0)
no_bottom_extreme:

* poly_minx, poly_miny, poly_maxx og poly_maxy skal senere justeres sådan
* at de ikke havner udenfor firkanten afgrænset af koordinaterne
* (0,0) og (clipx,clipy), dvs efter justering skal følgende være tilfældet:
*
* poly_minx >= 0
* poly_miny >= 0
* poly_maxx <= clipx
* poly_maxy <= clipy
*
* Dette klares i en anden rutine, sædvanligvis draw_mainobj
 
	move	d2,d4
	moveq	#$fffffff0,d5	;d5=-16
	and	d5,d4	;normaliserer maxx til den første pixel i wordet.
	sub	d0,d4	;-15..0 skal gi 1, 1..16 skal give 2 osv...
	subq	#1,d4	;-16..-1 skal gi 1, 0..15 skal give 2 osv..
	asr	#4,d4	;-1 skal give 1, 0 skal give 2, 1 skal give 3 osv.
	addq	#2,d4	;d4=antal words i bredden!
	cmp	#63,d4
	bhi	poly_drawn	;Hvis polygonet er for bredt..
	
* d4 indeholder nu antal words i bredden for sletningen.
* Vi kan så begynde på højden:

	move	d3,d6	;d6=maxy
	sub	d1,d6	;d6=maxy-miny
	cmp	#511,d6
	bhi	poly_drawn	;Hvis polygonet er for højt...
	addq	#1,d6	;d6=antal linier i y-retning!
	
	move	d4,del_width(a6)
	move	d6,del_height(a6)
 	
	add	d5,d7	;d5 = -16, d7=addx-16. Det gøres fordi
		;start_adresse for linie-tegningen er temp_plane,
		;mens starten for fyldningen, kopieringen og sletningen
		;er temp_plane+2. Vi skal derfor trække 2 bytes fra
		;=16 pixels på koordinaterne før fyldning, kopiering
		;og sletning.
	
	
* Så kan vi begynde at tænke på klipning...

* Modulo udregnes til sidst, fra de forskellige bredder.
* F.eks er copy_dest_modulo = lnmod-(copy_width*2) bytes.

* Klipning på den venstre side:
* bredden i word justeres for fyldning og kopiering.
* LÆG KUN DISSE LINIER IND:
*	asr	#4,d0
*	add	d0,d4

* Klipning på toppen:
* højden i linier justeres.
* Læg kun en ADD D1,D6 ind

* Klipning på den højre side:
* bredden i word og modulo justeres for kopiering, ikke fyldning
* x-offset sættes til
*	(clipx>>4)*2+d7>>3 for kopiering-dest og source,
*	da source_base = temp_plane+2,
*	hvor d7 er antal words forskydning mod højre i temp_plane.

* Klipning under:
* højden i linier justeres.
* y-offset sættes til :
*	(clipy-miny)*LnModMul for kopiering_dest
*	(clipy-miny)*64 for kopiering_source og fyldning

clipping:
	tst	d0
	bpl	no_lclip
lclip:
* klipning på den venstre side (mindst)
	tst	d1
	bpl	l_no_tclip
ltclip:
* klipning på venstre- og over-siden (mindst)
	cmp	#clipx,d2
	bls	lt_no_rclip
ltrclip:
* Klipning venstre, top og højre (mindst)
	cmp	#clipy,d3
 	bls	ltr_no_bclip
ltrbclip:
* Klipning på alle 4 sider!

	asr	#4,d0
	add	d0,d4	;d4 = fill_width
	move	d4,fill_width(a6)
	move	#(clipx+15)>>4,copy_width(a6) ;sædvanligvis 40
	move	d2,d0

	neg	d1
	add	#clipy,d1	;d1=Afstand (i antal linier) fra toppen.

	add	d7,d2	;d2=maxplotx i tempplane
	lsl	#6,d1	;d3=maxploty*64 (64 bytes pr linie i temp_plane)
	move	d1,d0
	lsr	#4,d2
	add	d2,d2
	add	d2,d1
	move	d1,fill_offset(a6)	;temp_plane+fill_offset=adr på første fill
	
	lsr	#3,d7
	add	#(clipx>>4)*2,d0
	add	d7,d0
	
	move	d0,copy_srcoffset(a6)	;offset i temp_plane
	move	#clipy*lnmod+(clipx>>4)*2,copy_destoffset(a6)
	move	#clipy+1,fill_height(a6)
	bra	clipped
		
ltr_no_bclip:
* Klipning venstre, top og højre.

	asr	#4,d0
	add	d0,d4
	move	d4,fill_width(a6)
	add	d1,d6
	ble	poly_drawn	;Hvis objektet ligger helt over y=0.
	move	d6,fill_height(a6)

	move	#(clipx+15)>>4,copy_width(a6) ;Dækker hele skærm-bredden
	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Indholdet i d0 ødelægges
	add	#(clipx>>4)*2,d4 ;x-offset i bytes lægges til.
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
 	move	d3,d4
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	add	#(clipx>>4)*2,d4
	lsr	#3,d7
	add	d7,d4
	move	d4,copy_srcoffset(a6)
	bra	clipped

lt_no_rclip:
* Klipning venstre og top (mindst), ikke højre
	cmp	#clipy,d3
	bls	lt_no_rbclip
ltb_no_rclip:
* Klipning venstre, top og bund.
	
	asr	#4,d0
	add	d0,d4
	ble	poly_drawn	;Hvis objektet er til venstre for skærmen
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	move	#clipy+1,fill_height(a6)
	
	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	#clipy*lnmod,d0	;d0=copy_destoffset
	move	d0,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped


lt_no_rbclip:
* Klipning venstre og top

	asr	#4,d0
	add	d0,d4	;Klipper  den venstre side.
	ble	poly_drawn	;Hvis objektet er til venstre for skærmen
 	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	add	d1,d6	;Klipper toppen.
	ble	poly_drawn	;Hvis objektet ligger over y=0
	move	d6,fill_height(a6)

	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Indholdet i d0 ødelægges
	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	d0,d4	;d4=copy_destoffset
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped

l_no_tclip:
* Klipning venstre (mindst), ikke top
	cmp	#clipx,d2
	bls	l_no_trclip
lr_no_tclip:
* Klipning venstre og højre (mindst), ikke top
	cmp	#clipy,d3
	bls	lr_no_tbclip
lrb_no_tclip:
* Klipning venstre, højre og bund.
	asr	#4,d0
	add	d0,d4
	move	d4,fill_width(a6)

	move	#(clipx+15)>>4,copy_width(a6) ;Dækker hele skærm-bredden
	move	#clipy*lnmod+(clipx>>4)*2,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	bmi	poly_drawn	;Hvis objektet ligger nedenunder skærmen
	move	d3,d6
	addq	#1,d6
	move	d6,fill_height(a6)
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	move	d3,d4
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
 	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	add	#(clipx>>4)*2,d4
	lsr	#3,d7
	add	d7,d4
	move	d4,copy_srcoffset(a6)
	bra	clipped

lr_no_tbclip:
* Klipning venstre og højre.
	asr	#4,d0
	add	d0,d4
	move	d4,fill_width(a6)
	move	d6,fill_height(a6)

	move	#(clipx+15)>>4,copy_width(a6) ;Dækker hele skærm-bredden
	move	d3,d4
	LnModMul	d4,d0	;d4=d1*lnmod. Indholdet i d0 ødelægges
	add	#(clipx>>4)*2,d4 ;x-offset i bytes lægges til.
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	move	d3,d4
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	add	#(clipx>>4)*2,d4
	lsr	#3,d7
	add	d7,d4

	move	d4,copy_srcoffset(a6)
	bra	clipped
l_no_trclip:
* Klipning venstre (mindst), ikke top eller højre.
	cmp	#clipy,d3
	bls	l_no_trbclip
lb_no_trclip:
* Klipning venstre og bund.
	asr	#4,d0
	add	d0,d4	;Sørger for klipning på den venstre side...
	ble	poly_drawn	;Hvis objektet ligger helt under clipy.
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	
 	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	#clipy*lnmod,d0	;d0=copy_destoffset
	move	d0,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	bmi	poly_drawn ;hvis hele figuren havner helt udenfor skærmen...
	move	d3,d6
	addq	#1,d6
	move	d6,fill_height(a6)
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped

l_no_trbclip:
* Klipning venstre.
	asr	#4,d0
	add	d0,d4	;Disse 4 linier klipper den venstre side væk!
	ble	poly_drawn	;Hvis objektet ligger til venstre for skærmen
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	move	d6,fill_height(a6)

	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Indholdet i d0 ødelægges
	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	d0,d4	;d4=copy_destoffset
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped

no_lclip:
* Ikke klipning på den venstre side
	tst	d1
	bpl	no_ltclip
t_no_lclip:
* Klipning top (mindst), ikke på den venstre side
	cmp	#clipx,d2
	bls	t_no_lrclip
tr_no_lclip:
* Klipning top og højre (mindst), ikke venstre
	cmp	#clipy,d3
	bls	tr_no_lbclip
trb_no_lclip:
* Klipning top, højre og bund.
	move	d4,fill_width(a6)
	move	#clipy+1,fill_height(a6)
	move	#clipx,d5
	sub	d2,d5
	asr	#4,d5	;d5=-(Antal word som "stikker ud")
	add	d5,d4
	ble	poly_drawn	;Hvis objektet er til højre for skærmen
	move	d4,copy_width(a6)
	
	move	#clipy*lnmod+(clipx>>4)*2,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	add	d5,d3
	add	d5,d3
	move	d3,copy_srcoffset(a6)
	bra	clipped

tr_no_lbclip:
* Klipning top og højre.
	move	d4,fill_width(a6)
	add	d1,d6
	ble	poly_drawn	;Hvis objektet ligger over y=0
	move	d6,fill_height(a6)
	move	#clipx,d5
	sub	d2,d5	;d5=-(Antal pixles som "stikker ud")
	asr	#4,d5
	add	d5,d4
	ble	poly_drawn	;hvis objektet falder helt udenfor den højre side
	move	d4,copy_width(a6)	;d5 = -(antal word som klippes på den højre side)
 	
	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Indholdet i d0 ødelægges
	add	#(clipx>>4)*2,d4 ;x-offset i bytes lægges til.
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	add	d5,d3
	add	d5,d3	;d5 = antal words som skal klippes væk på den højre side.
	move	d3,copy_srcoffset(a6)
	bra	clipped

t_no_lrclip:
* Klipning top (mindst), ikke venstre eller højre
	cmp	#clipy,d3
	bls	t_no_lrbclip
tb_no_lrclip:
* Klipning top og bund.
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	move	#clipy+1,fill_height(a6)
	
	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	#clipy*lnmod,d0	;d0=copy_destoffset
	move	d0,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped

t_no_lrbclip:
* Klipning top
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	add	d1,d6	;d6<0, den delen af fig, som er over 0, fjernes.
	ble	poly_drawn	;Hvis objektet ligger over y=0
	move	d6,fill_height(a6)

	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Indholdet i d0 ødelægges
	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	d0,d4	;d4=copy_destoffset
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped

no_ltclip:
* Ikke klipning venstre eller top
	cmp	#clipx,d2
	bls	no_ltrclip
r_no_ltclip:
* Klipning højre (mindst), ikke venstre eller top
	cmp	#clipy,d3
	bls	r_no_ltbclip
rb_no_ltclip:
* Klipning højre og bund.
	move	d4,fill_width(a6)
	move	#clipx,d5
	sub	d2,d5	;d5=-(Antal pixles som "stikker ud")
	asr	#4,d5	;d5=-(antal words som skal klippes på den højre side)
	add	d5,d4
	ble	poly_drawn	;Hvis objektet er til højre for skærmen
	move	d4,copy_width(a6)
	
	move	#clipy*lnmod+(clipx>>4)*2,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	bmi	poly_drawn ;hvis hele figuren havner helt udenfor skærmen...
	move	d3,d6
	addq	#1,d6
	move	d6,fill_height(a6)
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
 	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for fyldning.
	move	d3,fill_offset(a6)
	add	d5,d3
	add	d5,d3
	move	d3,copy_srcoffset(a6)
	bra	clipped

r_no_ltbclip:
* Klipning højre

	move	d4,fill_width(a6)
	move	d6,fill_height(a6)
	move	#clipx,d5
	sub	d2,d5	;d5=-(Antal pixles som "stikker ud")
	asr	#4,d5
	add	d5,d4
	ble	poly_drawn	;hvis objektet falder helt udenfor den højre side
	move	d4,copy_width(a6)	;d5 = -(antal word, som klippes væk på den højre side)
	
	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Indholdet i d0 ødelægges
	add	#(clipx>>4)*2,d4 ;x-offset i bytes lægges til.
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	add	d5,d3
	add	d5,d3	;d5 = antal words, som skal klippes væk på den højre side.
	move	d3,copy_srcoffset(a6)
	bra	clipped

no_ltrclip:
* Ikke klipning venstre, top eller højre.
	cmp	#clipy,d3
	bls	no_clipping
b_no_ltrclip:
* Klipning bund
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	
	move	d2,d0	;d0=maxx
 	lsr	#4,d0
	add	d0,d0	;d0=x-delen af copy_destoffset
	add	#clipy*lnmod,d0	;d0=copy_destoffset
	move	d0,copy_destoffset(a6)
	move	#clipy,d3
	sub	d1,d3	;d3=temp_plotmaxy
	bmi	poly_drawn ;hvis hele objektet havner helt udenfor skærmen...
	move	d3,d6
	addq	#1,d6
	move	d6,fill_height(a6)
	lsl	#6,d3	;d3=maxy*64. (64 bytes pr linie i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fyldning.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
	bra	clipped

no_clipping:
* Ingen klipping i det hele tatt (det mest normale)
	move	d4,copy_width(a6)
	move	d4,fill_width(a6)
	move	d6,fill_height(a6)

	move	d3,d4
	LnModMul	d4,d0	;d4=d1*40. Innholdet i d0 ødelegges
	move	d2,d0	;d0=maxx
	lsr	#4,d0
	add	d0,d0	;d0=x-delen av copy_destoffset
	add	d0,d4	;d4=copy_destoffset
	move	d4,copy_destoffset(a6)
	sub	d1,d3	;d3=temp_plotmaxy
	lsl	#6,d3	;d3=maxy*64. (64 bytes per linje i temp-plane)
	add	d7,d2	;d2=temp_plotmaxx
	lsr	#4,d2
	add	d2,d2
	add	d2,d3	;d3=offset for kopierings-source og for fylling.
	move	d3,fill_offset(a6)
	move	d3,copy_srcoffset(a6)
clipped:

* Linierne ligger nu i -(a4), evt i line_table+
* Det bedste er at tage dem fra -(a4)
* Afslut ved negativt x eller y-koordinat (som aldrig må forekomme...)

* Linietegningsrutinen behøver:
* bitplan-adressen i a3
* Et opkals til init_line før første linie.
*	init_line sætter bl.a a5=$dff000. Derudover sætter den en del
*	af hardware-registrene i blitteren, og som holder sig konstante
*	for fyldning.
* Linien tegnes fra (d0,d1) til (d2,d3).

* Registre som OVERLEVER draw_line og draw_xline
* d0.UW, d1.L, d3.UW og d5.L
* og a1-a6 (a5 skal være $DFF000 ved opkald..)

	IFEQ	debug-OFF

	IFEQ	line_waitblit+1
befldrw_wb:
	btst	#6,dmaconr(a5)
	bne.s	befldrw_wb
	ENDC
		
	bsr	init_line
	
	ELSE
	lea	hardware_fake(a6),a5
	ENDC
	move.l	tempplane_pointer(a6),a3 ;linierutinen ødelægger ikke A3.
	subq.l	#2,a3	;linierne har start-offset temp_plane, resten
			;af rutinerne har start-offset temp_plane+2
	
draw_borderline:
	move	-(a4),d3
	move	-(a4),d2
	move	-(a4),d1
	move	-(a4),d0
	pea	draw_blloop(pc)
	bmi	draw_line
	bra	draw_xline
dbl_looppoint:
	IFEQ	mouse_wait-ON
	bsr	wait_mouse
	ENDC
	move	-(a4),d2
	move	-(a4),d1
	move	-(a4),d0
	pea	draw_blloop(pc)
	bmi	draw_line
	bra	draw_xline
draw_blloop:
	move	-(a4),d3
	bpl.s	dbl_looppoint
dp_lines_drawn:
	
	IFEQ	mouse_wait-ON
	bsr	wait_mouse
	ENDC
	
	
* Så er linierne rundt om objektet færdigtegnede. Objektet skal så fyldes,
* kopieres på bitplanerne og slettes fra temp_plane igen.

* fyldning:
* Startadresse er temp_plane+2+fill_offset
* bredden af fyldningen er fill_width
* højden på fyldningen er fill_height
* modulo er line_lnmod-2*fill_width
* Vi kører en enkelt A->D fyld, uden noget andet i.
* A5 indeholder $dff000 (efter linie-initialiseringen)

	ifeq	line_waitblit+1
fill_waitblit:
	btst	#6,dmaconr(a5)
	bne.s	fill_waitblit
	endc

	move	#$09f0,bltcon0(a5)	;no shift, A&D, D=A.
	move	#$0012,bltcon1(a5)	;EFE-fill, DESCending mode

	move.l	tempplane_pointer(a6),a0
	add.w	fill_offset(a6),a0
	move.l	a0,bltapth(a5)
	move.l	a0,bltdpth(a5)

	move	fill_width(a6),d0
	move	d0,d1
	add	d1,d1
	neg	d1
	add	#line_lnmod,d1
	move	d1,bltamod(a5)
	move	d1,bltdmod(a5)
	move	fill_height(a6),d1
	lsl	#6,d1
	or	d0,d1	;d0 SKAL være mindre end 64, og så virker det.
	move	d1,bltsize(a5)

	IFEQ	mouse_wait-ON
	bsr	wait_mouse
	ENDC

	
* Så skal figuren kopieres ind i de enkelte bitplanes...
* Du kan faktisk bruge ligeså mange bitplanes, som du vil, men du skal have en
 * bitplan-tabel, og den afsluttes med et NEGATIVT TAL!
* Du kan altså tegne i så mange bitplanes du vil med denne rutine.
* bitplane_table_pointer skal pege på bitplane-tabellen!

* ex:
*	move.l	#bitplane_table,bitplane_table_pointer+var
* 	....
* bitplane_table
*	dc.l	 bitplane1,bitplane2,bitplane3,bitplane4,bitplane5,-1
*


* Gør at figuren tegnes i 5 bitplanes.
* Farven skal ligge i "poly_color"

	move	poly_color(a6),d7
	move.l	bitplane_table_pointer(a6),a4
	move	copy_width(a6),d0
	move	d0,d1
	add	d1,d1
	neg	d1
	add	#lnmod,d1	;d1=modulo i DESTINATION-bitplan
	move	d1,d2
	add	#line_lnmod-lnmod,d2	;d2=modulo i SOURCE-bitplan
	move	fill_height(a6),d3
	lsl	#6,d3
	or	d0,d3	;d3=bltsize

	IFEQ	line_waitblit+1
dp_bef_colorize_wb:
	btst	#6,dmaconr(a5)
	bne.s	dp_bef_colorize_wb
	ENDC
	
	move	d2,bltamod(a5)	;modulo i temp_plane
	move	d1,bltcmod(a5)	;modulo i destination-bitplane
	move	d1,bltdmod(a5)	; ----------  " ----------
	move	#$0002,bltcon1(a5)	;DESCENDING mode, sædvanlig kopiering.
	move.l	tempplane_pointer(a6),a0
	add	copy_srcoffset(a6),a0	;a0=bltapt, nedre venstre hjørne i temp_plane
	move	copy_destoffset(a6),d1
	ext.l	d1
dp_colorize_loop:
	move.l	(a4)+,d6
	bmi	dp_colorized

	IFEQ	line_waitblit+1
dp_in_colorize_wb:
 	btst	#6,dmaconr(a5)
	bne.s	dp_in_colorize_wb
	ENDC
	
	
	move.l	a0,bltapth(a5)
	add.l	d1,d6
	move.l	d6,bltcpth(a5)
	move.l	d6,bltdpth(a5)	;Vi bruger A, C og D i blitteren...
	ror	#1,d7
	bmi	dp_col_pos

dp_col_neg:
* I dette bitplane skal der indsættes et 0, hvor polygonet er ..
* Minterm :$0A, hvor A er polygonet og C er baggrunden.
*                   _
* Blitterligning: D=AC
	move	#$0b0a,bltcon0(a5)	;blitter-sourcer A, C og D
	move	d3,bltsize(a5)
	bra.s	dp_colorize_loop

dp_col_pos:
* I dette bitplane skal der indsættes en 1, hvor polygonet er ..
* Minterm: $f9
* Blitterligning: D=A+C
	move	#$0bf9,bltcon0(a5)	;blitter-sourcer A, C og D
	move	d3,bltsize(a5)
	bra.s	dp_colorize_loop
dp_colorized:

* Nu mnagler vi bare at slette slette polygonet fra det
* midlertidige bitplane...

	move.l	tempplane_pointer(a6),a0
	move	del_width(a6),d0
	move	d0,d1
	add	d1,d1
	neg	d1
	add	#line_lnmod,d1	;d1=modulo
	move	del_height(a6),d2
	lsl	#6,d2
	or	d0,d2	;d2=bltsize
dp_del_tempplane:
	IFEQ	line_waitblit+1
	btst	#6,dmaconr(a5)
	bne.s	dp_del_tempplane
	ENDC

	move.l	a0,bltdpth(a5)
	move	d1,bltdmod(a5)
	move	#$0100,bltcon0(a5)	;USE D, D=0.
 	move	#0,bltcon1(a5)	;Standard kopiering, NEDOVER (ikke DESC.)
	move	d2,bltsize(a5)	;Starter sletningen af polygonet fra temp_plane.

poly_drawn:
	rts
	
single_point:
* Det hele drejer sig om et enkelt punkt.
		
	move	-(a0),d1
	bmi.s	poly_drawn
	move	-(a0),d0
	bmi.s	poly_drawn
	cmp	#clipx,d0
	bhi.s	poly_drawn
	cmp	#clipy,d1
	bhi.s	poly_drawn
	
	lea	poly_minx(a6),a0
	
	cmp	(a0)+,d0
	bge.s	spno_left_extreme
	move	d0,-2(a0)
spno_left_extreme:

	cmp	(a0)+,d1
	bge.s	spno_top_extreme
	move	d1,-2(a0)
spno_top_extreme:

	cmp	(a0)+,d0
	ble.s	spno_right_extreme
	move	d0,-2(a0)
spno_right_extreme:

	cmp	(a0)+,d1
	ble.s	spno_bottom_extreme
	move	d1,-2(a0)
spno_bottom_extreme:

	LnModMul	d1,d2	;d1=d1*lnmod
	move	d0,d2
	lsr	#3,d2
	add	d2,d1	;d1=offset fra øverste venstre hjørne
	ext.l	d1
	not	d0	;d0 = bitnummeret som skal sættes/slettes
	
	IFEQ	line_waitblit+1
dsp_waitblitter:
	btst	#6,dmaconr(a5)
	bne.s	dsp_waitblitter
	ENDC
 	move.l	bitplane_table_pointer(a6),a0
	move	poly_color(a6),d7
dsp_loop:
	move.l	(a0)+,d2
	bmi.s	sp_drawn
	add.l	d1,d2
	move.l	d2,a1
	ror	#1,d7
	bmi.s	dsp_set
dsp_clear:
	bclr	d0,(a1)
	bra.s	dsp_loop
dsp_set:
	bset	d0,(a1)
	bra.s	dsp_loop
sp_drawn:
	rts


