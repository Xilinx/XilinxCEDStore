create_pblock pblock_VitisRegion
add_cells_to_pblock [get_pblocks pblock_VitisRegion] [get_cells -quiet [list design_1_i/VitisRegion]]
resize_pblock [get_pblocks pblock_VitisRegion] -add {SLICE_X72Y0:SLICE_X239Y327 \
                                                     BLI_A_GRP0_X36Y0:BLI_A_GRP0_X127Y1 \
                                                     BLI_A_GRP1_X36Y0:BLI_A_GRP1_X127Y1 \
                                                     BLI_A_GRP2_X36Y0:BLI_A_GRP2_X127Y1 \
                                                     BLI_B_GRP0_X36Y0:BLI_B_GRP0_X127Y1 \
                                                     BLI_B_GRP1_X36Y0:BLI_B_GRP1_X127Y1 \
                                                     BLI_B_GRP2_X36Y0:BLI_B_GRP2_X127Y1 \
                                                     BLI_C_GRP0_X36Y0:BLI_C_GRP0_X127Y1 \
                                                     BLI_C_GRP1_X36Y0:BLI_C_GRP1_X127Y1 \
                                                     BLI_C_GRP2_X36Y0:BLI_C_GRP2_X127Y1 \
                                                     BLI_D_GRP4_X36Y0:BLI_D_GRP4_X127Y1 \
                                                     BLI_D_GRP5_X36Y0:BLI_D_GRP5_X127Y1 \
                                                     BLI_D_GRP6_X36Y0:BLI_D_GRP6_X127Y1 \
                                                     BLI_D_GRP7_X36Y0:BLI_D_GRP7_X127Y1 \
                                                     BUFGCE_X3Y0:BUFGCE_X8Y23 \
                                                     BUFGCE_DIV_X3Y0:BUFGCE_DIV_X8Y3 \
                                                     BUFGCE_HDIO_X0Y0:BUFGCE_HDIO_X0Y7 \
                                                     BUFGCTRL_X3Y0:BUFGCTRL_X8Y7 \
                                                     BUFG_FABRIC_X2Y0:BUFG_FABRIC_X3Y95 \
                                                     BUFG_GT_X1Y0:BUFG_GT_X1Y95 \
                                                     BUFG_GT_SYNC_X1Y0:BUFG_GT_SYNC_X1Y163 \
                                                     DDRMC_X1Y0:DDRMC_X2Y0 \
                                                     DDRMC_RIU_X2Y0:DDRMC_RIU_X2Y0 \
                                                     DPLL_X4Y0:DPLL_X10Y9 \
                                                     DSP58_CPLX_X0Y0:DSP58_CPLX_X3Y163 \
                                                     DSP_X0Y0:DSP_X7Y163 \
                                                     GTYP_QUAD_X1Y2:GTYP_QUAD_X1Y4 \
                                                     GTYP_REFCLK_X1Y4:GTYP_REFCLK_X1Y9 \
                                                     HDIOLOGIC_X0Y0:HDIOLOGIC_X0Y21 \
                                                     HDLOGIC_APB_X0Y0:HDLOGIC_APB_X0Y1 \
                                                     IOB_X68Y3:IOB_X68Y24 \
                                                     IRI_QUAD_X44Y0:IRI_QUAD_X152Y1367 \
                                                     MISR_X1Y0:MISR_X2Y3 \
                                                     MMCM_X3Y0:MMCM_X7Y0 \
                                                     MRMAC_X0Y0:MRMAC_X0Y1 \
                                                     NOC_NMU512_X1Y0:NOC_NMU512_X2Y6 \
                                                     NOC_NPS_VNOC_X1Y0:NOC_NPS_VNOC_X2Y13 \
                                                     NOC_NSU512_X1Y0:NOC_NSU512_X2Y6 \
                                                     PCIE50_X1Y0:PCIE50_X1Y2 \
                                                     RAMB18_X1Y0:RAMB18_X7Y167 \
                                                     RAMB36_X1Y0:RAMB36_X7Y83 \
                                                     RPI_HD_APB_X0Y0:RPI_HD_APB_X0Y1 \
                                                     URAM288_X1Y0:URAM288_X3Y83 \
                                                     URAM_CAS_DLY_X1Y0:URAM_CAS_DLY_X3Y3 \
                                                     VDU_X0Y0:VDU_X0Y3 \
                                                     XPLL_X6Y0:XPLL_X15Y0 \
                                                     CLOCKREGION_X0Y5:CLOCKREGION_X8Y5 \
}
set_property SNAPPING_MODE ON [get_pblocks pblock_VitisRegion]

resize_pblock pblock_VitisRegion -remove [get_sites -of [get_tiles DDRMC_DMC_CORE_X32Y0]]
resize_pblock pblock_VitisRegion -remove [get_sites -of [get_tiles CMT_XPLL_X26Y0]]
resize_pblock pblock_VitisRegion -remove [get_sites -of [get_tiles CMT_XPLL_X37Y0]]
resize_pblock pblock_VitisRegion -remove [get_sites -of [get_tiles DDRMC_DMC_CORE_X67Y0]]
resize_pblock pblock_VitisRegion -remove [get_sites -of [get_tiles DDRMC_RIU_CORE_X56Y0]]
resize_pblock pblock_VitisRegion -remove [get_sites -of [get_tiles CMT_XPLL_X71Y0]]
 

