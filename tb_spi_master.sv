`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:41:30
// Design Name: 
// Module Name: tb_spi_master
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


module tb_spi_master();
    logic clk_spi;
    logic rst_n;
    
    
    logic tx_fifo_empty;
    logic tx_fifo_rd_en;
    logic [31:0] tx_fifo_data;
    
    
    logic rx_fifo_full;
    logic rx_fifo_wr_en;
    logic [31:0] rx_fifo_data;
    
    
    logic spi_cs_n;
    logic spi_sclk;
    logic spi_mosi;
    logic spi_miso;

    
    spi_master DUT (
        .clk_spi(clk_spi),
        .rst_n(rst_n),
        .tx_fifo_empty(tx_fifo_empty),
        .tx_fifo_rd_en(tx_fifo_rd_en),
        .tx_fifo_data(tx_fifo_data),
        .rx_fifo_full(rx_fifo_full),
        .rx_fifo_wr_en(rx_fifo_wr_en),
        .rx_fifo_data(rx_fifo_data),
        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso)
    );

    
    always #5 clk_spi = ~clk_spi;

    
    logic [31:0] slave_tx_data = 32'hDEADBEEF; 
    logic [31:0] slave_rx_data = 32'h0;       
    
   
    assign spi_miso = (!spi_cs_n) ? slave_tx_data[31] : 1'bz;

    
    always_ff @(negedge spi_sclk or posedge spi_cs_n) begin
        if (spi_cs_n) begin
            slave_tx_data <= 32'hDEADBEEF; 
        end else begin
            slave_tx_data <= {slave_tx_data[30:0], 1'b0}; 
        end
    end

    
    always_ff @(posedge spi_sclk) begin
        if (!spi_cs_n) begin
            slave_rx_data <= {slave_rx_data[30:0], spi_mosi};
        end
    end
    
  
    
    always_ff @(posedge clk_spi) begin
        if (tx_fifo_rd_en) begin
            tx_fifo_empty <= 1'b1; 
        end
    end

    
    initial begin
        
        clk_spi = 0;
        rst_n = 0;
        tx_fifo_empty = 1;
        tx_fifo_data  = '0;
        rx_fifo_full  = 0;
        
        
        $display("Starting SPI Master Simulation");
      
        #20 rst_n = 1;
        #20;

        $display("[%0t] AXI side wrote 32'hA5A5C3C3 into TX FIFO.", $time);
        tx_fifo_data  = 32'hA5A5C3C3;
        tx_fifo_empty = 0; 

        
        wait (rx_fifo_wr_en == 1'b1);
        
        
        @(posedge clk_spi); 
        
       
        $display("[%0t] Transaction Complete!", $time);
        
        if (rx_fifo_data == 32'hDEADBEEF) begin
            $display("SUCCESS: Master RX FIFO successfully received 32'h%h from Slave.", rx_fifo_data);
        end else begin
            $display("ERROR: Master RX FIFO received 32'h%h, expected 32'hDEADBEEF.", rx_fifo_data);
        end

        if (slave_rx_data == 32'hA5A5C3C3) begin
            $display("SUCCESS: Slave successfully received 32'h%h from Master TX FIFO.", slave_rx_data);
        end else begin
            $display("ERROR: Slave received 32'h%h, expected 32'hA5A5C3C3.", slave_rx_data);
        end

        
        #100;
  
        $display("Simulation Finished");
        $finish;
    end

endmodule

