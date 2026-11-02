////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
////////////////////////////////////////////////////////////////////////

package pcie_intf_pkg;

//************************************************************************
//
//      TX Headers
//
//************************************************************************

`define STRUCT_TX_DATA_P
typedef struct packed {
    logic [555:0]       reserved;                   // 851:296
    logic [21:0]        hdr_prot;                   // 295:274
    logic [8:0]         dst_segment;                // 273:265
    logic [8:0]         segment;                    // 264:256
    logic [95:0]        prfx;                       // 255:160
    logic               addr_align_en;              // 159
    logic               atu_bypass;                 // 158
    logic               bad_eot;                    // 157
    logic               ep;                         // 156
    logic [7:0]         st;                         // 155:148
    logic [1:0]         ph;                         // 147:146
    logic               th;                         // 145
    logic               nw;                         // 144
    logic [1:0]         ats;                        // 143:142
    logic [7:0]         byte_en;                    // 141:134
    logic [12:0]        byte_len;                   // 133:121
    logic               td;                         // 120
    logic               vfunc_active;               // 119
    logic [7:0]         vfunc_num;                  // 118:111
    logic [2:0]         func_num;                   // 110:108
    logic               t_bit;                      // 107
    logic [13:0]        tid;                        // 106:93
    logic [15:0]        remote_req_id;              // 92:77
    logic [2:0]         attr;                       // 76:74
    logic [2:0]         tc;                         // 73:71
    logic [4:0]         ttype;                      // 70:66
    logic [1:0]         fmt;                        // 65:64
    logic [63:0]        addr;                       // 63:0
} tx_data_p;

`define STRUCT_TX_DATA_NP
typedef struct packed {
    logic [9:0]         reserved;                   // 283:274
    logic [8:0]         dst_segment;                // 273:265
    logic [8:0]         segment;                    // 264:256
    logic [95:0]        prfx;                       // 255:160
    logic               addr_align_en;              // 159
    logic               atu_bypass;                 // 158
    logic               bad_eot;                    // 156
    logic               ep;                         // 156
    logic [7:0]         st;                         // 155:148
    logic [1:0]         ph;                         // 147:146
    logic               th;                         // 145
    logic               nw;                         // 144
    logic [1:0]         ats;                        // 143:142
    logic [7:0]         byte_en;                    // 141:134
    logic [12:0]        byte_len;                   // 133:121
    logic               td;                         // 120
    logic               vfunc_active;               // 119
    logic [7:0]         vfunc_num;                  // 118:111
    logic [2:0]         func_num;                   // 110:108
    logic               t_bit;                      // 107
    logic [13:0]        tid;                        // 106:93
    logic [15:0]        remote_req_id;              // 92:77
    logic [2:0]         attr;                       // 76:74
    logic [2:0]         tc;                         // 73:71
    logic [4:0]         ttype;                      // 70:66
    logic [1:0]         fmt;                        // 65:64
    logic [63:0]        addr;                       // 63:0
} tx_data_np;

