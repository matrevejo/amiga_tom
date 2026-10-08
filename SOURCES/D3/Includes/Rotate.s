rotate
* x: d5, svaret kommer også ud der!
* y: d6
* z: d7
* a4: sinustabel
* a3: cosinustabel
* a5: Vinkeltabel (z,y,x!)

	move	(a5)+,d0	; 8	(2/0)
	add	d0,d0	 	; 4	(1/0)
	move	0(a4,d0.w),d1	;14	(3/0)
	move	0(a3,d0.w),d0	;14	(3/0)

	move	d5,d2		; 4	(1/0)
	move	d6,d3		; 4	(1/0)
	
	muls	d0,d5		;56	(1/0)
	muls	d1,d2		;56	(1/0)
	muls	d1,d3		;56	(1/0)
	muls	d0,d6		;56	(1/0)
	
	add.l	d2,d6		; 8	(1/0)
	sub.l	d3,d5		; 8	(1/0)
	asl.l	#2,d6		;12	(1/0)
	asl.l	#2,d5		;12	(1/0)
	swap	d6		; 4	(1/0)
	swap	d5		; 4	(1/0)

* Sum, clockcycles per rot.:	;320	(21/0)

	move	(a5)+,d0
	add	d0,d0
	move	0(a4,d0.w),d1
	move	0(a3,d0.w),d0
	
	move	d5,d2
	move	d7,d4
	
	muls	d0,d5
	muls	d1,d2
	muls	d0,d7
	muls	d1,d4
	
	add.l	d4,d5
	sub.l	d2,d7
	asl.l	#2,d5
	asl.l	#2,d7
	swap	d5
	swap	d7
	
 	move	(a5),d0
	add	d0,d0
	move	0(a4,d0.w),d1	;d1=sin(rx)
	move	0(a3,d0.w),d0	;d0=cos(rx)
	
	move	d6,d3
	move	d7,d4
	
	muls	d0,d6
	muls	d1,d3
	muls	d0,d7
	muls	d1,d4
	
	sub.l	d4,d6
	add.l	d3,d7
	asl.l	#2,d6
	asl.l	#2,d7
	swap	d6
	swap	d7

* Clockcycles efter 3 rot.:	;960 	(63/0)
	
	subq.l	#4,a5		;  8	(1/0)

oyep=1000
oyep2=250*65536
	neg	d7		;  4	(1/0)
	add	#oyep,d7	;  8	(2/0)
			
	move.l	#oyep2,d0	; 12	(3/0)
	divu	d7,d0		;134	(1/0)	ca. værdi!
	
	muls	d0,d6		; 56	(1/0)
	muls	d0,d5		; 56	(1/0)
	swap	d6		;  4	(1/0)
	swap	d5		;  4	(1/0)
	add.w	#159,d5		;  8	(2/0)
	add.w	#127,d6		;  8	(2/0)
	rts			; 16	(4/0)
	
* Sum, clockcycles :	        ;ca 1278	(83/0)
* Hvis blitteren arbejder for fuld tryk:
* 1278+6*83=  ca 1776	


