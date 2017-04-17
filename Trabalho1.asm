#	Miguel Barreto Rezende Marques de Freitas
#	12/0130424
#	Trabalho 01
#	Carregar uma imagem RGB da Lena no display do MARS e conseguir tirar os componentes de cores


.data	# Declaração de variáveis e constantes

#	heap:		.word 0x10040000

buffer:		.space 3	# Buffer para guardar as componentes de um pixel do arquivo

arq:		.asciiz "lena.bmp"
msg_menu:	.asciiz "\n1) Ler o arquivo e carregar imagem\n2) Eliminar a componente vermelha\n3) Eliminar a componente verde\n4) Eliminar a componente azul\n5) Encerrar programa\n"
msg_opcao:	.asciiz "Escolha sua opcao: "
msg_nomearq:	.asciiz "\nTentando ler o arquivo 'lena.bmp'..."
num_invalido:	.asciiz "\n\nEscolha um número inteiro entre 1 e 5\n\n"
file_error:	.asciiz "\n\nArquivo nao encontrado! Se certifique que o arquivo 'lena.bmp' está na mesma pasta e tente novamente!\n"
confirmacao:	.asciiz "\n\nLeitura feita com sucesso\n\n"
img:		.asciiz "Imagem exibida com sucesso!\n\n"
tchau:		.asciiz "\n\nObrigado por usar, volte sempre!\n\n"



.text	# O programa começa aqui
	
main:		jal menu		# Abre o menu
		ble $v0, $zero, invalido	# Informa o usuário que o valor é inválido e abre o menu novamente
		add $a0, $zero, $v0	# Passa o resultado da subrotina menu para o registrador $a0, que será argumento da subrotina switch
		jal switch
		j   main		# Abre o menu novamente depois de executar a opção escolhida

menu:		la $a0, msg_menu	# Coloca a mensagem no registrador $a0
		li $v0, 4		# Código para o syscall de print string
		syscall
		
		la $a0, msg_opcao	# Coloca a mensagem no registrador $a0
		syscall
		
		li $v0, 5		# Código para o syscall de read integer
		syscall
		
		jr $ra
		
switch:		li $t0, 1		# Coloca 1 no registrador $t0
		beq $t0, $a0, abre_arq	# Pula para abre_arq se $a0 = 1
		
		li $t0, 2		# Coloca 2 no registrador $t0
		beq $t0, $a0, R		# Vai para o label R, que é pra quando se quer zerar a componente Red
		
		li $t0, 3		# Coloca 3 no registrador $t0
		beq $t0, $a0, G		# Vai para o label G, que é pra quando se quer zerar a componente Green
		
		li $t0, 4		# Coloca 4 no registrador $t0
		beq $t0, $a0, B		# Vai para o label B, que é pra quando se quer zerar a componente Blue
		
		li $t0, 5		# Coloca 5 no registrador $t0
		beq $t0, $a0, encerra	# Pula para encerra se $a0 = 5
		
		invalido:		# Pro caso da opção não ser válida
			la $a0, num_invalido	# Coloca a mensagem de aviso no registrador $a0
			li $v0, 4		# Código para o syscall de print string
			syscall
		
			j main			# Inicia novamente o menu, pois não foi dada uma opção válida
		
		# Vai para a função elimina, com o argumento em $a0 representando
		# a máscara para zerar a componente em questão através de um AND
		
		R:	li $a0, 0x0000ffff	# Máscara para zerar a componente Red através de um AND 
			j elimina		
		G:	li $a0, 0x00ff00ff	# Máscara para zerar a componente Green através de um AND  
			j elimina		
		B:	li $a0, 0x00ffff00	# Máscara para zerar a componente Blue através de um AND 
			j elimina		
			
erro:		la $a0, file_error	# Coloca a mensagem no registrador $a0
		li $v0, 4		# Código para o syscall de print string
		syscall
		
		j encerra

abre_arq:	la $a0, msg_nomearq	# Coloca a mensagem no registrador $a0
		li $v0, 4		# Código para o syscall de print string
		syscall
		
		la $a0, arq		# Endereço de onde começa a string do nome do arquivo a ser lido
		li $a1, 0		# Flag para abrir como read only
		li $a2, 0		# Ignorado neste caso
		li $v0, 13		# Código para abrir um arquivo
		syscall	
		
		add $s0, $zero, $v0	# Salva o file descriptor
		
		blt $s0, $zero, erro	# Vai para a mensagem de erro caso o arquivo dê erro de leitura ou não exista
		
		la $a0, confirmacao	# Coloca a mensagem no registrador $a0
		li $v0, 4		# Código para o syscall de print string
		syscall
# Continua a execução para load_img
		
load_img:	addi $s3, $zero, 262144	# Guarda em s3 o numero de pixels da imagem 512x512 para fazer um contador regressivo
		la $s2, 0x10040000	# Guarda o endereço base da heap
		la $s1, buffer		# Guarda o endereço base do buffer
		
		# Configurações de leitura
		add $a0, $zero, $s0	# Carrega o file descriptor
		la $a1, ($s1)		# Endereço de memória onde a leitura vai ser carregada
		li $a2, 3		# Tamanho do bloco a ser lido
		
		loop:	li $v0, 14		# Código para ler um arquivo
			syscall			# A leitura será feita várias vezes, para cada pixel de 3 bytes
			
			lb $t1, 2($s1)		# Red
			lb $t2, 1($s1)		# Green
			lb $t3, ($s1)		# Blue
				
			sll $t1, $t1, 16	# Coloca o componente red entre 16:24	
			sll $t2, $t2, 8		# Coloca o componente Green entre 8:16
			
			add $t4, $t2, $t1	# Junta os componentes R e G
			add $t4, $t4, $t3	# Junta o componente B, formando o registrador com as informações RGB
		
			sw $t4, ($s2) 		# Carrega o pixel na heap do MARS
			
			addi $s2, $s2, 4 	# Avança 4 bytes na heap para o próximo pixel
			addi $s3, $s3, -1 	# Decresce o contador regressivo
		
			bne $s3, $zero, loop	# Repete o loop enquanto o contador não chega a 0
			
		la $a0, img		# Coloca a mensagem no registrador $a0
		li $v0, 4		# Código para o syscall de print string
		syscall
		
		add $a0, $s0, $zero	# Carrega o file descriptor
		li $v0, 16		# Código para fechar o arquivo
		syscall	
		
		
		jr $ra			# Volta para a main de onde parou


elimina:	addi $s3, $zero, 262144	# Guarda em s3 o numero de pixels da imagem 512x512 para fazer um contador regressivo
		la $s2, 0x10040000	# Guarda o endereço base da heap

		loop_B:	lw $t5, ($s2)
			and $t5, $t5, $a0	# Zera a componente em questão
			
			sw $t5, ($s2)			# Carrega de novo na heap o pixel com a componente de cor zerada
			
			addi $s3, $s3, -1		# Decresce o contador regressivo
			addi $s2, $s2, 4		# Avança 4 bytes para o próximo pixel na heap
			
			bne $s3, $zero, loop_B	# Repete o loop enquanto o contador não chega a 0
			
		jr $ra


encerra:	li $v0, 4		# Código de print string
		la $a0, tchau		# Mensagem de despedida
		syscall	

		li $v0, 10		# Carrega o codigo de saida em v0
		syscall			# Encerra o programa
		
	
	
		
