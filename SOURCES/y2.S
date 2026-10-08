Comienzo:
	move.b TomPos+1,d0
	cmpi.b #220,d0
	bls .NoEndAnimation
	move #1,d1

.NoEndAnimation
	move #2,d1
	
TomPos:
	dc.w $8cEE,$9c80
	
