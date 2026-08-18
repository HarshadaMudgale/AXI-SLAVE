`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 15:00:20
// Design Name: 
// Module Name: tb_async_fifo_pkt
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


module tb_async_fifo_pkt;

    localparam int CMD_WIDTH = 1;
    localparam int ADDR_WIDTH = 4;
    localparam int DATA_WIDTH = 32;
    localparam int FIFO_DEPTH_BITS = 4;                
    localparam int DEPTH = (1 << FIFO_DEPTH_BITS);

    logic wr_clk, wr_rst_n, wr_en, wr_full;
    logic [CMD_WIDTH-1:0] wr_cmd;
    logic [ADDR_WIDTH-1:0] wr_addr;
    logic [DATA_WIDTH-1:0] wr_data;

    logic rd_clk, rd_rst_n, rd_en, rd_empty;
    logic [CMD_WIDTH-1:0] rd_cmd;
    logic [ADDR_WIDTH-1:0] rd_addr;
    logic [DATA_WIDTH-1:0] rd_data;

    async_fifo_pkt #(
        .CMD_WIDTH (CMD_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH_BITS (FIFO_DEPTH_BITS)
    ) DUT (
        .wr_clk (wr_clk),   
	.wr_rst_n (wr_rst_n), 
	.wr_en (wr_en),
        .wr_cmd (wr_cmd),   
	.wr_addr (wr_addr),  
	.wr_data (wr_data),
        .wr_full (wr_full),

        .rd_clk (rd_clk),   
	.rd_rst_n (rd_rst_n), 
	.rd_en (rd_en),
        .rd_cmd (rd_cmd),   
	.rd_addr (rd_addr),  
	.rd_data (rd_data),
        .rd_empty (rd_empty)
    );

    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;

    
    initial rd_clk = 0;
    always #7 rd_clk = ~rd_clk;

    
    logic [CMD_WIDTH-1:0] exp_cmd [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] exp_addr [0:DEPTH-1];
    logic [DATA_WIDTH-1:0] exp_data [0:DEPTH-1];
    integer errors = 0;

    logic fill_done = 1'b0;

    
    initial begin
        wr_rst_n = 0;
        wr_en = 0;
        wr_cmd = 0;
        wr_addr = 0;
        wr_data = 0;
        repeat (3) @(posedge wr_clk);
        wr_rst_n = 1;

        $display(" Filling packet FIFO with %0d packets ", DEPTH);
        for (int i = 0; i < DEPTH; i++) begin
            @(negedge wr_clk);
            wr_cmd = i[0];               
            wr_addr = i[ADDR_WIDTH-1:0];
            wr_data = 32'hA000_0000 + i;
            exp_cmd[i] = wr_cmd;
            exp_addr[i] = wr_addr;
            exp_data[i] = wr_data;
            wr_en = 1'b1;
            @(negedge wr_clk);
            wr_en = 1'b0;
        end

        @(negedge wr_clk);
        if (wr_full) $display("PASS: wr_full asserted correctly after %0d writes", DEPTH);
        else begin
            $display("ERROR: wr_full NOT asserted after filling the FIFO");
            errors++;
        end

        wr_cmd = 1'b1;
        wr_addr = 4'h0;
        wr_data = 32'hFFFF_FFFF;
        wr_en = 1'b1;
        @(negedge wr_clk);
        wr_en = 1'b0;

        fill_done = 1'b1;   
     end

    
    initial begin
        rd_rst_n = 0;
        rd_en = 0;
        repeat (3) @(posedge rd_clk);
        rd_rst_n = 1;

        wait (fill_done);
        wait (!rd_empty);
        $display(" Draining packet FIFO ");

        for (int i = 0; i < DEPTH; i++) begin
            @(negedge rd_clk);
            while (rd_empty) @(negedge rd_clk);

            if (rd_cmd !== exp_cmd[i] || rd_addr !== exp_addr[i] || rd_data !== exp_data[i]) begin
                $display("ERROR: packet %0d mismatch. Expected cmd=%b addr=%h data=%h | Got cmd=%b addr=%h data=%h",
                          i, exp_cmd[i], exp_addr[i], exp_data[i], rd_cmd, rd_addr, rd_data);
                errors++;
            end else begin
                $display("PASS: packet %0d = cmd=%b addr=%h data=%h", i, rd_cmd, rd_addr, rd_data);
            end

            rd_en = 1'b1;
            @(negedge rd_clk);
            rd_en = 1'b0;
        end

        @(negedge rd_clk);
        if (rd_empty) $display("PASS: rd_empty asserted correctly after draining the FIFO");
        else begin
            $display("ERROR: rd_empty NOT asserted after draining the FIFO");
            errors++;
        end

        #100;
        if (errors == 0)
            $display("ASYNC_FIFO_PKT TEST PASSED");
        else
            $display("ASYNC_FIFO_PKT TEST FAILED (%0d error(s))", errors);

        $finish;
    end

endmodule
