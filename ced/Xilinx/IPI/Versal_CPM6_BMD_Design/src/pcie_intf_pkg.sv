package pcie_intf_pkg;

//************************************************************************
//
//      TX Headers
//
//************************************************************************

`define STRUCT_TX_DATA_P
typedef struct packed {
    logic [555:0]       reserved;                   // 851:296
    // xali_xaim_pkt[0].hdr_prot
    logic [21:0]        hdr_prot;                   // 295:274
    // xali_xaim_pkt[0].hdr.tlp_dst_segment
    logic [8:0]         dst_segment;                // 273:265
    // xali_xaim_pkt[0].hdr.tlp_segment
    logic [8:0]         segment;                    // 264:256
    // xali_xaim_pkt[0].prfx
    logic [95:0]        prfx;                       // 255:160
    // xali_xaim_pkt[0].hdr.addr_align_en
    logic               addr_align_en;              // 159
    // xali_xaim_pkt[0].hdr.tlp_atu_bypass
    logic               atu_bypass;                 // 158
    // xali_xaim_pkt[0].hdr.tlp_bad_eot
    logic               bad_eot;                    // 157
    // xali_xaim_pkt[0].hdr.tlp_ep
    logic               ep;                         // 156
    // xali_xaim_pkt[0].hdr.tlp_st
    logic [7:0]         st;                         // 155:148
    // xali_xaim_pkt[0].hdr.tlp_ph
    logic [1:0]         ph;                         // 147:146
    // xali_xaim_pkt[0].hdr.tlp_th
    logic               th;                         // 145
    // xali_xaim_pkt[0].hdr.tlp_nw
    logic               nw;                         // 144
    // xali_xaim_pkt[0].hdr.tlp_ats
    logic [1:0]         ats;                        // 143:142
    // xali_xaim_pkt[0].hdr.tlp_byte_en
    logic [7:0]         byte_en;                    // 141:134
    // xali_xaim_pkt[0].hdr.tlp_byte_len
    logic [12:0]        byte_len;                   // 133:121
    // xali_xaim_pkt[0].hdr.tlp_td
    logic               td;                         // 120
    // xali_xaim_pkt[0].hdr.tlp_vfunc_active
    logic               vfunc_active;               // 119
    // xali_xaim_pkt[0].hdr.tlp_vfunc_num
    logic [7:0]         vfunc_num;                  // 118:111
    // xali_xaim_pkt[0].hdr.tlp_func_num
    logic [2:0]         func_num;                   // 110:108
    // xali_xaim_pkt[0].t_bit
    logic               t_bit;                      // 107
    // xali_xaim_pkt[0].hdr.tlp_tid
    logic [13:0]        tid;                        // 106:93
    // xali_xaim_pkt[0].hdr.remote_req_id
    logic [15:0]        remote_req_id;              // 92:77
    // xali_xaim_pkt[0].hdr.tlp_attr
    logic [2:0]         attr;                       // 76:74
    // xali_xaim_pkt[0].hdr.tlp_tc
    logic [2:0]         tc;                         // 73:71
    // xali_xaim_pkt[0].hdr.tlp_type
    logic [4:0]         ttype;                      // 70:66
    // xali_xaim_pkt[0].hdr.tlp_fmt
    logic [1:0]         fmt;                        // 65:64
    // xali_xaim_pkt[0].hdr.tlp_addr
    logic [63:0]        addr;                       // 63:0
} tx_data_p;

`define STRUCT_TX_DATA_NP
typedef struct packed {
    logic [9:0]         reserved;                   // 283:274
    // xali_xaim_pkt[1].hdr.tlp_dst_segment
    logic [8:0]         dst_segment;                // 273:265
    // xali_xaim_pkt[1].hdr.tlp_segment
    logic [8:0]         segment;                    // 264:256
    // xali_xaim_pkt[1].prfx
    logic [95:0]        prfx;                       // 255:160
    // xali_xaim_pkt[1].hdr.addr_align_en
    logic               addr_align_en;              // 159
    // xali_xaim_pkt[1].hdr.tlp_atu_bypass
    logic               atu_bypass;                 // 158
    // xali_xaim_pkt[1].hdr.tlp_bad_eot
    logic               bad_eot;                    // 156
    // xali_xaim_pkt[1].hdr.tlp_ep
    logic               ep;                         // 156
    // xali_xaim_pkt[1].hdr.tlp_st
    logic [7:0]         st;                         // 155:148
    // xali_xaim_pkt[1].hdr.tlp_ph
    logic [1:0]         ph;                         // 147:146
    // xali_xaim_pkt[1].hdr.tlp_th
    logic               th;                         // 145
    // xali_xaim_pkt[1].hdr.tlp_nw
    logic               nw;                         // 144
    // xali_xaim_pkt[1].hdr.tlp_ats
    logic [1:0]         ats;                        // 143:142
    // xali_xaim_pkt[1].hdr.tlp_byte_en
    logic [7:0]         byte_en;                    // 141:134
    // xali_xaim_pkt[1].hdr.tlp_byte_len
    logic [12:0]        byte_len;                   // 133:121
    // xali_xaim_pkt[1].hdr.tlp_td
    logic               td;                         // 120
    // xali_xaim_pkt[1].vfunc_active
    logic               vfunc_active;               // 119
    // xali_xaim_pkt[1].vfunc_num
    logic [7:0]         vfunc_num;                  // 118:111
    // xali_xaim_pkt[1].func_num
    logic [2:0]         func_num;                   // 110:108
    // xali_xaim_pkt[1].t_bit
    logic               t_bit;                      // 107
    // xali_xaim_pkt[1].hdr.tlp_tid
    logic [13:0]        tid;                        // 106:93
    // xali_xaim_pkt[1].hdr.remote_req_id
    logic [15:0]        remote_req_id;              // 92:77
    // xali_xaim_pkt[1].hdr.tlp_attr
    logic [2:0]         attr;                       // 76:74
    // xali_xaim_pkt[1].hdr.tlp_tc
    logic [2:0]         tc;                         // 73:71
    // xali_xaim_pkt[1].hdr.tlp_type
    logic [4:0]         ttype;                      // 70:66
    // xali_xaim_pkt[1].hdr.tlp_fmt
    logic [1:0]         fmt;                        // 65:64
    // xali_xaim_pkt[1].hdr.tlp_addr
    logic [63:0]        addr;                       // 63:0
} tx_data_np;

