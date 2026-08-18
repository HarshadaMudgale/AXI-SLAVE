`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 15:29:05
// Design Name: 
// Module Name: axi2spi_framer
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


module axi2spi_framer #(parameter int CMD_WIDTH  = 1,
                        parameter int ADDR_WIDTH = 4,
                        parameter int DATA_WIDTH = 32)
   (input logic clk,      
    input logic rst_n,
    input logic pkt_rd_empty,
    output logic pkt_rd_en,
    input logic [CMD_WIDTH-1:0] pkt_cmd,
    input logic [ADDR_WIDTH-1:0] pkt_addr,
    input logic [DATA_WIDTH-1:0] pkt_data,
    output logic tx_fifo_empty,
    input logic tx_fifo_rd_en,
    output logic [DATA_WIDTH-1:0] tx_fifo_data);

    localparam int PAD = DATA_WIDTH - CMD_WIDTH - ADDR_WIDTH;

    typedef enum logic {S_HDR, S_DATA} state_t;
    state_t state;

    logic [DATA_WIDTH-1:0] latched_data;

    always_ff @(posedge clk or negedge rst_n) begin
     if (!rst_n) begin
      state <= S_HDR;
      latched_data <= '0;
      pkt_rd_en <= 1'b0;
     end else begin
      pkt_rd_en <= 1'b0; 
      case (state)
       S_HDR: begin
        if (tx_fifo_rd_en && !pkt_rd_empty) begin
         pkt_rd_en <= 1'b1;
         latched_data <= pkt_data;
         state <= S_DATA;
        end
       end
       S_DATA: begin
        if (tx_fifo_rd_en) state <= S_HDR;
       end
       default: state <= S_HDR;
      endcase
     end
    end
    assign tx_fifo_empty = (state == S_HDR) ? pkt_rd_empty : 1'b0;
    assign tx_fifo_data = (state == S_HDR) ? {{PAD{1'b0}}, pkt_cmd, pkt_addr}
                                             : latched_data;
endmodule

