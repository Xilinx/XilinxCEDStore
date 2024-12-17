
`ifndef PCIE_APP_USCALE_BMD_H
`define PCIE_APP_USCALE_BMD_H

`define PCI_EXP_EP_OUI                          24'h000A35
`define PCI_EXP_EP_DSN_1                        {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                        32'h10EE0001
`define MSI_INTR                                1
`define MSIX                                    1

`define STRUCT_AXI_RC_IF \
typedef struct packed { \
   logic [63:0]   parity;        /* 160:97 */ \
   logic          discontinue;   /* 96 */ \
   logic [3:0]    is_eop3_ptr;   /* 95:92 */ \
   logic [3:0]    is_eop2_ptr;   /* 91:88 */ \
   logic [3:0]    is_eop1_ptr;   /* 87:84 */ \
   logic [3:0]    is_eop0_ptr;   /* 83:80 */ \
   logic [3:0]    is_eop;        /* 79:76 */ \
   logic [1:0]    is_sop3_ptr;   /* 75:74 */ \
   logic [1:0]    is_sop2_ptr;   /* 73:72 */ \
   logic [1:0]    is_sop1_ptr;   /* 71:70 */ \
   logic [1:0]    is_sop0_ptr;   /* 69:68 */ \
   logic [3:0]    is_sop;        /* 67:64 */ \
   logic [63:0]   byte_en;       /* 63:0 */ \
} s_axis_rc_tuser_512; \
 \
typedef struct packed { \
   logic [415:0]  dw3_15; \
   logic          rsvd3;         /* 31 */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic          rsvd2;         /* 24 */ \
   logic [7:0]    cmp_bus;       /* 23:16 */ \
   logic [7:0]    cmp_dev_fn;    /* 15:8 */ \
   logic [7:0]    tag;           /* 7:0 */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          rsvd1;         /* 15 */ \
   logic          poisoned_cmp;  /* 14 */ \
   logic [2:0]    cmp_status;    /* 13:11 */ \
   logic [10:0]   dword_count;   /* 10:0 */ \
   logic          rsvd0;         /* 31 */ \
   logic          req_completed; /* 30 */ \
   logic          lock_read_cmp; /* 29 */ \
   logic [12:0]   byte_count;    /* 28:16 */ \
   logic [3:0]    error_code;    /* 15:12 */ \
   logic [11:0]   address;       /* 11:0 */ \
} s_axis_rc_tdata_512;

`define STRUCT_AXI_RQ_IF \
typedef struct packed { \
   logic [63:0]   parity;        /* 136:73 */ \
   logic [5:0]    seq_num1;      /* 72:67 */ \
   logic [5:0]    seq_num0;      /* 66:61 */ \
   logic [15:0]   tph_st_tag;    /* 60:45 */ \
   logic [1:0]    tph_id_tag_en; /* 44:43 */ \
   logic [3:0]    tph_type;      /* 42:39 */ \
   logic [1:0]    tph_present;   /* 38:37 */ \
   logic          discontinue;   /* 36 */ \
   logic [3:0]    is_eop1_ptr;   /* 35:32 */ \
   logic [3:0]    is_eop0_ptr;   /* 31:28 */ \
   logic [1:0]    is_eop;        /* 27:26 */ \
   logic [1:0]    is_sop1_ptr;   /* 25:24 */ \
   logic [1:0]    is_sop0_ptr;   /* 23:22 */ \
   logic [1:0]    is_sop;        /* 21:20 */ \
   logic [3:0]    addr_offset;   /* 19:16 */ \
   logic [7:0]    last_be;       /* 15:8 */ \
   logic [7:0]    first_be;      /* 7:0 */ \
} s_axis_rq_tuser_512; \
 \
typedef struct packed { \
   logic          force_ecrc;    /* 31 */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic          req_id_en;     /* 24 */ \
   logic [7:0]    cmp_bus;       /* 23:16 */ \
   logic [7:0]    cmp_dev_fn;    /* 15:8 */ \
   logic [7:0]    tag;           /* 7:0 */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          poisoned_req;  /* 15 */ \
   logic [3:0]    req_type;      /* 14:11 */ \
   logic [10:0]   dword_count;   /* 10:0 */ \
   logic [61:0]   addr_63_2;     /* 63:2 */ \
   logic [1:0]    addr_type;     /* 1:0 */ \
} s_axis_rq_header; \
 \
typedef struct packed { \
   logic [127:0]     ud; \
   s_axis_rq_header  uh; \
   logic [127:0]     ld; \
   s_axis_rq_header  lh; \
} s_axis_rq_tdata_512;


`define STRUCT_AXI_CC_IF_512 \
typedef struct packed { \
   logic [63:0]   parity;        /* 80:17 */ \
   logic          discontinue;   /* 16 */ \
   logic [3:0]    is_eop1_ptr;   /* 15:12 */ \
   logic [3:0]    is_eop0_ptr;   /* 11:8 */ \
   logic [1:0]    is_eop;        /* 7:6 */ \
   logic [1:0]    is_sop1_ptr;   /* 5:4 */ \
   logic [1:0]    is_sop0_ptr;   /* 3:2 */ \
   logic [1:0]    is_sop;        /* 1:0 */ \
} s_axis_cc_tuser_512; \
 \
typedef struct packed { \
   logic [415:0]  dw3_15; \
   logic          force_ecrc;    /* 31 */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic          cmp_id_en;     /* 24 */ \
   logic [7:0]    cmp_bus;       /* 23:16 */ \
   logic [7:0]    cmp_dev_fn;    /* 15:8 */ \
   logic [7:0]    tag;           /* 7:0 */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          rsvd3;         /* 15 */ \
   logic          poisoned_cmp;  /* 14 */ \
   logic [2:0]    cmp_status;    /* 13:11 */ \
   logic [10:0]   dword_count;   /* 10:0 */ \
   logic [1:0]    rsvd2;         /* 31:30 */ \
   logic          lock_read_cmp; /* 29 */ \
   logic [12:0]   byte_count;    /* 28:16 */ \
   logic [5:0]    rsvd1;         /* 15:10 */ \
   logic [1:0]    at;            /* 9:8 */ \
   logic          rsvd0;         /* 7 */ \
   logic [6:0]    address;       /* 6:0 */ \
} s_axis_cc_tdata_512;

`define STRUCT_AXI_CQ_IF_512 \
typedef struct packed { \
   logic [63:0]   parity;        /* 182:119 */ \
   logic [15:0]   tph_st_tag;    /* 118:103 */ \
   logic [3:0]    tph_type;      /* 102:99 */ \
   logic [1:0]    tph_present;   /* 98:97 */ \
   logic          discontinue;   /* 96 */ \
   logic [3:0]    is_eop1_ptr;   /* 95:92 */ \
   logic [3:0]    is_eop0_ptr;   /* 91:88 */ \
   logic [1:0]    is_eop;        /* 87:86 */ \
   logic [1:0]    is_sop1_ptr;   /* 85:84 */ \
   logic [1:0]    is_sop0_ptr;   /* 83:82 */ \
   logic [1:0]    is_sop;        /* 81:80 */ \
   logic [63:0]   byte_en;       /* 79:16 */ \
   logic [7:0]    last_be;       /* 15:8 */ \
   logic [7:0]    first_be;      /* 7:0 */ \
} s_axis_cq_tuser_512; \
 \
typedef struct packed { \
   logic [383:0]  dw4_15; \
   logic          rsvd1;         /* 31 */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic [5:0]    bar_aperture;  /* 24:19 */ \
   logic [2:0]    bar_id;        /* 18:16 */ \
   logic [7:0]    target_fn;     /* 15:8 */ \
   logic [7:0]    tag;           /* 7:0 */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          rsvd0;         /* 15 */ \
   logic [3:0]    req_type;      /* 14:11 */ \
   logic [10:0]   dword_count;   /* 10:0 */ \
   logic [61:0]   addr_63_2;     /* 63:2 */ \
   logic [1:0]    addr_type;     /* 1:0 */ \
} s_axis_cq_tdata_512;


`define STRUCT_AXI_RC_IF_1024 \
typedef struct packed { \
   logic [127:0]  parity;        /* 336:209 */ \
   logic          discontinue;   /* 208     */ \
   logic [4:0]    is_eop7_ptr;   /* 207:203 */ \
   logic [4:0]    is_eop6_ptr;   /* 202:198 */ \
   logic [4:0]    is_eop5_ptr;   /* 197:193 */ \
   logic [4:0]    is_eop4_ptr;   /* 192:188 */ \
   logic [4:0]    is_eop3_ptr;   /* 187:183 */ \
   logic [4:0]    is_eop2_ptr;   /* 182:178 */ \
   logic [4:0]    is_eop1_ptr;   /* 177:173 */ \
   logic [4:0]    is_eop0_ptr;   /* 172:168 */ \
   logic [7:0]    is_eop;        /* 167:160 */ \
   logic [2:0]    is_sop7_ptr;   /* 159:157 */ \
   logic [2:0]    is_sop6_ptr;   /* 156:154 */ \
   logic [2:0]    is_sop5_ptr;   /* 153:151 */ \
   logic [2:0]    is_sop4_ptr;   /* 150:148 */ \
   logic [2:0]    is_sop3_ptr;   /* 147:145 */ \
   logic [2:0]    is_sop2_ptr;   /* 144:142 */ \
   logic [2:0]    is_sop1_ptr;   /* 141:139 */ \
   logic [2:0]    is_sop0_ptr;   /* 138:136 */ \
   logic [7:0]    is_sop;        /* 135:128 */ \
   logic [127:0]  byte_en;       /* 127:0   */ \
} s_axis_rc_tuser_1024; \
 \
typedef struct packed { \
   logic [927:0]  dw3_31; \
   logic          rsvd3;         /* 31    */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic          rsvd2;         /* 24    */ \
   logic [7:0]    cmp_bus;       /* 23:16 */ \
   logic [7:0]    cmp_dev_fn;    /* 15:8  */ \
   logic [7:0]    tag;           /*  7:0  */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          rsvd1;         /* 15    */ \
   logic          poisoned_cmp;  /* 14    */ \
   logic [2:0]    cmp_status;    /* 13:11 */ \
   logic [10:0]   dword_count;   /* 10:0  */ \
   logic          rsvd0;         /* 31    */ \
   logic          req_completed; /* 30    */ \
   logic          lock_read_cmp; /* 29    */ \
   logic [12:0]   byte_count;    /* 28:16 */ \
   logic [3:0]    error_code;    /* 15:12 */ \
   logic [11:0]   address;       /* 11:0  */ \
} s_axis_rc_tdata_1024;

`define STRUCT_AXI_RQ_IF_1024 \
typedef struct packed { \
   logic [  5:0]  seq_num3;        /* 372:367 */ \
   logic [  5:0]  seq_num2;        /* 366:361 */ \
   logic [  5:0]  seq_num1;        /* 360:355 */ \
   logic [  5:0]  seq_num0;        /* 354:349 */ \
   logic [  3:0]  pasid_pmode_req; /* 348:345 */ \
   logic [  3:0]  pasid_exe_req;   /* 344:341 */ \
   logic [ 79:0]  pasid;           /* 340:261 */ \
   logic [  3:0]  pasid_valid;     /* 260:257 */ \
   logic [127:0]  parity;          /* 256:129 */ \
   logic [ 31:0]  tph_st_tag;      /* 128: 97 */ \
   logic [  7:0]  tph_type;        /*  96: 89 */ \
   logic [  3:0]  tph_present;     /*  88: 85 */ \
   logic          discontinue;     /*      84 */ \
   logic [  4:0]  is_eop3_ptr;     /*  83: 79 */ \
   logic [  4:0]  is_eop2_ptr;     /*  78: 74 */ \
   logic [  4:0]  is_eop1_ptr;     /*  73: 69 */ \
   logic [  4:0]  is_eop0_ptr;     /*  68: 64 */ \
   logic [  3:0]  is_eop;          /*  63: 60 */ \
   logic [  1:0]  is_sop3_ptr;     /*  59: 58 */ \
   logic [  1:0]  is_sop2_ptr;     /*  57: 56 */ \
   logic [  1:0]  is_sop1_ptr;     /*  55: 54 */ \
   logic [  1:0]  is_sop0_ptr;     /*  53: 52 */ \
   logic [  3:0]  is_sop;          /*  51: 48 */ \
   logic [ 15:0]  addr_offset;     /*  47: 32 */ \
   logic [ 15:0]  last_be;         /*  31: 16 */ \
   logic [ 15:0]  first_be;        /*  15:  0 */ \
} s_axis_rq_tuser_1024; \
 \
typedef struct packed { /* 128 bits */ \
   logic          force_ecrc;    /* 127 */ \
   logic [2:0]    attr;          /* 126:124 */ \
   logic [2:0]    tc;            /* 123:121 */ \
   logic          req_id_en;     /* 120 */ \
   logic [7:0]    cmp_bus;       /* 119:112 */ \
   logic [7:0]    cmp_dev_fn;    /* 111:104 */ \
   logic [7:0]    tag;           /* 103:96 */ \
   logic [7:0]    req_bus;       /* 95:88 TODO: need it?*/ \
   logic [7:0]    req_dev_fn;    /* 87:80 TODO: need it?*/ \
   logic          poisoned_req;  /* 79 */ \
   logic [3:0]    req_type;      /* 78:75 */ \
   logic [10:0]   dword_count;   /* 74:64*/ \
   logic [61:0]   addr_63_2;     /* 63:2 */ \
   logic [1:0]    addr_type;     /* 1:0 */ \
} s_axis_rq_header_1024; \
 \
typedef struct packed { \
   logic [127:0]     d_3; \
   s_axis_rq_header_1024  h_3; \
   logic [127:0]     d_2; \
   s_axis_rq_header_1024  h_2; \
   logic [127:0]     d_1; \
   s_axis_rq_header_1024  h_1; \
   logic [127:0]     d_0; \
   s_axis_rq_header_1024  h_0; \
} s_axis_rq_tdata_1024;

`define STRUCT_AXI_CC_IF_1024 \
typedef struct packed { \
   logic [127:0]  parity;        /* 164:37 */ \
   logic          discontinue;   /*  36    */ \
   logic [4:0]    is_eop3_ptr;   /*  35:31 */ \
   logic [4:0]    is_eop2_ptr;   /*  30:26 */ \
   logic [4:0]    is_eop1_ptr;   /*  25:21 */ \
   logic [4:0]    is_eop0_ptr;   /*  20:16 */ \
   logic [3:0]    is_eop;        /*  15:12 */ \
   logic [1:0]    is_sop3_ptr;   /*  11:10 */ \
   logic [1:0]    is_sop2_ptr;   /*   9:8  */ \
   logic [1:0]    is_sop1_ptr;   /*   7:6  */ \
   logic [1:0]    is_sop0_ptr;   /*   5:4  */ \
   logic [3:0]    is_sop;        /*   3:0  */ \
} s_axis_cc_tuser_1024; \
 \
typedef struct packed { \
   logic [927:0]  dw3_31;                    \
   logic          force_ecrc;    /* 31    */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic          cmp_id_en;     /* 24    */ \
   logic [7:0]    cmp_bus;       /* 23:16 */ \
   logic [7:0]    cmp_dev_fn;    /* 15:8  */ \
   logic [7:0]    tag;           /*  7:0  */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          rsvd3;         /* 15    */ \
   logic          poisoned_cmp;  /* 14    */ \
   logic [2:0]    cmp_status;    /* 13:11 */ \
   logic [10:0]   dword_count;   /* 10:0  */ \
   logic [1:0]    rsvd2;         /* 31:30 */ \
   logic          lock_read_cmp; /* 29    */ \
   logic [12:0]   byte_count;    /* 28:16 */ \
   logic [5:0]    rsvd1;         /* 15:10 */ \
   logic [1:0]    at;            /* 9:8   */ \
   logic          rsvd0;         /*  7    */ \
   logic [6:0]    address;       /*  6:0  */ \
} s_axis_cc_tdata_1024;

`define STRUCT_AXI_CQ_IF_1024 \
typedef struct packed { \
   logic [3:0]    poisoned_tlp;    /* 464:461 */ \
   logic [3:0]    pasid_pmode_req; /* 460:457 */ \
   logic [3:0]    pasid_exe_req;   /* 456:453 */ \
   logic [79:0]   pasid;           /* 452:373 */ \
   logic [3:0]    pasid_valid;     /* 372:369 */ \
   logic [127:0]  parity;          /* 368:241 */ \
   logic [31:0]   tph_st_tag;      /* 240:209 */ \
   logic [7:0]    tph_type;        /* 208:201 */ \
   logic [3:0]    tph_present;     /* 200:197 */ \
   logic          discontinue;     /* 196 */ \
   logic [4:0]    is_eop3_ptr;     /* 195:191 */ \
   logic [4:0]    is_eop2_ptr;     /* 190:186 */ \
   logic [4:0]    is_eop1_ptr;     /* 185:181 */ \
   logic [4:0]    is_eop0_ptr;     /* 180:176 */ \
   logic [3:0]    is_eop;          /* 175:172 */ \
   logic [1:0]    is_sop3_ptr;     /* 171:170 */ \
   logic [1:0]    is_sop2_ptr;     /* 169:168 */ \
   logic [1:0]    is_sop1_ptr;     /* 167:166 */ \
   logic [1:0]    is_sop0_ptr;     /* 165:164 */ \
   logic [3:0]    is_sop;          /* 163:160 */ \
   logic [15:0]   last_be;         /* 159:144 */ \
   logic [15:0]   first_be;        /* 143:128 */ \
   logic [127:0]  byte_en;         /* 127:0   */ \
} s_axis_cq_tuser_1024; \
 \
typedef struct packed { \
   logic [896:0]  dw4_31;                    \
   logic          rsvd2;         /* 31    */ \
   logic [2:0]    attr;          /* 30:28 */ \
   logic [2:0]    tc;            /* 27:25 */ \
   logic          rsvd1;         /* 24    */ \
   logic [4:0]    fun_id;        /* 23:19 */ \
   logic [2:0]    bar_id;        /* 18:16 */ \
   logic [7:0]    target_fn;     /* 15:8  */ \
   logic [7:0]    tag;           /*  7:0  */ \
   logic [7:0]    req_bus;       /* 31:24 */ \
   logic [7:0]    req_dev_fn;    /* 23:16 */ \
   logic          rsvd0;         /* 15    */ \
   logic [3:0]    req_type;      /* 14:11 */ \
   logic [10:0]   dword_count;   /* 10:0  */ \
   logic [61:0]   addr_63_2;     /* 63:2  */ \
   logic [1:0]    addr_type;     /*  1:0  */ \
} s_axis_cq_tdata_1024;

`define BMDREG(clk, reset_n, q, d, rstval)  \
   always_ff @(posedge clk) begin \
      if (~reset_n) \
         q  <= #(TCQ)   rstval;  \
      else  \
         q  <= #(TCQ)   d; \
   end

`define AS_BMDREG(clk, reset_n, q, d, rstval)  \
   always_ff @(posedge clk or negedge reset_n) begin \
      if (~reset_n) \
         q  <= #(TCQ)   rstval;  \
      else  \
         q  <= #(TCQ)   d; \
   end

`else    // PCIE_APP_USCALE_BMD_H
`endif   // PCIE_APP_USCALE_BMD_H
