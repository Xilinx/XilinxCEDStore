# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

 # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

proc create_root_design {currentDir design_name use_lpddr clk_options irqs use_aie} {

	puts "create_root_design"

	set fpga_part [get_property PART [current_project ]]

	puts "INFO: $fpga_part is selected"

	puts "INFO: selected design_name:: $design_name"
	puts "INFO: selected Interrupts:: $irqs"
	puts "INFO: selected Include_LPDDR:: $use_lpddr"
	puts "INFO: selected Clock_Options:: $clk_options"
	puts "INFO: selected Include_AIE:: $use_aie"
	
	puts "INFO: Using enhanced Versal extensible platform CED (part based)"

	set use_intc_15 [set use_intc_32 [set use_cascaded_irqs [set no_irqs ""]]]

	set use_intc_15 [ expr $irqs eq "15" ]
	set use_intc_32 [ expr $irqs eq "32" ]
	set use_cascaded_irqs [ expr $irqs eq "63" ]
	set no_irqs [ expr $irqs eq "0" ]

	# Create instance: ps_wizard_0, and set properties
	set ps_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ps_wizard ps_wizard_0]
	set ps_wiz_noc2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 ps_wiz_noc2]
	
	if { ([regexp "xc2v" $fpga_part]) && (![regexp "xc2vp" $fpga_part]) } {
		
		puts "Applying Versal * Gen 2 config" 

		#set_property -dict [list \
			CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
			CONFIG.PS11_CONFIG(MMI_GPU_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PL_FPD_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0} \
			CONFIG.PS11_CONFIG(PMC_QSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 MODE Single} \
			CONFIG.PS11_CONFIG(PMC_SDIO_30_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_13:25 IO_TYPE MIO} \
			CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI0_MASTER) {A78_0} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
			CONFIG.PS11_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:1 IO_TYPE MIO} \
			CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
			CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_PL) {1} \
			CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
			CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
		] $ps_wizard_0
		
		set_property -dict [list \
			CONFIG.MMI_CONFIG(MMI_GPU_ENABLE) {1} \
			CONFIG.PS11_CONFIG(MMI_GPU_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PL_FPD_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0} \
			CONFIG.PS11_CONFIG(PMC_QSPI_PERIPHERAL) {ENABLE 1 MODE Single} \
			CONFIG.PS11_CONFIG(PMC_SDIO_30_PERIPHERAL) {ENABLE 1 IO PMC_MIO_13:25 IO_TYPE MIO} \
			CONFIG.PS11_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
			CONFIG.PS11_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
			CONFIG.PS11_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PS_MIO_0:1 IO_TYPE MIO} \
			CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_NOC) {1} \
			CONFIG.PS11_CONFIG(PS_USE_FPD_AXI_PL) {1} \
			CONFIG.PS11_CONFIG(PS_USE_LPD_AXI_NOC) {1} \
			CONFIG.PS11_CONFIG(PS_USE_PMCPL_CLK0) {1} \
		] [get_bd_cells ps_wizard_0]

		set_property -dict [list \
			CONFIG.NUM_CLKS {11} \
			CONFIG.NUM_MI {0} \
			CONFIG.NUM_NMI {1} \
			CONFIG.NUM_SI {10} \
			CONFIG.SI_SIDEBAND_PINS {} \
		] [get_bd_cells ps_wiz_noc2]
		
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S08_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S09_AXI]
		
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S00_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S01_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC2] [get_bd_intf_pins ps_wiz_noc2/S02_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC3] [get_bd_intf_pins ps_wiz_noc2/S03_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC4] [get_bd_intf_pins ps_wiz_noc2/S04_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC5] [get_bd_intf_pins ps_wiz_noc2/S05_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC6] [get_bd_intf_pins ps_wiz_noc2/S06_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC7] [get_bd_intf_pins ps_wiz_noc2/S07_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S08_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S09_AXI]
		
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk1]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk2]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc2_clk] [get_bd_pins ps_wiz_noc2/aclk3]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc3_clk] [get_bd_pins ps_wiz_noc2/aclk4]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc4_clk] [get_bd_pins ps_wiz_noc2/aclk5]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc5_clk] [get_bd_pins ps_wiz_noc2/aclk6]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc6_clk] [get_bd_pins ps_wiz_noc2/aclk7]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc7_clk] [get_bd_pins ps_wiz_noc2/aclk8]
		connect_bd_net [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk9]
		connect_bd_net [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk10]
	
	} elseif { [regexp "xcvr1652" $fpga_part] || [regexp "xcvr1602" $fpga_part] } {
	
		puts "Applying Versal AI RF config"
		
		set_property -dict [list \
			CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
			CONFIG.PS_PMC_CONFIG(PMC_QSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 MODE Single} \
			CONFIG.PS_PMC_CONFIG(PMC_SD0_30_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_37:49 IO_TYPE MIO} \
			CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0} \
			CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
			CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
			CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_34:35 IO_TYPE MIO} \
			CONFIG.PS_PMC_CONFIG(PS_UART1_PERIPHERAL) {ENABLE 0 IO PMC_MIO_4:5 IO_TYPE MIO} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_PL) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
		] $ps_wizard_0
		
		
		set_property -dict [list CONFIG.NUM_CLKS {9} CONFIG.NUM_MI {0} CONFIG.NUM_NMI {1} CONFIG.NUM_SI {8} CONFIG.SI_SIDEBAND_PINS {} ] [get_bd_cells ps_wiz_noc2]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
		
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S00_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S01_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC2] [get_bd_intf_pins ps_wiz_noc2/S02_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC3] [get_bd_intf_pins ps_wiz_noc2/S03_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S04_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S05_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S06_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S07_AXI]
		
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk1]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk2]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc2_clk] [get_bd_pins ps_wiz_noc2/aclk3]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc3_clk] [get_bd_pins ps_wiz_noc2/aclk4]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk5]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk6]
		connect_bd_net [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk7]
		connect_bd_net [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk8]
	
	} else {
	
		puts "Applying Versal Prime config "
		
		set_property -dict [list \
			CONFIG.PS_PMC_CONFIG(PMC_CRP_PL0_REF_CTRL_FREQMHZ) {100} \
			CONFIG.PS_PMC_CONFIG(PMC_QSPI_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 MODE Single} \
			CONFIG.PS_PMC_CONFIG(PMC_QSPI_PERIPHERAL_DATA_MODE) {x4} \
			CONFIG.PS_PMC_CONFIG(PMC_SD0_30_PERIPHERAL) {PRIMARY_ENABLE 1 SECONDARY_ENABLE 0 IO PMC_MIO_37:49 IO_TYPE MIO} \
			CONFIG.PS_PMC_CONFIG(PMC_USE_PMC_AXI_NOC0) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI0_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI1_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI2_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI3_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI4_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI5_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_GEN_IPI6_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_IRQ_USAGE) {CH0 1 CH1 0 CH2 0 CH3 0 CH4 0 CH5 0 CH6 0 CH7 0 CH8 0 CH9 0 CH10 0 CH11 0 CH12 0 CH13 0 CH14 0 CH15 0} \
			CONFIG.PS_PMC_CONFIG(PS_NUM_FABRIC_RESETS) {1} \
			CONFIG.PS_PMC_CONFIG(PS_SLR_ID) {0} \
			CONFIG.PS_PMC_CONFIG(PS_TTC0_PERIPHERAL_ENABLE) {1} \
			CONFIG.PS_PMC_CONFIG(PS_UART0_PERIPHERAL) {ENABLE 1 IO PMC_MIO_34:35 IO_TYPE MIO} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC0) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_NOC1) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_AXI_PL) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_FPD_CCI_NOC) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_LPD_AXI_NOC0) {1} \
			CONFIG.PS_PMC_CONFIG(PS_USE_PMCPL_CLK0) {1} \
		] [get_bd_cells ps_wizard_0]
		
		set_property -dict [list \
			CONFIG.NUM_CLKS {9} \
			CONFIG.NUM_MI {0} \
			CONFIG.NUM_NMI {1} \
			CONFIG.NUM_SI {8} \
			CONFIG.SI_SIDEBAND_PINS {} \
		] [get_bd_cells ps_wiz_noc2]

		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
		
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S00_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S01_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC2] [get_bd_intf_pins ps_wiz_noc2/S02_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_CCI_NOC3] [get_bd_intf_pins ps_wiz_noc2/S03_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S04_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/FPD_AXI_NOC1] [get_bd_intf_pins ps_wiz_noc2/S05_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/LPD_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S06_AXI]
		connect_bd_intf_net [get_bd_intf_pins ps_wizard_0/PMC_AXI_NOC0] [get_bd_intf_pins ps_wiz_noc2/S07_AXI]
		
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk1]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk2]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc2_clk] [get_bd_pins ps_wiz_noc2/aclk3]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_cci_noc3_clk] [get_bd_pins ps_wiz_noc2/aclk4]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk5]
		connect_bd_net [get_bd_pins ps_wizard_0/fpd_axi_noc1_clk] [get_bd_pins ps_wiz_noc2/aclk6]
		connect_bd_net [get_bd_pins ps_wizard_0/lpd_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk7]
		connect_bd_net [get_bd_pins ps_wizard_0/pmc_axi_noc0_clk] [get_bd_pins ps_wiz_noc2/aclk8]

	}

	if {$use_intc_15} {
		# Create instance: axi_intc_0, and set properties
		set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
		set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0	
	}

	if {$use_intc_32} {
		# Create instance: axi_intc_0, and set properties
		set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
		set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0
	}

	if { $use_cascaded_irqs } {
		# Create instance: axi_intc_cascaded_1, and set properties
		set axi_intc_cascaded_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_cascaded_1 ]
		set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_cascaded_1
	
		# Create instance: axi_intc_parent, and set properties
		set axi_intc_parent [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_parent ]
		set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_parent
		
		# Create instance: xlconcat_0, and set properties
		create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:* xlconcat_0
		set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_0]
	}

	# Clocks options, and set properties
	set clk_freqs [ list 156.250000 104.166666 312.500000 100.000 100.000 100.000 100.000 ]
	set clk_used [list true false false false false false false ]
	set clk_ports [list clk_out1 clk_out2 clk_out3 clk_out4 clk_out5 clk_out6 clk_out7 ]
	set default_clk_port clk_out1
	set default_clk_num 0

	set i 0
	set clocks {}

	foreach { port freq id is_default } $clk_options {

		lset clk_ports $i $port
		lset clk_freqs $i $freq
		lset clk_used $i true
		
		if { $is_default } {
			set default_clk_port $port
			set default_clk_num $i
		}
		
		dict append clocks clk_out$i { id $id is_default $is_default proc_sys_reset "proc_sys_reset$i" status "fixed" }
		incr i
		
	}

	set num_clks $i

	# Create instance: clk_wizard_0, and set properties
	set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clkx5_wiz clk_wizard_0 ]
		set_property -dict [list \
		CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
		CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
		CONFIG.CLKOUT_GROUPING {Auto,Auto,Auto,Auto,Auto,Auto,Auto} \
		CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
		CONFIG.CLKOUT_PORT [join $clk_ports ","] \
		CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
		CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
		CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
		CONFIG.CLKOUT_USED [join $clk_used "," ]\
		CONFIG.JITTER_SEL {Min_O_Jitter} \
		CONFIG.PRIM_SOURCE {No_buffer} \
		CONFIG.RESET_TYPE {ACTIVE_LOW} \
		CONFIG.USE_LOCKED {true} \
		CONFIG.USE_PHASE_ALIGNMENT {true} \
		CONFIG.USE_RESET {true} \
	] $clk_wizard_0

	# Create instance: noc2_ddr5, and set properties
	set noc2_ddr5_flag 0
	
	if { [regexp "xc2vm3558" $fpga_part] || [regexp "xc2ve3558" $fpga_part] || [regexp "xc2ve3504" $fpga_part] || [regexp "xc2ve3304" $fpga_part] || [regexp "xc2ve3358" $fpga_part] } {
	
		puts "NOC2_DDR5_INFO :: Applying Versal DDR5 configuration - 1"
		set noc2_ddr5_flag 1

		set noc2_ddr5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 noc2_ddr5 ]
		
		set_property -dict [list \
			CONFIG.DDR5_DEVICE_TYPE {Components} \
			CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE DDR5_SDRAM DDRMC5_SPEED_GRADE DDR5-6400AN(46-46-46) DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH NA DDRMC5_F1_LP5_BANK_ARCH NA DDRMC5_DRAM_WIDTH x16 DDRMC5_DATA_WIDTH 16 DDRMC5_ROW_ADDR_WIDTH 16 DDRMC5_COL_ADDR_WIDTH 10 DDRMC5_BA_ADDR_WIDTH 2 DDRMC5_BG_WIDTH 2 DDRMC5_BURST_ADDR_WIDTH 0 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE NA DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH 1 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 16Gb DDRMC5_MEMORY_DENSITY 2GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_DDR5_RDIMM_ADDR_MODE DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_OTF_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI true DDRMC5_RD_DBI true DDRMC5_AUTO_PRECHARGE false DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_DDR5_PAR_RCD_EN false DDRMC5_OP_TEMPERATURE LOW DDRMC5_F0_TCK 313 DDRMC5_INPUTCLK0_PERIOD 9703 DDRMC5_F0_TFAW 12520 DDRMC5_F0_DDR5_TRP 14375 DDRMC5_F0_TRTP 24 DDRMC5_F0_TRTP_RU 24 DDRMC5_F1_TRTP_RU 24 DDRMC5_F0_TRCD 14375 DDRMC5_TREFI 3900000 DDRMC5_DDR5_TRFC1 295000 DDRMC5_DDR5_TRFC2 160000 DDRMC5_DDR5_TRFCSB 130000 DDRMC5_F0_TRAS 32000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 64 DDRMC5_F0_DDR5_TCCD_L_WR_RU 64 DDRMC5_F0_TXP 7500 DDRMC5_F0_DDR5_TPD 7500 DDRMC5_DDR5_TREFSBRD 30000 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL 46 DDRMC5_F0_CWL 44 DDRMC5_F0_DDR5_TRRD_L 16 DDRMC5_F0_TCCD_L 16 DDRMC5_F0_DDR5_TCCD_L_WR2 32 DDRMC5_F0_DDR5_TCCD_L_WR2_RU 32 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 313 DDRMC5_F1_TFAW 12520 DDRMC5_F1_DDR5_TRP 14375 DDRMC5_F1_TRTP 24 DDRMC5_F1_TRCD 14375 DDRMC5_F1_TRAS 32000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 64 DDRMC5_F1_DDR5_TCCD_L_WR_RU 64 DDRMC5_F1_TXP 7500 DDRMC5_F1_DDR5_TPD 7500 DDRMC5_F1_CL 46 DDRMC5_F1_CWL 44 DDRMC5_F1_DDR5_TRRD_L 16 DDRMC5_F1_TCCD_L 16 DDRMC5_F1_DDR5_TCCD_L_WR2 32 DDRMC5_F1_DDR5_TCCD_L_WR2_RU 32 DDRMC5_LP5_TRFCAB 0 DDRMC5_LP5_TRFCPB 0 DDRMC5_LP5_TPBR2PBR 0 DDRMC5_F0_LP5_TRPAB 0 DDRMC5_F0_LP5_TRPPB 0 DDRMC5_F0_LP5_TRRD 0 DDRMC5_LP5_TPBR2ACT 0 DDRMC5_F0_LP5_TCSPD 0 DDRMC5_F0_RL 0 DDRMC5_F0_WL 0 DDRMC5_F1_LP5_TRPAB 0 DDRMC5_F1_LP5_TRPPB 0 DDRMC5_F1_LP5_TRRD 0 DDRMC5_F1_LP5_TCSPD 0 DDRMC5_F1_RL 0 DDRMC5_F1_WL 0 DDRMC5_LP5_TRFMAB 0 DDRMC5_LP5_TRFMPB 0 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA9,CA8,CA7,CA6,CA5,CA4,NC,NC,NC,NC,NA DDRMC5_MC0_CONFIG_SEL config2 DDRMC5_MC1_CONFIG_SEL config2 DDRMC5_MC2_CONFIG_SEL config2 DDRMC5_MC3_CONFIG_SEL config2 DDRMC5_MC4_CONFIG_SEL config2 DDRMC5_MC5_CONFIG_SEL config2 DDRMC5_MC6_CONFIG_SEL config2 DDRMC5_MC7_CONFIG_SEL config2 DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 0 DDRMC5_SILICON_REVISION NA DDRMC5_FPGA_DEVICE_TYPE NON_KSB DDRMC5_SELF_REFRESH DISABLE DDRMC5_LBDQ_SWAP false DDRMC5_CAL_MASK_POLL ENABLE DDRMC5_BOARD_INTRF_EN false} \
			CONFIG.DDRMC5_NUM_CH {1} \
			CONFIG.NUM_MI {0} \
			CONFIG.NUM_NSI {1} \
			CONFIG.NUM_SI {0} \
		] [get_bd_cells noc2_ddr5]
		
		set_property CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} [get_bd_cells noc2_ddr5]

	} elseif { [regexp "xc2vm3358" $fpga_part] || [regexp "xc2vp3602" $fpga_part] } {
		
		puts "NOC2_DDR5_INFO :: Applying Versal DDR5 configuration - 2"
		set noc2_ddr5_flag 1

		set noc2_ddr5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 noc2_ddr5 ]

		set_property -dict [list \
			CONFIG.DDR5_DEVICE_TYPE {Components} \
			CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE DDR5_SDRAM DDRMC5_SPEED_GRADE DDR5-6400AN(46-46-46) DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH NA DDRMC5_F1_LP5_BANK_ARCH NA DDRMC5_DRAM_WIDTH x4 DDRMC5_DATA_WIDTH 16 DDRMC5_ROW_ADDR_WIDTH 16 DDRMC5_COL_ADDR_WIDTH 11 DDRMC5_BA_ADDR_WIDTH 2 DDRMC5_BG_WIDTH 3 DDRMC5_BURST_ADDR_WIDTH 0 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE NA DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH 1 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 16Gb DDRMC5_MEMORY_DENSITY 8GB DDRMC5_DM_EN false DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_DDR5_RDIMM_ADDR_MODE DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_OTF_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI true DDRMC5_RD_DBI true DDRMC5_AUTO_PRECHARGE false DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_DDR5_PAR_RCD_EN false DDRMC5_OP_TEMPERATURE LOW DDRMC5_F0_TCK 313 DDRMC5_INPUTCLK0_PERIOD 9703 DDRMC5_F0_TFAW 10016 DDRMC5_F0_DDR5_TRP 14375 DDRMC5_F0_TRTP 24 DDRMC5_F0_TRTP_RU 24 DDRMC5_F1_TRTP_RU 24 DDRMC5_F0_TRCD 14375 DDRMC5_TREFI 3900000 DDRMC5_DDR5_TRFC1 295000 DDRMC5_DDR5_TRFC2 160000 DDRMC5_DDR5_TRFCSB 130000 DDRMC5_F0_TRAS 32000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 64 DDRMC5_F0_DDR5_TCCD_L_WR_RU 64 DDRMC5_F0_TXP 7500 DDRMC5_F0_DDR5_TPD 7500 DDRMC5_DDR5_TREFSBRD 30000 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL 46 DDRMC5_F0_CWL 44 DDRMC5_F0_DDR5_TRRD_L 16 DDRMC5_F0_TCCD_L 16 DDRMC5_F0_DDR5_TCCD_L_WR2 32 DDRMC5_F0_DDR5_TCCD_L_WR2_RU 32 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 313 DDRMC5_F1_TFAW 11016 DDRMC5_F1_DDR5_TRP 14375 DDRMC5_F1_TRTP 24 DDRMC5_F1_TRCD 14375 DDRMC5_F1_TRAS 32000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 64 DDRMC5_F1_DDR5_TCCD_L_WR_RU 64 DDRMC5_F1_TXP 7500 DDRMC5_F1_DDR5_TPD 7500 DDRMC5_F1_CL 46 DDRMC5_F1_CWL 44 DDRMC5_F1_DDR5_TRRD_L 16 DDRMC5_F1_TCCD_L 16 DDRMC5_F1_DDR5_TCCD_L_WR2 32 DDRMC5_F1_DDR5_TCCD_L_WR2_RU 32 DDRMC5_LP5_TRFCAB 0 DDRMC5_LP5_TRFCPB 0 DDRMC5_LP5_TPBR2PBR 0 DDRMC5_F0_LP5_TRPAB 0 DDRMC5_F0_LP5_TRPPB 0 DDRMC5_F0_LP5_TRRD 0 DDRMC5_LP5_TPBR2ACT 0 DDRMC5_F0_LP5_TCSPD 0 DDRMC5_F0_RL 0 DDRMC5_F0_WL 0 DDRMC5_F1_LP5_TRPAB 0 DDRMC5_F1_LP5_TRPPB 0 DDRMC5_F1_LP5_TRRD 0 DDRMC5_F1_LP5_TCSPD 0 DDRMC5_F1_RL 0 DDRMC5_F1_WL 0 DDRMC5_LP5_TRFMAB 0 DDRMC5_LP5_TRFMPB 0 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,RA15,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG2,BG1,BG0,CA10,CA9,CA8,CA7,CA6,CA5,CA4,NC,NC,NC,NC,NA DDRMC5_MC0_CONFIG_SEL config1 DDRMC5_MC1_CONFIG_SEL config1 DDRMC5_MC2_CONFIG_SEL config1 DDRMC5_MC3_CONFIG_SEL config1 DDRMC5_MC4_CONFIG_SEL config1 DDRMC5_MC5_CONFIG_SEL config1 DDRMC5_MC6_CONFIG_SEL config1 DDRMC5_MC7_CONFIG_SEL config1 DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 0 DDRMC5_SILICON_REVISION NA DDRMC5_FPGA_DEVICE_TYPE NON_KSB DDRMC5_SELF_REFRESH DISABLE DDRMC5_LBDQ_SWAP false DDRMC5_CAL_MASK_POLL ENABLE DDRMC5_BOARD_INTRF_EN false} \
			CONFIG.DDRMC5_NUM_CH {1} \
			CONFIG.NUM_MI {0} \
			CONFIG.NUM_NSI {1} \
			CONFIG.NUM_SI {0} \
		] [get_bd_cells noc2_ddr5]


	} elseif { (![regexp "xc2vp3402" $fpga_part]) && (![regexp "xc2vp3502" $fpga_part]) } {
	
		puts "NOC2_DDR5_INFO :: Applying Versal DDR5 configuration - 3"
		set noc2_ddr5_flag 1

		set noc2_ddr5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 noc2_ddr5 ]

		set_property -dict [list \
			CONFIG.DDR5_DEVICE_TYPE {DIMMs} \
			CONFIG.NUM_MI {0} \
			CONFIG.NUM_NSI {1} \
			CONFIG.NUM_SI {0} \
		] [get_bd_cells noc2_ddr5]
		
		set_property CONFIG.MC_CHAN_REGION1 {DDR_CH0_MED} [get_bd_cells noc2_ddr5]
	}
	
	if { $noc2_ddr5_flag } {
		set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /noc2_ddr5/S00_INI]
		make_bd_intf_pins_external  [get_bd_intf_pins noc2_ddr5/sys_clk0] [get_bd_intf_pins noc2_ddr5/C0_DDR5]
		connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M00_INI] [get_bd_intf_pins noc2_ddr5/S00_INI]
	} elseif { $noc2_ddr5_flag == 0 } {
		puts "NOC2_DDR5_INFO :: NOC2_DDR5 instance NOT created due limited IO constraints - $fpga_part"
	}
	
	
	# Create instance: proc_sys_reset_N, and set properties
	for {set i 0} {$i < $num_clks} {incr i} {
		set proc_sys_reset_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_$i ]
	}

	connect_bd_net -net ps_wizard_0_pl_clk0 [get_bd_pins ps_wizard_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1]
	connect_bd_net -net ps_wizard_0_pl_resetn1 [get_bd_pins ps_wizard_0/pl0_resetn] [get_bd_pins clk_wizard_0/resetn]

	for {set i 0} {$i < $num_clks} {incr i} {
		connect_bd_net -net ps_wizard_0_pl_resetn1 [get_bd_pins proc_sys_reset_$i/ext_reset_in]
	}
	 
	# Create instance: icn_ctrl, and set properties
	set icn_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl ]
	 
	set default_clock_net clk_wizard_0_$default_clk_port
	connect_bd_net -net $default_clock_net [get_bd_pins ps_wizard_0/fpd_axi_pl_aclk] [get_bd_pins ps_wiz_noc2/aclk0] [get_bd_pins icn_ctrl/aclk] 
	 
	# Create instance: icn_ctrl, and set properties
	if {!$no_irqs} {
		
		if { $use_intc_15 } {
		
			# Using only 1 smartconnect to accomodate 15 AXI_Masters 
			set num_masters 1
			set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $icn_ctrl

		} else {
		
			# Adding multiple Smartconnects and dummy AXI_VIP to accomodate 32 or 63 AXI_Masters selected
		
			set num_masters [ expr "$use_cascaded_irqs ? 6 : 3" ]
			set num_kernal [ expr "$use_cascaded_irqs ? 4 : 2" ]
			set m_incr [ expr "$use_cascaded_irqs ? 2 : 1" ]

			set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $icn_ctrl 
		
			for {set i 0} {$i < $num_kernal} {incr i} {
				set to_delete_kernel_ctrl_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel_ctrl_$i ]
				set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] [get_bd_cells to_delete_kernel_ctrl_$i]
				set icn_ctrl_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl_$i ]
				set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} ] [get_bd_cells icn_ctrl_$i]
				set m [expr $i+$m_incr]
				connect_bd_intf_net [get_bd_intf_pins icn_ctrl/M0${m}_AXI] [get_bd_intf_pins icn_ctrl_$i/S00_AXI]
				connect_bd_intf_net [get_bd_intf_pins to_delete_kernel_ctrl_$i/S_AXI] [get_bd_intf_pins icn_ctrl_$i/M00_AXI]
				connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins to_delete_kernel_ctrl_$i/aresetn]
				connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins icn_ctrl_$i/aresetn]
				connect_bd_net -net $default_clock_net [get_bd_pins icn_ctrl_$i/aclk]
				connect_bd_net -net $default_clock_net [get_bd_pins to_delete_kernel_ctrl_$i/aclk]
			} 
		}
	}

	if {$no_irqs} {
		
		set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells icn_ctrl]
		set_property -dict [list CONFIG.PS_PMC_CONFIG { PS_IRQ_USAGE {{CH0 0} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}}}] [get_bd_cells ps_wizard_0]

		set to_delete_kernel [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel ]
		set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel

		connect_bd_intf_net [get_bd_intf_pins icn_ctrl/M00_AXI] [get_bd_intf_pins to_delete_kernel/S_AXI]
		connect_bd_net -net $default_clock_net [get_bd_pins to_delete_kernel/aclk] 
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins to_delete_kernel/aresetn] 
		
	}
		
	connect_bd_intf_net -intf_net ps_wizard_0_M_AXI_GP0 [get_bd_intf_pins ps_wizard_0/FPD_AXI_PL] [get_bd_intf_pins icn_ctrl/S00_AXI]

	for {set i 0} {$i < $num_clks} {incr i} {
		set port [lindex $clk_ports $i]
		connect_bd_net -net clk_wizard_0_$port [get_bd_pins clk_wizard_0/$port] [get_bd_pins proc_sys_reset_$i/slowest_sync_clk]
	}

	connect_bd_net -net clk_wizard_0_locked [get_bd_pins clk_wizard_0/locked]

	for {set i 0} {$i < $num_clks} {incr i} {
		connect_bd_net -net clk_wizard_0_locked [get_bd_pins proc_sys_reset_$i/dcm_locked] 
	}

	connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins proc_sys_reset_${default_clk_num}/peripheral_aresetn] [get_bd_pins icn_ctrl/aresetn] 
	

	if { $use_intc_15 } {
		
		set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells icn_ctrl]
		connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
		
		if { ([regexp "xc2v" $fpga_part]) && (![regexp "xc2vp" $fpga_part]) } {
			connect_bd_net [get_bd_pins axi_intc_0/irq] [get_bd_pins ps_wizard_0/pl_fpd_irq0]
		} else {
			connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
		}

		connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
	}
	
	
	if { $use_intc_32 } {
		set_property -dict [list CONFIG.NUM_MI {3}] [get_bd_cells icn_ctrl]
		connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]

		if { ([regexp "xc2v" $fpga_part]) && (![regexp "xc2vp" $fpga_part]) } {
			connect_bd_net [get_bd_pins axi_intc_0/irq] [get_bd_pins ps_wizard_0/pl_fpd_irq0]
		} else {
			connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq] 
		}

		connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
		connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
	}
	
	if { $use_cascaded_irqs } {
		connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_cascaded_1/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
		connect_bd_intf_net -intf_net icn_ctrl_M01_AXI [get_bd_intf_pins axi_intc_parent/s_axi] [get_bd_intf_pins icn_ctrl/M01_AXI]
		connect_bd_net [get_bd_pins axi_intc_cascaded_1/irq] [get_bd_pins xlconcat_0/In31]
		connect_bd_net [get_bd_pins axi_intc_parent/intr] [get_bd_pins xlconcat_0/dout]
		
		if { ([regexp "xc2v" $fpga_part]) && (![regexp "xc2vp" $fpga_part]) } {
			connect_bd_net [get_bd_pins ps_wizard_0/pl_fpd_irq0] [get_bd_pins axi_intc_parent/irq]
		} else {
			connect_bd_net -net axi_intc_0_irq [get_bd_pins ps_wizard_0/pl_ps_irq0] [get_bd_pins axi_intc_parent/irq] }
			connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_cascaded_1/s_axi_aclk]
			connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_parent/s_axi_aclk]
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_cascaded_1/s_axi_aresetn]
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_parent/s_axi_aresetn]
	}

	if { $use_aie } {
		
		# Create instance: ai_engine_0, and set properties
		set ai_engine_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine:* ai_engine_0 ]
		
		if { [regexp "xc2v" $fpga_part] } {
			
			set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_CLKS {12} CONFIG.NUM_MI {1} ] [get_bd_cells ps_wiz_noc2] 
			set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /ps_wiz_noc2/M00_AXI]
			
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
			set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S08_AXI]

			#set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S08_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S09_AXI]
			
			connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins ps_wiz_noc2/aclk11]
		
		} else {
		
			set_property -dict [list CONFIG.MI_SIDEBAND_PINS {} CONFIG.NUM_CLKS {10} CONFIG.NUM_MI {1} ] [get_bd_cells ps_wiz_noc2]
			set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /ps_wiz_noc2/M00_AXI]
			
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]

			connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins ps_wiz_noc2/aclk9]
		
		}
		
		connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]

	}

	if { $use_lpddr } {

		puts "INFO: LPDDR5 selected"
		
		if { $noc2_ddr5_flag == 1 } {
			set_property -dict [list CONFIG.NUM_NMI {2} ] [get_bd_cells ps_wiz_noc2]
		}
		
		if { $use_aie && $noc2_ddr5_flag } {
		
			if { ([regexp "xc2v" $fpga_part]) && (![regexp "xc2vp" $fpga_part]) } {

				#set_property CONFIG.NUM_NMI {2} [get_bd_cells ps_wiz_noc2]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S08_AXI]
				# set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S09_AXI]
				
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
				set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S08_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500} } M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4} } M00_INI {read_bw {500} write_bw {500} }}] [get_bd_intf_pins /ps_wiz_noc2/S09_AXI]

				
			} else {

				#set_property CONFIG.NUM_NMI {2} [get_bd_cells ps_wiz_noc2]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_AXI {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
				
			}

		} elseif { $noc2_ddr5_flag } {

			if { ([regexp "xc2v" $fpga_part]) && (![regexp "xc2vp" $fpga_part]) } {

				#set_property CONFIG.NUM_NMI {2} [get_bd_cells ps_wiz_noc2]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S08_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {500} write_bw {500}} M00_INI {read_bw {500} write_bw {500}}}] [get_bd_intf_pins /ps_wiz_noc2/S09_AXI]
			
			} else {
			
				#set_property CONFIG.NUM_NMI {2} [get_bd_cells ps_wiz_noc2]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S00_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S01_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S02_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S03_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S04_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S05_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S06_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI {read_bw {128} write_bw {128}} M00_INI {read_bw {128} write_bw {128}}}] [get_bd_intf_pins /ps_wiz_noc2/S07_AXI]
			
			}
		}
		
		set noc2_lpddr5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc2 noc2_lpddr5 ]
		
		if { ([regexp "xc2vm3558" $fpga_part]) || ([regexp "xc2ve3558" $fpga_part]) || ([regexp "xc2ve3504" $fpga_part])} {
		
			set_property -dict [list \
				CONFIG.DDR5_DEVICE_TYPE {Components} \
				CONFIG.DDRMC5_CONFIG {DDRMC5_CONTROLLERTYPE LPDDR5_SDRAM DDRMC5_SPEED_GRADE LPDDR5X-8533 DDRMC5_DEVICE_TYPE Components DDRMC5_F0_LP5_BANK_ARCH BG DDRMC5_F1_LP5_BANK_ARCH BG DDRMC5_DRAM_WIDTH x16 DDRMC5_DATA_WIDTH 16 DDRMC5_ROW_ADDR_WIDTH 15 DDRMC5_COL_ADDR_WIDTH 6 DDRMC5_BA_ADDR_WIDTH 2 DDRMC5_BG_WIDTH 2 DDRMC5_BURST_ADDR_WIDTH 4 DDRMC5_NUM_RANKS 1 DDRMC5_LATENCY_MODE x16 DDRMC5_NUM_SLOTS 1 DDRMC5_NUM_CK 1 DDRMC5_NUM_CH 1 DDRMC5_STACK_HEIGHT 1 DDRMC5_DRAM_SIZE 8Gb DDRMC5_MEMORY_DENSITY 1GB DDRMC5_DM_EN true DDRMC5_DQS_OSCI_EN DISABLE DDRMC5_SIDE_BAND_ECC false DDRMC5_INLINE_ECC false DDRMC5_DDR5_2T DISABLE DDRMC5_DDR5_RDIMM_ADDR_MODE DDR DDRMC5_REFRESH_MODE NORMAL DDRMC5_REFRESH_TYPE ALL_BANK DDRMC5_FREQ_SWITCHING false DDRMC5_BACKGROUND_SCRUB false DDRMC5_OTF_SCRUB false DDRMC5_SCRUB_SIZE 1 DDRMC5_MEM_FILL false DDRMC5_PERIODIC_READ ENABLE DDRMC5_USER_REFRESH false DDRMC5_WL_SET A DDRMC5_WR_DBI true DDRMC5_RD_DBI true DDRMC5_AUTO_PRECHARGE true DDRMC5_CRYPTO false DDRMC5_ON_DIE_ECC false DDRMC5_DDR5_PAR_RCD_EN false DDRMC5_OP_TEMPERATURE LOW DDRMC5_F0_TCK 938 DDRMC5_INPUTCLK0_PERIOD 9849 DDRMC5_F0_TFAW 20000 DDRMC5_F0_DDR5_TRP 18000 DDRMC5_F0_TRTP 7500 DDRMC5_F0_TRTP_RU 24 DDRMC5_F1_TRTP_RU 24 DDRMC5_F0_TRCD 18000 DDRMC5_TREFI 3906000 DDRMC5_DDR5_TRFC1 295000 DDRMC5_DDR5_TRFC2 160000 DDRMC5_DDR5_TRFCSB 130000 DDRMC5_F0_TRAS 42000 DDRMC5_F0_TZQLAT 30000 DDRMC5_F0_DDR5_TCCD_L_WR 0 DDRMC5_F0_DDR5_TCCD_L_WR_RU 32 DDRMC5_F0_TXP 7000 DDRMC5_F0_DDR5_TPD 0 DDRMC5_DDR5_TREFSBRD 0 DDRMC5_DDR5_TRFC1_DLR 0 DDRMC5_DDR5_TRFC1_DPR 0 DDRMC5_DDR5_TRFC2_DLR 0 DDRMC5_DDR5_TRFC2_DPR 0 DDRMC5_DDR5_TRFCSB_DLR 0 DDRMC5_DDR5_TREFSBRD_SLR 0 DDRMC5_DDR5_TREFSBRD_DLR 0 DDRMC5_F0_CL 64 DDRMC5_F0_CWL 0 DDRMC5_F0_DDR5_TRRD_L 0 DDRMC5_F0_TCCD_L 4 DDRMC5_F0_DDR5_TCCD_L_WR2 0 DDRMC5_F0_DDR5_TCCD_L_WR2_RU 16 DDRMC5_DDR5_TFAW_DLR 0 DDRMC5_F1_TCK 938 DDRMC5_F1_TFAW 20000 DDRMC5_F1_DDR5_TRP 18000 DDRMC5_F1_TRTP 7500 DDRMC5_F1_TRCD 18000 DDRMC5_F1_TRAS 42000 DDRMC5_F1_TZQLAT 30000 DDRMC5_F1_DDR5_TCCD_L_WR 0 DDRMC5_F1_DDR5_TCCD_L_WR_RU 32 DDRMC5_F1_TXP 7000 DDRMC5_F1_DDR5_TPD 0 DDRMC5_F1_CL 64 DDRMC5_F1_CWL 0 DDRMC5_F1_DDR5_TRRD_L 0 DDRMC5_F1_TCCD_L 4 DDRMC5_F1_DDR5_TCCD_L_WR2 0 DDRMC5_F1_DDR5_TCCD_L_WR2_RU 16 DDRMC5_LP5_TRFCAB 210000 DDRMC5_LP5_TRFCPB 120000 DDRMC5_LP5_TPBR2PBR 90000 DDRMC5_F0_LP5_TRPAB 21000 DDRMC5_F0_LP5_TRPPB 18000 DDRMC5_F0_LP5_TRRD 5000 DDRMC5_LP5_TPBR2ACT 7500 DDRMC5_F0_LP5_TCSPD 11250 DDRMC5_F0_RL 17 DDRMC5_F0_WL 9 DDRMC5_F1_LP5_TRPAB 21000 DDRMC5_F1_LP5_TRPPB 18000 DDRMC5_F1_LP5_TRRD 5000 DDRMC5_F1_LP5_TCSPD 11250 DDRMC5_F1_RL 17 DDRMC5_F1_WL 9 DDRMC5_LP5_TRFMAB 210000 DDRMC5_LP5_TRFMPB 170000 DDRMC5_SYSTEM_CLOCK Differential DDRMC5_UBLAZE_BLI_INTF false DDRMC5_REF_AND_PER_CAL_INTF false DDRMC5_PRE_DEF_ADDR_MAP_SEL ROW_BANK_COLUMN DDRMC5_USER_DEFINED_ADDRESS_MAP None DDRMC5_ADDRESS_MAP NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,RA14,RA13,RA12,RA11,RA10,RA9,RA8,RA7,RA6,RA5,RA4,RA3,RA2,RA1,RA0,BA1,BA0,BG1,BG0,CA5,CA4,CA3,CA2,CA1,CA0,NC,NC,NC,NC,NA DDRMC5_MC0_CONFIG_SEL config9 DDRMC5_MC1_CONFIG_SEL config10 DDRMC5_MC2_CONFIG_SEL config10 DDRMC5_MC3_CONFIG_SEL config10 DDRMC5_MC4_CONFIG_SEL config10 DDRMC5_MC5_CONFIG_SEL config10 DDRMC5_MC6_CONFIG_SEL config10 DDRMC5_MC7_CONFIG_SEL config10 DDRMC5_LOW_TRFC_DPR false DDRMC5_NUM_MC 1 DDRMC5_NUM_MCP 1 DDRMC5_MAIN_DEVICE_TYPE Components DDRMC5_INTERLEAVE_SIZE 0 DDRMC5_SILICON_REVISION NA DDRMC5_FPGA_DEVICE_TYPE NON_KSB DDRMC5_SELF_REFRESH DISABLE DDRMC5_LBDQ_SWAP false DDRMC5_CAL_MASK_POLL ENABLE DDRMC5_BOARD_INTRF_EN false} \
				CONFIG.DDRMC5_NUM_CH {1} \
				CONFIG.NUM_MI {0} \
				CONFIG.NUM_NSI {1} \
				CONFIG.NUM_SI {0} \
			] [get_bd_cells noc2_lpddr5]
			
			set_property CONFIG.MC_CHAN_REGION0 {DDR_CH1} [get_bd_cells noc2_lpddr5]
			
			set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /noc2_lpddr5/S00_INI]
		
		} else {
	
			set_property -dict [list \
				CONFIG.DDR5_DEVICE_TYPE {Components} \
				CONFIG.NUM_MI {0} \
				CONFIG.NUM_NSI {1} \
				CONFIG.NUM_SI {0} \
			] $noc2_lpddr5
			
			set_property CONFIG.MC_CHAN_REGION0 {DDR_CH1} [get_bd_cells noc2_lpddr5]
			set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}} MC_1 {read_bw {500} write_bw {500} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /noc2_lpddr5/S00_INI]
		}
	
		if { $noc2_ddr5_flag } {
			connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M01_INI] [get_bd_intf_pins noc2_lpddr5/S00_INI]
		} else {
			connect_bd_intf_net [get_bd_intf_pins ps_wiz_noc2/M00_INI] [get_bd_intf_pins noc2_lpddr5/S00_INI]
		}

		if { [regexp "xc2vp3602-vsva3014" $fpga_part] } {
			set_property -dict [list CONFIG.DDRMC5_CONFIG(DDRMC5_SYSTEM_CLOCK) {Differential} ] [get_bd_cells noc2_lpddr5]		
		}
		
		make_bd_intf_pins_external  [get_bd_intf_pins noc2_lpddr5/C0_CH0_LPDDR5] [get_bd_intf_pins noc2_lpddr5/C0_CH1_LPDDR5] [get_bd_intf_pins noc2_lpddr5/sys_clk0]
		
	}
	
	set_param project.replaceDontTouchWithKeepHierarchySoft 0
	assign_bd_address
	
	if { ! $use_intc_15 } {
		group_bd_cells axi_smc_vip_hier [get_bd_cells to_delete_kernel_ctrl_*] [get_bd_cells icn_ctrl] [get_bd_cells icn_ctrl_*]
	}

}


