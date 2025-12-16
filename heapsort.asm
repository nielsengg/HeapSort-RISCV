.text
.globl main

# ==============================================================================
# DEFINIÇÕES DE HARDWARE (Baseadas no top.v) ok
# ==============================================================================
.eqv IO_LEDS  0x104
.eqv IO_SW    0x120
.eqv ARRAY_SZ 10        # tamanho do array para ordenar (está no final deste código)

# ==============================================================================
# INÍCIO DO PROGRAMA ok
# ==============================================================================
main:
    # Configurar ponteiros de IO
    li s10, IO_LEDS     # s10 = Endereço dos LEDs
    li s11, IO_SW       # s11 = Endereço dos Switches

    # 2. Loop de espera até input (fica aqui até o usuário ligar o SW[0])
wait_start:
    lw  t0, 0(s11)      # Lê Switches
    andi t0, t0, 1      # verifica bit 0
    bnez t0, start_sort # Se SW[0] == 1, começa o start sort
    
    # Pisca LED 0
    sw  t1, 0(s10)
    li  t1, 0
    sw  t1, 0(s10)
    j   wait_start

# ==============================================================================
# CÓDIGO PRINCIPAL DE HEAPSORT ok
# ==============================================================================

# aqui temos apenas uma indicação de que o sort será iniciado
start_sort:
    # Acende todos os LEDs para indicar "Processando..."
    li t0, 1023
    sw t0, 0(s10)

    # Carrega endereço do array e tamanho
    la   a0, my_array   # a0 = endereço base do array
    li   a1, ARRAY_SZ   # a1 = n (tamanho)

    jal  heapsort       # Chama função de ordenação

    # ==========================================================================
    # MODO DE VISUALIZAÇÃo ok
    # Usa os Switches para escolher qual índice do vetor mostrar nos LEDs
    # ==========================================================================
display_loop:
    lw   t0, 0(s11)     # Lê Switches (Índice desejado)
    
    # Se índice >= Tamanho, força índice = Tamanho-1
    li   t1, ARRAY_SZ
    blt  t0, t1, read_mem
    addi t0, t1, -1     # Clamp no último elemento
    

read_mem:
    slli t0, t0, 2      # Multiplica índice por 4 por conta de word
    la   t2, my_array   # Base do array
    add  t2, t2, t0     # Endereço do elemento: Base + (Index*4)
    lw   t3, 0(t2)      # Lê o valor ordenado da memória
    
    sw   t3, 0(s10)     # Mostra nos LEDs
    j    display_loop   # Loop infinito

# ==============================================================================
# FUNÇÃO: HEAPSORT (a0 = array, a1 = n)
# ==============================================================================
heapsort:
    addi sp, sp, -4
    sw   ra, 0(sp)      # Salva endereço de retorno

    # 1. Build Max Heap
    # Começa do último nó não-folha, que é (n/2) - 1
    srli t0, a1, 1      # t0 = n / 2
    addi t0, t0, -1     # t0 = i = (n/2) - 1

build_loop:
# este organiza a árvore
    blt  t0, zero, sort_phase # Se i < 0, a árvore está montada e terminou o build
    
    # Prepara argumentos para heapify(arr, n, i)
    mv   a2, t0         # a2 = i

    addi sp, sp, -8
    sw   t0, 0(sp)      # Salva i atual
    sw   a1, 4(sp)      # Salva n
    jal  heapify 	# sift down
    lw   a1, 4(sp)
    lw   t0, 0(sp)
    addi sp, sp, 8
    
    addi t0, t0, -1     # vai até o nó pai
    j    build_loop

    # 2. Extrair elementos um por um
sort_phase:
    addi t0, a1, -1     # t0 = i = n - 1

extract_loop:
    ble  t0, zero, sort_done # Se i <= 0, terminou
    
    # Swap(arr[0], arr[i])
    slli t1, t0, 2      # Offset i
    add  t1, a0, t1     # &arr[i]
    lw   t2, 0(a0)      # carrega arr[0]
    lw   t3, 0(t1)      # carrega arr[i]
    sw   t3, 0(a0)      # arr[0] = arr[i]
    sw   t2, 0(t1)      # arr[i] = arr[0] (O maior vai pro final)

    # heapify(arr, i, 0)
    # Reduz tamanho do heap para 'i'
    mv   a1, t0         # n vira i (o tamanho reduzido)
    li   a2, 0          # raiz = 0
    
    addi sp, sp, -4      # abre espaço na fila
    sw   t0, 0(sp)      # Salva i do loop para não perder
    jal  heapify
    lw   t0, 0(sp)
    addi sp, sp, 4
    
    addi t0, t0, -1     # i--
    j    extract_loop

sort_done:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# ==============================================================================
# FUNÇÃO: HEAPIFY (a0 = array, a1 = n, a2 = i)
# ==============================================================================
heapify:
    # t0 = largest
    # t1 = left
    # t2 = right
    mv   t0, a2         # largest = i
    slli t1, a2, 1      # left = 2*i
    addi t1, t1, 1      # left = 2*i + 1
    addi t2, t1, 1      # right = 2*i + 2 (ou left + 1)

    # if (left < n && arr[left] > arr[largest])
    bge  t1, a1, check_right # Se left >= n, pula
    
    # Carrega arr[left] e arr[largest]
    slli t3, t1, 2      # Offset left
    add  t3, a0, t3
    lw   t4, 0(t3)      # arr[left]
    
    slli t5, t0, 2      # Offset largest
    add  t5, a0, t5
    lw   t6, 0(t5)      # arr[largest]
    
    ble  t4, t6, check_right
    mv   t0, t1         # largest = left

check_right:
    # if (right < n && arr[right] > arr[largest])
    bge  t2, a1, check_swap
    
    # Carrega arr[right] e arr[largest] (largest pode ter mudado)
    slli t3, t2, 2
    add  t3, a0, t3
    lw   t4, 0(t3)      # arr[right]
    
    slli t5, t0, 2
    add  t5, a0, t5
    lw   t6, 0(t5)      # arr[largest]
    
    ble  t4, t6, check_swap
    mv   t0, t2         # largest = right

check_swap:
    beq  t0, a2, heapify_end # Se largest == i, fim
    
    # Swap(arr[i], arr[largest])
    slli t3, a2, 2      # &arr[i]
    add  t3, a0, t3
    lw   t4, 0(t3)
    
    slli t5, t0, 2      # &arr[largest]
    add  t5, a0, t5
    lw   t6, 0(t5)
    
    sw   t6, 0(t3)
    sw   t4, 0(t5)
    
    # Chamada Recursiva: heapify(arr, n, largest)
    # Como assembly RISC-V prefere não estourar pilha, 
    # podemos fazer "Tail Call" (loop) ou recursão simples.
    # Vamos usar recursão simples.
    addi sp, sp, -4
    sw   ra, 0(sp) 
    
    mv   a2, t0         # i = largest
    jal  heapify
    
    lw   ra, 0(sp)
    addi sp, sp, 4

heapify_end:
    ret

# ==============================================================================
# DADOS A ORDERNAR
# ==============================================================================
.data
.align 2
my_array: 
    .word 45, 10, 99, 2, 0, 15, 7, 33, 1, 100
