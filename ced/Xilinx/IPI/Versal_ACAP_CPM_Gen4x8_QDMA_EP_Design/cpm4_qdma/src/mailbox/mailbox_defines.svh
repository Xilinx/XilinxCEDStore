`ifndef MAILBOX_DEFINES_SVH
`define MAILBOX_DEFINES_SVH

`define MAILBOX_SOFT_IP

`define MAILBOX_N_PF 4
`define MAILBOX_N_FN 256
`define MAILBOX_MAX_MSG_SIZE 128

`define MAILBOX_AXIL_ADDR_W 32
`define MAILBOX_AXIL_DATA_W 32
`define MAILBOX_AXIL_USER_W 29 

`define MAILBOX_CSR_ADDR_W 12
`define USER_INT_VECT_W 5

`define MAILBOX_N_ACK_REG 8
`define MAILBOX_N_MSG_REG 32

`define FLR_USE_CLR 1

`timescale 1ns/1ps

//package mailbox_global_defines_pkg;
typedef logic [`MAILBOX_CSR_ADDR_W-1:0] mailbox_csr_addr_t;
typedef enum mailbox_csr_addr_t {
  FN_STATUS_A,
  FN_CMD_A,
  FN_INT_VECT_A,
  TARGET_FN_A,
  ICR_A,
  RTL_REV_A,
  PATCH_REV_A,
  PF_ACK_A[`MAILBOX_N_ACK_REG] = 8,
  FN_FLR_CTRL_A=64,
  I_MSG_MEM_A[`MAILBOX_N_MSG_REG]=512,
  O_MSG_MEM_A[`MAILBOX_N_MSG_REG]=768,
  MAX_ADDR_A
} mailbox_csr_addr_e;

typedef struct packed {
  logic [31-13:0]rsv; 
  logic       rst_status; // PF only
  logic [7:0] cur_src_fn; // PF only
  logic       rsv0;
  logic ack_status;       // PF only
  logic o_msg_status;
  logic i_msg_status;
} mailbox_reg_status_t;

typedef struct packed {
  logic [31-4:0]rsv; 
  logic vf_reset; 
  logic msg_pop;      
  logic msg_rcv;
  logic msg_send;
} mailbox_reg_cmd_t;

typedef struct packed {
  logic [31:24] src_fn;
  logic [23:16] dest_fn;
  logic [15:8]  rsv;
  logic [7:0]   ofst;
} mailbox_reg_msg_t;

typedef struct packed {
  logic [31-8:0]rsv; 
  logic [7:0] fn;
} mailbox_reg_target_fn_t;

typedef struct packed {
  logic [31:0] data; 
} mailbox_reg_data_t;

typedef struct packed {
  logic [1:0]  vfg;
  logic [7:0]  func;
  logic [31:0] data; 
} mailbox_mb2flr_data_t;

typedef struct packed {
  logic [31:1] rsv;
  logic        flr_status; 
} mailbox_reg_flr_t;


typedef union packed {
 mailbox_reg_data_t      csr_data;
 mailbox_reg_status_t    csr_status;
 mailbox_reg_target_fn_t csr_target_fn;
 mailbox_reg_cmd_t       csr_cmd; 
 mailbox_reg_msg_t       csr_msg;
 mailbox_reg_flr_t       csr_flr;
} mailbox_csr_data_chk_u;

typedef struct packed {
    logic    [1:0]            vfg;
    logic    [7:0]            vfg_ofst;
    logic    [2:0]            bardec;
    logic    [7:0]            bus_id;
    logic    [7:0]            func;
} mailbox_axil_user_t;

typedef enum {AXI4L_RD, AXI4L_WR} axi4l_opcode_e;

typedef enum bit [4:0] {
    RAND_NONE = 'b0000,
    RAND_ADDR = 'b0001,
    RAND_DATA = 'b0010,
    RAND_FN   = 'b0100,
    RAND_VFG  = 'b1000,
    RAND_ALL  = 'b1111
} mailbox_pkt_random_property_e;

//endpackage: mailbox_global_defines_pkg

`endif