##################################################################
# MAIN FLOW
##################################################################

# puts "INFO: design_name:: $design_name and options:: $options is selected from GUI"
# get the clock options

set clk_options_param "Clock_Options.VALUE"
# set clk_options { clk_out1 200.000 0 true clk_out2 100.000 1 false clk_out3 300.000 2 false }
set clk_options { clk_out1 156.250000 0 true }

if { [dict exists $options $clk_options_param] } {
	set clk_options [ dict get $options $clk_options_param ]
}

# By default all available memory will be used. Here user choice is disabled
# Versal Prime Series ES1 : xcvm1102-sfva784* & Versal AI Edge Series ES1 : xcve2302-sfva784* parts do not support both LPDDR4 and DDR4 as the available MRMAC on the device is 1.
# Filterig unsupported parts for lpddr4

set fpga_part_prop [debug::dump_part_properties [get_property PART [current_project ]]]

set ddrmc_flag 1
set io_flag 1

foreach ddrmc_prop $fpga_part_prop {

	if {([regexp "DDRMC5" [lindex $ddrmc_prop 1 ]] == 1) && ([lindex $ddrmc_prop 3 ] < 2) } {
		set ddrmc_flag 0
	} elseif {$ddrmc_flag == 1} {
		set ddrmc_flag 1
	}
}


