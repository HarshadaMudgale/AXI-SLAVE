`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

import uvm_pkg::*;
`include "uvm_macros.svh"


interface axi_if(input logic clk, input logic rst_n);
  logic [3:0]  awaddr;
  logic        awvalid;
  logic        awready;
  logic [31:0] wdata;
  logic [3:0]  wstrb;
  logic        wvalid;
  logic        wready;
  logic [1:0]  bresp;
  logic        bvalid;
  logic        bready;
  logic [3:0]  araddr;
  logic        arvalid;
  logic        arready;
  logic [31:0] rdata;
  logic [1:0]  rresp;
  logic        rvalid;
  logic        rready;

  property p_awvalid_stable;
    @(posedge clk) disable iff (!rst_n)
    (awvalid && !awready) |=> awvalid;
  endproperty
  assert property(p_awvalid_stable) else $error("PROTOCOL VIOLATION: AWVALID dropped before AWREADY!");

  property p_wvalid_stable;
    @(posedge clk) disable iff (!rst_n)
    (wvalid && !wready) |=> wvalid;
  endproperty
  assert property(p_wvalid_stable) else $error("PROTOCOL VIOLATION: WVALID dropped before WREADY!");
endinterface

interface fifo_debug_if(input logic clk, input logic rst_n);
  logic        tx_fifo_wren;
  logic        tx_fifo_full;
  logic [31:0] tx_fifo_wdata;
  logic        rx_fifo_rden;
  logic        rx_fifo_empty;
  logic [31:0] rx_fifo_rdata;
  logic        spi_cs_n;
  logic        spi_sclk;
endinterface


