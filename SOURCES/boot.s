register	equ	$dff000
execbase	equ	4 
startlist	equ	38	;addresse der alten Copperlist
permit		equ	-138
forbid		equ	-132
openlib		equ	-408
open		equ	-30
close		equ	-36
closelib	equ	-414
write		equ	-48
read		equ	-42
delete		equ	-72
fensterprog:
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	(execbase).w,a6
	lea	dosname,a1
	moveq	#0,d0
	jsr	openlib(a6)	;dos.library
	move.l	d0,dosbase	;dosbase retten
	move.l	d0,a6
	move.l	#fname,d1	;fenster oeffnen
	move.l	#1005,d2
	jsr	open(a6)	;handle retten
	move.l	d0,handle
	beq	nofen
anf:
	bsr	clr
	move.l	#ausgabe1,d2	;text zur ausgabe
	bsr	pmsg		;ausgeben
	bsr	anzahl
	move.l	#ausgabe2,d2	;text zur ausgabe
	bsr	pline		;ausgeben
 	bsr	getnames
	move.l	#ausgabe3,d2	;text zur ausgabe
	bsr	pline		;ausgeben
	bsr	will
	cmp.b	#1,d0
	beq	wit
	bra.s 	anf
wit:
	bsr	inst
	move.l	dosbase,a6
	move.l	handle,d1
	move.l	#line,d2
	bsr	pline
	move.l	#ausgabe4,d2	;text zur ausgabe                         
	bsr	pline		;ausgeben
	bsr	will
	cmp.b	#1,d0
	bne.s	wit1
	bsr	linst
wit1:
	move.l	dosbase,a6
	move.l	handle,d1
	move.l	#line,d2
	bsr	pline
	move.l	#ausgabe5,d2	;text zur ausgabe                         
	bsr	pline		;ausgeben
	bsr	will
	cmp.b	#1,d0
	bne.s	wit2
	bsr	sinst
wit2:
	moveq	#$c,d0
	bsr	pchar
	move.l	#ausgabe6,d2	;text zur ausgabe                         
	bsr	pline		;ausgeben
	bsr	will
	
seufz:
	move.l	dosbase,a6
	move.l	handle,d1
	jsr	close(a6)
nofen:
	move.l	(execbase).w,a6
	move.l	dosbase,a1
	jsr	closelib(a6)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
;************************************
;******     Unterprogramme     ******
;************************************
sinst:
	move.l	(execbase).w,a6
	move.l	#2000,d0
	move.l	#$10002,d1
	jsr	-$c6(a6)
	tst.l	d0
	beq	seufz2
	move.l	d0,startup
	move.l	dosbase,a6
	move.l	#sload,d1
	move.l	#1005,d2
	jsr	open(a6)
	move.l	d0,fhandle
	beq	spenerror
	move.l	d0,d1
	move.l	startup,d2
	move.l	#2000,d3
	jsr	read(a6)
	cmp.b	#-1,d0
	beq	readerror
	move.l	d0,laeng
	move.l	fhandle,d1
	jsr	close(a6)
	moveq	#$c,d0
	bsr	pchar
	move.l	#stmess,d2
	bsr	pline
	move.l	startup,d2
	bsr	pline	
	move.l	#stmess2,d2
	bsr	pmsg
xnzahl:
	moveq	#0,d0
 	bsr	readchr
	lea	inline,a0
	cmp.b	#"a"-1,(a0)
	bgt	xuswert
	cmp.b	#"1",(a0)
	blt	xnzahl
	cmp.b	#"9",(a0)
	bgt	xnzahl
	move.b	(a0),d0
	sub.w	#48,d0
	move.l	d0,wiev
	bra.s	xus1
xuswert:
	cmp.b	#"f",(a0)
	bgt	xnzahl
	move.b	(a0),d0
	sub.w	#87,d0
	move.l	d0,wiev
xus1:
	move.b	(a0),d0
	bsr	pchar
	move.l	(execbase).w,a6
	move.l	laeng,d0
	addq	#7,d0
	move.l	#$10002,d1
	jsr	-$c6(a6)
	tst.l	d0
	beq	seufz3
	move.l	d0,sbuffer
	move.l	startup,a1
	move.l	d0,a0
	moveq	#1,d2
	move.l	wiev,d1
	move.l	laeng,d0
	subq	#1,d0
scop1:
	cmp.b	d1,d2
	beq	scop2
scop3:	
	move.b	(a1)+,d7
	cmp.b	#$0a,d7
	bne	scop4
	addq	#1,d2
scop4:	
	move.b	d7,(a0)+
	dbf	d0,scop1
	bra.s	scop5
