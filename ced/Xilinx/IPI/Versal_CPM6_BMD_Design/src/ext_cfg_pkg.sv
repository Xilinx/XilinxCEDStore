package ext_cfg_pkg;
// VSEC
//////////////////////////////////////////////////////////////////////////////
    // Offset of extended capability - first offset should be hD00
    localparam logic [11:0]          VSEC_BASE_ADDRESS      = 12'hD00;
    // Byte-length of the PCIe extended capability (including header regs)
    localparam logic [11:0]          VSEC_CAP_LENGTH        = 12'h010;
    // Terminate capability chain (h000) or address of next capability
    localparam logic [11:0]          VSEC_NEXT_CAP          = 12'hD10;
    // Defined by the vendor
    localparam logic [15:0]          PCIE_VSEC_ID           = 16'hBEEF;
    localparam logic [3:0]           PCIE_VSEC_REV          = 4'h0;

// TPH
//////////////////////////////////////////////////////////////////////////////
            // Offset of extended capability - first offset
    localparam logic [11:0]          TPH_BASE_ADDRESS       = 12'hD10;
    // Terminate capability chain (h000) or address of next capability
    localparam logic [11:0]          TPH_NEXT_CAP           = 12'h000;
    // Capability Register
        // Indicates maximum number of ST Table entries - encoded as N-1
        // Max 64 entries when table is located in TPH Capability Structure
    localparam logic [10:0]          ST_TABLE_SIZE          = 11'h007;
        // Indicates where (and if) the ST table is located.
        // 00 - Not Present
        // 01 - In TPH Capability Structure
        // 10 - In MSI-X Table
        // 11 - Reserved
    localparam logic [1:0]           ST_TABLE_LOC           = 2'b01;
        // Indicates function is capable of generating requests with TPH Prefix.
    localparam logic                 EXT_TPH_REQ_SUP        = 1'b1;
        // Indicates Device Specific Mode of operation is supported.
    localparam logic                 DEV_SPEC_MODE_SUP      = 1'b1;
        // Indicates Interrupt Vector Mode is supported.
    localparam logic                 INT_VEC_MODE_SUP       = 1'b1;
        // Indicates No ST Mode is supported. Must be set to 1
    localparam logic                 NO_ST_MODE_SUP         = 1'b1;
endpackage
