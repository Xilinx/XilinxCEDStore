// Vivado projects will set their incdir so that their actual proj_test_pkg
// can be found first before this empty one
`include "bmd_write_csr_if.sv"
`include "bmd_read_csr_if.sv"
`include "plstr_credit_if.sv"
`include "plstr_rx_if.sv"
`include "plstr_tx_if.sv"

package proj_test_pkg;

    // Avery VIP uses these values so we set ours to these so that
    // hardcoded time literals (e.g. 100us) actually resolves to that
    // time value in the VIP
    timeunit 1ps;
    timeprecision 1ps;

    import uvm_pkg::*;
    import pcie_cfg_pkg::*;
    import avery_pkg::*;
    import apci_pkg::*;
    import env_pkg::*;
    import test_pkg::*;	
    import shim_device_pkg::*;
    import shim_pkg::*;
    import shim_ecaps_pkg::*;
    import pcie_intf_pkg::*;
    import bmd_mem_pkg::*;

    // Config
    `include "config/bmd_cap_config.sv"
    `include "config/bmd_csr_config.sv"
    `include "config/bmd_test_config.sv"

    // Callbacks
    `include "callbacks/bmd_mem_callback.sv"
    `include "callbacks/bmd_ur_callback.sv"

    // Sequence Items
    `include "sequences/items/rx_str_transaction.sv"
    `include "sequences/items/tx_str_transaction.sv"

    // Sequences
        // Base
    `include "sequences/bmd_base_sequence.sv"
        // Capability
    `include "sequences/capability/bmd_10b_tag_config_seq.sv"
    `include "sequences/capability/bmd_ext_tag_config_seq.sv"
    `include "sequences/capability/bmd_intx_config_seq.sv"
    `include "sequences/capability/bmd_msi_config_seq.sv"
    `include "sequences/capability/bmd_msix_config_seq.sv"
    `include "sequences/capability/bmd_pasid_config_seq.sv"
    `include "sequences/capability/bmd_tph_config_seq.sv"
    `include "sequences/capability/bmd_vsec_config_seq.sv"
        // CSR
    `include "sequences/csr/bmd_byte_enable_config_seq.sv"
    `include "sequences/csr/bmd_int_vec_config_seq.sv"
    `include "sequences/csr/bmd_pasid_prefix_seq.sv"
    `include "sequences/csr/bmd_read_tlp_format_seq.sv"
    `include "sequences/csr/bmd_reset_seq.sv"
    `include "sequences/csr/bmd_start_traffic_seq.sv"
    `include "sequences/csr/bmd_tlp_type_config_seq.sv"
    `include "sequences/csr/bmd_tph_prefix_seq.sv"
    `include "sequences/csr/bmd_write_tlp_format_seq.sv"
        // Error
    `include "sequences/error/bmd_out_of_range_read_seq.sv"
        // Virtual
    `include "sequences/virtual/bmd_capability_config_vseq.sv"
    `include "sequences/virtual/bmd_startup_vseq.sv"
    `include "sequences/virtual/bmd_traffic_vseq.sv"

    // Monitors
    `include "monitors/plstr_rx_monitor.sv"
    `include "monitors/plstr_tx_monitor.sv"

    // Scoreboards
    `include "scoreboards/bmd_extended_config_scoreboard.sv"
    `include "scoreboards/bmd_interrupt_scoreboard.sv"
    `include "scoreboards/bmd_write_scoreboard.sv"
    `include "scoreboards/bmd_vdm_scoreboard.sv"
    `include "scoreboards/bmd_read_scoreboard.sv"
    `include "scoreboards/bmd_rx_scoreboard.sv"
    `include "scoreboards/bmd_tx_scoreboard.sv"
    `include "scoreboards/bmd_ur_scoreboard.sv"
    `include "scoreboards/bmd_pasid_scoreboard.sv"
    `include "scoreboards/bmd_tph_scoreboard.sv"
    `include "scoreboards/bmd_performance_scoreboard.sv"

    // Environment
    `include "env/bmd_env.sv"

    ///////////////////////////////////////
    // Tests
    ///////////////////////////////////////

    // Base
    `include "tests/base/test_bmd_ep.sv"
    `include "tests/base/test_bmd_base.sv"
    `include "tests/base/test_bmd.sv"

    // Extended
        // Capabilities
            // Interrupts
    `include "tests/ext/capabilities/interrupts/test_bmd_intx.sv"
    `include "tests/ext/capabilities/interrupts/test_bmd_msi.sv"
    `include "tests/ext/capabilities/interrupts/test_bmd_msix.sv"
            // Other
    `include "tests/ext/capabilities/other/test_bmd_ama.sv"
    `include "tests/ext/capabilities/other/test_bmd_vdm_w_data.sv"
    `include "tests/ext/capabilities/other/test_bmd_vdm.sv"
            // PL Extended Configuration
    `include "tests/ext/capabilities/pl_ext_cfg/test_bmd_vsec.sv"
            // Prefixes
    `include "tests/ext/capabilities/prefix/test_bmd_tph.sv"
    `include "tests/ext/capabilities/prefix/test_bmd_pasid.sv"
    `include "tests/ext/capabilities/prefix/test_bmd_pasid_tph.sv"
            // Tags
    `include "tests/ext/capabilities/tags/test_bmd_5b_tag.sv"
    `include "tests/ext/capabilities/tags/test_bmd_8b_tag.sv"
    `include "tests/ext/capabilities/tags/test_bmd_10b_tag.sv"
        // Error
    `include "tests/ext/error/test_bmd_inject_bad_data.sv"
    `include "tests/ext/error/test_bmd_larger_than_mps.sv"
    `include "tests/ext/error/test_bmd_read_out_of_range.sv"
    `include "tests/ext/error/test_bmd_send_ur.sv"
        // Traffic
            // Byte Enable
    `include "tests/ext/traffic/be/test_bmd_all_zero_byte_enables.sv"
    `include "tests/ext/traffic/be/test_bmd_striped_byte_enables.sv"
            // Other
            // Read
    `include "tests/ext/traffic/rd/test_bmd_read_min_size_min_count.sv"
    `include "tests/ext/traffic/rd/test_bmd_read_min_size_max_count.sv"
    `include "tests/ext/traffic/rd/test_bmd_read_max_size_min_count.sv"
    `include "tests/ext/traffic/rd/test_bmd_read_max_size_max_count.sv"
            // Write
    `include "tests/ext/traffic/wr/test_bmd_write_min_size_min_count.sv"
    `include "tests/ext/traffic/wr/test_bmd_write_min_size_max_count.sv"
    `include "tests/ext/traffic/wr/test_bmd_write_max_size_min_count.sv"
    `include "tests/ext/traffic/wr/test_bmd_write_max_size_max_count.sv"
            // Custom
    `include "tests/ext/traffic/other/test_bmd_custom_perf.sv"

endpackage

