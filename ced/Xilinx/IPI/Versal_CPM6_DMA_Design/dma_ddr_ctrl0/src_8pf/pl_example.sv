import axil_slave_pkg::*;

module pl_example(
    input         clk,
    input         reset_n,
    
    // DBI interface
    output logic [31:0] m_dbi_axil_awaddr,
    output logic [15:0] 	m_dbi_axil_awuser,
    output logic		m_dbi_axil_awvalid,
    output logic [2:0] 	m_dbi_axil_awprot,
    input 		        m_dbi_axil_awready,
    output logic [31:0] m_dbi_axil_wdata,
    output logic [3:0] 	m_dbi_axil_wuser,
    output logic [3:0] 	m_dbi_axil_wstrb,
    output logic 		m_dbi_axil_wvalid,
    input 		        m_dbi_axil_wready,
    input [1:0] 	    m_dbi_axil_bresp,
    input 		        m_dbi_axil_bvalid,
    input [5:0] 	    m_dbi_axil_buser, 
    output logic 		m_dbi_axil_bready,
    output logic [31:0] m_dbi_axil_araddr,
    output logic 		m_dbi_axil_arvalid,
    input 		        m_dbi_axil_arready,
    output logic [15:0] m_dbi_axil_aruser,
    output logic [2:0] 	m_dbi_axil_arprot,
    input [31:0] 	    m_dbi_axil_rdata,
    input [1:0] 	    m_dbi_axil_rresp,
    input [3:0] 	    m_dbi_axil_ruser,
    input 		        m_dbi_axil_rvalid,
    output logic		m_dbi_axil_rready,

    // m_pl_axil _0 interface (Master AXI)
    input logic [11:0]  m_pl_axil_awuser,  // sideband user bits from cpm_user_aligner
    input logic [63:0] 	m_pl_axil_awaddr,
    input logic [2:0]  	m_pl_axil_awprot,
    input logic        	m_pl_axil_awvalid,
    output logic       	m_pl_axil_awready,
    input logic [31:0] 	m_pl_axil_wdata,
    input logic        	m_pl_axil_wvalid,
	input logic [3:0] 	m_pl_axil_wstrb,
    output logic       	m_pl_axil_wready,
    output logic [1:0] 	m_pl_axil_bresp,
    output             	m_pl_axil_bvalid,
    input         		m_pl_axil_bready,
    input  [11:0]       m_pl_axil_aruser,  // sideband user bits from cpm_user_aligner
    input  [63:0] 		m_pl_axil_araddr,
    input  [2:0]  		m_pl_axil_arprot,
    input         		m_pl_axil_arvalid,
    output logic       	m_pl_axil_arready,
    output logic [31:0] m_pl_axil_rdata,
    output logic [1:0]  m_pl_axil_rresp,
    output logic        m_pl_axil_rvalid,
    input         		m_pl_axil_rready,

	// DMA interrupt from DMA engin, each bit represents an interrupt from a channel. So bit0 is channel 0, bit1 is channel 1 and so on.
    input [127:0]       dma_irq,

    // MSIX interface to MSI-X table module
    output logic [10:0] pcie_msix_vector_num, // output
    output logic [2:0]  pcie_msix_func_num, // output
    output logic        pcie_msix_vfunc_active, // output
    output logic [7:0]  pcie_msix_vfunc_num,   // output

    output logic [1:0]  pcie_msix_operation, // output
    output logic        pcie_msix_req, // output
    input               pcie_msix_error, //input
    input               pcie_msix_grant        //input
);

///////////// Interrupt check
// find channel number so a RR check.
//     
// temp int region
localparam NUM_CHN = 128;



