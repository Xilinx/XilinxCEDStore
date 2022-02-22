module user_control 
  #(
    parameter C_DATA_WIDTH = 64,
    parameter QID_MAX = 64,
    parameter TM_DSC_BITS = 16,
    parameter PF0_M_AXILITE_ADDR_MSK    =  32'h000FFFFF,
    parameter PF1_M_AXILITE_ADDR_MSK    =  32'h000FFFFF,
    parameter PF2_M_AXILITE_ADDR_MSK    =  32'h000FFFFF,
    parameter PF3_M_AXILITE_ADDR_MSK    =  32'h000FFFFF,
    parameter PF0_VF_M_AXILITE_ADDR_MSK =  32'h00000FFF,
    parameter PF1_VF_M_AXILITE_ADDR_MSK =  32'h00000FFF,
    parameter PF2_VF_M_AXILITE_ADDR_MSK =  32'h00000FFF,
    parameter PF3_VF_M_AXILITE_ADDR_MSK =  32'h00000FFF,
    parameter PF0_PCIEBAR2AXIBAR        =  32'h00000000,
    parameter PF1_PCIEBAR2AXIBAR        =  32'h10000000,
    parameter PF2_PCIEBAR2AXIBAR        =  32'h20000000,
    parameter PF3_PCIEBAR2AXIBAR        =  32'h30000000,
    parameter PF0_VF_PCIEBAR2AXIBAR     =  32'h40000000,
    parameter PF1_VF_PCIEBAR2AXIBAR     =  32'h50000000,
    parameter PF2_VF_PCIEBAR2AXIBAR     =  32'h60000000,
    parameter PF3_VF_PCIEBAR2AXIBAR     =  32'h70000000

    )
   (
    input axi_aclk,
    input axi_aresetn,
    input m_axil_wvalid,
    input m_axil_wready,
    output logic m_axil_rvalid,
    output logic m_axil_bvalid,
    input m_axil_bready,
    input m_axil_rready,
    input [31:0] m_axil_awaddr,
    input [31:0] m_axil_wdata,
    output logic [31:0] m_axil_rdata,
    input [31:0] m_axil_rdata_bram,
    input [31:0] m_axil_araddr,
    input        m_axil_arvalid,
    output  soft_reset_n,
    output  st_loopback,
    input axi_mm_h2c_valid,
    input axi_mm_h2c_ready,
    input axi_mm_c2h_valid,
    input axi_mm_c2h_ready,
    input axi_st_h2c_valid,
    input axi_st_h2c_ready,
    input axi_st_c2h_valid,
    input axi_st_c2h_ready,
    output reg [31:0] control_reg_c2h,
    output reg [10:0] c2h_num_pkt,
    output reg [10:0] c2h_st_qid,
    output clr_h2c_match,
    output reg [15:0] c2h_st_len,
    input [1:0] h2c_match,
    input [10:0] h2c_qid,
    input [31:0] h2c_count,
    input h2c_zero_byte,
    output reg [31:0] cmpt_size,
    output reg [255:0] wb_dat,
    output reg [TM_DSC_BITS-1:0] credit_out,
    output reg       credit_updt,
    output reg [TM_DSC_BITS-1:0] credit_needed,
    output reg [TM_DSC_BITS-1:0] credit_perpkt_in,
    output wire [15:0] buf_count,
    output wire h2c_dsc_bypass,
    output wire [1:0] c2h_dsc_bypass,
    input usr_irq_out_fail,
    input usr_irq_out_ack,
    output [4:0] usr_irq_in_vec,
    output [7:0] usr_irq_in_fnc,
    output reg usr_irq_in_vld,
    output st_rx_msg_rdy,
    input st_rx_msg_valid,
    input st_rx_msg_last,
    input [31:0] st_rx_msg_data,
    input         axis_c2h_drop,
    input         axis_c2h_drop_valid,
    input   [7:0] usr_flr_fnc,
    input         usr_flr_set,
    input         usr_flr_clr,
    output  reg [7:0] usr_flr_done_fnc,
    output        usr_flr_done_vld,
    output        c2h_mm_marker_req,
    input         c2h_mm_marker_rsp,
    output        h2c_mm_marker_req,
    input         h2c_mm_marker_rsp,
    output        h2c_st_marker_req,
    input         h2c_st_marker_rsp,
    input         c2h_st_marker_rsp,
    input         tm_dsc_sts_vld,
    input         tm_dsc_sts_byp,
    input         tm_dsc_sts_qen,
    input         tm_dsc_sts_dir,
    input         tm_dsc_sts_mm,
    input         tm_dsc_sts_error,
    input [10:0]  tm_dsc_sts_qid,
    input [7:0]   tm_dsc_sts_avl,
    input         tm_dsc_sts_qinv,
    input 	 tm_dsc_sts_irq_arm,
    output        tm_dsc_sts_rdy
    );

   reg [31:0] 	       control_reg_h2c;
   reg [31:0] 	       scratch_reg1, scratch_reg2;
   reg [4:0] 	       perf_ctl;
   reg 		       control_h2c_clr;
   reg 		       control_c2h_str;
   wire 	       perf_stop;
   wire 	       perf_clear;

   reg 		       start_counter;
   wire 	       start_c2h;
   reg [63:0] 	       data_count;
   reg [63:0] 	       valid_count;
   reg [15:0] 	       c2h_st_buffsz;

   reg 	     tm_vld_out;
   reg 	     tm_vld_out_d1;
   reg 	     tm_vld_out_d2;
   reg [7:0] axis_pkt_drop;
   reg [7:0] axis_pkt_accept;
   reg [6:0] dsc_bypass;
   reg [19:0] usr_irq;
   reg        usr_irq_d;
   reg [31:0] usr_irq_msk;
   reg [31:0] usr_irq_num;
   wire usr_irq_tmp;
   reg [2:0] usr_irq_clr;
   reg gen_qdma_reset;
   //wire soft_reset_n;
   reg [15:0] qdma_reset_count;
   localparam [15:0] QDMA_RESET_CYCLE_COUNT = 16'h0064;

   reg       invalid_axilm_addr;
   reg 	     clr_reset;
   reg [31:0] vdm_msg_rd_dout;
   reg h2c_zero_byte_reg;
   wire reg_x10_read;
   reg h2c_mm_marker_rsp_reg;
   reg c2h_mm_marker_rsp_reg;
   reg h2c_st_marker_rsp_reg;
   reg c2h_st_marker_rsp_reg;

   // Interpreting request on the axilite master interface
   wire [31:0] wr_addr;
   reg  [31:0] rd_addr;