scop2:
	move.b	#"l",(a0)+
	move.b	#"o",(a0)+
	move.b	#"a",(a0)+
	move.b	#"d",(a0)+
	move.b	#"e",(a0)+
	move.b	#"r",(a0)+
	move.b	#$0a,(a0)+
	move.b	#$a0,d2
	bra.s	scop3
scop5:
	cmp.w	#$9f,d2
	blt	zuviel
	move.l	dosbase,a6
	move.l	#sload,d1
xdelete:
	jsr	delete(a6)
spene5:
	move.l	#sload,d1
	move.l	#1006,d2
xopen:
	jsr	open(a6)
	move.l	d0,fhandle
	beq	s2penerror
	move.l	d0,d1
	move.l	laeng,d3
	addq	#7,d3
	move.l	sbuffer,d2
xwrite:
	jsr	write(a6)
	cmp.b	#-1,d0
	bne	scop6
	move.l	#swerror,d2
	bsr	pline
scop6:
	move.l	fhandle,d1
	jsr	close(a6)
spene2:
	move.l	(execbase).w,a6
	move.l	laeng,d0
	addq	#7,d0
	move.l	sbuffer,a1
	jsr	-$d2(a6)
spene1:
	move.l	(execbase).w,a6
	move.l	#2000,d0
	move.l	startup,a1
	jsr	-$d2(a6)
	rts
zuviel:
	move.l	#line,d2
	bsr	pline
	move.l	#line,d2
	bsr	pline
	move.l	#zuviel1,d2
	bsr	pline
	bsr	willi	
	bra	spene2
readerror:
	move.l	#readerr,d2
	bsr	pline
	bsr	will
	move.l	fhandle,d1
	jsr	close(a6)
	bra	spene1
s2penerror:
	move.l	#line,d2
	bsr	pline
	move.l	#serror,d2
	bsr	pline
	bsr	will
	bra	spene2
spenerror:
	moveq	#$c,d0
	bsr	pchar
	move.l	#line,d2
	bsr	pline
	move.l	#serror,d2
	bsr	pline
	move.l	#nofile,d2
	bsr	pline
	bsr	will
	cmp.b	#1,d0
	bne.s	wit3
	move.l	#0,laeng
	move.l	(execbase).w,a6
	move.l	laeng,d0
	addq	#7,d0
	move.l	#$10002,d1
	jsr	-$c6(a6)
	tst.l	d0
	beq	seufz3
	move.l	d0,sbuffer
	move.l	d0,a0
	move.l	#"load",(a0)+
	move.w	#"er",(a0)+
	move.b	#$0a,(a0)+
	move.l	dosbase,a6
	bra	spene5
wit3:
	move.l	fhandle,d1
	jsr	close(a6)
	bra	spene1
linst:
	move.l	#fload,d1
	move.l	#1006,d2
	jsr	open(a6)
	move.l	d0,fhandle
	beq	openerror
	move.l	d0,d1
	move.l	#loader,d2
	move.l	#loaderende-loader,d3
	jsr	write(a6)
	beq	writeerror
liclose:
	move.l	fhandle,d1
	jsr	close(a6)
	rts
openerror:
	move.l	dosbase,a6
	move.l	handle,d1
	move.l	#line,d2
	bsr	pline
	move.l	#oerror,d2
	bsr	pline
	rts

writeerror:
	move.l	dosbase,a6
	move.l	handle,d1
	move.l	#line,d2
	bsr	pline
	move.l	#werror,d2
	bsr	pline
	bra.s	liclose
seufz3:
	move.l	(execbase).w,a6
	move.l	#2000,d0
	move.l	startup,a1
	jsr	-$d2(a6)
seufz2:
	move.l	#nomem,d2
	bsr	pline
	bsr	will
	bra	seufz
clr:
	moveq	#$c,d0
	bsr	pchar
	rts
secnam:
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	#b,d2
	bsr	pmsg
	moveq	#0,d4		;zaehler
xl1:
	bsr	readchr
	lea	inline,a0
	cmp.b	#$0d,(a0)
	beq	xspafil
	cmp.b	#" ",(a0)
	blt	xl1
	cmp.b	#"z",(a0)
	bgt	xl1
xok1:
	move.b	(a0),(a3)+	
	addq	#1,d4
	move.b	(a0),d0
	bsr	pchar
	cmp.b	#35,d4
	bne	xl1
	move.b	#$0,(a3)+
	move.b	#$a,d0
	bsr	pchar
	move.b	#$d,d0
	bsr	pchar
	movem.l	(sp)+,d0-d7/a0-a6
	rts
