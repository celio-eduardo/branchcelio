.data
# Buffer do nome e da leitura de arquivo
filename: .space 100              # Espaço para o nome do arquivo
buffer:   .space 1024             # Buffer para leitura do arquivo

# Seção atual (.data ou .text)
# Não identificada -> 0
# .data -> 1
# .text -> 2

# $s0 tem o endereço da memória atual
current_section: .byte 0

# Constantes

newline:  .asciiz "\n"
prompt_entrada: .asciiz "Digite o nome do arquivo (.asm): "
erro_arquivo: .asciiz "Erro ao abrir o arquivo\n"
sucesso_arquivo: .asciiz "Arquivo aberto com sucesso\n"
invalid_instruction_error: .asciiz "Invalid instruction detected. Exiting."

# Constante de directivas do Parser

_data_token: .asciiz ".data\n"
_text_token: .asciiz ".text\n"

_word_token: .asciiz ".word"
_asciiz_token: .asciiz ".asciiz"
_byte_token: .asciiz ".byte"
_ascii_token: .asciiz ".ascii"
_half_token: .asciiz ".half"
_space_token: .asciiz ".space"

# Lista de instruções válidas
instructions: .asciiz "add\0sub\0and\0or\0xor\0nor\0slt\0lw\0sw\0beq\0bne\0addi\0andi\0ori\0xori\0"

.text
.globl main
main:
    # Solicita o nome do arquivo ao usuário
    li $v0, 4                     # syscall para imprimir string
    la $a0, prompt_entrada	  # prompt_entrada
    syscall

    li $v0, 8                     # syscall para leitura de string
    la $a0, filename
    li $a1, 100                   # tamanho máximo da string
    syscall

    # Remove o caractere de nova linha (\n) do final da string
    # remove_newline(), um strip
    jal remove_newline
    
open_file:
    # Abre o arquivo para leitura
    li $v0, 13                    # syscall para abrir arquivo
    la $a0, filename
    li $a1, 0                     # modo de leitura (0 = read)
    li $a2, 0                     # flags (0 = padrão)
    syscall
    move $s0, $v0                 # file descriptor
    
    bltz $v0, erro_abrir_arquivo
    add $s0, $v0, $zero
    
    # Lê e analisa o conteúdo do arquivo
read_file:
    li $v0, 14                    # syscall para ler arquivo
    move $a0, $s0                 # file descriptor
    la $a1, buffer
    li $a2, 1024                  # tamanho do buffer
    syscall
    # Coloca em $v0 -> -1 se o read não deu certo
    beq $v0, -1, erro_abrir_arquivo # se retornar -1, fim da leitura

    # Processa as linhas do buffer
    la $t0, buffer

process_lines: # Recebe o char em $t0
    lb $t1, 0($t0)
    beq $t1, 0, read_file         # Fim do buffer, leia mais
    beq $t1, '#', skip_line       # Ignora linhas de comentário
    beq $t1, '\n', next_line      # Ignora linhas em branco
    
    # Identifica se as partes são .data ou .text
    beq $t1, '.', identifica_parte
    
    # Isola a instrução
    la $a0, ($t0)
    jal isolate_instruction

    # Verifica se a instrução é válida
    la $a0, instructions
    jal validate_instruction
    beq $v0, 0, invalid_instruction

    # Identifica o tipo de instrução e analisa campos
    move $a0, $v0
    jal analyze_instruction

    # Gera o valor hexadecimal e escreve no arquivo
    jal generate_hex
    jal write_hex_file

next_line:
    addi $t0, $t0, 1
    j process_lines

skip_line:
    # Pula até o final da linha de comentário
    lb $t1, 0($t0)
    beq $t1, '\n', next_line
    addi $t0, $t0, 1
    j skip_line

invalid_instruction:
    # Lança exceção de instrução inexistente e descarta arquivo
    li $v0, 4                     # syscall para imprimir string
    la $a0, invalid_instruction_error # Printa "Invalid instruction detected. Exiting."
    syscall
    j close_file

close_file:
    # Fecha o arquivo
    li $v0, 16                    # syscall para fechar arquivo
    move $a0, $s0                 # file descriptor
    syscall

    # Finaliza o programa
    li $v0, 10                    # syscall para encerrar programa
    syscall

# Função para isolar a instrução da linha
isolate_instruction:
    # Implementar a lógica para isolar a instrução
    jr $ra

# Função para validar a instrução
validate_instruction: # validate_instruction($a0 [endereço das instruções])
    # Implementar a lógica para validar a instrução
    
    jr $ra

# Função para analisar a instrução e seus campos
analyze_instruction:
    # Implementar a lógica para analisar os campos da instrução
    jr $ra

# Função para gerar o valor hexadecimal da instrução
generate_hex:
    # Implementar a lógica para gerar o valor hexadecimal
    jr $ra

# Função para escrever o valor hexadecimal no arquivo
write_hex_file:
    # Implementar a lógica para escrever no arquivo
    jr $ra

# Erro é acionado ao não conseguir abrir o arquivo

erro_abrir_arquivo:
    li $v0, 4
    la $a0, erro_arquivo # print que deu erro em abrir
    j close_file # vai para a rotina de fechar o arquivo
    
remove_newline:
    la $t0, filename
    add $t1, $zero, $zero
_remove_newline_loop:
    # loop para remover o caractere de \n
    lb $t2, 0($t0)
    beq $t2, '\n', found_newline
    beq $t2, 0, found_newline
    addi $t0, $t0, 1
    j _remove_newline_loop
found_newline:
    sb $t1, 0($t0)
    jr $ra
    