`define STRUCT_TX_DATA_NPD
typedef struct packed {
    logic [555:0]       reserved;                   // 851:296
    logic [21:0]        hdr_prot;                   // 295:274
    logic [8:0]         dst_segment;                // 273:265
    logic [8:0]         segment;                    // 264:256
    logic [95:0]        prfx;                       // 255:160
    logic               addr_align_en;              // 159
    logic               atu_bypass;                 // 158
    logic               bad_eot;                    // 157
    logic               ep;                         // 156
    logic [7:0]         st;                         // 155:148
    logic [1:0]         ph;                         // 147:146
    logic               th;                         // 145
    logic               nw;                         // 144
    logic [1:0]         ats;                        // 143:142
    logic [7:0]         byte_en;                    // 141:134
    logic [12:0]        byte_len;                   // 133:121
    logic               td;                         // 120
    logic               vfunc_active;               // 119
    logic [7:0]         vfunc_num;                  // 118:111
    logic [2:0]         func_num;                   // 110:108
    logic               t_bit;                      // 107
    logic [13:0]        tid;                        // 106:93
    logic [15:0]        remote_req_id;              // 92:77
    logic [2:0]         attr;                       // 76:74
    logic [2:0]         tc;                         // 73:71
    logic [4:0]         ttype;                      // 70:66
    logic [1:0]         fmt;                        // 65:64
    logic [63:0]        addr;                       // 63:0
} tx_data_npd;


//************************************************************************
//
//      RX Headers
//
//************************************************************************




`define STRUCT_RX_DATA_CPL
typedef struct packed {
    logic [615:0]       reserved;                   // 884:269
    logic               last;                       // 268
    logic [15:0]        cmpltr_id;                  // 267:252
    logic [11:0]        byte_cnt;                   // 251:240
    logic               bcm;                        // 239
    logic [17:0]        hdr_prot;                   // 238:221
    logic               dllp_abort;                 // 220
    logic               tlp_abort;                  // 219
    logic [107:0]       prfx;                       // 218:111
    logic [2:0]         status;                     // 110:108
    logic [15:0]        pkt_order_no;               // 107:92
    logic [7:0]         cpl_sgmt;                   // 91:84
    logic [8:0]         dest_sgmt;                  // 83:75
    logic [9:0]         dw_len;                     // 74:65
    logic               td;                         // 64
    logic               vc_num;                     // 63
    logic               vfunc_active;               // 62
    logic [7:0]         vfunc_num;                  // 61:54
    logic [2:0]         func_num;                   // 53:51
    logic               t_bit;                      // 50
    logic [13:0]        tag;                        // 49:36
    logic [15:0]        reqid;                      // 35:20
    logic [2:0]         attr;                       // 19:17
    logic [2:0]         tc;                         // 16:14
    logic [4:0]         ttype;                      // 13:9
    logic [1:0]         fmt;                        // 8:7
    logic [6:0]         addr;                       // 6:0
} rx_data_cpl;

//************************************************************************
//
//      Helper Structs (RX)
//
//************************************************************************


`define RX_SINGLE_SLOT_DATA
typedef union packed{
    rx_data_cpl                                     cpl;
    logic [pcie_str_pkg::RX_SLOT_WIDTH-1:0]         data;
} rx_single_slot_data;



//***************************************************************************
//      TX DATA SLOT
//***************************************************************************

`define STRUCT_TX_DATA_SLOT
typedef struct packed {
    logic [(pcie_str_pkg::TX_SLOT_WIDTH/32)-1:0] [31:0]  data;         // Data is DW format for SLOT WIDTH
} tx_data_slot;



//************************************************************************
//
//      Helper Structs (TX)
//
//************************************************************************

`define UNION_TX_SINGLE_SLOT_DATA
typedef union packed {
    tx_data_p                                       p;
    tx_data_np [pcie_str_pkg::MAX_SUB_SLOTS-1:0]    np;
    tx_data_npd                                     npd;
    logic [pcie_str_pkg::TX_SLOT_WIDTH-1:0]         data;
} tx_single_slot_data;


`define STRUCT_END_PTR
typedef struct packed {
    logic [pcie_str_pkg::END_PTR_WIDTH-1:0]     ptr;
    logic [pcie_str_pkg::END_DPTR_WIDTH-1:0]    dptr;
} endptr_t;

//************************************************************************
//
//      RX Interface
//
//************************************************************************

