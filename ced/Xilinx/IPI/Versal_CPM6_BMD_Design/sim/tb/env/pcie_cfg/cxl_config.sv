class cxl_config extends uvm_object;

  `uvm_object_utils(cxl_config)

  function new(string name = "cxl_config");
    super.new(name);
  endfunction

  /* Typedefs */
  typedef enum bit [3:0] {NA, _64KB, _1MB, NO_CSU} csu_t;

  typedef struct {
    rand  logic [63:32] hi;
    rand  logic [31:28] lo;
          bit           mem_info_valid = 1'b1;
    rand  logic         mem_active;
          bit   [ 2: 0] media_type     = 3'b010;
          bit   [ 2: 0] memory_class   = 3'b010;
    rand  logic [14: 0] des_ileave;
    rand  logic [ 8: 0] mem_active_timeout;
    rand  logic         mem_active_degr;
  } hdm_range_s;

  typedef struct packed {
    bit [31:0] rsvd;
    // target_list and skip are the same register offset,
    // which is used is dependent on if it's a CXL device or not
    union packed {
      struct packed {
        struct packed {
          bit [31:24] tpi_for_ilvway7;
          bit [23:16] tpi_for_ilvway6;
          bit [15: 8] tpi_for_ilvway5;
          bit [ 7: 0] tpi_for_ilvway4;
        } high;
        struct packed {
          bit [31:24] tpi_for_ilvway3;
          bit [23:16] tpi_for_ilvway2;
          bit [15: 8] tpi_for_ilvway1;
          bit [ 7: 0] tpi_for_ilvway0;
        } low;
      } target_list;
      struct packed {
        bit [63:32] high;
        struct packed {
          bit [31:28] addr;
          bit [27: 0] rsvd;
        } low;
      } skip;
    } opt;
    // --- //
    struct packed {
      bit [31:28] rsvd1;
      bit [27:24] ilv_set_pos;
      bit [23:20] us_ilv_ways;
      bit [19:16] us_ilv_gran;
      bit         rsvd0;
      bit         uio;
      bit         bi;
      bit         target_range_type;
      bit         err_not_commited;
      bit         committed;
      bit         commit;
      bit         lock_on_commit;
      bit [ 7: 4] ilv_ways;
      bit [ 3: 0] ilv_gran;
    } control;
    struct packed {
      bit [63:32] high;
      struct packed {
        bit [31:28] addr;
        bit [27: 0] rsvd;
      } low;
    } size;
    struct packed {
      bit [63:32] high;
      struct packed {
        bit [31:28] addr;
        bit [27: 0] rsvd;
      } low;
    } base;
  } hdm_decoder_n_t;

  /* Sideband Features (that may roll into capabilities */
  rand logic [1:0] cxl_rev_maj;
  rand logic [1:0] cxl_device_type;

  /* Extended Capabilities */
  typedef struct {
    bit en;
    rand struct {
           bit         cache_cap;
           bit         mem_cap;
      rand logic [1:0] hdm_count;
    } cxl_cap; 
    rand struct {
      rand csu_t       cache_size_unit = NO_CSU;
      rand logic [7:0] cache_size;
    } cxl_cap2; 
    rand hdm_range_s hdm_range[1:2];
  } dvsec_for_cxl_ecap_t; rand dvsec_for_cxl_ecap_t dvsec_cxl_cap;

  // MMIO Capabilities
  typedef struct {
    bit en;
    hdm_decoder_n_t decoder[];
    struct packed {
      bit [31: 2] rsvd;
      bit         hdm_dec_en;
      bit         poison_on_dec_err_en;
    } global_ctrl; 
    struct packed {
      bit [31:23] rsvd;
      bit [22:21] coherency_model_supp;
      bit         memdata_nxm_cap;
      bit [19:16] uio_decoder_cnt;
      bit         uio_cap;
      bit         way16_ilv_cap;
      bit         way3_6_12_ilv_cap;
      bit         poison_on_dec_err_cap;
      bit         a14to12_ilv_cap;
      bit         a11to8_ilv_cap;
      bit [ 7: 4] target_cnt;
      bit [ 3: 0] decoder_cnt;
    } cap;
  } hdm_dec_cap_t; hdm_dec_cap_t hdm_dec_cap;

  typedef struct {
    bit en;
    struct packed { 
      bit         en_txfer_emd;
      bit [30: 9] rsvd1;
      bit         emd_err_log_en;
      bit         rsvd0;
      bit [ 6: 0] nbits_emd;
    } ctrl;
    struct packed {
      bit [31: 9] rsvd1;
      bit         emd_err_log_supp;
      bit         rsvd0;
      bit [ 6: 0] max_nbits_emd;
    } cap;
  } emd_cap_t; emd_cap_t emd_cap;

  /* Constraints */
  constraint c_valid_type { cxl_device_type inside {[1:3]}; }  
  constraint c_valid_cxl_rev { 
    cxl_rev_maj inside {[1:3]}; 
    soft cxl_rev_maj != 1;
  }
  constraint c_device_limits {
    dvsec_cxl_cap.cxl_cap2.cache_size_unit!=NO_CSU;
    // CXL.mem only
    if (cxl_device_type==3) {
      dvsec_cxl_cap.cxl_cap2.cache_size_unit==NA;
      dvsec_cxl_cap.cxl_cap2.cache_size==0;
    }
    // CXL.mem 
    if (cxl_device_type inside {2,3}) {
      dvsec_cxl_cap.cxl_cap.hdm_count inside {1,2};
    } 
    // CXL.cache only
    if (cxl_device_type==1) {
      !dvsec_cxl_cap.cxl_cap.hdm_count;
    }
    // CXL.cache 
    if (cxl_device_type inside {1,2}) {
      dvsec_cxl_cap.cxl_cap2.cache_size_unit!=NA;
      dvsec_cxl_cap.cxl_cap2.cache_size!=0;
    }
  }
  constraint c_range {
    foreach (dvsec_cxl_cap.hdm_range[ii]) {
           dvsec_cxl_cap.hdm_range[ii].mem_active^dvsec_cxl_cap.hdm_range[ii].mem_active_degr;
           dvsec_cxl_cap.hdm_range[ii].des_ileave inside {0, 256, 512, 1024, 2048, 4096, 8192, 16384};
           dvsec_cxl_cap.hdm_range[ii].mem_active_timeout inside {1, 4, 16, 64, 256};
      soft {dvsec_cxl_cap.hdm_range[ii].hi,dvsec_cxl_cap.hdm_range[ii].lo} != '0;
    }
  }
 
  function void pre_randomize;
    // Disable randomization if variable already set
    cxl_rev_maj.rand_mode(cxl_rev_maj==='x); 
    cxl_device_type.rand_mode(cxl_device_type==='x); 
    foreach (dvsec_cxl_cap.hdm_range[ii]) begin
      dvsec_cxl_cap.hdm_range[ii].hi.rand_mode(dvsec_cxl_cap.hdm_range[ii].hi==='x);
      dvsec_cxl_cap.hdm_range[ii].lo.rand_mode(dvsec_cxl_cap.hdm_range[ii].lo==='x);
      dvsec_cxl_cap.hdm_range[ii].mem_active.rand_mode(dvsec_cxl_cap.hdm_range[ii].mem_active==='x);
      dvsec_cxl_cap.hdm_range[ii].mem_active_degr.rand_mode(dvsec_cxl_cap.hdm_range[ii].mem_active_degr==='x);
      // ---
      if (!(dvsec_cxl_cap.hdm_range[ii].des_ileave inside {'x, 0, 256, 512, 1024, 2048, 4096, 8192, 16384})) begin
       `uvm_error(get_type_name, $sformatf("dvsec_cxl_cap.hdm_range[ii].des_ileave=%0d is invalid", dvsec_cxl_cap.hdm_range[ii].des_ileave))
        dvsec_cxl_cap.hdm_range[ii].des_ileave.rand_mode(1);
      end
      else dvsec_cxl_cap.hdm_range[ii].des_ileave.rand_mode(dvsec_cxl_cap.hdm_range[ii].des_ileave==='x);
      // ---
      if (!(dvsec_cxl_cap.hdm_range[ii].mem_active_timeout inside {'x, 1, 4, 16, 64, 256})) begin
       `uvm_error(get_type_name, $sformatf("dvsec_cxl_cap.hdm_range[ii].mem_active_timeout=%0d is invalid", dvsec_cxl_cap.hdm_range[ii].mem_active_timeout))
        dvsec_cxl_cap.hdm_range[ii].mem_active_timeout.rand_mode(1);
      end
      else dvsec_cxl_cap.hdm_range[ii].mem_active_timeout.rand_mode(dvsec_cxl_cap.hdm_range[ii].mem_active_timeout==='x);
    end
    dvsec_cxl_cap.cxl_cap.hdm_count.rand_mode(dvsec_cxl_cap.cxl_cap.hdm_count==='x);
    dvsec_cxl_cap.cxl_cap2.cache_size_unit.rand_mode(dvsec_cxl_cap.cxl_cap2.cache_size_unit===NO_CSU);
    dvsec_cxl_cap.cxl_cap2.cache_size.rand_mode(dvsec_cxl_cap.cxl_cap2.cache_size==='x);
  endfunction

  function void post_randomize;
    dvsec_cxl_cap.cxl_cap.mem_cap   = cxl_device_type inside {2,3};
    dvsec_cxl_cap.cxl_cap.cache_cap = cxl_device_type inside {1,2};
  endfunction

  virtual function void print_settings(int fd);
    string str;
    $fdisplay(fd, "  // Settings from %0s", get_type_name);
    $fdisplay(fd, "  - cxl_rev_maj : %0d",     cxl_rev_maj); 
    $fdisplay(fd, "  - cxl_device_type : %0d", cxl_device_type);
    // DVSEC_CXL_CAP: Mandatory=[D1, D2, LD, FMLD], else Not Permitted
    if (dvsec_cxl_cap.en) begin
      // Cache-relevant details
      if (cxl_device_type inside {1,2}) begin
        str = dvsec_cxl_cap.cxl_cap2.cache_size_unit.name;
        if (str.getc(0) == "_") str = str.substr(1, str.len-1);
        $fdisplay(fd, "  - cache_size_unit : %0s", str);
        $fdisplay(fd, "  - cache_size      : %0d", dvsec_cxl_cap.cxl_cap2.cache_size);
      end
      // Mem-relevant details
      if (cxl_device_type inside {2,3}) begin
        $fdisplay(fd, "  - hdm_count : %0d", dvsec_cxl_cap.cxl_cap.hdm_count);
        foreach (dvsec_cxl_cap.hdm_range[ii]) begin
          if (ii>dvsec_cxl_cap.cxl_cap.hdm_count) continue;
          $fdisplay(fd, "  // HDM Range %0d", ii);
          $fdisplay(fd, "  - size.hi[63:32] : 'h%0x",         dvsec_cxl_cap.hdm_range[ii].hi);
          $fdisplay(fd, "  - size.lo[31:28] : 'h%0x",         dvsec_cxl_cap.hdm_range[ii].lo);
          $fdisplay(fd, "  - mem_info_valid : %0d",           dvsec_cxl_cap.hdm_range[ii].mem_info_valid);
          $fdisplay(fd, "  - mem_active : %0d",               dvsec_cxl_cap.hdm_range[ii].mem_active);
          $fdisplay(fd, "  - media_type : %0d",               dvsec_cxl_cap.hdm_range[ii].media_type);
          $fdisplay(fd, "  - memory_class : %0d",             dvsec_cxl_cap.hdm_range[ii].memory_class);
          $fdisplay(fd, "  - des_ileave : %0d (B)",           dvsec_cxl_cap.hdm_range[ii].des_ileave);
          $fdisplay(fd, "  - mem_active_timeout : %0d (sec)", dvsec_cxl_cap.hdm_range[ii].mem_active_timeout);
          $fdisplay(fd, "  - mem_active_degr : %0d",          dvsec_cxl_cap.hdm_range[ii].mem_active_degr);
        end 
      end
    end
    if (hdm_dec_cap.en) begin
      $fdisplay(fd, "  // HDM Decoder Capability");
      case (hdm_dec_cap.cap.decoder_cnt)
        0 : $fdisplay(fd, "  - decoder_count : 1");
        1 : $fdisplay(fd, "  - decoder_count : 2");
        2 : $fdisplay(fd, "  - decoder_count : 4");
        3 : $fdisplay(fd, "  - decoder_count : 6");
        4 : $fdisplay(fd, "  - decoder_count : 8");
        5 : $fdisplay(fd, "  - decoder_count : 10");
        6 : $fdisplay(fd, "  - decoder_count : 12");
        7 : $fdisplay(fd, "  - decoder_count : 14");
        8 : $fdisplay(fd, "  - decoder_count : 16");
        9 : $fdisplay(fd, "  - decoder_count : 20");
        10: $fdisplay(fd, "  - decoder_count : 24");
        11: $fdisplay(fd, "  - decoder_count : 28");
        12: $fdisplay(fd, "  - decoder_count : 32");
      endcase
      $fdisplay(fd, "  - target_count : %0d", hdm_dec_cap.cap.target_cnt);
      $fdisplay(fd, "  - a11to8_ilv_cap  : %0b", hdm_dec_cap.cap.a11to8_ilv_cap);
      $fdisplay(fd, "  - a14to12_ilv_cap : %0b", hdm_dec_cap.cap.a14to12_ilv_cap);
      $fdisplay(fd, "  - poison_on_dec_err_cap : %0b", hdm_dec_cap.cap.poison_on_dec_err_cap);
      $fdisplay(fd, "  - way3_6_12_ilv_cap : %0b", hdm_dec_cap.cap.way3_6_12_ilv_cap);
      $fdisplay(fd, "  - way16_ilv_cap : %0b", hdm_dec_cap.cap.way16_ilv_cap);
      $fdisplay(fd, "  - uio_cap : %0b", hdm_dec_cap.cap.uio_cap);
      case (hdm_dec_cap.cap.uio_decoder_cnt)
        0 : $fdisplay(fd, "  - uio_decoder_count : 1");
        1 : $fdisplay(fd, "  - uio_decoder_count : 2");
        2 : $fdisplay(fd, "  - uio_decoder_count : 4");
        3 : $fdisplay(fd, "  - uio_decoder_count : 6");
        4 : $fdisplay(fd, "  - uio_decoder_count : 8");
        5 : $fdisplay(fd, "  - uio_decoder_count : 10");
        6 : $fdisplay(fd, "  - uio_decoder_count : 12");
        7 : $fdisplay(fd, "  - uio_decoder_count : 14");
        8 : $fdisplay(fd, "  - uio_decoder_count : 16");
        9 : $fdisplay(fd, "  - uio_decoder_count : 20");
        10: $fdisplay(fd, "  - uio_decoder_count : 24");
        11: $fdisplay(fd, "  - uio_decoder_count : 28");
        12: $fdisplay(fd, "  - uio_decoder_count : 32");
      endcase
      $fdisplay(fd, "  - memdata_nxm_cap : %0b", hdm_dec_cap.cap.memdata_nxm_cap);
      case (hdm_dec_cap.cap.coherency_model_supp)
        2'b00 : $fdisplay(fd, "  - coherency_model_supp : Unknown");
        2'b01 : $fdisplay(fd, "  - coherency_model_supp : Device Coherent (HDM-D or HDM-DB)");
        2'b10 : $fdisplay(fd, "  - coherency_model_supp : Host-Only Coherent (HDM-H)");
        2'b11 : $fdisplay(fd, "  - coherency_model_supp : Host-Only (HDM-H) or Device Coherent (HDM-D or HDM-DB)");
      endcase
    end
    if (emd_cap.en) begin
      $fdisplay(fd, "  // Ext. Metadata Capability");
      $fdisplay(fd, "  - max_size_emd : %0d", emd_cap.cap.max_nbits_emd);
      $fdisplay(fd, "  - emd_err_log_supp : %0b", emd_cap.cap.emd_err_log_supp);
    end
  endfunction

  // We will just overwrite all the fields that we have configured, not taking 
  // into account default values. There is no methodology for RdModWr.
  virtual function void create_cdo(int fd, int ctrlr);
    bit [31:0] d;
    // Cache-relevant details
    // DVSEC_CXL_CAP: Mandatory=[D1, D2, LD, FMLD], else Not Permitted
    if (dvsec_cxl_cap.en) begin
      d = `GET_DFAULT_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_DVSEC_HDR_2_FLEXBUS_CAP_OFF)
      d[21:20] = dvsec_cxl_cap.cxl_cap.hdm_count;
      d[18]    = dvsec_cxl_cap.cxl_cap.mem_cap;
      d[16]    = dvsec_cxl_cap.cxl_cap.cache_cap;
      `CDO_SET_ALL_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_DVSEC_HDR_2_FLEXBUS_CAP_OFF, d)
      // --- 
      d = `GET_DFAULT_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEX_BUS_LOCK_OFF)
      d[31:24] = dvsec_cxl_cap.cxl_cap2.cache_size;
      d[19:16] = dvsec_cxl_cap.cxl_cap2.cache_size_unit;
      `CDO_SET_ALL_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEX_BUS_LOCK_OFF, d)
      // ---  
      `CDO_SET_ALL_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_HIGH_OFF, dvsec_cxl_cap.hdm_range[1].hi)
      // ---  
      d = `GET_DFAULT_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_LOW_OFF)
      d[31:28] = dvsec_cxl_cap.hdm_range[1].lo;
      d[   16] = dvsec_cxl_cap.hdm_range[1].mem_active_degr;
      d[15:13] = int'($log10(int'(dvsec_cxl_cap.hdm_range[1].mem_active_timeout))/$log10(4)); //log4
      case (1'b1)
        dvsec_cxl_cap.hdm_range[1].des_ileave==0     : d[12:8] = 5'h0;
        dvsec_cxl_cap.hdm_range[1].des_ileave==256   : d[12:8] = 5'h1;
        dvsec_cxl_cap.hdm_range[1].des_ileave==4096  : d[12:8] = 5'h2;
        dvsec_cxl_cap.hdm_range[1].des_ileave==512   : d[12:8] = 5'h3;
        dvsec_cxl_cap.hdm_range[1].des_ileave==1024  : d[12:8] = 5'h4;
        dvsec_cxl_cap.hdm_range[1].des_ileave==2048  : d[12:8] = 5'h5;
        dvsec_cxl_cap.hdm_range[1].des_ileave==8192  : d[12:8] = 5'h6;
        dvsec_cxl_cap.hdm_range[1].des_ileave==16384 : d[12:8] = 5'h7;
      endcase
      d[ 7: 5] = dvsec_cxl_cap.hdm_range[1].memory_class;
      d[ 4: 2] = dvsec_cxl_cap.hdm_range[1].media_type;
      d[    1] = dvsec_cxl_cap.hdm_range[1].mem_active;
      d[    0] = dvsec_cxl_cap.hdm_range[1].mem_info_valid;
      `CDO_SET_ALL_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R1_SIZE_LOW_OFF, d)
      if (dvsec_cxl_cap.cxl_cap.hdm_count == 2) begin
        `CDO_SET_ALL_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_HIGH_OFF, dvsec_cxl_cap.hdm_range[2].hi)
        // ---  
        d = `GET_DFAULT_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_LOW_OFF)
        d[31:28] = dvsec_cxl_cap.hdm_range[2].lo;
        d[   16] = dvsec_cxl_cap.hdm_range[2].mem_active_degr;
        d[15:13] = int'($log10(int'(dvsec_cxl_cap.hdm_range[2].mem_active_timeout))/$log10(4)); //log4
        case (1'b1)
          dvsec_cxl_cap.hdm_range[2].des_ileave==0     : d[12:8] = 5'h0;
          dvsec_cxl_cap.hdm_range[2].des_ileave==256   : d[12:8] = 5'h1;
          dvsec_cxl_cap.hdm_range[2].des_ileave==4096  : d[12:8] = 5'h2;
          dvsec_cxl_cap.hdm_range[2].des_ileave==512   : d[12:8] = 5'h3;
          dvsec_cxl_cap.hdm_range[2].des_ileave==1024  : d[12:8] = 5'h4;
          dvsec_cxl_cap.hdm_range[2].des_ileave==2048  : d[12:8] = 5'h5;
          dvsec_cxl_cap.hdm_range[2].des_ileave==8192  : d[12:8] = 5'h6;
          dvsec_cxl_cap.hdm_range[2].des_ileave==16384 : d[12:8] = 5'h7;
        endcase
        d[ 7: 5] = dvsec_cxl_cap.hdm_range[2].memory_class;
        d[ 4: 2] = dvsec_cxl_cap.hdm_range[2].media_type;
        d[    1] = dvsec_cxl_cap.hdm_range[2].mem_active;
        d[    0] = dvsec_cxl_cap.hdm_range[2].mem_info_valid;
        `CDO_SET_ALL_C(PF0_CXL_DEVICE_CAP_CXL_RCIEP_FLEXBUS_R2_SIZE_LOW_OFF, d)
      end
    end
  endfunction

  typedef logic [31:0] dw_array_t[]; 

  // Return the entire capability structure
  function dw_array_t get_capability_structure(string name);
    logic [31:0] dw_array[$];  
    case (name)
      "HDM_DEC" : begin
                    dw_array = '{hdm_dec_cap.cap, 
                                 hdm_dec_cap.global_ctrl,
                                 32'h0,
                                 32'h0};
                    foreach (hdm_dec_cap.decoder[ii]) begin
                      dw_array.push_back(hdm_dec_cap.decoder[ii].base.low);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].base.high);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].size.low);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].size.high);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].control);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].opt[31: 0]);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].opt[63:32]);
                      dw_array.push_back(hdm_dec_cap.decoder[ii].rsvd);
                    end
                  end
      "EMD"     : begin
                    dw_array = '{emd_cap.cap,
                                 emd_cap.ctrl};
                  end
              
      default : `uvm_error(get_type_name, $sformatf("Invalid argument '%0s'",name))
    endcase
    return dw_array;
  endfunction

endclass
