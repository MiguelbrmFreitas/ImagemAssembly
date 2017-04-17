.data
menu:		.asciiz "Menu:\n1. Load File\n2. Invert Component\n3. Nullify Component\n4. Invert Colors\n5. Apply Grayscale\n6. Reset Bitmap\n7. Quit\n"
menu_prompt:	.asciiz "Your Option(1-7):"
error_menu:	.asciiz "Invalid menu option. Please try again."
data_error:	.asciiz "Data error or no data written. Please try again."
end_prog:	.asciiz "End of program. Thanks for using it!"
def_X:		.word 512
def_Y:		.word 512

.text
.globl _start

_start:
	li $v0,9
	li $a0,1048576
	syscall
	move $s0,$v0
	lw $s1,def_X
	lw $s2,def_Y
menu_loop:
	li $v0,4
	la $a0,menu
	syscall
	
	la $a0,menu_prompt
	la $a1,error_menu
	li $a2,1
	li $a3,7
	jal read_int
	
	beq $v0,7,menu_exit
	
	move $a0,$s0
	move $a1,$s1
	move $a2,$s2

	bne $v0,1,not_load
	jal load_file
	move $s1,$v0
	move $s2,$v1
	j menu_loop
not_load:
	bne $v0,2,not_cinv
	jal invert_component_option
	j menu_loop
not_cinv:
	bne $v0,3,not_cnul
	jal nullify_component_option
	j menu_loop
not_cnul:
	bne $v0,4,not_invcol
	jal invert_all_color
	j menu_loop
not_invcol:
	bne $v0,5,is_reset_col
	jal apply_grayscale_option
	j menu_loop
is_reset_col:
	jal reset_bitmap
	j menu_loop
menu_exit:
	li $v0,55
	la $a0,end_prog
	li $a1,100
	syscall
	li $v0,10
	syscall

#####################################################################################################################################
# nonwln()
# $a0: String
nonwln:
	addi $sp,$sp,-12
	sw $ra,8($sp)
	sw $t1,4($sp)
	sw $t0,0($sp)
	
	move $t0,$a0

noloop:
	lbu $t2,0($t0)
	beqz $t2,endnoloop
	bne $t2,10,next_it
	sb $zero,0($t0)
next_it:
	addi $t0,$t0,1
	j noloop
endnoloop:
	lw $t0,0($sp)
	lw $t1,4($sp)
	lw $ra,8($sp)
	addi $sp,$sp,12
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# str8toi()
# $a0: String
# $v0: Integer
str8toi:
	addi $sp,$sp,-20
	sw $ra,16($sp)
	sw $t3,12($sp)
	sw $t2,8($sp)
	sw $t1,4($sp)
	sw $t0,0($sp)
	
	move $t0,$a0
	li $t1,0
	li $v0,0
strloop:
	beq $t1,8,endconvert
	
	lbu $t2,0($t0)
	subiu $t2,$t2,48
	blt $t2,10,notletter
	subiu $t2,$t2,7
notletter:
	li $t3,8
	subu $t3,$t3,$t1
	addi $t3,$t3,-1
	sll $t3,$t3,2
	sllv $t2,$t2,$t3
	add $v0,$v0,$t2
	
	addi $t1,$t1,1
	addi $t0,$t0,1
	j strloop
endconvert:
	lw $t0,0($sp)
	lw $t1,4($sp)
	lw $t2,8($sp)
	lw $t3,12($sp)
	lw $ra,16($sp)
	addi $sp,$sp,20
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# load_file()
# $a0: Bitmap address
# $v0: Width (X)
# $v1: Height (Y)
.data
file_prompt:	.asciiz "Enter the name of the txt file (with extension .txt):"
file_error:	.asciiz "File not found."
str_error:	.asciiz "Invalid input. Please try again."
file_end:	.asciiz "File loaded."
w_prompt:	.asciiz "Width (1-512):"
h_prompt:	.asciiz "Height (1-512):"
dim_error:	.asciiz "Invalid size value."
file_name:	.space 80
int_str:	.space 8
rn_trash:	.space 2
.text
load_file:
	addi $sp,$sp,-40
	sw $ra,0($sp)
	sw $a0,4($sp)
	sw $t0,8($sp)
	sw $t1,12($sp)
	sw $t2,16($sp)
	sw $t3,20($sp)
	sw $t4,24($sp)
	sw $t5,28($sp)
	sw $t6,32($sp)
	sw $t7,36($sp)
	move $t0,$a0
