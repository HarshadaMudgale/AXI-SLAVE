`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 16:15:08
// Design Name: 
// Module Name: top_spi_axi_fifo
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


module top_spi_axi_fifo #(parameter integer C_S00_AXI_DATA_WIDTH = 32,
                          parameter integer C_S00_AXI_ADDR_WIDTH = 4,
                          parameter int CMD_WIDTH            = 1,
                          parameter int PKT_ADDR_WIDTH       = 4,   
                          parameter int PKT_FIFO_DEPTH_BITS  = 4,   
                          parameter int RX_FIFO_ADDR_WIDTH   = 4)
           (input wire s00_axi_aclk,
            input wire s00_axi_aresetn,
            input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
            input wire [2 : 0] s00_axi_awprot,
            input wire s00_axi_awvalid,
            output wire s00_axi_awready,
            input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
            input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
            input wire s00_axi_wvalid,
            output wire s00_axi_wready,
            output wire [1 : 0] s00_axi_bresp,
            output wire s00_axi_bvalid,
            input wire s00_axi_bready,
            input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
            input wire [2 : 0] s00_axi_arprot,
            input wire s00_axi_arvalid,
            output wire s00_axi_arready,
            output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
            output wire [1 : 0] s00_axi_rresp,
            output wire s00_axi_rvalid,
            input wire s00_axi_rready,
            input wire spi_clk,
            output wire [C_S00_AXI_DATA_WIDTH-1:0] control_reg_dbg,
            output wire spi_cs_n_dbg,
            output wire spi_sclk_dbg);

    logic [1:0] spi_rst_sync;
    always_ff @(posedge spi_clk or negedge s00_axi_aresetn) begin
        if (!s00_axi_aresetn) spi_rst_sync <= 2'b00;
        else spi_rst_sync <= {spi_rst_sync[0], 1'b1};
    end
    wire spi_rst_n = spi_rst_sync[1];
    wire [31:0] tx_fifo_wdata;
    wire tx_fifo_wren;
    wire tx_fifo_full;
    wire [31:0] rx_fifo_rdata;
    wire rx_fifo_rden;
    wire rx_fifo_empty;
    wire [31:0] control_reg;
    assign control_reg_dbg = control_reg;
    wire pkt_wr_cmd  = control_reg[0];
    wire [PKT_ADDR_WIDTH-1:0]  pkt_wr_addr = control_reg[4:1];

    my_axi_fifo_ip_slave_lite_v1_0_S00_AXI #(.C_S_AXI_DATA_WIDTH (C_S00_AXI_DATA_WIDTH), .C_S_AXI_ADDR_WIDTH (C_S00_AXI_ADDR_WIDTH)) 
    u_axi_slave (.tx_fifo_wdata(tx_fifo_wdata),
                 .tx_fifo_wren (tx_fifo_wren),
                 .tx_fifo_full (tx_fifo_full),
                 .rx_fifo_rdata(rx_fifo_rdata),
                 .rx_fifo_rden (rx_fifo_rden),
                 .rx_fifo_empty(rx_fifo_empty),
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
                 .S_AXI_BRESP (s00_axi_bresp),
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

    wire pkt_rd_empty;
    wire pkt_rd_en;
    wire [CMD_WIDTH-1:0] pkt_cmd;
    wire [PKT_ADDR_WIDTH-1:0] pkt_addr;
    wire [31:0] pkt_data;

    async_fifo_pkt #(.CMD_WIDTH (CMD_WIDTH),
        .ADDR_WIDTH (PKT_ADDR_WIDTH),
        .DATA_WIDTH (32),
        .FIFO_DEPTH_BITS (PKT_FIFO_DEPTH_BITS))
         
        u_tx_pkt_fifo (.wr_clk (s00_axi_aclk),
        .wr_rst_n (s00_axi_aresetn),
        .wr_en (tx_fifo_wren),
        .wr_cmd (pkt_wr_cmd),
        .wr_addr (pkt_wr_addr),
        .wr_data (tx_fifo_wdata),
        .wr_full (tx_fifo_full),
        .rd_clk (spi_clk),
        .rd_rst_n (spi_rst_n),
        .rd_en (pkt_rd_en),
        .rd_cmd (pkt_cmd),
        .rd_addr (pkt_addr),
        .rd_data (pkt_data),
        .rd_empty (pkt_rd_empty));
    wire tx_word_empty;
    wire tx_word_rd_en;
    wire [31:0] tx_word_data;

    axi2spi_framer #(.CMD_WIDTH (CMD_WIDTH),
        .ADDR_WIDTH (PKT_ADDR_WIDTH),
        .DATA_WIDTH (32)) 
        
        u_framer (.clk (spi_clk),
        .rst_n (spi_rst_n),
        .pkt_rd_empty (pkt_rd_empty),
        .pkt_rd_en (pkt_rd_en),
        .pkt_cmd (pkt_cmd),
        .pkt_addr (pkt_addr),
        .pkt_data (pkt_data),
        .tx_fifo_empty (tx_word_empty),
        .tx_fifo_rd_en (tx_word_rd_en),
        .tx_fifo_data (tx_word_data) );

    wire rx_word_full;
    wire rx_word_wr_en;
    wire [31:0] rx_word_data;
    wire spi_cs_n, spi_sclk, spi_mosi, spi_miso;
    assign spi_cs_n_dbg  = spi_cs_n;
    assign spi_sclk_dbg  = spi_sclk;

    spi_master u_spi_master (.clk_spi (spi_clk),
        .rst_n (spi_rst_n),
        .tx_fifo_empty (tx_word_empty),
        .tx_fifo_rd_en (tx_word_rd_en),
        .tx_fifo_data (tx_word_data),
        .rx_fifo_full (rx_word_full),
        .rx_fifo_wr_en (rx_word_wr_en),
        .rx_fifo_data (rx_word_data),
        .spi_cs_n (spi_cs_n),
        .spi_sclk (spi_sclk),
        .spi_mosi (spi_mosi),
        .spi_miso (spi_miso));

    spi_slave_32 #(.DATA_WIDTH (32),
        .ADDR_WIDTH (PKT_ADDR_WIDTH),
        .CMD_WIDTH (CMD_WIDTH)) 
        u_spi_slave (.RESET_N (spi_rst_n),
        .SCLK (spi_sclk),
        .CS_N (spi_cs_n),
        .MOSI (spi_mosi),
        .MISO (spi_miso));

    wire rxfifo_wr_en;
    wire [31:0] rxfifo_wr_data;
    wire rxfifo_wr_full;

    spi2axi_deframer u_deframer (.clk (spi_clk),
        .rst_n (spi_rst_n),
        .mst_rx_wr_en (rx_word_wr_en),
        .mst_rx_data (rx_word_data),
        .mst_rx_full (rx_word_full),
        .fifo_wr_en (rxfifo_wr_en),
        .fifo_wr_data (rxfifo_wr_data),
        .fifo_wr_full (rxfifo_wr_full));

    async_fifo #(.DATA_WIDTH (32),
        .ADDR_WIDTH (RX_FIFO_ADDR_WIDTH)) 
        u_rx_fifo (.wr_clk   (spi_clk),
        .wr_rst_n (spi_rst_n),
        .wr_en (rxfifo_wr_en),
        .wr_data (rxfifo_wr_data),
        .wr_full (rxfifo_wr_full),
        .rd_clk (s00_axi_aclk),
        .rd_rst_n (s00_axi_aresetn),
        .rd_en (rx_fifo_rden),
        .rd_data (rx_fifo_rdata),
        .rd_empty (rx_fifo_empty));

endmodule