foreach io_prop $fpga_part_prop {
	if {([regexp "Io" [lindex $io_prop 1 ]] == 1) && ([lindex $io_prop 3 ] < 324)} {
		set io_flag 0
	} elseif {$io_flag == 1} {
		set io_flag 1
	}
}

if {( $ddrmc_flag == 0 ) || ($io_flag == 0) } {
	set use_lpddr 0
} else {
	set use_lpddr 1
}


if { ([regexp "xc2vp" $fpga_part]) } {
	set use_lpddr 1
}

#Force disable NOC2 lpddr5 instantiation as already noc2_ddr5 configured as lpddr5 in 2023.2.1
#set use_lpddr 0

set aie "Include_AIE.VALUE"
set use_aie 0
if { [dict exists $options $aie] } {
	set use_aie [dict get $options $aie ] 
}
puts "INFO: selected use_aie:: $use_aie"

# 0 (no interrupts) / 15 (interrupt controller : default) / 32 (interrupt controller) / 63 (interrupt controller + cascade block)

set irqs_param "IRQS.VALUE"
set irqs 15
if { [dict exists $options $irqs_param] } {
	set irqs [dict get $options $irqs_param ]
}


create_root_design $currentDir $design_name $use_lpddr $clk_options $irqs $use_aie

open_bd_design [get_bd_files $design_name]

