// qdma_periph_txn.sv — UVM transaction for the QDMA periphery monitor
//
// Captures AXI handshake events on s_axi_mem, s_axi_reg, m_axil_dbi
// and MSI-X sideband handshakes at the cpm6_qdma boundary.
class qdma_periph_txn extends uvm_sequence_item;

   `uvm_object_utils(qdma_periph_txn)

   typedef enum logic [3:0] {
      // s_axi_mem events
      MEM_AW,        // Write address handshake
      MEM_W,         // Write beat (wvalid & wready)
      MEM_B,         // Write response
      MEM_AR,        // Read address handshake
      MEM_R,         // Read last beat (rvalid & rready & rlast)
      // s_axi_reg events
      REG_WR,        // Write complete (bvalid & bready) — addr + wdata
      REG_RD,        // Read complete (rvalid & rready & rlast) — addr + rdata
      // m_axil_dbi events
      DBI_WR,        // Write address+data (awvalid & awready)
      DBI_B,         // Write response
      DBI_RD,        // Read address (arvalid & arready)
      DBI_R,         // Read response (rvalid & rready)
      // MSI-X events
      MSIX_REQ,      // msix_req rising edge
      MSIX_GRANT,    // msix_grant rising edge
      MSIX_ERROR,    // msix_error rising edge
      // tm_dsc_sts event
      TM_DSC_STS     // tm_dsc_sts_vld fire
   } qdma_periph_txn_type_e;

   qdma_periph_txn_type_e txn_type;

   // ---- AXI address/data fields (shared across event types) ----
   logic [63:0]  addr;
   logic [31:0]  data;       // wdata (REG_WR, DBI_WR) or rdata (REG_RD, DBI_R)
   logic [1:0]   id;         // MEM awid/arid/bid/rid (2-bit)
   logic [7:0]   len;        // burst length (MEM_AW, MEM_AR)
   logic [2:0]   size;       // burst size (MEM_AW, MEM_AR)
   logic [1:0]   resp;       // bresp/rresp
   longint unsigned bytes;   // MEM_AW/MEM_AR: (len+1)<<size burst estimate (AR has no
                             // per-strobe accuracy in AXI4); the WSTRB-accurate total
                             // for a completed write is in the MEM_AW_W log line instead

   // ---- MEM_W specific ----
   logic [7:0]   beat_idx;   // current beat index within burst (0-based)
   logic [7:0]   beat_total; // burst length (awlen+1)
   int unsigned  gap_cycles; // clock cycles since previous W beat on this interface

   // ---- MSIX fields ----
   logic [2:0]   msix_func;
   logic [7:0]   msix_vfunc;
   logic [10:0]  msix_vec;
   logic [1:0]   msix_op;

   // ---- Register decode (REG_WR) ----
   string        reg_decode; // human-readable decode of known register offsets

   // ---- DBI decode (DBI_WR, DBI_RD) ----
   string        dbi_decode; // human-readable channel+register decode

   // ---- tm_dsc_sts fields ----
   logic [12:0]  tm_qid;
   logic         tm_dir;
   logic [11:0]  tm_func;
   logic [15:0]  tm_pidx;
   logic [15:0]  tm_avl;
   logic [2:0]   tm_port_id;
   logic         tm_byp, tm_qen, tm_mm, tm_error, tm_qinv, tm_irq_arm;
   logic         tm_vio_dsc_crdt, tm_vio_en, tm_vio_hw_db, tm_vio_sw_db, tm_vio_avl_flg;

   // Simulation timestamp
   time          timestamp_ns;

   function new(string name = "qdma_periph_txn");
      super.new(name);
   endfunction

   virtual function void do_copy(uvm_object rhs);
      qdma_periph_txn t;
      super.do_copy(rhs);
      if (!$cast(t, rhs))
         `uvm_fatal("qdma_periph_txn", "do_copy: cast failed")
      txn_type     = t.txn_type;
      addr         = t.addr;
      data         = t.data;
      id           = t.id;
      len          = t.len;
      size         = t.size;
      resp         = t.resp;
      bytes        = t.bytes;
      beat_idx     = t.beat_idx;
      beat_total   = t.beat_total;
      gap_cycles   = t.gap_cycles;
      msix_func    = t.msix_func;
      msix_vfunc   = t.msix_vfunc;
      msix_vec     = t.msix_vec;
      msix_op      = t.msix_op;
      reg_decode   = t.reg_decode;
      dbi_decode   = t.dbi_decode;
      tm_qid       = t.tm_qid;
      tm_dir       = t.tm_dir;
      tm_func      = t.tm_func;
      tm_pidx      = t.tm_pidx;
      tm_avl       = t.tm_avl;
      tm_port_id   = t.tm_port_id;
      tm_byp       = t.tm_byp;
      tm_qen       = t.tm_qen;
      tm_mm        = t.tm_mm;
      tm_error     = t.tm_error;
      tm_qinv      = t.tm_qinv;
      tm_irq_arm   = t.tm_irq_arm;
      tm_vio_dsc_crdt = t.tm_vio_dsc_crdt;
      tm_vio_en       = t.tm_vio_en;
      tm_vio_hw_db    = t.tm_vio_hw_db;
      tm_vio_sw_db    = t.tm_vio_sw_db;
      tm_vio_avl_flg  = t.tm_vio_avl_flg;
      timestamp_ns = t.timestamp_ns;
   endfunction

   virtual function string convert2string();
      string s;
      s = $sformatf("[%0t ns] QPER %s", timestamp_ns, txn_type.name());
      case (txn_type)
         MEM_AW:
            s = {s, $sformatf(" addr=0x%016h id=0x%01h len=%0d sz=%0d bytes_est=%0d",
                 addr, id, len, size, bytes)};
         MEM_W:
            s = {s, $sformatf(" beat=%0d/%0d gap=%0d",
                 beat_idx, beat_total, gap_cycles)};
         MEM_B:
            s = {s, $sformatf(" bid=0x%01h resp=%0d", id, resp)};
         MEM_AR:
            s = {s, $sformatf(" addr=0x%016h id=0x%01h len=%0d sz=%0d bytes_est=%0d",
                 addr, id, len, size, bytes)};
         MEM_R:
            s = {s, $sformatf(" rid=0x%01h resp=%0d", id, resp)};
         REG_WR:
            s = {s, $sformatf(" addr=0x%011h wdata=0x%08h resp=%0d%s",
                 addr, data, resp, (reg_decode != "") ? {" ", reg_decode} : "")};
         REG_RD:
            s = {s, $sformatf(" addr=0x%011h rdata=0x%08h resp=%0d",
                 addr, data, resp)};
         DBI_WR:
            s = {s, $sformatf(" addr=0x%08h wdata=0x%08h%s", addr, data,
                 (dbi_decode != "") ? {" ", dbi_decode} : "")};
         DBI_B:
            s = {s, $sformatf(" resp=%0d", resp)};
         DBI_RD:
            s = {s, $sformatf(" addr=0x%08h%s", addr,
                 (dbi_decode != "") ? {" ", dbi_decode} : "")};
         DBI_R:
            s = {s, $sformatf(" rdata=0x%08h resp=%0d", data, resp)};
         MSIX_REQ:
            s = {s, $sformatf(" func=%0d vfunc=%0d vec=%0d op=%0d",
                 msix_func, msix_vfunc, msix_vec, msix_op)};
         MSIX_GRANT:
            s = {s, $sformatf(" granted  func=%0d vfunc=%0d vec=%0d",
                 msix_func, msix_vfunc, msix_vec)};
         MSIX_ERROR:
            s = {s, $sformatf(" error  func=%0d vfunc=%0d vec=%0d",
                 msix_func, msix_vfunc, msix_vec)};
         TM_DSC_STS:
            s = {s, $sformatf(
                 {" qid=%0d dir=%s func=%0d pidx=%0d avl=%0d port_id=%0d byp=%0b qen=%0b mm=%0b",
                  " error=%0b qinv=%0b irq_arm=%0b vio_dsc_crdt=%0b vio_en=%0b vio_hw_db=%0b",
                  " vio_sw_db=%0b vio_avl_flg=%0b"},
                 tm_qid, tm_dir ? "C2H" : "H2C", tm_func, tm_pidx, tm_avl, tm_port_id,
                 tm_byp, tm_qen, tm_mm, tm_error, tm_qinv, tm_irq_arm,
                 tm_vio_dsc_crdt, tm_vio_en, tm_vio_hw_db, tm_vio_sw_db, tm_vio_avl_flg)};
      endcase
      return s;
   endfunction

endclass