`define STRUCT_TX_DATA_NPD
typedef struct packed {
    logic [555:0]       reserved;                   // 851:296
    // xali_xaim_pkt[1].hdr_prot
    logic [21:0]        hdr_prot;                   // 295:274
    // xali_xaim_pkt[1].hdr.tlp_dst_segment
    logic [8:0]         dst_segment;                // 273:265
    // xali_xaim_pkt[1].hdr.tlp_segment
    logic [8:0]         segment;                    // 264:256
    // xali_xaim_pkt[1].prfx
    logic [95:0]        prfx;                       // 255:160
    // xali_xaim_pkt[1].hdr.addr_align_en
    logic               addr_align_en;              // 159
    // xali_xaim_pkt[1].hdr.tlp_atu_bypass
    logic               atu_bypass;                 // 158
    // xali_xaim_pkt[1].hdr.tlp_bad_eot
    logic               bad_eot;                    // 157
    // xali_xaim_pkt[1].hdr.tlp_ep
    logic               ep;                         // 156
    // xali_xaim_pkt[1].hdr.tlp_st
    logic [7:0]         st;                         // 155:148
    // xali_xaim_pkt[1].hdr.tlp_ph
    logic [1:0]         ph;                         // 147:146
    // xali_xaim_pkt[1].hdr.tlp_th
    logic               th;                         // 145
    // xali_xaim_pkt[1].hdr.tlp_nw
    logic               nw;                         // 144
    // xali_xaim_pkt[1].hdr.tlp_ats
    logic [1:0]         ats;                        // 143:142
    // xali_xaim_pkt[1].hdr.tlp_byte_en
    logic [7:0]         byte_en;                    // 141:134
    // xali_xaim_pkt[1].hdr.tlp_byte_len
    logic [12:0]        byte_len;                   // 133:121
    // xali_xaim_pkt[1].hdr.tlp_td
    logic               td;                         // 120
    // xali_xaim_pkt[1].hdr.tlp_vfunc_active
    logic               vfunc_active;               // 119
    // xali_xaim_pkt[1].hdr.tlp_vfunc_num
    logic [7:0]         vfunc_num;                  // 118:111
    // xali_xaim_pkt[1].hdr.tlp_func_num
    logic [2:0]         func_num;                   // 110:108
    // xali_xaim_pkt[1].t_bit
    logic               t_bit;                      // 107
    // xali_xaim_pkt[1].hdr.tlp_tid
    logic [13:0]        tid;                        // 106:93
    // xali_xaim_pkt[1].hdr.remote_req_id
    logic [15:0]        remote_req_id;              // 92:77
    // xali_xaim_pkt[1].hdr.tlp_attr
    logic [2:0]         attr;                       // 76:74
    // xali_xaim_pkt[1].hdr.tlp_tc
    logic [2:0]         tc;                         // 73:71
    // xali_xaim_pkt[1].hdr.tlp_type
    logic [4:0]         ttype;                      // 70:66
    // xali_xaim_pkt[1].hdr.tlp_fmt
    logic [1:0]         fmt;                        // 65:64
    // xali_xaim_pkt[1].hdr.tlp_addr
    logic [63:0]        addr;                       // 63:0
} tx_data_npd;

`define STRUCT_TX_DATA_CPL
typedef struct packed {
    logic [525:0]       reserved;                   // 851:326
    // cpl_lookup_id
    logic [13:0]        lookup_id;                  // 325:312
    // xali_xaim_pkt[2].hdr_prot
    logic [21:0]        hdr_prot;                   // 311:290
    // xali_xaim_pkt[2].hdr.tlp_dst_segment
    logic [8:0]         dst_segment;                // 289:281
    // xali_xaim_pkt[2].hdr.tlp_segment
    logic [8:0]         segment;                    // 280:272
    // xali_xaim_pkt[2].prfx
    logic [95:0]        prfx;                       // 271:176
    // xali_xaim_pkt[2].hdr.cpl_byte_cnt
    logic [11:0]        byte_cnt;                   // 175:164
    // xali_xaim_pkt[2].hdr.cpl_bcm
    logic               bcm;                        // 163
    // xali_xaim_pkt[2].hdr.cpl_status
    logic [2:0]         status;                     // 162:160
    // xali_xaim_pkt[2].hdr.addr_align_en
    logic               addr_align_en;              // 159
    // xali_xaim_pkt[2].hdr.tlp_atu_bypass
    logic               atu_bypass;                 // 158
    // xali_xaim_pkt[2].hdr.tlp_bad_eot
    logic               bad_eot;                    // 157
    // xali_xaim_pkt[2].hdr.tlp_ep
    logic               ep;                         // 156
    // xali_xaim_pkt[2].hdr.tlp_st
    logic [7:0]         st;                         // 155:148
    // xali_xaim_pkt[2].hdr.tlp_ph
    logic [1:0]         ph;                         // 147:146
    // xali_xaim_pkt[2].hdr.tlp_th
    logic               th;                         // 145
    // xali_xaim_pkt[2].hdr.tlp_nw
    logic               nw;                         // 144
    // xali_xaim_pkt[2].hdr.tlp_ats
    logic [1:0]         ats;                        // 143:142
    // xali_xaim_pkt[2].hdr.tlp_byte_en
    logic [7:0]         byte_en;                    // 141:134
    // xali_xaim_pkt[2].hdr.tlp_byte_len
    logic [12:0]        byte_len;                   // 133:121
    // xali_xaim_pkt[2].hdr.tlp_td
    logic               td;                         // 120
    // xali_xaim_pkt[2].hdr.tlp_vfunc_active
    logic               vfunc_active;               // 119
    // xali_xaim_pkt[2].hdr.tlp_vfunc_num
    logic [7:0]         vfunc_num;                  // 118:111
    // xali_xaim_pkt[2].hdr.tlp_func_num
    logic [2:0]         func_num;                   // 110:108
    // xali_xaim_pkt[2].t_bit
    logic               t_bit;                      // 107
    // xali_xaim_pkt[2].hdr.tlp_tid
    logic [13:0]        tid;                        // 106:93
    // xali_xaim_pkt[2].hdr.remote_req_id
    logic [15:0]        remote_req_id;              // 92:77
    // xali_xaim_pkt[2].hdr.tlp_attr
    logic [2:0]         attr;                       // 76:74
    // xali_xaim_pkt[2].hdr.tlp_tc
    logic [2:0]         tc;                         // 73:71
    // xali_xaim_pkt[2].hdr.tlp_type
    logic [4:0]         ttype;                      // 70:66
    // xali_xaim_pkt[2].hdr.tlp_fmt
    logic [1:0]         fmt;                        // 65:64
    // xali_xaim_pkt[2].hdr.tlp_addr
    logic [63:0]        addr;                       // 63:0
} tx_data_cpl;

