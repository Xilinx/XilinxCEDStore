# ########################################################################
# Copyright (C) 2023, Advanced Micro Devices Inc - All rights reserved

# Licensed under the Apache License, Version 2.0 (the "License"). You may
# not use this file except in compliance with the License. A copy of the
# License is located at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
# ########################################################################

# ---------------------------------------------------------------------------
# Board / interface discovery helpers (no hardcoded board or interface names)
# ---------------------------------------------------------------------------

proc mbv_first_board_component {filter} {
    if {[catch {
        set comps [get_board_components -filter $filter]
        if {[llength $comps] > 0} {
            return [get_property COMPONENT_NAME [lindex $comps 0]]
        }
    }]} {}
    return ""
}

proc mbv_first_component_interface {pattern} {
    set lst [board::get_board_component_interfaces $pattern]
    if {[llength $lst] > 0} { return [lindex $lst 0] }
    return ""
}

proc mbv_first_part_interface {pattern} {
    set lst [board::get_board_part_interfaces $pattern]
    if {[llength $lst] > 0} { return [lindex [split $lst { }] 0] }
    return ""
}

proc mbv_build_board_context {fpga_part} {
    set uart_ifcs [get_board_component_interfaces -filter {BUSDEF_NAME == uart_rtl}]
    set has_lpddr5 [expr {[llength [board::get_board_part_interfaces *lpddr5*]] > 0}]
    dict create fpga_part       $fpga_part spartan_us_plus [regexp -nocase {^xcsu} $fpga_part] series_7        [regexp -nocase {^xc7}  $fpga_part] has_lpddr5      $has_lpddr5 multi_uart      [expr {[llength $uart_ifcs] > 1}] skip_top_xdc    $has_lpddr5 reset_ifc       [mbv_first_board_component {BUSDEF_NAME == reset_rtl}] sys_clock_ifc   [mbv_first_board_component {SUB_TYPE == system_clock}]
}

proc mbv_connect_board_reset {ip_pin diagram} {
    # get_board_component_interfaces returns interface NAME strings, not Tcl objects.
    # get_property COMPONENT_NAME on a plain string silently fails — use $ifc directly.
    # apply_board_connection -board_interface accepts the same interface name string
    # that apply_bd_automation Board_Interface uses, so this is consistent.
    # BUSDEF_NAME is an interface property; must use get_board_component_interfaces
    # (get_board_components has no BUSDEF_NAME property and always returns nothing).
    # Exclude:
    #   *phy*   — PHY output resets (gem0_phy_reset_out on SCU200, phy_reset_out on KC705)
    #   *pcie*  — PCIe perst_n (FPGA output, causes BoardRule 102-3 if used as reset source)
    #   *dummy* — SGMII Ethernet dummy PHY reset placeholder (dummy_port_in on VCU128/
    #             VCU129 and SCU200); the actual FPGA reset button is "reset".
    set ifc ""
    catch {
        set candidates [get_board_component_interfaces \
            -filter {BUSDEF_NAME == reset_rtl && NAME !~ *phy* && NAME !~ *pcie* && NAME !~ *dummy*}]
        if {[llength $candidates] > 0} { set ifc [lindex $candidates 0] }
    }
    if {$ifc eq ""} {
        catch {
            set candidates [get_board_component_interfaces \
                -filter {BUSDEF_NAME == reset_rtl && NAME !~ *dummy*}]
            if {[llength $candidates] > 0} { set ifc [lindex $candidates 0] }
        }
    }
    if {$ifc ne ""} {
        apply_board_connection -board_interface $ifc -ip_intf $ip_pin -diagram $diagram
    }
}

proc mbv_automation_board_reset {pin} {
    # Use get_board_component_interfaces (not get_board_components) because
    # BUSDEF_NAME is a property of the interface object, not the component.
    # Prefer the FPGA-input reset button; exclude:
    #   *phy*   — PHY output resets (gem0_phy_reset_out on SCU200, phy_reset_out on KC705)
    #   *pcie*  — PCIe perst_n (pcie_perstn on KC705/KCU105), output from FPGA, causes
    #             "BoardRule 102-3: Invalid Configuration value pcie_perstn"
    #   *dummy* — SGMII Ethernet dummy PHY reset placeholder (dummy_port_in on VCU128/
    #             VCU129); those boards expose this as reset_rtl but it is for the Ethernet
    #             PHY, not the processor reset. The actual FPGA reset button is "reset".
    set ifc ""
    catch {
        set candidates [get_board_component_interfaces \
            -filter {BUSDEF_NAME == reset_rtl && NAME !~ *phy* && NAME !~ *pcie* && NAME !~ *dummy*}]
        if {[llength $candidates] > 0} { set ifc [lindex $candidates 0] }
    }
    # Fall back: any reset_rtl interface that is not a PCIe/PHY/dummy output
    if {$ifc eq ""} {
        catch {
            set candidates [get_board_component_interfaces \
                -filter {BUSDEF_NAME == reset_rtl && NAME !~ *dummy*}]
            if {[llength $candidates] > 0} { set ifc [lindex $candidates 0] }
        }
    }
    if {$ifc ne ""} {
        apply_bd_automation -rule xilinx.com:bd_rule:board \
            -config [list Board_Interface [list $ifc] Manual_Source {Auto}] $pin
    }
}

proc mbv_automation_board_sys_clock {intf_pin} {
    set ifc [mbv_first_board_component {SUB_TYPE == system_clock}]
    if {$ifc eq ""} { set ifc [mbv_first_part_interface *sys*clock*] }
    if {$ifc ne ""} {
        apply_bd_automation -rule xilinx.com:bd_rule:board -config [list Board_Interface [list $ifc] Manual_Source {Auto}] $intf_pin
    }
}

proc mbv_automation_board_default_sysclk {intf_pin} {
    set ifc [mbv_first_part_interface *default*sysclk*]
    if {$ifc ne ""} {
        apply_bd_automation -rule xilinx.com:bd_rule:board -config [list Board_Interface [list $ifc] Manual_Source {Auto}] $intf_pin
    }
}

proc mbv_automation_ethernet_mgt_clk {pin} {
    set ifc [mbv_first_component_interface *sfp_mgt_clk*]
    if {$ifc eq ""} { set ifc [mbv_first_component_interface *sgmii_mgt_clk*] }
    if {$ifc ne ""} {
        apply_bd_automation -rule xilinx.com:bd_rule:board -config [list Board_Interface [list $ifc] Manual_Source {Auto}] $pin
    }
}