xspafil:
	move.b	#$0,(a3)+
	addq	#1,d4
	cmp.b	#35,d4
	bne	xspafil
	move.b	#$0,(a3)+
	move.b	#$a,d0
	bsr	pchar
	move.b	#$d,d0
	bsr	pchar
	movem.l	(sp)+,d0-d7/a0-a6
	rts
getnames:
	lea	prg1,a3
	lea	xnames,a5
	moveq	#0,d5
	move.b	(a5)+,d5	;ab a0 muessen die namen stehen
	subq	#1,a5
eing:
	move.l	#a,d2
	bsr	pmsg
	moveq	#0,d4		;zaehler
	addq	#1,a5
l1:
	bsr	readchr
	lea	inline,a0
	cmp.b	#$0d,(a0)
	beq	spafil
	cmp.b	#$20,(a0)
	beq	ok
	cmp.b	#"A",(a0)
	blt	l1
	cmp.b	#"z",(a0)
	bgt	l1
	cmp.b	#"Z",(a0)
	bgt	t1
ok:
	move.b	(a0),d6	
	cmp.b	#90,d6
	blt	ok1
	sub.w	#32,d6
ok1:
	move.b	d6,(a5)+	
	addq	#1,d4
	move.b	(a0),d0
	bsr	pchar
	cmp.b	#20,d4
	bne	l1
	move.b	#$a,d0
	bsr	pchar
	move.b	#$d,d0
	bsr	pchar
	bsr	secnam
	add.w	#36,a3
	dbf	d5,eing
	bra	goon	
t1:	
	cmp.b	#"a",(a0)
	blt	l1
	bra.s	ok
spafil:
	move.b	#$ff,(a5)+
	addq	#1,d4
	cmp.b	#20,d4
	bne	spafil
	move.b	#$a,d0
	bsr	pchar
	move.b	#$d,d0
	bsr	pchar
	bsr	secnam
	add.w	#36,a3
	dbf	d5,eing
goon:
	lea	xnames,a0
	lea	names,a1
	clr.l	d0
	move.b	(a0)+,d0
	move.b	d0,(a1)+
goon5:
	clr.l	d2
	move.l	a0,a2
goon2:
	move.b	(a2)+,d1
	beq	goon1
	cmp.b	#$ff,d1
	beq	goon1
	addq	#1,d2
	bra	goon2
goon1:
	move.l	d2,d3		;anzahl der Buchstaben
	beq	goon6
	subq	#1,d3		;-2  der erste und letzte
	lsl.l	#2,d3
	addq	#1,d3		; aufheben ....
	lsr.l	#1,d3		;durch 2 
	move.b	d3,(a1)+
	subq	#1,d2
	move.b	d2,(a1)+	;anzahl der Buchstaben
goon3:
	clr.l	d7
	move.b	(a0)+,d7
	cmp.b	#32,d7
	beq	spa
	sub.b	#65,d7
	mulu.w	#5,d7
goon7:
	move.b	d7,(a1)+
	dbf	d2,goon3
goon4:
	move.b	(a0)+,d2
	bne	goon4
	dbf	d0,goon5
	rts
goon6:
	move.b	#$0,(a1)+
	move.b	#$ff,(a1)+
	bra.s	goon4
spa:
	moveq	#-1,d7
	bra.s	goon7
will:
	moveq	#0,d0
willi:

	btst	#6,$bfe001	; auf maustaste- ende von prg
	beq.s	will2
	btst	#10,$dff016
	bne.s	willi
willi1:
	rts
will2:
	moveq	#1,d0
	rts
readchr:
	moveq	#1,d3
	move.l	#inline,d2
	move.l	handle,d1
	jsr	read(a6)
	rts
anzahl:
	moveq	#0,d0
	bsr.s	readchr
	lea	inline,a0
	cmp.b	#"a",(a0)
	beq	auswert
	cmp.b	#"1",(a0)
	blt	anzahl
	cmp.b	#"9",(a0)
	bgt	anzahl
	move.b	(a0),d0
	sub.w	#48,d0
	bra.s	aus1
auswert:
	moveq	#10,d0
aus1:
	lea	xnames,a1
	subq	#1,d0
	move.b	d0,(a1)
	clr.b	0(a0,a0)
	bsr	pline
	rts
pline:
	bsr	pmsg
pcrlf:
	move.l	#10,d0
	bsr	pchar
	move.l	#13,d0
pchar:	move.b	d0,outline
	move.l	#outline,d2
pmsg:
	move.l	d2,a0
	clr.l	d3
ploopp:
	tst.b	(a0)+
	beq	pmsg2
	addq.l	#1,d3
	bra	ploopp
