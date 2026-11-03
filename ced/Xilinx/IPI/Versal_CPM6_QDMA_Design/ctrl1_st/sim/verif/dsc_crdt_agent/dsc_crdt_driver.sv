// (c) Copyright 2026 Advanced Micro Devices, Inc. All rights reserved.
//
// dsc_crdt_driver.sv — UVM driver for DSC_CRDT handshake interface.
//
// Implements vld/rdy handshake:
//   1. Assert vld with qid, crdt, dir, fence
//   2. Wait for rdy (posedge clk where rdy=1)
//   3. Deassert vld
//   4. Log to cpm6_qdma_dbg.log with tag DCRD

`ifndef __DSC_CRDT_DRIVER__SV__
`define __DSC_CRDT_DRIVER__SV__

class dsc_crdt_driver extends uvm_driver#(dsc_crdt_seq_item);
   `uvm_component_utils(dsc_crdt_driver)

   virtual dsc_crdt_if vif;
   int log_fd;
   int rdy_timeout_cycles = 200000;  // max clk cycles to wait for rdy (~800us at 250MHz)

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual dsc_crdt_if)::get(this, "", "vif", vif))
         `uvm_fatal("dsc_crdt_driver", "Failed to get dsc_crdt_if from config_db")
      if (!uvm_config_db#(int)::get(this, "", "log_fd", log_fd))
         log_fd = 1;
      if (!uvm_config_db#(int)::get(this, "", "rdy_timeout_cycles", rdy_timeout_cycles))
         rdy_timeout_cycles = 10000;
   endfunction

   task run_phase(uvm_phase phase);
      dsc_crdt_seq_item txn;

      // Initialize to idle
      vif.drv_cb.vld   <= 1'b0;
      vif.drv_cb.qid   <= '0;
      vif.drv_cb.crdt  <= '0;
      vif.drv_cb.dir   <= 1'b0;
      vif.drv_cb.fence <= 1'b0;

      forever begin
         seq_item_port.get_next_item(txn);
         drive_credit(txn);
         seq_item_port.item_done();
      end
   endtask

   task drive_credit(dsc_crdt_seq_item txn);
      // Assert vld with transaction data
      @(vif.drv_cb);
      vif.drv_cb.vld   <= 1'b1;
      vif.drv_cb.qid   <= txn.qid;
      vif.drv_cb.crdt  <= txn.crdt;
      vif.drv_cb.dir   <= txn.dir;
      vif.drv_cb.fence <= txn.fence;

      // Wait for rdy handshake with timeout
      begin
         int wait_cnt = 0;
         @(vif.drv_cb);
         while (!vif.drv_cb.rdy) begin
            wait_cnt++;
            if (wait_cnt >= rdy_timeout_cycles) begin
               vif.drv_cb.vld <= 1'b0;
               $fdisplay(log_fd,
                  "%0t ns  [DCRD]  RDY_TIMEOUT  qid=%0d  crdt=%0d  dir=%s  waited=%0d cycles",
                  $realtime/1ns, txn.qid, txn.crdt, txn.dir ? "C2H" : "H2C", wait_cnt);
               $fflush(log_fd);
               `uvm_fatal("dsc_crdt_driver",
                  $sformatf("dsc_crdt rdy timeout after %0d cycles  -  qid=%0d crdt=%0d dir=%s. DUT never asserted rdy.",
                            wait_cnt, txn.qid, txn.crdt, txn.dir ? "C2H" : "H2C"))
            end
            @(vif.drv_cb);
         end
      end

      // Deassert vld after handshake
      vif.drv_cb.vld <= 1'b0;

      $fdisplay(log_fd,
         "%0t ns  [DCRD]  CREDIT  qid=%0d  crdt=%0d  dir=%s  fence=%0b",
         $realtime/1ns, txn.qid, txn.crdt, txn.dir ? "C2H" : "H2C", txn.fence);
      $fflush(log_fd);
   endtask

endclass : dsc_crdt_driver

`endif // __DSC_CRDT_DRIVER__SV__