proc mbv_connect_qspi_flash {board_if diagram} {
    # kcu105 / vcu118 use STARTUPE3 (SPI_1); all other boards use external SPI pins (SPI_0).
    # The entire block is wrapped in a catch by the caller so any failure is absorbed
    # without leaving the Vivado error counter in a bad state.
    if {$board_if eq ""} { return }
    set board_name [get_property BOARD_NAME [current_board]]
    if {$board_name eq "kcu105" || $board_name eq "vcu118"} {
        apply_board_connection -board_interface $board_if \
            -ip_intf axi_quad_spi_0/SPI_1 -diagram $diagram
    } else {
        apply_board_connection -board_interface $board_if \
            -ip_intf axi_quad_spi_0/SPI_0 -diagram $diagram
    }
}

proc mbv_connect_gmii_ethernet {diagram inpt_var} {
    upvar $inpt_var inpt
    set gmii [mbv_first_component_interface *gmii*]
    if {$gmii eq ""} { return 0 }
    set mdio  [mbv_first_component_interface *mdio*]
    set phyrst [mbv_first_component_interface *phy_reset*]
    if {[get_bd_cells -quiet axi_ethernet_0] eq ""} {
        create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:* axi_ethernet_0
    }
    apply_board_connection -board_interface $gmii -ip_intf axi_ethernet_0/gmii -diagram $diagram
    if {$mdio ne ""} {
        apply_board_connection -board_interface $mdio -ip_intf axi_ethernet_0/mdio -diagram $diagram
    }
    if {$phyrst ne ""} {
        apply_board_connection -board_interface $phyrst -ip_intf axi_ethernet_0/phy_rst_n -diagram $diagram
    }
    set_property -dict [list CONFIG.RXMEM {32k} CONFIG.TXMEM {32k}] [get_bd_cells axi_ethernet_0]
    apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {FIFO_DMA {DMA} PHY_TYPE {GMII}} [get_bd_cells axi_ethernet_0]
    return 1
}

proc mbv_connect_sgmii_ethernet_board {diagram design_name} {
    set sgmii  [mbv_first_component_interface *sgmii*]
    if {$sgmii eq ""} { return 0 }
    set mdio   [mbv_first_component_interface *mdio*]
    set phyclk [mbv_first_component_interface *phyclk*]
    if {$phyclk eq ""} { set phyclk [mbv_first_component_interface *mgt_clk*] }
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0
    apply_board_connection -board_interface $sgmii -ip_intf axi_ethernet_0/sgmii -diagram $diagram
    if {$mdio ne ""} {
        apply_board_connection -board_interface $mdio -ip_intf axi_ethernet_0/mdio -diagram $diagram
    }
    if {$phyclk ne ""} {
        catch { apply_board_connection -board_interface $phyclk -ip_intf axi_ethernet_0/lvds_clk -diagram $diagram }
        catch { apply_board_connection -board_interface $phyclk -ip_intf axi_ethernet_0/mgt_clk  -diagram $diagram }
    }
    set ip [lindex [get_ips -quiet ${design_name}_axi_ethernet_0_0] 0]
    set phy_rst_cfg  [get_property CONFIG.PHYRST_BOARD_INTERFACE            $ip]
    set dummy_cfg    [get_property CONFIG.PHYRST_BOARD_INTERFACE_DUMMY_PORT $ip]
    if {$phy_rst_cfg ne "" && $phy_rst_cfg ne "Custom"} {
        set pr_if [mbv_first_component_interface *phy_reset*]
        if {$pr_if ne ""} {
            apply_board_connection -board_interface $pr_if -ip_intf axi_ethernet_0/phy_rst_n -diagram $diagram
        }
    } elseif {$dummy_cfg ne "" && $dummy_cfg ne "Custom"} {
        set dp_if [mbv_first_component_interface *dummy_port*]
        if {$dp_if ne ""} {
            apply_board_connection -board_interface $dp_if -ip_intf axi_ethernet_0/dummy_port_in -diagram $diagram
        }
    }
    apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config {PHY_TYPE {SGMII} FIFO_DMA {DMA}} [get_bd_cells axi_ethernet_0]
    return 1
}

proc mbv_resolve_uart_component {suffix} {
    foreach uart [get_board_component_interfaces -filter {BUSDEF_NAME == uart_rtl}] {
        if {[string match -nocase *${suffix}* $uart]} { return $uart }
    }
    return ""
}

# Fix: use format so $mem_int is substituted (was bug: {$mem_int} inside braces)
proc mbv_connect_axi_uartlite {idx diagram mem_int board_if inpt_var} {
    upvar $inpt_var inpt
    if {$board_if eq ""} { return }
    if {[get_bd_cells -quiet axi_uartlite_${idx}] eq ""} {
        create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_${idx}
    }
    set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells axi_uartlite_${idx}]
    # Guard: skip if UART interface already connected (preset branch may have done it)
    if {[get_bd_intf_nets -quiet -of [get_bd_intf_pins axi_uartlite_${idx}/UART]] eq ""} {
        apply_board_connection -board_interface $board_if \
            -ip_intf axi_uartlite_${idx}/UART -diagram $diagram
    }
    # Guard: skip S_AXI automation if already connected — prevents a dangling
    # master port on microblaze_riscv_0_axi_periph (e.g. M08_AXI on AC701)
    if {[get_bd_intf_nets -quiet -of [get_bd_intf_pins axi_uartlite_${idx}/S_AXI]] eq ""} {
        apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [format {
                Clk_master {%s (100 MHz)} Clk_slave {Auto} Clk_xbar {%s (100 MHz)}
                Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uartlite_%d/S_AXI}
                ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}
            } $mem_int $mem_int $idx] [get_bd_intf_pins axi_uartlite_${idx}/S_AXI]
    }
    set irq axi_uartlite_${idx}/interrupt
    if {[lsearch -exact $inpt $irq] < 0} { lappend inpt $irq }
}

proc mbv_add_scu200_uart_interfaces {diagram mem_int inpt_var} {
    upvar $inpt_var inpt
    puts "INFO: SCU200 UART mapping: UARTB->axi_uartlite_0, UARTC->axi_uartlite_1, UART0->axi_uartlite_2"
    mbv_connect_axi_uartlite 0 $diagram $mem_int [mbv_resolve_uart_component uartb] inpt
    mbv_connect_axi_uartlite 1 $diagram $mem_int [mbv_resolve_uart_component uartc] inpt
    mbv_connect_axi_uartlite 2 $diagram $mem_int [mbv_resolve_uart_component uart0] inpt
}

