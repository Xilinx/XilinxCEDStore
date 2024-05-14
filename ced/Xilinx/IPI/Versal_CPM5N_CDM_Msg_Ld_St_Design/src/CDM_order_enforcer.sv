`timescale 1ps / 1ps

// This module will enforce order between MSG ST and MSG LD interface.
// It is used for making sure the read request issued never crosses the write request.
// It will also detect if a write request passes another write request.
// If the IP illegally re-order the request, then data checking on read will fail for that address

// Purpose: This module will monitor the Address requested in MSG ST and MSG LD requests.
//          If the module detects that MSG LD is trying to "read" on the address that
//          hasn't been "written" to by MSG ST, it will throttle MSG LD interface
//          until the response cookie has come back for a MSG ST request with that Address

// Note:    To increase the likelihood the re-ordering occurs, it's best to issue the MSG ST and MSG LD
//          of the same size or at the very least keep MSG ST packet short. That way we increase the
//          amount of MSG ST request to match the MSG LD request which will always be one clock cycle.

module CDM_order_enforcer #(
  parameter ADDR_WIDTH  = 12, // Address Width. Reduce to ease timing.
  parameter TCQ         = 1
)(
  // Global
  input logic                       user_clk,
  input logic                       user_reset_n,
  
  // Control
  input logic                       en,    // Enable / Disable this module
  input logic                       start, // Start the traffic generator
  
  input logic [31:0]                pci0_msgst_host_addr_0,
  input logic [31:0]                pci0_msgst_host_addr_1,
  input logic [31:0]                pci0_msgld_host_addr_0,
  input logic [31:0]                pci0_msgld_host_addr_1,
  
  // Status
  output logic                      error,
  
  // Traffic Generator Side
  cdx5n_cmpt_msgst_if.s             fab0_cmpt_msgst_fab_int_tg,
  cdx5n_mm_byp_out_rsp_if.m         fab0_byp_out_msgld_dat_fab_int_tg,
  cdx5n_dsc_crd_in_msgld_req_if.s   fab0_dsc_crd_msgld_req_fab_int_tg,
  
  // CPM5N Side
  cdx5n_cmpt_msgst_if.m             fab0_cmpt_msgst_fab_int,
  cdx5n_mm_byp_out_rsp_if.s         fab0_byp_out_msgld_dat_fab_int,
  cdx5n_dsc_crd_in_msgld_req_if.m   fab0_dsc_crd_msgld_req_fab_int
);

localparam [11:0] MSGST_RESPONSE_COOKIE = 12'h0;
localparam [11:0] MSGLD_RESPONSE_COOKIE = 12'h1;
localparam [8:0]  MAX_MSGST_MSGLD_DIFF  = 9'h0FF; // Since MSGST can pass MSGLD legally, limit to 255 (must be < the amount of MSGST Req to fill the whole address space).
                                                  // MSGST can only get ahead by this amount to ensure data is not overwritten before read.
                                                  // The limit will be loose (can be a little extra) to ease timing.

logic        data_err;
logic [15:0] expected_data         = 16'b0;
logic [11:0] msgld_addr,msgst_addr;
logic        msgld_hold,msgst_hold;
logic [15:0] msgst_data_pattern;
logic [15:0] msgld_data_pattern;
logic [8:0]  msgst_msgld_diff      ; // This counts requests differences
logic [8:0]  msgld_rsps,msgst_rsps ; // This counts responses
logic [8:0]  msgld_reqs,msgst_reqs ; // This counts requests
logic [8:0]  msgld_allowed_cnts    ;

enum {IDLE, SEND_PKT} msgld_sm, msgst_sm;// = IDLE;

always_ff @(posedge user_clk) begin
  if (~user_reset_n | (~en)) begin
    msgst_data_pattern  <= #TCQ 16'b0;
    msgld_data_pattern  <= #TCQ 16'b0;
  end else begin
    if (fab0_cmpt_msgst_fab_int.vld && fab0_cmpt_msgst_fab_int.rdy && fab0_cmpt_msgst_fab_int.intf.eop) begin
      msgst_data_pattern  <= #TCQ msgst_data_pattern + 1;
    end else begin
      msgst_data_pattern  <= #TCQ msgst_data_pattern;
    end
    
    if (fab0_byp_out_msgld_dat_fab_int.vld && fab0_byp_out_msgld_dat_fab_int.rdy && 
       (fab0_byp_out_msgld_dat_fab_int.intf.u.cdm.response_cookie[0] == MSGLD_RESPONSE_COOKIE[0])) begin
      msgld_data_pattern  <= #TCQ msgld_data_pattern + 1;
    end else begin
      msgld_data_pattern  <= #TCQ msgld_data_pattern;
    end
  end
end


// Send 1DW up to 4KB then repeat
localparam ADDR_INCREMENT = 4; // This is length

// MSGST SM
always_ff @(posedge user_clk) begin
  if (~user_reset_n | (~en)) begin
    msgst_addr          <= #TCQ 12'b0;
    msgst_sm            <= #TCQ IDLE;
  end else begin
    case (msgst_sm)
      IDLE:
      begin
        if (start) begin
          msgst_sm      <= #TCQ SEND_PKT;
        end
      end
      SEND_PKT:
      begin
        if (fab0_cmpt_msgst_fab_int.vld && fab0_cmpt_msgst_fab_int.rdy && fab0_cmpt_msgst_fab_int.intf.eop) begin
          msgst_addr    <= #TCQ msgst_addr + ADDR_INCREMENT;
        end
        
        if (!start) begin
          msgst_sm      <= #TCQ IDLE;
        end else begin
          msgst_sm      <= #TCQ SEND_PKT;
        end
      end
    endcase
  end
end

// MSGLD SM
always_ff @(posedge user_clk) begin
  if (~user_reset_n | (~en)) begin
    msgld_addr          <= #TCQ 12'b0;
    msgld_sm            <= #TCQ IDLE;
  end else begin
    case (msgld_sm)
      IDLE:
      begin
        if (start) begin
          msgld_sm      <= #TCQ SEND_PKT;
        end
      end
      SEND_PKT:
      begin
        if (fab0_dsc_crd_msgld_req_fab_int.vld && fab0_dsc_crd_msgld_req_fab_int.rdy) begin
          msgld_addr    <= #TCQ msgld_addr + ADDR_INCREMENT;
        end
        
        if (!start) begin
          msgld_sm      <= #TCQ IDLE;
        end else begin
          msgld_sm      <= #TCQ SEND_PKT;
        end
      end
    endcase
  end
end

// Throttle interface if one goes too quickly
always_ff @(posedge user_clk) begin
  if (~user_reset_n | (~en)) begin
    msgst_msgld_diff    <= #TCQ 9'h0;
    msgst_rsps          <= #TCQ 9'h0;
    msgld_rsps          <= #TCQ 9'h0;
    msgst_reqs          <= #TCQ 9'h0;
    msgld_reqs          <= #TCQ 9'h0;
    msgld_allowed_cnts  <= #TCQ 9'h0;
  end else begin
    if ((fab0_byp_out_msgld_dat_fab_int.vld && fab0_byp_out_msgld_dat_fab_int.rdy && 
       (fab0_byp_out_msgld_dat_fab_int.intf.u.cdm.response_cookie[0] == MSGST_RESPONSE_COOKIE[0])) &&
       (fab0_dsc_crd_msgld_req_fab_int.vld && fab0_dsc_crd_msgld_req_fab_int.rdy)) begin
      msgld_allowed_cnts       <= #TCQ msgld_allowed_cnts;
    end else if (fab0_byp_out_msgld_dat_fab_int.vld && fab0_byp_out_msgld_dat_fab_int.rdy && 
       (fab0_byp_out_msgld_dat_fab_int.intf.u.cdm.response_cookie[0] == MSGST_RESPONSE_COOKIE[0])) begin
      msgld_allowed_cnts       <= #TCQ msgld_allowed_cnts + 1;
    end else if (fab0_dsc_crd_msgld_req_fab_int.vld && fab0_dsc_crd_msgld_req_fab_int.rdy) begin
      msgld_allowed_cnts       <= #TCQ msgld_allowed_cnts - 1;
    end else begin
      msgld_allowed_cnts       <= #TCQ msgld_allowed_cnts;
    end
    
    if (fab0_byp_out_msgld_dat_fab_int.vld && fab0_byp_out_msgld_dat_fab_int.rdy && 
       (fab0_byp_out_msgld_dat_fab_int.intf.u.cdm.response_cookie[0] == MSGST_RESPONSE_COOKIE[0])) begin
      msgst_rsps        <= #TCQ msgst_rsps + 1;
    end
    if (fab0_byp_out_msgld_dat_fab_int.vld && fab0_byp_out_msgld_dat_fab_int.rdy && 
       (fab0_byp_out_msgld_dat_fab_int.intf.u.cdm.response_cookie[0] == MSGLD_RESPONSE_COOKIE[0])) begin
      msgld_rsps        <= #TCQ msgld_rsps + 1;
    end
    
    if (fab0_cmpt_msgst_fab_int.vld && fab0_cmpt_msgst_fab_int.rdy && fab0_cmpt_msgst_fab_int.intf.eop) begin
      msgst_reqs        <= #TCQ msgst_reqs + 1;
    end
    if (fab0_dsc_crd_msgld_req_fab_int.vld && fab0_dsc_crd_msgld_req_fab_int.rdy) begin
      msgld_reqs        <= #TCQ msgld_reqs + 1;
    end
  
    if ((fab0_cmpt_msgst_fab_int.vld && fab0_cmpt_msgst_fab_int.rdy && fab0_cmpt_msgst_fab_int.intf.eop) &&
       (fab0_dsc_crd_msgld_req_fab_int.vld && fab0_dsc_crd_msgld_req_fab_int.rdy)) begin
      msgst_msgld_diff  <= #TCQ msgst_msgld_diff;
    end else if (fab0_cmpt_msgst_fab_int.vld && fab0_cmpt_msgst_fab_int.rdy && fab0_cmpt_msgst_fab_int.intf.eop) begin
      msgst_msgld_diff  <= #TCQ msgst_msgld_diff + 1;
    end else if (fab0_dsc_crd_msgld_req_fab_int.vld && fab0_dsc_crd_msgld_req_fab_int.rdy) begin
      msgst_msgld_diff  <= #TCQ msgst_msgld_diff - 1;
    end else begin
      msgst_msgld_diff  <= #TCQ msgst_msgld_diff;
    end
  end
end

assign msgst_hold = (msgst_msgld_diff > MAX_MSGST_MSGLD_DIFF) ? 1'b1 : 1'b0;
assign msgld_hold = (msgld_allowed_cnts == 0)                 ? 1'b1 : 1'b0;

// Data Checking
always_ff @(posedge user_clk) begin
  if (~user_reset_n | (~en)) begin
    data_err            <= #TCQ 1'b0;
  end else begin
    data_err            <= #TCQ ((fab0_byp_out_msgld_dat_fab_int.vld && fab0_byp_out_msgld_dat_fab_int.rdy) && (fab0_byp_out_msgld_dat_fab_int.intf.u.cdm.response_cookie[0] == MSGLD_RESPONSE_COOKIE[0]) &&
                                (fab0_byp_out_msgld_dat_fab_int.intf.dsc[15:0] != msgld_data_pattern[15:0])) ? 1'b1 : data_err; // Looking at just bit 0 of cookie for timing
  end
end

assign error = data_err;

// Select enable disable of the ordering test
always_comb begin
  if (en) begin
    // MSGST
    fab0_cmpt_msgst_fab_int.intf.dat                   = 256'b0 | msgst_data_pattern[15:0];
    fab0_cmpt_msgst_fab_int.intf.eop                   = 1'b1;

    fab0_cmpt_msgst_fab_int.intf.ecc                   = 11'b0;
    fab0_cmpt_msgst_fab_int.intf.length                = 9'b0 | ADDR_INCREMENT; // In Bytes
    fab0_cmpt_msgst_fab_int.intf.op                    = 2'b0;           // MSGST
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.wc_op           = 2'b0;//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.wc_line_size    = 1'b1;

    // Address Assignments
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr.u.imm.translated       = 1'b0;//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr.u.imm.addr             = {pci0_msgst_host_addr_1, pci0_msgst_host_addr_0} | msgst_addr;
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr.use_addr_tbl__reserved = 1'b0;//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

    // WC
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.wc_id           = 16'b0;
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.wc_timeout_idx  = 3'b111;//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

    // Addr_spc
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst_fifo = 9'h0;
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr_spc.u.imm.csi_dst      = 5'h4; //PCIE 0 //update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr_spc.u.imm.fnc          = 16'h0;
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr_spc.u.imm.pasid        = 23'h0;

    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.addr_spc.use_addr_spc_tbl__reserved = 1'b0;//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx

    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.response_req    = 1'b1;
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.response_cookie = MSGST_RESPONSE_COOKIE;
    fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.start_offset    = 5'b0;//update based on CDM_SOFT_IP_Registers_RAMs_v2.0.xlsx
    fab0_cmpt_msgst_fab_int.intf.data_width                    = 2'b1; // Use full 32-byte data bus
    fab0_cmpt_msgst_fab_int.intf.client_id                     = 4'b1; // CDM FAB 1
	
	fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.st2m_ordered    = 1'b0;
   	fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.tph             = 11'h0;
   	fab0_cmpt_msgst_fab_int.intf.u.cdm_bal.cdm.attr            = 3'b0; // No IDO, No Relax Ordering
    fab0_cmpt_msgst_fab_int.intf.wait_pld_pkt_id               = 16'h0;
	
    fab0_cmpt_msgst_fab_int.vld                                = ((msgst_sm == SEND_PKT) && (!msgst_hold)) ? 1'b1 : 1'b0;

    // MSGLD
    // MSGLD Request assigments
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.relaxed_read        = 1'b0; 
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.data_width          = 1'b1; 
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.response_cookie     = MSGLD_RESPONSE_COOKIE;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.length              = 9'b0 | ADDR_INCREMENT; // In Bytes
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.start_offset        = 5'b0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.op                  = 2'b0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.attr.ido            = 1'b0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.attr.ro             = 1'b0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.attr.no_snoop       = 1'b0;

    // Address Assignments 
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr.u.imm.addr     = {pci0_msgld_host_addr_1, pci0_msgld_host_addr_0} | msgld_addr;
  
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr.u.imm.translated       = 1'b0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr.use_addr_tbl__reserved = 1'b0;

    // Addr_spc
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr_spc.u.imm.csi_dst_fifo = 9'h0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr_spc.u.imm.csi_dst      = 5'h4;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr_spc.u.imm.fnc          = 16'h0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr_spc.u.imm.pasid        = 23'h0;
    fab0_dsc_crd_msgld_req_fab_int.intf.cmd.msgld.addr_spc.use_addr_spc_tbl__reserved = 1'b0;

    fab0_dsc_crd_msgld_req_fab_int.intf.rc_id                         = 6'hB;
    fab0_dsc_crd_msgld_req_fab_int.intf.client_id                     = 4'b1; // CDM FAB 1
    fab0_dsc_crd_msgld_req_fab_int.intf.op                            = 2'b0;
    fab0_dsc_crd_msgld_req_fab_int.vld                                = ((msgld_sm == SEND_PKT) && (!msgld_hold)) ? 1'b1 : 1'b0;;   
    
    // Tie off
    fab0_byp_out_msgld_dat_fab_int_tg.vld  = 1'b0;
    fab0_byp_out_msgld_dat_fab_int_tg.intf = '0;
    fab0_byp_out_msgld_dat_fab_int.rdy     = 1'b1;
    
    fab0_cmpt_msgst_fab_int_tg.rdy         = 1'b0;
    fab0_dsc_crd_msgld_req_fab_int_tg.rdy  = 1'b0;
  end else begin
    // Pass-through
    fab0_cmpt_msgst_fab_int.vld            = fab0_cmpt_msgst_fab_int_tg.vld;
    fab0_cmpt_msgst_fab_int.intf           = fab0_cmpt_msgst_fab_int_tg.intf;
    fab0_cmpt_msgst_fab_int_tg.rdy         = fab0_cmpt_msgst_fab_int.rdy;
  
    fab0_byp_out_msgld_dat_fab_int_tg.vld  = fab0_byp_out_msgld_dat_fab_int.vld;
    fab0_byp_out_msgld_dat_fab_int_tg.intf = fab0_byp_out_msgld_dat_fab_int.intf;
    fab0_byp_out_msgld_dat_fab_int.rdy     = fab0_byp_out_msgld_dat_fab_int_tg.rdy;
  
    fab0_dsc_crd_msgld_req_fab_int.vld     = fab0_dsc_crd_msgld_req_fab_int_tg.vld;
    fab0_dsc_crd_msgld_req_fab_int.intf    = fab0_dsc_crd_msgld_req_fab_int_tg.intf;
    fab0_dsc_crd_msgld_req_fab_int_tg.rdy  = fab0_dsc_crd_msgld_req_fab_int.rdy;
  end

end

endmodule
