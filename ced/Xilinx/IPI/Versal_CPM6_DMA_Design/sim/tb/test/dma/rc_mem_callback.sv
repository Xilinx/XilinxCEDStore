class rc_mem_callback extends apci_callbacks;
   logic [31:0] pattern;
   logic [31:0] exp_txfr_size;
   logic [31:0] act_txfr_size = 0;
   logic [63:0] rd_mem_data[int];
   logic [63:0] wr_mem_data[int];
   logic [63:0] wr_addr = 0;
   logic [63:0] rd_addr = 0;
   bit          inject_bad_data;
   logic [31:0] bad_data;
   logic [7:0]  bad_byte;
   bit 		int_msi_set = 0;
   bit 		int_msix_set = 0;
   
   
   apci_device bfm_handle;
   function new(apci_device bfm_handle, logic[31:0] pattern, logic[31:0] size);
      this.pattern = pattern;
      this.exp_txfr_size = size;
   endfunction // new
/*
   apci_device bfm_handle;
   function new(apci_device bfm_handle, logic[31:0] pattern);
      this.pattern = pattern;
   endfunction // new
*/
 /*   
   int injection_index;
    virtual function void read_mem_cb(
            input bit             is_host_mem,
            input bit[63:0]       addr       ,
            input bit[31:0]       ndw        ,
            input bit[3:0]        first_be   ,
            input bit[3:0]        last_be    ,
            ref   bit[31:0]       va[]       ,
            input avery_data_base src         );

        `uvm_info("RC_MEM", $psprintf("read me cb: ADDR %0h, NDW %0h, FBE %0h, LBE  %0h,",
        addr, ndw, first_be, last_be), UVM_LOW);
        injection_index = $urandom_range(0, ndw);
        for(int j=0; j <ndw; j++)
            if (j == injection_index && inject_bad_data) begin
                va[j] = bad_data;
            end else begin
//                va[j] = pattern;
                va[j] = pattern;
            end
        va[0][7:0]   = first_be[0] == 1'b1 ? va[0][7:0] : bad_byte;
        va[0][15:8]  = first_be[1] == 1'b1 ? va[0][15:8] : bad_byte;
        va[0][23:16] = first_be[2] == 1'b1 ? va[0][23:16] : bad_byte;
        va[0][31:24] = first_be[3] == 1'b1 ? va[0][31:24] : bad_byte;
        if (ndw > 1) begin
            va[ndw-1][7:0]   = last_be[0] == 1'b1 ? va[ndw-1][7:0] : bad_byte;
            va[ndw-1][15:8]  = last_be[1] == 1'b1 ? va[ndw-1][15:8] : bad_byte;
            va[ndw-1][23:16] = last_be[2] == 1'b1 ? va[ndw-1][23:16] : bad_byte;
            va[ndw-1][31:24] = last_be[3] == 1'b1 ? va[ndw-1][31:24] : bad_byte;
        end
    endfunction // read_mem_cb
 */  
   virtual function void read_mem_cb(
            input bit             is_host_mem,
            input bit[63:0]       addr       ,
            input bit[31:0]       ndw        ,
            input bit[3:0]        first_be   ,
            input bit[3:0]        last_be    ,
            ref   bit[31:0]       va[]       ,
            input avery_data_base src         );

      rd_addr = addr;
        `uvm_info("RC_MEM", $psprintf("read me cb: Data Read from Host ADDR %0h, NDW %0h, FBE %0h, LBE  %0h,", addr, ndw, first_be, last_be), UVM_LOW);
        for(int j=0; j <ndw; j++) begin
	   randomize(pattern);
	   rd_mem_data[rd_addr] = pattern;
           va[j] = rd_mem_data[rd_addr];
//           `uvm_info("RC_MEM", $psprintf("Data Read from Host ADDR %0h, data %0h", rd_addr, rd_mem_data[rd_addr]), UVM_LOW);
	   rd_addr = rd_addr+4;
	end
   endfunction // read_mem_cb

   virtual function void write_mem_cb(
            input bit             is_host_mem,
            input bit[63:0]       addr       ,
            input bit[3:0]        first_be   ,
            input bit[3:0]        last_be    ,
            ref   bit[31:0]       va[]       ,
            input avery_data_base src         );

      wr_addr= addr;
      `uvm_info("RC_MEM", $psprintf("Write mem cb: Data write to host %h, ADDR %0h, FBE %0h, LBE  %0h,", is_host_mem, addr, first_be, last_be), UVM_LOW);
      if (addr[63:56] == 8'hff) begin   // This is a MSI interrupt writes
	      int_msi_set = 1'b1;
	      `uvm_info("MSI Interrupt", $psprintf("Write mem cb: Int ADDR 0x%0h, Ind Data 0x%0h,", addr, va[0]), UVM_LOW);
      end
      else if (addr[63:52] == 12'hadd) begin   // This is a MSIX interrupt writes
	      int_msix_set = 1'b1;
	      `uvm_info("MSIX Interrupt", $psprintf("Write mem cb: Int ADDR 0x%0h, Ind Data 0x%0h,", addr, va[0]), UVM_LOW);
      end
      else begin
	      act_txfr_size =   (last_be == 4'hf) ? act_txfr_size +4 :
			                  (last_be == 4'h7) ? act_txfr_size +3 :
			                  (last_be == 4'h3) ? act_txfr_size +2 :
			                  (last_be == 4'h1) ? act_txfr_size +1 : act_txfr_size;
	 
	 for(int j=0; j < va.size; j++) begin
	    wr_mem_data[wr_addr] = va[j];
//           `uvm_info("RC_MEM", $psprintf("Data write to Host ADDR %0h, data %0h", wr_addr, wr_mem_data[wr_addr]), UVM_LOW);
	    case (last_be)
	      4'h1 : begin if (wr_mem_data[wr_addr][7:0] != rd_mem_data[wr_addr][7:0])
		`uvm_error("ERROR", $sformatf("Byte 0 Data does not match, expected data = 0x%h, got = 0x%h", rd_mem_data[wr_addr], wr_mem_data[wr_addr]));
	      end
	      
	      4'h3 : begin if (wr_mem_data[wr_addr][15:0] != rd_mem_data[wr_addr][15:0])
		`uvm_error("ERROR", $sformatf("Byte 1-0 Data does not match, expected data = 0x%h, got = 0x%h", rd_mem_data[wr_addr], wr_mem_data[wr_addr]));
	      end
	      
	      4'h7 : begin if (wr_mem_data[wr_addr][23:0] != rd_mem_data[wr_addr][23:0])
		`uvm_error("ERROR", $sformatf("Byte 2-1-0 Data does not match, expected data = 0x%h, got = 0x%h", rd_mem_data[wr_addr], wr_mem_data[wr_addr]));
	      end
	      
	      4'hF : begin if (wr_mem_data[wr_addr] != rd_mem_data[wr_addr])
		`uvm_error("ERROR", $sformatf("Data does not match, Addr = 0x%h, expected data = 0x%h, got = 0x%h", wr_addr, rd_mem_data[wr_addr], wr_mem_data[wr_addr]));
	      end
	      
	    endcase // case (last_be)
	    wr_addr = wr_addr + 4;  // word to bytes
	    bad_data = va[j];
	 end
      end // else: !if(addr[63:56] == 'hff)
   endfunction // write_mem_cb
      
endclass // rc_mem_callback
