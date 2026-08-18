`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 14:37:43
// Design Name: 
// Module Name: my_axi_fifo_ip_slave_lite_v1_0_S00_AXI
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


module my_axi_fifo_ip_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    // Custom FIFO Interface Ports
    output wire [C_S_AXI_DATA_WIDTH-1:0] tx_fifo_wdata,
    output wire tx_fifo_wren,
    input wire tx_fifo_full,
    input wire [C_S_AXI_DATA_WIDTH-1:0] rx_fifo_rdata,
    output wire rx_fifo_rden,
    input wire rx_fifo_empty,
    output wire [C_S_AXI_DATA_WIDTH-1:0] control_reg,
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY);

    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    integer byte_index;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY = axi_wready;
    assign S_AXI_BRESP = axi_bresp;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RRESP = axi_rresp;
    assign S_AXI_RVALID = axi_rvalid;
    always @(posedge S_AXI_ACLK) begin
     if (!S_AXI_ARESETN) begin
      axi_awready <= 1'b0;
      axi_wready <= 1'b0;
      axi_awaddr <= 0;
     end else begin
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
        if ((S_AXI_AWADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) && tx_fifo_full) begin
         axi_awready <= 1'b0; 
         axi_wready  <= 1'b0;
        end else begin
         axi_awready <= 1'b1;
         axi_wready  <= 1'b1;
         axi_awaddr  <= S_AXI_AWADDR;
        end
      end else begin
       axi_awready <= 1'b0;
       axi_wready  <= 1'b0;
      end
     end
    end
    always @(posedge S_AXI_ACLK) begin
     if (!S_AXI_ARESETN) begin
         axi_bvalid <= 1'b0;
         axi_bresp  <= 2'b0;
     end else begin
         if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid) begin
             axi_bvalid <= 1'b1;
             axi_bresp  <= 2'b0;
         end else if (S_AXI_BREADY && axi_bvalid) begin
             axi_bvalid <= 1'b0;
         end
     end
    end
    wire slv_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    always @(posedge S_AXI_ACLK) begin
     if (!S_AXI_ARESETN) begin
      slv_reg0 <= 0;
      slv_reg2 <= 0;
     end else if (slv_wren) begin
      case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
       2'h0: begin
         for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
         if (S_AXI_WSTRB[byte_index]) slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
       end
       2'h2: begin
        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
        if (S_AXI_WSTRB[byte_index]) slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
       end
      endcase
     end
    end
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else begin
         if (~axi_arready && S_AXI_ARVALID) begin
             if ((S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) && rx_fifo_empty) begin
              axi_arready <= 1'b0;
             end else begin
              axi_arready <= 1'b1;
              axi_araddr  <= S_AXI_ARADDR;
             end
         end else
          axi_arready <= 1'b0;
        end
    end
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end
    wire slv_rd_pulse = axi_arready && S_AXI_ARVALID && ~axi_rvalid;
    reg [C_S_AXI_DATA_WIDTH-1:0] rx_fifo_rdata_captured;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)      rx_fifo_rdata_captured <= 0;
        else if (rx_fifo_rden)   rx_fifo_rdata_captured <= rx_fifo_rdata;
    end
    assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0) ? slv_reg0 :
                         (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1) ? {30'b0, rx_fifo_empty, tx_fifo_full} :
                         (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) ? slv_reg2 :
                         (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3) ? rx_fifo_rdata_captured : 32'h0;

    assign control_reg = slv_reg0;
    assign tx_fifo_wdata = S_AXI_WDATA;
    assign tx_fifo_wren = (slv_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2));
    assign rx_fifo_rden = (slv_rd_pulse && (S_AXI_ARADDR[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h3));

endmodule