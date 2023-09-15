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

proc createDesign {design_name options} {  

	##################################################################
	# DESIGN PROCs													 
	##################################################################
	
	
	proc board_memory_config { board_selected } {
	
		if {[regexp "vpk120" $board_selected]||[regexp "vek280" $board_selected]||[regexp "vpk180" $board_selected]} {
		
			set default_mem "noc_lpddr4_0"
			set additional_mem "noc_lpddr4_1"
					
		} elseif {[regexp "vhk158" $board_selected]} {
		
			set default_mem "noc_ddr4_0"
			set additional_mem "noc_ddr4_1"
					
		} else {
					
			set default_mem "noc_ddr4"
			set additional_mem "noc_lpddr4"
		}
		
		return [ list $default_mem $additional_mem ]
	}
	
	variable currentDir
	set_property target_language Verilog [current_project]

	proc create_root_design {currentDir design_name use_lpddr clk_options irqs use_aie} {

		set use_lpddr 1
		
		puts "create_root_design"
		
		set board_part [get_property NAME [current_board_part]]
		set board_name [get_property BOARD_NAME [current_board]]
		set fpga_part [get_property PART_NAME [current_board_part]]
		
		puts "INFO: $board_name is selected"
		puts "INFO: $board_part is selected"
		puts "INFO: $fpga_part is selected"

		puts "INFO: selected Interrupts:: $irqs"
		puts "INFO: selected design_name:: $design_name"
		puts "INFO: selected Include_LPDDR:: $use_lpddr"
		puts "INFO: selected Clock_Options:: $clk_options"
		puts "INFO: selected Include_AIE:: $use_aie"
		
		puts "INFO: Using enhanced Versal extensible platform CED"
		
		# Fetching memory configurations availale on the selected board
		
		set mem_config [board_memory_config [get_property BOARD_NAME [current_board]]]
		
		set default_mem [lindex $mem_config 0]
		set additional_mem [lindex $mem_config 1]
		
		puts "INFO: Available memory types for $board_name board are :"
		puts "\t -> Default memory type : $default_mem"
		puts "\t -> Additional memory type : $additional_mem"

		set use_intc_15 [set use_intc_32 [set use_cascaded_irqs [set no_irqs ""]]]

		set use_intc_15 [ expr $irqs eq "15" ]
		set use_intc_32 [ expr $irqs eq "32" ]
		set use_cascaded_irqs [ expr $irqs eq "63" ]
		set no_irqs [ expr $irqs eq "0" ]

		# Create instance: CIPS_0, and set properties
		create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:* CIPS_0
		
		#apply_board_connection -board_interface "cips_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name
		apply_board_connection -board_interface "ps_pmc_fixed_io" -ip_intf "CIPS_0/FIXED_IO" -diagram $design_name

		set_property -dict [list CONFIG.PS_PMC_CONFIG { CLOCK_MODE Custom DDR_MEMORY_MODE Custom PMC_CRP_PL0_REF_CTRL_FREQMHZ 99.999992 PMC_USE_PMC_NOC_AXI0 1 PS_IRQ_USAGE {{CH0 1} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} PS_TTC0_PERIPHERAL_ENABLE {1} PS_NUM_FABRIC_RESETS 1 PS_PL_CONNECTIVITY_MODE Custom PS_USE_FPD_AXI_NOC0 1 PS_USE_FPD_AXI_NOC1 1 PS_USE_FPD_CCI_NOC 1 PS_USE_M_AXI_FPD 1 PS_USE_NOC_LPD_AXI0 1 PS_USE_PMCPL_CLK0 1 } CONFIG.CLOCK_MODE {Custom} CONFIG.DDR_MEMORY_MODE {Custom} CONFIG.PS_PL_CONNECTIVITY_MODE {Custom}] [get_bd_cells CIPS_0]

		set_property -dict [list CONFIG.PS_PMC_CONFIG {PS_GEN_IPI0_ENABLE 1 PS_GEN_IPI0_MASTER A72 PS_GEN_IPI1_ENABLE 1 PS_GEN_IPI1_MASTER A72 PS_GEN_IPI2_ENABLE 1 PS_GEN_IPI2_MASTER A72 PS_GEN_IPI3_ENABLE 1 PS_GEN_IPI3_MASTER A72 PS_GEN_IPI4_ENABLE 1 PS_GEN_IPI4_MASTER A72 PS_GEN_IPI5_ENABLE 1 PS_GEN_IPI5_MASTER A72 PS_GEN_IPI6_ENABLE 1 PS_GEN_IPI6_MASTER A72} ] [get_bd_cells CIPS_0]

		 if {$use_intc_15} {

			# Create instance: axi_intc_0, and set properties
			set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
			set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0
				
		}

		if {$use_intc_32} {
		 
			# Create instance: axi_intc_0, and set properties
			set axi_intc_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_0 ]
			set_property -dict [ list CONFIG.C_ASYNC_INTR {0xFFFFFFFF} CONFIG.C_IRQ_CONNECTION {1} ] $axi_intc_0
			
			#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_0
			#set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_0]
			#connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi_intc_0/intr]
			
		}

		if { $use_cascaded_irqs } {
		 
			# Create instance: axi_intc_cascaded_1, and set properties
			set axi_intc_cascaded_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_cascaded_1 ]
			set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_cascaded_1
		  
			# Create instance: axi_intc_parent, and set properties
			set axi_intc_parent [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc axi_intc_parent ]
			set_property -dict [ list CONFIG.C_IRQ_CONNECTION {1} CONFIG.C_ASYNC_INTR  {0xFFFFFFFF} ] $axi_intc_parent
			
			# Create instance: xlconcat_0, and set properties
			create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_0
			set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_0]
			
			# Create instance: xlconcat_1, and set properties
			#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:* xlconcat_1
			#set_property -dict [list CONFIG.NUM_PORTS {32} CONFIG.IN0_WIDTH {1}] [get_bd_cells xlconcat_1]
		}
		
		# Clocks options, and set properties
			
		set clk_freqs [ list 100.000 150.000 300.000 100.000 100.000 100.000 100.000 ]
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
		
		set clk_wizard_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard clk_wizard_0 ]
		set_property -dict [ list \
		   CONFIG.CLKOUT_DRIVES {BUFG,BUFG,BUFG,BUFG,BUFG,BUFG,BUFG} \
		   CONFIG.CLKOUT_DYN_PS {None,None,None,None,None,None,None} \
		   CONFIG.CLKOUT_MATCHED_ROUTING {false,false,false,false,false,false,false} \
		   CONFIG.CLKOUT_PORT [join $clk_ports ","] \
		   CONFIG.CLKOUT_REQUESTED_DUTY_CYCLE {50.000,50.000,50.000,50.000,50.000,50.000,50.000} \
		   CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY [join $clk_freqs ","] \
		   CONFIG.CLKOUT_REQUESTED_PHASE {0.000,0.000,0.000,0.000,0.000,0.000,0.000} \
		   CONFIG.CLKOUT_USED [join $clk_used "," ]\
		   CONFIG.JITTER_SEL {Min_O_Jitter} \
		   CONFIG.RESET_TYPE {ACTIVE_LOW} \
		   CONFIG.USE_LOCKED {true} \
		   CONFIG.USE_PHASE_ALIGNMENT {true} \
		   CONFIG.USE_RESET {true} \
		 ] $clk_wizard_0
		 
		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* cips_noc

		set_property -dict [list CONFIG.NUM_SI {8} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {0} CONFIG.NUM_NMI {1} CONFIG.NUM_CLKS {9}] [get_bd_cells cips_noc]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_cci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_nci} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_rpu} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
		set_property -dict [list CONFIG.CATEGORY {ps_pmc} CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
		set_property -dict [list CONFIG.ASSOCIATED_BUSIF {S03_AXI:S02_AXI:S00_AXI:S01_AXI:S04_AXI:S07_AXI:S06_AXI:S05_AXI}] [get_bd_pins /cips_noc/aclk0]

		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $default_mem
		
		if {[regexp "vpk120" $board_name]||[regexp "vek280" $board_name]} {
		
			apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "$default_mem/CH0_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "$default_mem/CH1_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "$default_mem/sys_clk0" -diagram $design_name
			
		} elseif {[regexp "vpk180" $board_name]} {
		
			apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/$default_mem/CH0_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/$default_mem/CH1_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/$default_mem/sys_clk0" -diagram $design_name
			
		} elseif {[regexp "vhk158" $board_name]} {
		
			apply_board_connection -board_interface "ddr4_dimm0" -ip_intf "$default_mem/CH0_DDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ddr4_dimm0_sma_clk" -ip_intf "$default_mem/sys_clk0" -diagram $design_name 
		
		} else {
		
			apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "$default_mem/CH0_DDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "$default_mem/sys_clk0" -diagram $design_name 
		
		}
		
		set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {1} CONFIG.NUM_CLKS {0} CONFIG.NUM_MCP {4} CONFIG.MC_CHAN_REGION1 {DDR_LOW1}] [get_bd_cells $default_mem]
		if { [regexp "noc_lpddr4" $default_mem] } {
			set_property -dict [list \
			CONFIG.MC_CHANNEL_INTERLEAVING {true} \
			CONFIG.MC_CH_INTERLEAVING_SIZE {4K_Bytes} \
			] [get_bd_cells $default_mem]
		}
		set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {128} write_bw {128} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /$default_mem/S00_INI]
		
		connect_bd_intf_net [get_bd_intf_pins cips_noc/M00_INI] [get_bd_intf_pins $default_mem/S00_INI]

		connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_0] [get_bd_intf_pins cips_noc/S00_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_1] [get_bd_intf_pins cips_noc/S01_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_2] [get_bd_intf_pins cips_noc/S02_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_CCI_NOC_3] [get_bd_intf_pins cips_noc/S03_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_0] [get_bd_intf_pins cips_noc/S04_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/FPD_AXI_NOC_1] [get_bd_intf_pins cips_noc/S05_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/LPD_AXI_NOC_0] [get_bd_intf_pins cips_noc/S06_AXI]
		connect_bd_intf_net [get_bd_intf_pins CIPS_0/PMC_NOC_AXI_0] [get_bd_intf_pins cips_noc/S07_AXI]
		connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi0_clk] [get_bd_pins cips_noc/aclk1]
		connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi1_clk] [get_bd_pins cips_noc/aclk2]
		connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi2_clk] [get_bd_pins cips_noc/aclk3]
		connect_bd_net [get_bd_pins CIPS_0/fpd_cci_noc_axi3_clk] [get_bd_pins cips_noc/aclk4]
		connect_bd_net [get_bd_pins CIPS_0/fpd_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk5]
		connect_bd_net [get_bd_pins CIPS_0/fpd_axi_noc_axi1_clk] [get_bd_pins cips_noc/aclk6]
		connect_bd_net [get_bd_pins CIPS_0/lpd_axi_noc_clk] [get_bd_pins cips_noc/aclk7]
		connect_bd_net [get_bd_pins CIPS_0/pmc_axi_noc_axi0_clk] [get_bd_pins cips_noc/aclk8]

		for {set i 0} {$i < $num_clks} {incr i} {
			# Create instance: proc_sys_reset_N, and set properties
			set proc_sys_reset_$i [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_$i ]
		}

		connect_bd_net -net CIPS_0_pl_clk0 [get_bd_pins CIPS_0/pl0_ref_clk] [get_bd_pins clk_wizard_0/clk_in1]
		connect_bd_net -net CIPS_0_pl_resetn1 [get_bd_pins CIPS_0/pl0_resetn] [get_bd_pins clk_wizard_0/resetn]

		for {set i 0} {$i < $num_clks} {incr i} {
			connect_bd_net -net CIPS_0_pl_resetn1 [get_bd_pins proc_sys_reset_$i/ext_reset_in]
		}
		   
		# Create instance: icn_ctrl, and set properties
		set icn_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect icn_ctrl ]
		  
		set default_clock_net clk_wizard_0_$default_clk_port
		connect_bd_net -net $default_clock_net [get_bd_pins CIPS_0/m_axi_fpd_aclk] [get_bd_pins cips_noc/aclk0] [get_bd_pins icn_ctrl/aclk] 
		  
		
		# Create instance: icn_ctrl, and set properties
		
		if {!$no_irqs } {
		
			if { $use_intc_15 } {
			
				# Using only 1 smartconnect to accomodate 15 AXI_Masters 

				set num_masters 1
								
				set_property -dict [ list CONFIG.NUM_CLKS {1} CONFIG.NUM_MI $num_masters CONFIG.NUM_SI {1} ] $icn_ctrl
				

			} else {
			
				# Adding multiple Smartconnects and dummy AXI_VIP to accomodate 32 or 63 AXI_Masters selected
				# Create instance: icn_ctrl, and set properties
				
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
		 
		if {$no_irqs } {
		
			set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells icn_ctrl]
			set_property -dict [list CONFIG.PS_PMC_CONFIG { PS_IRQ_USAGE {{CH0 0} {CH1 0} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}}}] [get_bd_cells CIPS_0]
			
			set to_delete_kernel [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vip to_delete_kernel ]
			set_property -dict [ list CONFIG.INTERFACE_MODE {SLAVE} ] $to_delete_kernel
			connect_bd_intf_net [get_bd_intf_pins icn_ctrl/M00_AXI] [get_bd_intf_pins to_delete_kernel/S_AXI]
			#apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wizard_0/clk_out1 (200 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins to_delete_kernel/aclk]
			connect_bd_net -net $default_clock_net [get_bd_pins to_delete_kernel/aclk] 
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins to_delete_kernel/aresetn] 
		
		}
		
		connect_bd_intf_net -intf_net CIPS_0_M_AXI_GP0 [get_bd_intf_pins CIPS_0/M_AXI_FPD] [get_bd_intf_pins icn_ctrl/S00_AXI]

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
			connect_bd_net -net axi_intc_0_irq [get_bd_pins CIPS_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
			connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
		}

		if { $use_intc_32 } {
			set_property -dict [list CONFIG.NUM_MI {3}] [get_bd_cells icn_ctrl]
			connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_0/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
			connect_bd_net -net axi_intc_0_irq [get_bd_pins CIPS_0/pl_ps_irq0] [get_bd_pins axi_intc_0/irq]
			connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_0/s_axi_aclk]
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_0/s_axi_aresetn]
		}
		  
		if { $use_cascaded_irqs } {
			connect_bd_intf_net -intf_net icn_ctrl_M00_AXI [get_bd_intf_pins axi_intc_cascaded_1/s_axi] [get_bd_intf_pins icn_ctrl/M00_AXI]
			connect_bd_intf_net -intf_net icn_ctrl_M01_AXI [get_bd_intf_pins axi_intc_parent/s_axi] [get_bd_intf_pins icn_ctrl/M01_AXI]
			connect_bd_net [get_bd_pins axi_intc_cascaded_1/irq] [get_bd_pins xlconcat_0/In31]
			connect_bd_net [get_bd_pins axi_intc_parent/intr] [get_bd_pins xlconcat_0/dout]
			#connect_bd_net [get_bd_pins axi_intc_cascaded_1/intr] [get_bd_pins xlconcat_1/dout]
			connect_bd_net -net axi_intc_0_irq [get_bd_pins CIPS_0/pl_ps_irq0] [get_bd_pins axi_intc_parent/irq]
			connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_cascaded_1/s_axi_aclk]
			connect_bd_net -net $default_clock_net [get_bd_pins axi_intc_parent/s_axi_aclk]
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_cascaded_1/s_axi_aresetn]
			connect_bd_net -net proc_sys_reset_${default_clk_num}_peripheral_aresetn [get_bd_pins axi_intc_parent/s_axi_aresetn]
		}
		

		
		
		if { $use_aie } {
		
			set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_CLKS {10}] [get_bd_cells cips_noc]
			set_property -dict [list CONFIG.CATEGORY {aie}] [get_bd_intf_pins /cips_noc/M00_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
			set_property -dict [list CONFIG.CONNECTIONS {M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
			set_property -dict [list CONFIG.ASSOCIATED_BUSIF {M00_AXI}] [get_bd_pins /cips_noc/aclk9]

			# Create instance: ai_engine_0, and set properties
			set ai_engine_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ai_engine:* ai_engine_0 ]
			set_property -dict [ list \
			  CONFIG.CLK_NAMES {} \
			  CONFIG.NAME_MI_AXI {} \
			  CONFIG.NAME_MI_AXIS {} \
			  CONFIG.NAME_SI_AXI {S00_AXI,} \
			  CONFIG.NAME_SI_AXIS {} \
			  CONFIG.NUM_CLKS {0} \
			  CONFIG.NUM_MI_AXI {0} \
			  CONFIG.NUM_MI_AXIS {0} \
			  CONFIG.NUM_SI_AXI {1} \
			  CONFIG.NUM_SI_AXIS {0} \
			] $ai_engine_0
		
			set_property -dict [ list CONFIG.CATEGORY {NOC} ] [get_bd_intf_pins /ai_engine_0/S00_AXI]
		  
			connect_bd_intf_net [get_bd_intf_pins cips_noc/M00_AXI] [get_bd_intf_pins ai_engine_0/S00_AXI]
			connect_bd_net [get_bd_pins ai_engine_0/s00_axi_aclk] [get_bd_pins cips_noc/aclk9] 

			# assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
			# assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
			# assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
			# assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
			# assign_bd_address -offset 0x020000000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs ai_engine_0/S00_AXI/AIE_ARRAY_0] -force
		}

		if { $use_lpddr } {
		
			puts "INFO: lpddr4 selected"
			
			if {$use_aie } {
				set_property -dict [list CONFIG.NUM_NMI {2}] [get_bd_cells cips_noc]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_AXI { read_bw {5} write_bw {5} read_avg_burst {4} write_avg_burst {4}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
				set_property -dict [list CONFIG.ASSOCIATED_BUSIF {}] [get_bd_pins /cips_noc/aclk9]
			} else {
				set_property -dict [list CONFIG.NUM_NMI {2}] [get_bd_cells cips_noc]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S00_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S01_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S02_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S03_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S04_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S05_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S06_AXI]
				set_property -dict [list CONFIG.CONNECTIONS {M01_INI { read_bw {128} write_bw {128}} M00_INI { read_bw {128} write_bw {128}} }] [get_bd_intf_pins /cips_noc/S07_AXI]
			}

		create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:* $additional_mem

		if {[regexp "vpk120" $board_name]||[regexp "vek280" $board_name]} {

			apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "$additional_mem/CH0_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "$additional_mem/CH1_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

			apply_board_connection -board_interface "ch0_lpddr4_trip3" -ip_intf "/$additional_mem/CH0_LPDDR4_1" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_trip3" -ip_intf "/$additional_mem/CH1_LPDDR4_1" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_clk3" -ip_intf "/$additional_mem/sys_clk1" -diagram $design_name 
			
		} elseif {[regexp "vpk180" $board_name]} {
		
			apply_board_connection -board_interface "ch0_lpddr4_trip2" -ip_intf "$additional_mem/CH0_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_trip2" -ip_intf "$additional_mem/CH1_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_clk2" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

			apply_board_connection -board_interface "ch0_lpddr4_trip1" -ip_intf "/$additional_mem/CH0_LPDDR4_1" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_trip1" -ip_intf "/$additional_mem/CH1_LPDDR4_1" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_clk1" -ip_intf "/$additional_mem/sys_clk1" -diagram $design_name  

		} elseif {[regexp "vhk158" $board_name]} {
		
			apply_board_connection -board_interface "ddr4_dimm1" -ip_intf "$additional_mem/CH0_DDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ddr4_dimm1_sma_clk" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 
		
		} else {

			apply_board_connection -board_interface "ch0_lpddr4_c0" -ip_intf "$additional_mem/CH0_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_c0" -ip_intf "$additional_mem/CH1_LPDDR4_0" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_sma_clk1" -ip_intf "$additional_mem/sys_clk0" -diagram $design_name 

			apply_board_connection -board_interface "ch0_lpddr4_c1" -ip_intf "/$additional_mem/CH0_LPDDR4_1" -diagram $design_name 
			apply_board_connection -board_interface "ch1_lpddr4_c1" -ip_intf "/$additional_mem/CH1_LPDDR4_1" -diagram $design_name 
			apply_board_connection -board_interface "lpddr4_sma_clk2" -ip_intf "/$additional_mem/sys_clk1" -diagram $design_name 
		
		} 

		set_property -dict [list CONFIG.NUM_SI {0} CONFIG.NUM_MI {0} CONFIG.NUM_NSI {1} CONFIG.NUM_CLKS {0} CONFIG.MC_CHAN_REGION0 {DDR_CH1}] [get_bd_cells $additional_mem]
		set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /$additional_mem/S00_INI]

		connect_bd_intf_net [get_bd_intf_pins cips_noc/M01_INI] [get_bd_intf_pins $additional_mem/S00_INI] 
	
		# if {[regexp "vhk158" $board_name]} {
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1] -force

		# } else {
		
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
			# assign_bd_address -offset 0x050000000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs $additional_mem/S00_INI/C0_DDR_CH1x2] -force
		# }
		}
		
		# if { $use_intc } {
			# assign_bd_address -target_address_space /CIPS_0/M_AXI_FPD [get_bd_addr_segs axi_intc_0/S_AXI/Reg] -force
			# assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_0/S_AXI/Reg] 
		# }

		# if { $use_cascaded_irqs } {
			# assign_bd_address -offset 0xA4000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_cascaded_1/S_AXI/Reg] -force 
			# assign_bd_address -offset 0xA5000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] [get_bd_addr_segs axi_intc_parent/S_AXI/Reg] -force 
		# }

		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force
		# assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW0] -force

		# if {[regexp "vpk120" $board_name]||[regexp "vpk180" $board_name]} {

			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force

		# } else {
		
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_1] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_2] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/LPD_AXI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_3] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_CCI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/PMC_NOC_AXI_0] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
			# assign_bd_address -offset 0x000800000000 -range 0x180000000 -target_address_space [get_bd_addr_spaces CIPS_0/FPD_AXI_NOC_1] [get_bd_addr_segs $default_mem/S00_INI/C0_DDR_LOW1] -force
		# }
		
		assign_bd_address
		
		set_param project.replaceDontTouchWithKeepHierarchySoft 0
		
		catch {
			exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
			exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_0/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
			exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_1/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
			exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_2/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD]
			exclude_bd_addr_seg [get_bd_addr_segs to_delete_kernel_ctrl_3/S_AXI/Reg] -target_address_space [get_bd_addr_spaces CIPS_0/M_AXI_FPD] 
		}
		
		if { ! $use_intc_15 } {
			group_bd_cells axi_smc_vip_hier [get_bd_cells to_delete_kernel_ctrl_*] [get_bd_cells icn_ctrl] [get_bd_cells icn_ctrl_*]  
		}
	}

	##################################################################
	# MAIN FLOW
	##################################################################
	
	# Fetching memory configurations availale on the selected board

	set mem_config [board_memory_config [get_property BOARD_NAME [current_board]]]
		
	set default_mem [lindex $mem_config 0]
	set additional_mem [lindex $mem_config 1]
	
	# puts "INFO: design_name:: $design_name and options:: $options is selected from GUI"
	# get the clock options

	set clk_options_param "Clock_Options.VALUE"
	# set clk_options { clk_out1 200.000 0 true clk_out2 100.000 1 false clk_out3 300.000 2 false }
	set clk_options { clk_out1 200.000 0 true }
	if { [dict exists $options $clk_options_param] } {
		set clk_options [ dict get $options $clk_options_param ]
	}
	
	# By default all available memory will be used. Here user choice is disabled

	#puts "INFO: selected clk_options:: $clk_options"
	set lpddr "Include_LPDDR.VALUE"
	set use_lpddr 1
	
	# if { [dict exists $options $lpddr] } {
		# set use_lpddr [dict get $options $lpddr ]
	# }

	#puts "INFO: selected use_lpddr:: $use_lpddr"

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
	
	#QoR script for vck190 production CED platforms
	
	set board_part [get_property NAME [current_board_part]]
	
	if [regexp "vck190" $board_part] {
	
		#set bdDesignPath [file join [get_property directory [current_project]] [current_project].srcs sources_1 bd $design_name]
		
		set script_dir [file join $currentDir qor_scripts prohibit_select_bli_bels_for_hold.tcl]
		#set tempTBFile [file join $bdDesignPath prohibit_select_bli_bels_for_hold.v] 

		import_files -fileset utils_1 -norecurse $script_dir
		set_property platform.run.steps.place_design.tcl.pre [get_files prohibit_select_bli_bels_for_hold.tcl] [current_project] 
	
	}
	
	open_bd_design [get_bd_files $design_name]
	
	puts "INFO: Block design generation completed, yet to set PFM properties"
	
	set board_name [get_property BOARD_NAME [current_board]]
	
	# Create PFM attributes
	
	puts "INFO: Creating extensible_platform for $board_name"
	set pfmName "xilinx.com:${board_name}:versal_extensible_platform_base:1.0"
	set_property PFM_NAME $pfmName [get_files [current_bd_design].bd]
		
	if { $irqs eq "15" } {
		set_property PFM.IRQ {intr {id 0 range 15}}  [get_bd_cells /axi_intc_0]
		
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells /icn_ctrl]
	}


	if { $irqs eq "32" } {
	
		set_property PFM.IRQ {intr {id 0 range 31}}  [get_bd_cells /axi_intc_0]
		
		set_property PFM.AXI_PORT {M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} } [get_bd_cells axi_smc_vip_hier/icn_ctrl]
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_0]
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_1]
	}
	
	if { $irqs eq "63" } {
	
		set_property PFM.IRQ {intr {id 0 range 32}}  [get_bd_cells /axi_intc_cascaded_1]
		
		set_property PFM.IRQ {In0 {id 32} In1 {id 33} In2 {id 34} In3 {id 35} In4 {id 36} In5 {id 37} In6 {id 38} In7 {id 39} In8 {id 40} \
		In9 {id 41} In10 {id 42} In11 {id 43} In12 {id 44} In13 {id 45} In14 {id 46} In15 {id 47} In16 {id 48} In17 {id 49} In18 {id 50} \
		In19 {id 51} In20 {id 52} In21 {id 53} In22 {id 54} In23 {id 55} In24 {id 56} In25 {id 57} In26 {id 58} In27 {id 59} In28 {id 60} \
		In29 {id 61} In30 {id 62} } [get_bd_cells /xlconcat_0]
		
		set_property PFM.AXI_PORT {M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl]
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_0]
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_1]
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_2]
		set_property PFM.AXI_PORT {M01_AXI {memport "M_AXI_GP" sptag "" memory ""} M02_AXI {memport "M_AXI_GP" sptag "" memory ""} M03_AXI {memport "M_AXI_GP" sptag "" memory ""} M04_AXI {memport "M_AXI_GP" sptag "" memory ""} M05_AXI {memport "M_AXI_GP" sptag "" memory ""} M06_AXI {memport "M_AXI_GP" sptag "" memory ""} M07_AXI {memport "M_AXI_GP" sptag "" memory ""} M08_AXI {memport "M_AXI_GP" sptag "" memory ""} M09_AXI {memport "M_AXI_GP" sptag "" memory ""} M10_AXI {memport "M_AXI_GP" sptag "" memory ""} M11_AXI {memport "M_AXI_GP" sptag "" memory ""} M12_AXI {memport "M_AXI_GP" sptag "" memory ""} M13_AXI {memport "M_AXI_GP" sptag "" memory ""} M14_AXI {memport "M_AXI_GP" sptag "" memory ""} M15_AXI {memport "M_AXI_GP" sptag "" memory ""}} [get_bd_cells axi_smc_vip_hier/icn_ctrl_3]
	
	}
	
	set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "DDR"} S01_AXI {memport "S_AXI_NOC" sptag "DDR"} S02_AXI {memport "S_AXI_NOC" sptag "DDR"} S03_AXI {memport "S_AXI_NOC" sptag "DDR"} S04_AXI {memport "S_AXI_NOC" sptag "DDR"} S05_AXI {memport "S_AXI_NOC" sptag "DDR"} S06_AXI {memport "S_AXI_NOC" sptag "DDR"} S07_AXI {memport "S_AXI_NOC" sptag "DDR"} S08_AXI {memport "S_AXI_NOC" sptag "DDR"} S09_AXI {memport "S_AXI_NOC" sptag "DDR"} S10_AXI {memport "S_AXI_NOC" sptag "DDR"} S11_AXI {memport "S_AXI_NOC" sptag "DDR"} S12_AXI {memport "S_AXI_NOC" sptag "DDR"} S13_AXI {memport "S_AXI_NOC" sptag "DDR"} S14_AXI {memport "S_AXI_NOC" sptag "DDR"} S15_AXI {memport "S_AXI_NOC" sptag "DDR"} S16_AXI {memport "S_AXI_NOC" sptag "DDR"} S17_AXI {memport "S_AXI_NOC" sptag "DDR"} S18_AXI {memport "S_AXI_NOC" sptag "DDR"} S19_AXI {memport "S_AXI_NOC" sptag "DDR"} S20_AXI {memport "S_AXI_NOC" sptag "DDR"} S21_AXI {memport "S_AXI_NOC" sptag "DDR"} S22_AXI {memport "S_AXI_NOC" sptag "DDR"} S23_AXI {memport "S_AXI_NOC" sptag "DDR"} S24_AXI {memport "S_AXI_NOC" sptag "DDR"} S25_AXI {memport "S_AXI_NOC" sptag "DDR"} S26_AXI {memport "S_AXI_NOC" sptag "DDR"} S27_AXI {memport "S_AXI_NOC" sptag "DDR"}} [get_bd_cells /$default_mem]
	
	set clocks {}
   
	set i 0
   
	foreach { port freq id is_default } $clk_options {
		dict append clocks $port "id \"$id\" is_default \"$is_default\" proc_sys_reset \"/proc_sys_reset_$i\" status \"fixed\""
		incr i
    }
	
	set_property PFM.CLOCK $clocks [get_bd_cells /clk_wizard_0]
	#puts "clocks :: $clocks  PFM properties"
	
	catch { set lpddr [get_bd_cells /$additional_mem] }
	
	if { $use_lpddr } {
		puts "INFO: lpddr4 selected"
		set_property PFM.AXI_PORT {S00_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S01_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S02_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S03_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S04_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S05_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S06_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S07_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S08_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S09_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S10_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S11_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S12_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S13_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S14_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S15_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S16_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S17_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S18_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S19_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S20_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S21_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S22_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S23_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S24_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S25_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S26_AXI {memport "S_AXI_NOC" sptag "LPDDR"} S27_AXI {memport "S_AXI_NOC" sptag "LPDDR"}} [get_bd_cells /$additional_mem]
		set_property SELECTED_SIM_MODEL tlm [get_bd_cells /$additional_mem]
	}
	
	#Platform Level Properties
	set_property platform.default_output_type "sd_card" [current_project]
	set_property platform.design_intent.embedded "true" [current_project]
	set_property platform.num_compute_units $irqs [current_project]
	set_property platform.design_intent.server_managed "false" [current_project]
	set_property platform.design_intent.external_host "false" [current_project]
	set_property platform.design_intent.datacenter "false" [current_project]
	set_property platform.uses_pr  "false" [current_project]
	set_property platform.extensible true [current_project]
	puts "INFO: Platform creation completed!"

	set_property platform.extensible true [current_project]
	
	# Add USER_COMMENTS on $design_name
	#set_property USER_COMMENTS.comment0 "An Example Versal Extensible Embedded Platform" [get_bd_designs $design_name]
	
	if { $irqs eq "15" } {
	
		if { $use_aie eq "true" } {
			
			set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to CIPS and memory controller settings
			\t --> AI Engine control path is connected to CIPS
			\t --> V++ will connect AI Engine data path automatically
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md}  [current_bd_design]
		} else {
			
			set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to CIPS and memory controller settings
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md}  [current_bd_design] 
		}
	
	} else {
	
		if { $use_aie eq "true" } {
			
			set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to CIPS and memory controller settings
			\t --> AI Engine control path is connected to CIPS
			\t --> V++ will connect AI Engine data path automatically
			\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
			\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md}  [current_bd_design]
		} else {
			
			set_property USER_COMMENTS.comment0 {\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
			\t Note:
			\t --> Board preset applied to CIPS and memory controller settings
			\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
			\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
			\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
			\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md}  [current_bd_design] 
		}
	}
	
		
	
	
	# Perform GUI Layout
 
	if { $irqs eq "15" } {
	
		if { $use_aie == "true" } {
		 
		   regenerate_bd_layout -layout_string {
			   "ActiveEmotionalView":"Default View",
			   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
				\t Note:
				\t --> Board preset applied to CIPS and memory controller
				\t --> AI Engine control path is connected to CIPS
				\t --> V++ will connect AI Engine data path automatically
				\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
				\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md",
			   "commentid":"comment_0|",
			   "font_comment_0":"14",
			   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
				#  -string -flagsOSRD
				preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
				",
			   "linktoobj_comment_0":"",
			   "linktotype_comment_0":"bd_design" }
		 
		 } else {
		  regenerate_bd_layout -layout_string {
			   "ActiveEmotionalView":"Default View",
			   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
				\t Note:
				\t --> Board preset applied to CIPS and memory controller
				\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
				\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md",
			   "commentid":"comment_0|",
			   "font_comment_0":"14",
			   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
				#  -string -flagsOSRD
				preplace cgraphic comment_0 place right -1750 -185 textcolor 4 linecolor 3
				",
			   "linktoobj_comment_0":"",
			   "linktotype_comment_0":"bd_design" }
		}
		
	} else {
	
		if { $use_aie == "true" } {
	 	   regenerate_bd_layout -layout_string {
			   "ActiveEmotionalView":"Default View",
			   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
				\t Note:
				\t --> Board preset applied to CIPS and memory controller
				\t --> AI Engine control path is connected to CIPS
				\t --> V++ will connect AI Engine data path automatically
				\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
				\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
				\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
				\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md",
			   "commentid":"comment_0|",
			   "font_comment_0":"14",
			   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
				#  -string -flagsOSRD
				preplace cgraphic comment_0 place right -1750 -200 textcolor 4 linecolor 3
				",
			   "linktoobj_comment_0":"",
			   "linktotype_comment_0":"bd_design" }
		 
		 } else {
		  regenerate_bd_layout -layout_string {
			   "ActiveEmotionalView":"Default View",
			   "comment_0":"\t \t ======================= >>>>>>>>> An Example Versal Extensible Embedded Platform <<<<<<<<< =======================
				\tNote:
				\t --> Board preset applied to CIPS and memory controller.
				\t --> BD has VIPs on the accelerator SmartConnect IPs because IPI platform can't handle export with no slaves on SmartConnect IP.
				\t \t \t \t \t \t \t Hence VIPs are there to have at least one slave on a smart connect
				\t --> Execute TCL command : launch_simulation -scripts_only ,to establish the sim_1 source set hierarchy after successful design creation.
				\t --> For Next steps, Refer to README.md https://github.com/Xilinx/XilinxCEDStore/tree/2023.1/ced/Xilinx/IPI/Versal_Extensible_Embedded_Platform/README.md",
			   "commentid":"comment_0|",
			   "font_comment_0":"14",
			   "guistr":"# # String gsaved with Nlview 7.0r4  2019-12-20 bk=1.5203 VDI=41 GEI=36 GUI=JA:10.0 TLS
				#  -string -flagsOSRD
				preplace cgraphic comment_0 place right -1750 -185 textcolor 4 linecolor 3
				",
			   "linktoobj_comment_0":"",
			   "linktotype_comment_0":"bd_design" }
		}
	}
 
  
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /CIPS_0]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /cips_noc]
	#set_property SELECTED_SIM_MODEL tlm [get_bd_cells /$additional_mem]
	set_property SELECTED_SIM_MODEL tlm [get_bd_cells /$default_mem]
	set_property preferred_sim_model tlm [current_project]
	
	set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wizard_0]
	save_bd_design
	validate_bd_design
	open_bd_design [get_bd_files $design_name]
	regenerate_bd_layout
	make_wrapper -files [get_files $design_name.bd] -top -import -quiet
	
	set TB_file [file join $currentDir test_bench tb.v]
	set_property SOURCE_SET sources_1 [get_filesets sim_1]
	# -flat imports all files into the imports folder without preserving their relative paths
	import_files -fileset  sim_1 -norecurse -flat $TB_file 
	set_property top tb [get_filesets sim_1]
    update_compile_order -fileset sim_1	
	

	puts "INFO: End of create_root_design"
}