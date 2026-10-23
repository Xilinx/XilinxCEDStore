// DESCRIPTION
// This sequence is designed to parse an EP's BARs - it is assumed  
// after enumeration - and build the results into an easily readable
// format: an associative array.
class seq_ep_get_bars extends vseq_in_order;

  `uvm_object_utils(seq_ep_get_bars)

  // Knobs to set before calling 'start'
  logic [15:0] dst_bdf;
  bit          print = 1;

  // Summary
  typedef struct {
    bit        is_64;  
    bit        is_pftch;
    string     sz_str;
    bit [63:0] sz;
    bit [63:0] base;
  } mem_bar_s;
  
  typedef struct {
    string     sz_str;
    bit [31:0] sz;
    bit [31:0] base;
  } io_bar_s;

  mem_bar_s membar[bit [2:0]];
  io_bar_s  iobar [bit [2:0]];

  function new(string name = "seq_ep_get_bars");
    super.new(name);
  endfunction

  // Fill the queue
  virtual task pre_body(); 
    amd_cfg_tlp tlp;
    if (dst_bdf==='x)
      `uvm_fatal(get_type_name, "dst_bdf member must be set before running sequence")
    // Start fresh
    membar.delete;
    iobar.delete;
    // Read each BAR successively for reprogramming later
    for (bit [2:0] bar=0; bar<6; bar++) begin
      tlp = amd_cfg_tlp::type_id::create("tlp");
      tlp.build_rd('h10+'h4*bar, .bdf(dst_bdf));
      add_txn(tlp);
    end
  endtask

  virtual task body();
    bit         upper;
    bit [63:0]  bar_reg; 
    amd_cfg_tlp tlp;
    // Read all 6 BARs first
    super.body();
    // Set txn constant 
    tlp = amd_cfg_tlp::type_id::create("tlp");
    tlp.dst_bdf = dst_bdf;
    // Write then readback each BAR successively
    for (bit [2:0] bar=0; bar<6; bar++) begin
      if (!upper) bar_reg = '0;
      tlp.build_wr('h10+'h4*bar, '1);
      p_sequencer.api.send_cfg(tlp);
      tlp.rd = 1;
      p_sequencer.api.send_cfg(tlp);
      if (upper) bar_reg[63:32] = tlp.payload[0];
      else       bar_reg[31: 0] = tlp.payload[0];
      // 64b Memory BAR detected
      if (!upper && bar_reg[2:0]=='b100)
        upper = 1;  
      else if (upper || (!upper && (|bar_reg[31:0]))) begin
        // Memory BAR
        if (upper || (!upper && !bar_reg[0])) begin
          parse_mem_bar(bar_reg, upper, (upper ? bar-1 : bar));
          upper = 0;
        end
        // IO BAR
        else 
          parse_io_bar(bar_reg[31:0], bar);
      end
    end
    // Change each original BAR read to a write
    foreach (q[ii]) begin
      $cast(tlp, q[ii]);
      tlp.rd = 0; 
    end
    // Re-run the programming to restore
    super.body();
  endtask

  virtual task post_body();
    if (print) begin
      if (membar.size) begin
        `uvm_info(get_type_name, $sformatf("BDF 0x%h : Printing %0d memory BARs", dst_bdf, membar.size), UVM_LOW)
        foreach (membar[ii])
          `uvm_info(get_type_name, $sformatf("  - BAR[%0d] | is_64=%0b, prefetchable=%0b, size=%0s, base=0x%0h", ii, membar[ii].is_64, membar[ii].is_pftch, membar[ii].sz_str, membar[ii].base), UVM_LOW)
      end
      if (iobar.size) begin
        `uvm_info(get_type_name, $sformatf("BDF 0x%h : Printing %0d IO BARs", dst_bdf, iobar.size), UVM_LOW)
        foreach (iobar[ii])
          `uvm_info(get_type_name, $sformatf("  - BAR[%0d] | size=%0s, base=0x%0h", ii, iobar[ii].sz_str, iobar[ii].base), UVM_LOW)
      end
      if (!membar.size && !iobar.size)
        `uvm_info(get_type_name, $sformatf("BDF 0x%h has no BARs", dst_bdf), UVM_LOW)
    end
  endtask

  // --------------------------------
  // HELPER METHODS 
  // --------------------------------

  // MEM BARs can map any pow2 size 
  virtual function void parse_mem_bar(bit [63:0] bar, bit is_64, int idx);
    amd_cfg_tlp tlp;
    int         sz_num;
    string      sz_unit;
    bit [63:0]  masked_bar = bar & (~64'hF);
    // Get values
    membar[idx].is_64    = is_64;
    membar[idx].is_pftch = bar[3];
    membar[idx].sz       = ~masked_bar+1;
    if (is_64) begin 
      $cast(tlp, q[idx]);
      membar[idx].base[31: 0] = tlp.payload[0] & (~32'hF);
      $cast(tlp, q[idx+1]);
      membar[idx].base[63:32] = tlp.payload[0];
    end
    else begin
      $cast(tlp, q[idx]);
      membar[idx].base[31: 0] = tlp.payload[0] & (~32'hF);
    end
    // Build string
    for (int ii=0; ii<(is_64?64:32); ii++) begin
      case (ii) 
        0 : sz_unit = "B";
        10: sz_unit = "KiB";
        20: sz_unit = "MiB";
        30: sz_unit = "GiB";
        40: sz_unit = "TiB";
        50: sz_unit = "PiB";
        60: sz_unit = "EiB";
      endcase
      if (membar[idx].sz[ii]) begin
        case (1'b1)
          ii<10  : sz_num = 1<<ii; 
          ii<20  : sz_num = 1<<(ii-10); 
          ii<30  : sz_num = 1<<(ii-20); 
          ii<40  : sz_num = 1<<(ii-30); 
          ii<50  : sz_num = 1<<(ii-40); 
          ii<60  : sz_num = 1<<(ii-50); 
          default: sz_num = 1<<(ii-60);
        endcase
        break;
      end
    end
    membar[idx].sz_str = $sformatf("%0d%0s", sz_num, sz_unit);
  endfunction

  // Spec: IO BARs can map 16-256B only
  virtual function void parse_io_bar(bit [31:0] bar, int idx);
    amd_cfg_tlp tlp;
    int         sz_num;
    string      sz_unit;
    bit [31:0]  masked_bar = bar & (~32'h3);
    // Get values
    iobar[idx].sz   = ~masked_bar+1;
    $cast(tlp, q[idx]);
    iobar[idx].base = tlp.payload[0] & (~32'h3);
    // Build string
    for (int ii=0; ii<32; ii++) begin
      case (ii) 
        0 : sz_unit = "B";
        10: sz_unit = "KiB";
        20: sz_unit = "MiB";
        30: sz_unit = "GiB";
      endcase
      if (iobar[idx].sz[ii]) begin
        case (1'b1)
          ii<10  : sz_num = 1<<ii; 
          ii<20  : sz_num = 1<<(ii-10); 
          ii<30  : sz_num = 1<<(ii-20); 
          default: sz_num = 1<<(ii-30);
        endcase
        break;
      end
    end
    iobar[idx].sz_str = $sformatf("%0d%0s", sz_num, sz_unit);
  endfunction

endclass