proc mbv_add_all_uart_interfaces {diagram mem_int inpt_var} {
    upvar $inpt_var inpt
    set uart_list [get_board_component_interfaces -filter {BUSDEF_NAME == uart_rtl}]
    set uart_cnt 0
    foreach uart $uart_list {
        mbv_connect_axi_uartlite $uart_cnt $diagram $mem_int $uart inpt
        incr uart_cnt
    }
}

proc mbv_write_ethernet_xdc_extras {fd} {
    catch {
        if {[llength [get_ports -quiet -filter {NAME =~ *sgmii*phyclk*}]]} {
            puts $fd "create_clock -period 1.6 \[get_ports -filter {NAME =~ *sgmii*phyclk*}\]"
        }
    }
    catch {
        if {[llength [get_ports -quiet -filter {NAME =~ *sgmii*mgt_clk*}]]} {
            puts $fd "create_clock -period 8 \[get_ports -filter {NAME =~ *sgmii*mgt_clk*}\]"
        }
    }
}

proc mbv_write_qspi_7series_xdc {fd} {
    puts $fd "set cclk_delay 6.7"
    puts $fd "set tco_max 7"
    puts $fd "set tco_min 1"
    puts $fd "set tsu 2"
    puts $fd "set th 3"
    puts $fd "set tdata_trace_delay_max 0.25"
    puts $fd "set tdata_trace_delay_min 0.25"
    puts $fd "set tclk_trace_delay_max 0.2"
    puts $fd "set tclk_trace_delay_min 0.2"
    puts $fd "set_max_delay 1.5 -from \[get_pins -hier *SCK_O_reg_reg/C\] -to \[get_pins -hier *USRCCLKO\] -datapath_only"
    puts $fd "set_min_delay 0.1 -from \[get_pins -hier *SCK_O_reg_reg/C\] -to \[get_pins -hier *USRCCLKO\]"
    puts $fd "create_generated_clock -name clk_sck -source \[get_pins -hierarchical *axi_quad_spi_0/ext_spi_clk\] \[get_pins -hierarchical *USRCCLKO\] -edges {3 5 7} -edge_shift \[list \$cclk_delay \$cclk_delay \$cclk_delay\]"
    puts $fd "set_input_delay -clock clk_sck -max \[expr \$tco_max + \$tdata_trace_delay_max + \$tclk_trace_delay_max\] \[get_ports spi_flash_io*io\] -clock_fall"
    puts $fd "set_input_delay -clock clk_sck -min \[expr \$tco_min + \$tdata_trace_delay_min + \$tclk_trace_delay_min\] \[get_ports spi_flash_io*io\] -clock_fall"
    puts $fd "set_multicycle_path 2 -setup -from clk_sck -to \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\]"
    puts $fd "set_multicycle_path 1 -hold -end -from clk_sck -to \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\]"
    puts $fd "set_output_delay -clock clk_sck -max \[expr \$tsu + \$tdata_trace_delay_max - \$tclk_trace_delay_min\] \[get_ports spi_flash_io*io\]"
    puts $fd "set_output_delay -clock clk_sck -min \[expr \$tdata_trace_delay_min -\$th - \$tclk_trace_delay_max\] \[get_ports spi_flash_io*io\]"
    puts $fd "set_multicycle_path 2 -setup -start -from \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\] -to clk_sck"
    puts $fd "set_multicycle_path 1 -hold -from \[get_clocks -of_objects \[get_pins -hierarchical */ext_spi_clk\]\] -to clk_sck"
}

# ---------------------------------------------------------------------------
# Helper: apply_bd_automation for a peripheral slave, substituting $mem_int.
# Fixes bug where {$mem_int (100 MHz)} inside braces was never expanded.
# ---------------------------------------------------------------------------
proc mbv_automate_peripheral {mem_int slave} {
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [format {
            Clk_master {%s (100 MHz)} Clk_slave {Auto} Clk_xbar {%s (100 MHz)}
            Master {/microblaze_riscv_0 (Periph)} Slave {%s}
            ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}
        } $mem_int $mem_int $slave] [get_bd_intf_pins $slave]
}

# ---------------------------------------------------------------------------
# Helper: assign LMB local-memory address segments (identical across presets).
# ---------------------------------------------------------------------------
proc mbv_assign_local_mem_addr {} {
    assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs microblaze_riscv_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
    assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs microblaze_riscv_0_axi_intc/S_AXI/Reg] -force
    assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Instruction] [get_bd_addr_segs microblaze_riscv_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
}

# ---------------------------------------------------------------------------
# Helper: create MBV core IPs and make common interface connections.
# Used by all non-automation (manual) preset paths.
#   template_id    : G_TEMPLATE_LIST value (1=microcontroller, 2=real-time, 7=linux)
#   has_fast_intc  : C_HAS_FAST value for axi_intc (0 or 1)
# ---------------------------------------------------------------------------
proc mbv_create_mbv_core {template_id has_fast_intc} {
    set_property -dict [list CONFIG.C_DEBUG_ENABLED {1} CONFIG.C_D_AXI         {1} CONFIG.C_D_LMB         {1} CONFIG.C_I_LMB         {1} CONFIG.G_TEMPLATE_LIST $template_id ] [get_bd_cells microblaze_riscv_0]

    create_hier_cell_microblaze_riscv_0_local_memory [current_bd_instance .] microblaze_riscv_0_local_memory

    set periph [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect microblaze_riscv_0_axi_periph]
    set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $periph

    set intc [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_riscv_0_axi_intc]
    set_property CONFIG.C_HAS_FAST $has_fast_intc $intc

    create_bd_cell -type ip -vlnv xilinx.com:ip:mdm_riscv mdm_1

    create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:* microblaze_riscv_0_xlconcat

    # Interface connections common to all manual paths
    connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/S00_AXI] [get_bd_intf_pins microblaze_riscv_0/M_AXI_DP]
    connect_bd_intf_net [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_riscv_0/DEBUG]
    connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/DLMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/DLMB]
    connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/ILMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/ILMB]
    connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/M00_AXI] [get_bd_intf_pins microblaze_riscv_0_axi_intc/s_axi]
    connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_intc/interrupt] [get_bd_intf_pins microblaze_riscv_0/INTERRUPT]
    connect_bd_net [get_bd_pins microblaze_riscv_0_xlconcat/dout] [get_bd_pins microblaze_riscv_0_axi_intc/intr]
}