puts "INFO: Block design generation completed, yet to set PFM properties"


# Set PFM properties


if { [get_bd_cells noc2_ddr5 -quiet] == "" } {
	set noc_ddr 0
} else {
	set noc_ddr [get_bd_cells noc2_ddr5]
}
set noc_lpddr [get_bd_cells noc2_lpddr5 -quiet]
set pfm_bd_name $design_name
set bdc false

source -notrace "$currentDir/pfm_properties.tcl"


set_property SELECTED_SIM_MODEL tlm [get_bd_cells /ps_wizard_0]
set_property SELECTED_SIM_MODEL tlm [get_bd_cells /ps_wiz_noc2]
if { [get_bd_cells noc2_ddr5 -quiet] != "" } {
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /noc2_ddr5]
}

set_property preferred_sim_model tlm [current_project]

set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wizard_0]


save_bd_design
validate_bd_design
open_bd_design [get_bd_files $design_name]
regenerate_bd_layout

make_wrapper -files [get_files $design_name.bd] -top -import

set TB_file [file join $currentDir test_bench ps_wizard_tb.v] 

set_property SOURCE_SET sources_1 [get_filesets sim_1]

import_files -fileset  sim_1 -norecurse -flat $TB_file 
set_property top tb [get_filesets sim_1]
update_compile_order -fileset sim_1

open_bd_design [get_bd_files $design_name]
puts "INFO: End of create_root_design"