// Interrupt control interface
logic [6:0] chn_num;  // latched from arbiter when entering SM_INT_SRD
logic       start_int;
logic [2:0] sm_dbi;
logic [2:0] sm_axilm;
// Interrupt status read interface (DBI read of channel int-status register after MSI-X grant)
logic           int_read_req;
logic [31:0]    int_read_addr;
logic [31:0]    int_read_data;
logic           int_read_ack;
// Interrupt clear interface
logic           irq_clr_req_c2h;    // from axil_slave: host has written C2H clear offset
logic           irq_clr_req_h2c;    // from axil_slave: host has written H2C clear offset
logic           irq_clr_done_c2h;   // to axil_slave: 1-cycle pulse when C2H clear write completes
logic           irq_clr_done_h2c;   // to axil_slave: 1-cycle pulse when H2C clear write completes
logic           irq_status_wr;      // to axil_slave: 1-cycle pulse to store irq_status
logic           irq_status_is_c2h;  // to axil_slave: target irq status bank
logic [31:0]    irq_status_data;    // to axil_slave: int-status value to store
logic [31:0]    irq_clr_addr_lat_c2h; // latched C2H DMA channel clear address
logic [31:0]    irq_clr_addr_lat_h2c; // latched H2C DMA channel clear address
logic [31:0]    irq_status_lat_c2h;   // local C2H copy of int_read_data for clear write data
logic [31:0]    irq_status_lat_h2c;   // local H2C copy of int_read_data for clear write data
logic           clr_is_c2h;           // clear operation selector latched at SM_INT_IDL
// Interrupt DBI write interface
logic           int_write_req;
logic [31:0]    int_write_addr;
logic [31:0]    int_write_data;
logic           int_write_ack;
// axil_slave outputs
axil_regs_t  pl_regs;
logic        pl_write_req;
logic        pl_is_c2h;      // 0=H2C, 1=C2H
logic        pl_vfunc_active;
logic [7:0]  pl_vfunc_num;
logic [2:0]  pl_pf_num;
logic        pl_ar_vfunc_active;
logic [7:0]  pl_ar_vfunc_num;
logic [2:0]  pl_ar_pf_num;

// Debug status signals
logic [31:0] irq_status;
logic [31:0] msix_dbg_snapshot;
logic [31:0] msix_dbg_events;
logic        pcie_msix_req_d;
logic        pcie_msix_grant_d;
logic        pcie_msix_error_d;
logic        msix_req_pulse;
logic        msix_grant_pulse;
logic        msix_error_pulse;

// Round-robin arbiter outputs
logic [6:0] grant_chn;
logic       grant_vld;
logic       rr_advance;  // pulse: asserted when pcie_msix_grant received
logic [127:0] dma_irq_seen;      // one-shot mask: set after service, clear when source deasserts
logic [127:0] dma_irq_eligible;  // rr arbiter input after one-shot masking
localparam [2:0] 
    SM_INT_IDL  = 3'b000,
    SM_INT_SRD  = 3'b001,
    SM_INT_RDW  = 3'b010,  // wait for interrupt status read to complete (after grant)
    SM_FNC_NUM  = 3'b011,
    SM_FNC_CHN  = 3'b100,
    SM_INT_GNT  = 3'b101,
    SM_INT_CLR  = 3'b110,  // issue DBI write to clear DMA interrupt register
    SM_INT_END  = 3'b111;  // wait for DBI write ack, then pulse irq_clr_done
logic [2:0] 	sm_int;              // state for interrupt control state machine
logic [6:0]     h2c_chn_num, c2h_chn_num;
logic           h2c_chn_vld, c2h_chn_vld;
logic [31:0]    int_status_add;
logic [31:0]    int_clr_addr;


// Channel numnber 128, dma_irq[127:0] breakdown
// [63:0]    Write channel C2H
// [127: 64] Read channel  H2C
assign c2h_chn_num = chn_num <= 63 ? chn_num : 0;   
assign c2h_chn_vld = chn_num <= 63;
assign h2c_chn_num = chn_num > 63 ? chn_num - 64 : 0;
assign h2c_chn_vld = chn_num > 63;
  
// Interrupt Status address is bsed on Channle number + Interrupt status offset
// Interrupt address set for Controller0 (DMA/DBI register base 0xFC2C_0000; Controller1 uses 0xFC6C_0000). 
assign int_status_add = 32'hFC2C_0000 + (c2h_chn_vld ? 32'h000 + (c2h_chn_num * 32'h400) + 32'h84 :
                                          h2c_chn_vld ? 32'h200 + (h2c_chn_num * 32'h400) + 32'h84 :
                                          32'h0);
