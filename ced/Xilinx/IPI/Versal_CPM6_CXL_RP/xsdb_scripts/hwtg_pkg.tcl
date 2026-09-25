# hwtg_pkg.tcl
#
# Constants mirrored from the custom_axi_tg IP's RTL. There is no single
# source of truth shared between hardware and this script, so keep these in
# sync by hand with:
#   src/ip_repo/custom_axi_tg/src/custom_axi_tg_pkg.sv  (instruction word,
#     opcodes, sticky error bit positions)
#   src/ip_repo/custom_axi_tg/src/custom_axi_tg_csr.sv  (CSR / per-command
#     status window offsets, documented in its header comment)
#   src/axil_gpio4.sv                                   (GPIO register map)

namespace eval hwtg {

  #----------------------------------------------------------------------
  # Instruction word geometry (custom_axi_tg_pkg.sv)
  #----------------------------------------------------------------------
  variable MAX_COMMANDS 32 ;# custom_axi_tg.sv localparam. Also readable live
                            ;# from TG_CFG bits[25:16] -- see hwtg::tg_cfg.

  # field -> {word_index bit_lsb width}. word_index selects which of the 6
  # 32-bit AXI-Lite slices the field lives in.
  variable FIELDS
  array set FIELDS {
    opcode      {0  0  2}
    addr_mode   {0  2  1}
    id_mode     {0  3  1}
    data_mode   {0  4  1}
    poison      {0  5  1}
    aruser_cmd  {0  6  2}
    addr_k      {0  8  5}
    be_k        {0 13  3}
    start_id    {0 16  4}
    id_stride   {0 20  4}
    addr_hi     {1  0 16}
    repeat      {1 16 12}
    addr_lo     {2  0 32}
    addr_stride {3  0 32}
    data_start  {4  0 32}
    data_stride {5  0 32}
  }

  variable ADDR_K_MAX 26 ;# values 27..31 silently clamp to 26 at commit

  #----------------------------------------------------------------------
  # Opcodes
  #----------------------------------------------------------------------
  variable OPCODES
  array set OPCODES {WRITE 0 READ 1 WAIT 2 RSVD 3}
  variable OPCODE_NAMES {WRITE READ WAIT RSVD}

  #----------------------------------------------------------------------
  # TG_BRESP_ERROR sticky bit positions (also FIRST_ERR_CODE values)
  #----------------------------------------------------------------------
  variable ERR_NAMES {
    ERR_GAP ERR_RSVD_OPCODE ERR_BUSY_IRAM ERR_IDX_RANGE ERR_ASSY_IDX
    ERR_UNMAPPED ERR_RSVD_SLICE ERR_DONE_PTR_RANGE ERR_START_BUSY
    ERR_SOFT_RST_BUSY
  }

  #----------------------------------------------------------------------
  # CSR offsets, relative to a custom_axi_tg instance's own s_axil base
  # address (custom_axi_tg_csr.sv header comment)
  #----------------------------------------------------------------------
  variable CSR_IRAM_BASE 0x0000
  variable CSR_BASE      0x8000
  variable CSR_STAT_BASE 0x9000

  variable CSR
  array set CSR {
    TG_CTRL           0x00
    TG_DONE_PTR       0x04
    TG_STATUS         0x08
    TG_BRESP_ERROR    0x0C
    TG_ID             0x14
    TG_CFG            0x18
    TG_ORPHAN_RSP     0x1C
    TG_RING_WR_STATUS 0x20
    TG_RING_RD_STATUS 0x24
    TG_CUR_CMD        0x28
  }

  variable RUN_STATE_NAMES {IDLE IN_PROG ALL_REQUESTED ALL_RESPONDED STOPPING}

  #----------------------------------------------------------------------
  # axil_gpio4 register offsets (src/axil_gpio4.sv), relative to its own
  # S_AXI base address
  #----------------------------------------------------------------------
  variable GPIO_MODE    0x00
  variable GPIO_STRETCH 0x04
  variable GPIO_GPIO    0x08
}
