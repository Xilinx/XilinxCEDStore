//=============================================================================
// IDE (Integrity and Data Encryption) Extended Capability
// PCIe Extended Capability ID: 0x30
//=============================================================================
class ecap_ide extends ecap_base;

  `uvm_object_utils(ecap_ide)

  //--- DW Offset Constants (for use with shim_api) ---
  // Base registers
  localparam int DW_HDR            = 0;   // 0x00: Extended Capability Header
  localparam int DW_CAP            = 1;   // 0x04: IDE Capability
  localparam int DW_CTRL           = 2;   // 0x08: IDE Control
  
  // Link IDE Stream Block (assuming 1 TC, offset 0x0C)
  localparam int DW_LINK_CTRL      = 3;   // 0x0C: Link IDE Stream Control
  localparam int DW_LINK_STATUS    = 4;   // 0x10: Link IDE Stream Status
  
  // Selective IDE Stream Block 0 (assuming starts at 0x14)
  // Note: Actual offset depends on number of Link IDE TCs supported
  localparam int DW_SEL_CAP        = 5;   // 0x14: Selective IDE Stream Capability
  localparam int DW_SEL_CTRL       = 6;   // 0x18: Selective IDE Stream Control
  localparam int DW_SEL_STATUS     = 7;   // 0x1C: Selective IDE Stream Status
  localparam int DW_SEL_RID_ASSOC1 = 8;   // 0x20: IDE RID Association Register 1
  localparam int DW_SEL_RID_ASSOC2 = 9;   // 0x24: IDE RID Association Register 2
  localparam int DW_SEL_ADDR_ASSOC0= 10;  // 0x28: IDE Address Association Register Block 0
  // Each Address Association block is 3 DWs (12 bytes)

  // -------------------- 
  // Capability Registers
  // -------------------- 

  typedef struct packed {
    logic [5:0]  rsvd31to26;
    logic        tee_limited_stream_sup;         // [25]
    logic        flowthrough_ide_stream_sup;     // [24]
    logic [7:0]  num_sel_ide_streams_sup;        // [23:16]
    logic [2:0]  num_tcs_for_link_ide;           // [15:13]
    logic [4:0]  supported_algo;                 // [12:8] 0=AES-GCM-256
    logic        sel_ide_for_cfg_req_sup;        // [7]
    logic        ide_km_protocol_sup;            // [6]
    logic        pcrc_sup;                       // [5]
    logic        aggregation_sup;                // [4]
    logic        rsvd3;                          // [3]
    logic        flowthrough_sup;                // [2]
    logic        sel_ide_stream_sup;             // [1]
    logic        link_ide_stream_sup;            // [0]
  } ide_cap_s;

  typedef struct packed {
    logic [31:1] rsvd31to1;
    logic        flowthrough_ide_stream_en;      // [0]
  } ide_ctrl_s;

  // Link IDE Stream Control
  typedef struct packed {
    logic [7:0]  stream_id;                      // [31:24]
    logic [1:0]  rsvd23to22;                     // [23:22]
    logic [2:0]  tc;                             // [21:19]
    logic [2:0]  rsvd18to16;                     // [18:16]
    logic [3:0]  partial_header_enc_mode;        // [15:12] PCIe 6.1+
    logic [2:0]  rsvd11to9;                      // [11:9]
    logic        pcrc_en;                        // [8]
    logic [5:0]  rsvd7to2;                       // [7:2]
    logic        tx_aggr_mode_npr;               // [1]
    logic        en;                             // [0]
  } link_ide_ctrl_s;

  // Link IDE Stream Status
  typedef struct packed {
    logic [27:0] rsvd31to4;                      // [31:4]
    logic        recv_integrity_check_fail;      // [3]
    logic        rsvd2;                          // [2]
    logic        state;                          // [1] 0=Insecure, 1=Secure
    logic        rsvd0;                          // [0]
  } link_ide_stts_s;

  // Selective IDE Stream Capability
  typedef struct packed {
    logic [27:0] rsvd31to4;                      // [31:4]
    logic [3:0]  num_addr_assoc_reg_blocks;      // [3:0]
  } sel_ide_cap_s;

  // Selective IDE Stream Control
  // PCIe 6.x spec: DEFAULT_STREAM at [22], PHE_MODE at [13:10]
  typedef struct packed {
    logic [7:0]  stream_id;                      // [31:24]
    logic        rsvd23;                         // [23]
    logic        default_stream;                 // [22]
    logic [2:0]  tc;                             // [21:19]
    logic [4:0]  rsvd18to14;                     // [18:14]
    logic [3:0]  partial_header_enc_mode;        // [13:10]
    logic        sel_ide_for_cfg_req_en;         // [9]
    logic        pcrc_en;                        // [8]
    logic [5:0]  rsvd7to2;                       // [7:2]
    logic        tx_aggr_mode_npr;               // [1]
    logic        en;                             // [0]
  } sel_ide_ctrl_s;

  // Selective IDE Stream Status
  typedef struct packed {
    logic [27:0] rsvd31to4;                      // [31:4]
    logic        recv_integrity_check_fail;      // [3]
    logic        rsvd2;                          // [2]
    logic        state;                          // [1] 0=Insecure, 1=Secure
    logic        rsvd0;                          // [0]
  } sel_ide_stts_s;

  // IDE RID Association Register 1
  typedef struct packed {
    logic [7:0]  rsvd31to24;                     // [31:24]
    logic [15:0] rid_limit;                      // [23:8]
    logic [7:0]  rsvd7to0;                       // [7:0]
  } ide_rid_assoc1_s;

  // IDE RID Association Register 2
  typedef struct packed {
    logic [7:0]  rsvd31to24;                     // [31:24]
    logic [15:0] rid_base;                       // [23:8]
    logic [6:0]  rsvd7to1;                       // [7:1]
    logic        valid;                          // [0]
  } ide_rid_assoc2_s;

  // IDE Address Association Register (first DW of block)
  typedef struct packed {
    logic [11:0] mem_limit_lo;                   // [31:20]
    logic [11:0] mem_base_lo;                    // [19:8]
    logic [6:0]  rsvd7to1;                       // [7:1]
    logic        valid;                          // [0]
  } ide_addr_assoc_lo_s;

  // IDE Address Association Register (upper limit DW)
  typedef struct packed {
    logic [31:0] mem_limit_hi;                   // [31:0]
  } ide_addr_limit_hi_s;

  // IDE Address Association Register (upper base DW)
  typedef struct packed {
    logic [31:0] mem_base_hi;                    // [31:0]
  } ide_addr_base_hi_s;

  // IDE Address Association Block (3 DWs per block)
  typedef struct packed {
    ide_addr_base_hi_s   base_hi;                // Highest DW in block
    ide_addr_limit_hi_s  limit_hi;               // Middle DW
    ide_addr_assoc_lo_s  lo;                     // Lowest DW in block
  } ide_addr_assoc_block_s;

  // -------------------- 
  // The capability's data: to read or write
  // Note: This is a simplified structure for 1 Link IDE TC and 1 Selective IDE Stream
  // with 2 address association blocks
  // -------------------- 
  
  // Number of supported address association blocks
  localparam int NUM_ADDR_ASSOC_BLOCKS = 2;

  union packed {
    logic [63:0][ 7:0] bytes;
    logic [15:0][31:0] dws;
    struct packed {
      ide_addr_assoc_block_s [NUM_ADDR_ASSOC_BLOCKS-1:0] sel_addr; // DW10-15 (0x28-0x3C) - packed array
      ide_rid_assoc2_s     sel_rid_assoc2;         // DW9  (0x24)
      ide_rid_assoc1_s     sel_rid_assoc1;         // DW8  (0x20)
      sel_ide_stts_s       sel_status;             // DW7  (0x1C)
      sel_ide_ctrl_s       sel_ctrl;               // DW6  (0x18)
      sel_ide_cap_s        sel_cap;                // DW5  (0x14)
      link_ide_stts_s      link_status;            // DW4  (0x10)
      link_ide_ctrl_s      link_ctrl;              // DW3  (0x0C)
      ide_ctrl_s           ctrl;                   // DW2  (0x08)
      ide_cap_s            cap;                    // DW1  (0x04)
      ecap_hdr_s           hdr;                    // DW0  (0x00)
    } cap;
  } data;

  // -------------------- 
  // Each register field's attributes (partial - key fields only)
  // -------------------- 
    
  struct { 
    struct {
      field_attr_t link_ide_stream_sup   = {'h4, 0, 0, ACC_RO, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t sel_ide_stream_sup    = {'h4, 1, 1, ACC_RO, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t num_sel_ide_streams   = {'h4, 23, 16, ACC_RO, ACC_UNSPEC, 'x, 'x, 'x};
    } cap;
    struct {
      field_attr_t en                    = {'hC, 0, 0, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t pcrc_en               = {'hC, 8, 8, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t tc                    = {'hC, 21, 19, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t stream_id             = {'hC, 31, 24, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
    } link_ctrl;
    struct {
      field_attr_t state                 = {'h10, 1, 1, ACC_RO, ACC_UNSPEC, 'x, 'x, 'x};
    } link_status;
    struct {
      field_attr_t en                    = {'h18, 0, 0, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t pcrc_en               = {'h18, 8, 8, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t sel_ide_for_cfg_req   = {'h18, 9, 9, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t partial_header_enc_mode = {'h18, 13, 10, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t default_stream        = {'h18, 22, 22, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t tc                    = {'h18, 21, 19, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t stream_id             = {'h18, 31, 24, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
    } sel_ctrl;
    struct {
      field_attr_t state                 = {'h1C, 1, 1, ACC_RO, ACC_UNSPEC, 'x, 'x, 'x};
    } sel_status;
    struct {
      field_attr_t rid_limit             = {'h20, 23, 8, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
    } rid_assoc1;
    struct {
      field_attr_t rid_base              = {'h24, 23, 8, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t valid                 = {'h24, 0, 0, ACC_RW, ACC_UNSPEC, 'x, 'x, 'x};
    } rid_assoc2;
  } attrs; 

  function new(string name = "ecap_ide");
    super.new(name);
    cap_id = ECAP_IDE;
  endfunction

  virtual function logic [7:0] get_byte(int offset);
    return data.bytes[offset];
  endfunction

  virtual function void set_byte(int offset, logic [7:0] data); 
    this.data.bytes[offset] = data;
  endfunction

  virtual function logic [31:0] get_dw(int offset);
    return data.dws[offset];
  endfunction

  virtual function void set_dw(int offset, logic [31:0] data); 
    this.data.dws[offset] = data;
  endfunction

  //--- Helper functions for Link IDE Stream ---

  // Build Link IDE control register value
  function logic [31:0] build_link_ctrl(
    bit [7:0] stream_id,
    bit [2:0] tc,
    bit       pcrc_en,
    bit       enable
  );
    logic [31:0] val;
    val = {stream_id, 2'b0, tc, 3'b0, 4'b0, 3'b0, pcrc_en, 6'b0, 1'b0, enable};
    return val;
  endfunction

  // Set Link IDE enable
  function void set_link_enable(bit en);
    data.cap.link_ctrl.en = en;
  endfunction

  // Check Link IDE secure state
  function bit is_link_secure();
    return data.cap.link_status.state;
  endfunction

  //--- Helper functions for Selective IDE Stream ---

  // Build Selective IDE control register value
  function logic [31:0] build_sel_ctrl(
    bit [7:0] stream_id,
    bit [2:0] tc,
    bit [3:0] partial_header_enc_mode,
    bit       sel_ide_for_cfg_req,
    bit       default_stream,
    bit       pcrc_en,
    bit       enable
  );
    logic [31:0] val;
    // PCIe 6.x: [31:24]=stream_id, [23]=rsvd, [22]=default_stream, [21:19]=tc,
    //           [18:14]=rsvd, [13:10]=phe_mode, [9]=sel_cfg, [8]=pcrc, [7:2]=rsvd, [1]=aggr, [0]=en
    val = {stream_id, 1'b0, default_stream, tc, 5'b0, partial_header_enc_mode,
           sel_ide_for_cfg_req, pcrc_en, 6'b0, 1'b0, enable};
    return val;
  endfunction

  // Set Selective IDE enable
  function void set_sel_enable(bit en);
    data.cap.sel_ctrl.en = en;
  endfunction

  // Check Selective IDE secure state
  function bit is_sel_secure();
    return data.cap.sel_status.state;
  endfunction

  // Set RID association
  function void set_rid_assoc(
    bit [15:0] rid_base,
    bit [15:0] rid_limit,
    bit        valid
  );
    data.cap.sel_rid_assoc1.rid_limit = rid_limit;
    data.cap.sel_rid_assoc2.rid_base = rid_base;
    data.cap.sel_rid_assoc2.valid = valid;
  endfunction

  // Set address association (block 0 to NUM_ADDR_ASSOC_BLOCKS-1)
  function void set_addr_assoc(
    int        block_idx,
    bit [63:0] addr_base,
    bit [63:0] addr_limit,
    bit        valid
  );
    if (block_idx < NUM_ADDR_ASSOC_BLOCKS) begin
      data.cap.sel_addr[block_idx].lo.mem_base_lo = addr_base[31:20];
      data.cap.sel_addr[block_idx].lo.mem_limit_lo = addr_limit[31:20];
      data.cap.sel_addr[block_idx].lo.valid = valid;
      data.cap.sel_addr[block_idx].limit_hi.mem_limit_hi = addr_limit[63:32];
      data.cap.sel_addr[block_idx].base_hi.mem_base_hi = addr_base[63:32];
    end
  endfunction

  // Get address association values (block 0 to NUM_ADDR_ASSOC_BLOCKS-1)
  function void get_addr_assoc(
    int              block_idx,
    output bit [63:0] addr_base,
    output bit [63:0] addr_limit,
    output bit        valid
  );
    if (block_idx < NUM_ADDR_ASSOC_BLOCKS) begin
      addr_base[31:20] = data.cap.sel_addr[block_idx].lo.mem_base_lo;
      addr_base[19:0] = 0;
      addr_base[63:32] = data.cap.sel_addr[block_idx].base_hi.mem_base_hi;
      addr_limit[31:20] = data.cap.sel_addr[block_idx].lo.mem_limit_lo;
      addr_limit[19:0] = 0;
      addr_limit[63:32] = data.cap.sel_addr[block_idx].limit_hi.mem_limit_hi;
      valid = data.cap.sel_addr[block_idx].lo.valid;
    end
  endfunction

  // Get DW offset for address association block
  function int get_addr_assoc_dw_offset(int block_idx);
    return DW_SEL_ADDR_ASSOC0 + (block_idx * 3);
  endfunction

  //--- Configure ecap_ide internal data from parameters ---
  
  // Configure Link IDE from config object
  function void configure_link_from_cfg(
    bit [7:0] stream_id,
    bit [2:0] tc,
    bit       pcrc_en,
    bit [3:0] partial_header_enc_mode = 0,
    bit       tx_aggr_mode_npr = 0,
    bit       enable = 0
  );
    data.cap.link_ctrl.stream_id = stream_id;
    data.cap.link_ctrl.tc = tc;
    data.cap.link_ctrl.pcrc_en = pcrc_en;
    data.cap.link_ctrl.partial_header_enc_mode = partial_header_enc_mode;
    data.cap.link_ctrl.tx_aggr_mode_npr = tx_aggr_mode_npr;
    data.cap.link_ctrl.en = enable;
  endfunction

  // Configure Selective IDE from config object
  function void configure_sel_from_cfg(
    bit [7:0]  stream_id,
    bit [2:0]  tc,
    bit        pcrc_en,
    bit [3:0]  partial_header_enc_mode = 0,
    bit        default_stream = 0,
    bit        sel_ide_for_cfg_req = 0,
    bit        tx_aggr_mode_npr = 0,
    bit        enable = 0,
    bit [15:0] rid_base = 0,
    bit [15:0] rid_limit = 0,
    bit        rid_valid = 0
  );
    data.cap.sel_ctrl.stream_id = stream_id;
    data.cap.sel_ctrl.tc = tc;
    data.cap.sel_ctrl.pcrc_en = pcrc_en;
    data.cap.sel_ctrl.partial_header_enc_mode = partial_header_enc_mode;
    data.cap.sel_ctrl.default_stream = default_stream;
    data.cap.sel_ctrl.sel_ide_for_cfg_req_en = sel_ide_for_cfg_req;
    data.cap.sel_ctrl.tx_aggr_mode_npr = tx_aggr_mode_npr;
    data.cap.sel_ctrl.en = enable;
    set_rid_assoc(rid_base, rid_limit, rid_valid);
  endfunction

endclass