assign int_clr_addr = int_status_add + 32'h8;  // clear address +8 tatus address. just write to it to clear interrupt.
assign dma_irq_eligible = dma_irq & ~dma_irq_seen;

// One MSI-X per asserted dma_irq bit: re-arm only after that bit deasserts.
always @(posedge clk) begin
  if (!reset_n) begin
    dma_irq_seen <= '0;
  end else begin
    dma_irq_seen <= dma_irq_seen & dma_irq;
    if ((sm_int == SM_INT_GNT) && pcie_msix_grant && dma_irq[chn_num])
      dma_irq_seen[chn_num] <= 1'b1;
  end
end
 
  // Main SM to controle the interrupt flow.
  // 1. Get interrupt from DMA engin 128 bits (128 channels)
  // 2. Fing Interrupt Channel in roound-robin way. 
  // 3. Retch Interrupt satus for the channel that is interrupting.
  // 4. find MSI-X function from functioan table.
  // 5. send interrupt request to MSI-X table module
  // 6. once MSI-X grant/error is observed, return to IDLE
  // 
  always @(posedge clk) begin
      if (!reset_n) begin
	    sm_int          <= 3'h0;
	    chn_num         <= 0;
	    start_int       <= 0;
	    pcie_msix_req   <= 1'b0;
	    int_read_req    <= 1'b0;
	    int_read_addr   <= '0;
	    int_write_req   <= 1'b0;
	    int_write_addr  <= '0;
	    int_write_data  <= '0;
      irq_status_data <= '0;
      irq_status_is_c2h <= 1'b0;
	    irq_status_wr   <= 1'b0;
      irq_clr_done_c2h <= 1'b0;
      irq_clr_done_h2c <= 1'b0;
      irq_clr_addr_lat_c2h <= '0;
      irq_clr_addr_lat_h2c <= '0;
      irq_status_lat_c2h <= '0;
      irq_status_lat_h2c <= '0;
      clr_is_c2h <= 1'b0;
      end
      else begin
	 case (sm_int)
	   SM_INT_IDL : begin
        irq_status_wr <= 1'b0; // deassert after one-cycle pulse
        irq_clr_done_c2h <= 1'b0;  // deassert after one-cycle pulse
        irq_clr_done_h2c <= 1'b0;  // deassert after one-cycle pulse
        if (irq_clr_req_c2h && ~start_int) begin  //000 Host requested C2H DMA register clear
         clr_is_c2h <= 1'b1;
         sm_int    <= SM_INT_CLR;
         start_int <= 1'b1;
        end else if (irq_clr_req_h2c && ~start_int) begin  //000 Host requested H2C DMA register clear
         clr_is_c2h <= 1'b0;
		     sm_int    <= SM_INT_CLR;
		     start_int <= 1'b1;
        end else if (grant_vld && dma_irq_eligible[grant_chn] && ~start_int) begin  // Round-robin: arbiter selects next eligible channel
	         chn_num       <= grant_chn;
	         sm_int        <= SM_INT_SRD;
	         start_int     <= 1'b1;
	      end
	   end
	   SM_INT_SRD : begin                             //001 Verify interrupt still pending
	      if (dma_irq[chn_num]) begin
	         // IRQ still asserted: proceed to function lookup
	         sm_int <= SM_FNC_NUM;
	      end else begin
	         // IRQ already cleared by DMA engine: release channel and return to IDLE
	         start_int <= 1'b0;
	         sm_int    <= SM_INT_IDL;
	      end
	   end
	   SM_FNC_NUM : begin                            //011 look up function number from func_vec_table
	      sm_int <= SM_FNC_CHN;
	   end
	   
	   SM_FNC_CHN : begin                             // 100 send MSI-X interrupt request
	      pcie_msix_req <= 1'b1;
	      sm_int <= SM_INT_GNT;
	   end
	   SM_INT_GNT : begin                             // 101 Wait for Interrupt Grant
        if (pcie_msix_grant || pcie_msix_error) begin
          sm_int        <= SM_INT_RDW;  // read interrupt status before returning to IDLE
		      pcie_msix_req  <= 1'b0;
		      int_read_req   <= 1'b1;      // kick off DBI read
		      int_read_addr  <= int_status_add;
	      end
     end
	   SM_INT_RDW : begin                             // 010 Wait for interrupt status read
	      irq_status_wr <= 1'b0;  // deassert after one-cycle pulse
	      if (int_read_ack) begin
           int_read_req     <= 1'b0;
           // Store status in direction bank and latch clear addr per direction
           irq_status_is_c2h <= c2h_chn_vld;
           irq_status_data  <= int_read_data;
	         irq_status_wr    <= 1'b1;
           if (c2h_chn_vld) begin
             irq_status_lat_c2h   <= int_read_data;
             irq_clr_addr_lat_c2h <= int_clr_addr;
           end else begin
             irq_status_lat_h2c   <= int_read_data;
             irq_clr_addr_lat_h2c <= int_clr_addr;
           end
	         sm_int           <= SM_INT_IDL;
	         start_int        <= 1'b0;
	      end
	   end
	   SM_INT_CLR : begin                             // 110 Issue DBI write to clear DMA int reg
	      int_write_req  <= 1'b1;
        int_write_addr <= clr_is_c2h ? irq_clr_addr_lat_c2h : irq_clr_addr_lat_h2c;
        int_write_data <= clr_is_c2h ? {29'b0, irq_status_lat_c2h[2:0]} :
                                      {29'b0, irq_status_lat_h2c[2:0]};  // write-to-clear: replay status bits
	      sm_int         <= SM_INT_END;
	   end
	   SM_INT_END : begin                             // 111 Wait for DBI write ack
	      if (int_write_ack) begin
           int_write_req   <= 1'b0;
           irq_status_is_c2h <= clr_is_c2h;
           irq_status_data <= 32'h0;
           irq_status_wr   <= 1'b1;  // clear host-visible irq status register
           if (clr_is_c2h) begin
             irq_status_lat_c2h <= 32'h0;
             irq_clr_done_c2h <= 1'b1;  // pulse: tells axil_slave to clear C2H irq_clr_req
           end else begin
             irq_status_lat_h2c <= 32'h0;
             irq_clr_done_h2c <= 1'b1;  // pulse: tells axil_slave to clear H2C irq_clr_req
           end
	         sm_int       <= SM_INT_IDL;
	         start_int    <= 1'b0;
	      end
	   end
	 endcase // case (sm_int)
      end // else: !if(!reset_n)
   end // always @ (posedge clk)

// ----------------------------------------------------------------
// Function-to-channel table (single source of truth, PF-only phase)
// Index = PF number (0-7), value = channel number assigned to that PF.
// Both H2C and C2H share the same channel; direction selected by is_c2h.
// To add VF support later: extend func_to_chn and chn_to_pf accordingly.
// ----------------------------------------------------------------
logic [6:0] func_to_chn [0:7];

always_comb begin : p_func_to_chn
    func_to_chn[0] = 7'd0;  // PF0 -> channel 0
    func_to_chn[1] = 7'd1;  // PF1 -> channel 1
    func_to_chn[2] = 7'd2;  // PF2 -> channel 2
    func_to_chn[3] = 7'd3;  // PF3 -> channel 3
    func_to_chn[4] = 7'd4;  // PF4 -> channel 4
    func_to_chn[5] = 7'd5;  // PF5 -> channel 5
    func_to_chn[6] = 7'd6;  // PF6 -> channel 6
    func_to_chn[7] = 7'd7;  // PF7 -> channel 7
end

// Auto-derived reverse table: channel -> PF number (direct O(1) lookup for interrupt path)
logic [2:0] chn_to_pf [0:63];

always_comb begin : p_chn_to_pf
    for (int c = 0; c < 64; c++) chn_to_pf[c] = 3'h0;           // default
    for (int f = 0; f < 8;  f++) chn_to_pf[func_to_chn[f]] = f[2:0];
end

// Write path: direct channel lookup from requesting PF
logic [6:0] pl_channel;
assign pl_channel = func_to_chn[pl_pf_num];

// Interrupt path: direct PF lookup from interrupting channel
logic [6:0] irq_chn;
assign irq_chn = c2h_chn_vld ? c2h_chn_num : h2c_chn_num;

// 4 vectors per function:
//   C2H -> 0
//   H2C -> 2
// Vector is table-relative; pcie_msix_func_num selects which PF MSI-X table.
assign pcie_msix_vector_num   = c2h_chn_vld ? 11'd0 :
                                h2c_chn_vld ? 11'd2 :
                                11'hFF;

assign pcie_msix_operation    = 2'b00;
assign pcie_msix_func_num     = chn_to_pf[irq_chn];  // direct O(1) reverse lookup
assign pcie_msix_vfunc_active = 1'b0;                 // PF-only phase: no VFs
assign pcie_msix_vfunc_num    = 8'h0;                 // PF-only phase: no VFs

// Interrupt status debug register
assign irq_status = {14'b0,
                     chn_num[5:0],    // [17:12] channel being processed
                     pcie_msix_error, // [11]    MSI-X error
                     grant_vld,       // [10]    RR arbiter has pending grant
                     start_int,       // [9]     interrupt processing in-flight
                     sm_dbi,          // [8:6]   DBI access SM state
                     sm_int,          // [5:3]   interrupt SM state
                     pcie_msix_grant, // [2]     MSI-X grant received
                     pcie_msix_req,   // [1]     MSI-X request asserted
                     |dma_irq};       // [0]     any DMA interrupt pending

assign msix_req_pulse   = pcie_msix_req   & ~pcie_msix_req_d;
assign msix_grant_pulse = pcie_msix_grant & ~pcie_msix_grant_d;
assign msix_error_pulse = pcie_msix_error & ~pcie_msix_error_d;

// Capture MSI-X req/grant/error pulses and snapshot outputs at request time
always @(posedge clk) begin
    if (!reset_n) begin
        pcie_msix_req_d   <= 1'b0;
        pcie_msix_grant_d <= 1'b0;
        pcie_msix_error_d <= 1'b0;
        msix_dbg_snapshot <= 32'h0;
        msix_dbg_events   <= 32'h0;
    end else begin
        pcie_msix_req_d   <= pcie_msix_req;
        pcie_msix_grant_d <= pcie_msix_grant;
        pcie_msix_error_d <= pcie_msix_error;

        if (msix_req_pulse) begin
            msix_dbg_snapshot <= {
                sm_int,                  // [31:29] interrupt SM state
                sm_dbi,                  // [28:26] DBI SM state
                pcie_msix_req,           // [25]    req asserted on this pulse
                pcie_msix_operation,     // [24:23]
                pcie_msix_vfunc_num,     // [22:15]
                pcie_msix_vfunc_active,  // [14]
                pcie_msix_func_num,      // [13:11]
                pcie_msix_vector_num     // [10:0]
            };
            msix_dbg_events[11:9] <= sm_dbi;
            msix_dbg_events[8:6]  <= sm_int;
            msix_dbg_events[5:3]  <= sm_axilm;
        end

        if (msix_req_pulse)   msix_dbg_events[0] <= 1'b1;
        if (msix_grant_pulse) msix_dbg_events[1] <= 1'b1;
        if (msix_error_pulse) msix_dbg_events[2] <= 1'b1;
    end
end

//
// DBI interface state machine — handles context writes and interrupt status reads.
//
localparam [2:0]
    AXILM_IDLE = 3'b000,
    AXILM_W    = 3'b001,
    AXILM_W_B  = 3'b010,
    AXILM_R    = 3'b011,  // AR accepted, waiting for R data
    AXILM_R_RS = 3'b100;  // R data received

logic        st_dbi_rd;
logic        st_dbi_wr;
logic [31:0] dbi_rd_addr;
logic [31:0] dbi_rd_data;
logic [31:0] dbi_wr_addr;
logic [31:0] dbi_wr_data;
logic        read_done;
logic        read_error;

logic [31:0] ctxt_write_addr [0:7];
logic [31:0] ctxt_write_data [0:7];
logic [3:0]  wr_count;
logic [3:0]  num_wr;
logic        ctxt_write_req;
logic        ctxt_write_pending;
logic        ctxt_write_ack;
logic write_done;
assign ctxt_write_req = ctxt_write_pending;

// Context write address formulas:
//   H2C base = 0xFC2C_0000 + 0x200 + (chn * 0x400)
//   C2H base = 0xFC2C_0000 + 0x000 + (chn * 0x400)
//   Registers: size(+0x1C), src_lo(+0x20), src_hi(+0x24),
//              dst_lo(+0x28), dst_hi(+0x2C), doorbell(+0x04)
 always_comb begin : context_write
    automatic logic [31:0] ctxt_base;
    ctxt_base = pl_is_c2h ? (32'hFC2C_0000 + (pl_channel * 32'h400))
                           : (32'hFC2C_0000 + 32'h200 + (pl_channel * 32'h400));
	ctxt_write_addr[0] = ctxt_base + 32'h1C; //Size
	ctxt_write_data[0] = pl_regs.reg0;
	ctxt_write_addr[1] = ctxt_base + 32'h20; //Src addr Lo
	ctxt_write_data[1] = pl_regs.reg1;
	ctxt_write_addr[2] = ctxt_base + 32'h24; //Src addr Hi
	ctxt_write_data[2] = pl_regs.reg2;
	ctxt_write_addr[3] = ctxt_base + 32'h28; //Dst addr Lo
	ctxt_write_data[3] = pl_regs.reg3;
	ctxt_write_addr[4] = ctxt_base + 32'h2C; //Dst addr Hi
	ctxt_write_data[4] = pl_regs.reg4;
	ctxt_write_addr[5] = ctxt_base + 32'h04; //Doorbell
	ctxt_write_data[5] = 32'h1;
	num_wr = 4'd6;
 end

// DBI state machine to handle context programming writes from the PL master.
// Context will be written via mpl_axil interface.

localparam [2:0]
    DBI_IDLE       = 3'b000,
    DBI_INT_RD     = 3'b001,  // interrupt status read in progress
    DBI_WR         = 3'b010,  // single DBI write (interrupt clear)
    DBI_CTXT_WR    = 3'b011,
    DBI_CTXT_WR_DN = 3'b100;

assign m_dbi_axil_aruser = 'h0;
assign m_dbi_axil_arprot = 'h0;
assign m_dbi_axil_wuser  = 'h0;
assign m_dbi_axil_wstrb  = 4'hF;
assign m_dbi_axil_awprot = 'h0;
assign m_dbi_axil_awuser = 'h0;
assign m_dbi_axil_bready = 1'b1;

assign dbi_rd_addr    = (sm_dbi == DBI_INT_RD)  ? int_read_addr              : 'h0;
assign dbi_wr_addr    = (sm_dbi == DBI_WR)       ? int_write_addr             :
                        (sm_dbi == DBI_CTXT_WR)  ? ctxt_write_addr[wr_count]  : 'h0;
assign dbi_wr_data    = (sm_dbi == DBI_WR)       ? int_write_data             :
                        (sm_dbi == DBI_CTXT_WR)  ? ctxt_write_data[wr_count]  : 'h0;
assign ctxt_write_ack = (sm_dbi == DBI_CTXT_WR_DN) & (wr_count == num_wr);
assign int_read_ack   = (sm_dbi == DBI_INT_RD) & read_done;
assign int_write_ack  = (sm_dbi == DBI_WR) & write_done;
assign int_read_data  = dbi_rd_data;

always @(posedge clk) begin
  if (!reset_n) begin
    sm_dbi    <= DBI_IDLE;
    st_dbi_rd <= 1'b0;
    st_dbi_wr <= 1'b0;
    wr_count  <= 0;
    ctxt_write_pending <= 1'b0;
  end else begin
    if (pl_write_req)
      ctxt_write_pending <= 1'b1;

    case (sm_dbi)
      DBI_IDLE : begin
        st_dbi_rd <= 1'b0;
        st_dbi_wr <= 1'b0;
        if (int_read_req) begin          // interrupt status read has priority
          sm_dbi    <= DBI_INT_RD;
          st_dbi_rd <= 1'b1;
        end else if (int_write_req) begin // interrupt clear write
          sm_dbi    <= DBI_WR;
          st_dbi_wr <= 1'b1;
        end else if (ctxt_write_req) begin
          sm_dbi    <= DBI_CTXT_WR;
          st_dbi_wr <= 1'b1;
          wr_count  <= 4'd0;
          ctxt_write_pending <= 1'b0;
        end
      end

      DBI_INT_RD : begin
        st_dbi_rd <= 1'b0;
        if (read_done)
          sm_dbi <= DBI_IDLE;
      end

      DBI_WR : begin
        st_dbi_wr <= 1'b0;
        if (write_done)
          sm_dbi <= DBI_IDLE;
      end

      DBI_CTXT_WR : begin
        st_dbi_wr <= 1'b0;
        if (write_done) begin
          sm_dbi <= DBI_CTXT_WR_DN;
          wr_count <= wr_count + 1;
        end
      end

      DBI_CTXT_WR_DN : begin
        st_dbi_wr <= 1'b0;
        if (wr_count == num_wr) begin
          sm_dbi <= DBI_IDLE;
          wr_count <= 4'd0;
        end else begin
          sm_dbi <= DBI_CTXT_WR;
          st_dbi_wr <= 1'b1;
        end
      end

      default : sm_dbi <= DBI_IDLE;
    endcase
  end
end

always @(posedge clk) begin
  if (!reset_n) begin
    sm_axilm           <= AXILM_IDLE;
    m_dbi_axil_araddr  <= 'h0;
    m_dbi_axil_arvalid <= 'h0;
    m_dbi_axil_rready  <= 1'b1;   // always ready to accept read data
    m_dbi_axil_awaddr  <= 'h0;
    m_dbi_axil_awvalid <= 'h0;
    m_dbi_axil_wdata   <= 'h0;
    m_dbi_axil_wvalid  <= 'h0;
    dbi_rd_data        <= 'h0;
    read_done          <= 1'b0;
    read_error         <= 1'b0;
    write_done         <= 'h0;
  end else begin
    case (sm_axilm)
      AXILM_IDLE : begin
        read_done  <= 1'b0;
        write_done <= 1'b0;
        if (st_dbi_rd) begin              // read request: issue AR
          sm_axilm           <= AXILM_R;
          m_dbi_axil_araddr  <= dbi_rd_addr;
          m_dbi_axil_arvalid <= 1'b1;
        end else if (st_dbi_wr) begin
          sm_axilm           <= AXILM_W;
          m_dbi_axil_awaddr  <= dbi_wr_addr;
          m_dbi_axil_awvalid <= 1'b1;
          m_dbi_axil_wvalid  <= 1'b1;
          m_dbi_axil_wdata   <= dbi_wr_data;
        end
      end

      AXILM_R : begin                     // wait for AR handshake
        if (m_dbi_axil_arready) begin
          sm_axilm           <= AXILM_R_RS;
          m_dbi_axil_arvalid <= 1'b0;
        end
      end

      AXILM_R_RS : begin                  // wait for R data
        if (m_dbi_axil_rvalid) begin
          sm_axilm   <= AXILM_IDLE;
          read_done  <= 1'b1;
          if (m_dbi_axil_rresp == 2'b00)
            dbi_rd_data <= m_dbi_axil_rdata;
          else
            read_error  <= 1'b1;
        end
      end

      AXILM_W : begin
        if (m_dbi_axil_awready & m_dbi_axil_wready) begin
          sm_axilm           <= AXILM_W_B;
          m_dbi_axil_awvalid <= 1'b0;
          m_dbi_axil_wvalid  <= 1'b0;
        end
      end

      AXILM_W_B : begin
        m_dbi_axil_wvalid <= 1'b0;
        if (m_dbi_axil_bvalid) begin
          sm_axilm   <= AXILM_IDLE;
          write_done <= 1'b1;
        end
      end

      default : sm_axilm <= AXILM_IDLE;
    endcase
  end
end


// AXI-Lite slave: receives context writes from PL master.
// Writing reg5 (offset 0x14) triggers a DMA context write sequence via DBI.
// write_ack is driven by ctxt_write_ack once all 6 context entries are sent.
axil_slave u_axil_slave (
    .clk              (clk),
    .reset_n          (reset_n),
    // Write address channel
    .s_axil_awaddr    (m_pl_axil_awaddr),
    .s_axil_awprot    (m_pl_axil_awprot),
    .s_axil_awvalid   (m_pl_axil_awvalid),
    .s_axil_awready   (m_pl_axil_awready),
    // Write data channel
    .s_axil_wdata     (m_pl_axil_wdata),
    .s_axil_wstrb     (m_pl_axil_wstrb),
    .s_axil_wvalid    (m_pl_axil_wvalid),
    .s_axil_wready    (m_pl_axil_wready),
    // Write response channel
    .s_axil_bresp     (m_pl_axil_bresp),
    .s_axil_bvalid    (m_pl_axil_bvalid),
    .s_axil_bready    (m_pl_axil_bready),
    // Read address channel
    .s_axil_araddr    (m_pl_axil_araddr),
    .s_axil_arprot    (m_pl_axil_arprot),
    .s_axil_arvalid   (m_pl_axil_arvalid),
    .s_axil_arready   (m_pl_axil_arready),
    // Read data channel
    .s_axil_rdata     (m_pl_axil_rdata),
    .s_axil_rresp     (m_pl_axil_rresp),
    .s_axil_rvalid    (m_pl_axil_rvalid),
    .s_axil_rready    (m_pl_axil_rready),
    // Handshake
    .regs_out         (pl_regs),
    .write_req        (pl_write_req),
    .is_c2h           (pl_is_c2h),
    .write_ack        (ctxt_write_ack),
    // AW user bits sideband
    .s_axil_awuser    (m_pl_axil_awuser),
    .vfunc_active     (pl_vfunc_active),
    .vfunc_num        (pl_vfunc_num),
    .pf_num           (pl_pf_num),
    // AR user bits sideband
    .s_axil_aruser    (m_pl_axil_aruser),
    .ar_vfunc_active  (pl_ar_vfunc_active),
    .ar_vfunc_num     (pl_ar_vfunc_num),
    .ar_pf_num        (pl_ar_pf_num),
    .irq_status_wr    (irq_status_wr),
    .irq_status_is_c2h(irq_status_is_c2h),
    .irq_status_data  (irq_status_data),
    .irq_clr_req_c2h  (irq_clr_req_c2h),
    .irq_clr_req_h2c  (irq_clr_req_h2c),
    .irq_clr_done_c2h (irq_clr_done_c2h),
    .irq_clr_done_h2c (irq_clr_done_h2c),
    // Debug status inputs
    .dma_irq          (dma_irq),
    .h2c_chn_num      (h2c_chn_num),
    .c2h_chn_num      (c2h_chn_num),
    .irq_status       (irq_status),
    .msix_dbg_snapshot(msix_dbg_snapshot),
    .msix_dbg_events  (msix_dbg_events),
    .dma_irq_eligible0(dma_irq_eligible[31:0]),
    .sm_dbi           (sm_dbi),
    .sm_axilm         (sm_axilm),
    .st_dbi_wr        (st_dbi_wr),
    .write_done       (write_done),
    .wr_count         ({1'b0, wr_count})
);


// Advance the round-robin pointer when MSI-X grant is received.
assign rr_advance = (sm_int == SM_INT_GNT) && pcie_msix_grant;

// Round-robin arbiter: selects the next pending channel after last_served.
rr_arbiter_128 u_rr_arbiter (
    .clk        (clk),
    .reset_n    (reset_n),
  .req        (dma_irq_eligible),
    .advance    (rr_advance),
    .served_chn (chn_num),    // registered channel being processed, not combinatorial grant_chn
    .grant_chn  (grant_chn),
    .grant_vld  (grant_vld)
);

endmodule
   

