# HeapSort-RISCV
O projeto consiste na implementação de um processador RISC-V em pipeline que executa o algoritmo Heapsort para organizar um array de dados.

## Funcionamento
O funcionamento inicia com o processador em modo de espera até que o SW[0] seja acionado, gatilho que dispara a ordenação do vetor armazenado na memória RAM (carregado via arquivo hexadecimal no Assembly). Após a conclusão do algoritmo, o usuário utiliza os switches (SW[x]) para selecionar um índice específico do array, e o processador exibe o valor correspondente, agora ordenado, nos LEDs da FPGA.
