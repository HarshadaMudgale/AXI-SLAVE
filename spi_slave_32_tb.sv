`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:39:42
// Design Name: 
// Module Name: spi_slave_32_tb
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


module spi_slave_32_tb;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 4;

    logic RESET_N;
    logic SCLK;
    logic CS_N;
    logic MOSI;
    logic MISO;

    spi_slave_32 #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH))
    DUT (.RESET_N(RESET_N), .SCLK(SCLK), .CS_N(CS_N), .MOSI(MOSI), .MISO(MISO));

    initial begin
        SCLK = 0;
        forever #5 SCLK = ~SCLK;
    end

      task automatic transfer_word(input [DATA_WIDTH-1:0] tx_data, output [DATA_WIDTH-1:0] rx_data);
        integer i;
        begin
            for (i = DATA_WIDTH-1; i >= 0; i = i - 1) begin
                @(negedge SCLK);
                MOSI = tx_data[i];
                @(posedge SCLK);
                rx_data[i] = MISO;
            end
        end
    endtask

    task automatic do_transaction(input bit cmd, input [ADDR_WIDTH-1:0] addr,
                                   input [DATA_WIDTH-1:0] wdata, output [DATA_WIDTH-1:0] rdata);
        logic [DATA_WIDTH-1:0] header, dummy_rx;
        begin
            header = {{(DATA_WIDTH-ADDR_WIDTH-1){1'b0}}, cmd, addr};

            CS_N = 0;
            transfer_word(header, dummy_rx);
            #1;  
	    CS_N = 1;
            #10;  
	    CS_N = 0;
            transfer_word(wdata, rdata);   
            #1;
            CS_N = 1;
        end
    endtask

    logic [DATA_WIDTH-1:0] readback;
    integer errors = 0;

    initial begin
        RESET_N = 0;
        CS_N    = 1;
        MOSI    = 0;
        #20;
        RESET_N = 1;
        #20;

                $display("WRITE OPERATION");
        do_transaction(1'b0, 4'h3, 32'hA5A5_1234, readback);
        #10;
        if (DUT.memory[4'h3] === 32'hA5A5_1234)
            $display("PASS: memory[3] = %h", DUT.memory[4'h3]);
        else begin
            $display("FAIL: memory[3] = %h, expected A5A51234", DUT.memory[4'h3]);
            errors++;
        end
        #50;

         	$display("READ OPERATION");
        do_transaction(1'b1, 4'h3, 32'h0000_0000, readback);
        if (readback === 32'hA5A5_1234)
            $display("PASS: read data = %h", readback);
        else begin
            $display("FAIL: read data = %h, expected A5A51234", readback);
            errors++;
        end

        #100;
        if (errors == 0) 
	    $display(" spi_slave_32 UNIT TEST PASSED ");
        else             
	    $display(" spi_slave_32 UNIT TEST FAILED (%0d error(s)) ", errors);
        $finish;
    end

    initial begin
        $monitor("TIME=%0t RESET=%b CS=%b MOSI=%b MISO=%b word_phase=%b cmd_bit=%b tgt_addr=%h",
                 $time, RESET_N, CS_N, MOSI, MISO, DUT.word_phase, DUT.cmd_bit, DUT.tgt_addr);
    end

endmodule