module top(
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output reg [9:0] LEDR,
    output [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

    wire memwrite, clk, reset;
    wire [31:0] PC, Instr; // Fios para Instrução
    wire [31:0] DataAddr, WriteData, ReadData, MEM_readdata, IO_readdata; 
    
    // Clock
    integer counter = 0;  
    always @(posedge CLOCK_50) 
        counter <= counter + 1;
    assign clk = counter[21]; // ~11.9 Hz
    assign reset = ~KEY[0];   // active low


    riscvpipeline cpu(clk, reset, PC, Instr, DataAddr, WriteData, memwrite, ReadData);

    //  mem de leitura de intruções
    mem imem (clk, 1'b0, PC, 32'b0, Instr);

    // mem de data
    wire isIO = DataAddr[8]; 
    mem dmem (clk, memwrite && !isIO, DataAddr, WriteData, MEM_readdata);


    // 4. Memory-mapped I/O
    localparam IO_LEDS_bit = 2; // 0x104 (addr[8]=1, addr[2]=1)
    localparam IO_HEX_bit  = 3; // 0x108
    localparam IO_KEY_bit  = 4; // 0x110 
    localparam IO_SW_bit   = 5; // 0x120
    
    reg [23:0] hex_digits; 

    // Drivers dos 7 segmentos
    dec7seg hex0(hex_digits[ 3: 0], HEX0);
    dec7seg hex1(hex_digits[ 7: 4], HEX1);
    dec7seg hex2(hex_digits[11: 8], HEX2);
    dec7seg hex3(hex_digits[15:12], HEX3);
    dec7seg hex4(hex_digits[19:16], HEX4);
    dec7seg hex5(hex_digits[23:20], HEX5);

    // Escrita em IO (LEDS e HEX)
    always @(posedge clk)
        if (memwrite && isIO) begin 
        if (DataAddr[IO_LEDS_bit])
            LEDR <= WriteData[9:0]; // Ajustado para 10 bits
        if (DataAddr[IO_HEX_bit])
            hex_digits <= WriteData[23:0];
    end

    // Leitura de IO (KEY e SW)
    assign IO_readdata = (DataAddr[IO_KEY_bit]) ? {28'b0, KEY} :
                        (DataAddr[IO_SW_bit])  ? {22'b0, SW}  : 
                                                    32'b0;

    // Mux final de leitura (Memória ou IO)
    assign ReadData = isIO ? IO_readdata : MEM_readdata; 

    endmodule