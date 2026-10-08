class ecap_pl_64gts extends ecap_base;

  `uvm_object_utils(ecap_pl_64gts)

  typedef enum {
    MAX_LINK_UNSPEC=0,
    MAX_LINK1=1, 
    MAX_LINK2=2, 
    MAX_LINK4=4, 
    MAX_LINK8=8, 
    MAX_LINK16=16
  } max_link_w_e;

  max_link_w_e max_link_width;

  // -------------------- 
  // Capability Registers
  // -------------------- 

  typedef struct packed {
    logic [31:0] rsvd31to0;
  } caps_64gts_s;

  typedef struct packed {
    logic [31:0] rsvd31to0;
  } ctrl_64gts_s;
  
  typedef struct packed {
    logic [23:0] rsvd31to8;
    logic        no_eq_needed;
    logic        tx_precoding_req;
    logic        tx_precoding_on;
    logic        link_eq_req_64gts;
    logic        eq_64gts_ph3_succ;
    logic        eq_64gts_ph2_succ;
    logic        eq_64gts_ph1_succ;
    logic        eq_64gts_complete;
  } stts_64gts_s;

  typedef struct packed {
    logic [3:0] usp_tx_preset;
    logic [3:0] dsp_tx_preset;
  } lane_eq_64gts_s;

  // -------------------- 
  // The capability's data: to read or write
  // -------------------- 

  // 3 ways to access the data
  // a) data.cap...   (referenced by name)
  // b) data.bytes[n] (a byte offset)
  // b) data.dws[n]   (a DW offset)
  union packed {
    logic [31:0][ 7:0] bytes;
    logic [ 7:0][31:0] dws;
    struct packed {
      lane_eq_64gts_s lane15_eq;
      lane_eq_64gts_s lane14_eq;
      lane_eq_64gts_s lane13_eq;
      lane_eq_64gts_s lane12_eq;
      lane_eq_64gts_s lane11_eq;
      lane_eq_64gts_s lane10_eq;
      lane_eq_64gts_s lane9_eq;
      lane_eq_64gts_s lane8_eq;
      lane_eq_64gts_s lane7_eq;
      lane_eq_64gts_s lane6_eq;
      lane_eq_64gts_s lane5_eq;
      lane_eq_64gts_s lane4_eq;
      lane_eq_64gts_s lane3_eq;
      lane_eq_64gts_s lane2_eq;
      lane_eq_64gts_s lane1_eq;
      lane_eq_64gts_s lane0_eq;
      stts_64gts_s    stts_64gts;
      ctrl_64gts_s    ctrl_64gts;
      caps_64gts_s    caps_64gts;
      ecap_hdr_s      hdr;
    } cap;
  } data;

  // -------------------- 
  // Each register field's attributes
  // -------------------- 
    
  struct { 
    struct {
      field_attr_t usp_tx_preset = {'h1F, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h1F, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane15_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h1E, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h1E, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane14_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h1D, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h1D, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane13_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h1C, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h1C, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane12_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h1B, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h1B, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane11_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h1A, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h1A, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane10_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h19, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h19, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane9_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h18, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h18, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane8_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h17, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h17, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane7_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h16, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h16, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane6_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h15, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h15, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane5_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h14, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h14, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane4_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h13, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h13, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane3_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h12, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h12, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane2_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h11, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h11, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane1_eq;
    // -- //
    struct {
      field_attr_t usp_tx_preset = {'h10, 7, 4, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t dsp_tx_preset = {'h10, 3, 0, ACC_HWINIT|ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } lane0_eq;
    // -- //
    struct {
      field_attr_t rsvd31to8         = {'hC, 31, 8, ACC_RSVDZ,           ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t no_eq_needed      = {'hC, 7,  7, ACC_RO,              ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t tx_precoding_req  = {'hC, 6,  6, ACC_RO,              ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t tx_precoding_on   = {'hC, 5,  5, ACC_RO,              ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t link_eq_req_64gts = {'hC, 4,  4, ACC_RW1CS|ACC_RSVDZ, ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t eq_64gts_ph3_succ = {'hC, 3,  3, ACC_ROS|ACC_RSVDZ,   ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t eq_64gts_ph2_succ = {'hC, 2,  2, ACC_ROS|ACC_RSVDZ,   ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t eq_64gts_ph1_succ = {'hC, 1,  1, ACC_ROS|ACC_RSVDZ,   ACC_UNSPEC, 'x, 'x, 'x};
      field_attr_t eq_64gts_complete = {'hC, 0,  0, ACC_ROS|ACC_RSVDZ,   ACC_UNSPEC, 'x, 'x, 'x};
    } stts_64gts;
    // -- //
    struct {
      field_attr_t rsvd31to0 = {'h8, 31, 0, ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } ctrl_64gts;
    // -- //
    struct {
      field_attr_t rsvd31to0 = {'h4, 31, 0, ACC_RSVDP, ACC_UNSPEC, 'x, 'x, 'x};
    } caps_64gts;
  } attrs; 

  function new(string name = "ecap_pl_64gts");
    super.new(name);
    cap_id = ECAP_PL_64GTS;
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

endclass
