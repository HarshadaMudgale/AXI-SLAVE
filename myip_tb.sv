`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:45:30
// Design Name: 
// Module Name: myip_tb
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


module myip_tb;

  
  localparam int ADDR_WIDTH=4;
  localparam int DATA_WIDTH=32;
  localparam logic [3:0] BASE_ADDR=4'h0;   
  localparam int NUM_TXN=4;

  logic clk;
  logic aresetn;
  logic start;
  logic error;
  logic done;

  logic [3:0] awaddr;
  logic [2:0] awprot;
  logic awvalid;
  logic awready;

  logic [31:0] wdata;
  logic [3:0] wstrb;
  logic wvalid;
  logic wready;

  logic [1:0]  bresp;
  logic bvalid;
  logic bready;   

  logic [3:0] araddr;
  logic [2:0] arprot;
  logic arvalid;
  logic arready;

  logic [31:0] rdata;
  logic [1:0] rresp;
  logic rvalid;
  logic rready;
 
  myip #(
      .C_M00_AXI_ADDR_WIDTH (ADDR_WIDTH),
      .C_M00_AXI_DATA_WIDTH (DATA_WIDTH),
      .C_M00_AXI_TARGET_SLAVE_BASE_ADDR(BASE_ADDR),
      .C_M00_AXI_TRANSACTIONS_NUM (NUM_TXN)
  ) DUT (
      .m00_axi_init_axi_txn (start),
      .m00_axi_error (error),
      .m00_axi_txn_done (done),
      .m00_axi_aclk (clk),
      .m00_axi_aresetn (aresetn),

      .m00_axi_awaddr (awaddr),
      .m00_axi_awprot (awprot),
      .m00_axi_awvalid (awvalid),
      .m00_axi_awready (awready),

      .m00_axi_wdata (wdata),
      .m00_axi_wstrb (wstrb),
      .m00_axi_wvalid (wvalid),
      .m00_axi_wready (wready),

      .m00_axi_bresp (bresp),
      .m00_axi_bvalid (bvalid),
      .m00_axi_bready (bready),

      .m00_axi_araddr (araddr),
      .m00_axi_arprot (arprot),
      .m00_axi_arvalid (arvalid),
      .m00_axi_arready (arready),

      .m00_axi_rdata (rdata),
      .m00_axi_rresp (rresp),
      .m00_axi_rvalid (rvalid),
      .m00_axi_rready (rready)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  logic [31:0] mem [0:15];

  function automatic int addr_to_index(input logic [3:0] addr);
    addr_to_index = (addr - BASE_ADDR) >> 2;
  endfunction

  logic [3:0] cap_awaddr;
  logic [31:0] cap_wdata;
  logic [3:0] cap_araddr;

  task automatic write_addr();
    begin
      do @(posedge clk); while (!awready);
      awvalid = 1'b1;
      awprot = 3'b000;
      @(posedge clk);                 
      cap_awaddr = awaddr;
      awvalid = 1'b0;
      $display("[%0t] WRITE_ADDR   addr=0x%01h", $time, cap_awaddr);
    end
  endtask

  task automatic write_data();
    begin
      do @(posedge clk); while (!wready);
      wvalid = 1'b1;
      wstrb = 4'b1111;
      @(posedge clk);                 
      cap_wdata = wdata;
      wvalid = 1'b0;
      $display("[%0t] WRITE_DATA   data=0x%08h", $time, cap_wdata);
    end
  endtask

  task automatic write_resp();
    begin
      mem[addr_to_index(cap_awaddr)] = cap_wdata;

      bready = 1'b1;
      wait (bvalid);
      bresp  = 2'b00;                 
      @(posedge clk);
      bready = 1'b0;
    end
  endtask

  task automatic read_addr();
    begin
      do @(posedge clk); while (!arready);
      arvalid = 1'b1;
      arprot = 3'b000;
      @(posedge clk);               
      cap_araddr = araddr;
      arvalid = 1'b0;
      $display("[%0t] READ_ADDR    addr=0x%01h", $time, cap_araddr);
    end
  endtask

  task automatic read_data();
    begin
      rdata  = mem[addr_to_index(cap_araddr)];
      rresp  = 2'b00;                 
      rready = 1'b1;
      $display("[%0t] READ_DATA    data=0x%08h", $time, rdata);

      wait (rvalid);
      @(posedge clk);
      rready = 1'b0;
    end
  endtask

  initial begin : SLAVE_PROC
    awready = 1'b0;
    wready  = 1'b0;
    bvalid  = 1'b0;
    bresp   = 2'b00;
    arready = 1'b0;
    rvalid  = 1'b0;
    rresp   = 2'b00;
    rdata   = '0;

    wait (aresetn == 1'b1);

    repeat (NUM_TXN) begin
      fork
        write_addr();
        write_data();
      join
      write_resp();
    end

    repeat (NUM_TXN) begin
      read_addr();
      read_data();
    end
  end

  initial begin : STIMULUS_PROC
    aresetn = 1'b0;
    start   = 1'b0;

    repeat (4) @(posedge clk);
    aresetn = 1'b1;
    repeat (2) @(posedge clk);

    start = 1'b1;
    @(posedge clk);
    start = 1'b0;

    wait (done == 1'b1);
    @(posedge clk);

    if (error)
      $display("[%0t] TEST FAILED  - master flagged ERROR", $time);
    else
      $display("[%0t] TEST PASSED  - %0d writes/%0d reads matched, ERROR=0", $time, NUM_TXN, NUM_TXN);

    repeat (5) @(posedge clk);
    $finish;
  end

  initial begin
    #5000;
    $display("[%0t] TIMEOUT - TXN_DONE never asserted, check handshake", $time);
    $finish;
  end

endmodule