# Função para identificar a parte do texto
# Seja .text ou .data
identifica_parte: # $t0 é o ponteiro para '.'; $t1 está com '.'
    lb $t1, 1($t0) # $t1 está com o primeiro char depois de '.'
    la $t2, _data_token 
    lb $t3, 1($t2)	# $t3 = 'd'
    beq $t1, $t3, _possivel_data_parte # verifica se '.d' é o que tem
    
    la $t2, _text_token
    lb $t3, 1($t2)	# $t3 = 't'
    beq $t1, $t3, _possivel_text_parte
    
    j parte_nao_identificada # se não for nenhuma das duas -> parte não identificada

_possivel_data_parte:
    addi $t0, $t0, 2  # adiciona 2 para pular os dois primeiros char's
    addi $t2, $t2, 2
    
    add $a0, $t0, $zero #vamos comparar $t0 com $t2, utilizando a função auxiliar
    add $a1, $t2, $zero
    addi $a2, $zero, 4 # compara os 4 dígitos 'ata\n' no caso
    # aloca para a0 e a1 os endereços;
    # aloca para a2 o tamanho que queremos comparar    
    jal compara_str

    beqz $v0, invalid_instruction # se o retorno der 0 -> é uma instrução inválida
    
    # Passou na verificação, adiciona ao $t0 para continuar lendo o arquivo
    
    addi $t0, $t0, 4 # vai para a próxima linha do código
    
    la $t2, current_section
    addi $t3, $zero, 1 # determina e atualiza a atual seção de código -> seção de dado
    sb $t3, ($t2)
    
    ############################# Decisão de Projeto -> colocar em $s0 o atual endereço 0x00000000
    
    add $s0, $zero, $zero
    
    j process_lines # volta ao process_lines com o $t0 já alterado

_possivel_text_parte:
    addi $t0, $t0, 2  # adiciona 2 para pular os dois primeiros char's
    addi $t2, $t2, 2
    
    add $a0, $t0, $zero #vamos comparar $t0 com $t2, utilizando a função auxiliar
    add $a1, $t2, $zero
    addi $a2, $zero, 4 # compara os 4 dígitos 'ext\n' no caso
    # aloca para a0 e a1 os endereços;
    # aloca para a2 o tamanho que queremos comparar    
    jal compara_str
                   # 'ext\n' comparando
    beqz $v0, invalid_instruction # se o retorno der 0 -> é uma instrução inválida
    
    # Passou na verificação, adiciona ao $t0 para continuar lendo o arquivo
    
    addi $t0, $t0, 4 # vai para a próxima linha do código, pois passa o \n
    
    la $t2, current_section
    addi $t3, $zero, 2 # determina e atualiza a atual seção de código -> seção de texto
    sb $t3, ($t2)
    
    ############################# Decisão de Projeto -> colocar em $s0 o atual endereço 0x00000000
    
    add $s0, $zero, $zero
    
    j process_lines # volta ao process_lines com o $t0 já alterado

parte_nao_identificada:
    # Possibilidade de tipo de dado
    # SE E SOMENTE SE -> current_section == 1
    # SE FOR DIFERENTE -> A instrução é inválida, visto que não está em área de dados e é tipo de dado 
    # OU é .alguma coisa sem estar em .data ou .text
    la $t2, current_section
    lb $t3, 0($t2)
    bne $t3, 1, invalid_instruction
    
    #_word_token: .asciiz ".word"
_verifica_word_token:     # possível word_token
    la $t2, _word_token   # vamos utilizar a função auxiliar compara_str
    # $t0 está apontando para '.'
    # aloca para a0 e a1, o endereço das strings a serem comparadas
    add $a0, $t2, $zero
    add $a1, $t0, $zero
    # inicia o a2 com a qtd de byte a ser comparado
    addi $a2, $zero, 5
    jal compara_str
    beqz $v0, _verifica_ascii # vai para o próximo provável valor de '.'
    # e temos uma .word 
    addi $t0, $t0, 5
    lb $t1, 0($t0)
    bne $t1, ' ', invalid_instruction # verifica impreterivelmente se depois de .word tem um espaço 
_rotina_word_token:
    # $t0 está apontando atualmente para um ' ' e os próximos caracteres podem ser
    # ou não um ' ' 
    # Após reconhecer o tipo de dado, ler atá o final, saindo quando ver um \n
    # Viu \n registra
    # Viu ',' vai para o próximo endereço!!!!
    # $s0 tem o endereço da memória atual
    addi $t0, $t0, 1
    lb $t1, 0($t0)
    
    beq $t1, ' ', _rotina_word_token
    beq $t1, ',', _rotina_virgula_word_token
    beq $t1, '\n', process_lines
    
    
    
_rotina_virgula_word_token:
    # ainda não
    j process_lines
_verifica_ascii:

# ainda não
    la $t2, _ascii_token
    lb $t3, 1($t2)
    j process_lines
    
    #_asciiz_token: .asciiz ".asciiz"
    #_byte_token: .asciiz ".byte"
    #_ascii_token: .asciiz ".ascii"
    #_half_token: .asciiz ".half"
    #_space_token: .asciiz ".space"
    
############################################################
# função auxiliar compara strings
# recebe a0, a1 -> endereço das strings a serem comparadas
# recebe a2 -> tamanho a ser comparado 
# retorna v0 -> 1 se iguais; 0 se desiguais
############################################################

compara_str:
    beqz $a2, fim_igual_compara_str	# while n:
    lb $t4, 0($a0)				# compara '' com ''
    lb $t5, 0($a1)
    bne $t4, $t5, fim_desigual_compara_str # se não for igual, já termina
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    addi $a2, $a2, -1 # se for igual continua
    j compara_str

fim_desigual_compara_str:
    add $v0, $zero, $zero
    jr $ra
fim_igual_compara_str:
    addi $v0, $zero, 1
    jr $ra