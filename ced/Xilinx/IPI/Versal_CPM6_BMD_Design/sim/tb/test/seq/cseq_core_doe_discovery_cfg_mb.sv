class cseq_core_doe_discovery_cfg_mb extends cseq_cpm6_pcie_core_isr_src;

  `uvm_object_utils(cseq_core_doe_discovery_cfg_mb)

  logic [31:0] doe_data[$];
  logic [31:0] doe_data_rd[$];
  logic [17:0] doe_rd_ptr;
  logic [17:0] doe_length;
  logic        doe_busy;
  logic        doe_ready;

  function new(string name = "cseq_core_doe_discovery_cfg_mb");
    super.new(name);
  
    doe_length = '0;
    doe_ready  = '0;
    doe_busy   = '0;
  endfunction

  virtual function void set_ctrlr(bit c);
    super.set_ctrlr(c);
    bit_trigger = 'hC;
    reg_trigger = IR_STATUS;
    irqs.delete(PCIE_ERR_STATUS);
    irqs.delete(MISC_EVENT0_STATUS);
    irqs.delete(MISC_EVENT1_STATUS);
  endfunction

  virtual task generate_response(output bit err);
    err = 0;
    //Generate DOE Discovery response
    doe_data_rd.delete();
  
    foreach (doe_data[i]) begin
      `uvm_info(get_type_name, $sformatf("doe_data[%0d] = 0x%08h", i, doe_data[i]), UVM_LOW)
    end

    if (doe_data[0] == 32'h00000001) begin
      doe_data_rd.push_back(32'h00000001); //DOE Discovery
      if (doe_data[2][7:0] == 8'h00) begin
        //At index 0 is DOE Discovery and have another index at 1
        doe_data_rd.push_back(32'h00000003);
        doe_data_rd.push_back(32'h01000001);
      end else if (doe_data[2][7:0] == 8'h01) begin
        //At index 1 is SPDM and have another index at 2
        doe_data_rd.push_back(32'h00000003);
        doe_data_rd.push_back(32'h02010001);
        // doe_data_rd.push_back(32'h00000200);
      end else if (doe_data[2][7:0] == 8'h02) begin
        //At index 2 is Secure SPDM and have no other index
        doe_data_rd.push_back(32'h00000003);
        doe_data_rd.push_back(32'h00020001);
        // doe_data_rd.push_back(32'h00000200);
      end else begin
        doe_data_rd.push_back(32'h00000003);
        doe_data_rd.push_back(32'h0000FFFF);
      end

    end else begin
      err = 1;
    end
  endtask

  task parse_mailbox(output bit [3:0] txn_type, output bit [11:0] addr, output bit [7:0] wrbe, output bit [31:0] data);
    bit [31:0] rd_data;

    axi_rd('hFC840400+(ctrlr*'h10_0000), rd_data);
    txn_type = rd_data[3:0];
    wrbe     = rd_data[23:16];

    axi_rd('hFC840404+(ctrlr*'h10_0000), rd_data);
    addr = rd_data[11:0];

    if (wrbe[7:4] == 'hF) begin
      axi_rd('hFC84040C+(ctrlr*'h10_0000), rd_data);
    end else begin
      axi_rd('hFC840408+(ctrlr*'h10_0000), rd_data);
    end

    data = rd_data;

    `uvm_info(get_type_name, $sformatf("Parsed mailbox: type=%0h, addr=0x%0h, wrbe=0x%0h", 
              txn_type, addr, wrbe), UVM_LOW)
  endtask

  virtual task do_action();
    bit [31:0] rd_data;
    bit [7:0]  wrbe;
    bit [11:0] addr;
    bit [31:0] data;
    bit [3:0]  txn_type;
    bit [31:0] rd_data;
    bit        err;

    if (irqs[IR_STATUS].sts[3]) begin //CFG MB Wr
      parse_mailbox(txn_type, addr, wrbe, data);
      if (txn_type == 4'h2) begin
        axi_wr('hFC840018+(ctrlr*'h10_0000), (1'b1<<3));
        axi_wr('hFC84000C+(ctrlr*'h10_0000), (1'b1<<3));

        case (addr)
          'hD20: begin
            `uvm_info(get_type_name, "Write to ext cap header", UVM_LOW)
            //No writable bits in this register
          end
          'hD24: begin
            `uvm_info(get_type_name, "Write to cap register", UVM_LOW)
            //No writable bits in this register
          end
          'hD28: begin
            `uvm_info(get_type_name, "Write to control register", UVM_LOW)
            if (data[0]) begin //DOE Abort issued
              doe_data.delete();
              doe_busy   = 0;
              doe_ready  = 0;
              doe_rd_ptr = 0;
              `uvm_info(get_type_name, "DOE Abort issued, resetting state", UVM_LOW)
            end else begin
              if (data[31]) begin
                `uvm_info(get_type_name, "DOE Go bit set", UVM_LOW)
                doe_busy   = 1;
                doe_rd_ptr = 0;
                doe_ready  = 0;
                fork
                  begin
                    // #(1us);
                    generate_response(err);
                    if (err)
                      `uvm_error(get_type_name, $sformatf("Unknown DOE protocol detected: %0h", doe_data[0]))
                    doe_ready = 1;
                    doe_data.delete();
                    doe_busy = 0;
                  end
                join_none
              end

              if (data[1]) begin
                `uvm_info(get_type_name, "DOE Interrupt enabled not supported", UVM_LOW)
              end

              if (data[2]) begin
                `uvm_info(get_type_name, "DOE Attention mechanism not supported", UVM_LOW)
              end

              if (data[3]) begin
                `uvm_info(get_type_name, "DOE async messages not supported", UVM_LOW)
              end
            end
          end
          'hD2C: begin
            `uvm_info(get_type_name, "Write to status register", UVM_LOW)
            if (data[1]) begin
              `uvm_info(get_type_name, "DOE Interrupt enabled not supported", UVM_LOW)
            end
          end
          'hD30: begin
            `uvm_info(get_type_name, "Write to wr mb register", UVM_LOW)
            doe_data.push_back(data);
          end
          'hD34: begin
            `uvm_info(get_type_name, "Write to rd mb register", UVM_LOW)
            if (doe_ready) begin
              doe_rd_ptr++;
            end
          end
          default: begin
            `uvm_info(get_type_name, $sformatf("Unhandled addr: %0h", addr), UVM_LOW)
          end
        endcase

        axi_wr('hFC84041C+(ctrlr*'h10_0000), 'h1);
        axi_wr('hFC840014+(ctrlr*'h10_0000), (1'b1<<3));
        axi_wr('hFC84000C+(ctrlr*'h10_0000), (1'b1<<3));
        axi_wr('hFCDD0300, (1'b1<<(2 + ctrlr*6)));
      end else begin
        `uvm_error(get_type_name, $sformatf("Unknown mailbox transaction type: %0h", txn_type))
      end
    end

    if (irqs[IR_STATUS].sts[2]) begin
      parse_mailbox(txn_type, addr, wrbe, data);
      if (txn_type == 4'h1) begin
        axi_wr('hFC840018+(ctrlr*'h10_0000), (1'b1<<2));
        axi_wr('hFC84000C+(ctrlr*'h10_0000), (1'b1<<2));

        case (addr)
          'hD20: begin
            `uvm_info(get_type_name, "read to ext cap header", UVM_LOW)
            // axi_wr('hFC840410, 'h0002002e);
            data = 'h0001002e;
          end
          'hD24: begin
            `uvm_info(get_type_name, "read to cap register", UVM_LOW)
            // axi_wr('hFC840414, 'h0);
            data = '0;
          end
          'hD28: begin
            `uvm_info(get_type_name, "read to control register", UVM_LOW)
            // axi_wr('hFC840410, 'h0);
            data = '0;
          end
          'hD2C: begin
            `uvm_info(get_type_name, "read to status register", UVM_LOW)
            //Busy, Interrupt Status, Error, Async Status, At Attention, RSVD, Ready 
            // axi_wr('hFC840414, {doe_ready, 26'h0, 1'b0, 1'b0, 1'b0, 1'b0, doe_busy});
            data = {doe_ready, 26'h0, 1'b0, 1'b0, 1'b0, 1'b0, doe_busy};
          end
          'hD30: begin
            `uvm_info(get_type_name, "read to wr mb register", UVM_LOW)
            // axi_wr('hFC840410, 'h0);
            data = '0;
          end
          'hD34: begin
            `uvm_info(get_type_name, "read to rd mb register", UVM_LOW)
            // axi_wr('hFC840414, doe_data_rd[doe_rd_ptr]);
            data = doe_data_rd[doe_rd_ptr];
          end
          default: begin
            `uvm_info(get_type_name, $sformatf("Unhandled addr: %0h", addr), UVM_LOW)
          end
        endcase

        if (addr[2]) begin
          axi_wr('hFC840414+(ctrlr*'h10_0000), data);
        end else begin
          axi_wr('hFC840410+(ctrlr*'h10_0000), data);
        end

        axi_wr('hFC84041C+(ctrlr*'h10_0000), 'h2);
        axi_wr('hFC840014+(ctrlr*'h10_0000), (1'b1<<2));
        axi_wr('hFC84000C+(ctrlr*'h10_0000), (1'b1<<2));
        axi_wr('hFCDD0300, (1'b1<<(1 + ctrlr*6)));
      end else begin
        `uvm_error(get_type_name, $sformatf("Unknown mailbox transaction type: %0h", txn_type))
      end
    end
  endtask
endclass