`define STRUCT_RX_IF
typedef struct packed {
// Core -> PL (Input)

    // Data and Control Valid
    logic                                                       rx_valid;
    rx_single_slot_data [pcie_str_pkg::MAX_NUM_SLOTS-1:0]       rx_data ;

    // Odd Data Parity. One checkbit for every 64-bit data chunk
        // bit[0]: parity checkbit for rx_data[63:0]
        // ...
        // bit[31]: parity checkbit for { 5'd0, rx_data[2042:1984] }
    logic [pcie_str_pkg::RX_PARITY_WIDTH-1:0]       rx_parity;

    // Each bit in rx_start indicates that a packet is starting in this beat
    //      rx_start[0] = 1, at least 1 packet starting in this beat
    //      ...
    //      rx_start[2] = 1, at least 3 packets starting in this beat
    // if any bit of rx_start is 1, all lower bits must be 1
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                                          rx_start;

    // Pointer to starting slot location
    // Corresponds to rx_start[0]/[1]/[2]
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0][pcie_str_pkg::START_PTR_WIDTH-1:0]       rx_startptr;

    // Corresponds to rx_start[0]/[1]/[2]
    // Slot type:
    //      2'b00: Posted
    //      2'b01: NonPosted
    //      2'b10: Completion
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0][pcie_str_pkg::START_TYPE_WIDTH-1:0]      rx_starttype;

    // NonPosted TLP header info regarding packet corresponding to rx_start[n]
    // and residing in slot identified by rx_startnptr. This field is valid if
    // rx_startntype[1:0] == NonPosted
    //      3'b000 = NonPosted with Data TLP header
    //      3'b001 = 1 NonPosted no Data TLP header occupying subslot 0
    //      3'b011 = 2 NonPosted no Data TLP headers occupying subslot 0 and subslot 1
    //      3'b111 = 3 NonPosted no Data TLP headers occupying subslot 0, subslot 1, and subslot 2
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0][pcie_str_pkg::START_NP_INFO_WIDTH-1:0]   rx_startnpinfo;

    // Each bit in rx_end indicates that a packet is ending in this beat
    //      rx_end[0] = 1, at least 1 packet ending in this beat
    //      ...
    //      rx_end[2] = 1, at least 3 packets ending in this beat
    // if any bit of rx_end is 1, all lower bits must be 1
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0]         rx_end;

    // Corresponds to rx_end[0]/[1]/[2]
    // [5:4]: Pointer to end slot position
    // [3:0]: Pointer to the last aligned 4 bytes (DW) of data
    //        Valid only for data slots. Value is 0 for header slots
    endptr_t [pcie_str_pkg::MAX_NUM_SLOTS-1:0]      rx_endptr ;

    logic [pcie_str_pkg::END_ERROR_WIDTH-1:0]       rx_end_error;
} rx_intf;

//************************************************************************
//
//      TX Interface
//
//************************************************************************

`define STRUCT_TX_IF
typedef struct packed {
// PL -> Core (Output)

    // Data and Control Valid
    logic                                                                           tx_valid;
    tx_single_slot_data [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                           tx_data;

    // Odd Data Parity. One checkbit for every 64-bit data chunk
        // bit[0]: parity checkbit for tx_data[63:0]
        // ...
        // bit[30]: parity checkbit for { 31'd0, tx_data[1952:1920] }
    logic [pcie_str_pkg::TX_PARITY_WIDTH-1:0]                                       tx_parity;

    // Each bit in tx_start indicates that a packet is starting in this beat
    //      tx_start[0] = 1, at least 1 packet starting in this beat
    //      ...
    //      tx_start[2] = 1, at least 3 packets starting in this beat
    // if any bit of tx_start is 1, all lower bits must be 1
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0]                                         tx_start;

    // Pointer to starting slot location
    // Corresponds to tx_start[0]/[1]/[2]
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0][pcie_str_pkg::START_PTR_WIDTH-1:0]      tx_startptr;

    // Corresponds to tx_start[0]/[1]/[2]
    // Slot type:
    //      2'b00: Posted
    //      2'b01: NonPosted
    //      2'b10: Completion
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0][pcie_str_pkg::START_TYPE_WIDTH-1:0]     tx_starttype;

    // NonPosted TLP header info regarding packet corresponding to tx_start[n]
    // and residing in slot identified by tx_startnptr. This field is valid if
    // tx_startntype[1:0] == NonPosted
    //      3'b000 = NonPosted with Data TLP header
    //      3'b001 = 1 NonPosted no Data TLP header occupying subslot 0
    //      3'b011 = 2 NonPosted no Data TLP headers occupying subslot 0 and subslot 1
    //      3'b111 = 3 NonPosted no Data TLP headers occupying subslot 0, subslot 1, and subslot 2
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0][pcie_str_pkg::START_NP_INFO_WIDTH-1:0]   tx_startnpinfo;

    // Each bit in tx_end indicates that a packet is ending in this beat
    //      tx_end[0] = 1, at least 1 packet ending in this beat
    //      ...
    //      tx_end[2] = 1, at least 3 packets ending in this beat
    // if any bit of tx_end is 1, all lower bits must be 1
    logic [pcie_str_pkg::MAX_NUM_SLOTS-1:0]         tx_end;

    // Corresponds to tx_end[0]/[1]/[2]
    // [5:4]: Pointer to end slot position
    // [3:0]: Pointer to the last aligned 4 bytes (DW) of data
    //        Valid only for data slots. Value is 0 for header slots
    endptr_t [pcie_str_pkg::MAX_NUM_SLOTS-1:0]      tx_endptr;

    logic [pcie_str_pkg::END_ERROR_WIDTH-1:0]       tx_end_error;
} tx_intf;