/*   
   assign wr_addr = ((m_axil_awaddr >= PF0_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF1_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF0_M_AXILITE_ADDR_MSK) :
                    ((m_axil_awaddr >= PF1_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF2_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF1_M_AXILITE_ADDR_MSK) :
                    ((m_axil_awaddr >= PF2_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF3_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF2_M_AXILITE_ADDR_MSK) :
                    ((m_axil_awaddr >= PF3_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF0_VF_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF3_M_AXILITE_ADDR_MSK) :
                    ((m_axil_awaddr >= PF0_VF_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF1_VF_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF0_VF_M_AXILITE_ADDR_MSK) :
                    ((m_axil_awaddr >= PF1_VF_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF2_VF_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF1_VF_M_AXILITE_ADDR_MSK) :
                    ((m_axil_awaddr >= PF2_VF_PCIEBAR2AXIBAR) && (m_axil_awaddr < PF3_VF_PCIEBAR2AXIBAR)) ? (m_axil_awaddr & PF2_VF_M_AXILITE_ADDR_MSK) :
                     (m_axil_awaddr >= PF3_VF_PCIEBAR2AXIBAR)                                             ? (m_axil_awaddr & PF3_VF_M_AXILITE_ADDR_MSK) : 32'hFFFFFFFF;

   assign rd_addr = ((m_axil_araddr >= PF0_PCIEBAR2AXIBAR) && (m_axil_araddr < PF1_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF0_M_AXILITE_ADDR_MSK) :
                    ((m_axil_araddr >= PF1_PCIEBAR2AXIBAR) && (m_axil_araddr < PF2_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF1_M_AXILITE_ADDR_MSK) :
                    ((m_axil_araddr >= PF2_PCIEBAR2AXIBAR) && (m_axil_araddr < PF3_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF2_M_AXILITE_ADDR_MSK) :
                    ((m_axil_araddr >= PF3_PCIEBAR2AXIBAR) && (m_axil_araddr < PF0_VF_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF3_M_AXILITE_ADDR_MSK) :
                    ((m_axil_araddr >= PF0_VF_PCIEBAR2AXIBAR) && (m_axil_araddr < PF1_VF_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF0_VF_M_AXILITE_ADDR_MSK) :
                    ((m_axil_araddr >= PF1_VF_PCIEBAR2AXIBAR) && (m_axil_araddr < PF2_VF_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF1_VF_M_AXILITE_ADDR_MSK) :
                    ((m_axil_araddr >= PF2_VF_PCIEBAR2AXIBAR) && (m_axil_araddr < PF3_VF_PCIEBAR2AXIBAR)) ? (m_axil_araddr & PF2_VF_M_AXILITE_ADDR_MSK) :
                     (m_axil_araddr >= PF3_VF_PCIEBAR2AXIBAR)                                             ? (m_axil_araddr & PF3_VF_M_AXILITE_ADDR_MSK) : 32'hFFFFFFFF;
  */
   assign wr_addr =  32'h0 | m_axil_awaddr[11:0];
