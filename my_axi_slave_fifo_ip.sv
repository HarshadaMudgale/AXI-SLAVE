`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 13:58:17
// Design Name: 
// Module Name: my_axi_slave_fifo_ip
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


module my_axi_fifo_ip #(parameter integer C_S00_AXI_DATA_WIDTH = 32,
                        parameter integer C_S00_AXI_ADDR_WIDTH = 4)
   (output logic [31:0] tx_fifo_wdata,
    output logic tx_fifo_wren,
    input logic tx_fifo_full,
    input logic [31:0] rx_fifo_rdata,
    output logic rx_fifo_rden,
    input logic rx_fifo_empty,
    output logic [31:0] control_reg,
    input logic s00_axi_aclk,
    input logic s00_axi_aresetn,
    input logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr,
    input logic [2:0] s00_axi_awprot,
    input logic s00_axi_awvalid,
    output logic s00_axi_awready,
    input logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_wdata,
    input logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb,
    input logic s00_axi_wvalid,
    output logic s00_axi_wready,
    output logic [1:0]s00_axi_bresp,
    output logic s00_axi_bvalid,
    input logic s00_axi_bready,
    input logic [C_S00_AXI_ADDR_WIDTH-1:0] s00_axi_araddr,
    input logic [2:0]s00_axi_arprot,
    input logic s00_axi_arvalid,
    output logic s00_axi_arready,
    output logic [C_S00_AXI_DATA_WIDTH-1:0] s00_axi_rdata,
    output logic [1:0] s00_axi_rresp,
    output logic s00_axi_rvalid,
    input logic s00_axi_rready);

    my_axi_fifo_ip_slave_lite_v1_0_S00_AXI #(.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH))
         my_axi_fifo_ip_slave_lite_v1_0_S00_AXI_inst (.tx_fifo_wdata (tx_fifo_wdata),
        .tx_fifo_wren (tx_fifo_wren),
        .tx_fifo_full (tx_fifo_full),
        .rx_fifo_rdata (rx_fifo_rdata),
        .rx_fifo_rden (rx_fifo_rden),
        .rx_fifo_empty (rx_fifo_empty),
        .control_reg (control_reg),
        .S_AXI_ACLK (s00_axi_aclk),
        .S_AXI_ARESETN (s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID (s00_axi_awvalid),
        .S_AXI_AWREADY (s00_axi_awready),
        .S_AXI_WDATA (s00_axi_wdata),
        .S_AXI_WSTRB (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID (s00_axi_arvalid),
        .S_AXI_ARREADY (s00_axi_arready),
        .S_AXI_RDATA (s00_axi_rdata),
        .S_AXI_RRESP (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready));
endmodule