class axi_seq_item extends uvm_sequence_item;
  `uvm_object_utils(axi_seq_item)

  rand bit [31:0] addr;
  rand bit [31:0] data;
  rand bit        is_write;

  constraint c_addr {
    addr inside {32'h0, 32'h4, 32'h8, 32'hC};
  }

  function new(string name = "axi_seq_item");
    super.new(name);
  endfunction
endclass



class base_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(base_seq)
  function new(input string name="base_seq"); super.new(name); endfunction

  task body();
    req = axi_seq_item::type_id::create("req");

    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h0; data == 32'h00000002;});
    finish_item(req);

    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h8; data == 32'hFF5A9FB1;});
    finish_item(req);

    #4000ns;

    start_item(req);
    assert(req.randomize() with {is_write == 0; addr == 32'hC;});
    finish_item(req);

    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h0; data == 32'h00000003;});
    finish_item(req);

    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h8; data == 32'h00000000;});
    finish_item(req);

    #4000ns;

    start_item(req);
    assert(req.randomize() with {is_write == 0; addr == 32'hC;});
    finish_item(req);
  endtask
endclass

// CORNER CASE: TX FIFO Full (Tests Backpressure)
class fifo_full_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(fifo_full_seq)
  function new(input string name="fifo_full_seq"); super.new(name); endfunction

  task body();
    for (int i = 0; i < 20; i++) begin
      req = axi_seq_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with {is_write == 1; addr == 32'h8;});
      finish_item(req);
    end
  endtask
endclass

// CORNER CASE: RX FIFO Full (Overflow) Sequence
class rx_fifo_full_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(rx_fifo_full_seq)
  function new(input string name="rx_fifo_full_seq"); super.new(name); endfunction

  task body();
    req = axi_seq_item::type_id::create("req");

    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h0; data == 32'h00000003;});
    finish_item(req);

    for (int i = 0; i < 18; i++) begin
      start_item(req);
      assert(req.randomize() with {is_write == 1; addr == 32'h8; data == (32'h4000 + i);});
      finish_item(req);
    end

    #15000ns;
  endtask
endclass

// CORNER CASE: Mid-Transaction Reset Recovery
class reset_recovery_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(reset_recovery_seq)
  function new(input string name="reset_recovery_seq"); super.new(name); endfunction

  task body();
    req = axi_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h8; data == 32'hDEADBEEF;});
    finish_item(req);
  endtask
endclass


class status_reg_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(status_reg_seq)
  function new(input string name="status_reg_seq"); super.new(name); endfunction

  task body();
    req = axi_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {is_write == 0; addr == 32'h4;});
    finish_item(req);

    req = axi_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h4; data == 32'hDEAD_0000;});
    finish_item(req);

    req = axi_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {is_write == 0; addr == 32'h4;});
    finish_item(req);
  endtask
endclass


class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)
  virtual axi_if vif;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", vif))
      `uvm_fatal("DRV", "Failed to get AXI VIF")
  endfunction

  task run_phase(uvm_phase phase);
    vif.awvalid <= 0; vif.wvalid <= 0; vif.arvalid <= 0; vif.bready <= 0; vif.rready <= 0;

    wait(vif.rst_n == 1'b1);
    @(posedge vif.clk);

    forever begin
      seq_item_port.get_next_item(req);
      if (req.is_write) drive_write(req);
      else              drive_read(req);
      seq_item_port.item_done();
    end
  endtask

  task drive_write(axi_seq_item item);
    @(posedge vif.clk);
    vif.awaddr <= item.addr; vif.wdata <= item.data; vif.wstrb <= 4'hF;
    vif.awvalid <= 1; vif.wvalid <= 1;
    wait(vif.awready && vif.wready);
    @(posedge vif.clk);
    vif.awvalid <= 0; vif.wvalid <= 0;
    vif.bready <= 1;
    wait(vif.bvalid);
    @(posedge vif.clk);
    vif.bready <= 0;
  endtask

  task drive_read(axi_seq_item item);
    @(posedge vif.clk);
    vif.araddr <= item.addr; vif.arvalid <= 1;
    wait(vif.arready);
    @(posedge vif.clk);
    vif.arvalid <= 0; vif.rready <= 1;
    wait(vif.rvalid);
    item.data = vif.rdata;
    @(posedge vif.clk);
    vif.rready <= 0;
  endtask
endclass

class axi_monitor extends uvm_monitor;
  `uvm_component_utils(axi_monitor)
  virtual axi_if vif;
  uvm_analysis_port #(axi_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", vif)) `uvm_fatal("MON", "No VIF")
  endfunction

  task run_phase(uvm_phase phase);
    axi_seq_item item;
    forever begin
      @(posedge vif.clk);
      if (vif.awvalid && vif.awready && vif.wvalid && vif.wready) begin
        item = axi_seq_item::type_id::create("item");
        item.is_write = 1; item.addr = vif.awaddr; item.data = vif.wdata;
        ap.write(item);
      end
      if (vif.rvalid && vif.rready) begin
        item = axi_seq_item::type_id::create("item");
        item.is_write = 0; item.addr = vif.araddr; item.data = vif.rdata;
        ap.write(item);
      end
    end
  endtask
endclass


class axi_coverage extends uvm_subscriber #(axi_seq_item);
  `uvm_component_utils(axi_coverage)
  virtual fifo_debug_if fifo_vif;

  bit [31:0] txn_addr;
  bit        txn_is_write;

  covergroup cg_fifo;
    option.per_instance = 1;
    cp_tx_full:  coverpoint fifo_vif.tx_fifo_full  { bins full = {1}; bins not_full = {0}; }
    cp_rx_empty: coverpoint fifo_vif.rx_fifo_empty { bins empty = {1}; bins not_empty = {0}; }
    cp_spi_cs:   coverpoint fifo_vif.spi_cs_n      { bins active = {0}; bins idle = {1}; }
    cx_full_cs:  cross cp_tx_full, cp_spi_cs;
  endgroup

  covergroup cg_txn;
    option.per_instance = 1;
    cp_addr: coverpoint txn_addr {
      bins ctrl   = {32'h0};
      bins status = {32'h4};
      bins txfifo = {32'h8};
      bins rxfifo = {32'hC};
    }
    cp_rw: coverpoint txn_is_write { bins wr = {1}; bins rd = {0}; }
    cross cp_addr, cp_rw;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_fifo = new();
    cg_txn  = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual fifo_debug_if)::get(this, "", "fifo_vif", fifo_vif))
      `uvm_fatal("COV", "No FIFO VIF")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge fifo_vif.clk);
      cg_fifo.sample();
    end
  endtask

  virtual function void write(axi_seq_item t);
    txn_addr = t.addr; txn_is_write = t.is_write;
    cg_txn.sample();
  endfunction
endclass

