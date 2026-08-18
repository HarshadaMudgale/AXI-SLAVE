`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:32:36
// Design Name: 
// Module Name: async_fifo
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


module async_fifo #(parameter int DATA_WIDTH = 32,
                    parameter int ADDR_WIDTH = 4 )
   (input logic wr_clk,
    input logic wr_rst_n,
    input logic wr_en,
    input logic [DATA_WIDTH-1:0] wr_data,
    output logic wr_full,
    input logic rd_clk,
    input logic rd_rst_n,
    input logic rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic rd_empty);

    localparam int DEPTH = 1 << ADDR_WIDTH;

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_bin_next;
    logic [ADDR_WIDTH:0] wr_ptr_gray, wr_ptr_gray_next;
    logic [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_bin_next;
    logic [ADDR_WIDTH:0] rd_ptr_gray, rd_ptr_gray_next;
    logic [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2; 
    logic [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2; 
    logic wr_full_next;
    logic rd_empty_next;

    assign wr_ptr_bin_next = wr_ptr_bin + (wr_en & ~wr_full);
    assign wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
     if (!wr_rst_n) begin
      wr_ptr_bin <= '0;
      wr_ptr_gray <= '0;
     end else begin
      wr_ptr_bin <= wr_ptr_bin_next;
      wr_ptr_gray <= wr_ptr_gray_next;
     end
    end

    always_ff @(posedge wr_clk) begin
     if (wr_en && !wr_full)
      mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
     if (!wr_rst_n) begin
      rd_ptr_gray_sync1 <= '0;
      rd_ptr_gray_sync2 <= '0;
     end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
     end
    end

    assign wr_full_next = (wr_ptr_gray_next == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                         rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
     if (!wr_rst_n) wr_full <= 1'b0;
     else wr_full <= wr_full_next;
    end

    assign rd_ptr_bin_next = rd_ptr_bin + (rd_en & ~rd_empty);
    assign rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
     if (!rd_rst_n) begin
      rd_ptr_bin <= '0;
      rd_ptr_gray <= '0;
     end else begin
      rd_ptr_bin <= rd_ptr_bin_next;
      rd_ptr_gray <= rd_ptr_gray_next;
     end
    end
    assign rd_data = mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
     if (!rd_rst_n) begin
      wr_ptr_gray_sync1 <= '0;
      wr_ptr_gray_sync2 <= '0;
     end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
     end
    end

    assign rd_empty_next = (rd_ptr_gray_next == wr_ptr_gray_sync2);
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
     if (!rd_rst_n) rd_empty <= 1'b1;
     else rd_empty <= rd_empty_next;
    end

endmodule