pmsg2:
	move.l	dosbase,a6
	move.l	handle,d1
	jsr	write(a6)
	rts
subb1:	
	add.w	#80,6(a0)
	addq.w	#1,2(a0)
findtask 	equ -294
addport 	equ -354
remport 	equ -360
opendevice 	equ -444
closedevice 	equ -450
doio 		equ -456
laenge		equ 1024
inst:
	move.l	(execbase).w,a6
	move.l	#20000,d0
	move.l	#$10002,d1
	jsr	-$c6(a6)
	tst.l	d0
	beq	seufz2
	move.l	d0,a5
	move.l	d0,speicher
	lea	bootmain(pc),a0		; normalen Bootblock
	move.l	a0,buf(a5)		; in buf eintragen
	move.l	#bootende-bootmain,lang(a5)	; und Länge eintragen
run:
	lea	puffer(a5),a1		; Floppybuffer nach a1
	move.l	a1,a2
	lea	bootmain(pc),a0	;startadresse holen
	lea	bootende(pc),a3	;enadresse holen
	sub.l	a0,a3		;laenge errechnen
	move.l	a3,d0
	subq.l	#1,d0
copy_schleife2:
	move.b	(a0)+,(a1)+	;und an neue pos. kopieren
	dbf	d0,copy_schleife2

	move.l	a2,buf(a5)
checksumme:
	move.l	buf(a5),a3
 	move.l	a3,a0
	clr.l	4(a0)
	move.l	#$ff,d1
	moveq	#0,d0
loop:	add.l	(a3)+,d0
	bcc.s	jump
	addq.l	#1,d0
jump:	dbra	d1,loop
	not.l	d0
	move.l	d0,4(a0)
	move.l	4.w,a6
	sub.l	a1,a1
	jsr	findtask(a6)		; Task finden
	lea	replyport(a5),a1
	move.l	d0,16(a1)		; Replyport eintragen
	jsr	addport(a6)
	lea	diskio(a5),a1
	lea	replyport(a5),a0
	move.l	a0,14(a1)
	moveq	#0,d0
	move.b	dr(a5),d0		; drive number
	moveq	#0,d1
	lea	trdname(pc),a0
	jsr	opendevice(a6)		; open trackdisk.device
	move.w	#3,28(a1)		; Command Write
	move.l	#2*512,36(a1)		; Anzahl bytes
	move.l	buf(a5),a0
	move.l	a0,40(a1)		; Puffer
	move.l	#0,44(a1)		; Offset
	jsr	doio(a6)
	move.w	#4,28(a1)		; Command Update
	jsr	doio(a6)
	move.w	#9,28(a1)		; Command Motor aus
	clr.l	36(a1)
	jsr	doio(a6)
ende:	lea	replyport(a5),a1
	jsr	remport(a6)
	lea	diskio(a5),a1
	jsr	closedevice(a6)
	move.l	(execbase).w,a6
	move.l	#20000,d0
	move.l	speicher,a1
	jsr	-$d2(a6)
	rts
trdname:
		dc.b "trackdisk.device",0
dosname:
		dc.b "dos.library",0
	even
	rsreset
	cnop 0,4
diskio		rs.b	80
replyport	rs.b	32
info		rs.b	36
infoblock	rs.b	260
loc		rs.l	1
hd		rs.l	1
dosbase		rs.l	1
dhd		rs.l	1
lang		rs.l 	1
buf		rs.l	1
dr		rs.b	2
liste		rs.l	10
puffer		rs.b	11024
VARE		rs.l	0
	even
speicher:
	dc.l	1
laeng:
	dc.l	1
sbuffer:
	dc.l	1
wiev:
	dc.l	1
startup:
	dc.l	1
fhandle:
	dc.l	1
handle:
	dc.l	1
fname:	
	dc.b	"raw:0/10/640/200/Boot Gen 0.1",0
ausgabe1:
	dc.b	"                 Wieviele Programme sollen geladen werden ? ",$0d,$0a
	dc.b	"                                 ( 1 - $a )",$0d,$0a
	dc.b	"Anzahl : ",0
ausgabe2:
	dc.b	"     Geben Sie nun die Programmnamen ein, maximal 20 Buchstaben.",$0d,$0a
	dc.b	$0d,$0a
	dc.b	"      Unter a. geben sie bitte den Namen ein, der im Bootblock ",$0d,$0a
	dc.b	"                      ausgegeben werden soll.",$d,$a,$d,$a
	dc.b	"       Unter b. geben sie bitte den Namen ein, unter dem das",$d,$a
	dc.b	"                   Programm geladen werden soll.",0
