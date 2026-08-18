`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 15:34:36
// Design Name: 
// Module Name: tb_axi2spi_framer
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


module tb_axi2spi_framer;

    localparam CMD_WIDTH  = 1;
    localparam ADDR_WIDTH = 4;
    localparam DATA_WIDTH = 32;
    localparam PAD = DATA_WIDTH - CMD_WIDTH - ADDR_WIDTH;

    logic clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk;

   
    logic pkt_rd_empty, pkt_rd_en;
    logic [CMD_WIDTH-1:0]  pkt_cmd;
    logic [ADDR_WIDTH-1:0] pkt_addr;
    logic [DATA_WIDTH-1:0] pkt_data;

    logic [CMD_WIDTH-1:0]  pkt_cmd_mem  [0:2] = '{1'b0, 1'b1, 1'b0};
    logic [ADDR_WIDTH-1:0] pkt_addr_mem [0:2] = '{4'h1, 4'h2, 4'h3};
    logic [DATA_WIDTH-1:0] pkt_data_mem [0:2] = '{32'hAAAA_0001, 32'hBBBB_0002, 32'hCCCC_0003};
    integer pkt_idx;

    assign pkt_rd_empty = (pkt_idx >= 3);
    assign pkt_cmd  = pkt_rd_empty ? '0 : pkt_cmd_mem[pkt_idx];
    assign pkt_addr = pkt_rd_empty ? '0 : pkt_addr_mem[pkt_idx];
    assign pkt_data = pkt_rd_empty ? '0 : pkt_data_mem[pkt_idx];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)      pkt_idx <= 0;
        else if (pkt_rd_en) pkt_idx <= pkt_idx + 1;
    end

    
    logic tx_fifo_empty, tx_fifo_rd_en;
    logic [DATA_WIDTH-1:0] tx_fifo_data;

    axi2spi_framer #(.CMD_WIDTH(CMD_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH))
    DUT (
        .clk(clk),
       	.rst_n(rst_n),
        .pkt_rd_empty(pkt_rd_empty),
       	.pkt_rd_en(pkt_rd_en),
        .pkt_cmd(pkt_cmd),
       	.pkt_addr(pkt_addr),
       	.pkt_data(pkt_data),
        .tx_fifo_empty(tx_fifo_empty),
       	.tx_fifo_rd_en(tx_fifo_rd_en),
	.tx_fifo_data(tx_fifo_data)
    );

    
    logic [DATA_WIDTH-1:0] popped [0:5];
    integer pop_idx;

    assign tx_fifo_rd_en = !tx_fifo_empty;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) pop_idx <= 0;
        else if (tx_fifo_rd_en && pop_idx < 6) begin
            popped[pop_idx] <= tx_fifo_data;
            pop_idx <= pop_idx + 1;
        end
    end

    integer errors = 0;
    logic [DATA_WIDTH-1:0] exp_hdr, exp_data;

    initial begin
        rst_n = 0;
        #12;
        rst_n = 1;

        wait (pop_idx == 6);
        #10;

        for (int p = 0; p < 3; p++) begin
            exp_hdr  = {{PAD{1'b0}}, pkt_cmd_mem[p], pkt_addr_mem[p]};
            exp_data = pkt_data_mem[p];
            if (popped[2*p] !== exp_hdr) begin
                $display("FAIL: packet %0d header = %h, expected %h", p, popped[2*p], exp_hdr);
                errors++;
            end else
                $display("PASS: packet %0d header = %h", p, popped[2*p]);

            if (popped[2*p+1] !== exp_data) begin
                $display("FAIL: packet %0d data = %h, expected %h", p, popped[2*p+1], exp_data);
                errors++;
            end else
                $display("PASS: packet %0d data = %h", p, popped[2*p+1]);
        end

        if (errors == 0) $display("axi2spi_framer UNIT TEST PASSED");
        else $display("axi2spi_framer UNIT TEST FAILED (%0d error(s))", errors);
        $finish;
    end

endmodule

