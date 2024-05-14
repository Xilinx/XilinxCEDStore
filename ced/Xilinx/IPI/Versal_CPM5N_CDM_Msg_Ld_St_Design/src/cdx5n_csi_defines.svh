//-----------------------------------------------------------------------------
//
// (c) Copyright 1986-2022 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
`ifndef CDX_CSI_DEFINES_SVH
`define CDX_CSI_DEFINES_SVH


//`define PCI_SINK_BASE_ADDR 'hFD00_0000
//`define PCI_SINK_BASE_ADDR 'hFD01_0000
//`define PCI_SINK_BASE_ADDR 'hFD02_0000
`define PCI_SINK_BASE_ADDR 'hFD03_0000


typedef logic [7:0]     uint8_t;
typedef logic [8:0]     uint9_t;
typedef logic [15:0]    uint16_t;
typedef logic [51:0]    uint52_t;
typedef logic [55:0]    uint56_t;
typedef logic [61:0]    uint62_t;

typedef logic [2:0] csi_pcie_tc_t;

typedef struct packed {
  logic [0:0] ido;
  logic [0:0] ro;
  logic [0:0] no_snoop;
} csi_pcie_attr_t;

typedef struct packed {
  logic [15:0] st;
  logic [1:0] ph;
  logic [0:0] th;
} csi_pcie_tph_t;

typedef union packed {
  uint8_t rd_st_lo;
  struct packed {
    logic [3:0] last_be;
    logic [3:0] first_be;
  } be;
} csi_pcie_byte_enables_t;


typedef enum logic [2:0] {
    CSI_CMPT_STATUS_SC          = 3'b000,
    CSI_CMPT_STATUS_UR          = 3'b001,
    CSI_CMPT_STATUS_CRS         = 3'b010,
    CSI_CMPT_STATUS_CA          = 3'b100,
    CSI_CMPT_STATUS_FUNC_DIS    = 3'b110, 
    CSI_CMPT_STATUS_TIMEOUT     = 3'b111
} csi_cpl_status_t;

typedef enum logic [1:0] {
  CSI_PCIE_AT_UNTRANSLATED = 0,
  CSI_PCIE_AT_TRANSLATION_RQ = 1,
  CSI_PCIE_AT_TRANSLATED = 2,
  CSI_PCIE_AT_RESERVED = 3
} csi_pcie_addr_type_t;

localparam __CSI_CT_GRP_MASK    = 6'b1111_00;
localparam __CSI_CT_RD          = 6'b0000_00;
localparam __CSI_CT_WR          = 6'b0001_00;
localparam __CSI_CT_ATOMIC      = 6'b0010_00;
localparam __CSI_CT_MSG         = 6'b0011_00;
localparam __CSI_CT_CTL         = 6'b0101_00;

typedef enum logic [5:0] {
  CSI_CT_RD_MEM     = 0,    //6'b00_00_00
  CSI_CT_RD_IO      = 1,    //6'b00_00_01
  CSI_CT_RD_CFG0    = 2,    //6'b00_00_10
  CSI_CT_RD_CFG1    = 3,    //6'b00_00_11
  CSI_CT_WR_MEM     = 4,    //6'b00_01_00
  CSI_CT_WR_IO      = 5,    //6'b00_01_01
  CSI_CT_WR_CFG0    = 6,    //6'b00_01_10
  CSI_CT_WR_CFG1    = 7,    //6'b00_01_11
  CSI_CT_FETCHADD   = 8,    //6'b00_10_00
  CSI_CT_SWAP       = 9,    //6'b00_10_01
  CSI_CT_CAS        = 10,   //6'b00_10_10
  CSI_CT_MESSAGE_RQ = 12,   //6'b00_11_00
  CSI_CT_INTERRUPT  = 13,   //6'b00_11_01
  CSI_CT_COMPLETION = 16,   //6'b01_00_00
  CSI_CT_IB_CTL     = 20,   //6'b01_01_00
  CSI_CT_OB_CTL     = 21,   //6'b01_01_01
  CSI_CT_BARRIER    = 22,   //6'b01_01_10
  CSI_CT_INVALID    = 31    //6'11_11_11
} csi_cap_type_t;

typedef enum logic [7:0] {
    PCIE_MC_UNLOCK          = 8'b0000_0000,
    PCIE_MC_INVALIDATE_REQ  = 8'b0000_0001,
    PCIE_MC_INVALIDATE_CMPL = 8'b0000_0010,
    PCIE_MC_PAGE_REQ        = 8'b0000_0100,
    PCIE_MC_PRG_RESP        = 8'b0000_0101,
    PCIE_MC_LTR             = 8'b0001_0000,
    PCIE_MC_OBFF            = 8'b0001_0010,
    PCIE_MC_PM_ACT_ST_NAK   = 8'b0001_0100,
    PCIE_MC_PM_PME          = 8'b0001_1000,
    PCIE_MC_PME_TURN_OFF    = 8'b0001_1001,
    PCIE_MC_PME_TO_ACK      = 8'b0001_1011,
    PCIE_MC_ASSERT_INTA     = 8'b0010_0000,
    PCIE_MC_ASSERT_INTB     = 8'b0010_0001,
    PCIE_MC_ASSERT_INTC     = 8'b0010_0010,
    PCIE_MC_ASSERT_INTD     = 8'b0010_0011,
    PCIE_MC_DEASSERT_INTA   = 8'b0010_0100,
    PCIE_MC_DEASSERT_INTB   = 8'b0010_0101,
    PCIE_MC_DEASSERT_INTC   = 8'b0010_0110,
    PCIE_MC_DEASSERT_INTD   = 8'b0010_0111,
    PCIE_MC_ERR_COR         = 8'b0011_0000,
    PCIE_MC_ERR_NONFATAL    = 8'b0011_0001,
    PCIE_MC_ERR_FATAL       = 8'b0011_0011,
    PCIE_MC_IGNORED_MSG_1   = 8'b0100_0000,
    PCIE_MC_IGNORED_MSG_2   = 8'b0100_0001,
    PCIE_MC_IGNORED_MSG_3   = 8'b0100_0011,
    PCIE_MC_IGNORED_MSG_4   = 8'b0100_0100,
    PCIE_MC_IGNORED_MSG_5   = 8'b0100_0101,
    PCIE_MC_IGNORED_MSG_6   = 8'b0100_0111,
    PCIE_MC_IGNORED_MSG_7   = 8'b0100_1000,
    PCIE_MC_SET_SLOT_PWR_LMT= 8'b0101_0000,
    PCIE_MC_PTM_REQ         = 8'b0101_0010,
    PCIE_MC_PTM_RESP        = 8'b0101_0011,
    PCIE_MC_VDM_TYPE0       = 8'b0111_1110,
    PCIE_MC_VDM_TYPE1       = 8'b0111_1111
} csi_pcie_message_code_t;

typedef enum logic [1:0] {
  CSI_NPR = 0,
  CSI_CMPT = 1,
  CSI_PR = 2
} csi_flow_t;

typedef logic [4:0] csi_intf_id_t;

typedef logic [5:0] csi_ap_id_t;

typedef logic [3:0] csi_vc_t;

typedef logic [9:0] csi_tag_t;

typedef logic [7:0] csi_msg_cookie_t;

typedef logic [15:0] csi_func_t;

typedef logic [15:0] csi_int_vector_t;

typedef logic [39:0] csi_pr_seq_t;

typedef logic [7:0] csi_cap_pr_seq_t;

typedef struct packed {
  logic [9:0] csi_hdr_ecc;
  logic [0:0] csi_hdr_ecc_valid;
} csi_hdr_integrity_t;

typedef struct packed {
    logic [9:0] csi_hdr_ecc;
    logic [0:0] csi_hdr_ecc_valid;
} csi_hdr_backend_t;

typedef struct packed {
  logic [31:0] crc;
} csi_payload_check_t;

typedef union packed {
  struct packed {
    csi_ap_id_t ap_id;
    union packed {
      struct packed {
        logic [15:0] func_id;
        logic [2:0] bar_id;
        logic [36:0] bar_dw_offset;
      } info;
      uint56_t ap_dw_offset;
    } bar;
  } ap;
  struct packed {
    logic [45:0] rsv;
    uint16_t cfg_reg_no;
  } cfg;
  uint62_t dw_addr;
} csi_addr_t;

typedef struct packed {
  logic [0:0] privileged_mode_rq;
  logic [0:0] execute_rq;
  logic [19:0] pasid;
  logic [0:0] enable;
} csi_pasid_t;

typedef struct packed {
  logic [7:0] st_hi;
  logic [1:0] ph;
  logic [0:0] th;
} csi_tph_t;

typedef struct packed {
  logic [2:0] csi_reserved;
  logic csi_is_managed;
  logic csi_poison;
  union packed {
    uint9_t csi_pr_reserved;
    struct packed {
      csi_cap_pr_seq_t csi_after_pr_seq;
      logic [0:0] csi_rro;
    } info;
  } pr;
  csi_intf_id_t csi_dst;
  union packed {
    uint9_t csi_dst_fifo;
    struct packed {
      csi_intf_id_t csi_src;
      csi_vc_t csi_vc;
    } info;
  } src;
  logic [9:0] csi_dw_len;
  logic [0:0] csi_has_payload_check;
  logic [0:0] csi_has_payload;
  csi_flow_t csi_flow;
  csi_cap_type_t csi_type;
} csi_cap_hdr_t;

typedef struct packed {
  logic ide_enable;
  logic trusted;
  logic secure;
  union packed {
    csi_tag_t npr_tag;
    struct packed {
      logic [1:0] rsv;
      logic [7:0] mwr_st_lo;
    } info;
  } tag;
  csi_tph_t tph;
  csi_pcie_tc_t tc;
  csi_pasid_t pasid;
  csi_pcie_byte_enables_t byte_enables;
  csi_pcie_addr_type_t addr_type;
  csi_addr_t addr;
  logic [0:0] completer_set;
  csi_func_t completer;
  csi_func_t requester;
  csi_pcie_attr_t attr;
  csi_cap_hdr_t hdr;
} csi_rw_t;

typedef struct packed {
    logic [5 : 0] rsv;    
  logic is_not_admin;
  logic ide_enable;
  logic trusted;
  logic secure;
  union packed {
    csi_tag_t npr_tag;
    struct packed {
      logic [1:0] rsv;
      logic [7:0] mwr_st_lo;
    } info;
  } tag;
  csi_tph_t tph;
  csi_pcie_tc_t tc;
  csi_pasid_t pasid;
  csi_pcie_byte_enables_t byte_enables;
  csi_pcie_addr_type_t addr_type;
  csi_addr_t addr;
  logic [0:0] completer_set;
  csi_func_t completer;
  csi_func_t requester;
  csi_pcie_attr_t attr;
  //csi_cap_hdr_t hdr;
} csi_type_rw_t;

typedef struct packed {
    logic [2:0] fmt;
    logic [4:0] ptype;
    logic       t9;
    logic [2:0] tc;
    logic       t8;
    logic       attr2;
    logic       rsvd;
    logic       th;
    logic       td;
    logic       ep;
    logic [1:0] attr1_0;
    logic [1:0] at;
    logic [9:0] length;
    logic [15:0] requester_id;
    logic [7:0] tag;
    csi_pcie_message_code_t message_code;
    union packed {
        struct packed {
            logic [15:0] destination_id;
            logic [15:0] vendor_id;
            logic [ 7:0] subtype;
            logic [23:0] pci_sig_vdm_bytes;
        } pci_sig_vdm;
        struct packed {
            logic [ 7:0] bus_number;
            logic [ 4:0] dev_number;
            logic [ 2:0] func_number;
            logic [15:0] vendor_id;
            logic [31:0] vdm_hdr_bytes;
        } vdm;
        struct packed {
            logic [15:0] rsvd_dw2_bytes;
            logic [15:0] vendor_id;
            logic [ 7:0] subtype;
            logic [23:0] rsvd_dw3_bytes;
        } other_vdm;
        struct packed {
            logic [ 7:0] byte8;
            logic [ 7:0] byte9;
            logic [ 7:0] byte10;
            logic [ 7:0] byte11;
            logic [ 7:0] byte12;
            logic [ 7:0] byte13;
            logic [ 7:0] byte14;
            logic [ 7:0] byte15;
        } any;
    } mtype;
} csi_msg_tlp_hdr_t;

typedef struct packed {
  csi_msg_tlp_hdr_t msg_tlp_hdr;
  logic ide_enable;
  logic trusted;
  logic secure;
  csi_msg_cookie_t msg_cookie;
  csi_func_t requester;
  csi_pcie_attr_t attr;
  csi_cap_hdr_t hdr;
} csi_message_rq_t;

typedef enum logic [2:0] {
    CSI_INTERRUPT_MSI,
    CSI_INTERRUPT_ASSERT,
    CSI_INTERRUPT_DEASSERT
} csi_interrupt_msg_type_t;

typedef struct packed {
  logic ide_enable;
  logic trusted;
  logic secure;
  csi_interrupt_msg_type_t msg_type;  
  csi_int_vector_t vector;
  csi_pcie_tph_t tph;
  csi_pcie_tc_t tc;
  csi_func_t requester;
  csi_pcie_attr_t attr;
  csi_cap_hdr_t hdr;
} csi_interrupt_t;

    localparam CSI_INTR_BITS =  $bits(csi_interrupt_msg_type_t) + $bits(csi_int_vector_t) + $bits(csi_pcie_tph_t) + $bits(csi_pcie_tc_t) + $bits(csi_func_t) + $bits(csi_pcie_attr_t) +3;

typedef struct packed {
  logic[164 - CSI_INTR_BITS : 0] rsv;
  logic ide_enable;
  logic trusted;
  logic secure;
  csi_interrupt_msg_type_t msg_type;  
  csi_int_vector_t vector;
  csi_pcie_tph_t tph;
  csi_pcie_tc_t tc;
  csi_func_t requester;
  csi_pcie_attr_t attr;
  //csi_cap_hdr_t hdr;
} csi_type_interrupt_t;

typedef struct packed {
  logic [6:0] rsv;
  csi_msg_tlp_hdr_t msg_tlp_hdr;
  logic ide_enable;
  logic trusted;
  logic secure;
  csi_msg_cookie_t msg_cookie;
  csi_func_t requester;
  csi_pcie_attr_t attr;
  //csi_cap_hdr_t hdr;
} csi_type_message_rq_t;

typedef struct packed {
  logic [0:0] is_last;
  logic [0:0] is_first;
  logic [12:0] byte_count;
  logic [6:0] lower_addr;
  csi_tag_t tag;
  csi_pcie_tc_t tc;
  csi_cpl_status_t status;
  csi_pcie_addr_type_t addr_type;
  csi_cap_type_t request_type;
  csi_func_t requester;
  csi_func_t completer;
  csi_pcie_attr_t attr;
  csi_cap_hdr_t hdr;
} csi_completion_t;

typedef struct packed {
  logic [83 : 0] rsv;    
  logic [0:0] is_last;
  logic [0:0] is_first;
  logic [12:0] byte_count;
  logic [6:0] lower_addr;
  csi_tag_t tag;
  csi_pcie_tc_t tc;
  csi_cpl_status_t status;
  csi_pcie_addr_type_t addr_type;
  csi_cap_type_t request_type;
  csi_func_t requester;
  csi_func_t completer;
  csi_pcie_attr_t attr;
  //csi_cap_hdr_t hdr;
} csi_type_completion_t;


typedef union packed {
    logic [164:0]       check;
    csi_type_completion_t    cmpl;
    csi_type_rw_t            rw;
    csi_type_interrupt_t     intr;
    csi_type_message_rq_t    msg;
} csi_per_type_t;

typedef struct packed {
  logic [9:0] csi_hdr_ecc;
  logic [0:0] csi_hdr_ecc_valid;
  csi_per_type_t ptype;
  csi_cap_hdr_t hdr;
} csi_capsule_t;

typedef enum logic [3:0] {
  CSI_IB_CTL_SEQ_SYNC = 0
} csi_ib_ctl_type_t;

typedef struct packed {
  csi_pr_seq_t seq_sync_after_pr_seq;
  csi_ib_ctl_type_t subtype;
  csi_cap_hdr_t hdr;
} csi_ib_control_t;

//TODO: This union is a place holder. Final definition has to be populated or
//could be moved to //IP3/DEV/hw/hnicx/hnicxshared_v1_7t/...
typedef enum logic [1:0] {
  CSI_RAM_NO_ACCESS = 0,
  CSI_RAM_RD_ACCESS = 1,
  CSI_RAM_WR_ACCESS = 2
} csi_ram_access_type_t;

typedef union packed {
  struct packed {
    logic [47:0] usr;
  } user;
  struct packed {
    logic [13:0] len;
    logic [33:0] usr;
  } len;
  struct packed {
    logic        err;
    logic [13:0] len;
    logic [32:0] usr;
  } len_w_err;
  struct packed {
    logic        err;
    logic [46:0] usr;
  } err;
  struct packed {
    logic [2:0]   ctrl;
    logic [31:0]  cnt;
    logic [10:0]  buf_id;
    logic         is_sop; //If 1 indicates that the cnt is SOP cnt else cnt is EOP Cnt
    logic         is_valid;
  } cnt;
  struct packed {
    logic [15:0] reserved;
    csi_ram_access_type_t [15:0] acc;
  } ram_acc;
  
  struct packed {
    logic [15:0] usr; //Reserved
    logic [7:0]  vc;  //VC / Buffer ID
    logic [1:0]  dst; //Destination ID
    logic [1:0]  src; //Source ID
    logic [1:0]  cke; //User Cookie
    logic        jce; //Job Chunk End
    logic        idle;
    logic [13:0] len;
    logic        eop;
    logic        sop;
  } csi_hdr;

} csi_tel_bus_t;

typedef struct packed {
  csi_flow_t  fltyp; //2-bit flow type
  logic [5:0] vc_id;
  logic       en;    //Enable signal to increment crdt accumulator
} csi2dpu_lcl_cdt_t;


`endif