readfile_loop:
	li $v0,54
	la $a0,file_prompt
	la $a1,file_name
	li $a2,80
	syscall
	beqz $a1,attempt_openfile
	li $v0,55
	la $a0,str_error
	andi $a1,0
	syscall
	j readfile_loop

attempt_openfile:
	li $v0,13
	la $a0,file_name
	jal nonwln
	andi $a1,0
	andi $a2,0
	syscall
	bgtz $v0,file_opened
	li $v0,55
	la $a0,file_error
	andi $a1,0
	syscall
	j load_end
file_opened:
	move $t1,$v0
	
	la $a0,w_prompt
	la $a1,dim_error
	li $a2,1
	li $a3,512
	jal read_int
	move $t2,$v0
	
	la $a0,h_prompt
	la $a1,dim_error
	li $a2,1
	li $a3,512
	jal read_int
	move $t3,$v0

	andi $t4,0
readYloop:
	beq $t4,$t3,end_read_loop
	andi $t5,0
readXloop:
	beq $t5,$t2,endXread
	
	li $v0,14
	move $a0,$t1
	la $a1,int_str
	li $a2,8
	syscall
	bne $v0,8,end_read_loop
	li $v0,14
	move $a0,$t1
	la $a1,rn_trash
	li $a2,2
	syscall
	
	sll $t6,$t5,2
	sll $t7,$t4,11
	add $t7,$t7,$t6
	add $t7,$t7,$t0
	la $a0,int_str
	jal str8toi
	sw $v0,0($t7)
	
	addi $t5,$t5,1
	j readXloop
endXread:
	addi $t4,$t4,1
	j readYloop	
end_read_loop:
	li $v0,16
	move $a0,$t1
	syscall
	li $v0,55
	la $a0,file_end
	li $a1,1
	syscall
	move $v0,$t2
	move $v1,$t3	
load_end:	
	lw $ra,0($sp)
	lw $a0,4($sp)
	lw $t0,8($sp)
	lw $t1,12($sp)
	lw $t2,16($sp)
	lw $t3,20($sp)
	lw $t4,24($sp)
	lw $t5,28($sp)
	lw $t6,32($sp)
	lw $t7,36($sp)
	addi $sp,$sp,40
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# nullify_component_option()
# $a0: Bitmap address
# $a1: width (X)
# $a2: height (Y)
.data
nulc_prompt:	.asciiz "Select component to nullify (1-Red, 2-Green, 3-Blue):"
nulc_error:	.asciiz "Invalid component option. Please try again."
nulc_endmsg:	.asciiz "Selected component nullified."
.text
nullify_component_option:
	addi $sp,$sp,-48
	sw $ra,0($sp)
	sw $a0,4($sp)
	sw $a1,8($sp)
	sw $a2,12($sp)
	sw $t0,16($sp)
	sw $t1,20($sp)
	sw $t2,24($sp)
	sw $t3,28($sp)
	sw $t4,32($sp)
	sw $t5,36($sp)
	sw $t6,40($sp)
	sw $t7,44($sp)
	
	move $t0,$a0
	move $t1,$a1
	move $t2,$a2
	
	la $a0,nulc_prompt
	la $a1,nulc_error
	li $a2,1
	li $a3,3
	jal read_int
	move $t3,$v0
	li $t4,0
nulc_loop:
	beq $t4,$t2,nulc_end
	li $t5,0
nulcXloop:
	beq $t5,$t1,nulcXend
	
	sll $t6,$t5,2
	sll $t7,$t4,11
	add $t7,$t7,$t6
	add $t7,$t7,$t0
	
	lw $a0,0($t7)
	addi $a1,$t3,-1
	jal nul_pixel_comp
	sw $v0,0($t7)
	addi $t5,$t5,1
	j nulcXloop
