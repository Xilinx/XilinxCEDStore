# -----------------------------------------------------------------------------
# All parent Makefiles should have this common code and agent-specific defaults
# -----------------------------------------------------------------------------
ifdef TEST
 PRINT_DESC = 1
endif
TEST = h2c_mem_api_test
SIM = questa
ROOT_PATH = ../..
COMP_FILES = -F ../cxl_nfi.F params_pkg.sv +incdir+$(ROOT_PATH)/common
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Specific variables that define commands that are dependent on the above
# -----------------------------------------------------------------------------
ifeq ($(SIM),questa)
 GUI_DO = log /tb_top/h2c_mst_if/*; log /tb_top/h2c_slv_if/*; \
          log /tb_top/c2h_mst_if/*; log /tb_top/c2h_slv_if/*; \
          log /tb_top/h2c_ss0_sf;   log /tb_top/h2c_ss1_sf;   log /tb_top/h2c_ss2_sf; \
          log /tb_top/c2h_ss0_sf;   log /tb_top/c2h_ss1_sf;   log /tb_top/c2h_ss2_sf; \
          log /tb_top/h2c_ss0_mreq; log /tb_top/h2c_ss1_mreq; log /tb_top/h2c_ss2_mreq; \
          log /tb_top/h2c_ss0_mrwd; log /tb_top/h2c_ss1_mrwd; log /tb_top/h2c_ss2_mrwd; \
          log /tb_top/c2h_ss0_mndr; log /tb_top/c2h_ss1_mndr; log /tb_top/c2h_ss2_mndr; \
          log /tb_top/c2h_ss0_mdrs; log /tb_top/c2h_ss1_mdrs; log /tb_top/c2h_ss2_mdrs; \
          log /tb_top/h2c_f256_ssptr; log /tb_top/c2h_f256_ssptr; \
          log /tb_top/h2c_rolli; log /tb_top/h2c_rollo; \
          log /tb_top/c2h_rolli; log /tb_top/c2h_rollo; \
          do dofile/radixes.do;
 ifneq ($(findstring h2c,$(TEST)),)
  GUI_DO += source dofile/h2c.do;
 endif
 ifneq ($(findstring c2h,$(TEST)),)
  GUI_DO += source dofile/c2h.do;
 endif
 ifeq ($(GUI),2)
  GUI_DO += run -a
 endif
else
 ifneq ($(GUI),1)
  PRE_SIM_CMD += echo "run" > uclirun.do;
 else
  PRE_SIM_CMD += echo "" > uclirun.do;
 endif
 GUI_DO=uclirun.do
endif

ifdef NFI #[1-3] | Default: 3
DEFINES+=NFI_W=$(NFI)
endif
ifdef MODE #[F68, F256] | Default=F68
DEFINES+=MODE=$(MODE)
endif

ADDL_HELP_PRINT += "    - TB Parameters"
ADDL_HELP_PRINT += "      - MODE   = [F68, F256] (default = F68)"
ADDL_HELP_PRINT += "      - NFI    = [1-3]       (default = 1)"

# -----------------------------------------------------------------------------
# All targets are captured here in the template
# -----------------------------------------------------------------------------
include $(ROOT_PATH)/common/Makefile.sim