//   assign rd_addr =  32'h0 | m_axil_araddr[11:0];
   
   // Register Write
   //
   // To Control AXI-Stream pattern generator and checker
   //
   // address 0x0000 : Qid 
   // address 0x0004 : C2H transfer length
   // address 0x0008 : C2H Control
   //                  [0] Streaming loop back  // not supported now
   //                  [1] start C2H
   //                  [2] Immediate data
   //                  [3] Disable C2H completion transfer to Host
   //                  [4] Reserved 
   //                  [5] Marker 
   // address 0x00C0 : H2C Control
   //                  [0] clear match for H2C transfer
   // address 0x0010 : H2C Qid, 3'b0, h2c transfer match // Read only
   // address 0x0014 : H2C tranfer count // Read only
   // address 0x0020 : C2H number of packets to transfer
   // address 0x0030 : C2H Write back data [31:0]
   // address 0x0034 : C2H Write back data [63:32]
   // address 0x0038 : C2H Write back data [95:64]
   // address 0x003C : C2H Write back data [127:96]
   // address 0x0040 : C2H Write back data [159:128]
   // address 0x0044 : C2H Write back data [191:160]
   // address 0x0048 : C2H Write back data [223:192]
   // address 0x004C : C2H Write back data [255:224]
   // address 0x0050 : C2H Write back type [31:0]
   // address 0x0060 : Scratch pad reg0 
   // address 0x0064 : Scratch pad reg1
   // address 0x0070 : Performance control
   //                  [0] start
   //                  [1] end
   //                  [2] clear
   //                  [4:3] : 00 AXI-MM H2C, 01 AXI-MM C2H
   //                        : 10 AXI-ST H2C, 11 AXI-ST C2H
   // address 0x0074 : Performance data count [31:0]
   // address 0x0078 : Performance data count [63:30]
   // address 0x007C : Performance valid count [31:0]
   // address 0x0080 : Performance valid count [63:30]
   // address 0x0084 : C2H Streaming Buffer size, default 4K
   // address 0x0088 : C2H Streaming packet drop count
   // address 0x008C : C2H Streaming packet accepted 
   // address 0x0090 : DSC bypass loopback [0] H2C dsc loopback [1] C2H dsc loopback 
   // address 0x0094 : user interrupt reg 
   // address 0x0098 : Multiple user interrupt Mask reg 
   // address 0x009C : Multiple user interrupt reg 
   // address 0x00A0 : DMA Control
   // address 0x00A4 : VMD messge read
   
   wire clr_marker_rsp_pls;

   always @(posedge axi_aclk) begin
      if (!axi_aresetn) begin
	 c2h_st_qid <= 1;
	 c2h_st_len <= 16'h80;  // default transfer size set to 128Bytes
	 control_reg_h2c <= 32'h0;
	 control_reg_c2h <= 32'h0;
	 wb_dat[255:0] <= 0;
	 cmpt_size[31:0] <= 0;
	 c2h_num_pkt <= 11'h1;
	 perf_ctl <= 0;