class axi_agent extends uvm_agent;
  `uvm_component_utils(axi_agent)
  axi_driver driver;
  axi_monitor monitor;
  uvm_sequencer #(axi_seq_item) sequencer;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver = axi_driver::type_id::create("driver", this);
    monitor = axi_monitor::type_id::create("monitor", this);
    sequencer = uvm_sequencer#(axi_seq_item)::type_id::create("sequencer", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

class axi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_seq_item, axi_scoreboard) axi_export;


  localparam int RX_FIFO_DEPTH = 16;

  bit [31:0] shadow_memory [int];
  bit [31:0] expected_rx_queue[$];

  int current_cmd  = 0;
  int current_addr = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    axi_export = new("axi_export", this);
  endfunction

  // Use only after a REAL hardware reset - control_reg and both FIFOs
  // genuinely go back to empty/0 in silicon.
  function void reset_model();
    expected_rx_queue.delete();
    shadow_memory.delete();
    current_cmd  = 0;
    current_addr = 0;
  endfunction

  virtual function void write(axi_seq_item item);
    if (item.is_write && item.addr == 32'h0) begin
       current_cmd  = item.data[0];
       current_addr = item.data[4:1];
    end

    if (item.is_write && item.addr == 32'h8) begin
 
       if (expected_rx_queue.size() < RX_FIFO_DEPTH) begin
         if (current_cmd == 0) begin
            shadow_memory[current_addr] = item.data;
            expected_rx_queue.push_back(32'h00000000);
         end else begin
            if (shadow_memory.exists(current_addr))
               expected_rx_queue.push_back(shadow_memory[current_addr]);
            else
               expected_rx_queue.push_back(32'h00000000);
         end
       end else if (current_cmd == 0) begin
        
         shadow_memory[current_addr] = item.data;
       end
    end

    if (!item.is_write && item.addr == 32'hC) begin
       if (expected_rx_queue.size() == 0) begin
         `uvm_info("SCBD", "AXI Read performed, queue is currently waiting for sync data.", UVM_LOW)
         return;
       end

       begin
         bit [31:0] exp_data = expected_rx_queue.pop_front();
         if (item.data === exp_data) begin
            `uvm_info("SCBD", $sformatf("PASS! Match found -> Exp: 0x%0h Act: 0x%0h", exp_data, item.data), UVM_NONE)
         end else begin
            `uvm_error("SCBD", $sformatf("MISMATCH! -> Exp: 0x%0h Act: 0x%0h", exp_data, item.data))
         end
       end
    end
  endfunction
endclass

