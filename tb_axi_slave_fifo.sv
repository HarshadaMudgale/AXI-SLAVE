`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 14:41:06
// Design Name: 
// Module Name: tb_axi_slave_fifo
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


module tb_axi_slave_fifo;

    localparam time CLK_PERIOD = 10ns;

    logic s00_axi_aclk_0;
    logic s00_axi_aresetn_0;

    logic [31:0] tx_fifo_wdata_0;
    logic tx_fifo_wren_0;
    logic tx_fifo_full_0;

    logic [31:0] rx_fifo_rdata_0;
    logic rx_fifo_rden_0;
    logic rx_fifo_empty_0;

    logic [31:0] control_reg_0;

    logic [3:0] S00_AXI_0_awaddr;
    logic [2:0] S00_AXI_0_awprot;
    logic S00_AXI_0_awvalid;
    logic S00_AXI_0_awready;

    logic [31:0] S00_AXI_0_wdata;
    logic [3:0] S00_AXI_0_wstrb;
    logic S00_AXI_0_wvalid;
    logic S00_AXI_0_wready;

    logic [1:0] S00_AXI_0_bresp;
    logic S00_AXI_0_bvalid;
    logic S00_AXI_0_bready;

    logic [3:0] S00_AXI_0_araddr;
    logic [2:0] S00_AXI_0_arprot;
    logic S00_AXI_0_arvalid;
    logic S00_AXI_0_arready;

    logic [31:0] S00_AXI_0_rdata;
    logic [1:0]  S00_AXI_0_rresp;
    logic S00_AXI_0_rvalid;
    logic S00_AXI_0_rready;

    
    my_axi_fifo_ip uut (
        .s00_axi_aclk (s00_axi_aclk_0),
        .s00_axi_aresetn (s00_axi_aresetn_0),

        .s00_axi_awaddr (S00_AXI_0_awaddr),
        .s00_axi_awprot (S00_AXI_0_awprot),
        .s00_axi_awvalid (S00_AXI_0_awvalid),
        .s00_axi_awready (S00_AXI_0_awready),

        .s00_axi_wdata (S00_AXI_0_wdata),
        .s00_axi_wstrb (S00_AXI_0_wstrb),
        .s00_axi_wvalid (S00_AXI_0_wvalid),
        .s00_axi_wready (S00_AXI_0_wready),

        .s00_axi_bresp (S00_AXI_0_bresp),
        .s00_axi_bvalid (S00_AXI_0_bvalid),
        .s00_axi_bready (S00_AXI_0_bready),

        .s00_axi_araddr (S00_AXI_0_araddr),
        .s00_axi_arprot (S00_AXI_0_arprot),
        .s00_axi_arvalid (S00_AXI_0_arvalid),
        .s00_axi_arready (S00_AXI_0_arready),

        .s00_axi_rdata (S00_AXI_0_rdata),
        .s00_axi_rresp (S00_AXI_0_rresp),
        .s00_axi_rvalid (S00_AXI_0_rvalid),
        .s00_axi_rready (S00_AXI_0_rready),

        .tx_fifo_wdata (tx_fifo_wdata_0),
        .tx_fifo_wren (tx_fifo_wren_0),
        .tx_fifo_full (tx_fifo_full_0),

        .rx_fifo_rdata (rx_fifo_rdata_0),
        .rx_fifo_rden (rx_fifo_rden_0),
        .rx_fifo_empty (rx_fifo_empty_0),

        .control_reg (control_reg_0)
    );

    
    always #(CLK_PERIOD / 2) s00_axi_aclk_0 = ~s00_axi_aclk_0;

   
    task automatic axi_write(input logic [3:0] addr, input logic [31:0] data);
        @(posedge s00_axi_aclk_0);
        S00_AXI_0_awaddr <= addr;
        S00_AXI_0_awvalid <= 1'b1;
        S00_AXI_0_wdata <= data;
        S00_AXI_0_wstrb <= 4'b1111;
        S00_AXI_0_wvalid <= 1'b1;
        S00_AXI_0_bready <= 1'b1;

        wait (S00_AXI_0_awready && S00_AXI_0_wready);
        @(posedge s00_axi_aclk_0);
        S00_AXI_0_awvalid <= 1'b0;
        S00_AXI_0_wvalid <= 1'b0;

        wait (S00_AXI_0_bvalid);
        @(posedge s00_axi_aclk_0);
        S00_AXI_0_bready <= 1'b0;
        $display("[AXI WRITE] Addr: 0x%0h | Data: 0x%0h", addr, data);
    endtask

    
    task automatic axi_read(input logic [3:0] addr);
        @(posedge s00_axi_aclk_0);
        S00_AXI_0_araddr <= addr;
        S00_AXI_0_arvalid <= 1'b1;
        S00_AXI_0_rready <= 1'b1;

        wait (S00_AXI_0_arready);
        @(posedge s00_axi_aclk_0);
        S00_AXI_0_arvalid <= 1'b0;

        wait (S00_AXI_0_rvalid);
        @(posedge s00_axi_aclk_0);
        $display("[AXI READ]  Addr: 0x%0h | Data Read: 0x%0h", addr, S00_AXI_0_rdata);
        S00_AXI_0_rready <= 1'b0;
    endtask

    
    initial begin
        s00_axi_aclk_0 = 1'b0;
        s00_axi_aresetn_0 = 1'b0;
        S00_AXI_0_awaddr = '0;
        S00_AXI_0_awprot = '0;
        S00_AXI_0_awvalid = 1'b0;
        S00_AXI_0_wdata = '0;
        S00_AXI_0_wstrb = '0;
        S00_AXI_0_wvalid = 1'b0;
        S00_AXI_0_bready = 1'b0;
        S00_AXI_0_araddr = '0;
        S00_AXI_0_arprot = '0;
        S00_AXI_0_arvalid = 1'b0;
        S00_AXI_0_rready = 1'b0;

        tx_fifo_full_0 = 1'b0;
        rx_fifo_empty_0 = 1'b0;
        rx_fifo_rdata_0 = 32'hDEADBEEF;

        #50ns;
        s00_axi_aresetn_0 = 1'b1;
        #20ns;

        $display("STARTING AXI FIFO SYSTEMVERILOG SIMULATION");

        
        axi_write(4'h0, 32'h0000_0001);

        
        axi_write(4'h8, 32'hA5A5_1234);

      
        axi_read(4'h4);

        
        axi_read(4'hC);

        #100ns;
        $display(" SIMULATION COMPLETED SUCCESSFULLY ");
        $finish;
    end

endmodule



