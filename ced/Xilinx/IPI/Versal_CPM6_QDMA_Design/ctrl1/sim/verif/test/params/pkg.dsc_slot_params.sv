// pkg.dsc_slot_params.sv — HDMA descriptor-slot geometry constants
//
// A "slot" (as fetched/programmed by dsc_fetch_engine.sv) holds NUM_DE_PER_SLOT
// Data Elements plus NUM_LINK_PER_SLOT Link element(s) — 7 DEs + 1 LINK, per
// dsc_fetch_engine.sv's MAX_DSC_PER_SLOT. Each element is DSC_ELEMENT_BYTES.
//
// Used to decode a host-facing AXI address (cpm_noc0, cpm_axi_pl0/1/3) into
// the HDMA channel/slot index via addr / SLOT_SIZE_BYTES.
package dsc_slot_params_pkg;
   localparam NUM_DE_PER_SLOT   = 7;
   localparam NUM_LINK_PER_SLOT = 1;
   localparam DSC_ELEMENT_BYTES = 192;
   localparam SLOT_SIZE_BYTES   = (NUM_DE_PER_SLOT + NUM_LINK_PER_SLOT) * DSC_ELEMENT_BYTES;
endpackage