//	 perf_ctl <= 5'b11001;
	 scratch_reg1 <=0;
	 scratch_reg2 <=0;
	 c2h_st_buffsz<=16'h1000;  // default buff size 4K
         dsc_bypass <= 7'b0;
	 usr_irq <= 'h0;
	 usr_irq_msk <= 'h0;
	 usr_irq_num <= 'h0;
	 invalid_axilm_addr <= 'h0;
	 gen_qdma_reset <= 1'b0;
      end
      else if (m_axil_wvalid && m_axil_wready ) begin
	 case (wr_addr)
	   32'h00 : c2h_st_qid     <= m_axil_wdata[10:0];
	   32'h04 : c2h_st_len     <= m_axil_wdata[15:0];
	   32'h08 : control_reg_c2h<= m_axil_wdata[31:0];
	   32'h0C : control_reg_h2c<= m_axil_wdata[31:0];
	   32'h20 : c2h_num_pkt[10:0]  <= m_axil_wdata[10:0];
	   32'h30 : wb_dat[31:0]   <= m_axil_wdata[31:0];
	   32'h34 : wb_dat[63:32]  <= m_axil_wdata[31:0];
	   32'h38 : wb_dat[95:64]  <= m_axil_wdata[31:0];
	   32'h3C : wb_dat[127:96] <= m_axil_wdata[31:0];
	   32'h40 : wb_dat[159:128]<= m_axil_wdata[31:0];
	   32'h44 : wb_dat[191:160]<= m_axil_wdata[31:0];
	   32'h48 : wb_dat[223:192]<= m_axil_wdata[31:0];
	   32'h4C : wb_dat[255:224]<= m_axil_wdata[31:0];
	   32'h50 : cmpt_size[31:0]  <= m_axil_wdata[31:0];
	   32'h60 : scratch_reg1[31:0]  <= m_axil_wdata[31:0];
	   32'h64 : scratch_reg2[31:0]  <= m_axil_wdata[31:0];
	   32'h70 : perf_ctl[4:0]  <= m_axil_wdata[4:0];
	   32'h84 : c2h_st_buffsz  <= m_axil_wdata[15:0];
	   32'h90 : dsc_bypass[6:0]    <= m_axil_wdata[6:0];
	   32'h94 : usr_irq[19:0] <= m_axil_wdata[19:0];
	   32'h98 : usr_irq_msk[31:0] <= m_axil_wdata[31:0];
	   32'h9C : usr_irq_num[31:0] <= m_axil_wdata[31:0];
	   32'hA0 : gen_qdma_reset <= m_axil_wdata[0]; //Write 1 to reset, self clearing register
       32'hFFFFFFFF: invalid_axilm_addr <= 1'b1;
	 endcase // case (m_axil_awaddr[15:0])
      end // if (m_axil_wvalid && m_axil_wready )
      else begin
	 control_reg_c2h <= {control_reg_c2h[31:2],start_c2h,control_reg_c2h[0]};
	 control_reg_h2c <= {control_reg_h2c[31:1],clr_h2c_match};
	 perf_ctl[4:0] <= {perf_ctl[4:3],perf_clear,perf_stop, (perf_ctl[0]& ~perf_stop)};
	 usr_irq[16:0] <= {usr_irq[16:1],usr_irq_in_vld};
	 gen_qdma_reset <= ~clr_reset & gen_qdma_reset;
	 dsc_bypass  <= {clr_marker_rsp_pls, dsc_bypass[5:0]};
	 usr_irq_num <= usr_irq_clr[2] ? 32'h0 : usr_irq_num;
      end
   end // always @ (posedge axi_aclk)

   
    //  Descriptor bypass / Marker request
   assign h2c_mm_marker_req = dsc_bypass[3];
   assign c2h_mm_marker_req = dsc_bypass[4];
   assign h2c_st_marker_req = dsc_bypass[5];

   reg clr_marker_rsp_d;
   assign clr_marker_rsp_pls = dsc_bypass[6] & ~clr_marker_rsp_d;
   
   always @(posedge axi_aclk)
      if (~axi_aresetn) begin
	 clr_marker_rsp_d <= 0;
	 h2c_mm_marker_rsp_reg <= 0;
	 c2h_mm_marker_rsp_reg <= 0;
	 h2c_st_marker_rsp_reg <= 0;
	 c2h_st_marker_rsp_reg <= 0;
      end 
      else begin
	 clr_marker_rsp_d <= dsc_bypass[6];
	 h2c_mm_marker_rsp_reg <= h2c_mm_marker_rsp ? 1'b1 : clr_marker_rsp_pls ? 1'b0 : h2c_mm_marker_rsp_reg;
	 c2h_mm_marker_rsp_reg <= c2h_mm_marker_rsp ? 1'b1 : clr_marker_rsp_pls ? 1'b0 : c2h_mm_marker_rsp_reg;
	 h2c_st_marker_rsp_reg <= h2c_st_marker_rsp ? 1'b1 : clr_marker_rsp_pls ? 1'b0 : h2c_st_marker_rsp_reg;
	 c2h_st_marker_rsp_reg <= c2h_st_marker_rsp ? 1'b1 : clr_marker_rsp_pls ? 1'b0 : c2h_st_marker_rsp_reg;
	 
      end
      
   
   // Soft reset
   always @(posedge axi_aclk) begin
      if (~axi_aresetn) begin
	 qdma_reset_count <= 16'h0;
	 clr_reset <= 1'b0;
      end 
      else if (gen_qdma_reset & ~clr_reset)
	if (qdma_reset_count != QDMA_RESET_CYCLE_COUNT)
	    qdma_reset_count <= qdma_reset_count + 1;
	else begin
	   qdma_reset_count <= 'h0;
	   clr_reset <= 1'b1;
	end
      else
	clr_reset <= 1'b0;
   end
   assign soft_reset_n = ~gen_qdma_reset;
  
   // User interrupt
   logic usr_irq_gen;
   assign usr_irq_gen = usr_irq[0] ? usr_irq[0] : usr_irq_tmp;
   
   always @(posedge axi_aclk) begin
     if (~axi_aresetn) begin
          usr_irq_d <= 1'b0;
          usr_irq_in_vld <= 1'b0;
	  usr_irq_clr[2:0] <= 1'b0;
     end	      
     else begin
          usr_irq_in_vld <= (usr_irq_gen & ~usr_irq_d) ? 1'b1 : usr_irq_out_ack ? 1'b0 : usr_irq_in_vld;
	  usr_irq_d <= usr_irq_gen;
	  usr_irq_clr[2:0] <= {usr_irq_clr[1:0],(m_axil_rvalid & m_axil_rready & (rd_addr == 32'h9C))};
     end 
   end // always @ (posedge axi_aclk)
   
   assign usr_irq_tmp = |(usr_irq_msk & usr_irq_num);
   
   assign usr_irq_in_vec = usr_irq[8:4];   // vector
   assign usr_irq_in_fnc = usr_irq[19:12]; // function number

   // Register Read
   assign reg_x10_read = (m_axil_rvalid & m_axil_rready & (rd_addr == 32'h10));

   reg rvalid;
   reg bvalid;
   
   always @(posedge axi_aclk) begin
     if (~axi_aresetn) begin
	rvalid <= 0;
	m_axil_rvalid <= 0;
	bvalid <= 0;
	m_axil_bvalid <= 0;
	rd_addr <= 'h0;
     end
     else begin
	rvalid <= m_axil_arvalid ? 1'b1 : m_axil_rvalid ? 1'b0 : rvalid;
	m_axil_rvalid <= ~m_axil_rvalid & rvalid & m_axil_rready;
	bvalid <= m_axil_wvalid ? 1'b1 : m_axil_bvalid ? 1'b0 : bvalid;
	m_axil_bvalid <= ~m_axil_bvalid & bvalid & m_axil_bready;
	rd_addr <= m_axil_arvalid ? {31'b0 | m_axil_araddr[11:0]} : rd_addr;
     end
   end
   
   always_comb begin
      case (rd_addr)
	32'h00 : m_axil_rdata  = (32'h0 | c2h_st_qid[10:0]);
	32'h04 : m_axil_rdata  = (32'h0 | c2h_st_len);
	32'h08 : m_axil_rdata  = (32'h0 | control_reg_c2h[31:0]);
	32'h0C : m_axil_rdata  = (32'h0 | control_reg_h2c[31:0]);
	32'h10 : m_axil_rdata  = (32'h0 | {h2c_qid[10:0],1'b0,h2c_match[1],h2c_zero_byte_reg,h2c_match[0]});
	32'h14 : m_axil_rdata  = h2c_count;
	32'h20 : m_axil_rdata  = (32'h0 | c2h_num_pkt[10:0]);
	32'h30 : m_axil_rdata  = wb_dat[31:0];
	32'h34 : m_axil_rdata  = wb_dat[63:32];
	32'h38 : m_axil_rdata  = wb_dat[95:64];
	32'h3C : m_axil_rdata  = wb_dat[127:96];
	32'h40 : m_axil_rdata  = wb_dat[159:128];
	32'h44 : m_axil_rdata  = wb_dat[191:160];
	32'h48 : m_axil_rdata  = wb_dat[223:192];
	32'h4C : m_axil_rdata  = wb_dat[255:224];
	32'h50 : m_axil_rdata  = cmpt_size[31:0];
	32'h60 : m_axil_rdata  = scratch_reg1[31:0];
	32'h64 : m_axil_rdata  = scratch_reg2[31:0];
	32'h70 : m_axil_rdata  = {32'h0 | perf_ctl[4:0]};
	32'h74 : m_axil_rdata  = data_count[31:0];
	32'h78 : m_axil_rdata  = data_count[63:32];
	32'h7C : m_axil_rdata  = valid_count[31:0];
	32'h80 : m_axil_rdata  = valid_count[63:32];
	32'h84 : m_axil_rdata  = c2h_st_buffsz[15:0];
	32'h88 : m_axil_rdata  = {32'h0 | axis_pkt_drop[7:0]};
	32'h8C : m_axil_rdata  = {32'h0 | axis_pkt_accept[7:0]};
	32'h90 : m_axil_rdata  = {12'h0, c2h_st_marker_rsp_reg, h2c_st_marker_rsp_reg, c2h_mm_marker_rsp_reg, h2c_mm_marker_rsp_reg, 9'h0, dsc_bypass[6:0]};
	32'h94 : m_axil_rdata  = {32'h0 | usr_irq[16:0]};
	32'h98 : m_axil_rdata  = {32'h0 | usr_irq_msk[31:0]};
	32'h9C : m_axil_rdata  = {32'h0 | usr_irq_num[31:0]};
	32'hA0 : m_axil_rdata  = {32'h0 | gen_qdma_reset};
	32'hA4 : m_axil_rdata  = {32'h0 | vdm_msg_rd_dout};
	32'hFFFFFFFF: m_axil_rdata = {32'h0 | invalid_axilm_addr};
    default : m_axil_rdata  = 'h0;
      endcase // case (m_axil_araddr[31:0]...
    end // always_comb begin
   reg perf_ctl_stp;
   reg perf_ctl_clr;

   assign h2c_dsc_bypass = dsc_bypass[0];  // 1 : h2c dsc bypass out looped back to dsc bypass in. 0 no loopback 
   // C2h Dsc bypass options
   // 2'b00 : Normal mode
   // 2'b01 : C2H Cash bypass mode loopback
   // 2'b10 : C2H simple bypass mode loopback

  assign c2h_dsc_bypass = dsc_bypass[2:1];  // 1 : h2c dsc bypass out looped back to dsc bypass in. 0 no loopback 
    
   always @(posedge axi_aclk) begin
      if (!axi_aresetn) begin
	 control_h2c_clr <= 0;
	 control_c2h_str <= 0;
	 perf_ctl_stp <= 0;
	 perf_ctl_clr <= 0;
      end
      else begin
	control_h2c_clr <= control_reg_h2c[0];
	control_c2h_str <= control_reg_c2h[1];
	 perf_ctl_stp <=  perf_ctl[1];
	 perf_ctl_clr <=  perf_ctl[2];
      end
   end
