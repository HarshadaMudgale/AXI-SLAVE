`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 15:52:09
// Design Name: 
// Module Name: tb_spi2axi_deframer
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


module tb_spi2axi_deframer;

    logic clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk;

    logic mst_rx_wr_en;
    logic [31:0] mst_rx_data;
    logic mst_rx_full;
    logic fifo_wr_en;
    logic [31:0] fifo_wr_data;
    logic fifo_wr_full;

    assign fifo_wr_full = 1'b0; 

    spi2axi_deframer DUT (
        .clk(clk), 
	.rst_n(rst_n),
        .mst_rx_wr_en(mst_rx_wr_en), 
	.mst_rx_data(mst_rx_data),
       	.mst_rx_full(mst_rx_full),
        .fifo_wr_en(fifo_wr_en), 
	.fifo_wr_data(fifo_wr_data),
       	.fifo_wr_full(fifo_wr_full)
    );

    
    logic [31:0] forwarded [0:7];
    integer fwd_idx;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fwd_idx <= 0;
        end else if (fifo_wr_en && fwd_idx < 8) begin
            forwarded[fwd_idx] <= fifo_wr_data;
            fwd_idx <= fwd_idx + 1;
        end
    end

    
    logic [31:0] junk_words [0:2] = '{32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
    logic [31:0] data_words [0:2] = '{32'h1111_1111, 32'h2222_2222, 32'h3333_3333};

    integer errors = 0;

    task automatic push_word(input [31:0] w);
        begin
            @(posedge clk);
            #1;                 
                                                     
            mst_rx_wr_en = 1'b1;
            mst_rx_data  = w;
            @(posedge clk);       
                            
            #1;
            mst_rx_wr_en = 1'b0;
        end
    endtask

    initial begin
        rst_n = 0;
        mst_rx_wr_en = 0;
        mst_rx_data  = 0;
        #12;
        rst_n = 1;
        #10;

        for (int t = 0; t < 3; t++) begin
            push_word(junk_words[t]);
            push_word(data_words[t]);
        end

        #20;

        if (fwd_idx !== 3) begin
            $display("FAIL: expected 3 forwarded words, got %0d", fwd_idx);
            errors++;
        end else begin
            $display("PASS: exactly 3 words forwarded (one per transaction)");
        end

        for (int t = 0; t < 3 && t < fwd_idx; t++) begin
            if (forwarded[t] !== data_words[t]) begin
                $display("FAIL: forwarded[%0d] = %h, expected %h", t, forwarded[t], data_words[t]);
                errors++;
            end else begin
                $display("PASS: forwarded[%0d] = %h", t, forwarded[t]);
            end
        end

        if (errors == 0) $display(" spi2axi_deframer UNIT TEST PASSED ");
        else $display(" spi2axi_deframer UNIT TEST FAILED (%0d error(s)) ", errors);
        $finish;
    end

endmodule