class axi_env extends uvm_env;
  `uvm_component_utils(axi_env)
  axi_agent      m_agent;
  axi_scoreboard m_scb;
  axi_coverage   m_cov;

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_agent = axi_agent::type_id::create("m_agent", this);
    m_scb   = axi_scoreboard::type_id::create("m_scb", this);
    m_cov   = axi_coverage::type_id::create("m_cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    m_agent.monitor.ap.connect(m_scb.axi_export);
    m_agent.monitor.ap.connect(m_cov.analysis_export);
  endfunction
endclass


class bridge_verify_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(bridge_verify_seq)
  rand bit [3:0]  vaddr = 4'h2;
  rand bit [31:0] vdata = 32'hFEED_CAFE;
  function new(input string name="bridge_verify_seq"); super.new(name); endfunction

  task body();
    req = axi_seq_item::type_id::create("req");
    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h0; data == {27'd0, vaddr, 1'b0};});
    finish_item(req);

    start_item(req);
    assert(req.randomize() with {is_write == 1; addr == 32'h8; data == vdata;});
    finish_item(req);

    #4000ns;

    start_item(req);
    assert(req.randomize() with {is_write == 0; addr == 32'hC;});
    finish_item(req);
  endtask
endclass

class top_test extends uvm_test;
  `uvm_component_utils(top_test)
  axi_env env;
  virtual fifo_debug_if dbg_vif;  
  virtual axi_if        bus_vif; 
                                  
                               

  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi_env::type_id::create("env", this);
    if(!uvm_config_db#(virtual fifo_debug_if)::get(this, "", "fifo_vif", dbg_vif))
      `uvm_fatal("TEST", "Failed to get fifo_debug_if in top_test")
    if(!uvm_config_db#(virtual axi_if)::get(this, "", "axi_vif", bus_vif))
      `uvm_fatal("TEST", "Failed to get axi_if in top_test")
  endfunction

  task run_phase(uvm_phase phase);
    base_seq            seq1 = base_seq::type_id::create("seq1");
    fifo_full_seq        seq2 = fifo_full_seq::type_id::create("seq2");
    rx_fifo_full_seq     seq3 = rx_fifo_full_seq::type_id::create("seq3");
    reset_recovery_seq   seq4 = reset_recovery_seq::type_id::create("reset_recovery_seq");
    status_reg_seq       seq5 = status_reg_seq::type_id::create("seq5");     // NEW
    fifo_full_seq        fill_seq = fifo_full_seq::type_id::create("fill_seq"); // NEW
    bridge_verify_seq    vseq;

    phase.raise_objection(this);

    `uvm_info("TEST", "1. Running Basic Data Loopback...", UVM_NONE)
    seq1.start(env.m_agent.sequencer);
    #2000ns;

    `uvm_info("TEST", "1b. Running STATUS Register Coverage (addr 0x4)...", UVM_NONE)
    seq5.start(env.m_agent.sequencer);
    #500ns;

    `uvm_info("TEST", "2. Running TX FIFO Full Corner Case...", UVM_NONE)
    seq2.start(env.m_agent.sequencer);
    #3000ns;

  
    `uvm_info("TEST", "2b. Verifying design still functions after TX flood...", UVM_NONE)
    vseq = bridge_verify_seq::type_id::create("vseq2");
    vseq.vaddr = 4'h2; vseq.vdata = 32'hFEED_CAFE;
    vseq.start(env.m_agent.sequencer);
    #2000ns;

    `uvm_info("TEST", "3. Running RX FIFO Full Corner Case...", UVM_NONE)
    seq3.start(env.m_agent.sequencer);
    #3000ns;

    `uvm_info("TEST", "3b. Verifying design still functions after RX overflow attempt...", UVM_NONE)
    vseq = bridge_verify_seq::type_id::create("vseq3");
    vseq.vaddr = 4'h5; vseq.vdata = 32'hABCD_1234;
    vseq.start(env.m_agent.sequencer);
    #2000ns;

  
    `uvm_info("TEST", "4. Running Mid-Transaction Reset Recovery Test (guaranteed mid-backpressure)...", UVM_NONE)
    fork
      begin
        fill_seq.start(env.m_agent.sequencer);   // drives TX FIFO to full
      end
      begin
        wait(dbg_vif.tx_fifo_full == 1'b1);
        seq4.start(env.m_agent.sequencer);       // this write WILL stall
      end
      begin
        wait(bus_vif.awvalid && bus_vif.wvalid && !bus_vif.awready);
        #20ns;
        tb_top.rst_n = 0;
        #300ns;
        tb_top.rst_n = 1;
      end
    join

    env.m_scb.reset_model();  // a real reset genuinely clears control_reg
                              // and both FIFOs - this IS the right place
                              // (and the only place) to resync the model.
    `uvm_info("TEST", "4b. Verifying design still functions after reset recovery...", UVM_NONE)
    vseq = bridge_verify_seq::type_id::create("vseq4");
    vseq.vaddr = 4'h7; vseq.vdata = 32'h1357_9BDF;
    vseq.start(env.m_agent.sequencer);

    #2000ns;
    phase.drop_objection(this);
  endtask
endclass


module tb_top;
  logic clk_axi = 0;
  logic clk_spi = 0;
  logic rst_n = 0;

  always #5  clk_axi = ~clk_axi;   // 100 MHz
  always #50 clk_spi = ~clk_spi;   // 10 MHz

  axi_if        axi_vif(.clk(clk_axi), .rst_n(rst_n));
  fifo_debug_if fifo_vif(.clk(clk_axi), .rst_n(rst_n));

  top_spi_axi_fifo DUT (
      .s00_axi_aclk    (clk_axi),
      .s00_axi_aresetn (rst_n),
      .s00_axi_awaddr  (axi_vif.awaddr),
      .s00_axi_awvalid (axi_vif.awvalid),
      .s00_axi_awready (axi_vif.awready),
      .s00_axi_wdata   (axi_vif.wdata),
      .s00_axi_wstrb   (axi_vif.wstrb),
      .s00_axi_wvalid  (axi_vif.wvalid),
      .s00_axi_wready  (axi_vif.wready),
      .s00_axi_bresp   (axi_vif.bresp),
      .s00_axi_bvalid  (axi_vif.bvalid),
      .s00_axi_bready  (axi_vif.bready),
      .s00_axi_araddr  (axi_vif.araddr),
      .s00_axi_arvalid (axi_vif.arvalid),
      .s00_axi_arready (axi_vif.arready),
      .s00_axi_rdata   (axi_vif.rdata),
      .s00_axi_rresp   (axi_vif.rresp),
      .s00_axi_rvalid  (axi_vif.rvalid),
      .s00_axi_rready  (axi_vif.rready),
      .spi_clk         (clk_spi)
  );

  assign fifo_vif.tx_fifo_wren  = DUT.tx_fifo_wren;
  assign fifo_vif.tx_fifo_full  = DUT.tx_fifo_full;
  assign fifo_vif.tx_fifo_wdata = DUT.tx_fifo_wdata;
  assign fifo_vif.rx_fifo_rden  = DUT.rx_fifo_rden;
  assign fifo_vif.rx_fifo_empty = DUT.rx_fifo_empty;
  assign fifo_vif.rx_fifo_rdata = DUT.rx_fifo_rdata;
  assign fifo_vif.spi_cs_n      = DUT.spi_cs_n;
  assign fifo_vif.spi_sclk      = DUT.spi_sclk;

  initial begin
    rst_n = 0;
    #100 rst_n = 1;
  end

  initial begin
    uvm_config_db#(virtual axi_if)::set(null, "*", "axi_vif", axi_vif);
    uvm_config_db#(virtual fifo_debug_if)::set(null, "*", "fifo_vif", fifo_vif);
    run_test("top_test");
  end
endmodule