//************************************************************************
//      COMPLETOR 
//************************************************************************

`define RX_CPL_IF
typedef struct packed {
    logic [1024 - 1 - pcie_str_pkg::RX_SLOT_WIDTH - 1 - 1 - 1 - pcie_str_pkg::END_DPTR_WIDTH - pcie_str_pkg::END_ERROR_WIDTH - 1:0] reserved; // Reserved bits to make struct exactly 1024 bits wide
    logic                           cpl_valid;      // if this slot is valid 
    rx_single_slot_data             cpl_data;       // data for this slot
    logic                           cpl_start;      // if this slot is start of a packet
    logic                           cpl_type;       // type of packet - cpl or data:  HDR:1, DATA:0
    logic                           cpl_end;        // if this slot is end of a packet
    logic [pcie_str_pkg::END_DPTR_WIDTH-1:0]      cpl_end_dptr;   // end data pointer for this slot
    logic [pcie_str_pkg::END_ERROR_WIDTH-1:0]     cpl_end_error;  // parameterize width  poisoned TLP if packet ending in the slot
} rx_cpl_intf;


/***************************************************************************
//     TRANSMITTER - to posted and non posted generation
***************************************************************************/
`define TX_PKT_IF
typedef struct packed {
    logic                               pkt_valid;      // if this slot is valid 
    logic                               pkt_type;      // type of packet - Hdr-0 or data-1
    logic [63:0]                        pkt_addr_data;       // addr/data for this slot
    logic [2:0]                         pkt_info;       // info for this slot
    logic [$clog2(pcie_rp_pkg::MAX_TAG_COUNT)-1:0]    pkt_tag; // tag for this slot
    ////////**********//////////////
    //PKT INFO//
    // type Hdr:  info: Mem32 Wr-'000, Mem32 Rd- '100, 
                    //  Mem64 Wr-'011, Mem64 Rd- '111,
                    //  Config RD-'101, Config WR-'110,
    // type Data: info: cfg/mem (0: cfg    1: mem), start (not required), end -> end: 001/101 
                       // bit 2: cfg(0) or mem(1)
                       // bit 1: start -> currently used only in configs
                       // bit 0: end - yes(1) or no(0)
    ///////**********//////////////
   } tx_pkt_intf;


//************************************************************************
//      RP CONFIGURATION INTERFACE
//************************************************************************
`define RP_CFG_IF
typedef struct packed {
    logic [31:0]                   addr;     // address for config read/write
    logic [31:0]                   data;     // data for config write
    logic                          valid;    // if this slot is valid for config read/write
    logic                          cfg_type; // type of config read/write - 1 for read, 0 for write
    logic [31:0]                   expected_data; // expected data for config read/write
} rp_cfg_intf;


// Add error counter declarations
typedef struct packed {
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] addr_mismatch_cnt;    // Address mismatch counter
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] data_mismatch_cnt;    // Data mismatch counter
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] fmt_mismatch_cnt;
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] ttype_mismatch_cnt;
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] URs_cnt;     // Unrecoverable errors counter
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] CAs_cnt;        // Completor Abort counter
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] cfg_retry_err_cnt;        // Configuration retry error counter
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] tlp_or_dllp_abort_err_cnt; // TLP or DLLP abort error counter
    logic [pcie_rp_pkg::ERROR_CNT_WIDTH-1:0] tlp_poisoned_cnt;          // TLP poisoned error counter
} error_counters_t;



endpackage
