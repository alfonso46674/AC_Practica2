	
	.text
	#Addi
	addi $t0, $zero, 2
	addi $t1, $zero, 5
	
	#add
	add $t2, $t0, $t1 #t1 + t0 = 7
	
	#sub
	sub $t2, $t1, $t0 #t1 - t0 = 3
	
	#or
	or $t2, $t1, $t0 # debe de dar 7
	
	#ori
	ori $t2, $t1, 4 # debe de dar 5
	
	#and
	and $t2, $t1, $t0 # debe de dar 0
	
	#andi
	andi $t2, $t1, 6 # debe de dar 4
	
	#lui
	lui $t3, 8
	#nor
	nor $t2, $t1, $t0 # debe de dar fffffff8
	
	#sll
	sll $t2, $t1, 2 # debe de dar 20
	
	#srl
	srl $t2, $t1, 2 # debe de dar 1
	
	#lw
	
	#sw
	
	#beq
	addi $t1, $zero,2
	beq $t1,$t0, prueba
	addi $t3, $zero, 1
prueba:	addi $t1, $zero,9


	#bne
	bne $t0, $t1, prueba2
	addi $t1, $zero, 8
prueba2: addi $t0, $zero, 4
	#j
	
	#jal
	
	#jr