nulcXend:
	addi $t4,$t4,1
	j nulc_loop
nulc_end:
	li $v0,55
	la $a0,nulc_endmsg
	li $a1,1
	syscall
	lw $ra,0($sp)
	lw $a0,4($sp)
	lw $a1,8($sp)
	lw $a2,12($sp)
	lw $t0,16($sp)
	lw $t1,20($sp)
	lw $t2,24($sp)
	lw $t3,28($sp)
	lw $t4,32($sp)
	lw $t5,36($sp)
	lw $t6,40($sp)
	lw $t7,44($sp)
	addi $sp,$sp,48
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# nul_pixel_comp()
# $a0: pixel
# $a1: Component (0-Red, 1-Green, 2-Blue)
# $v0: nullified pixel
.data
nulc_mask:	.word 0xFF00FFFF,0xFFFF00FF,0xFFFFFF00
.text
nul_pixel_comp:
	addi $sp,$sp,-12
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)

	sll $t1,$a1,2
	la $t0,nulc_mask
	add $t0,$t0,$t1
	lw $t1,0($t0)
	
	and $v0,$a0,$t1
	
	lw $ra,0($sp)
	lw $t0,4($sp)
	lw $t1,8($sp)
	addi $sp,$sp,12
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# invert_component_option()
# $a0: Bitmap address
# $a1: width (X)
# $a2: height (Y)
.data
invc_prompt:	.asciiz "Select component to invert (1-Red, 2-Green, 3-Blue):"
invc_error:	.asciiz "Invalid component option. Please try again."
invc_endmsg:	.asciiz "Selected component inverted."
.text
invert_component_option:
	addi $sp,$sp,-48
	sw $ra,0($sp)
	sw $a0,4($sp)
	sw $a1,8($sp)
	sw $a2,12($sp)
	sw $t0,16($sp)
	sw $t1,20($sp)
	sw $t2,24($sp)
	sw $t3,28($sp)
	sw $t4,32($sp)
	sw $t5,36($sp)
	sw $t6,40($sp)
	sw $t7,44($sp)
	
	move $t0,$a0
	move $t1,$a1
	move $t2,$a2
	
	la $a0,invc_prompt
	la $a1,invc_error
	li $a2,1
	li $a3,3
	jal read_int
	move $t3,$v0
	li $t4,0
invc_loop:
	beq $t4,$t2,invc_end
	li $t5,0
invcXloop:
	beq $t5,$t1,invcXend
	
	sll $t6,$t5,2
	sll $t7,$t4,11
	add $t7,$t7,$t6
	add $t7,$t7,$t0
	
	lw $a0,0($t7)
	addi $a1,$t3,-1
	jal inv_pixel_comp
	sw $v0,0($t7)

	addi $t5,$t5,1
	j invcXloop
invcXend:
	addi $t4,$t4,1
	j invc_loop
invc_end:
	li $v0,55
	la $a0,invc_endmsg
	li $a1,1
	syscall
	lw $ra,0($sp)
	lw $a0,4($sp)
	lw $a1,8($sp)
	lw $a2,12($sp)
	lw $t0,16($sp)
	lw $t1,20($sp)
	lw $t2,24($sp)
	lw $t3,28($sp)
	lw $t4,32($sp)
	lw $t5,36($sp)
	lw $t6,40($sp)
	lw $t7,44($sp)
	addi $sp,$sp,48
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# inv_pixel_comp()
# $a0: pixel
# $a1: Component (0-Red, 1-Green, 2-Blue)
# $v0: inverted pixel
.data
invc_mask:	.word 0x00FF0000,0x0000FF00,0x000000FF
.text
inv_pixel_comp:
	addi $sp,$sp,-12
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)

	sll $t1,$a1,2
	la $t0,invc_mask
	add $t0,$t0,$t1
	lw $t1,0($t0)
	
	xor $v0,$a0,$t1
	
	lw $ra,0($sp)
	lw $t0,4($sp)
	lw $t1,8($sp)
	addi $sp,$sp,12
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# apply_grayscale_option()
# $a0: Bitmap address
# $a1: width (X)
# $a2: height (Y)
.data
gray_menu:	.asciiz "Grayscales:\n1 - Normal\n2 - Average\n3 - Luminosity\n4 - Lightness\n"
gray_prompt:	.asciiz "Enter your grayscale option (1-4):"
gray_error:	.asciiz "Invalid grayscale option. Please try again."
gray_endmsg:	.asciiz "Grayscale applied."
.text
apply_grayscale_option:
	addi $sp,$sp,-48
	sw $ra,0($sp)
	sw $a0,4($sp)
	sw $a1,8($sp)
	sw $a2,12($sp)
	sw $t0,16($sp)
	sw $t1,20($sp)
	sw $t2,24($sp)
	sw $t3,28($sp)
	sw $t4,32($sp)
	sw $t5,36($sp)
	sw $t6,40($sp)
	sw $t7,44($sp)
	
	move $t0,$a0
	move $t1,$a1
	move $t2,$a2
	
	li $v0,4
	la $a0,gray_menu
	syscall
	
	la $a0,gray_prompt
	la $a1,gray_error
	li $a2,1
	li $a3,4
	jal read_int
	move $t3,$v0
	li $t4,0
