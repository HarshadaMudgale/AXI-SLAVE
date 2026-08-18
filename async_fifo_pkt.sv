`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:35:59
// Design Name: 
// Module Name: async_fifo_pkt
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


module async_fifo_pkt #(parameter int CMD_WIDTH  = 1,   
                        parameter int ADDR_WIDTH = 4,       
                        parameter int DATA_WIDTH = 32,      
                        parameter int FIFO_DEPTH_BITS = 4 )
   (input logic wr_clk,
    input logic wr_rst_n,
    input logic wr_en,
    input logic [CMD_WIDTH-1:0] wr_cmd,
    input logic [ADDR_WIDTH-1:0] wr_addr,
    input logic [DATA_WIDTH-1:0] wr_data,
    output logic wr_full,
    input logic rd_clk,
    input logic rd_rst_n,
    input logic rd_en,
    output logic [CMD_WIDTH-1:0]  rd_cmd,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic rd_empty);

    localparam int PKT_WIDTH = CMD_WIDTH + ADDR_WIDTH + DATA_WIDTH;

    logic [PKT_WIDTH-1:0] wr_pkt;
    logic [PKT_WIDTH-1:0] rd_pkt;

    assign wr_pkt = {wr_cmd, wr_addr, wr_data};
    assign {rd_cmd, rd_addr, rd_data} = rd_pkt;

    async_fifo #(.DATA_WIDTH (PKT_WIDTH),
        .ADDR_WIDTH (FIFO_DEPTH_BITS)) 
        
        u_core_fifo (.wr_clk (wr_clk),
        .wr_rst_n (wr_rst_n),
        .wr_en (wr_en),
        .wr_data (wr_pkt),
        .wr_full (wr_full),
        .rd_clk (rd_clk),
        .rd_rst_n (rd_rst_n),
        .rd_en (rd_en),
        .rd_data (rd_pkt),
        .rd_empty (rd_empty));

endmodule

