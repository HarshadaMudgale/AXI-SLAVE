`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:38:35
// Design Name: 
// Module Name: spi_slave_32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_slave_32 #(parameter int DATA_WIDTH = 32,
                      parameter int ADDR_WIDTH = 4,
                      parameter int CMD_WIDTH  = 1)
   (input logic RESET_N,
    input logic SCLK,
    input logic CS_N,
    input logic MOSI,
    output logic MISO);

    localparam CMD_WRITE = 1'b0;   
    localparam CMD_READ = 1'b1;
    localparam int CNT_W = $clog2(DATA_WIDTH);

    logic [DATA_WIDTH-1:0] memory [0:(2**ADDR_WIDTH)-1];
    logic [DATA_WIDTH-1:0] rx_shift;
    logic [DATA_WIDTH-1:0] tx_shift;
    logic [CNT_W-1:0] bit_cnt;    
    logic word_phase;  
    logic cmd_bit;
    logic [ADDR_WIDTH-1:0] tgt_addr;
    always_ff @(posedge SCLK or negedge RESET_N) begin
     if (!RESET_N) begin
      rx_shift <= '0;
      bit_cnt <= '0;
      word_phase <= 1'b0;
      cmd_bit <= 1'b0;
      tgt_addr <= '0;
     end else if (CS_N)
      bit_cnt <= '0;
     else begin
      logic [DATA_WIDTH-1:0] next_shift;
      next_shift = {rx_shift[DATA_WIDTH-2:0], MOSI};
      rx_shift <= next_shift;
      if (bit_cnt == DATA_WIDTH-1) begin
       bit_cnt <= '0;
       if (word_phase == 1'b0) begin
        cmd_bit <= next_shift[ADDR_WIDTH];
        tgt_addr <= next_shift[ADDR_WIDTH-1:0];
        word_phase <= 1'b1;
       end else begin
        if (cmd_bit == CMD_WRITE)
          memory[tgt_addr] <= next_shift;
        word_phase <= 1'b0;
       end
       end else
         bit_cnt <= bit_cnt + 1'b1;
     end
    end
    always_ff @(negedge SCLK or negedge RESET_N) begin
     if (!RESET_N)
      tx_shift <= '0;
     else if (bit_cnt == '0)
      tx_shift <= (word_phase == 1'b1 && cmd_bit == CMD_READ) ? memory[tgt_addr] : '0;
     else if (!CS_N)
      tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
     end
    assign MISO = CS_N ? 1'bz : tx_shift[DATA_WIDTH-1];
    integer i;
    initial begin
     for (i = 0; i < (2**ADDR_WIDTH); i = i + 1)
      memory[i] = '0;
    end
endmodule