gray_loop:
	beq $t4,$t2,gray_end
	li $t5,0
grayXloop:
	beq $t5,$t1,grayXend
	
	sll $t6,$t5,2
	sll $t7,$t4,11
	add $t7,$t7,$t6
	add $t7,$t7,$t0
	
	lw $a0,0($t7)
	addi $a1,$t3,-1
	jal pixel_gray
	sw $v0,0($t7)
	
	addi $t5,$t5,1
	j grayXloop
grayXend:
	addi $t4,$t4,1
	j gray_loop
gray_end:
	li $v0,55
	la $a0,gray_endmsg
	li $a1,1
	syscall
	lw $ra,0($sp)
	lw $a0,4($sp)
	lw $a1,8($sp)
	lw $a2,12($sp)
	lw $t0,16($sp)
	lw $t1,20($sp)
	lw $t2,24($sp)
	lw $t3,28($sp)
	lw $t4,32($sp)
	lw $t5,36($sp)
	lw $t6,40($sp)
	lw $t7,44($sp)
	addi $sp,$sp,48
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# pixel_gray()
# $a0: pixel
# $a1: type of gray scale (0-Normal, 1-Average, 2-Luminosity, 3-Lightness)
# $v0: gray pixel
.data
R_freq:		.word 30,1,21
G_freq:		.word 59,1,72
B_freq:		.word 11,1,7
a_freq:		.word 100,3,100
.text
pixel_gray:
	addi $sp,$sp,-28
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)
	sw $t2,12($sp)
	sw $t3,16($sp)
	sw $t4,20($sp)
	sw $t5,24($sp)
	
	andi $v0,0
	andi $t2,$a0,0xFF
	srl $t1,$a0,8
	andi $t1,0xFF
	srl $t0,$a0,16
	andi $t0,0xFF
	
	bge $a1,3,apply_lightness
	
	la $t3,R_freq
	sll $t4,$a1,2
	add $t3,$t3,$t4
	lw $t4,0($t3)
	mult $t0,$t4
	mflo $t3
	add $t5,$zero,$t3
	
	la $t3,G_freq
	sll $t4,$a1,2
	add $t3,$t3,$t4
	lw $t4,0($t3)
	mult $t1,$t4
	mflo $t3
	add $t5,$t5,$t3
	
	la $t3,B_freq
	sll $t4,$a1,2
	add $t3,$t3,$t4
	lw $t4,0($t3)
	mult $t2,$t4
	mflo $t3
	add $t5,$t5,$t3
	
	la $t3,a_freq
	sll $t4,$a1,2
	add $t3,$t3,$t4
	lw $t4,0($t3)
	div $t5,$t4
	mflo $t3
	j end_graypixels
apply_lightness:
	move $t3,$t0
	move $t4,$t0
	ble $t1,$t3,no_gt1
	move $t3,$t1
no_gt1:
	ble $t2,$t3,no_gt2
	move $t3,$t2