# ---------------------------------------------------------------------------
# Helper: create clk_wiz_1 (differential) + rst_clk_wiz_1_100M.
# ---------------------------------------------------------------------------
proc mbv_create_clkwiz_and_rst {} {
    set clk_wiz [create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_1]
    set_property CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} $clk_wiz
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_clk_wiz_1_100M
}

# ---------------------------------------------------------------------------
# Hierarchical cell: MicroBlaze local memory (LMB + BRAM)
# Moved to top level — was incorrectly nested inside createDesign.
# ---------------------------------------------------------------------------
proc create_hier_cell_microblaze_riscv_0_local_memory {parentCell nameHier} {
    if {$parentCell eq "" || $nameHier eq ""} {
        catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_riscv_0_local_memory() - Empty argument(s)!"}
        return
    }
    set parentObj [get_bd_cells $parentCell]
    if {$parentObj eq ""} {
        catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
        return
    }
    if {[get_property TYPE $parentObj] ne "hier"} {
        catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <[get_property TYPE $parentObj]>. Expected <hier>."}
        return
    }
    set oldCurInst [current_bd_instance .]
    current_bd_instance $parentObj
    set hier_obj [create_bd_cell -type hier $nameHier]
    current_bd_instance $hier_obj

    create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
    create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB
    create_bd_pin -dir I -type clk LMB_Clk
    create_bd_pin -dir I -type rst SYS_Rst

    set dlmb_v10          [create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10]
    set ilmb_v10          [create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10]
    set dlmb_bram_if_cntlr [create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr]
    set ilmb_bram_if_cntlr [create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr]
    set_property CONFIG.C_ECC {0} $dlmb_bram_if_cntlr
    set_property CONFIG.C_ECC {0} $ilmb_bram_if_cntlr

    set lmb_bram [create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen lmb_bram]
    set_property -dict [list CONFIG.Memory_Type     {True_Dual_Port_RAM} CONFIG.use_bram_block  {BRAM_Controller} ] $lmb_bram

    connect_bd_intf_net [get_bd_intf_pins dlmb_v10/LMB_M]           [get_bd_intf_pins DLMB]
    connect_bd_intf_net [get_bd_intf_pins dlmb_v10/LMB_Sl_0]        [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB]
    connect_bd_intf_net [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
    connect_bd_intf_net [get_bd_intf_pins ilmb_v10/LMB_M]           [get_bd_intf_pins ILMB]
    connect_bd_intf_net [get_bd_intf_pins ilmb_v10/LMB_Sl_0]        [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB]
    connect_bd_intf_net [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

    connect_bd_net [get_bd_pins SYS_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst]
    connect_bd_net [get_bd_pins LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk]

    current_bd_instance $oldCurInst
}

# ---------------------------------------------------------------------------
# create_root_design: builds the full block design for the chosen preset.
# Moved to top level (was nested inside createDesign — caused proc-redefine
# warnings on repeated CED invocations).
# ---------------------------------------------------------------------------
proc create_root_design {parentCell design_name options} {

    # Resolve preset from the options dict (safe dict get with default).
    # Fix: was using fragile lsearch on dict; dict get is correct.
    set preset "Microcontroller"
    if {[dict exists $options Preset.VALUE]} {
        set preset [dict get $options Preset.VALUE]
    }

    # Normalise preset name: tolerate alternate spellings and casing.
    switch -nocase -glob $preset {
        "Microcontroller"     { set preset "Microcontroller"     }
        "Real-time_Processor" -
        "Real_time_Processor" -
        "Realtime_Processor"  { set preset "Real-time_Processor" }
    }

    set board_part  [get_property NAME      [current_board_part]]
    set board_name  [get_property BOARD_NAME [current_board]]
    set fpga_part   [get_property PART_NAME  [current_board_part]]

    set mbv_is_scu200       [regexp -nocase {scu200} $board_name]
    set mbv_is_scu35        [regexp -nocase {scu35}  $board_name]
    set mbv_spartan_us_plus [expr {$mbv_is_scu200 || $mbv_is_scu35}]
    set mbv_ctx             [mbv_build_board_context $fpga_part]
    set mbv_series_7        [dict get $mbv_ctx series_7]

    # Determine memory controller type from FPGA part
    set mem_ctrl ""
    set mem_int  ""
    if {[regexp {xcsu200p} $fpga_part]} {
        set mem_ctrl ddr4
        set mem_int  /ddr4_0/addn_ui_clkout1
    } elseif {[regexp {xcvu|xcku} $fpga_part]} {
        set mem_ctrl ddr4
        set mem_int  /ddr4_0/addn_ui_clkout1
    } else {
        set mem_ctrl ddr3
        set mem_int  /mig_7series_0/ui_addn_clk_0
    }

    puts "INFO: $board_part is selected"

    # Board interface variables (empty = not present on this board)
    set uart_board_interface      ""
    set iic_board_interface       ""
    set qspi_flash_board_interface ""
    set bpi_flash_board_interface  ""
    set ddr3_board_interface      ""
    set ddr3_board_interface_1    ""
    set ddr4_board_interface      ""
    set ddr4_board_interface_1    ""
    set lpddrmc_board_interface   ""
    set lpddrmc_board_interface_1 ""
    set ethenet_board_interface   ""
    set sfp_board_interface       ""
    set rgmii_board_interface     ""
    set inpt                      ""
    set phy_rst                   ""

    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0
    lappend inpt axi_timer_0/interrupt

    # UART — Fix: narrow catch to only the board query, not cell creation
    if {!$mbv_is_scu200} {
        catch { set uart_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==uart}] 0]] }
        if {$uart_board_interface ne ""} {
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0
            apply_board_connection -board_interface $uart_board_interface -ip_intf axi_uartlite_0/UART -diagram $design_name
            set_property -dict [list CONFIG.C_BAUDRATE {115200}] [get_bd_cells axi_uartlite_0]
            lappend inpt axi_uartlite_0/interrupt
        }
    }

    # IIC — Fix: narrow catch
    catch { set iic_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==mux}] 0]] }
    if {$iic_board_interface ne ""} {
        create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0
        apply_board_connection -board_interface $iic_board_interface -ip_intf axi_iic_0/IIC -diagram $design_name
        lappend inpt axi_iic_0/iic2intc_irpt
    }

    # QSPI flash — mirror HEAD approach: broad catch over the whole block so any
    # board-connection failure is silently absorbed.  Downstream AXI/clkrst
    # automations are gated on $qspi_flash_board_interface being non-empty, not on
    # the board connection succeeding, so ext_spi_clk and AXI_LITE are always
    # connected when the board has a QSPI component (matches HEAD behavior).
    catch {
        set qspi_flash_board_interface [get_property COMPONENT_NAME \
            [lindex [get_board_components -filter {SUB_TYPE==memory_flash_qspi}] 0]]
        if {$qspi_flash_board_interface ne ""} {
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0
            mbv_connect_qspi_flash $qspi_flash_board_interface $design_name
            lappend inpt axi_quad_spi_0/ip2intc_irpt
        }
    }

    # BPI flash — Fix: narrow catch
    catch { set bpi_flash_board_interface [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==memory_flash_bpi}] 0]] }
    if {$bpi_flash_board_interface ne ""} {
        create_bd_cell -type ip -vlnv xilinx.com:ip:axi_emc axi_emc_0
        apply_board_connection -board_interface $bpi_flash_board_interface -ip_intf axi_emc_0/EMC_INTF -diagram $design_name
    }

    create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_riscv microblaze_riscv_0

    set ddr3_board_interface   [board::get_board_part_interfaces *ddr3*]
    set ddr3_board_interface_1 [lindex [split $ddr3_board_interface { }] 0]
    set ddr4_board_interface   [board::get_board_part_interfaces *ddr4*]
    set ddr4_board_interface_1 [lindex [split $ddr4_board_interface { }] 0]
    set lpddrmc_board_interface   [board::get_board_part_interfaces *lpddr5_sdram*]
    set lpddrmc_board_interface_1 [lindex [split $lpddrmc_board_interface { }] 0]

    ##########################################################################
    # MICROCONTROLLER PRESET
    ##########################################################################
    if {$preset eq "Microcontroller"} {
        puts "INFO: Microcontroller preset enabled"

        if {$mbv_spartan_us_plus} {
            puts "INFO: SpartanUS+ Board Selected"

            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0
            mbv_connect_board_reset proc_sys_reset_0/ext_reset $design_name

            set_property -dict [list CONFIG.C_DEBUG_ENABLED {1} CONFIG.C_D_AXI         {1} CONFIG.C_D_LMB         {1} CONFIG.C_I_LMB         {1} CONFIG.G_TEMPLATE_LIST {1} ] [get_bd_cells microblaze_riscv_0]

            apply_bd_automation -rule xilinx.com:bd_rule:microblaze_riscv -config {axi_intc {0} axi_periph {Enabled} cache {None} clk {New Clocking Wizard} debug_module {Debug Enabled} ecc {None} local_mem {16KB} preset {None}} [get_bd_cells microblaze_riscv_0]
            mbv_automation_board_reset    [get_bd_pins clk_wiz_1/reset]
            mbv_automation_board_sys_clock [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]

            set microblaze_riscv_0_axi_periph [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect microblaze_riscv_0_axi_periph]
            set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $microblaze_riscv_0_axi_periph

            set microblaze_riscv_0_axi_intc [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_riscv_0_axi_intc]
            set_property CONFIG.C_HAS_FAST {1} $microblaze_riscv_0_axi_intc

            create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:* microblaze_riscv_0_xlconcat

            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/S00_AXI] [get_bd_intf_pins microblaze_riscv_0/M_AXI_DP]
            connect_bd_intf_net [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_riscv_0/DEBUG]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/DLMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/DLMB]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/ILMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/ILMB]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/M00_AXI] [get_bd_intf_pins microblaze_riscv_0_axi_intc/s_axi]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_intc/interrupt] [get_bd_intf_pins microblaze_riscv_0/INTERRUPT]

            connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
            connect_bd_net [get_bd_pins microblaze_riscv_0_xlconcat/dout] [get_bd_pins microblaze_riscv_0_axi_intc/intr]
            connect_bd_net [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
            connect_bd_net [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst] [get_bd_pins proc_sys_reset_0/mb_reset]

            mbv_assign_local_mem_addr
            assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs microblaze_riscv_0_axi_intc/S_AXI/Reg] -force

            if {$qspi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}} [get_bd_pins axi_quad_spi_0/ext_spi_clk]
            }
            if {$bpi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins axi_emc_0/rdclk]
            }
            if {$iic_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_iic_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_iic_0/S_AXI]
            }
            if {$uart_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_uartlite_0/S_AXI]
            }
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_timer_0/S_AXI]

            create_bd_cell -type ip -vlnv xilinx.com:ip:pmcbridge:* pmcbridge_0
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/pmcbridge_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins pmcbridge_0/S_AXI]

        } else {
            # General Microcontroller (7-series / UltraScale+, no SPU)
            mbv_create_mbv_core 1 1

            set sys_diff_clock [get_property COMPONENT_NAME [lindex [get_board_components -filter {SUB_TYPE==system_clock}] 0]]
            mbv_create_clkwiz_and_rst
            apply_board_connection -board_interface $sys_diff_clock -ip_intf /clk_wiz_1/CLK_IN1_D -diagram $design_name
            mbv_automation_board_reset [get_bd_pins clk_wiz_1/reset]
            mbv_automation_board_reset [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
            set_property -dict [list CONFIG.CLKOUT2_USED                {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ  {50} CONFIG.MMCM_CLKOUT1_DIVIDE         {20} CONFIG.NUM_OUT_CLKS                {2} CONFIG.CLKOUT2_JITTER              {129.198} CONFIG.CLKOUT2_PHASE_ERROR         {89.971} ] [get_bd_cells clk_wiz_1]

            connect_bd_net [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
            connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
            connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
            connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset] [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
            connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/mb_reset] [get_bd_pins microblaze_riscv_0/Reset] [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst]
            connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn]

            mbv_assign_local_mem_addr

            if {$qspi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}} [get_bd_pins axi_quad_spi_0/ext_spi_clk]
            }
            if {$bpi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins axi_emc_0/rdclk]
            }
            if {$iic_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_iic_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_iic_0/S_AXI]
            }
            if {$uart_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_uartlite_0/S_AXI]
            }
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_timer_0/S_AXI]
        }

    ##########################################################################
    # REAL-TIME PROCESSOR PRESET
    ##########################################################################
    } elseif {$preset eq "Real-time_Processor"} {
        puts "INFO: Real-time_Processor preset enabled"

        if {$mbv_is_scu200} {
            # SCU200: Real-time with LPDDR5.
            # Fix: this path was previously unreachable dead code (was inside
            # else{spartan_us_plus} but scu200 implies spartan_us_plus).
            puts "INFO: SCU200 board — Real-time with LPDDR5"
            set mem_int /clk_wiz_1/clk_out1

            mbv_create_mbv_core 2 0
            mbv_create_clkwiz_and_rst

            mbv_automation_board_sys_clock [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
            mbv_automation_board_reset     [get_bd_pins clk_wiz_1/reset]
            mbv_automation_board_reset     [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
            apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
            # clk_wiz_1/locked must drive dcm_locked so proc_sys_reset releases after PLL locks
            connect_bd_net [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]

            connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset] [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
            connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn]
            connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]

            set_property name microblaze_riscv_0_Clk [get_bd_nets clk_wiz_1_clk_out1]
            connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk]

            if {$lpddrmc_board_interface_1 ne ""} {
                create_bd_cell -type ip -vlnv xilinx.com:ip:lpddrmc lpddrmc_0
                apply_board_connection -board_interface $lpddrmc_board_interface_1 -ip_intf lpddrmc_0/LPDDR5 -diagram $design_name
                set def_clk1 [lindex [board::get_board_part_interfaces *default*] 1]
                if {$def_clk1 ne ""} {
                    apply_board_connection -board_interface $def_clk1 -ip_intf lpddrmc_0/SYS_CLK -diagram $design_name
                }
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Cached)} Slave {/lpddrmc_0/S0_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}} [get_bd_intf_pins lpddrmc_0/S0_AXI]
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Cached)} Slave {/lpddrmc_0/S1_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}} [get_bd_intf_pins lpddrmc_0/S1_AXI]
                set_property CONFIG.LPDDR_ADDRESS_BLOCK_BASEADDR 0x80000000 [get_bd_cells /lpddrmc_0]
                set_property CONFIG.USER_XSDB_INTF_EN TRUE [get_bd_cells lpddrmc_0]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins lpddrmc_0/dbg_apb_clk]
                connect_bd_net [get_bd_pins lpddrmc_0/apb_rst_n] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
            }

            create_bd_cell -type ip -vlnv xilinx.com:ip:pmcbridge:* pmcbridge_0
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/pmcbridge_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins pmcbridge_0/S_AXI]

            # Peripheral AXI connections for SCU200 Real-time
            # (axi_timer_0 / axi_iic_0 / axi_quad_spi_0 cells were created
            #  before the preset branch; connect them to the periph bus here)
            if {$qspi_flash_board_interface ne ""} {
                mbv_automate_peripheral $mem_int /axi_quad_spi_0/AXI_LITE
                set_property -dict [list CONFIG.CLKOUT2_USED               {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} CONFIG.MMCM_CLKOUT1_DIVIDE        {20} CONFIG.NUM_OUT_CLKS               {2} ] [get_bd_cells clk_wiz_1]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}} [get_bd_pins axi_quad_spi_0/ext_spi_clk]
            }
            if {$bpi_flash_board_interface ne ""} {
                mbv_automate_peripheral $mem_int /axi_emc_0/S_AXI_MEM
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins axi_emc_0/rdclk]
            }
            if {$iic_board_interface ne ""} {
                mbv_automate_peripheral $mem_int /axi_iic_0/S_AXI
            }
            mbv_automate_peripheral $mem_int /axi_timer_0/S_AXI

            delete_bd_objs [get_bd_addr_segs] [get_bd_addr_segs -excluded]
            assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] [get_bd_addr_segs microblaze_riscv_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
            assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Instruction] [get_bd_addr_segs microblaze_riscv_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
            assign_bd_address

        } elseif {$mbv_is_scu35} {
            # SCU35: automation-based Real-time (no external DDR, BRAM only)
            puts "INFO: SCU35 board — Real-time with automation"

            create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0
            mbv_connect_board_reset proc_sys_reset_0/ext_reset $design_name

            set_property -dict [list CONFIG.C_DEBUG_ENABLED {1} CONFIG.C_D_AXI         {1} CONFIG.C_D_LMB         {1} CONFIG.C_I_LMB         {1} CONFIG.C_USE_DCACHE    {0} CONFIG.C_USE_ICACHE    {0} CONFIG.G_TEMPLATE_LIST {2} ] [get_bd_cells microblaze_riscv_0]

            apply_bd_automation -rule xilinx.com:bd_rule:microblaze_riscv -config {axi_intc {0} axi_periph {Enabled} cache {None} clk {New Clocking Wizard} debug_module {Debug Enabled} ecc {None} local_mem {16KB} preset {None}} [get_bd_cells microblaze_riscv_0]
            mbv_automation_board_reset    [get_bd_pins clk_wiz_1/reset]
            mbv_automation_board_sys_clock [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]

            set microblaze_riscv_0_axi_periph [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect microblaze_riscv_0_axi_periph]
            set_property -dict [list CONFIG.NUM_SI {1} CONFIG.NUM_MI {1}] $microblaze_riscv_0_axi_periph

            set microblaze_riscv_0_axi_intc [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_riscv_0_axi_intc]
            set_property CONFIG.C_HAS_FAST {0} $microblaze_riscv_0_axi_intc

            create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:* microblaze_riscv_0_xlconcat

            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/S00_AXI] [get_bd_intf_pins microblaze_riscv_0/M_AXI_DP]
            connect_bd_intf_net [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_riscv_0/DEBUG]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/DLMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/DLMB]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/ILMB] [get_bd_intf_pins microblaze_riscv_0_local_memory/ILMB]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_periph/M00_AXI] [get_bd_intf_pins microblaze_riscv_0_axi_intc/s_axi]
            connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0_axi_intc/interrupt] [get_bd_intf_pins microblaze_riscv_0/INTERRUPT]

            connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk]
            connect_bd_net [get_bd_pins microblaze_riscv_0_xlconcat/dout] [get_bd_pins microblaze_riscv_0_axi_intc/intr]
            connect_bd_net [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]

            mbv_assign_local_mem_addr

            if {$qspi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}} [get_bd_pins axi_quad_spi_0/ext_spi_clk]
            }
            if {$bpi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
                apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/clk_wiz_1/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}} [get_bd_pins axi_emc_0/rdclk]
            }
            if {$iic_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_iic_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_iic_0/S_AXI]
            }
            if {$uart_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_uartlite_0/S_AXI]
            }
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_timer_0/S_AXI]

            create_bd_cell -type ip -vlnv xilinx.com:ip:pmcbridge:* pmcbridge_0
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/pmcbridge_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins pmcbridge_0/S_AXI]

        } else {
            # General Real-time (7-series DDR3, UltraScale+ DDR4, or BRAM fallback)
            if {$mem_ctrl ne "ddr4"} {
                # DDR3 / 7-series path
                if {$ddr3_board_interface ne ""} {
                    create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series mig_7series_0
                    apply_board_connection -board_interface $ddr3_board_interface_1 -ip_intf mig_7series_0/mig_ddr_interface -diagram $design_name
                }
                mbv_create_mbv_core 2 [expr {$mbv_series_7 ? 0 : 1}]

                set rst_mig [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_mig_7series_0_100M]

                connect_bd_net [get_bd_pins rst_mig_7series_0_100M/bus_struct_reset] [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
                connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_mig_7series_0_100M/mb_debug_sys_rst]
                connect_bd_net [get_bd_pins rst_mig_7series_0_100M/peripheral_aresetn] [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn]

                if {$mbv_series_7} {
                    connect_bd_net [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] [get_bd_pins rst_mig_7series_0_100M/slowest_sync_clk]
                    connect_bd_net [get_bd_pins rst_mig_7series_0_100M/mb_reset] [get_bd_pins microblaze_riscv_0/Reset]
                } else {
                    connect_bd_net [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] [get_bd_pins rst_mig_7series_0_100M/slowest_sync_clk]
                    connect_bd_net [get_bd_pins rst_mig_7series_0_100M/mb_reset] [get_bd_pins microblaze_riscv_0/Reset] [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst]
                }

                mbv_assign_local_mem_addr

                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_7series_0/ui_clk (200 MHz)} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Cached)} Slave {/mig_7series_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}} [get_bd_intf_pins mig_7series_0/S_AXI]
                mbv_automation_board_reset [get_bd_pins mig_7series_0/sys_rst]
                connect_bd_net [get_bd_pins mig_7series_0/ui_clk_sync_rst] [get_bd_pins rst_mig_7series_0_100M/ext_reset_in]

            } elseif {$ddr4_board_interface_1 ne ""} {
                # DDR4 path (UltraScale+)
                create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0
                apply_board_connection -board_interface $ddr4_board_interface_1 -ip_intf ddr4_0/C0_DDR4 -diagram $design_name

                mbv_create_mbv_core 2 1

                set rst_ddr4 [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_100M]

                connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_ddr4_0_100M/mb_debug_sys_rst]
                connect_bd_net [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk] [get_bd_pins rst_ddr4_0_100M/slowest_sync_clk]
                connect_bd_net [get_bd_pins rst_ddr4_0_100M/bus_struct_reset] [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
                connect_bd_net [get_bd_pins rst_ddr4_0_100M/mb_reset] [get_bd_pins microblaze_riscv_0/Reset] [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst]
                connect_bd_net [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn]

                mbv_assign_local_mem_addr

                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Cached)} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}} [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]

                set ddr_sys_clk [get_property CONFIG.System_Clock [lindex [get_ips -quiet ${design_name}_ddr4_0_0] 0]]
                if {$ddr_sys_clk eq "No_Buffer"} {
                    set_property -dict [list CONFIG.System_Clock {Differential}] [get_bd_cells ddr4_0]
                }
                set def_clk [lindex [board::get_board_part_interfaces *default*] 0]
                apply_board_connection -board_interface $def_clk -ip_intf "ddr4_0/C0_SYS_CLK*" -diagram $design_name
                mbv_automation_board_reset [get_bd_pins ddr4_0/sys_rst]
                apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface {Custom} Manual_Source {/ddr4_0/c0_ddr4_ui_clk_sync_rst (ACTIVE_HIGH)}} [get_bd_pins rst_ddr4_0_100M/ext_reset_in]

                set s_axi_ctrl [get_property CONFIG.C0.DDR4_Ecc [lindex [get_ips -quiet ${design_name}_ddr4_0_0] 0]]
                if {$s_axi_ctrl eq "true"} {
                    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (333 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/ddr4_0/C0_DDR4_S_AXI_CTRL} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI_CTRL]
                }

            } else {
                # Fallback: BRAM-only Real-time (no DDR board interface)
                set mem_int /clk_wiz_1/clk_out1
                mbv_create_mbv_core 2 1
                mbv_create_clkwiz_and_rst

                mbv_automation_board_default_sysclk [get_bd_intf_pins clk_wiz_1/CLK_IN1_D]
                mbv_automation_board_reset [get_bd_pins clk_wiz_1/reset]
                mbv_automation_board_reset [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]

                connect_bd_net [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
                connect_bd_net [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
                connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins microblaze_riscv_0/Clk] [get_bd_pins microblaze_riscv_0_axi_periph/aclk] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_riscv_0_axi_intc/processor_clk] [get_bd_pins microblaze_riscv_0_local_memory/LMB_Clk]
                connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset] [get_bd_pins microblaze_riscv_0_local_memory/SYS_Rst]
                connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/mb_reset] [get_bd_pins microblaze_riscv_0/Reset] [get_bd_pins microblaze_riscv_0_axi_intc/processor_rst]
                connect_bd_net [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins microblaze_riscv_0_axi_periph/aresetn] [get_bd_pins microblaze_riscv_0_axi_intc/s_axi_aresetn]

                mbv_assign_local_mem_addr

                create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smartconnect_0
                create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_0
                set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_smartconnect_0]
                connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/M_AXI_DC] -boundary_type upper [get_bd_intf_pins axi_smartconnect_0/S00_AXI]
                connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/M_AXI_IC] -boundary_type upper [get_bd_intf_pins axi_smartconnect_0/S01_AXI]
                connect_bd_net [get_bd_pins axi_smartconnect_0/aresetn] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn]
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Cached)} Slave {/axi_bram_ctrl_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smartconnect_0} master_apm {0}} [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
                apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto"} [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
                apply_bd_automation -rule xilinx.com:bd_rule:bram_cntlr -config {BRAM "Auto"} [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTB]
                assign_bd_address
                set_property range 1M [get_bd_addr_segs {microblaze_riscv_0/Data/SEG_axi_bram_ctrl_0_Mem0}]
                set_property range 1M [get_bd_addr_segs {microblaze_riscv_0/Instruction/SEG_axi_bram_ctrl_0_Mem0}]
            }

            if {$qspi_flash_board_interface ne ""} {
                mbv_automate_peripheral $mem_int /axi_quad_spi_0/AXI_LITE
                if {$mem_ctrl ne "ddr4"} {
                    apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {New Clocking Wizard} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}} [get_bd_pins axi_quad_spi_0/ext_spi_clk]
                    set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.MMCM_CLKOUT0_DIVIDE_F      {20.000} CONFIG.CLKOUT1_JITTER              {151.636} ] [get_bd_cells clk_wiz]
                    set_property -dict [list CONFIG.PRIM_SOURCE {No_buffer}] [get_bd_cells clk_wiz]
                    connect_bd_net [get_bd_pins clk_wiz/reset] [get_bd_pins mig_7series_0/ui_clk_sync_rst]
                    apply_bd_automation -rule xilinx.com:bd_rule:board -config {Clk {/mig_7series_0/ui_addn_clk_0 (100 MHz)} Manual_Source {Auto}} [get_bd_pins clk_wiz/clk_in1]
                } elseif {$ddr4_board_interface_1 ne ""} {
                    set_property -dict [list CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {50}] [get_bd_cells ddr4_0]
                    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
                    apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk {/ddr4_0/addn_ui_clkout2 (50 MHz)} Freq {50} Ref_Clk0 {None} Ref_Clk1 {None} Ref_Clk2 {None}} [get_bd_pins axi_quad_spi_0/ext_spi_clk]
                } else {
                    set_property -dict [list CONFIG.CLKOUT2_USED                {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ  {50.000} CONFIG.MMCM_CLKOUT1_DIVIDE         {20} CONFIG.NUM_OUT_CLKS                {2} CONFIG.CLKOUT2_JITTER              {148.677} CONFIG.CLKOUT2_PHASE_ERROR         {98.575} ] [get_bd_cells clk_wiz_1]
                }
            }
            if {$bpi_flash_board_interface ne ""} {
                apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/mig_7series_0/ui_clk (100 MHz)} Clk_slave {Auto} Clk_xbar {/mig_7series_0/ui_clk (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
                connect_bd_net [get_bd_pins axi_emc_0/rdclk] [get_bd_pins mig_7series_0/ui_addn_clk_0]
            }
            # Fix: use mbv_automate_peripheral — was {$mem_int} (not expanded)
            if {$iic_board_interface ne ""}  { mbv_automate_peripheral $mem_int /axi_iic_0/S_AXI }
            if {$uart_board_interface ne ""} { mbv_automate_peripheral $mem_int /axi_uartlite_0/S_AXI }
            mbv_automate_peripheral $mem_int /axi_timer_0/S_AXI

            # XDC constraints
            set proj_dir  [get_property DIRECTORY [current_project]]
            set proj_name [get_property NAME      [current_project]]
            file mkdir $proj_dir/$proj_name.srcs/constrs_1/constrs
            set fd [open $proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc w]
            if {[get_ips -quiet ${design_name}_ddr4_0_0] ne {}} {
                puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */addn_ui_clkout1}\]"
                puts $fd "set_property CLOCK_DELAY_GROUP ddr_clk_grp \[get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}\]"
            }
            close $fd
            if {!$mbv_is_scu200} {
                add_files -fileset constrs_1 [list "$proj_dir/$proj_name.srcs/constrs_1/constrs/top.xdc"]
            }
        }


    } else {
        puts "ERROR: Invalid preset option: '$preset' (expected Microcontroller or Real-time_Processor)"
    }
    ##########################################################################
    # Common post-preset: GPIO, extra IIC, UART, interrupt concat, validate
    ##########################################################################

    # GPIO
    set gpios_list [get_board_component_interfaces -filter {BUSDEF_NAME == gpio_rtl}]
    set gpio_cnt 0
    foreach gpio $gpios_list {
        incr gpio_cnt
        if {$gpio_cnt % 2 == 1} {
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_[expr {$gpio_cnt / 2}]
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_riscv_0 (Periph)" Clk "Auto"} [get_bd_intf_pins axi_gpio_[expr {$gpio_cnt / 2}]/S_AXI]
            apply_board_connection -board_interface $gpio -ip_intf "axi_gpio_[expr {$gpio_cnt / 2}]/GPIO" -diagram $design_name
        } else {
            apply_board_connection -board_interface $gpio -ip_intf "axi_gpio_[expr {($gpio_cnt - 1) / 2}]/GPIO2" -diagram $design_name
        }
    }

    # Additional IIC channels (iic_cnt 0 already connected above if present)
    set iic_list [get_board_component_interfaces -filter {BUSDEF_NAME == iic_rtl}]
    set iic_cnt 0
    foreach iic $iic_list {
        if {$iic_cnt != 0} {
            create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_${iic_cnt}
            apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Clk_master {/clk_wiz_1/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_1/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_iic_${iic_cnt}/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}} [get_bd_intf_pins axi_iic_${iic_cnt}/S_AXI]
            apply_board_connection -board_interface $iic -ip_intf "axi_iic_${iic_cnt}/IIC" -diagram $design_name
            lappend inpt axi_iic_${iic_cnt}/iic2intc_irpt
        } else {
            apply_board_connection -board_interface $iic -ip_intf axi_iic_${iic_cnt}/IIC -diagram $design_name
        }
        incr iic_cnt
    }

    # UART channels
    if {$mbv_is_scu200} {
        mbv_add_scu200_uart_interfaces $design_name $mem_int inpt
    } else {
        mbv_add_all_uart_interfaces $design_name $mem_int inpt
    }

    # Wire interrupt concat inputs
    set int_num [llength $inpt]
    set_property -dict [list CONFIG.NUM_PORTS $int_num] [get_bd_cells microblaze_riscv_0_xlconcat]
    set i 0
    foreach item $inpt {
        connect_bd_net [get_bd_pins $item] [get_bd_pins /microblaze_riscv_0_xlconcat/In$i]
        incr i
    }

    # Rename xlconcat to ilconcat per CED naming convention
    set_property name microblaze_riscv_0_ilconcat [get_bd_cells microblaze_riscv_0_xlconcat]

    regenerate_bd_layout

    if {$bpi_flash_board_interface ne ""} {
        set_property range 128M [get_bd_addr_segs {microblaze_riscv_0/Data/SEG_axi_emc_0_Mem0}]
    }

    validate_bd_design
    make_wrapper -files [get_files $design_name.bd] -top -import

    puts "INFO: End of create_root_design"
}

# ---------------------------------------------------------------------------
# createDesign: CED framework entry point.
# ---------------------------------------------------------------------------
proc createDesign {design_name options} {
    create_root_design "" $design_name $options
    open_bd_design [get_bd_files $design_name]
}