//   assign clr_h2c_match = control_reg_h2c[0] & ~control_h2c_clr;
   assign clr_h2c_match = reg_x10_read | (control_reg_h2c[0] & ~control_h2c_clr);
   assign start_c2h = (control_reg_c2h[1] & ~control_c2h_str) & ~control_reg_c2h[2];  // for immediate data no credits will be used 
   assign perf_stop = perf_ctl[1] & ~perf_ctl_stp;
   assign perf_clear = perf_ctl[2] & ~perf_ctl_clr;
	 
   assign st_loopback = control_reg_c2h[0];       // Streaming loopback mode
   
   wire perf_start = perf_ctl[0];
   // Performance 
   wire 	 valids;
   wire 	 readys;
   assign valids = axi_mm_h2c_valid | axi_mm_c2h_valid | axi_st_h2c_valid | axi_st_c2h_valid;
   assign readys = axi_mm_h2c_ready | axi_mm_c2h_ready | axi_st_h2c_ready | axi_st_c2h_ready;

   reg 		 valids_d1;
   wire 	 valids_pls;
   wire 	 vld_rdys_pls;
   
   always @(posedge axi_aclk)
      if (!axi_aresetn | perf_stop) begin
	 valids_d1 <= 1'b0;
      end
      else if (~valids_d1) begin
	 valids_d1 <= valids;
      end
   
   assign valids_pls = valids & ~valids_d1;
   assign vld_rdys_pls = (valids & ~valids_d1) & readys;
   
   always @(posedge axi_aclk) begin
      if (!axi_aresetn | perf_stop) begin
	 start_counter <= 0;      end
      else if (perf_start & valids & readys)
	start_counter <= 1'b1;
   end
   
   always @(posedge axi_aclk) begin
      if (!axi_aresetn | perf_clear) begin
	 data_count <= 0;
	 valid_count <= 0;
      end
      else begin
	 case (perf_ctl[4:3])
	    2'b00 : begin
	       data_count <= ((vld_rdys_pls | start_counter) && axi_mm_h2c_valid && axi_mm_h2c_ready) ? data_count+1 :data_count;
	       valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
	    end
	   2'b01 : begin
	      data_count <= ((vld_rdys_pls | start_counter) && axi_mm_c2h_valid && axi_mm_c2h_ready) ? data_count+1 :data_count;
	      valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
	   end
	   2'b10 : begin
	      data_count <= ((vld_rdys_pls | start_counter) && axi_st_h2c_valid && axi_st_h2c_ready) ? data_count+1 :data_count;
	      valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
	   end
	   2'b11 : begin
	      data_count <= ((vld_rdys_pls | start_counter) && axi_st_c2h_valid && axi_st_c2h_ready) ? data_count+1 :data_count;
	      valid_count <= (valids_pls | start_counter) ? valid_count + 1 : valid_count;
	   end
	 endcase // case (perf_sel[1:0])
      end
   end // always @ (posedge axi_aclk)

   // H2C zero byte    
   always@(posedge axi_aclk) begin
     if (!axi_aresetn) begin
     h2c_zero_byte_reg <= 'b0;
     end else begin
      h2c_zero_byte_reg <= axi_st_h2c_valid & h2c_zero_byte ? 1'b1 : reg_x10_read ? 1'b0 : h2c_zero_byte_reg;
      end
   end


   // Credit BRAM and 
   // Traffic manger Credit block

   assign tm_dsc_sts_rdy = 1;  // always set to 1.
   (* mark_debug = "true" *)localparam [1:0] 
     SM_IDLE = 2'b00,
     SM_TFR  = 2'b01,
     SM_END  = 2'b10;
   (* mark_debug = "true" *) reg [1:0] sm_crdt;
   
   reg [7:0]  credit_sent;
   reg start_c2h_d1;
   wire wr_credit_en;
   reg 	tm_update_d1;
   wire tm_update;
   wire [TM_DSC_BITS-1:0] rd_credit_out_bram;
   wire [TM_DSC_BITS-1:0] wr_credit_in;
   wire [10:0] 		  wr_credit_qid;
   wire [10:0] 		  rd_credit_qid;
   reg 			  tm_dsc_sts_qinv_d1;
   reg 			  tm_dsc_sts_vld_d1;
   reg [7:0] 		  tm_dsc_sts_avl_d1;
   reg [10:0] 		  tm_dsc_sts_qid_d1;
   reg [TM_DSC_BITS-1:0]  rd_credit_out;

   always@(posedge axi_aclk) begin
      tm_dsc_sts_avl_d1 <= tm_dsc_sts_avl;
      tm_update_d1 <= tm_update;
      tm_dsc_sts_qinv_d1 <= tm_dsc_sts_qinv;
      tm_dsc_sts_qid_d1 <= tm_dsc_sts_qid;

      rd_credit_out <= ~tm_update ? rd_credit_out_bram : rd_credit_out;
   end