//************************************************************************
//
//      RX Headers
//
//************************************************************************

`define STRUCT_RX_DATA_P
typedef struct packed {
    logic [464:0]       reserved;                   // 884:420
    // radm_trgt1_p_0_hdr_prot
    logic [32:0]        hdr_prot;                   // 419:387
    // radm_trgt1_p_0_dllp_abort
    logic               dllp_abort;                 // 386
    // radm_trgt1_p_0_tlp_abort
    logic               tlp_abort;                  // 385
    // radm_trgt1_p_0_atu_cbuf_err
    logic [7:0]         atu_cbuf_err;               // 384:377
    // radm_trgt1_p_0_prfx
    logic [107:0]       prfx;                       // 376:269
    // radm_trgt1_p_0_cpl_status
    logic [2:0]         cpl_status;                 // 268:266
    // radm_trgt1_p_0_in_membar_range
    logic [2:0]         in_membar_range;            // 265:263
    // radm_trgt1_p_0_io_req_in_range
    logic               io_req_in_range;            // 262
    // radm_trgt1_p_0_rom_in_range
    logic               rom_in_range;               // 261
    // radm_trgt1_p_0_atu_sloc_match
    logic [7:0]         atu_sloc_match;             // 260:253
    // radm_trgt1_p_0_pkt_order_no
    logic [15:0]        pkt_order_no;               // 252:237
    // radm_trgt1_p_0_reqtr_sgmt
    logic [8:0]         reqtr_sgmt;                 // 236:228
    // radm_trgt1_p_0_dest_sgmt
    logic [8:0]         dest_sgmt;                  // 227:219
    // radm_trgt1_p_0_st
    logic [7:0]         st;                         // 218:211
    // radm_trgt1_p_0_ph
    logic [1:0]         ph;                         // 210:209
    // radm_trgt1_p_0_th
    logic               th;                         // 208
    // radm_trgt1_p_0_nw
    logic               nw;                         // 207
    // radm_trgt1_p_0_ats
    logic [1:0]         ats;                        // 206:205
    // radm_trgt1_p_0_last_be
    logic [3:0]         last_be;                    // 204:201
    // radm_trgt1_p_0_first_be
    logic [3:0]         first_be;                   // 200:197
    // radm_trgt1_p_0_dw_len
    logic [9:0]         dw_len;                     // 196:187
    // radm_trgt1_p_0_poisoned
    //logic               poisoned;                   // 187
    // radm_trgt1_p_0_td
    logic               td;                         // 186
    // radm_trgt1_p_0_vc_num
    logic               vc_num;                     // 185
    // radm_trgt1_p_0_vfunc_active
    logic               vfunc_active;               // 184
    // radm_trgt1_p_0_vfunc_num
    logic [7:0]         vfunc_num;                  // 183:176
    // radm_trgt1_p_0_func_num
    logic [2:0]         func_num;                   // 175:173
    // radm_trgt1_p_0_t_bit
    logic               t_bit;                      // 172
    // radm_trgt1_p_0_tag
    logic [13:0]        tag;                        // 171:158
    // radm_trgt1_p_0_reqid
    logic [15:0]        reqid;                      // 157:142
    // radm_trgt1_p_0_attr
    logic [2:0]         attr;                       // 141:139
    // radm_trgt1_p_0_tc
    logic [2:0]         tc;                         // 138:136
    // radm_trgt1_p_0_type
    logic [4:0]         ttype;                      // 135:131
    // radm_trgt1_p_0_fmt
    logic [1:0]         fmt;                        // 130:129
    // radm_trgt1_p_0_hdr_uppr_bytes_valid
    logic               hdr_uppr_bytes_valid;       // 128
    // radm_trgt1_p_0_hdr_uppr_bytes
    logic [63:0]        hdr_uppr_bytes;             // 127:64
    // radm_trgt1_p_0_addr
    logic [63:0]        addr;                       // 63:0
} rx_data_p;

`define STRUCT_RX_DATA_NP
typedef struct packed {
    logic [8:0]         reserved;                   // 294:286
    // trgt_lookup_id
    logic [13:0]        lookup_id;                  // 285:272
    // radm_trgt1_np_0_dllp_abort
    logic               dllp_abort;                 // 271
    // radm_trgt1_np_0_tlp_abort
    logic               tlp_abort;                  // 270
    // radm_trgt1_p_0_prfx
    logic [95:0]        prfx;                       // 269:164
    // radm_trgt1_np_0_in_membar_range
    logic [2:0]         in_membar_range;            // 173:171
    // radm_trgt1_np_0_reqtr_sgmt
    logic [8:0]         reqtr_sgmt;                 // 170:162
    // radm_trgt1_np_0_dest_sgmt
    logic [8:0]         dest_sgmt;                  // 161:153
    // radm_trgt1_np_0_st
    logic [7:0]         st;                         // 152:145
    // radm_trgt1_np_0_ph
    logic [1:0]         ph;                         // 144:143
    // radm_trgt1_np_0_th
    logic               th;                         // 142
    // radm_trgt1_np_0_nw
    logic               nw;                         // 141
    // radm_trgt1_np_0_ats
    logic [1:0]         ats;                        // 140:139
    // radm_trgt1_p_0_last_be
    logic [3:0]         last_be;                    // 138:135
    // radm_trgt1_p_0_first_be
    logic [3:0]         first_be;                   // 134:131
    // radm_trgt1_np_0_dw_len
    logic [9:0]         dw_len;                     // 130:121
    // radm_trgt1_np_0_td
    logic               td;                         // 120
    // radm_trgt1_np_0_vfunc_active
    logic               vfunc_active;               // 119
    // radm_trgt1_np_0_vfunc_num
    logic [7:0]         vfunc_num;                  // 118:111
    // radm_trgt1_np_0_func_num
    logic [2:0]         func_num;                   // 110:108
    // radm_trgt1_np_0_t_bit
    logic               t_bit;                      // 107
    // radm_trgt1_np_0_tag
    logic [13:0]        tag;                        // 106:93
    // radm_trgt1_np_0_reqid
    logic [15:0]        reqid;                      // 92:77
    // radm_trgt1_np_0_attr
    logic [2:0]         attr;                       // 76:74
    // radm_trgt1_np_0_tc
    logic [2:0]         tc;                         // 73:71
    // radm_trgt1_np_0_type
    logic [4:0]         ttype;                      // 70:66
    // radm_trgt1_np_0_fmt
    logic [1:0]         fmt;                        // 65:64
    // radm_trgt1_np_0_addr
    logic [63:0]        addr;                       // 63:0
} rx_data_np;