ausgabe3:
	dc.b	"     Druecke rechte Maustaste fuer erneute Eingabe",$0d,$0a
	dc.b	"       Druecke linke Maustaste um Bootblock auf",$0d,$0a
	dc.b	"               DF0: zu installieren.",0
ausgabe4:
	dc.b	"     Druecke linke Maustaste um Loader in DF0:C/ zu installieren ... ",$0d,$0a
	dc.b	"        Druecke rechte Maustaste um das zu umgehen...",0

ausgabe5:
	dc.b	"     Druecke linke Maustaste um Loader in die STARTUP-SEQUENCE",$0d,$0a
	dc.b	"                    zu installieren...",$0d,$0a
	dc.b	"        Druecke rechte Maustaste um das zu umgehen...",0
ausgabe6:
	dc.b	$d,$a,$d,$a,$d,$a
	dc.b	"     So das wars Maustaste druecken ... und Tschuess",0
stmess:
	dc.b	$d,$a,$d,$a,"STARTUP-SEQUENCE  :",$d,$a
	dc.b		    "-------------------",0
stmess2:
	dc.b	"     Vor welcher Zeile soll ´ loader ´ eingefuegt werden ( 1 - f ) ?",$d,$a
	dc.b	"                  Zeile  ",0
oerror:
	dc.b	"   File DF0:C/LOADER kann nicht geöffnet werden ...",0
serror:
	dc.b	"   File DF0:S/STARTUP-SEQUENCE kann nicht geöffnet werden ...",0
werror:
	dc.b	"    File DF0:C/LOADER kann nicht beschrieben werden ...",0
swerror:
	dc.b	"    File DF0:S/STARTUPE-SEQUENCE kann nicht beschrieben werden ...",0
readerr:
	dc.b	"   File DF0:S/STARTUPE-SEQUENCE kann nicht gelesen werden...",$d,$a
	dc.b	"              ich steige jetzt aus .... ",0
nofile:
	dc.b	$a,$d,"   Wahrscheinlich existiert das File DF0:S/STARTUP-SEQUENCE nicht",$a,$d
	dc.b	"                     soll ich eins erschaffen ?",$a,$d,$a,$d
	dc.b	"           Druecke linke Maustaste um die STARTUP-SEQUENCE",$0d,$0a
	dc.b	"                         zu installieren...",$0a,$d
	dc.b	"            Druecke rechte Maustaste um das zu umgehen...",0
zuviel1:
	dc.b	"    Die STARTUP-SEQUENCE hat nicht genug Zeilen, sie bleibt",$a,$d
	dc.b	"                          unverändert.",0
nomem:
	dc.b	"    Es ist nicht genuegend Speicherplatz vorhanden, ich",$d,$a
	dc.b	"               steige jetzt aus .... ",0
a:
	dc.b	"a.",0
b:
	dc.b	"b.",0

xnames:
	dc.b	5		;anzahl der auszugebenden namen
xnnames:
	ds.b	141
line:
	dc.b	0
fload:
	dc.b	"df0:c/LOADER",0
sload:
	dc.b	"df0:s/startup-sequence",0
	even
outline:
	dc.w	0
inline:
	ds.b	20

	even
eingabe:
	ds.w	0
loader:
	dc.w	$0000,$03f3,$0000,$0000,$0000,$0001,$0000,$0000
	dc.w	$0000,$0000,$0000,$0096,$0000,$03e9,$0000,$0096

start:
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	(execbase).w,a6
	lea	grname(pc),a1	;graphix lib oeffnen
	jsr	openlib(a6)	;wiederyufinden
	move.l	d0,a4
	move.l	d0,a1
	move.l	#$dff000,a5
	move.l	startlist(a4),$80(a5)
	jsr	closelib(a6)	
	clr.w	$88(a5)		;alte copperlist eintragen
	move.w	#$83e0,$96(a5)	;dmacon
	jsr	permit(a6)	;taskswitch erlaubt
	move.l	$79000,d0
	beq	noload
	subq	#1,d0
	mulu.w	#36,d0
	lea	offset(pc),a1
	move.l	d0,(a1)
opendoslib:
	lea	xdosname(pc),a1
	moveq	#0,d0
	jsr	-552(a6)
	tst.l	d0
	beq.s	liberror
	move.l	d0,a6
loadsegment:
	lea	prg1(pc),a1
	move.l	a1,d1
	lea	offset(pc),a1
	add.l	(a1),d1
	jsr	-150(a6)
	tst.l	d0
	beq.s	closedoslib
	move.l	d0,d7