//   assign tm_update = tm_dsc_sts_vld & tm_dsc_sts_qen & ~tm_dsc_sts_mm & tm_dsc_sts_dir ;
   assign tm_update = tm_dsc_sts_vld & (tm_dsc_sts_qen | tm_dsc_sts_qinv ) & ~tm_dsc_sts_mm & tm_dsc_sts_dir ;

   assign wr_credit_en = tm_update_d1 | credit_updt;
   assign wr_credit_in = (tm_update_d1 & tm_dsc_sts_qinv_d1) ? 'h0 : 
			  credit_updt ? rd_credit_out_bram - credit_out : 
			  rd_credit_out_bram + tm_dsc_sts_avl_d1;

   assign wr_credit_qid = credit_updt ? c2h_st_qid : tm_dsc_sts_qid_d1;
   assign rd_credit_qid = tm_update ? tm_dsc_sts_qid : c2h_st_qid;
   
   xpm_memory_sdpram # 
     (
        
      // Common module parameters
      .MEMORY_SIZE             (TM_DSC_BITS * 11),      //positive integer
      .MEMORY_PRIMITIVE        ("block"),               //string; "auto", "distributed", "block" or "ultra";
      .CLOCKING_MODE           ("common_clock"),        //string; "common_clock", "independent_clock" 
      .MEMORY_INIT_FILE        ("none"),                //string; "none" or "<filename>.mem" 
      .MEMORY_INIT_PARAM       (""    ),                //string;
      .USE_MEM_INIT            (1),                     //integer; 0,1
      .WAKEUP_TIME             ("disable_sleep"),       //string; "disable_sleep" or "use_sleep_pin" 
      .MESSAGE_CONTROL         (0),                     //integer; 0,1
      .ECC_MODE                ("no_ecc"),              //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
      .AUTO_SLEEP_TIME         (0),                     //Do not Change
      .USE_EMBEDDED_CONSTRAINT (0),                     //integer: 0,1
      
      // Port A module parameters
      .WRITE_DATA_WIDTH_A      (TM_DSC_BITS),           //positive integer
      .BYTE_WRITE_WIDTH_A      (TM_DSC_BITS),           //integer; 8, 9, or WRITE_DATA_WIDTH_A value
      .ADDR_WIDTH_A            (11),                    //positive integer
      
      // Port B module parameters
      .READ_DATA_WIDTH_B       (TM_DSC_BITS),           //positive integer
      .ADDR_WIDTH_B            (11),                    //positive integer
      .READ_RESET_VALUE_B      ("0"),                   //string
      .READ_LATENCY_B          (1),                     //non-negative integer
      .WRITE_MODE_B            ("read_first")           //string; "write_first", "read_first", "no_change" 
      
      ) xpm_mem_user_credi_i 
       (
	
	// Common module ports
        .sleep          (1'b0),
        
        // Port A module ports
        .clka           (axi_aclk),
        .ena            (wr_credit_en),
        .wea            (wr_credit_en),
        .addra          (wr_credit_qid),
        .dina           (wr_credit_in),
        .injectsbiterra (1'b0),
        .injectdbiterra (1'b0),
        
        // Port B module ports
        .clkb           (axi_aclk),
        .rstb           (~axi_aresetn),
        .enb            (1'b1),
        .regceb         (1'b1),
        .addrb          (rd_credit_qid),
        .doutb          (rd_credit_out_bram),
        .sbiterrb       (),
        .dbiterrb       ()
        );

   assign buf_count = c2h_st_buffsz/(C_DATA_WIDTH/8);
   
   always @(posedge axi_aclk) begin
      if (!axi_aresetn) begin
	 tm_vld_out <= 1'b0;
	 tm_vld_out_d1 <= 1'b0;
	 tm_vld_out_d2 <= 1'b0;
	 start_c2h_d1 <=0;
      end
      else begin
	 tm_vld_out <= tm_dsc_sts_vld & tm_dsc_sts_qen ;
	 tm_vld_out_d1 <=tm_vld_out;
	 tm_vld_out_d2 <=tm_vld_out_d1;
	 start_c2h_d1 <= start_c2h;
      end
   end

   always @(posedge axi_aclk) begin
      if (!axi_aresetn) begin
	 sm_crdt <= SM_IDLE;
	 credit_updt <= 1'b0;
	 credit_out <= 0;
	 credit_sent <= 0;
      end
      else
	case (sm_crdt)
	  SM_IDLE : begin  // 0
	     if (start_c2h_d1) begin
		credit_updt <= 1'b1;
		if (rd_credit_out >= credit_needed) begin
		   credit_out <= credit_needed;
		   sm_crdt <= SM_END;
		end
		else begin
		   credit_out <= rd_credit_out;
		   sm_crdt <= SM_TFR;
		   credit_sent <= rd_credit_out;
		end
	     end
	  end
	  SM_TFR : begin // 1
	     if (tm_vld_out_d2 & (rd_credit_out >= (credit_needed -credit_sent))) begin
		credit_updt <= 1'b1;
		credit_out  <= credit_needed - credit_sent;
		credit_sent <= credit_sent + (credit_needed - credit_sent);
		sm_crdt <= SM_END;
	     end
	     else if (tm_vld_out_d2 & (rd_credit_out > 0)) begin
		credit_updt <= 1'b1;
		credit_out  <= rd_credit_out;
		credit_sent <= credit_sent + rd_credit_out;
		sm_crdt <= SM_TFR;
	     end
	     else
		credit_updt <= 1'b0;
	     
	  end
	  SM_END : begin // 2
	     sm_crdt <= SM_IDLE;
	     credit_updt <= 1'b0;
	     credit_sent <= 0;
	  end
	endcase // case (sm_crdt)
   end

   always @(posedge axi_aclk) begin
      if (!axi_aresetn) begin
	 credit_needed <= 0;
	 credit_perpkt_in <= 0;
      end
      else begin
	 // Designing for 4K buffer size only
	 if (start_c2h) begin
	   credit_needed    <= ((c2h_st_len[15:0] < c2h_st_buffsz[15:0]) ? 1 : c2h_st_len[15:12]+|c2h_st_len[11:0]) * c2h_num_pkt[7:0];
	   credit_perpkt_in <=  (c2h_st_len[15:0] < c2h_st_buffsz[15:0]) ? 1 : c2h_st_len[15:12]+|c2h_st_len[11:0];
	 end
      end
   end

   // Axi Streaming Paket drop
   always @(posedge axi_aclk) begin
      if (!axi_aresetn) begin
	 axis_pkt_drop <=0;
	 axis_pkt_accept <=0;
      end
      else begin
	 if (start_c2h) begin
	    axis_pkt_drop <= 0;
	    axis_pkt_accept <=0;
	 end
	 else if (axis_c2h_drop_valid) begin
	    axis_pkt_drop   <= axis_c2h_drop ? axis_pkt_drop + 1 : axis_pkt_drop;
	    axis_pkt_accept <= ~axis_c2h_drop ? axis_pkt_accept+1 : axis_pkt_accept;
	 end
      end
   end

   // Checking FLR request and provide ack
   reg       usr_flr_done_vld_reg;
   reg       usr_flr_done_vld_reg_reg;
   
   always @ (posedge axi_aclk) begin
      if (!axi_aresetn) begin
         usr_flr_done_fnc <= 'h0;
         usr_flr_done_vld_reg <= 'h0;
         usr_flr_done_vld_reg_reg <= 'h0;
      end
      else begin
         usr_flr_done_vld_reg_reg <= usr_flr_done_vld_reg;
         if (usr_flr_set && ~usr_flr_clr) begin
           usr_flr_done_fnc <= usr_flr_fnc;
           usr_flr_done_vld_reg <= 1'b1;
         end
         else if (usr_flr_clr) begin
           usr_flr_done_fnc <= 'h0;
           usr_flr_done_vld_reg <= 1'b0;
         end
         else begin
           usr_flr_done_fnc <= usr_flr_done_fnc;
           usr_flr_done_vld_reg <= usr_flr_done_vld_reg;
         end
         
      end
   end

   assign usr_flr_done_vld = usr_flr_done_vld_reg && ~usr_flr_done_vld_reg_reg; // generate one-cycle pulse

  // VMD messge storage

   wire fifo_full;
   wire fifo_rd_en;
   wire [31:0] rd_dout;
   wire vdm_empty;
   assign st_rx_msg_rdy = ~fifo_full;

   assign fifo_rd_en =  m_axil_arvalid & (rd_addr == 32'hA4);

   always @(posedge axi_aclk)
   	  vdm_msg_rd_dout <= fifo_rd_en ? rd_dout : 32'b0;

   xpm_fifo_sync # 
     (
      .FIFO_MEMORY_TYPE     ("block"), //string; "auto", "block", "distributed", or "ultra";
      .ECC_MODE             ("no_ecc"), //string; "no_ecc" or "en_ecc";
      .FIFO_WRITE_DEPTH     (128), //positive integer
      .WRITE_DATA_WIDTH     (32), //positive integer
      .WR_DATA_COUNT_WIDTH  (7), //positive integer
      .PROG_FULL_THRESH     (10), //positive integer
      .FULL_RESET_VALUE     (0), //positive integer; 0 or 1
      .READ_MODE            ("fwft"), //string; "std" or "fwft";
      .FIFO_READ_LATENCY    (1), //positive integer;
      .READ_DATA_WIDTH      (32), //positive integer
      .RD_DATA_COUNT_WIDTH  (7), //positive integer
      .PROG_EMPTY_THRESH    (10), //positive integer
      .DOUT_RESET_VALUE     ("0"), //string
      .WAKEUP_TIME          (0) //positive integer; 0 or 2;
      ) xpm_fifo_vdm_msg_i 
       (
	.sleep           (1'b0),
	.rst             (~axi_aresetn),
	.wr_clk          (axi_aclk),
	.wr_en           (st_rx_msg_valid & st_rx_msg_rdy),
	.din             (st_rx_msg_data),
	.full            (fifo_full),
	.prog_full       (prog_full),
	.wr_data_count   (),
	.overflow        (overflow),
	.wr_rst_busy     (wr_rst_busy),
	.rd_en           (fifo_rd_en),
	.dout            (rd_dout),
	.empty           (vdm_empty),
	.prog_empty      (prog_empty),
	.rd_data_count   (),
	.underflow       (underflow),
	.rd_rst_busy     (rd_rst_busy),
	.injectsbiterr   (1'b0),
	.injectdbiterr   (1'b0),
	.sbiterr         (),
	.dbiterr         ()
	);
   // End of xpm_fifo_sync instance declaration


endmodule // user_control