`define STRUCT_RX_DATA_NPD
typedef struct packed {
    logic [457:0]       reserved;                   // 884:428
    // trgt_lookup_id
    logic [13:0]        lookup_id;                  // 427:414
    // radm_trgt1_np_0_cxlsrc
    logic               cxlsrc;                     // 413
    // radm_trgt1_np_0_hdr_prot
    logic [24:0]        hdr_prot;                   // 412:388
    // radm_trgt1_np_0_dllp_abort
    logic               dllp_abort;                 // 387
    // radm_trgt1_np_0_tlp_abort
    logic               tlp_abort;                  // 386
    // radm_trgt1_np_0_atu_cbuf_err
    logic [7:0]         atu_cbuf_err;               // 385:378
    // radm_trgt1_np_0_prfx
    logic [107:0]       prfx;                       // 377:270
    // radm_trgt1_np_0_cpl_status
    logic [2:0]         cpl_status;                 // 269:267
    // radm_trgt1_np_0_in_membar_range
    logic [2:0]         in_membar_range;            // 266:264
    // radm_trgt1_np_0_io_req_in_range
    logic               io_req_in_range;            // 263
    // radm_trgt1_np_0_rom_in_range
    logic               rom_in_range;               // 262
    // radm_trgt1_np_0_atu_sloc_match
    logic [7:0]         atu_sloc_match;             // 261:254
    // radm_trgt1_np_0_pkt_order_no
    logic [15:0]        pkt_order_no;               // 253:238
    // radm_trgt1_np_0_reqtr_sgmt
    logic [8:0]         reqtr_sgmt;                 // 237:229
    // radm_trgt1_np_0_dest_sgmt
    logic [8:0]         dest_sgmt;                  // 228:220
    // radm_trgt1_np_0_st
    logic [7:0]         st;                         // 219:212
    // radm_trgt1_np_0_ph
    logic [1:0]         ph;                         // 211:210
    // radm_trgt1_np_0_th
    logic               th;                         // 209
    // radm_trgt1_np_0_nw
    logic               nw;                         // 208
    // radm_trgt1_np_0_ats
    logic [1:0]         ats;                        // 207:206
    // radm_trgt1_np_0_last_be
    logic [3:0]         last_be;                    // 205:202
    // radm_trgt1_np_0_first_be
    logic [3:0]         first_be;                   // 201:198
    // radm_trgt1_np_0_dw_len
    logic [9:0]         dw_len;                     // 197:188
    // radm_trgt1_np_0_poisoned
    //logic               poisoned;                   // 187
    // radm_trgt1_np_0_td
    logic               td;                         // 186
    // radm_trgt1_np_0_vc_num
    logic               vc_num;                     // 185
    // radm_trgt1_np_0_vfunc_active
    logic               vfunc_active;               // 184
    // radm_trgt1_np_0_vfunc_num
    logic [7:0]         vfunc_num;                  // 183:176
    // radm_trgt1_np_0_func_num
    logic [2:0]         func_num;                   // 175:173
    // radm_trgt1_np_0_t_bit
    logic               t_bit;                      // 172
    // radm_trgt1_np_0_tag
    logic [13:0]        tag;                        // 171:158
    // radm_trgt1_np_0_reqid
    logic [15:0]        reqid;                      // 157:142
    // radm_trgt1_np_0_attr
    logic [2:0]         attr;                       // 141:139
    // radm_trgt1_np_0_tc
    logic [2:0]         tc;                         // 138:136
    // radm_trgt1_np_0_type
    logic [4:0]         ttype;                      // 135:131
    // radm_trgt1_np_0_fmt
    logic [1:0]         fmt;                        // 130:129
    // radm_trgt1_np_0_hdr_uppr_bytes_valid
    logic               hdr_uppr_bytes_valid;       // 128
    // radm_trgt1_np_0_hdr_uppr_bytes
    logic [63:0]        hdr_uppr_bytes;             // 127:64
    // radm_trgt1_np_0_addr
    logic [63:0]        addr;                       // 63:0
} rx_data_npd;

`define STRUCT_RX_DATA_CPL
typedef struct packed {
    logic [615:0]       reserved;                   // 884:270
    // radm_trgt1_cpl_0_last
    logic               last;                       // 269
    // radm_trgt1_cpl_0_cmpltr_id
    logic [15:0]        cmpltr_id;                  // 268:253
    // radm_trgt1_cpl_0_byte_cnt
    logic [11:0]        byte_cnt;                   // 252:241
    // radm_trgt1_cpl_0_bcm
    logic               bcm;                        // 240
    // radm_trgt1_cpl_0_hdr_prot
    logic [17:0]        hdr_prot;                   // 239:222
    // radm_trgt1_cpl_0_dllp_abort
    logic               dllp_abort;                 // 221
    // radm_trgt1_cpl_0_tlp_abort
    logic               tlp_abort;                  // 220
    // radm_trgt1_cpl_0_prfx
    logic [107:0]       prfx;                       // 219:112
    // radm_trgt1_cpl_0_status
    logic [2:0]         status;                     // 111:109
    // radm_trgt1_cpl_0_p_pkt_order_no
    logic [15:0]        pkt_order_no;               // 108:93
    // radm_trgt1_cpl_0_cpl_sgmt
    logic [7:0]         cpl_sgmt;                   // 92:85
    // radm_trgt1_cpl_0_dest_sgmt
    logic [8:0]         dest_sgmt;                  // 84:76
    // radm_trgt1_cpl_0_dw_len
    logic [9:0]         dw_len;                     // 75:66
    // radm_trgt1_cpl_0_td
    logic               td;                         // 64
    // radm_trgt1_cpl_0_vc_num
    logic               vc_num;                     // 63
    // radm_trgt1_cpl_0_vfunc_active
    logic               vfunc_active;               // 62
    // radm_trgt1_cpl_0_vfunc_num
    logic [7:0]         vfunc_num;                  // 61:54
    // radm_trgt1_cpl_0_func_num
    logic [2:0]         func_num;                   // 53:51
    // radm_trgt1_cpl_0_t_bit
    logic               t_bit;                      // 50
    // radm_trgt1_cpl_0_tag
    logic [13:0]        tag;                        // 49:36
    // radm_trgt1_cpl_0_reqid
    logic [15:0]        reqid;                      // 35:20
    // radm_trgt1_cpl_0_attr
    logic [2:0]         attr;                       // 19:17
    // radm_trgt1_cpl_0_tc
    logic [2:0]         tc;                         // 16:14
    // radm_trgt1_cpl_0_type
    logic [4:0]         ttype;                      // 13:9
    // radm_trgt1_cpl_0_fmt
    logic [1:0]         fmt;                        // 8:7
    // radm_trgt1_cpl_0_addr
    logic [6:0]         addr;                       // 6:0
} rx_data_cpl;

