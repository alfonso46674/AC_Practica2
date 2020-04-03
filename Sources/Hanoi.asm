#Author: Juan Pablo Ramos Robles & Alfonso Ramirez Castro
#Date: 21/02/2020
#MIPS: add, addi, sub, or, ori, and,andi, nor, srl, sll, lw, sw, beq, bne, j, jal y jr.


.data

.text
Main:
	addi $sp, $zero, 0x10010000
	addi $t1, $zero, 9
	sw $t1, 0($sp)
	addi $t1, $t1, -1
	lw $t1, 0($sp)
	addi $t8, $t1,2
	
	addi $s0, $zero, 3	#Number of disks
	add $t0, $zero, $s0 	#Store the number of disks in a temporal location
	jal TowerLocation	#Jumps to TowerLocation; this function helps to create the addresses of each tower 
	addi $t1, $zero, 6
	jal StoreDisks	    #Initialize first tower with the respective number of disks
	
	#Save the locations of each tower in temporal registers
	addi $t0, $a0, 0
	addi $t1, $a1, 0
	addi $t2, $a2, 0
	#Save the number of disks in the next temporal register
	addi $t3, $s0, 0
	
	jal Hanoi #Jumps to the Hanoi function
	
	j Exit 
	
	
TowerLocation:
	addi $t7, $zero, 12 
	addi $a0, $zero,  0x10010000 #0x00000000    #Reference to first tower; tp_1 -> tower_pointer_1
	addi $a1, $zero,  0x10010020 #0x00000010 #    #Reference to second tower; tp_2
	addi $a2, $zero,  0x10010040 #0x00000020    #Reference to third tower; tp_3
	add $sp, $a0, 0			#Set sp at the top of the first tower
	jr $ra 				#return to main
	
	
StoreDisks:
	beq $t0, $zero, StoreDisks_Finish  #When the number of disks drops to zero, jump to StoreDisks_Finish
	sw $t0, 0($a0)  	#Save in the first address of the first tower the current number of disks  			
	sub $t0, $t0, 1 	#Decrements the current number of disks
	addi $a0, $a0, 4 	#Move to the next address of the first tower
	j StoreDisks 		#Jump back to StoreDisks
		
StoreDisks_Finish:
	jr $ra	#Jump back to main 		


Hanoi:
	beq $t3, 1, FinalCase #If the current number of disks = 1, jump to FinalCase
	sw $t3, 0($sp)		#Store in sp the current disk
	sw $ra, -4($sp)		#Save $ra
	
	sub $t3, $t3, 1		#Decrement the current amount of disks
	
	#Do a swap between the location of the second tower and third tower
	
	addi $t4, $t1, 0	#Save the location of the second tower in an temporal location	
	addi $t1, $t2, 0	#Save the location of the third tower in t1 (second tower)
	addi $t2, $t4, 0	#Save the location of the second tower (that is saved in a temnporal location) in the third tower   
	sub $sp, $sp, 8		#Decrement sp by 8; PUSH
	jal Hanoi	#Jump to Hanoi after swap
	
	lw $t3, 0($sp) #Load the disk saved in sp in t3
	lw $ra, -4($sp) #Load in ra the address in sp
	
	#Do a swap between second and third tower again 
	addi $t4, $t1, 0 #temporal = second tower
	addi $t1, $t2, 0 #second tower = third tower
	addi $t2, $t4, 0 #third tower = temporal
	
	
	#Move disk at the top of the first tower to the third tower
	addi $t0, $t0, -4 #Decrease tp_1 in order to get the current top disk
	sw $zero, 0($t0) #Delete the disk from first tower
	sw $t3, 0($t2)  #Move current disk to third tower
	addi $t2, $t2, 4 #Increment tp_3 in order to be located at the current top disk																																																																						
	sub $t3, $t3, 1 #Decrease number of disks
																																																													
	#Do a swap between the first and second tower
	addi $t4, $t1, 0 #temporal = second tower
	addi $t1, $t0, 0 #second tower = first tower
	addi $t0, $t4, 0 #second tower = temporal
	sub $sp, $sp, 8 #Decrement sp 
	jal Hanoi
	
	lw $t3, 0($sp) #Load the disk saved in sp in t3
	lw $ra, -4($sp) #Load in ra the address in sp
	
	 	 																																																												 																																																											
	 #Undo the swap between the first and second tower	 																																																												 																																																											 	 																																																												 																																																											 	 																																																												 																																																											
	addi $t4, $t1, 0 #temporal = first tower
	addi $t1, $t0, 0 #first = second tower
	addi $t0, $t4, 0 # second tower = temporal 	
	
	addi $sp, $sp, 8 #Increment sp; POP
	jr $ra      	#Jump to return address																																																																																																																																																																																		
																																																																																																																																																							
FinalCase:		
	#if n = 1, move the disk from the first tower to the third tower
	sub $t0, $t0, 4  #Move tp_1 to the top disk in the first tower
	sw $zero, 0($t0) #Delete the value from the tower
	sw $t3, 0($t2) 	 #Insert the disk (n = 1) in the third tower
	addi $t2, $t2, 4 #Increment the tp_3 
	addi $sp, $sp, 8 #Increment sp
	jr $ra		#Jump to return address 
								
								
Exit:	