segmentloop:
	lsl.l	#2,d0
	move.l	d0,a0
	move.l	(a0),d0
	bne.s	segmentloop
	lea	start-4(pc),a1
	move.l	a1,d1
	lsr.l	#2,d1
	move.l	d1,(a0)
	move.l	4.w,a6
	sub.l	a1,a1
	jsr	-294(a6)
	tst.l	d0
	beq.s	closedoslib
	move.l	d0,a0
	move.l	172(a0),d0
	lsl.l	#2,d0
	move.l	d0,a0
	lea	$3c(a0),a0
	move.l	d7,(a0)
	lsl.l	#2,d7
	addq.l	#4,d7
	lea	vektor(pc),a0
	move.l	d7,(a0)
	bsr.s	closedoslib1
	movem.l	(a7)+,d0-d7/a0-a6
	dc.w	$4ef9		; jmp
vektor:
	dc.l	0
closedoslib:
	movem.l	(a7)+,d0-d7/a0-a6
closedoslib1:
	move.l	4.w,a6
	move.l	a6,a1
	jsr	-414(a6)
liberror:
	moveq	#0,d0
	rts
noload:
	movem.l	(a7)+,d0-d7/a0-a6
	rts
offset:
	dc.l	0
prg1:
	ds.b	36
prg2:
	ds.b	36
prg3:
	ds.b	36
prg4:
	ds.b	36
prg5:
	ds.b	36
prg6:
	ds.b	36
prg7:
	ds.b	36
prg8:
	ds.b	36
prg9:
	ds.b	36
prga:
	ds.b	36
grname:
	dc.b	"graphics.library",0
xdosname:
	dc.b	"dos.library",0
	dc.b	$00
	dc.w	$0000,$0000,$03f2
loaderende:


	even

bootmain:
	dc.b "DOS",0
	dc.l 0
	dc.l 880
bootprg:
	lea resname(pc),a1
	jsr -96(a6)
	move.l 	d0,a0
	move.l 	22(a0),a0
	moveq 	#$00,d0
plane	equ	$50000		; bitplane beginnt ab $70000
cop	equ	$78500	; addresseder cpperlist liegt hint. bitplane
init_plane:			; bitplane initialisieren , clrplane
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	#$50000,a1
	move.l	a1,a0
	add.w	#$4fe0,a0
	move.w	#$a400,d0
nochmal0:
	clr.l	(a1)+
	dbf	d0,nochmal0
	move.l	#$55024,a1
	lea	right(pc),a4	; was auszugeben ist holen
	movem.l	(a0)+,d0-d7
	moveq	#4,d6
printc3:
	move.b	(a4)+,d7
	lea 	code(pc),a2
	add.w	d7,a2
 	moveq	#4,d4
printc4:
	move.b	(a2)+,(a1)	;ist immer noch alles wie bei refresh
	add.w	#80,a1
	dbf	d4,printc4
	sub.w	#399,a1
	dbf	d6,printc3
	move.b	#180,d1		; y.pos
	move.b	(a4)+,d2	;anzahl der namen
ausweiter:	
	move.b	(a4)+,d3	;x-pos
	move.b	#40,d0
	sub.w	d3,d0
	clr.l	d6		; einfach nur loeschen
	move.b	(a4)+,d6	;anzahl der byte . .
	bmi.s	ausend
a1usweiter:	
	move.b	(a4)+,d7	;erster buchstabe nach d7
	bmi.s	space3
print_at_ein:			; in d7 steht zeichen fertig zur ausgabe
	movem.l	d0-d7/a0-a6,-(a7)
	lsl.l	#3,d1		; y*640 (jetzt nur noch mal 8 wegen screen )um die pos. zu ermitteln
	add.w	d0,a0		;bitplane + x-wert
	add.w	d1,a0		;bitplane + y-wert
	lea 	code(pc),a2
	add.w	d7,a2
				;in a2 steht aktuelle code adresse
				;in a0 aktuelle plane adresse
	moveq	#3,d4
printc2:
	move.b	(a2),(a0)	;ist immer noch alles wie bei refresh
	move.b	(a2)+,80(a0)	;ist immer noch alles wie bei refresh
	add.l	#$a0a0,a0	;fuer naehere docs s. main.s bei refresh...
	dbf	d4,printc2
	sub.l	#$28000,a0
	move.b	(a2),(a0)
	move.b	(a2),80(a0)	;ist immer noch alles wie bei refresh
	add.l	#$a000,a0
	move.b	(a2),(a0)
	move.b	(a2),80(a0)	;ist immer noch alles wie bei refresh
	movem.l	(sp)+,d0-d7/a0-a6
space3:
	addq	#4,d0	  	;abstand zwischen den zeichen ( 1 = 8 Pixels )
	dbf	d6,a1usweiter	; naechstes zeichen holen
ausend:				;ausgaben ende
	add.w   #160,d1
	dbf	d2,ausweiter
	move.l	$6c.w,-(a7)
	lea	pause(pc),a0
	move.l 	a0,$6c.w
	move.l	(execbase).w,a6
	move.l	#register,a5
	move.w	#$03a0,$96(a5)	;Dmacon
	move.l	#cop,d3
	move.l	d3,$80(a5)	;Copperliste eintragen
	clr.w	$88(a5)		;und aufrufen
setpar:
	lea	par(pc),a4	;Startaddresse von parameter daten
	moveq	#13,d1		;Für Grafik
ploop:
	move.w	(a4)+,d0	;  | und parameter setzen
	move.w	(a4)+,(a5,d0)	;/
	dbf	d1,ploop
	move.w	#$8380,$96(a5) 	;Damcon
	moveq	#$30,d7
	bsr	copper		;Copperliste zum ersren mal initialisieren
	move.b	#$30,$36(a5)	;Wenn echt kleiner 38, dann maus auf pos ( y ) 38
	bsr	scollin
wait:				;wait fuer mausabfrage
	move.b	$a(a5),d7		;abfrage
	cmp.b	#38,d7		;kleinster vertikaler ( y ) wert
	ble.s	hier		;Wenn kleiner gleich, verzweige
hier1:
	cmp.b	#208,d7		;groesster vertikaler wert
	bge.s	next		;wenn groesseer gleich, verzweige
next1:
	bsr.s	copper		;und neue copperliste schreiben
	bra.s 	hiernext	;weiter in die warte schleife
hier:
	btst	#7,d7		;bit 7 wird getestet ob groesser 127 ( < 0
	bne.s	hier1		;wenn bit 7 gesetzt, dann zawr kleiner als null aber trotzdem zurueck
	move.b	#$26,$36(a5)	;Wenn echt kleiner 38, dann maus auf pos ( y ) 38
	bra.s	hiernext	; weiter in der warteschleife
next:
	btst	#7,d7		;bit 7 wird getestet ob kleiner 127 
	beq.s	next1		;falls kleiner, dann kein grund zur sorge, zuruck und copperlist init.
	move.b	#$d0,$36(a5)	;Wenn echt groesser als 217  dann maus auf 217
hiernext:
	btst	#10,$16(a5)
	beq.s	nix	
	btst	#6,$bfe001	; auf maustaste- ende von prg
	bne.s	wait
creset:	
	move.l	#$79003,a0
	move.b	$29(a4),d0	;which-one
	addq	#1,d0
w1ei:
	move.b	d0,(a0)
nix:
	bclr	#1,-$50(a4)
	bset	#0,-$48(a4)
	bsr	scollin
	moveq	#30,d0
	add.w	#$182,a5
black:
	move.w	#0,(a5)+
	dbf	d0,black
	move.l	(sp)+,$6c.w
	movem.l	(sp)+,d0-d7/a0-a6
	rts
copper:
	move.b	$be(a4),d1	;names
	addq	#3,d1
	move.b 	d7,d0
	lsr.b	#4,d0
	move.b	d0,d6
	cmp.b	d0,d1
	blt	copdat2
	lsl.b	#4,d0
	cmp.b	d0,d7
	bne.s	copdat2
	lea	copb(pc),a2	;y.-pos
	move.b  d7,(a2)
	subq	#3,d6
	move.b	d6,$29(a4)	;which-one
	bsr.s	ccopy
copdat:				;routine um farben von null auf $f in die copperliste zu schreiben 
	lea	copl(pc),a0	;Farbe 		  - kopieren
	bsr.s	coppy
	addq	#1,2(a0)
	cmp.b	#$f,3(a0)	;Farbe schon $f
	bne.s	copdat		;wenn nein, dann nochmal hoch
copdat1:

	bsr.s	coppy
	subq	#1,2(a0)
	cmp.b	#$ff,3(a0)
	bne.s	copdat1
	move.l	#$fffffffe,(a1)+;copperliste mit unmoeglicher wait pos beenden
	addq	#1,2(a0)	; muss dazu addiert werden sonst weisser balken
copdat2:
	rts 			;copperliste fertig, und zurueck
coppy:
	move.b	(a2),(a1)+	;                 - kopieren
	add.b	#1,(a2)		
	move.b	#$0f,(a1)+	;gehoert zu y.pos - kopieren
	move.w	#$fffe,(a1)+	;wait... 	  - kopieren
	move.l	(a0),(a1)+	;  "			"
	lea	colors(pc),a3
