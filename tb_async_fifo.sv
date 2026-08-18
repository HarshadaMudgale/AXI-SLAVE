`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:34:49
// Design Name: 
// Module Name: tb_async_fifo
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


module tb_async_fifo;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 4;              
    localparam DEPTH = (1 << ADDR_WIDTH);

    logic wr_clk, wr_rst_n, wr_en, full;
    logic [DATA_WIDTH-1:0] wr_data;

    logic rd_clk, rd_rst_n, rd_en, empty;
    logic [DATA_WIDTH-1:0] rd_data;

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) DUT (
        .wr_clk(wr_clk), .wr_rst_n(wr_rst_n), .wr_en(wr_en), .wr_data(wr_data), .wr_full(full),
        .rd_clk(rd_clk), .rd_rst_n(rd_rst_n), .rd_en(rd_en), .rd_data(rd_data), .rd_empty(empty)
    );

    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;

    initial rd_clk = 0;
    always #7 rd_clk = ~rd_clk;

    logic [DATA_WIDTH-1:0] expected_q [0:DEPTH-1];
    integer errors = 0;

    event fill_done;

       initial begin
        wr_rst_n = 0;
        wr_en = 0;
        wr_data  = '0;
        repeat (3) @(posedge wr_clk);
        wr_rst_n = 1;

        $display("Filling FIFO with %0d words", DEPTH);
        for (int i = 0; i < DEPTH; i++) begin
            @(negedge wr_clk);
            wr_data = i;
            expected_q[i] = i;
            wr_en = 1'b1;
            @(negedge wr_clk);
            wr_en = 1'b0;
        end

        @(negedge wr_clk);
        if (full) $display("PASS: full asserted correctly after %0d writes", DEPTH);
        else begin
            $display("ERROR: full NOT asserted after filling FIFO");
            errors++;
        end

        wr_data = 32'hFFFF_FFFF;
        wr_en = 1'b1;
        @(negedge wr_clk);
        wr_en = 1'b0;

        -> fill_done;   
       end

        initial begin
        rd_rst_n = 0;
        rd_en = 0;
        repeat (3) @(posedge rd_clk);
        rd_rst_n = 1;

        @(fill_done);   
	$display("Draining FIFO");

        for (int i = 0; i < DEPTH; i++) begin
            @(negedge rd_clk);
            while (empty) @(negedge rd_clk);
            if (rd_data !== expected_q[i]) begin
                $display("ERROR: word %0d mismatch. Expected %h, Got %h", i, expected_q[i], rd_data);
                errors++;
            end else begin
                $display("PASS: word %0d = %h", i, rd_data);
            end
            rd_en = 1'b1;
            @(negedge rd_clk);
            rd_en = 1'b0;
        end

        @(negedge rd_clk);
        if (empty) $display("PASS: empty asserted correctly after draining FIFO");
        else begin
            $display("ERROR: empty NOT asserted after draining FIFO");
            errors++;
        end

        #100;
        if (errors == 0)
            $display(" ASYNC FIFO TEST PASSED ");
        else
            $display(" ASYNC FIFO TEST FAILED (%0d error(s)) ", errors);
        $finish;
    end

endmodule
