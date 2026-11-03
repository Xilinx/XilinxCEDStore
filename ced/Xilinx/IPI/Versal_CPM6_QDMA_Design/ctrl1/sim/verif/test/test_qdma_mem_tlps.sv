// test_qdma_mem_tlps.sv -- PCIe memory TLP write/read check on the QDMA
// register space. Each pattern is written to the QDMA global scratch register
// (PF0 BAR1 + 0x244, a 32-bit read/write register with no side effects) with a
// memory-write TLP, read back with a blocking memory-read TLP, and compared.
//
// Extends this design's DMA test to reuse its DUT and PCIe link setup;
// main_phase runs enumeration and the base-test setup only, with no DMA.

class test_qdma_mem_tlps extends test_qdma_h2c_c2h_mm_Mfnc_MQ;

  `uvm_component_utils(test_qdma_mem_tlps)

  localparam bit [31:0] SCRATCH_OFFSET = 32'h244;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual task main_phase(uvm_phase phase);
    bit [31:0] patterns[$] = '{32'h0000_0000, 32'hFFFF_FFFF, 32'hA5A5_A5A5,
                               32'h5A5A_5A5A, 32'h1F00_2F00};
    bit [31:0] rd_data;
    int        mismatches = 0;

    qdma_base_test::main_phase(phase);
    phase.raise_objection(this);

    foreach (patterns[i]) begin
      issue_reg_write(PF_DMA_BAR_INDEX, SCRATCH_OFFSET, patterns[i]);
      issue_reg_read(PF_DMA_BAR_INDEX, SCRATCH_OFFSET, .data(rd_data));
      if (rd_data !== patterns[i]) begin
        mismatches++;
        `uvm_error(get_type_name(), $sformatf(
          "BAR%0d+0x%0h: read 0x%08h, wrote 0x%08h",
          PF_DMA_BAR_INDEX, SCRATCH_OFFSET, rd_data, patterns[i]))
      end else begin
        `uvm_info(get_type_name(), $sformatf(
          "BAR%0d+0x%0h: wrote and read 0x%08h",
          PF_DMA_BAR_INDEX, SCRATCH_OFFSET, rd_data), UVM_NONE)
      end
    end

    if (mismatches == 0)
      `uvm_info(get_type_name(), $sformatf(
        "*** TEST PASSED *** %0d write/read pairs matched", patterns.size()), UVM_NONE)

    phase.drop_objection(this);
  endtask

endclass
