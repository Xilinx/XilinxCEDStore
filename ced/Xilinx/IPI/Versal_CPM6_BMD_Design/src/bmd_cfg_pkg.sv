package bmd_cfg_pkg;

localparam int              NUM_VFS             = 64;
localparam int              NUM_PFS             = 8;

localparam logic [2:0]      FUNC_NUM            = 3'b000;
localparam logic [7:0]      VFUNC_NUM           = 8'b0000_0000;
localparam logic [2:0]      BAR_NUM             = 3'b000;
localparam logic            VFUNC_ACTIVE        = 1'b0;

// Bar Size in bytes
localparam int              BAR_SIZE            = 'h1000;

localparam logic            HDR_PROT_CHECK      = 1'b0;
localparam logic            CMP_PARITY_CHECK    = 1'b0;

localparam int              FIFO_DEPTH          = 16;
localparam int              RX_CREDIT_CNT       = FIFO_DEPTH * pcie_str_pkg::NUM_SLOTS;
localparam int              TX_CREDIT_CNT       = 64;

endpackage
