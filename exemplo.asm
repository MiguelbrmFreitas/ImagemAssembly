.data
filename: .asciiz "lena.bmp" #file name
uimsgop: .asciiz "(1) Carregar imagem de arquivo\n(2) Eliminar componente R (vermelho)\n(3) Eliminar componente G (verde)\n(4) Eliminar componente B (azul)\n"
uimsgout: .asciiz "(5) Finalizar programa"

.text
main:

li $s1, 0x10040000
move $s2, $s1
li $s3, 262144
li $s4, 0x10010100
b ui

ui:
li $v0,4
la $a0,uimsgop
syscall

li $v0,5
syscall

li $t0, 1
beq $v0, $t0,abreArquivo
li $t0, 2
beq $v0, $t0,ui
li $t0, 3
beq $v0, $t0, ui
li $t0, 4
beq $v0, $t0, exit
b ui


abreArquivo:

li $v0, 13           #open a file
li $a1, 0            # file flag (read)
la $a0, filename         # load file name
add $a2, $zero, $zero    # file mode (unused)
syscall

move $s0, $v0
#b ui

leitura:
	move $a0, $s0        # load file descriptor
	li $v0, 14           #read from file
	la $a1, ($s4)     # allocate space for the bytes loaded
	li $a2, 3         # number of bytes to be read
	syscall 
	li $v0, 9                    #heap allocation
	li $a0, 4
	syscall
	lw $s5,($s4)
	sw $s5,($s1)
	addi $s1, $s1, 4
	addi $s3, $s3, -1	
	bnez $s3, leitura
	
	b ui

exit:
