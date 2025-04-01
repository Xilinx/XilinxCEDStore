// This include file requires device type to be defined. Valid values are "C_DEVICE_LEGACY" = older than CPM5N, or, "C_DEVICE_CPM5N" = CPM5N.

`ifndef PCIE_APP_USCALE_BMD_H
`define PCIE_APP_USCALE_BMD_H

`define PCI_EXP_EP_OUI                          24'h000A35
`define PCI_EXP_EP_DSN_1                        {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                        32'h10EE0001
`define MSI_INTR                                1

`define C_DEVICE_LEGACY

`ifdef C_DEVICE_LEGACY
`include "pcie_intf_defs_legacy.vh"
`endif // C_DEVICE_LEGACY

`ifdef C_DEVICE_CPM5N
`include "pcie_intf_defs_cpm5n.vh"
`endif // C_DEVICE_CPM5N

`define BMDREG(clk, reset_n, q, d, rstval)  \
   always_ff @(posedge clk) begin \
      if (~reset_n) \
         q  <= #(TCQ)   rstval;  \
      else  \
         q  <= #(TCQ)   d; \
   end

`define AS_BMDREG(clk, reset_n, q, d, rstval)  \
   always_ff @(posedge clk or negedge reset_n) begin \
      if (~reset_n) \
         q  <= #(TCQ)   rstval;  \
      else  \
         q  <= #(TCQ)   d; \
   end

`else    // PCIE_APP_USCALE_BMD_H
`endif   // PCIE_APP_USCALE_BMD_H
