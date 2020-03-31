#beq, bne, lw, sw, j, jr
	addi $t0, $zero, 2
	addi $t1, $zero, 5
	
	add $t2, $t0, $t1 #t1 + t0 = 7
	sub $t2, $t1, $t0 #t1 - t0 = 3
	or $t2, $t1, $t0 # debe de dar 7
	sll $t2, $t1, 2 # debe de dar 20, o 14h
	srl $t2, $t1, 2 # debe de dar 1
	and $t2, $t1, $t0 # debe de dar 0
	lui $t3, 8
	
	j test1
	addi $t1, $zero, 3
	
test1:
	sw $t1, 8($sp)
	addi $t1, $t1, -1
	lw $t1, 8($sp)
	jal branch
	addi $t0, $t0, 1
	j exit

branch:
	addi $t0, $zero, 1
	addi $t1, $zero, 1
	beq $t0, $t1, iguales #salta
	addi $t0, $zero, 9  # no deberia de ejecutarse
	
iguales:
	addi $t0, $zero, 8
	bne $t1, $t0, regreso #salta
	 addi $t1, $zero, 4  # no deberia de ejecutarse
	
regreso:
	jr $ra
	
exit: