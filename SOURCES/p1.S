

	move.b #$0f,d0
	move.b #20,d1
loop:

	sub.b #1,d1
	sub.b #1,d0
	cmp.b #$40,d0
	blt x
	add.b #$10,d0
x:
	cmp.b #0,d1
	jne loop
	