no_gt2:
	bge $t1,$t4,no_lt1
	move $t4,$t1
no_lt1:
	bge $t2,$t4,no_lt2
	move $t4,$t2
no_lt2:
	sub $t3,$t3,$t4
	srl $t3,$t3,1	
end_graypixels:
	add $v0,$v0,$t3
	sll $t3,$t3,8
	add $v0,$v0,$t3
	sll $t3,$t3,8
	add $v0,$v0,$t3
		
	lw $ra,0($sp)
	lw $t0,4($sp)
	lw $t1,8($sp)
	lw $t2,12($sp)
	lw $t3,16($sp)
	lw $t4,20($sp)
	lw $t5,24($sp)
	addi $sp,$sp,28
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# invert_all_color()
# $a0: bitmap address
# $a1: width (X)
# $a2: height (Y)
.data
inva_msg:	.asciiz "All components inverted."
.text
invert_all_color:
	addi $sp,$sp,-32
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)
	sw $t2,12($sp)
	sw $a0,16($sp)
	sw $t3,20($sp)
	sw $t4,24($sp)
	sw $t5,28($sp)
	move $t3,$a0
	li $t0,0
inva_loop:
	beq $t0,$a2,inva_end
	li $t1,0
invaXloop:
	beq $t1,$a1,invaXend
	
	sll $t4,$t1,2
	sll $t5,$t0,11
	add $t5,$t5,$t4
	add $t5,$t5,$t3
	
	lw $t2,0($t5)
	xori $t2,0x00FFFFFF
	sw $t2,0($t5)
	addi $t1,$t1,1
	j invaXloop
invaXend:
	addi $t0,$t0,1
	j inva_loop
inva_end:
	li $v0,55
	la $a0,inva_msg
	li $a1,1
	syscall
	lw $ra,0($sp)
	lw $t0,4($sp)
	lw $t1,8($sp)
	lw $t2,12($sp)
	lw $a0,16($sp)
	lw $t3,20($sp)
	lw $t4,24($sp)
	lw $t5,28($sp)
	addi $sp,$sp,32
	jr $ra
#####################################################################################################################################

#####################################################################################################################################
# reset_bitmap()
# $a0: bitmap address
.data
reset_msg:	.asciiz "Bitmap reset sucessfully."
.text
reset_bitmap:
	addi $sp,$sp,-16
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)
	sw $a0,12($sp)
	li $t0,0
resetXloop:
	beq $t0,512,reset_end
	li $t1,0
resetYloop:
	beq $t1,512,resetYend
	sw $zero,0($a0)
	addi $t1,$t1,1
	addi $a0,$a0,4
	j resetYloop
resetYend:
	addi $t0,$t0,1
	j resetXloop
reset_end:
	li $v0,55
	la $a0,reset_msg
	li $a1,1
	syscall
	lw $ra,0($sp)
	lw $t0,4($sp)
	lw $t1,8($sp)
	lw $a0,12($sp)
	addi $sp,$sp,16
	jr $ra
#####################################################################################################################################

#####################################################################################################################################	
# read_int()
# $a0: prompt
# $a1: error message
# $a2: lower integer
# $a3: upper integer
# $v0: Read integer data
read_int:
	addi $sp,$sp,-12
	sw $ra,0($sp)
	sw $t0,4($sp)
	sw $t1,8($sp)
	
	move $t0,$a0
	move $t1,$a1
read_int_loop:
	li $v0,51
	move $a0,$t0
	syscall
	blt $a0,$a2,int_trouble
	bgt $a0,$a3,int_trouble
	bnez $a1,read_data_error
	move $v0,$a0
	j end_readint_loop
int_trouble:
	li $v0,55
	move $a0,$t1
	andi $a1,$zero,0
	syscall
	j read_int_loop
read_data_error:
	li $v0,55
	la $a0,data_error
	andi $a1,$zero,0
	syscall
	j read_int_loop
end_readint_loop:
	lw $ra,0($sp)
	lw $t0,4($sp)
	lw $t1,8($sp)
	addi $sp,$sp,12
	jr $ra
#####################################################################################################################################
