// C = "controller", R = "register", O = "offset", F = "field"
// RA = "right align, CA = "center align", LA = "left align"
`define CDO_SET_BIT(C, R, O) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 rr.PCIE``C``_CFG.``R``.dfault | (1'b1 << O));
`define CDO_CLR_BIT(C, R, O) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 rr.PCIE``C``_CFG.``R``.dfault & ~(1'b1 << O));
// expects a 4 character BE with 'b prefix e.g. 4'b1111, 4'b1010
`define CDO_SET_BYTES(C, R, BE, F) \
   $fdisplay(fd, "mask_write 0x%h 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 { {8{1'(BE>>3)}}, {8{1'(BE>>2)}}, {8{1'(BE>>1)}}, {8{1'(BE>>0)}} }, \
                 F);
`define CDO_SET_BYTES_C(R, BE, F) \
   $fdisplay(fd, "mask_write 0x%h 0x%h 0x%h", \
                 !ctrlr ? rr.PCIE0_CFG.``R``.addr : rr.PCIE1_CFG.``R``.addr, \
                 { {8{1'(BE>>3)}}, {8{1'(BE>>2)}}, {8{1'(BE>>1)}}, {8{1'(BE>>0)}} }, \
                 F);
`define CDO_SET_FLD_RA(C, R, F) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 {rr.PCIE``C``_CFG.``R``.dfault[31:$bits(F)], F});
`define CDO_SET_FLD_CA(C, R, F, O) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 {rr.PCIE``C``_CFG.``R``.dfault[31:$bits(F)+O], F, rr.PCIE``C``_CFG.``R``.dfault[0+:O]});
`define CDO_SET_FLD_LA(C, R, F) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 {F, rr.PCIE``C``_CFG.``R``.dfault[31-$bits(F):0]});
`define CDO_SET_ALL(C, R, F) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 rr.PCIE``C``_CFG.``R``.addr, \
                 F);
`define CDO_SET_ALL_C(R, F) \
   $fdisplay(fd, "write 0x%h 0x%h", \
                 !ctrlr ? rr.PCIE0_CFG.``R``.addr : rr.PCIE1_CFG.``R``.addr, \
                 F);

`define GET_DFAULT(C, R) rr.PCIE``C``_CFG.``R``.dfault;
`define GET_DFAULT_C(R) !ctrlr ? rr.PCIE0_CFG.``R``.dfault : rr.PCIE1_CFG.``R``.dfault;

