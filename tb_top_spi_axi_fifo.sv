`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 16:15:41
// Design Name: 
// Module Name: tb_top_spi_axi_fifo
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


module tb_top_spi_axi_fifo;

    localparam AXI_CLK_PERIOD = 10;  
    localparam SPI_CLK_PERIOD = 20;  

    logic s00_axi_aclk;
    logic s00_axi_aresetn;
    logic spi_clk;

    logic [3:0] s00_axi_awaddr;
    logic [2:0] s00_axi_awprot;
    logic s00_axi_awvalid;
    logic s00_axi_awready;
    logic [31:0] s00_axi_wdata;
    logic [3:0] s00_axi_wstrb;
    logic s00_axi_wvalid;
    logic s00_axi_wready;
    logic [1:0] s00_axi_bresp;
    logic s00_axi_bvalid;
    logic s00_axi_bready;
    logic [3:0] s00_axi_araddr;
    logic [2:0] s00_axi_arprot;
    logic s00_axi_arvalid;
    logic s00_axi_arready;
    logic [31:0] s00_axi_rdata;
    logic [1:0] s00_axi_rresp;
    logic s00_axi_rvalid;
    logic s00_axi_rready;

    logic [31:0] control_reg_dbg;
    logic spi_cs_n_dbg, spi_sclk_dbg;

    top_spi_axi_fifo uut (
        .s00_axi_aclk (s00_axi_aclk),
        .s00_axi_aresetn (s00_axi_aresetn),
        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid (s00_axi_awvalid),
        .s00_axi_awready (s00_axi_awready),
        .s00_axi_wdata (s00_axi_wdata),
        .s00_axi_wstrb (s00_axi_wstrb),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bresp (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid (s00_axi_arvalid),
        .s00_axi_arready (s00_axi_arready),
        .s00_axi_rdata (s00_axi_rdata),
        .s00_axi_rresp (s00_axi_rresp),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready),
        .spi_clk (spi_clk),
        .control_reg_dbg (control_reg_dbg),
        .spi_cs_n_dbg (spi_cs_n_dbg),
        .spi_sclk_dbg (spi_sclk_dbg)
    );

    always #(AXI_CLK_PERIOD/2) s00_axi_aclk = ~s00_axi_aclk;
    always #(SPI_CLK_PERIOD/2) spi_clk = ~spi_clk;

    
    task axi_write(input [3:0] addr, input [31:0] data);
        begin
            @(posedge s00_axi_aclk);
            s00_axi_awaddr <= addr;
            s00_axi_awvalid <= 1'b1;
            s00_axi_wdata <= data;
            s00_axi_wstrb <= 4'b1111;
            s00_axi_wvalid <= 1'b1;
            s00_axi_bready <= 1'b1;

            wait (s00_axi_awready && s00_axi_wready);
            @(posedge s00_axi_aclk);
            s00_axi_awvalid <= 1'b0;
            s00_axi_wvalid <= 1'b0;

            wait (s00_axi_bvalid);
            @(posedge s00_axi_aclk);
            s00_axi_bready  <= 1'b0;
            $display("[%0t] [AXI WRITE] Addr: 0x%0h | Data: 0x%08h", $time, addr, data);
        end
    endtask

    task axi_read(input [3:0] addr, output [31:0] rdata);
        begin
            @(posedge s00_axi_aclk);
            s00_axi_araddr <= addr;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready <= 1'b1;

            wait (s00_axi_arready);
            @(posedge s00_axi_aclk);
            s00_axi_arvalid <= 1'b0;

            wait (s00_axi_rvalid);
            @(posedge s00_axi_aclk);
            rdata = s00_axi_rdata;
            $display("[%0t] [AXI READ]  Addr: 0x%0h | Data: 0x%08h", $time, addr, rdata);
            s00_axi_rready <= 1'b0;
        end
    endtask


    task wait_rx_ready(input integer timeout_cycles);
        logic [31:0] status;
        integer n;
        begin
            n = 0;
            do begin
                axi_read(4'h4, status);
                n = n + 1;
                if (status[1] == 1'b0) begin
                    
                    n = timeout_cycles;
                end
            end while (n < timeout_cycles);
        end
    endtask

    logic [31:0] rd_data;
    integer errors = 0;

    initial begin
        s00_axi_aclk = 0;
        spi_clk = 0;
        s00_axi_aresetn = 0;
        s00_axi_awaddr = 0; 
	s00_axi_awprot = 0; 
	s00_axi_awvalid = 0;
        s00_axi_wdata = 0; 
	s00_axi_wstrb  = 0; 
	s00_axi_wvalid  = 0;
        s00_axi_bready = 0;
        s00_axi_araddr = 0; 
	s00_axi_arprot = 0; 
	s00_axi_arvalid = 0;
        s00_axi_rready = 0;

        #50;
        s00_axi_aresetn = 1;
        #40;

        $display(" WRITE 0xA5A5_1234 to device address 0x3 ");
        axi_write(4'h0, {27'd0, 4'h3, 1'b0}); 
        axi_write(4'h8, 32'hA5A5_1234); 

        wait_rx_ready(2000);
        axi_read(4'hC, rd_data);
        $display("(drained WRITE ack word = 0x%08h - expected to be discarded)", rd_data);

        #200;

        $display(" READ BACK device address 0x3 ");
        axi_write(4'h0, {27'd0, 4'h3, 1'b1});  
        axi_write(4'h8, 32'h0000_0000);     

        wait_rx_ready(2000);
        axi_read(4'hC, rd_data);

        if (rd_data == 32'hA5A5_1234) begin
            $display("PASS: read back 0x%08h, matches what was written.", rd_data);
        end else begin
            $display("FAIL: read back 0x%08h, expected 0xA5A51234.", rd_data);
            errors = errors + 1;
        end

        #200;
        if (errors == 0) $display("END-TO-END TEST PASSED");
        else $display(" END-TO-END TEST FAILED (%0d error(s)) ", errors);
        $finish;
    end

endmodule

