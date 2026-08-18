`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:40:38
// Design Name: 
// Module Name: spi_master
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


module spi_master #(parameter int DATA_WIDTH = 32 )
   (input logic clk_spi,      
    input logic rst_n,        
    input logic tx_fifo_empty,
    output logic tx_fifo_rd_en,
    input logic [DATA_WIDTH-1:0] tx_fifo_data,
    input logic rx_fifo_full,
    output logic rx_fifo_wr_en,
    output logic [DATA_WIDTH-1:0] rx_fifo_data,
    output logic spi_cs_n,
    output logic spi_sclk,
    output logic spi_mosi,
    input logic spi_miso);

    typedef enum logic [1:0] {IDLE  = 2'd0,
                              FETCH = 2'd1,
                              SHIFT = 2'd2} 
    state_t;
    state_t state;

    logic [DATA_WIDTH-1:0] shift_reg;
    logic [7:0] bit_cnt;  
    logic sclk_reg; 

    assign spi_sclk = sclk_reg;

    always_ff @(posedge clk_spi or negedge rst_n) begin
     if (!rst_n) begin
      state <= IDLE;
      spi_cs_n <= 1'b1;
      spi_mosi <= 1'b0;
      sclk_reg <= 1'b0;
      shift_reg <= '0;
      bit_cnt <= '0;
      tx_fifo_rd_en <= 1'b0;
      rx_fifo_wr_en <= 1'b0;
      rx_fifo_data <= '0;
     end else begin
      tx_fifo_rd_en <= 1'b0;
      rx_fifo_wr_en <= 1'b0;
      case (state)
       IDLE: begin
        spi_cs_n <= 1'b1;
        sclk_reg <= 1'b0;
        if (!tx_fifo_empty) begin
         tx_fifo_rd_en <= 1'b1; 
         state <= FETCH;
        end
       end
       FETCH: begin
        shift_reg <= tx_fifo_data;
        spi_cs_n <= 1'b0;
        spi_mosi <= tx_fifo_data[DATA_WIDTH-1]; 
        bit_cnt <= DATA_WIDTH[7:0];           
        state <= SHIFT;
       end
       SHIFT: begin
       sclk_reg <= ~sclk_reg; 
       if (sclk_reg == 1'b0) begin
        shift_reg <= {shift_reg[DATA_WIDTH-2:0], spi_miso};
       end
       if (sclk_reg == 1'b1) begin
         bit_cnt <= bit_cnt - 8'd1;
         if (bit_cnt == 8'd1) begin
          state <= IDLE;      
          spi_cs_n <= 1'b1;      
          if (!rx_fifo_full) begin
           rx_fifo_wr_en <= 1'b1;
           rx_fifo_data <= shift_reg;
          end
         end else begin
           spi_mosi <= shift_reg[DATA_WIDTH-1]; 
         end
       end
       end
      endcase
     end
    end
endmodule

