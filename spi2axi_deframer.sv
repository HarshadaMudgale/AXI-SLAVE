`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 15:51:09
// Design Name: 
// Module Name: spi2axi_deframer
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


module spi2axi_deframer (input logic clk, 
                         input logic rst_n,
                         input logic mst_rx_wr_en,
                         input logic [31:0] mst_rx_data,
                         output logic mst_rx_full, 
                         output logic fifo_wr_en,
                         output logic [31:0] fifo_wr_data,
                         input logic fifo_wr_full);
    logic word_phase;
    always_ff @(posedge clk or negedge rst_n) begin
     if (!rst_n) word_phase <= 1'b0;
     else if (mst_rx_wr_en) word_phase <= ~word_phase;
    end
    assign fifo_wr_en   = mst_rx_wr_en && word_phase;
    assign fifo_wr_data = mst_rx_data;
    assign mst_rx_full = fifo_wr_full;
endmodule