//************************************************************************
//
//      Helper Structs (RX)
//
//************************************************************************

`define UNION_RX_SINGLE_SLOT_DATA
typedef union packed {
    rx_data_p                                       p;
    rx_data_np [pcie_str_pkg::MAX_SUB_SLOTS-1:0]    np;
    rx_data_npd                                     npd;
    rx_data_cpl                                     cpl;
    logic [pcie_str_pkg::RX_SLOT_WIDTH-1:0]         data;
} rx_single_slot_data;

`define STRUCT_RX_IF_FIFO
typedef struct packed {
    logic                                           pstart;
    logic [pcie_str_pkg::START_TYPE_WIDTH-1:0]      ptype;
    logic                                           pend;
    logic [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]   pnp_info;
    logic [pcie_str_pkg::END_DPTR_WIDTH-1:0]        pd_ptr;
    rx_single_slot_data                             pdata;
} rx_fifo_intf;

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
    tx_data_cpl                                     cpl;
    logic [pcie_str_pkg::TX_SLOT_WIDTH-1:0]         data;
} tx_single_slot_data;

`define STRUCT_TX_IF_FIFO
typedef struct packed {
    logic                                           pstart;
    logic [pcie_str_pkg::START_TYPE_WIDTH-1:0]      ptype;
    logic                                           pend;
    logic [pcie_str_pkg::START_NP_INFO_WIDTH-1:0]   pnp_info;
    logic [pcie_str_pkg::END_DPTR_WIDTH-1:0]        pd_ptr;
    tx_single_slot_data                             pdata;
} tx_fifo_intf;

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
    // rx_starttype[1:0] == NonPosted
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

localparam int              ENCODING_WIDTH_RX = $bits(pcie_intf_pkg::rx_fifo_intf);
localparam int              ENCODING_WIDTH_TX = $bits(pcie_intf_pkg::tx_fifo_intf);

endpackage
