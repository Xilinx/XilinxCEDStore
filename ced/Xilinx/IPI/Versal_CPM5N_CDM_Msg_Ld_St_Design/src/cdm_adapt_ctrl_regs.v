`timescale 1 ps / 1 ps



//Rev-4//

//provides seed for MSGLD engine and gets MSGLD received pkt pass/fail counts

//Added ST2M & M2ST registers also



module cdm_adapt_ctrl_regs #

(

	// Width of S_AXI data bus

	parameter integer C_S_AXI_DATA_WIDTH	= 32,

	// Width of S_AXI address bus

	parameter integer C_S_AXI_ADDR_WIDTH	= 10

)

(
  //
  output reg    [31:0]global_start,

  //R/W regsiter

  output reg 	[31:0] msg_ctrl_reg_0,

  output reg 	[31:0] msg_ctrl_reg_1,

  output reg 	[31:0] psx_msgst_host_addr_0,

  output reg 	[31:0] psx_msgst_host_addr_1,

  output reg 	[31:0] psx_msgld_host_addr_0,

  output reg 	[31:0] psx_msgld_host_addr_1,
  
  output reg 	[31:0] psx_msgst_host_addr_mask_0,

  output reg 	[31:0] psx_msgst_host_addr_mask_1,

  output reg 	[31:0] psx_msgld_host_addr_mask_0,

  output reg 	[31:0] psx_msgld_host_addr_mask_1,

  output reg 	[31:0] psx_host_reqid,

  output reg 	[31:0] psx_host_ctrl_reg,

  output reg 	[31:0] pci0_msgst_host_addr_0,

  output reg 	[31:0] pci0_msgst_host_addr_1,

  output reg 	[31:0] pci0_msgld_host_addr_0,

  output reg 	[31:0] pci0_msgld_host_addr_1,
  
  output reg 	[31:0] pci_msgst_host_addr_mask_0,

  output reg 	[31:0] pci_msgst_host_addr_mask_1,

  output reg 	[31:0] pci_msgld_host_addr_mask_0,

  output reg 	[31:0] pci_msgld_host_addr_mask_1,

  output reg 	[31:0] pci0_host_reqid,

  output reg 	[31:0] pci0_host_ctrl_reg,

  input  wire 	[31:0] msgst_rsp_status,

  input  wire 	[31:0] msgld_rsp_status,

  input  wire 	[31:0] msgld_pass_counter_stats,

  input  wire 	[31:0] msgld_fail_counter_stats,
  //debug signals
  input wire 	[31:0] msgst_dbg0,
  input wire 	[31:0] msgst_dbg1,
  input wire 	[31:0] msgld_dbg0,
  input wire 	[31:0] msgld_dbg1,
  input wire 	[31:0] msgld_dbg2,

  input wire 	[31:0] m2st_dbg0,
  input wire 	[31:0] m2st_dbg1,
  input wire 	[31:0] m2st_dbg2,

  // Streaming to Message interface 

  output reg 	[31:0] st2m_ctrl_reg, 		//[RW] bit 0 - Start bit ; bit 31:1 number of back to back ST2M messages number

  input  wire 	[31:0] st2m_rsp_status, 	//[RO] bit 0 - req_done; bit 1- all data sent

  output reg    [31:0] st2m_ctrl_reg_1,
  output reg    [31:0] st2m_ctrl_reg_2,
  input  wire   [31:0] st2m_dbg0,
  input  wire   [31:0] st2m_dbg1,
  input  wire   [31:0] st2m_dbg2,
  input  wire   [31:0] st2m_dbg3,
  // Message to streaming interface 

  output reg  	[31:0] m2st_ctrl_reg,		//[RW] bit 0 - start bit; bit 1-streaming messages counter; bir [31:2] number of back to back M2ST instructions
  output reg  	[31:0] m2st_ctrl_reg_1,		//[RW] bit 0 - start bit; bit 1-streaming messages counter; bir [31:2] number of back to back M2ST instructions

  input  wire  	[31:0] m2st_rsp_status,		//[RO] bit 0 - reuest done

  //input  wire  	[31:0] m2st_rsp_pass_cnt,	//[RO] bit [31:0] - Count of M2ST Pass packets
  input  wire  	[31:0] m2st_psx_pass_cnt,	//[RO] bit [31:0] - Count of M2ST Pass packets
  input  wire  	[31:0] m2st_pci_pass_cnt,	//[RO] bit [31:0] - Count of M2ST Pass packets

  //input  wire  	[31:0] m2st_rsp_fail_cnt,	//[RO] bit [31:0] - Count of M2ST fail packets
  input  wire  	[31:0] m2st_psx_fail_cnt,	//[RO] bit [31:0] - Count of M2ST fail packets
  input  wire  	[31:0] m2st_pci_fail_cnt,	//[RO] bit [31:0] - Count of M2ST fail packets


  output reg    [31:0] soft_rst_n,	

  

  //axi4lite interface//// 

  input  wire                             			axi_aclk,

  input  wire                             			axi_aresetn,



  input  wire  [C_S_AXI_ADDR_WIDTH-1:0]           	axi_awaddr,

  output wire                             			axi_awready,

  input  wire                             			axi_awvalid,



  input  wire  [C_S_AXI_ADDR_WIDTH-1:0]           	axi_araddr,

  output wire                             			axi_arready,

  input  wire                             			axi_arvalid,



  input  wire  [C_S_AXI_DATA_WIDTH-1:0]           	axi_wdata,

  input  wire  [(C_S_AXI_DATA_WIDTH/8)-1 : 0]     	axi_wstrb,

  output wire                             			axi_wready,

  input  wire                             			axi_wvalid,



  output reg   [C_S_AXI_DATA_WIDTH-1:0]           	axi_rdata,

  output wire  [1:0]           						axi_rresp,

  input  wire                             			axi_rready,

  output reg                              			axi_rvalid,



  output wire  [1:0]           						axi_bresp,

  input  wire                             			axi_bready,

  output reg                              			axi_bvalid

        

	);

	

  reg   [C_S_AXI_ADDR_WIDTH-1:0]    wr_addr;

  reg   [C_S_AXI_ADDR_WIDTH-1:0]    rd_addr;

  reg           					wr_req;

  reg           					rd_req;

					

  reg           					reset_released;

  reg           					reset_released_r;

  

   //******************************************************************************

  //A write address phase is accepted only when there is no pending read or

  //write transactions. when both read and write transactions occur on the

  //same clock read transaction will get the highest priority and processed

  //first. write transaction will not be accepted until the read transaction

  //is completed. 

  //******************************************************************************

  assign axi_awready = ((~wr_req) && (!(rd_req || axi_arvalid))) && reset_released_r;

  assign axi_bresp = 2'b00;

  assign axi_rresp = 2'b00;

  assign axi_wready = wr_req && ~axi_bvalid;

  assign axi_arready = ~rd_req && ~wr_req && reset_released_r;





  //******************************************************************************

  //According to xilinx guide lines after reset the AWREADY and ARREADY siganls

  //should be low atleast for one clock cycle. To achieve this a signal 

  //reset_released is taken and anded with axi_awready and axi_arready signals,

  //so that the output will show a logic '0' when in reset

  //******************************************************************************

  always @(posedge axi_aclk)

  begin

      if(~axi_aresetn) begin

          reset_released   <= 1'b0;

          reset_released_r <= 1'b0;

      end else begin

          reset_released   <= 1'b1;

          reset_released_r <= reset_released;

      end 

  end



  //******************************************************************************

  //AXI Lite trasaction decoding and address latching logic. 

  //when axi_a*valid signal is asserted by the master the address is latched 

  //and wr_req or rd_req signal is asserted until data phase is completed 

  //******************************************************************************

  always @(posedge axi_aclk)

  begin

      if(~axi_aresetn)begin

          wr_req <= 1'b0;

          rd_req <= 1'b0;

          wr_addr <= 'd0;

          rd_addr <= 'd0;

      end else begin

          if(axi_awvalid && axi_awready) begin

              wr_req <= 1'b1;

              wr_addr <= axi_awaddr;

          end else if (axi_bvalid && axi_bready) begin

              wr_req <= 1'b0;

              wr_addr <= 'd0;

          end else begin

              wr_req <= wr_req;

              wr_addr <= wr_addr;

          end



          if(axi_arvalid && axi_arready) begin

              rd_req <= 1'b1;

              rd_addr <= axi_araddr;

          end else if (axi_rvalid && axi_rready) begin

              rd_req <= 1'b0;

              rd_addr <= rd_addr;

          end else begin

              rd_req <= rd_req;

              rd_addr <= rd_addr;

          end

      end

  end 



  //******************************************************************************

  //AXI Lite read trasaction processing logic. 

  //when a read transaction is received, depending on address bits [9:2] the

  //data is recovered and sent on to axi_rdata signal along with axi_rvalid.  

  //The address bits [1:0] are not considred and it is expected that the

  //address is word aligned and reads complete word information. 

  //******************************************************************************

  always @(posedge axi_aclk)

  begin

      if(~axi_aresetn)begin

          axi_rvalid <= 1'b0;

          axi_rdata <= 32'd0;

      end else begin

          if(rd_req) begin

              if(axi_rvalid && axi_rready) begin

                  axi_rvalid <= 1'b0;

              end else begin

                  axi_rvalid <= 1'b1;

              end

              if(~axi_rvalid) begin

                 case (rd_addr[9:2]) 

					// Message store

                    8'h00: axi_rdata <= msg_ctrl_reg_0;
                    8'h01: axi_rdata <= msg_ctrl_reg_1;
                    8'h02: axi_rdata <= msgst_rsp_status;

					// Message load

                    8'h03: axi_rdata <= msgld_rsp_status;

                    8'h04: axi_rdata <= msgld_pass_counter_stats;

                    8'h05: axi_rdata <= msgld_fail_counter_stats;
					//MSGST-MSGLD debug 
                    8'h0C: axi_rdata <= msgst_dbg0;	
                    8'h0D: axi_rdata <= msgst_dbg1;	
                    8'h0E: axi_rdata <= msgld_dbg0;	
                    8'h0F: axi_rdata <= msgld_dbg1;
                    8'h10: axi_rdata <= msgld_dbg2;	
					
					8'h3F: axi_rdata	<=	global_start;
					
					//PSX-MSGST/MSGLD
					8'h40: axi_rdata	<=	psx_msgst_host_addr_0;
				    8'h41: axi_rdata	<=	psx_msgst_host_addr_1;
				    8'h42: axi_rdata	<=	psx_msgld_host_addr_0;
				    8'h43: axi_rdata	<=	psx_msgld_host_addr_1;	

					8'h44: axi_rdata	<=	psx_host_reqid;
					8'h46: axi_rdata	<=	psx_host_ctrl_reg;
					
					8'h47: axi_rdata	<=	pci0_msgst_host_addr_0;
					8'h48: axi_rdata	<=	pci0_msgst_host_addr_1;
					8'h49: axi_rdata	<=	pci0_msgld_host_addr_0;
					8'h4A: axi_rdata	<=	pci0_msgld_host_addr_1;
					
					8'h4B: axi_rdata	<=	pci0_host_reqid;
					8'h4D: axi_rdata	<=	pci0_host_ctrl_reg;	
					
					8'h50: axi_rdata	<=	psx_msgst_host_addr_mask_0;
					8'h51: axi_rdata	<=	psx_msgst_host_addr_mask_1;
					8'h52: axi_rdata	<=	psx_msgld_host_addr_mask_0;
					8'h53: axi_rdata	<=	psx_msgld_host_addr_mask_1;
					
					8'h57: axi_rdata	<=	pci_msgst_host_addr_mask_0;
					8'h58: axi_rdata	<=	pci_msgst_host_addr_mask_1;
					8'h59: axi_rdata	<=	pci_msgld_host_addr_mask_0;
					8'h5A: axi_rdata	<=	pci_msgld_host_addr_mask_1;
					//ST2M
					8'h80: axi_rdata	<=	st2m_ctrl_reg;  // ST2M interface control register	
					8'h81: axi_rdata 	<= 	st2m_rsp_status;					
					8'h82: axi_rdata	<=	st2m_ctrl_reg_1;  // ST2M interface control register
					8'h83: axi_rdata	<=	st2m_ctrl_reg_2;  // ST2M interface control register
					
					8'h84: axi_rdata 	<= 	st2m_dbg0;
					8'h85: axi_rdata 	<= 	st2m_dbg1;
					8'h86: axi_rdata 	<= 	st2m_dbg2;
					8'h87: axi_rdata 	<= 	st2m_dbg3;
					
					// M2ST
					8'h93: axi_rdata	<=	m2st_ctrl_reg;  // M2ST interface control register
					8'h94: axi_rdata	<=	m2st_ctrl_reg_1;  // M2ST interface control register
					8'h95: axi_rdata 	<= 	m2st_rsp_status;
					
					8'h96: axi_rdata <= m2st_psx_pass_cnt;
					8'h97: axi_rdata <= m2st_psx_fail_cnt;
					
					8'h98: axi_rdata	<=	soft_rst_n;	
					
					8'h99: axi_rdata <= m2st_pci_pass_cnt;
					8'h9A: axi_rdata <= m2st_pci_fail_cnt;					

                    8'h9B: axi_rdata <= m2st_dbg0;	
                    8'h9C: axi_rdata <= m2st_dbg1;
                    8'h9D: axi_rdata <= m2st_dbg2;	

                    default: axi_rdata <= 32'h0000DEAD;

                 endcase

              end

          end else begin

              axi_rvalid <= 1'b0;

              axi_rdata <= 32'd0;

          end

      end 

  end



  //******************************************************************************

  //AXI Lite write trasaction processing logic. 

  //when a write transaction is received, depending on address bits [9:2] the

  //data is written in to the corresponding register.  

  //The address bits [1:0] are not considred and it is expected that the

  //address is word aligned and writes into entire register.  

  //******************************************************************************

  always @(posedge axi_aclk)

  begin

      if(~axi_aresetn)begin

          msg_ctrl_reg_0     				<= 0;

          msg_ctrl_reg_1     				<= 0;

          psx_msgst_host_addr_0 			<= 0;

          psx_msgst_host_addr_1 			<= 0;

          psx_msgld_host_addr_0 			<= 0;

          psx_msgld_host_addr_1 			<= 0;
		  
		  psx_msgst_host_addr_mask_0 		<= 0;

          psx_msgst_host_addr_mask_1 		<= 0;

          psx_msgld_host_addr_mask_0 		<= 0;

          psx_msgld_host_addr_mask_1 		<= 0;

          psx_host_reqid     				<= 0;

          psx_host_ctrl_reg  				<= 0;

          pci0_msgst_host_addr_0 			<= 0;

          pci0_msgst_host_addr_1 			<= 0;

          pci0_msgld_host_addr_0 			<= 0;

          pci0_msgld_host_addr_1 			<= 0;
		  
		  pci_msgst_host_addr_mask_0 		<= 0;

          pci_msgst_host_addr_mask_1 		<= 0;

          pci_msgld_host_addr_mask_0 		<= 0;

          pci_msgld_host_addr_mask_1 		<= 0;

          pci0_host_reqid     				<= 0;

          pci0_host_ctrl_reg  				<= 0;

		  st2m_ctrl_reg						<= 0;  // ST2M interface control register				  

		  st2m_ctrl_reg_1					<= 0;  // ST2M interface control register for the roll over address	
		  
		  st2m_ctrl_reg_2					<= 0;  // ST2M interface control register for the roll over address				  

		  m2st_ctrl_reg						<= 0;  // M2ST interface control register
		  
		  m2st_ctrl_reg_1					<= 0;  // M2ST interface control register

		  soft_rst_n                        <= 0;
		  global_start						<= 0;
      end else begin

//          if(wr_req && axi_wvalid && ~axi_bvalid) begin
          if( axi_wready && axi_wvalid) begin

              case (wr_addr[9:2]) 

                  8'h00: msg_ctrl_reg_0           				<= axi_wdata;

				  8'h01: msg_ctrl_reg_1           				<= axi_wdata;

				  8'h40: psx_msgst_host_addr_0           		<= axi_wdata;

				  8'h41: psx_msgst_host_addr_1           		<= axi_wdata;

				  8'h42: psx_msgld_host_addr_0           		<= axi_wdata;

				  8'h43: psx_msgld_host_addr_1           		<= axi_wdata;

				  8'h44: psx_host_reqid           	 			<= axi_wdata;

				  8'h46: psx_host_ctrl_reg           			<= axi_wdata;

				  8'h47: pci0_msgst_host_addr_0           		<= axi_wdata;

				  8'h48: pci0_msgst_host_addr_1           		<= axi_wdata;

				  8'h49: pci0_msgld_host_addr_0           		<= axi_wdata;

				  8'h4A: pci0_msgld_host_addr_1           		<= axi_wdata;

				  8'h4B: pci0_host_reqid           	 			<= axi_wdata;

				  8'h4D: pci0_host_ctrl_reg           			<= axi_wdata;
				  
				  8'h50: psx_msgst_host_addr_mask_0        		<= axi_wdata;

				  8'h51: psx_msgst_host_addr_mask_1        		<= axi_wdata;

				  8'h52: psx_msgld_host_addr_mask_0        		<= axi_wdata;

				  8'h53: psx_msgld_host_addr_mask_1        		<= axi_wdata;
				  
				  8'h57: pci_msgst_host_addr_mask_0        		<= axi_wdata;

				  8'h58: pci_msgst_host_addr_mask_1           	<= axi_wdata;

				  8'h59: pci_msgld_host_addr_mask_0           	<= axi_wdata;

				  8'h5A: pci_msgld_host_addr_mask_1           	<= axi_wdata;

				  8'h80: st2m_ctrl_reg							<= axi_wdata;  // ST2M interface control register				  

				  8'h82: st2m_ctrl_reg_1						<= axi_wdata;  // ST2M interface control register

				  8'h84: st2m_ctrl_reg_2						<= axi_wdata;  // ST2M interface control register

				  8'h94: m2st_ctrl_reg							<= axi_wdata;  // M2ST interface control register	
				  
				  8'h96: m2st_ctrl_reg_1						<= axi_wdata;  // M2ST interface control register

				  8'h98: soft_rst_n                             <= axi_wdata;
				  
				  8'h3F: global_start							<= axi_wdata;
				 // 8'h80: m2st_ctrl_reg							<= axi_wdata;  // ST2M interface control register				  

				 // 8'h94: st2m_ctrl_reg							<= axi_wdata;  // M2ST interface control register							

   

              endcase

          end else begin

				msg_ctrl_reg_0     				<= msg_ctrl_reg_0;	//Need to double check these assignments

				msg_ctrl_reg_1     				<= msg_ctrl_reg_1;

				psx_msgst_host_addr_0 			<= psx_msgst_host_addr_0;

				psx_msgst_host_addr_1 			<= psx_msgst_host_addr_1;

				psx_msgld_host_addr_0 			<= psx_msgld_host_addr_0;

				psx_msgld_host_addr_1 			<= psx_msgld_host_addr_1;
				
				psx_msgst_host_addr_mask_0 		<= psx_msgst_host_addr_mask_0;

				psx_msgst_host_addr_mask_1 		<= psx_msgst_host_addr_mask_1;

				psx_msgld_host_addr_mask_0 		<= psx_msgld_host_addr_mask_0;

				psx_msgld_host_addr_mask_1 		<= psx_msgld_host_addr_mask_1;

				psx_host_reqid     				<= psx_host_reqid;

				psx_host_ctrl_reg  				<= psx_host_ctrl_reg;

				pci0_msgst_host_addr_0 			<= pci0_msgst_host_addr_0;

				pci0_msgst_host_addr_1 			<= pci0_msgst_host_addr_1;

				pci0_msgld_host_addr_0 			<= pci0_msgld_host_addr_0;

				pci0_msgld_host_addr_1 			<= pci0_msgld_host_addr_1;
				
				pci_msgst_host_addr_mask_0 		<= pci_msgst_host_addr_mask_0;

				pci_msgst_host_addr_mask_1 		<= pci_msgst_host_addr_mask_1;

				pci_msgld_host_addr_mask_0 		<= pci_msgld_host_addr_mask_0;

				pci_msgld_host_addr_mask_1 		<= pci_msgld_host_addr_mask_1;

				pci0_host_reqid     			<= pci0_host_reqid;

				pci0_host_ctrl_reg  			<= pci0_host_ctrl_reg;

				st2m_ctrl_reg					<= st2m_ctrl_reg;  // ST2M interface control register

				st2m_ctrl_reg_1					<= st2m_ctrl_reg_1;  // ST2M interface control register
				
				st2m_ctrl_reg_2					<= st2m_ctrl_reg_2;  // ST2M interface control register

                m2st_ctrl_reg					<= m2st_ctrl_reg;  // M2ST interface control register
				
                m2st_ctrl_reg_1					<= m2st_ctrl_reg_1;  // M2ST interface control register
				
				global_start					<= global_start;
			end

      end 

  end

  

   //********************************************************************************

  //write response channel logic. 

  //This logic will generate BVALID signal for the write transaction. 

  //********************************************************************************

  always @(posedge axi_aclk)

  begin

      if(~axi_aresetn) begin

          axi_bvalid <= 1'b0;

      end else begin

          if(wr_req && axi_wvalid && ~axi_bvalid) begin

              axi_bvalid <= 1'b1;

          end else if(axi_bready) begin

              axi_bvalid <= 1'b0;

          end else begin

              axi_bvalid <= axi_bvalid;

          end

      end

  end 

  

endmodule

  

  
