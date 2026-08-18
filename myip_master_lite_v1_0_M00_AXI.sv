`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2026 12:44:00
// Design Name: 
// Module Name: myip_master_lite_v1_0_M00_AXI
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


	module myip_master_lite_v1_0_M00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// The master will start generating data from the C_M_START_DATA_VALUE value
		parameter  C_M_START_DATA_VALUE	= 32'hAA000000,
		// The master requires a target slave base address.
    // The master will initiate read and write transactions on the slave with base address specified here as a parameter.
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 4'h0,
		// Width of M_AXI address bus. 
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		parameter int C_M_AXI_ADDR_WIDTH	= 4,
		// Width of M_AXI data bus. 
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		parameter int C_M_AXI_DATA_WIDTH	= 32,
		// Transaction number is the number of write 
    // and read transactions the master will perform as a part of this example memory test.
		parameter int C_M_TRANSACTIONS_NUM	= 4
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Initiate AXI transactions
		input logic  INIT_AXI_TXN,
		// Asserts when ERROR is detected
		output logic  ERROR,
		// Asserts when AXI transactions is complete
		output logic  TXN_DONE,
		// AXI clock signal
		input logic  M_AXI_ACLK,
		// AXI active low reset signal
		input logic  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output logic [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
		output logic [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
		output logic  M_AXI_AWVALID,
		// Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input logic  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output logic [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
		output logic [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output logic  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input logic  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
		input logic [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
		input logic  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output logic  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output logic [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    // This signal indicates the privilege and security level of the transaction, 
    // and whether the transaction is a data access or an instruction access.
		output logic [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
		output logic  M_AXI_ARVALID,
		// Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input logic  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input logic [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input logic [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input logic  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output logic  M_AXI_RREADY
	);

	// function called clogb2 that returns an integer which has the
	// value of the ceiling of the log base 2

	 function integer clogb2 (input integer bit_depth);
		 begin
		 for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			 bit_depth = bit_depth >> 1;
		 end
	 endfunction

	// TRANS_NUM_BITS is the width of the index counter for 
	// number of write or read transaction.
	 localparam integer TRANS_NUM_BITS = clogb2(C_M_TRANSACTIONS_NUM-1);

	// Example State machine to initialize counter, initialize write transactions, 
	// initialize read transactions and comparison of read data with the 
	// written data words.
	localparam [1:0] IDLE = 2'b00, // This state initiates AXI4Lite transaction 
			// after the state machine changes state to INIT_WRITE   
			// when there is 0 to 1 transition on INIT_AXI_TXN
		INIT_WRITE   = 2'b01, // This state initializes write transaction,
			// once writes are done, the state machine 
			// changes state to INIT_READ 
		INIT_READ = 2'b10, // This state initializes read transaction
			// once reads are done, the state machine 
			// changes state to INIT_COMPARE 
		INIT_COMPARE = 2'b11, // This state issues the status of comparison 
			// of the written data with the read data	
	  	WADDR = 2'b10, // This state initializes write address transaction 
	                      // once it is are done, the state machine 
	                    // changes state to WDATA 
	        WDATA = 2'b11, // This state issues the write data to slave 
	                   // once the write data is transferred to slave, state 
	                   // changes state to WADDR
	        RADDR = 2'b10, // This state initializes read address transaction
	                     // once it is are done, the state machine 
	                        // changes state to RDATA 
	        RDATA = 2'b11; // This state receives the read data from slave 
	                     // once the read data is transferred from slave, state 
	                    // changes state to WADDR 

	 logic [1:0] mst_exec_state;

	 logic [1:0] state_write;

	 logic [1:0] state_read;

	// AXI4LITE signals
	//write address valid
	logic  	axi_awvalid;
	//write data valid
	logic  	axi_wvalid;
	//read address valid
	logic  	axi_arvalid;
	//read data acceptance
	logic  	axi_rready;
	//write response acceptance
	logic  	axi_bready;
	//write address
	logic [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	//write data
	logic [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
	//read addresss
	logic [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	//Asserts when there is a write response error
	logic  	write_resp_error;
	//Asserts when there is a read response error
	logic  	read_resp_error;
	//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
	logic  	writes_done;
	//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
	logic  	reads_done;
	//The error register is asserted when any of the write response error, read response error or the data mismatch flags are asserted.
	logic  	error_reg;
	//index counter to track the number of write transaction issued
	logic [TRANS_NUM_BITS : 0] 	write_index;
	//index counter to track the number of read transaction issued
	logic [TRANS_NUM_BITS : 0] 	read_index;
	//Expected read data used to compare with the read data.
	logic [C_M_AXI_DATA_WIDTH-1 : 0] 	expected_rdata;
	//Flag marks the completion of comparison of the read data with the expected read data
	logic  	compare_done;
	//This flag is asserted when there is a mismatch of the read data with the expected read data.
	logic  	read_mismatch;
	//Flag is asserted when the write index reaches the last write transction number
	logic  	last_write;
	//Flag is asserted when the read index reaches the last read transction number
	logic  	last_read;
	logic  	init_txn_ff;
	logic  	init_txn_ff2;
	logic  	init_txn_edge;
	logic  	init_txn_pulse;


	// I/O Connections assignments

	//Adding the offset address to the base addr of the slave
	assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr;
	//AXI 4 write data
	assign M_AXI_WDATA	= axi_wdata;
	assign M_AXI_AWPROT	= 3'b000;
	assign M_AXI_AWVALID	= axi_awvalid;
	//Write Data(W)
	assign M_AXI_WVALID	= axi_wvalid;
	//Set all byte strobes in this example
	assign M_AXI_WSTRB	= 4'b1111;
	//Write Response (B)
	assign M_AXI_BREADY	= axi_bready;
	//Read Address (AR)
	assign M_AXI_ARADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_araddr;
	assign M_AXI_ARVALID	= axi_arvalid;
	assign M_AXI_ARPROT	= 3'b001;
	//Read and Read Response (R)
	assign M_AXI_RREADY	= axi_rready;
	//Example design I/O
	assign TXN_DONE	= compare_done;
	assign init_txn_pulse	= (!init_txn_ff2) && init_txn_ff;
	always @(posedge M_AXI_ACLK)										      
	  begin 
	    if (M_AXI_ARESETN == 0 )                                                   
	      begin                                                                    
	        init_txn_ff <= 1'b0;                                                   
	        init_txn_ff2 <= 1'b0;                                                   
	      end                                                                               
	    else                                                                       
	      begin  
	        init_txn_ff <= INIT_AXI_TXN;
	        init_txn_ff2 <= init_txn_ff;                                                                 
	      end                                                                      
	  end     


	  always @(posedge M_AXI_ACLK)										      
	  begin                                                                        
	    if (M_AXI_ARESETN == 0 || init_txn_pulse)                                                   
	      begin                                                                    
	        axi_awvalid <= 1'b0;                                                   
	        axi_awaddr <= 1'b0;                                                   
	        axi_wvalid <= 1'b0;                                                   
	        write_index <= 0;                                                   
	        axi_wdata <= C_M_START_DATA_VALUE;                                                   
	        axi_bready <= 1'b0;                                                   
	        if (init_txn_pulse) state_write <= IDLE;                                                    
	      end                                                                      
	    else                                                                       
	      begin                                                                    
	        case(state_write)                                                
	          IDLE:                                                                
	            begin                                               
	              if (init_txn_pulse == 0 && mst_exec_state == INIT_WRITE)                                                                  
	                begin                                                          
	                  axi_awvalid <= 1;                                            
	                  axi_wvalid <= 1;                                             
	                  state_write <= WADDR;                                             
	                end                                             
	              else                                             
	                begin                                             
	                  state_write <= state_write;                                             
	                  if (M_AXI_BVALID && axi_bready) axi_bready <= 0;                                             
	                end                                             
	           end                                             
	         WADDR: 
	           begin										      
	             if (M_AXI_AWREADY && axi_awvalid)										      
	               begin										      
	                 axi_awaddr <= axi_awaddr + 4'h4;										      
	                 axi_wvalid <= 1;										      
	                 if (M_AXI_WREADY && (write_index == C_M_TRANSACTIONS_NUM-1))										      
	                   begin										      
	                     axi_awvalid <= 0;										      
	                     axi_wvalid <= 0;										      
	                     axi_bready <= 1;										      
	                     axi_wdata <= C_M_START_DATA_VALUE;										      
	                     write_index <= 0;										      
	                     state_write <= IDLE;										      
	                   end										      
	                 else if (M_AXI_WREADY)										      
	                   begin										      
	                     axi_awvalid <= 1;										      
	                     axi_bready <= 1;										      
	                     axi_wdata <= axi_wdata + 1;										      
	                     write_index <= write_index + 1;										      
	                     state_write <= WADDR;										      
	                   end										      
	                 else										      
	                   begin										      
	                     axi_awvalid <= 0;										      
	                     axi_bready <= 0;										      
	                     axi_wdata <= axi_wdata;										      
	                     state_write <= WDATA;										      
	                   end										      
	               end										      
	             else										      
	               begin										      
	                  if (axi_bready && M_AXI_BVALID) axi_bready <= 0;										      
	                    state_write <= state_write;										      
	               end										      
	           end										      
	         WDATA:  
	           begin										      
	             if (M_AXI_WREADY && (write_index == C_M_TRANSACTIONS_NUM-1))										      
	               begin										      
	                 axi_awvalid <= 0;										      
	                 axi_wvalid <= 0;										      
	                 axi_bready <= 1;										      
	                 axi_wdata <= C_M_START_DATA_VALUE;										      
	                 write_index <= 0;										      
	                 state_write <= IDLE;										      
	               end										      
	             else if (axi_wvalid && M_AXI_WREADY)										      
	               begin										      
	                 axi_wdata <= axi_wdata + 1;										      
	                 axi_wvalid <= 1;										      
	                 axi_awvalid <= 1;										      
	                 write_index <= write_index + 1;										      
	                 axi_bready <= 1;										      
	                 state_write <= WADDR;										      
	               end										      
	           end										      
	        endcase										      
	      end										      
	      end										                                            
	assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);
	  always @(posedge M_AXI_ACLK)                                                     
	    begin                                                     
	      if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                                              
	        begin                                                                                                               
	          axi_arvalid <= 1'b0;                                                     
	          axi_rready <= 1'b0;                                                        
	          axi_araddr <= 0;                                                     
	          read_index <= 0;                                                     
	          if (init_txn_pulse) state_read <=  IDLE;                                                                                     
	        end                                                                                                                          
	      else                                                     
	        begin                                                     
	          case(state_read)                                                     
	            IDLE:                                                     
	              begin                                                     
	                if (init_txn_pulse == 0 && mst_exec_state == INIT_READ)                                                     
	                  begin                                                     
	                    axi_arvalid <= 1;                                                     
	                    state_read <= RADDR;                                                     
	                  end                                                     
	                else state_read <= state_read;                                                     
	              end                                                     
	            RADDR:
	              begin                                                       
	                if(axi_arvalid && M_AXI_ARREADY)                                                       
	                  begin                                                       
	                    axi_arvalid <= 0;                                                       
	                    axi_rready <= 1;                                                       
	                    axi_araddr <= axi_araddr + 4'h4;                                                        
	                    state_read <= RDATA;                                                       
	                  end                                                       
	                else state_read <= state_read;                                                       
	              end                                                       
	            RDATA: 
	              begin                                                     
	                if (axi_rready && M_AXI_RVALID && mst_exec_state != INIT_READ)                                                     
	                  begin                                                     
	                    axi_arvalid <= 0;                                                     
	                    axi_rready <= 0;                                                     
	                    read_index <= 0;                                                     
	                    state_read <= IDLE;                                                     
	                  end                                                     
	                else if (axi_rready && M_AXI_RVALID)                                                     
	                  begin                                                     
	                    axi_arvalid <= 1;                                                     
	                    axi_rready <= 0;                                                     
	                    read_index <= read_index + 1;                                                     
	                    state_read <= RADDR;                                                     
	                  end                                                     
	              end                                                     
	           endcase                                                     
	         end                                                                                   
	       end                                                          
	assign read_resp_error = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]);  


	//--------------------------------
	//User Logic
	//--------------------------------

	//Address/Data Stimulus

	//Address/data pairs for this example. The read and write values should
	//match.
	//Modify these as desired for different address patterns.
                  
	  always @(posedge M_AXI_ACLK)                                  
	      begin                                                     
	        if (M_AXI_ARESETN == 0  || init_txn_pulse == 1'b1)                                
	          begin                                                 
	            expected_rdata <= C_M_START_DATA_VALUE;             
	          end                                                 
	        else if (M_AXI_RVALID && axi_rready)                    
	          begin                                                 
	            expected_rdata <= C_M_START_DATA_VALUE + read_index + 1;
	          end                                                   
	      end                                                                  
	  always @ ( posedge M_AXI_ACLK)                                                    
	  begin                                                                             
	    if (M_AXI_ARESETN == 1'b0)                                                     
	      begin                                                                    
	        mst_exec_state  <= IDLE;                                            
	        compare_done  <= 1'b0;                                                      
	        ERROR <= 1'b0;
	      end                                                                           
	    else                                                                            
	      begin                                                                        
	        case (mst_exec_state)                                                     
	          IDLE:                                            
	            if ( init_txn_pulse == 1'b1 )                                     
	              begin                                                                 
	                mst_exec_state  <= INIT_WRITE;                                      
	                ERROR <= 1'b0;
	                compare_done <= 1'b0;
	              end                                                                   
	            else                                                                    
	              begin                                                                 
	                mst_exec_state  <= IDLE;                                    
	              end                                                                
	          INIT_WRITE:                                                             
	            if (writes_done)                                                        
	              begin                                                                 
	                mst_exec_state <= INIT_READ;//                                      
	              end                                                                   
	            else                                                                    
	              begin                                                                 
	                mst_exec_state  <= INIT_WRITE;   	                                                                                    
	              end                                                                 
	          INIT_READ:                                                         
	             if (reads_done)                                                        
	               begin                                                                
	                 mst_exec_state <= INIT_COMPARE;                                    
	               end                                                                  
	             else                                                                   
	               begin                                                                
	                 mst_exec_state  <= INIT_READ;                                                                 
	               end                                                                         
	           INIT_COMPARE:                                                            
	             begin       
	                 ERROR <= error_reg; 
	                 mst_exec_state <= IDLE;                                    
	                 compare_done <= 1'b1;                                              
	             end                                                                  
	           default :                                                                
	             begin                                                                  
	               mst_exec_state  <= IDLE;                                     
	             end                                                                    
	        endcase                                                                     
	    end                                                                             
	  end                                        
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
	      writes_done <= 1'b0;                                                        
	    else if ((write_index == C_M_TRANSACTIONS_NUM-1) && M_AXI_BVALID && axi_bready)                              
	      writes_done <= 1'b1;                                                          
	    else                                                                            
	      writes_done <= writes_done;                                                   
	  end                                                                      
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
	      reads_done <= 1'b0;                                                        
	    else if ((read_index == C_M_TRANSACTIONS_NUM-2) && M_AXI_RVALID && axi_rready)                               
	      reads_done <= 1'b1;                                                           
	    else                                                                            
	      reads_done <= reads_done;                                                     
	    end                                                                           
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0  || init_txn_pulse == 1'b1)                                                         
	    read_mismatch <= 1'b0;                                                          
	                                                                                   
	    //The read data when available (on axi_rready) is compared with the expected data
	    else if ((M_AXI_RVALID && axi_rready) && (M_AXI_RDATA != expected_rdata))         
	      read_mismatch <= 1'b1;                                                        
	    else                                                                            
	      read_mismatch <= read_mismatch;                                               
	  end                                                                               
	                                                                                    
	// Register and hold any data mismatches, or read/write interface errors            
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0  || init_txn_pulse == 1'b1)                                                         
	      error_reg <= 1'b0;                                                            
	                                                                                    
	    //Capture any error types                                                       
	    else if (read_mismatch || write_resp_error || read_resp_error)                  
	      error_reg <= 1'b1;                                                            
	    else                                                                            
	      error_reg <= error_reg;                                                       
	  end                                                                               
	// Add user logic here

//ADDING SIGNALS
logic [31:0] user_wr_data;
logic [31:0] user_rd_data;
logic [3:0] user_addr;
logic write_done;
logic read_done;
logic COMPARE;

//INITIALIZING SIGNALS
always @(posedge M_AXI_ACLK)
begin
 if(!M_AXI_ARESETN)
 begin
      user_wr_data <= 32'h12345678;
      user_addr    <= 4'h0;
      write_done <=0;
      read_done<=0;
 end
end
//WRITE LOGIC
always @(posedge M_AXI_ACLK)
begin
 if(M_AXI_BVALID && axi_bready)
 begin
      write_done <=1;
 end
end

//READ LOGIC
always @(posedge M_AXI_ACLK)
begin
 if(M_AXI_RVALID && axi_rready)
 begin
      user_rd_data <= M_AXI_RDATA;
      read_done<=1;
 end
end
//COMPARISON OF WRITE DATA AND READ DATA
always @(posedge M_AXI_ACLK)
begin

 if(read_done)
 begin
     if(user_rd_data==user_wr_data)
         COMPARE<=0;
     else
         COMPARE<=1;
 end
end
	// User logic ends

endmodule