setcol:
	moveq	#4,d0		;Für Grafik
p2loop:
	move.w	(a3)+,(a1)+	;  | und parameter setzen
	move.w	(a3)+,d1
	or.w	2(a0),d1
	move.w	d1,(a1)+
	dbf	d0,p2loop
	rts
ccopy:
	move.l	d3,a1		;adresse der copperlist nach a1
	move.l	a4,a0
	moveq	#17,d0		;6 teile werden kopiert
c1copy:
	move.w	(a0)+,(a1)+
	dbf	d0,c1copy	;kopieren
	rts
pause:	
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	#$54fd4,a1		
	moveq	#4,d1
won4:
	add.w	#80,a1
	move.l	(a1),d2
	lsl.l	#1,d2
	bcc.s	won2
	bset	#0,7(a1)
won2:
	move.l	d2,(a1)
	move.l	4(a1),d2
	lsl.l	#1,d2
	bcc.s	won3
	bset	#0,3(a1)
won3:
	move.l	d2,4(a1)
	dbf	d1,won4
	movem.l	(sp)+,d0-d7/a0-a6
	jmp $fc0cd8
scollin:
	move.w	#$ff,d1
weit0:
weit2:
	move.w	#$250,d2	;verzoegerungsschleife
w2eit:
	dbf	d2,w2eit
	lea	list1(pc),a0
	moveq	#3,d0
weit:
	addq	#8,a0
add1:
	add.w	#80,6(a0)
	bhs.s	weit1
add2:
	addq.w	#1,2(a0)
weit1:
	dbf	d0,weit
	bsr.s	ccopy
	dbf	d1,weit0
	rts
par:				; ab hier stehen die eigentlichen
	dc.w   $08e,$2981		; parameter fuer planes ...
   	dc.w   $090,$29c1
   	dc.w   $092,$003c
   	dc.w   $094,$00d4
   	dc.w   $100,$c200
   	dc.w   $102,$0000
   	dc.w   $104,$0000
   	dc.w   $108,00000
   	dc.w   $10a,00000
colors:
	dc.w	$182,$0f90
	dc.w	$184,$0fb0
	dc.w	$186,$0ff7
	dc.w	$188,$0fd0
list1:
	dc.w	$190,$0ff4
list:
	dc.w	$270f,$fffe	;anfang einer Copperlist
	dc.w	$0e0,$0005
	dc.w  	$0e2,$0000
	dc.w	$0e4,$0005
	dc.w  	$0e6,$a000
	dc.w	$0e8,$0006
	dc.w  	$0ea,$4000
	dc.w	$0ec,$0006
	dc.w  	$0ee,$e000
copl:
	dc.w	$180		;Farbe...
	dc.w	$0000
	dc.b	$00
	dc.b	$01
copb:
	dc.b	$50		;y.pos
code:				;zeichensatz daten nur Grossbuchstaben	
	dc.b	$20,$50,$70,$88,$88
	dc.b	$F0,$88,$F0,$88,$F0
	dc.b	240-128,$88,$80,$88,240-128
	dc.b	$E0,$90,$88,$90,$E0
	dc.b	$F8,$80,$E0,$80,$F8
	dc.b	$F8,$80,$E0,$80,$80
	dc.b	$F8,$80,$B8,$88,$F8
	dc.b	$88,$88,$F8,$88,$88
	dc.b	$38,$10,$10,$10,$38
	dc.b	$70,$20,$20,$24,$18
	dc.b	$90,$A0,$C0,$A0,$90
	dc.b	$E0,$40,$40,$48,$78
	dc.b	$88,$D8,$A8,$88,$88
	dc.b	$88,$C8,$A8,$A8,$98
	dc.b	$70,$88,$88,$88,$70
	dc.b	$E0,$90,$E0,$80,$80
	dc.b	$70,$88,$A8,$98,$70
	dc.b	$F0,$88,$F0,$88,$88
	dc.b	$38,$40,$30,$88,$70
	dc.b	$F8,$20,$20,$20,$20
	dc.b	$88,$88,$88,$88,$70
	dc.b	$44,$44,$44,$28,$10
	dc.b	$44,$44,$54,$6C,$44
	dc.b	$44,$28,$10,$28,$44
	dc.b	$44,$28,$10,$10,$10
	dc.b	$7C,$08,$10,$20,$7C
resname:
	 dc.b "dos.library",0
right:
	dc.b	10,35,85,40,90
names:
	dc.b	0		;anzahl der auszugebenden namen
nnames:
	ds.b	141
bootende:
