
################################################################
# This is a generated script based on design: TMR_Microblaze
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################
proc createDesign {design_name options} {

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORT1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  create_bd_intf_pin -mode MirroredSlave -vlnv xilinx.com:interface:lmb_rtl:1.0 LMB_Sl_1


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]
  set_property -dict [ list \
   CONFIG.C_LMB_NUM_SLAVES {2} \
 ] $dlmb_v10

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins LMB_Sl_1] [get_bd_intf_pins dlmb_v10/LMB_Sl_1]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins BRAM_PORT] [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins BRAM_PORTA] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins BRAM_PORT1] [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORT1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  create_bd_intf_pin -mode MirroredSlave -vlnv xilinx.com:interface:lmb_rtl:1.0 LMB_Sl_1


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]
  set_property -dict [ list \
   CONFIG.C_LMB_NUM_SLAVES {2} \
 ] $dlmb_v10

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins LMB_Sl_1] [get_bd_intf_pins dlmb_v10/LMB_Sl_1]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins BRAM_PORT] [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins BRAM_PORTA] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins BRAM_PORT1] [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORT

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORT1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  create_bd_intf_pin -mode MirroredSlave -vlnv xilinx.com:interface:lmb_rtl:1.0 LMB_Sl_1


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 dlmb_v10 ]
  set_property -dict [ list \
   CONFIG.C_LMB_NUM_SLAVES {2} \
 ] $dlmb_v10

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins LMB_Sl_1] [get_bd_intf_pins dlmb_v10/LMB_Sl_1]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins BRAM_PORT] [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins BRAM_PORTA] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins BRAM_PORT1] [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins lmb_bram/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: MB3
proc create_hier_cell_MB3 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_MB3() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1_3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1_4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1_5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2_6

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2_7

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2_8

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_15

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_16

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_17

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_mb3_ds

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_mb3_pb

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_mb3_rs

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 IIC1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 IIC2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M08_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 MB3_led_8bits

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI6

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI7

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI8

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI9

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI10

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI11

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI12

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:mbtrace_rtl:2.0 TRACE

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:mbtrace_rtl:2.0 Trace1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:mbtrace_rtl:2.0 Trace2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 UART1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 UART2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart1


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir O Fatal_3
  create_bd_pin -dir I -from 142 -to 0 From_TMR_Manager_1
  create_bd_pin -dir I -from 142 -to 0 From_TMR_Manager_2
  create_bd_pin -dir I -from 0 -to 0 In0
  create_bd_pin -dir I -from 0 -to 0 In1
  create_bd_pin -dir I -from 0 -to 0 In2
  create_bd_pin -dir I -from 0 -to 0 In3
  create_bd_pin -dir I -from 0 -to 0 In5
  create_bd_pin -dir I -from 0 -to 0 In8
  create_bd_pin -dir I -from 0 -to 4095 LOCKSTEP_Slave_In
  create_bd_pin -dir I SEM_classification
  create_bd_pin -dir I SEM_correction
  create_bd_pin -dir I SEM_detect_only
  create_bd_pin -dir I SEM_diagnostic_scan
  create_bd_pin -dir I SEM_essential
  create_bd_pin -dir I SEM_heartbeat
  create_bd_pin -dir O SEM_heartbeat_expired_3
  create_bd_pin -dir I SEM_initialization
  create_bd_pin -dir I SEM_injection
  create_bd_pin -dir I SEM_observation
  create_bd_pin -dir I SEM_uncorrectable
  create_bd_pin -dir O -from 31 -to 0 Status_3
  create_bd_pin -dir O -from 142 -to 0 To_TMR_Managers
  create_bd_pin -dir I -type rst ext_reset_in

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {8} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

  # Create instance: axi_gpio_mb3_ds, and set properties
  set axi_gpio_mb3_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_mb3_ds ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_mb3_ds

  # Create instance: axi_gpio_mb3_pb, and set properties
  set axi_gpio_mb3_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_mb3_pb ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {5} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_mb3_pb

  # Create instance: axi_gpio_mb3_rs, and set properties
  set axi_gpio_mb3_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_mb3_rs ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {3} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_mb3_rs

  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0 ]
  set_property -dict [ list \
   CONFIG.IIC_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_iic_0

  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {115200} \
   CONFIG.C_DATA_BITS {8} \
   CONFIG.C_ODD_PARITY {0} \
   CONFIG.C_USE_PARITY {0} \
   CONFIG.PARITY {No_Parity} \
   CONFIG.UARTLITE_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {17} \
   CONFIG.C_CACHE_BYTE_SIZE {16384} \
   CONFIG.C_DCACHE_ADDR_TAG {17} \
   CONFIG.C_DCACHE_BYTE_SIZE {16384} \
   CONFIG.C_DCACHE_VICTIMS {8} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_DIV_ZERO_EXCEPTION {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_ENABLE_DISCRETE_PORTS {1} \
   CONFIG.C_FAULT_TOLERANT {0} \
   CONFIG.C_ICACHE_LINE_LEN {8} \
   CONFIG.C_ICACHE_STREAMS {1} \
   CONFIG.C_ICACHE_VICTIMS {8} \
   CONFIG.C_ILL_OPCODE_EXCEPTION {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_LOCKSTEP_SELECT {2} \
   CONFIG.C_MMU_ZONES {2} \
   CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} \
   CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} \
   CONFIG.C_NUM_SYNC_FF_CLK {0} \
   CONFIG.C_OPCODE_0x0_ILLEGAL {1} \
   CONFIG.C_PVR {2} \
   CONFIG.C_RESET_MSR_BIP {1} \
   CONFIG.C_TRACE {1} \
   CONFIG.C_UNALIGNED_EXCEPTIONS {1} \
   CONFIG.C_USE_BARREL {1} \
   CONFIG.C_USE_DCACHE {1} \
   CONFIG.C_USE_DIV {1} \
   CONFIG.C_USE_HW_MUL {2} \
   CONFIG.C_USE_ICACHE {1} \
   CONFIG.C_USE_MMU {3} \
   CONFIG.C_USE_MSR_INSTR {1} \
   CONFIG.C_USE_PCMP_INSTR {1} \
   CONFIG.G_TEMPLATE_LIST {4} \
   CONFIG.G_USE_EXCEPTIONS {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {12} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory_2 $hier_obj microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat microblaze_0_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {10} \
 ] $microblaze_0_xlconcat

  # Create instance: tmr_comparator_AXI4LITE_0, and set properties
  set tmr_comparator_AXI4LITE_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_0

  # Create instance: tmr_comparator_AXI4LITE_1, and set properties
  set tmr_comparator_AXI4LITE_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_1

  # Create instance: tmr_comparator_AXI4LITE_2, and set properties
  set tmr_comparator_AXI4LITE_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_2 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_2

  # Create instance: tmr_comparator_AXI4LITE_8, and set properties
  set tmr_comparator_AXI4LITE_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_8 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_8

  # Create instance: tmr_comparator_AXI4_3, and set properties
  set tmr_comparator_AXI4_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4_3 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4_3

  # Create instance: tmr_comparator_AXI4_4, and set properties
  set tmr_comparator_AXI4_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4_4 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4_4

  # Create instance: tmr_comparator_GPIO_5, and set properties
  set tmr_comparator_GPIO_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_GPIO_5 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_GPIO_5

  # Create instance: tmr_comparator_IIC_9, and set properties
  set tmr_comparator_IIC_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_IIC_9 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {19} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_IIC_9

  # Create instance: tmr_comparator_TRACE_7, and set properties
  set tmr_comparator_TRACE_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_TRACE_7 ]
  set_property -dict [ list \
   CONFIG.C_INPUT_REGISTER {1} \
   CONFIG.C_INTERFACE {7} \
   CONFIG.C_TMR {1} \
   CONFIG.C_TRACE_SIZE {1} \
   CONFIG.C_VOTER_CHECK {0} \
 ] $tmr_comparator_TRACE_7

  # Create instance: tmr_comparator_UART_6, and set properties
  set tmr_comparator_UART_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_UART_6 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {12} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_UART_6

  # Create instance: tmr_comparator_mb3_ds, and set properties
  set tmr_comparator_mb3_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_mb3_ds ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_mb3_ds

  # Create instance: tmr_comparator_mb3_pb, and set properties
  set tmr_comparator_mb3_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_mb3_pb ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_mb3_pb

  # Create instance: tmr_comparator_mb3_rs, and set properties
  set tmr_comparator_mb3_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_mb3_rs ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_mb3_rs

  # Create instance: tmr_manager_0, and set properties
  set tmr_manager_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_manager tmr_manager_0 ]
  set_property -dict [ list \
   CONFIG.C_BRK_DELAY_RST_VALUE {0xffffffff} \
   CONFIG.C_BRK_DELAY_WIDTH {32} \
   CONFIG.C_COMPARATORS_MASK {0} \
   CONFIG.C_MAGIC1 {0x46} \
   CONFIG.C_MAGIC2 {0x73} \
   CONFIG.C_NO_OF_COMPARATORS {13} \
   CONFIG.C_SEM_HEARTBEAT_WATCHDOG {1} \
   CONFIG.C_SEM_HEARTBEAT_WATCHDOG_WIDTH {10} \
   CONFIG.C_SEM_INTERFACE {1} \
   CONFIG.C_TMR {1} \
   CONFIG.C_UE_IS_FATAL {0} \
   CONFIG.C_WATCHDOG {0} \
 ] $tmr_manager_0

  # Create instance: tmr_reset_0, and set properties
  set tmr_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset tmr_reset_0 ]

  # Create instance: tmr_voter_M_BRAM_0, and set properties
  set tmr_voter_M_BRAM_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_M_BRAM_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {13} \
 ] $tmr_voter_M_BRAM_0

  # Create instance: tmr_voter_M_BRAM_1, and set properties
  set tmr_voter_M_BRAM_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_M_BRAM_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {13} \
 ] $tmr_voter_M_BRAM_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins microblaze_0_local_memory/LMB_Sl_1] [get_bd_intf_pins tmr_manager_0/SLMB]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI1]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI2] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI2]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M03_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/M_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXI3] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI1]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins S_AXI4] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI2]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M04_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/M_AXI]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins S_AXI5] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI1]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins S_AXI6] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI2]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins M05_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/M_AXI]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins S_AXI7] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI1]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins S_AXI8] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI2]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins M_AXI_DC1] [get_bd_intf_pins tmr_comparator_AXI4_3/M_AXI]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins S_AXI9] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI1]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins S_AXI10] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI2]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins M_AXI_IC1] [get_bd_intf_pins tmr_comparator_AXI4_4/M_AXI]
  connect_bd_intf_net -intf_net Conn16 [get_bd_intf_pins GPIO1] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO1]
  connect_bd_intf_net -intf_net Conn17 [get_bd_intf_pins GPIO2] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO2]
  connect_bd_intf_net -intf_net Conn18 [get_bd_intf_pins led_8bits1] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO]
  connect_bd_intf_net -intf_net Conn19 [get_bd_intf_pins UART1] [get_bd_intf_pins tmr_comparator_UART_6/UART1]
  connect_bd_intf_net -intf_net Conn20 [get_bd_intf_pins UART2] [get_bd_intf_pins tmr_comparator_UART_6/UART2]
  connect_bd_intf_net -intf_net Conn21 [get_bd_intf_pins rs232_uart1] [get_bd_intf_pins tmr_comparator_UART_6/UART]
  connect_bd_intf_net -intf_net Conn22 [get_bd_intf_pins Trace1] [get_bd_intf_pins tmr_comparator_TRACE_7/Trace1]
  connect_bd_intf_net -intf_net Conn23 [get_bd_intf_pins Trace2] [get_bd_intf_pins tmr_comparator_TRACE_7/Trace2]
  connect_bd_intf_net -intf_net Conn24 [get_bd_intf_pins M_BRAM2] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM2]
  connect_bd_intf_net -intf_net Conn25 [get_bd_intf_pins M_BRAM3] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM2]
  connect_bd_intf_net -intf_net Conn26 [get_bd_intf_pins M_BRAM4] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM3]
  connect_bd_intf_net -intf_net Conn27 [get_bd_intf_pins M_BRAM5] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM3]
  connect_bd_intf_net -intf_net Conn28 [get_bd_intf_pins S_AXI11] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI1]
  connect_bd_intf_net -intf_net Conn29 [get_bd_intf_pins S_AXI12] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI2]
  connect_bd_intf_net -intf_net Conn30 [get_bd_intf_pins M_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net Conn31 [get_bd_intf_pins IIC1] [get_bd_intf_pins tmr_comparator_IIC_9/IIC1]
  connect_bd_intf_net -intf_net Conn32 [get_bd_intf_pins IIC2] [get_bd_intf_pins tmr_comparator_IIC_9/IIC2]
  connect_bd_intf_net -intf_net Conn33 [get_bd_intf_pins iic_main1] [get_bd_intf_pins tmr_comparator_IIC_9/IIC]
  connect_bd_intf_net -intf_net Conn34 [get_bd_intf_pins GPIO_mb3_pb] [get_bd_intf_pins axi_gpio_mb3_pb/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn34] [get_bd_intf_pins GPIO_mb3_pb] [get_bd_intf_pins tmr_comparator_mb3_pb/GPIO3]
  connect_bd_intf_net -intf_net Conn35 [get_bd_intf_pins GPIO_mb3_ds] [get_bd_intf_pins axi_gpio_mb3_ds/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn35] [get_bd_intf_pins GPIO_mb3_ds] [get_bd_intf_pins tmr_comparator_mb3_ds/GPIO3]
  connect_bd_intf_net -intf_net Conn36 [get_bd_intf_pins GPIO_mb3_rs] [get_bd_intf_pins axi_gpio_mb3_rs/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn36] [get_bd_intf_pins GPIO_mb3_rs] [get_bd_intf_pins tmr_comparator_mb3_rs/GPIO3]
  connect_bd_intf_net -intf_net Conn37 [get_bd_intf_pins GPIO1_3] [get_bd_intf_pins tmr_comparator_mb3_ds/GPIO1]
  connect_bd_intf_net -intf_net Conn38 [get_bd_intf_pins GPIO2_6] [get_bd_intf_pins tmr_comparator_mb3_ds/GPIO2]
  connect_bd_intf_net -intf_net Conn39 [get_bd_intf_pins GPIO_15] [get_bd_intf_pins tmr_comparator_mb3_ds/GPIO]
  connect_bd_intf_net -intf_net Conn40 [get_bd_intf_pins GPIO1_4] [get_bd_intf_pins tmr_comparator_mb3_pb/GPIO1]
  connect_bd_intf_net -intf_net Conn41 [get_bd_intf_pins GPIO2_7] [get_bd_intf_pins tmr_comparator_mb3_pb/GPIO2]
  connect_bd_intf_net -intf_net Conn42 [get_bd_intf_pins GPIO_16] [get_bd_intf_pins tmr_comparator_mb3_pb/GPIO]
  connect_bd_intf_net -intf_net Conn43 [get_bd_intf_pins GPIO1_5] [get_bd_intf_pins tmr_comparator_mb3_rs/GPIO1]
  connect_bd_intf_net -intf_net Conn44 [get_bd_intf_pins GPIO2_8] [get_bd_intf_pins tmr_comparator_mb3_rs/GPIO2]
  connect_bd_intf_net -intf_net Conn45 [get_bd_intf_pins GPIO_17] [get_bd_intf_pins tmr_comparator_mb3_rs/GPIO]
  connect_bd_intf_net -intf_net MB3_tmr_sem [get_bd_intf_pins M08_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_tmr_sem] [get_bd_intf_pins M08_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI3]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_pins MB3_led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_gpio_0_GPIO] [get_bd_intf_pins MB3_led_8bits] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO3]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins iic_main] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_iic_0_IIC] [get_bd_intf_pins iic_main] [get_bd_intf_pins tmr_comparator_IIC_9/IIC3]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_pins rs232_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_uartlite_0_UART] [get_bd_intf_pins rs232_uart] [get_bd_intf_pins tmr_comparator_UART_6/UART3]
  connect_bd_intf_net -intf_net microblaze_0_DLMB [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins microblaze_0/M_AXI_DC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_M_AXI_DC] [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI3]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins microblaze_0/M_AXI_IC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_M_AXI_IC] [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI3]
  connect_bd_intf_net -intf_net microblaze_0_TRACE [get_bd_intf_pins TRACE] [get_bd_intf_pins microblaze_0/TRACE]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_TRACE] [get_bd_intf_pins TRACE] [get_bd_intf_pins tmr_comparator_TRACE_7/Trace3]
  connect_bd_intf_net -intf_net microblaze_0_axi_dp [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M03_AXI] [get_bd_intf_pins M03_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI3]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M04_AXI] [get_bd_intf_pins M04_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI3]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M05_AXI] [get_bd_intf_pins M05_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI3]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins axi_timer_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins axi_gpio_mb3_ds/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins axi_gpio_mb3_pb/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins axi_gpio_mb3_rs/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net microblaze_0_local_memory_BRAM_PORT [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORT] [get_bd_intf_pins tmr_voter_M_BRAM_0/S_BRAM]
  connect_bd_intf_net -intf_net microblaze_0_local_memory_BRAM_PORT1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORT1] [get_bd_intf_pins tmr_voter_M_BRAM_1/S_BRAM]
  connect_bd_intf_net -intf_net tmr_voter_M_BRAM_0_M_BRAM1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTA] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_M_BRAM_0_M_BRAM1] [get_bd_intf_pins BRAM_PORTA] [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTA]
  connect_bd_intf_net -intf_net tmr_voter_M_BRAM_1_M_BRAM1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTB] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_M_BRAM_1_M_BRAM1] [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net From_TMR_Manager_1_1 [get_bd_pins From_TMR_Manager_1] [get_bd_pins tmr_manager_0/From_TMR_Manager_1]
  connect_bd_net -net From_TMR_Manager_2_1 [get_bd_pins From_TMR_Manager_2] [get_bd_pins tmr_manager_0/From_TMR_Manager_2]
  connect_bd_net -net Interrupt [get_bd_pins In8] [get_bd_pins microblaze_0_xlconcat/In8]
  connect_bd_net -net LOCKSTEP_Slave_In_1 [get_bd_pins LOCKSTEP_Slave_In] [get_bd_pins microblaze_0/LOCKSTEP_Slave_In]
  connect_bd_net -net SEM_classification_1 [get_bd_pins SEM_classification] [get_bd_pins tmr_manager_0/SEM_classification]
  connect_bd_net -net SEM_correction_1 [get_bd_pins SEM_correction] [get_bd_pins tmr_manager_0/SEM_correction]
  connect_bd_net -net SEM_detect_only_1 [get_bd_pins SEM_detect_only] [get_bd_pins tmr_manager_0/SEM_detect_only]
  connect_bd_net -net SEM_diagnostic_scan_1 [get_bd_pins SEM_diagnostic_scan] [get_bd_pins tmr_manager_0/SEM_diagnostic_scan]
  connect_bd_net -net SEM_essential_1 [get_bd_pins SEM_essential] [get_bd_pins tmr_manager_0/SEM_essential]
  connect_bd_net -net SEM_heartbeat_1 [get_bd_pins SEM_heartbeat] [get_bd_pins tmr_manager_0/SEM_heartbeat]
  connect_bd_net -net SEM_initialization_1 [get_bd_pins SEM_initialization] [get_bd_pins tmr_manager_0/SEM_initialization]
  connect_bd_net -net SEM_injection_1 [get_bd_pins SEM_injection] [get_bd_pins tmr_manager_0/SEM_injection]
  connect_bd_net -net SEM_observation_1 [get_bd_pins SEM_observation] [get_bd_pins tmr_manager_0/SEM_observation]
  connect_bd_net -net SEM_status_irq [get_bd_pins microblaze_0_xlconcat/In9] [get_bd_pins tmr_manager_0/SEM_status_irq]
  connect_bd_net -net SEM_uncorrectable_1 [get_bd_pins SEM_uncorrectable] [get_bd_pins tmr_manager_0/SEM_uncorrectable]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_introut [get_bd_pins In2] [get_bd_pins microblaze_0_xlconcat/In2]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_introut [get_bd_pins In3] [get_bd_pins microblaze_0_xlconcat/In3]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins In0] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins In1] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In6]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins In5] [get_bd_pins microblaze_0_xlconcat/In5]
  connect_bd_net -net axi_timer_0_interrupt [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In7]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In4]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins tmr_manager_0/Rst] [get_bd_pins tmr_reset_0/ext_reset_in]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_mb3_ds/s_axi_aclk] [get_bd_pins axi_gpio_mb3_pb/s_axi_aclk] [get_bd_pins axi_gpio_mb3_rs/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins tmr_comparator_AXI4LITE_0/Clk] [get_bd_pins tmr_comparator_AXI4LITE_1/Clk] [get_bd_pins tmr_comparator_AXI4LITE_2/Clk] [get_bd_pins tmr_comparator_AXI4LITE_8/Clk] [get_bd_pins tmr_comparator_AXI4_3/Clk] [get_bd_pins tmr_comparator_AXI4_4/Clk] [get_bd_pins tmr_comparator_TRACE_7/Clk] [get_bd_pins tmr_manager_0/Clk] [get_bd_pins tmr_reset_0/slowest_sync_clk]
  connect_bd_net -net microblaze_0_INTC_Interrupt [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net microblaze_0_Suspend [get_bd_pins microblaze_0/Suspend] [get_bd_pins tmr_manager_0/Recover]
  connect_bd_net -net tmr_comparator_AXI4LITE_0_Compare [get_bd_pins tmr_comparator_AXI4LITE_0/Compare] [get_bd_pins tmr_manager_0/Compare_0]
  connect_bd_net -net tmr_comparator_AXI4LITE_1_Compare [get_bd_pins tmr_comparator_AXI4LITE_1/Compare] [get_bd_pins tmr_manager_0/Compare_1]
  connect_bd_net -net tmr_comparator_AXI4LITE_2_Compare [get_bd_pins tmr_comparator_AXI4LITE_2/Compare] [get_bd_pins tmr_manager_0/Compare_2]
  connect_bd_net -net tmr_comparator_AXI4LITE_8_Compare [get_bd_pins tmr_comparator_AXI4LITE_8/Compare] [get_bd_pins tmr_manager_0/Compare_8]
  connect_bd_net -net tmr_comparator_AXI4_3_Compare [get_bd_pins tmr_comparator_AXI4_3/Compare] [get_bd_pins tmr_manager_0/Compare_3]
  connect_bd_net -net tmr_comparator_AXI4_4_Compare [get_bd_pins tmr_comparator_AXI4_4/Compare] [get_bd_pins tmr_manager_0/Compare_4]
  connect_bd_net -net tmr_comparator_GPIO_5_Compare [get_bd_pins tmr_comparator_GPIO_5/Compare] [get_bd_pins tmr_manager_0/Compare_5]
  connect_bd_net -net tmr_comparator_IIC_9_Compare [get_bd_pins tmr_comparator_IIC_9/Compare] [get_bd_pins tmr_manager_0/Compare_9]
  connect_bd_net -net tmr_comparator_TRACE_7_Compare [get_bd_pins tmr_comparator_TRACE_7/Compare] [get_bd_pins tmr_manager_0/Compare_7]
  connect_bd_net -net tmr_comparator_UART_6_Compare [get_bd_pins tmr_comparator_UART_6/Compare] [get_bd_pins tmr_manager_0/Compare_6]
  connect_bd_net -net tmr_comparator_mb3_ds_Compare [get_bd_pins tmr_comparator_mb3_ds/Compare] [get_bd_pins tmr_manager_0/Compare_10]
  connect_bd_net -net tmr_comparator_mb3_pb_Compare [get_bd_pins tmr_comparator_mb3_pb/Compare] [get_bd_pins tmr_manager_0/Compare_11]
  connect_bd_net -net tmr_comparator_mb3_rs_Compare [get_bd_pins tmr_comparator_mb3_rs/Compare] [get_bd_pins tmr_manager_0/Compare_12]
  connect_bd_net -net tmr_manager_0_Fatal [get_bd_pins Fatal_3] [get_bd_pins tmr_manager_0/Fatal]
  connect_bd_net -net tmr_manager_0_LockStep_Break [get_bd_pins microblaze_0/Ext_BRK] [get_bd_pins tmr_manager_0/LockStep_Break]
  connect_bd_net -net tmr_manager_0_Reset [get_bd_pins tmr_manager_0/Reset] [get_bd_pins tmr_reset_0/aux_reset_in]
  connect_bd_net -net tmr_manager_0_SEM_heartbeat_expired [get_bd_pins SEM_heartbeat_expired_3] [get_bd_pins tmr_manager_0/SEM_heartbeat_expired]
  connect_bd_net -net tmr_manager_0_Status [get_bd_pins Status_3] [get_bd_pins tmr_manager_0/Status]
  connect_bd_net -net tmr_manager_0_To_TMR_Managers [get_bd_pins To_TMR_Managers] [get_bd_pins tmr_manager_0/From_TMR_Manager_3] [get_bd_pins tmr_manager_0/To_TMR_Managers]
  connect_bd_net -net tmr_reset_0_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins tmr_reset_0/bus_struct_reset]
  connect_bd_net -net tmr_reset_0_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins tmr_reset_0/mb_reset]
  connect_bd_net -net tmr_reset_0_peripheral_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_mb3_ds/s_axi_aresetn] [get_bd_pins axi_gpio_mb3_pb/s_axi_aresetn] [get_bd_pins axi_gpio_mb3_rs/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins tmr_reset_0/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: MB2
proc create_hier_cell_MB2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_MB2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1_0

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1_1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO1_2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3_3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3_4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3_5

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_4

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_9

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_10

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_11

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 IIC1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 IIC3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M08_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI6

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI7

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI8

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI9

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI10

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI11

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI12

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:mbtrace_rtl:2.0 TRACE

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:mbtrace_rtl:2.0 Trace1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:mbtrace_rtl:2.0 Trace3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 UART1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 UART3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart1


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir O Fatal_2
  create_bd_pin -dir I -from 142 -to 0 From_TMR_Manager_1
  create_bd_pin -dir I -from 142 -to 0 From_TMR_Manager_3
  create_bd_pin -dir I -from 0 -to 0 In0
  create_bd_pin -dir I -from 0 -to 0 In1
  create_bd_pin -dir I -from 0 -to 0 In2
  create_bd_pin -dir I -from 0 -to 0 In3
  create_bd_pin -dir I -from 0 -to 0 In5
  create_bd_pin -dir I -from 0 -to 0 In8
  create_bd_pin -dir I -from 0 -to 4095 LOCKSTEP_Slave_In
  create_bd_pin -dir I SEM_classification
  create_bd_pin -dir I SEM_correction
  create_bd_pin -dir I SEM_detect_only
  create_bd_pin -dir I SEM_diagnostic_scan
  create_bd_pin -dir I SEM_essential
  create_bd_pin -dir I SEM_heartbeat
  create_bd_pin -dir O SEM_heartbeat_expired_2
  create_bd_pin -dir I SEM_initialization
  create_bd_pin -dir I SEM_injection
  create_bd_pin -dir I SEM_observation
  create_bd_pin -dir I SEM_uncorrectable
  create_bd_pin -dir O -from 31 -to 0 Status_2
  create_bd_pin -dir O -from 142 -to 0 To_TMR_Managers
  create_bd_pin -dir I -type rst ext_reset_in

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {8} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

  # Create instance: axi_gpio_mb2_ds, and set properties
  set axi_gpio_mb2_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_mb2_ds ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_mb2_ds

  # Create instance: axi_gpio_mb2_pb, and set properties
  set axi_gpio_mb2_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_mb2_pb ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {5} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_mb2_pb

  # Create instance: axi_gpio_mb2_rs, and set properties
  set axi_gpio_mb2_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_mb2_rs ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {3} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_mb2_rs

  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0 ]
  set_property -dict [ list \
   CONFIG.IIC_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_iic_0

  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {115200} \
   CONFIG.C_DATA_BITS {8} \
   CONFIG.C_ODD_PARITY {0} \
   CONFIG.C_USE_PARITY {0} \
   CONFIG.PARITY {No_Parity} \
   CONFIG.UARTLITE_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {17} \
   CONFIG.C_CACHE_BYTE_SIZE {16384} \
   CONFIG.C_DCACHE_ADDR_TAG {17} \
   CONFIG.C_DCACHE_BYTE_SIZE {16384} \
   CONFIG.C_DCACHE_VICTIMS {8} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_DIV_ZERO_EXCEPTION {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_ENABLE_DISCRETE_PORTS {1} \
   CONFIG.C_FAULT_TOLERANT {0} \
   CONFIG.C_ICACHE_LINE_LEN {8} \
   CONFIG.C_ICACHE_STREAMS {1} \
   CONFIG.C_ICACHE_VICTIMS {8} \
   CONFIG.C_ILL_OPCODE_EXCEPTION {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_LOCKSTEP_SELECT {2} \
   CONFIG.C_MMU_ZONES {2} \
   CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} \
   CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} \
   CONFIG.C_NUM_SYNC_FF_CLK {0} \
   CONFIG.C_OPCODE_0x0_ILLEGAL {1} \
   CONFIG.C_PVR {2} \
   CONFIG.C_RESET_MSR_BIP {1} \
   CONFIG.C_TRACE {1} \
   CONFIG.C_UNALIGNED_EXCEPTIONS {1} \
   CONFIG.C_USE_BARREL {1} \
   CONFIG.C_USE_DCACHE {1} \
   CONFIG.C_USE_DIV {1} \
   CONFIG.C_USE_HW_MUL {2} \
   CONFIG.C_USE_ICACHE {1} \
   CONFIG.C_USE_MMU {3} \
   CONFIG.C_USE_MSR_INSTR {1} \
   CONFIG.C_USE_PCMP_INSTR {1} \
   CONFIG.G_TEMPLATE_LIST {4} \
   CONFIG.G_USE_EXCEPTIONS {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {12} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory_1 $hier_obj microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat microblaze_0_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {10} \
 ] $microblaze_0_xlconcat

  # Create instance: tmr_comparator_AXI4LITE_0, and set properties
  set tmr_comparator_AXI4LITE_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_0

  # Create instance: tmr_comparator_AXI4LITE_1, and set properties
  set tmr_comparator_AXI4LITE_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_1

  # Create instance: tmr_comparator_AXI4LITE_2, and set properties
  set tmr_comparator_AXI4LITE_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_2 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_2

  # Create instance: tmr_comparator_AXI4LITE_8, and set properties
  set tmr_comparator_AXI4LITE_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_8 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_8

  # Create instance: tmr_comparator_AXI4_3, and set properties
  set tmr_comparator_AXI4_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4_3 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4_3

  # Create instance: tmr_comparator_AXI4_4, and set properties
  set tmr_comparator_AXI4_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4_4 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4_4

  # Create instance: tmr_comparator_GPIO_5, and set properties
  set tmr_comparator_GPIO_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_GPIO_5 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_GPIO_5

  # Create instance: tmr_comparator_IIC_9, and set properties
  set tmr_comparator_IIC_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_IIC_9 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {19} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_IIC_9

  # Create instance: tmr_comparator_TRACE_7, and set properties
  set tmr_comparator_TRACE_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_TRACE_7 ]
  set_property -dict [ list \
   CONFIG.C_INPUT_REGISTER {1} \
   CONFIG.C_INTERFACE {7} \
   CONFIG.C_TMR {1} \
   CONFIG.C_TRACE_SIZE {1} \
   CONFIG.C_VOTER_CHECK {0} \
 ] $tmr_comparator_TRACE_7

  # Create instance: tmr_comparator_UART_6, and set properties
  set tmr_comparator_UART_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_UART_6 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {12} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_UART_6

  # Create instance: tmr_comparator_mb2_ds, and set properties
  set tmr_comparator_mb2_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_mb2_ds ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_mb2_ds

  # Create instance: tmr_comparator_mb2_pb, and set properties
  set tmr_comparator_mb2_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_mb2_pb ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_mb2_pb

  # Create instance: tmr_comparator_mb2_rs, and set properties
  set tmr_comparator_mb2_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_mb2_rs ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_mb2_rs

  # Create instance: tmr_manager_0, and set properties
  set tmr_manager_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_manager tmr_manager_0 ]
  set_property -dict [ list \
   CONFIG.C_BRK_DELAY_RST_VALUE {0xffffffff} \
   CONFIG.C_BRK_DELAY_WIDTH {32} \
   CONFIG.C_COMPARATORS_MASK {0} \
   CONFIG.C_MAGIC1 {0x46} \
   CONFIG.C_MAGIC2 {0x73} \
   CONFIG.C_NO_OF_COMPARATORS {13} \
   CONFIG.C_SEM_HEARTBEAT_WATCHDOG {1} \
   CONFIG.C_SEM_HEARTBEAT_WATCHDOG_WIDTH {10} \
   CONFIG.C_SEM_INTERFACE {1} \
   CONFIG.C_TMR {1} \
   CONFIG.C_UE_IS_FATAL {0} \
   CONFIG.C_WATCHDOG {0} \
 ] $tmr_manager_0

  # Create instance: tmr_reset_0, and set properties
  set tmr_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset tmr_reset_0 ]

  # Create instance: tmr_voter_M_BRAM_0, and set properties
  set tmr_voter_M_BRAM_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_M_BRAM_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {13} \
 ] $tmr_voter_M_BRAM_0

  # Create instance: tmr_voter_M_BRAM_1, and set properties
  set tmr_voter_M_BRAM_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_M_BRAM_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {13} \
 ] $tmr_voter_M_BRAM_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins microblaze_0_local_memory/LMB_Sl_1] [get_bd_intf_pins tmr_manager_0/SLMB]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI1]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI3] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI3]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M03_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/M_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXI2] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI1]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins S_AXI4] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI3]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M04_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/M_AXI]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins S_AXI5] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI1]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins S_AXI6] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI3]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins M05_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/M_AXI]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins S_AXI7] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI1]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins S_AXI8] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI3]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins M_AXI_DC1] [get_bd_intf_pins tmr_comparator_AXI4_3/M_AXI]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins S_AXI9] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI1]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins S_AXI10] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI3]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins M_AXI_IC1] [get_bd_intf_pins tmr_comparator_AXI4_4/M_AXI]
  connect_bd_intf_net -intf_net Conn16 [get_bd_intf_pins GPIO1] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO1]
  connect_bd_intf_net -intf_net Conn17 [get_bd_intf_pins GPIO3] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO3]
  connect_bd_intf_net -intf_net Conn18 [get_bd_intf_pins led_8bits1] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO]
  connect_bd_intf_net -intf_net Conn19 [get_bd_intf_pins UART1] [get_bd_intf_pins tmr_comparator_UART_6/UART1]
  connect_bd_intf_net -intf_net Conn20 [get_bd_intf_pins UART3] [get_bd_intf_pins tmr_comparator_UART_6/UART3]
  connect_bd_intf_net -intf_net Conn21 [get_bd_intf_pins rs232_uart1] [get_bd_intf_pins tmr_comparator_UART_6/UART]
  connect_bd_intf_net -intf_net Conn22 [get_bd_intf_pins Trace1] [get_bd_intf_pins tmr_comparator_TRACE_7/Trace1]
  connect_bd_intf_net -intf_net Conn23 [get_bd_intf_pins Trace3] [get_bd_intf_pins tmr_comparator_TRACE_7/Trace3]
  connect_bd_intf_net -intf_net Conn24 [get_bd_intf_pins M_BRAM2] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM2]
  connect_bd_intf_net -intf_net Conn25 [get_bd_intf_pins M_BRAM3] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM2]
  connect_bd_intf_net -intf_net Conn26 [get_bd_intf_pins M_BRAM4] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM3]
  connect_bd_intf_net -intf_net Conn27 [get_bd_intf_pins M_BRAM5] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM3]
  connect_bd_intf_net -intf_net Conn28 [get_bd_intf_pins S_AXI11] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI1]
  connect_bd_intf_net -intf_net Conn29 [get_bd_intf_pins S_AXI12] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI3]
  connect_bd_intf_net -intf_net Conn30 [get_bd_intf_pins M_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net Conn31 [get_bd_intf_pins IIC1] [get_bd_intf_pins tmr_comparator_IIC_9/IIC1]
  connect_bd_intf_net -intf_net Conn32 [get_bd_intf_pins IIC3] [get_bd_intf_pins tmr_comparator_IIC_9/IIC3]
  connect_bd_intf_net -intf_net Conn33 [get_bd_intf_pins iic_main1] [get_bd_intf_pins tmr_comparator_IIC_9/IIC]
  connect_bd_intf_net -intf_net Conn34 [get_bd_intf_pins GPIO_3] [get_bd_intf_pins axi_gpio_mb2_pb/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn34] [get_bd_intf_pins GPIO_3] [get_bd_intf_pins tmr_comparator_mb2_pb/GPIO2]
  connect_bd_intf_net -intf_net Conn35 [get_bd_intf_pins GPIO_4] [get_bd_intf_pins axi_gpio_mb2_ds/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn35] [get_bd_intf_pins GPIO_4] [get_bd_intf_pins tmr_comparator_mb2_ds/GPIO2]
  connect_bd_intf_net -intf_net Conn36 [get_bd_intf_pins GPIO_5] [get_bd_intf_pins axi_gpio_mb2_rs/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn36] [get_bd_intf_pins GPIO_5] [get_bd_intf_pins tmr_comparator_mb2_rs/GPIO2]
  connect_bd_intf_net -intf_net Conn37 [get_bd_intf_pins GPIO3_3] [get_bd_intf_pins tmr_comparator_mb2_ds/GPIO3]
  connect_bd_intf_net -intf_net Conn38 [get_bd_intf_pins GPIO1_0] [get_bd_intf_pins tmr_comparator_mb2_ds/GPIO1]
  connect_bd_intf_net -intf_net Conn39 [get_bd_intf_pins GPIO_9] [get_bd_intf_pins tmr_comparator_mb2_ds/GPIO]
  connect_bd_intf_net -intf_net Conn40 [get_bd_intf_pins GPIO1_1] [get_bd_intf_pins tmr_comparator_mb2_pb/GPIO1]
  connect_bd_intf_net -intf_net Conn41 [get_bd_intf_pins GPIO3_4] [get_bd_intf_pins tmr_comparator_mb2_pb/GPIO3]
  connect_bd_intf_net -intf_net Conn42 [get_bd_intf_pins GPIO_10] [get_bd_intf_pins tmr_comparator_mb2_pb/GPIO]
  connect_bd_intf_net -intf_net Conn43 [get_bd_intf_pins GPIO1_2] [get_bd_intf_pins tmr_comparator_mb2_rs/GPIO1]
  connect_bd_intf_net -intf_net Conn44 [get_bd_intf_pins GPIO3_5] [get_bd_intf_pins tmr_comparator_mb2_rs/GPIO3]
  connect_bd_intf_net -intf_net Conn45 [get_bd_intf_pins GPIO_11] [get_bd_intf_pins tmr_comparator_mb2_rs/GPIO]
  connect_bd_intf_net -intf_net MB2_tmr_sem [get_bd_intf_pins M08_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_tmr_sem] [get_bd_intf_pins M08_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI2]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_pins led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_gpio_0_GPIO] [get_bd_intf_pins led_8bits] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO2]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins iic_main] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_iic_0_IIC] [get_bd_intf_pins iic_main] [get_bd_intf_pins tmr_comparator_IIC_9/IIC2]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_pins rs232_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_uartlite_0_UART] [get_bd_intf_pins rs232_uart] [get_bd_intf_pins tmr_comparator_UART_6/UART2]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins microblaze_0/M_AXI_DC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_M_AXI_DC] [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI2]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins microblaze_0/M_AXI_IC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_M_AXI_IC] [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI2]
  connect_bd_intf_net -intf_net microblaze_0_TRACE [get_bd_intf_pins TRACE] [get_bd_intf_pins microblaze_0/TRACE]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_TRACE] [get_bd_intf_pins TRACE] [get_bd_intf_pins tmr_comparator_TRACE_7/Trace2]
  connect_bd_intf_net -intf_net microblaze_0_axi_dp [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M03_AXI] [get_bd_intf_pins M03_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI2]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M04_AXI] [get_bd_intf_pins M04_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI2]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M05_AXI] [get_bd_intf_pins M05_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI2]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins axi_timer_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins axi_gpio_mb2_ds/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins axi_gpio_mb2_pb/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins axi_gpio_mb2_rs/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net microblaze_0_local_memory_BRAM_PORT [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORT] [get_bd_intf_pins tmr_voter_M_BRAM_0/S_BRAM]
  connect_bd_intf_net -intf_net microblaze_0_local_memory_BRAM_PORT1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORT1] [get_bd_intf_pins tmr_voter_M_BRAM_1/S_BRAM]
  connect_bd_intf_net -intf_net tmr_voter_M_BRAM_0_M_BRAM1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTA] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_M_BRAM_0_M_BRAM1] [get_bd_intf_pins BRAM_PORTA] [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTA]
  connect_bd_intf_net -intf_net tmr_voter_M_BRAM_1_M_BRAM1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTB] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_M_BRAM_1_M_BRAM1] [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net From_TMR_Manager_1_1 [get_bd_pins From_TMR_Manager_1] [get_bd_pins tmr_manager_0/From_TMR_Manager_1]
  connect_bd_net -net From_TMR_Manager_3_1 [get_bd_pins From_TMR_Manager_3] [get_bd_pins tmr_manager_0/From_TMR_Manager_3]
  connect_bd_net -net Interrupt [get_bd_pins In8] [get_bd_pins microblaze_0_xlconcat/In8]
  connect_bd_net -net LOCKSTEP_Slave_In_1 [get_bd_pins LOCKSTEP_Slave_In] [get_bd_pins microblaze_0/LOCKSTEP_Slave_In]
  connect_bd_net -net SEM_classification_1 [get_bd_pins SEM_classification] [get_bd_pins tmr_manager_0/SEM_classification]
  connect_bd_net -net SEM_correction_1 [get_bd_pins SEM_correction] [get_bd_pins tmr_manager_0/SEM_correction]
  connect_bd_net -net SEM_detect_only_1 [get_bd_pins SEM_detect_only] [get_bd_pins tmr_manager_0/SEM_detect_only]
  connect_bd_net -net SEM_diagnostic_scan_1 [get_bd_pins SEM_diagnostic_scan] [get_bd_pins tmr_manager_0/SEM_diagnostic_scan]
  connect_bd_net -net SEM_essential_1 [get_bd_pins SEM_essential] [get_bd_pins tmr_manager_0/SEM_essential]
  connect_bd_net -net SEM_heartbeat_1 [get_bd_pins SEM_heartbeat] [get_bd_pins tmr_manager_0/SEM_heartbeat]
  connect_bd_net -net SEM_initialization_1 [get_bd_pins SEM_initialization] [get_bd_pins tmr_manager_0/SEM_initialization]
  connect_bd_net -net SEM_injection_1 [get_bd_pins SEM_injection] [get_bd_pins tmr_manager_0/SEM_injection]
  connect_bd_net -net SEM_observation_1 [get_bd_pins SEM_observation] [get_bd_pins tmr_manager_0/SEM_observation]
  connect_bd_net -net SEM_status_irq [get_bd_pins microblaze_0_xlconcat/In9] [get_bd_pins tmr_manager_0/SEM_status_irq]
  connect_bd_net -net SEM_uncorrectable_1 [get_bd_pins SEM_uncorrectable] [get_bd_pins tmr_manager_0/SEM_uncorrectable]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_introut [get_bd_pins In2] [get_bd_pins microblaze_0_xlconcat/In2]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_introut [get_bd_pins In3] [get_bd_pins microblaze_0_xlconcat/In3]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins In0] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins In1] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In6]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins In5] [get_bd_pins microblaze_0_xlconcat/In5]
  connect_bd_net -net axi_timer_0_interrupt [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In7]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In4]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins tmr_manager_0/Rst] [get_bd_pins tmr_reset_0/ext_reset_in]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_mb2_ds/s_axi_aclk] [get_bd_pins axi_gpio_mb2_pb/s_axi_aclk] [get_bd_pins axi_gpio_mb2_rs/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins tmr_comparator_AXI4LITE_0/Clk] [get_bd_pins tmr_comparator_AXI4LITE_1/Clk] [get_bd_pins tmr_comparator_AXI4LITE_2/Clk] [get_bd_pins tmr_comparator_AXI4LITE_8/Clk] [get_bd_pins tmr_comparator_AXI4_3/Clk] [get_bd_pins tmr_comparator_AXI4_4/Clk] [get_bd_pins tmr_comparator_TRACE_7/Clk] [get_bd_pins tmr_manager_0/Clk] [get_bd_pins tmr_reset_0/slowest_sync_clk]
  connect_bd_net -net microblaze_0_INTC_Interrupt [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net microblaze_0_Suspend [get_bd_pins microblaze_0/Suspend] [get_bd_pins tmr_manager_0/Recover]
  connect_bd_net -net tmr_comparator_AXI4LITE_0_Compare [get_bd_pins tmr_comparator_AXI4LITE_0/Compare] [get_bd_pins tmr_manager_0/Compare_0]
  connect_bd_net -net tmr_comparator_AXI4LITE_1_Compare [get_bd_pins tmr_comparator_AXI4LITE_1/Compare] [get_bd_pins tmr_manager_0/Compare_1]
  connect_bd_net -net tmr_comparator_AXI4LITE_2_Compare [get_bd_pins tmr_comparator_AXI4LITE_2/Compare] [get_bd_pins tmr_manager_0/Compare_2]
  connect_bd_net -net tmr_comparator_AXI4LITE_8_Compare [get_bd_pins tmr_comparator_AXI4LITE_8/Compare] [get_bd_pins tmr_manager_0/Compare_8]
  connect_bd_net -net tmr_comparator_AXI4_3_Compare [get_bd_pins tmr_comparator_AXI4_3/Compare] [get_bd_pins tmr_manager_0/Compare_3]
  connect_bd_net -net tmr_comparator_AXI4_4_Compare [get_bd_pins tmr_comparator_AXI4_4/Compare] [get_bd_pins tmr_manager_0/Compare_4]
  connect_bd_net -net tmr_comparator_GPIO_5_Compare [get_bd_pins tmr_comparator_GPIO_5/Compare] [get_bd_pins tmr_manager_0/Compare_5]
  connect_bd_net -net tmr_comparator_IIC_9_Compare [get_bd_pins tmr_comparator_IIC_9/Compare] [get_bd_pins tmr_manager_0/Compare_9]
  connect_bd_net -net tmr_comparator_TRACE_7_Compare [get_bd_pins tmr_comparator_TRACE_7/Compare] [get_bd_pins tmr_manager_0/Compare_7]
  connect_bd_net -net tmr_comparator_UART_6_Compare [get_bd_pins tmr_comparator_UART_6/Compare] [get_bd_pins tmr_manager_0/Compare_6]
  connect_bd_net -net tmr_comparator_mb2_ds_Compare [get_bd_pins tmr_comparator_mb2_ds/Compare] [get_bd_pins tmr_manager_0/Compare_10]
  connect_bd_net -net tmr_comparator_mb2_pb_Compare [get_bd_pins tmr_comparator_mb2_pb/Compare] [get_bd_pins tmr_manager_0/Compare_11]
  connect_bd_net -net tmr_comparator_mb2_rs_Compare [get_bd_pins tmr_comparator_mb2_rs/Compare] [get_bd_pins tmr_manager_0/Compare_12]
  connect_bd_net -net tmr_manager_0_Fatal [get_bd_pins Fatal_2] [get_bd_pins tmr_manager_0/Fatal]
  connect_bd_net -net tmr_manager_0_LockStep_Break [get_bd_pins microblaze_0/Ext_BRK] [get_bd_pins tmr_manager_0/LockStep_Break]
  connect_bd_net -net tmr_manager_0_Reset [get_bd_pins tmr_manager_0/Reset] [get_bd_pins tmr_reset_0/aux_reset_in]
  connect_bd_net -net tmr_manager_0_SEM_heartbeat_expired [get_bd_pins SEM_heartbeat_expired_2] [get_bd_pins tmr_manager_0/SEM_heartbeat_expired]
  connect_bd_net -net tmr_manager_0_Status [get_bd_pins Status_2] [get_bd_pins tmr_manager_0/Status]
  connect_bd_net -net tmr_manager_0_To_TMR_Managers [get_bd_pins To_TMR_Managers] [get_bd_pins tmr_manager_0/From_TMR_Manager_2] [get_bd_pins tmr_manager_0/To_TMR_Managers]
  connect_bd_net -net tmr_reset_0_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins tmr_reset_0/bus_struct_reset]
  connect_bd_net -net tmr_reset_0_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins tmr_reset_0/mb_reset]
  connect_bd_net -net tmr_reset_0_peripheral_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_mb2_ds/s_axi_aresetn] [get_bd_pins axi_gpio_mb2_pb/s_axi_aresetn] [get_bd_pins axi_gpio_mb2_rs/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins tmr_reset_0/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: MB1
proc create_hier_cell_MB1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_MB1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTA

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 BRAM_PORTB

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbdebug_rtl:3.0 DEBUG

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2_0

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2_1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO2_2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3_0

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3_1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO3_2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_6

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_7

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_8

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_mb1_0

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_mb1_1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 GPIO_mb1_2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 IIC2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 IIC3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M08_AXI

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC1

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:bram_rtl:1.0 M_BRAM5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI4

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI5

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI6

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI7

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI8

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI9

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI10

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI11

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI12

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI13

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:mbtrace_rtl:2.0 TraceSlave1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbtrace_rtl:2.0 TraceSlave2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbtrace_rtl:2.0 TraceSlave3

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 UART2

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 UART3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart

  create_bd_intf_pin -mode Monitor -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart1


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir O Fatal_1
  create_bd_pin -dir I -from 142 -to 0 From_TMR_Manager_2
  create_bd_pin -dir I -from 142 -to 0 From_TMR_Manager_3
  create_bd_pin -dir I -from 0 -to 0 In0
  create_bd_pin -dir I -from 0 -to 0 In1
  create_bd_pin -dir I -from 0 -to 0 In2
  create_bd_pin -dir I -from 0 -to 0 In3
  create_bd_pin -dir I -from 0 -to 0 In5
  create_bd_pin -dir I -from 0 -to 0 In8
  create_bd_pin -dir O -from 0 -to 4095 LOCKSTEP_Master_Out
  create_bd_pin -dir I SEM_classification
  create_bd_pin -dir I SEM_correction
  create_bd_pin -dir I SEM_detect_only
  create_bd_pin -dir I SEM_diagnostic_scan
  create_bd_pin -dir I SEM_essential
  create_bd_pin -dir I SEM_heartbeat
  create_bd_pin -dir O SEM_heartbeat_expired_1
  create_bd_pin -dir I SEM_initialization
  create_bd_pin -dir I SEM_injection
  create_bd_pin -dir I SEM_observation
  create_bd_pin -dir I SEM_uncorrectable
  create_bd_pin -dir O -from 31 -to 0 Status_1
  create_bd_pin -dir O -from 142 -to 0 To_TMR_Managers
  create_bd_pin -dir I -type rst ext_reset_in

  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  set_property -dict [ list \
   CONFIG.C_ALL_OUTPUTS {1} \
   CONFIG.C_GPIO_WIDTH {8} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_gpio_0

  # Create instance: axi_gpio_ds, and set properties
  set axi_gpio_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_ds ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {4} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_ds

  # Create instance: axi_gpio_pb, and set properties
  set axi_gpio_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_pb ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {5} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_pb

  # Create instance: axi_gpio_rs, and set properties
  set axi_gpio_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_rs ]
  set_property -dict [ list \
   CONFIG.C_ALL_INPUTS {1} \
   CONFIG.C_GPIO_WIDTH {3} \
   CONFIG.GPIO_BOARD_INTERFACE {Custom} \
 ] $axi_gpio_rs

  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic axi_iic_0 ]
  set_property -dict [ list \
   CONFIG.IIC_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_iic_0

  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite axi_uartlite_0 ]
  set_property -dict [ list \
   CONFIG.C_BAUDRATE {115200} \
   CONFIG.C_DATA_BITS {8} \
   CONFIG.C_ODD_PARITY {0} \
   CONFIG.C_USE_PARITY {0} \
   CONFIG.PARITY {No_Parity} \
   CONFIG.UARTLITE_BOARD_INTERFACE {Custom} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_uartlite_0

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {17} \
   CONFIG.C_CACHE_BYTE_SIZE {16384} \
   CONFIG.C_DCACHE_ADDR_TAG {17} \
   CONFIG.C_DCACHE_BYTE_SIZE {16384} \
   CONFIG.C_DCACHE_VICTIMS {8} \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_DIV_ZERO_EXCEPTION {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_ENABLE_DISCRETE_PORTS {1} \
   CONFIG.C_FAULT_TOLERANT {0} \
   CONFIG.C_ICACHE_LINE_LEN {8} \
   CONFIG.C_ICACHE_STREAMS {1} \
   CONFIG.C_ICACHE_VICTIMS {8} \
   CONFIG.C_ILL_OPCODE_EXCEPTION {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_LOCKSTEP_SELECT {1} \
   CONFIG.C_MMU_ZONES {2} \
   CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} \
   CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} \
   CONFIG.C_NUM_SYNC_FF_CLK {0} \
   CONFIG.C_OPCODE_0x0_ILLEGAL {1} \
   CONFIG.C_PVR {2} \
   CONFIG.C_RESET_MSR_BIP {1} \
   CONFIG.C_TRACE {1} \
   CONFIG.C_UNALIGNED_EXCEPTIONS {1} \
   CONFIG.C_USE_BARREL {1} \
   CONFIG.C_USE_DCACHE {1} \
   CONFIG.C_USE_DIV {1} \
   CONFIG.C_USE_HW_MUL {2} \
   CONFIG.C_USE_ICACHE {1} \
   CONFIG.C_USE_MMU {3} \
   CONFIG.C_USE_MSR_INSTR {1} \
   CONFIG.C_USE_PCMP_INSTR {1} \
   CONFIG.G_TEMPLATE_LIST {4} \
   CONFIG.G_USE_EXCEPTIONS {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_intc, and set properties
  set microblaze_0_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc microblaze_0_axi_intc ]
  set_property -dict [ list \
   CONFIG.C_HAS_FAST {1} \
 ] $microblaze_0_axi_intc

  # Create instance: microblaze_0_axi_periph, and set properties
  set microblaze_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect microblaze_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {12} \
 ] $microblaze_0_axi_periph

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory $hier_obj microblaze_0_local_memory

  # Create instance: microblaze_0_xlconcat, and set properties
  set microblaze_0_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat microblaze_0_xlconcat ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {10} \
 ] $microblaze_0_xlconcat

  # Create instance: tmr_comparator_AXI4LITE_0, and set properties
  set tmr_comparator_AXI4LITE_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_0

  # Create instance: tmr_comparator_AXI4LITE_1, and set properties
  set tmr_comparator_AXI4LITE_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_1

  # Create instance: tmr_comparator_AXI4LITE_2, and set properties
  set tmr_comparator_AXI4LITE_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_2 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_2

  # Create instance: tmr_comparator_AXI4LITE_8, and set properties
  set tmr_comparator_AXI4LITE_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4LITE_8 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4LITE_8

  # Create instance: tmr_comparator_AXI4_3, and set properties
  set tmr_comparator_AXI4_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4_3 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4_3

  # Create instance: tmr_comparator_AXI4_4, and set properties
  set tmr_comparator_AXI4_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_AXI4_4 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_AXI4_4

  # Create instance: tmr_comparator_GPIO_5, and set properties
  set tmr_comparator_GPIO_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_GPIO_5 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_GPIO_5

  # Create instance: tmr_comparator_IIC_9, and set properties
  set tmr_comparator_IIC_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_IIC_9 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {19} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_IIC_9

  # Create instance: tmr_comparator_TRACE_7, and set properties
  set tmr_comparator_TRACE_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_TRACE_7 ]
  set_property -dict [ list \
   CONFIG.C_INPUT_REGISTER {1} \
   CONFIG.C_INTERFACE {7} \
   CONFIG.C_TMR {1} \
   CONFIG.C_TRACE1 {1} \
   CONFIG.C_TRACE2 {1} \
   CONFIG.C_TRACE3 {1} \
   CONFIG.C_TRACE_SIZE {1} \
   CONFIG.C_VOTER_CHECK {0} \
 ] $tmr_comparator_TRACE_7

  # Create instance: tmr_comparator_UART_6, and set properties
  set tmr_comparator_UART_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_UART_6 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {12} \
   CONFIG.C_TMR {1} \
 ] $tmr_comparator_UART_6

  # Create instance: tmr_comparator_ds, and set properties
  set tmr_comparator_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_ds ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_ds

  # Create instance: tmr_comparator_pb, and set properties
  set tmr_comparator_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_pb ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_pb

  # Create instance: tmr_comparator_rs, and set properties
  set tmr_comparator_rs [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_comparator tmr_comparator_rs ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
 ] $tmr_comparator_rs

  # Create instance: tmr_manager_0, and set properties
  set tmr_manager_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_manager tmr_manager_0 ]
  set_property -dict [ list \
   CONFIG.C_BRK_DELAY_RST_VALUE {0xffffffff} \
   CONFIG.C_BRK_DELAY_WIDTH {32} \
   CONFIG.C_COMPARATORS_MASK {0} \
   CONFIG.C_MAGIC1 {0x46} \
   CONFIG.C_MAGIC2 {0x73} \
   CONFIG.C_NO_OF_COMPARATORS {13} \
   CONFIG.C_SEM_HEARTBEAT_WATCHDOG {1} \
   CONFIG.C_SEM_HEARTBEAT_WATCHDOG_WIDTH {10} \
   CONFIG.C_SEM_INTERFACE {1} \
   CONFIG.C_TMR {1} \
   CONFIG.C_UE_IS_FATAL {0} \
   CONFIG.C_WATCHDOG {0} \
 ] $tmr_manager_0

  # Create instance: tmr_reset_0, and set properties
  set tmr_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset tmr_reset_0 ]

  # Create instance: tmr_voter_M_BRAM_0, and set properties
  set tmr_voter_M_BRAM_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_M_BRAM_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {13} \
 ] $tmr_voter_M_BRAM_0

  # Create instance: tmr_voter_M_BRAM_1, and set properties
  set tmr_voter_M_BRAM_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_M_BRAM_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {13} \
 ] $tmr_voter_M_BRAM_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins microblaze_0_local_memory/LMB_Sl_1] [get_bd_intf_pins tmr_manager_0/SLMB]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins S_AXI2] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI2]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins S_AXI3] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI3]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins M03_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/M_AXI]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins S_AXI4] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI2]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins S_AXI5] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI3]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M04_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/M_AXI]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins S_AXI6] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI2]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins S_AXI7] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI3]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins M05_AXI1] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/M_AXI]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins S_AXI8] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI2]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins S_AXI9] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI3]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins M_AXI_DC1] [get_bd_intf_pins tmr_comparator_AXI4_3/M_AXI]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins S_AXI10] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI2]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins S_AXI11] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI3]
  connect_bd_intf_net -intf_net Conn15 [get_bd_intf_pins M_AXI_IC1] [get_bd_intf_pins tmr_comparator_AXI4_4/M_AXI]
  connect_bd_intf_net -intf_net Conn16 [get_bd_intf_pins GPIO2] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO2]
  connect_bd_intf_net -intf_net Conn17 [get_bd_intf_pins GPIO3] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO3]
  connect_bd_intf_net -intf_net Conn18 [get_bd_intf_pins led_8bits1] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO]
  connect_bd_intf_net -intf_net Conn19 [get_bd_intf_pins UART2] [get_bd_intf_pins tmr_comparator_UART_6/UART2]
  connect_bd_intf_net -intf_net Conn20 [get_bd_intf_pins UART3] [get_bd_intf_pins tmr_comparator_UART_6/UART3]
  connect_bd_intf_net -intf_net Conn21 [get_bd_intf_pins rs232_uart1] [get_bd_intf_pins tmr_comparator_UART_6/UART]
  connect_bd_intf_net -intf_net Conn22 [get_bd_intf_pins M_BRAM3] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM3]
  connect_bd_intf_net -intf_net Conn23 [get_bd_intf_pins M_BRAM4] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM3]
  connect_bd_intf_net -intf_net Conn24 [get_bd_intf_pins M_BRAM2] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM2]
  connect_bd_intf_net -intf_net Conn25 [get_bd_intf_pins M_BRAM5] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM2]
  connect_bd_intf_net -intf_net Conn26 [get_bd_intf_pins S_AXI12] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI2]
  connect_bd_intf_net -intf_net Conn27 [get_bd_intf_pins S_AXI13] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI3]
  connect_bd_intf_net -intf_net Conn28 [get_bd_intf_pins M_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net Conn29 [get_bd_intf_pins IIC2] [get_bd_intf_pins tmr_comparator_IIC_9/IIC2]
  connect_bd_intf_net -intf_net Conn30 [get_bd_intf_pins IIC3] [get_bd_intf_pins tmr_comparator_IIC_9/IIC3]
  connect_bd_intf_net -intf_net Conn31 [get_bd_intf_pins iic_main1] [get_bd_intf_pins tmr_comparator_IIC_9/IIC]
  connect_bd_intf_net -intf_net Conn32 [get_bd_intf_pins GPIO_mb1_0] [get_bd_intf_pins axi_gpio_ds/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn32] [get_bd_intf_pins GPIO_mb1_0] [get_bd_intf_pins tmr_comparator_ds/GPIO1]
  connect_bd_intf_net -intf_net Conn33 [get_bd_intf_pins GPIO_mb1_1] [get_bd_intf_pins axi_gpio_pb/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn33] [get_bd_intf_pins GPIO_mb1_1] [get_bd_intf_pins tmr_comparator_pb/GPIO1]
  connect_bd_intf_net -intf_net Conn34 [get_bd_intf_pins GPIO_mb1_2] [get_bd_intf_pins axi_gpio_rs/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn34] [get_bd_intf_pins GPIO_mb1_2] [get_bd_intf_pins tmr_comparator_rs/GPIO1]
  connect_bd_intf_net -intf_net Conn35 [get_bd_intf_pins GPIO2_0] [get_bd_intf_pins tmr_comparator_ds/GPIO2]
  connect_bd_intf_net -intf_net Conn36 [get_bd_intf_pins GPIO_6] [get_bd_intf_pins tmr_comparator_pb/GPIO]
  connect_bd_intf_net -intf_net Conn37 [get_bd_intf_pins GPIO3_0] [get_bd_intf_pins tmr_comparator_ds/GPIO3]
  connect_bd_intf_net -intf_net Conn38 [get_bd_intf_pins GPIO3_1] [get_bd_intf_pins tmr_comparator_rs/GPIO3]
  connect_bd_intf_net -intf_net Conn39 [get_bd_intf_pins GPIO3_2] [get_bd_intf_pins tmr_comparator_pb/GPIO3]
  connect_bd_intf_net -intf_net Conn40 [get_bd_intf_pins GPIO2_1] [get_bd_intf_pins tmr_comparator_pb/GPIO2]
  connect_bd_intf_net -intf_net Conn41 [get_bd_intf_pins GPIO_7] [get_bd_intf_pins tmr_comparator_ds/GPIO]
  connect_bd_intf_net -intf_net Conn42 [get_bd_intf_pins GPIO2_2] [get_bd_intf_pins tmr_comparator_rs/GPIO2]
  connect_bd_intf_net -intf_net Conn43 [get_bd_intf_pins GPIO_8] [get_bd_intf_pins tmr_comparator_rs/GPIO]
  connect_bd_intf_net -intf_net MB1_tmr_sem [get_bd_intf_pins M08_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_tmr_sem] [get_bd_intf_pins M08_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_8/S_AXI1]
  connect_bd_intf_net -intf_net TraceSlave2_1 [get_bd_intf_pins TraceSlave2] [get_bd_intf_pins tmr_comparator_TRACE_7/TraceSlave2]
  connect_bd_intf_net -intf_net TraceSlave3_1 [get_bd_intf_pins TraceSlave3] [get_bd_intf_pins tmr_comparator_TRACE_7/TraceSlave3]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_pins led_8bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_gpio_0_GPIO] [get_bd_intf_pins led_8bits] [get_bd_intf_pins tmr_comparator_GPIO_5/GPIO1]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_pins iic_main] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_iic_0_IIC] [get_bd_intf_pins iic_main] [get_bd_intf_pins tmr_comparator_IIC_9/IIC1]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_pins rs232_uart] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net [get_bd_intf_nets axi_uartlite_0_UART] [get_bd_intf_pins rs232_uart] [get_bd_intf_pins tmr_comparator_UART_6/UART1]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins microblaze_0/M_AXI_DC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_M_AXI_DC] [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins tmr_comparator_AXI4_3/S_AXI1]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins microblaze_0/M_AXI_IC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_M_AXI_IC] [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins tmr_comparator_AXI4_4/S_AXI1]
  connect_bd_intf_net -intf_net microblaze_0_TRACE [get_bd_intf_pins microblaze_0/TRACE] [get_bd_intf_pins tmr_comparator_TRACE_7/TraceSlave1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_TRACE] [get_bd_intf_pins TraceSlave1] [get_bd_intf_pins microblaze_0/TRACE]
  connect_bd_intf_net -intf_net microblaze_0_axi_dp [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M03_AXI] [get_bd_intf_pins M03_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_0/S_AXI1]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M04_AXI] [get_bd_intf_pins M04_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_1/S_AXI1]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets microblaze_0_axi_periph_M05_AXI] [get_bd_intf_pins M05_AXI] [get_bd_intf_pins tmr_comparator_AXI4LITE_2/S_AXI1]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M07_AXI [get_bd_intf_pins axi_timer_0/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M09_AXI [get_bd_intf_pins axi_gpio_ds/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M10_AXI [get_bd_intf_pins axi_gpio_pb/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M11_AXI [get_bd_intf_pins axi_gpio_rs/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]
  connect_bd_intf_net -intf_net microblaze_0_intc_axi [get_bd_intf_pins microblaze_0_axi_intc/s_axi] [get_bd_intf_pins microblaze_0_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_interrupt [get_bd_intf_pins microblaze_0/INTERRUPT] [get_bd_intf_pins microblaze_0_axi_intc/interrupt]
  connect_bd_intf_net -intf_net microblaze_0_local_memory_BRAM_PORT [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORT] [get_bd_intf_pins tmr_voter_M_BRAM_0/S_BRAM]
  connect_bd_intf_net -intf_net microblaze_0_local_memory_BRAM_PORT1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORT1] [get_bd_intf_pins tmr_voter_M_BRAM_1/S_BRAM]
  connect_bd_intf_net -intf_net tmr_voter_M_BRAM_0_M_BRAM1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTA] [get_bd_intf_pins tmr_voter_M_BRAM_0/M_BRAM1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_M_BRAM_0_M_BRAM1] [get_bd_intf_pins BRAM_PORTA] [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTA]
  connect_bd_intf_net -intf_net tmr_voter_M_BRAM_1_M_BRAM1 [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTB] [get_bd_intf_pins tmr_voter_M_BRAM_1/M_BRAM1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_M_BRAM_1_M_BRAM1] [get_bd_intf_pins BRAM_PORTB] [get_bd_intf_pins microblaze_0_local_memory/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net From_TMR_Manager_2_1 [get_bd_pins From_TMR_Manager_2] [get_bd_pins tmr_manager_0/From_TMR_Manager_2]
  connect_bd_net -net From_TMR_Manager_3_1 [get_bd_pins From_TMR_Manager_3] [get_bd_pins tmr_manager_0/From_TMR_Manager_3]
  connect_bd_net -net Interrupt [get_bd_pins In8] [get_bd_pins microblaze_0_xlconcat/In8]
  connect_bd_net -net SEM_classification_1 [get_bd_pins SEM_classification] [get_bd_pins tmr_manager_0/SEM_classification]
  connect_bd_net -net SEM_correction_1 [get_bd_pins SEM_correction] [get_bd_pins tmr_manager_0/SEM_correction]
  connect_bd_net -net SEM_detect_only_1 [get_bd_pins SEM_detect_only] [get_bd_pins tmr_manager_0/SEM_detect_only]
  connect_bd_net -net SEM_diagnostic_scan_1 [get_bd_pins SEM_diagnostic_scan] [get_bd_pins tmr_manager_0/SEM_diagnostic_scan]
  connect_bd_net -net SEM_essential_1 [get_bd_pins SEM_essential] [get_bd_pins tmr_manager_0/SEM_essential]
  connect_bd_net -net SEM_heartbeat_1 [get_bd_pins SEM_heartbeat] [get_bd_pins tmr_manager_0/SEM_heartbeat]
  connect_bd_net -net SEM_initialization_1 [get_bd_pins SEM_initialization] [get_bd_pins tmr_manager_0/SEM_initialization]
  connect_bd_net -net SEM_injection_1 [get_bd_pins SEM_injection] [get_bd_pins tmr_manager_0/SEM_injection]
  connect_bd_net -net SEM_observation_1 [get_bd_pins SEM_observation] [get_bd_pins tmr_manager_0/SEM_observation]
  connect_bd_net -net SEM_status_irq [get_bd_pins microblaze_0_xlconcat/In9] [get_bd_pins tmr_manager_0/SEM_status_irq]
  connect_bd_net -net SEM_uncorrectable_1 [get_bd_pins SEM_uncorrectable] [get_bd_pins tmr_manager_0/SEM_uncorrectable]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_introut [get_bd_pins In2] [get_bd_pins microblaze_0_xlconcat/In2]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_introut [get_bd_pins In3] [get_bd_pins microblaze_0_xlconcat/In3]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins In0] [get_bd_pins microblaze_0_xlconcat/In0]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins In1] [get_bd_pins microblaze_0_xlconcat/In1]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In6]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins In5] [get_bd_pins microblaze_0_xlconcat/In5]
  connect_bd_net -net axi_timer_0_interrupt [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In7]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In4]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins tmr_manager_0/Rst] [get_bd_pins tmr_reset_0/ext_reset_in]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_ds/s_axi_aclk] [get_bd_pins axi_gpio_pb/s_axi_aclk] [get_bd_pins axi_gpio_rs/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_intc/processor_clk] [get_bd_pins microblaze_0_axi_intc/s_axi_aclk] [get_bd_pins microblaze_0_axi_periph/ACLK] [get_bd_pins microblaze_0_axi_periph/M00_ACLK] [get_bd_pins microblaze_0_axi_periph/M01_ACLK] [get_bd_pins microblaze_0_axi_periph/M02_ACLK] [get_bd_pins microblaze_0_axi_periph/M03_ACLK] [get_bd_pins microblaze_0_axi_periph/M04_ACLK] [get_bd_pins microblaze_0_axi_periph/M05_ACLK] [get_bd_pins microblaze_0_axi_periph/M06_ACLK] [get_bd_pins microblaze_0_axi_periph/M07_ACLK] [get_bd_pins microblaze_0_axi_periph/M08_ACLK] [get_bd_pins microblaze_0_axi_periph/M09_ACLK] [get_bd_pins microblaze_0_axi_periph/M10_ACLK] [get_bd_pins microblaze_0_axi_periph/M11_ACLK] [get_bd_pins microblaze_0_axi_periph/S00_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins tmr_comparator_AXI4LITE_0/Clk] [get_bd_pins tmr_comparator_AXI4LITE_1/Clk] [get_bd_pins tmr_comparator_AXI4LITE_2/Clk] [get_bd_pins tmr_comparator_AXI4LITE_8/Clk] [get_bd_pins tmr_comparator_AXI4_3/Clk] [get_bd_pins tmr_comparator_AXI4_4/Clk] [get_bd_pins tmr_comparator_TRACE_7/Clk] [get_bd_pins tmr_manager_0/Clk] [get_bd_pins tmr_reset_0/slowest_sync_clk]
  connect_bd_net -net microblaze_0_INTC_Interrupt [get_bd_pins microblaze_0_axi_intc/intr] [get_bd_pins microblaze_0_xlconcat/dout]
  connect_bd_net -net microblaze_0_LOCKSTEP_Master_Out [get_bd_pins LOCKSTEP_Master_Out] [get_bd_pins microblaze_0/LOCKSTEP_Master_Out]
  connect_bd_net -net microblaze_0_Suspend [get_bd_pins microblaze_0/Suspend] [get_bd_pins tmr_manager_0/Recover]
  connect_bd_net -net tmr_comparator_AXI4LITE_0_Compare [get_bd_pins tmr_comparator_AXI4LITE_0/Compare] [get_bd_pins tmr_manager_0/Compare_0]
  connect_bd_net -net tmr_comparator_AXI4LITE_1_Compare [get_bd_pins tmr_comparator_AXI4LITE_1/Compare] [get_bd_pins tmr_manager_0/Compare_1]
  connect_bd_net -net tmr_comparator_AXI4LITE_2_Compare [get_bd_pins tmr_comparator_AXI4LITE_2/Compare] [get_bd_pins tmr_manager_0/Compare_2]
  connect_bd_net -net tmr_comparator_AXI4LITE_8_Compare [get_bd_pins tmr_comparator_AXI4LITE_8/Compare] [get_bd_pins tmr_manager_0/Compare_8]
  connect_bd_net -net tmr_comparator_AXI4_3_Compare [get_bd_pins tmr_comparator_AXI4_3/Compare] [get_bd_pins tmr_manager_0/Compare_3]
  connect_bd_net -net tmr_comparator_AXI4_4_Compare [get_bd_pins tmr_comparator_AXI4_4/Compare] [get_bd_pins tmr_manager_0/Compare_4]
  connect_bd_net -net tmr_comparator_GPIO_5_Compare [get_bd_pins tmr_comparator_GPIO_5/Compare] [get_bd_pins tmr_manager_0/Compare_5]
  connect_bd_net -net tmr_comparator_IIC_9_Compare [get_bd_pins tmr_comparator_IIC_9/Compare] [get_bd_pins tmr_manager_0/Compare_9]
  connect_bd_net -net tmr_comparator_TRACE_7_Compare [get_bd_pins tmr_comparator_TRACE_7/Compare] [get_bd_pins tmr_manager_0/Compare_7]
  connect_bd_net -net tmr_comparator_UART_6_Compare [get_bd_pins tmr_comparator_UART_6/Compare] [get_bd_pins tmr_manager_0/Compare_6]
  connect_bd_net -net tmr_comparator_dip_sw_Compare [get_bd_pins tmr_comparator_ds/Compare] [get_bd_pins tmr_manager_0/Compare_10]
  connect_bd_net -net tmr_comparator_pb_Compare [get_bd_pins tmr_comparator_pb/Compare] [get_bd_pins tmr_manager_0/Compare_11]
  connect_bd_net -net tmr_comparator_rs_Compare [get_bd_pins tmr_comparator_rs/Compare] [get_bd_pins tmr_manager_0/Compare_12]
  connect_bd_net -net tmr_manager_0_Fatal [get_bd_pins Fatal_1] [get_bd_pins tmr_manager_0/Fatal]
  connect_bd_net -net tmr_manager_0_LockStep_Break [get_bd_pins microblaze_0/Ext_BRK] [get_bd_pins tmr_manager_0/LockStep_Break]
  connect_bd_net -net tmr_manager_0_Reset [get_bd_pins tmr_manager_0/Reset] [get_bd_pins tmr_reset_0/aux_reset_in]
  connect_bd_net -net tmr_manager_0_SEM_heartbeat_expired [get_bd_pins SEM_heartbeat_expired_1] [get_bd_pins tmr_manager_0/SEM_heartbeat_expired]
  connect_bd_net -net tmr_manager_0_Status [get_bd_pins Status_1] [get_bd_pins tmr_manager_0/Status]
  connect_bd_net -net tmr_manager_0_To_TMR_Managers [get_bd_pins To_TMR_Managers] [get_bd_pins tmr_manager_0/From_TMR_Manager_1] [get_bd_pins tmr_manager_0/To_TMR_Managers]
  connect_bd_net -net tmr_reset_0_bus_struct_reset [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins tmr_reset_0/bus_struct_reset]
  connect_bd_net -net tmr_reset_0_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins microblaze_0_axi_intc/processor_rst] [get_bd_pins tmr_reset_0/mb_reset]
  connect_bd_net -net tmr_reset_0_peripheral_aresetn [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_ds/s_axi_aresetn] [get_bd_pins axi_gpio_pb/s_axi_aresetn] [get_bd_pins axi_gpio_rs/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins microblaze_0_axi_intc/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph/ARESETN] [get_bd_pins microblaze_0_axi_periph/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph/M08_ARESETN] [get_bd_pins microblaze_0_axi_periph/M09_ARESETN] [get_bd_pins microblaze_0_axi_periph/M10_ARESETN] [get_bd_pins microblaze_0_axi_periph/M11_ARESETN] [get_bd_pins microblaze_0_axi_periph/S00_ARESETN] [get_bd_pins tmr_reset_0/peripheral_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: tmr_0
proc create_hier_cell_tmr_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_tmr_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:mbdebug_rtl:3.0 DEBUG

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M03_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M04_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M05_AXI

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 dip_switches_4bits

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 push_buttons_5bits

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 rotary_switch

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart


  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir O Fatal_1
  create_bd_pin -dir O Fatal_2
  create_bd_pin -dir O Fatal_3
  create_bd_pin -dir I -from 0 -to 0 In0
  create_bd_pin -dir I -from 0 -to 0 In1
  create_bd_pin -dir I -from 0 -to 0 In2
  create_bd_pin -dir I -from 0 -to 0 In3
  create_bd_pin -dir I -from 0 -to 0 In5
  create_bd_pin -dir O SEM_heartbeat_expired_1
  create_bd_pin -dir O SEM_heartbeat_expired_2
  create_bd_pin -dir O SEM_heartbeat_expired_3
  create_bd_pin -dir I -type rst S_AXI_ARESETN
  create_bd_pin -dir O -from 31 -to 0 Status_1
  create_bd_pin -dir O -from 31 -to 0 Status_2
  create_bd_pin -dir O -from 31 -to 0 Status_3
  create_bd_pin -dir I -type rst ext_reset_in

  # Create instance: MB1
  create_hier_cell_MB1 $hier_obj MB1

  # Create instance: MB2
  create_hier_cell_MB2 $hier_obj MB2

  # Create instance: MB3
  create_hier_cell_MB3 $hier_obj MB3

  # Create instance: tmr_sem_0, and set properties
  set tmr_sem_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_sem tmr_sem_0 ]
  set_property -dict [ list \
   CONFIG.C_SEM_STATUS {1} \
 ] $tmr_sem_0

  # Create instance: tmr_voter_AXI4LITE_0, and set properties
  set tmr_voter_AXI4LITE_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_AXI4LITE_0 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
 ] $tmr_voter_AXI4LITE_0

  # Create instance: tmr_voter_AXI4LITE_1, and set properties
  set tmr_voter_AXI4LITE_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_AXI4LITE_1 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
 ] $tmr_voter_AXI4LITE_1

  # Create instance: tmr_voter_AXI4LITE_2, and set properties
  set tmr_voter_AXI4LITE_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_AXI4LITE_2 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
 ] $tmr_voter_AXI4LITE_2

  # Create instance: tmr_voter_AXI4LITE_8, and set properties
  set tmr_voter_AXI4LITE_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_AXI4LITE_8 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {8} \
 ] $tmr_voter_AXI4LITE_8

  # Create instance: tmr_voter_AXI4_3, and set properties
  set tmr_voter_AXI4_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_AXI4_3 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
 ] $tmr_voter_AXI4_3

  # Create instance: tmr_voter_AXI4_4, and set properties
  set tmr_voter_AXI4_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_AXI4_4 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {3} \
 ] $tmr_voter_AXI4_4

  # Create instance: tmr_voter_GPIO_5, and set properties
  set tmr_voter_GPIO_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_GPIO_5 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.GPIO_BOARD_INTERFACE {led_8bits} \
 ] $tmr_voter_GPIO_5

  # Create instance: tmr_voter_IIC_7, and set properties
  set tmr_voter_IIC_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_IIC_7 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {19} \
   CONFIG.IIC_BOARD_INTERFACE {iic_main} \
 ] $tmr_voter_IIC_7

  # Create instance: tmr_voter_RS, and set properties
  set tmr_voter_RS [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_RS ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.GPIO_BOARD_INTERFACE {rotary_switch} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $tmr_voter_RS

  # Create instance: tmr_voter_UART_6, and set properties
  set tmr_voter_UART_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_UART_6 ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {12} \
   CONFIG.UART_BOARD_INTERFACE {rs232_uart} \
 ] $tmr_voter_UART_6

  # Create instance: tmr_voter_ds, and set properties
  set tmr_voter_ds [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_ds ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.GPIO_BOARD_INTERFACE {dip_switches_4bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $tmr_voter_ds

  # Create instance: tmr_voter_pb, and set properties
  set tmr_voter_pb [ create_bd_cell -type ip -vlnv xilinx.com:ip:tmr_voter tmr_voter_pb ]
  set_property -dict [ list \
   CONFIG.C_INTERFACE {11} \
   CONFIG.GPIO_BOARD_INTERFACE {push_buttons_5bits} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $tmr_voter_pb

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins MB1/TraceSlave1] [get_bd_intf_pins MB2/Trace1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn] [get_bd_intf_pins MB1/TraceSlave1] [get_bd_intf_pins MB3/Trace1]
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins MB1/BRAM_PORTA] [get_bd_intf_pins MB2/M_BRAM2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn1] [get_bd_intf_pins MB1/BRAM_PORTA] [get_bd_intf_pins MB3/M_BRAM2]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins MB1/BRAM_PORTB] [get_bd_intf_pins MB2/M_BRAM3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn2] [get_bd_intf_pins MB1/BRAM_PORTB] [get_bd_intf_pins MB3/M_BRAM3]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins MB1/M_BRAM3] [get_bd_intf_pins MB2/BRAM_PORTA]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn3] [get_bd_intf_pins MB1/M_BRAM3] [get_bd_intf_pins MB3/M_BRAM4]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins MB1/M_BRAM4] [get_bd_intf_pins MB2/BRAM_PORTB]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn4] [get_bd_intf_pins MB1/M_BRAM4] [get_bd_intf_pins MB3/M_BRAM5]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins MB1/M_BRAM2] [get_bd_intf_pins MB3/BRAM_PORTA]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn5] [get_bd_intf_pins MB1/M_BRAM2] [get_bd_intf_pins MB2/M_BRAM4]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins MB1/M_BRAM5] [get_bd_intf_pins MB3/BRAM_PORTB]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn6] [get_bd_intf_pins MB1/M_BRAM5] [get_bd_intf_pins MB2/M_BRAM5]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins dip_switches_4bits] [get_bd_intf_pins tmr_voter_ds/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn7] [get_bd_intf_pins dip_switches_4bits] [get_bd_intf_pins MB1/GPIO_7]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn7] [get_bd_intf_pins dip_switches_4bits] [get_bd_intf_pins MB2/GPIO_9]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn7] [get_bd_intf_pins dip_switches_4bits] [get_bd_intf_pins MB3/GPIO_15]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins push_buttons_5bits] [get_bd_intf_pins tmr_voter_pb/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn8] [get_bd_intf_pins push_buttons_5bits] [get_bd_intf_pins MB1/GPIO_6]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn8] [get_bd_intf_pins push_buttons_5bits] [get_bd_intf_pins MB3/GPIO_16]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn8] [get_bd_intf_pins push_buttons_5bits] [get_bd_intf_pins MB2/GPIO_10]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins rotary_switch] [get_bd_intf_pins tmr_voter_RS/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn9] [get_bd_intf_pins rotary_switch] [get_bd_intf_pins MB1/GPIO_8]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn9] [get_bd_intf_pins rotary_switch] [get_bd_intf_pins MB2/GPIO_11]
  connect_bd_intf_net -intf_net [get_bd_intf_nets Conn9] [get_bd_intf_pins rotary_switch] [get_bd_intf_pins MB3/GPIO_17]
  connect_bd_intf_net -intf_net MB1_GPIO_mb1_0 [get_bd_intf_pins MB1/GPIO_mb1_0] [get_bd_intf_pins tmr_voter_ds/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_GPIO_mb1_0] [get_bd_intf_pins MB2/GPIO1_0] [get_bd_intf_pins tmr_voter_ds/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_GPIO_mb1_0] [get_bd_intf_pins MB3/GPIO1_3] [get_bd_intf_pins tmr_voter_ds/GPIO1]
  connect_bd_intf_net -intf_net MB1_GPIO_mb1_1 [get_bd_intf_pins MB1/GPIO_mb1_1] [get_bd_intf_pins tmr_voter_pb/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_GPIO_mb1_1] [get_bd_intf_pins MB2/GPIO1_1] [get_bd_intf_pins tmr_voter_pb/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_GPIO_mb1_1] [get_bd_intf_pins MB3/GPIO1_4] [get_bd_intf_pins tmr_voter_pb/GPIO1]
  connect_bd_intf_net -intf_net MB1_GPIO_mb1_2 [get_bd_intf_pins MB1/GPIO_mb1_2] [get_bd_intf_pins tmr_voter_RS/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_GPIO_mb1_2] [get_bd_intf_pins MB2/GPIO1_2] [get_bd_intf_pins tmr_voter_RS/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_GPIO_mb1_2] [get_bd_intf_pins MB3/GPIO1_5] [get_bd_intf_pins tmr_voter_RS/GPIO1]
  connect_bd_intf_net -intf_net MB1_M03_AXI [get_bd_intf_pins MB1/M03_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_0/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M03_AXI] [get_bd_intf_pins MB1/M03_AXI] [get_bd_intf_pins MB2/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M03_AXI] [get_bd_intf_pins MB1/M03_AXI] [get_bd_intf_pins MB3/S_AXI1]
  connect_bd_intf_net -intf_net MB1_M04_AXI [get_bd_intf_pins MB1/M04_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_1/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M04_AXI] [get_bd_intf_pins MB1/M04_AXI] [get_bd_intf_pins MB2/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M04_AXI] [get_bd_intf_pins MB1/M04_AXI] [get_bd_intf_pins MB3/S_AXI3]
  connect_bd_intf_net -intf_net MB1_M05_AXI [get_bd_intf_pins MB1/M05_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_2/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M05_AXI] [get_bd_intf_pins MB1/M05_AXI] [get_bd_intf_pins MB2/S_AXI5]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M05_AXI] [get_bd_intf_pins MB1/M05_AXI] [get_bd_intf_pins MB3/S_AXI5]
  connect_bd_intf_net -intf_net MB1_M_AXI_DC [get_bd_intf_pins MB1/M_AXI_DC] [get_bd_intf_pins tmr_voter_AXI4_3/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M_AXI_DC] [get_bd_intf_pins MB1/M_AXI_DC] [get_bd_intf_pins MB2/S_AXI7]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M_AXI_DC] [get_bd_intf_pins MB1/M_AXI_DC] [get_bd_intf_pins MB3/S_AXI7]
  connect_bd_intf_net -intf_net MB1_M_AXI_IC [get_bd_intf_pins MB1/M_AXI_IC] [get_bd_intf_pins tmr_voter_AXI4_4/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M_AXI_IC] [get_bd_intf_pins MB1/M_AXI_IC] [get_bd_intf_pins MB2/S_AXI9]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_M_AXI_IC] [get_bd_intf_pins MB1/M_AXI_IC] [get_bd_intf_pins MB3/S_AXI9]
  connect_bd_intf_net -intf_net MB1_iic_main [get_bd_intf_pins MB1/iic_main] [get_bd_intf_pins tmr_voter_IIC_7/IIC1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_iic_main] [get_bd_intf_pins MB2/IIC1] [get_bd_intf_pins tmr_voter_IIC_7/IIC1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_iic_main] [get_bd_intf_pins MB3/IIC1] [get_bd_intf_pins tmr_voter_IIC_7/IIC1]
  connect_bd_intf_net -intf_net MB1_led_8bits [get_bd_intf_pins MB1/led_8bits] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_led_8bits] [get_bd_intf_pins MB2/GPIO1] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_led_8bits] [get_bd_intf_pins MB3/GPIO1] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO1]
  connect_bd_intf_net -intf_net MB1_rs232_uart [get_bd_intf_pins MB1/rs232_uart] [get_bd_intf_pins tmr_voter_UART_6/UART1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_rs232_uart] [get_bd_intf_pins MB2/UART1] [get_bd_intf_pins tmr_voter_UART_6/UART1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_rs232_uart] [get_bd_intf_pins MB3/UART1] [get_bd_intf_pins tmr_voter_UART_6/UART1]
  connect_bd_intf_net -intf_net MB1_tmr_sem [get_bd_intf_pins MB1/M08_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/S_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_tmr_sem] [get_bd_intf_pins MB1/M08_AXI] [get_bd_intf_pins MB2/S_AXI11]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB1_tmr_sem] [get_bd_intf_pins MB1/M08_AXI] [get_bd_intf_pins MB3/S_AXI11]
  connect_bd_intf_net -intf_net MB2_GPIO_3 [get_bd_intf_pins MB2/GPIO_3] [get_bd_intf_pins tmr_voter_pb/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_GPIO_3] [get_bd_intf_pins MB1/GPIO2_1] [get_bd_intf_pins tmr_voter_pb/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_GPIO_3] [get_bd_intf_pins MB3/GPIO2_7] [get_bd_intf_pins tmr_voter_pb/GPIO2]
  connect_bd_intf_net -intf_net MB2_GPIO_4 [get_bd_intf_pins MB2/GPIO_4] [get_bd_intf_pins tmr_voter_ds/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_GPIO_4] [get_bd_intf_pins MB1/GPIO2_0] [get_bd_intf_pins tmr_voter_ds/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_GPIO_4] [get_bd_intf_pins MB3/GPIO2_6] [get_bd_intf_pins tmr_voter_ds/GPIO2]
  connect_bd_intf_net -intf_net MB2_GPIO_5 [get_bd_intf_pins MB2/GPIO_5] [get_bd_intf_pins tmr_voter_RS/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_GPIO_5] [get_bd_intf_pins MB1/GPIO2_2] [get_bd_intf_pins tmr_voter_RS/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_GPIO_5] [get_bd_intf_pins MB3/GPIO2_8] [get_bd_intf_pins tmr_voter_RS/GPIO2]
  connect_bd_intf_net -intf_net MB2_M03_AXI [get_bd_intf_pins MB2/M03_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_0/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M03_AXI] [get_bd_intf_pins MB1/S_AXI2] [get_bd_intf_pins MB2/M03_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M03_AXI] [get_bd_intf_pins MB2/M03_AXI] [get_bd_intf_pins MB3/S_AXI2]
  connect_bd_intf_net -intf_net MB2_M04_AXI [get_bd_intf_pins MB2/M04_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_1/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M04_AXI] [get_bd_intf_pins MB1/S_AXI4] [get_bd_intf_pins MB2/M04_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M04_AXI] [get_bd_intf_pins MB2/M04_AXI] [get_bd_intf_pins MB3/S_AXI4]
  connect_bd_intf_net -intf_net MB2_M05_AXI [get_bd_intf_pins MB2/M05_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_2/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M05_AXI] [get_bd_intf_pins MB1/S_AXI6] [get_bd_intf_pins MB2/M05_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M05_AXI] [get_bd_intf_pins MB2/M05_AXI] [get_bd_intf_pins MB3/S_AXI6]
  connect_bd_intf_net -intf_net MB2_M_AXI_DC [get_bd_intf_pins MB2/M_AXI_DC] [get_bd_intf_pins tmr_voter_AXI4_3/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M_AXI_DC] [get_bd_intf_pins MB1/S_AXI8] [get_bd_intf_pins MB2/M_AXI_DC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M_AXI_DC] [get_bd_intf_pins MB2/M_AXI_DC] [get_bd_intf_pins MB3/S_AXI8]
  connect_bd_intf_net -intf_net MB2_M_AXI_IC [get_bd_intf_pins MB2/M_AXI_IC] [get_bd_intf_pins tmr_voter_AXI4_4/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M_AXI_IC] [get_bd_intf_pins MB1/S_AXI10] [get_bd_intf_pins MB2/M_AXI_IC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_M_AXI_IC] [get_bd_intf_pins MB2/M_AXI_IC] [get_bd_intf_pins MB3/S_AXI10]
  connect_bd_intf_net -intf_net MB2_TRACE [get_bd_intf_pins MB1/TraceSlave2] [get_bd_intf_pins MB2/TRACE]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_TRACE] [get_bd_intf_pins MB2/TRACE] [get_bd_intf_pins MB3/Trace2]
  connect_bd_intf_net -intf_net MB2_iic_main [get_bd_intf_pins MB2/iic_main] [get_bd_intf_pins tmr_voter_IIC_7/IIC2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_iic_main] [get_bd_intf_pins MB1/IIC2] [get_bd_intf_pins tmr_voter_IIC_7/IIC2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_iic_main] [get_bd_intf_pins MB3/IIC2] [get_bd_intf_pins tmr_voter_IIC_7/IIC2]
  connect_bd_intf_net -intf_net MB2_led_8bits [get_bd_intf_pins MB2/led_8bits] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_led_8bits] [get_bd_intf_pins MB1/GPIO2] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_led_8bits] [get_bd_intf_pins MB3/GPIO2] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO2]
  connect_bd_intf_net -intf_net MB2_rs232_uart [get_bd_intf_pins MB2/rs232_uart] [get_bd_intf_pins tmr_voter_UART_6/UART2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_rs232_uart] [get_bd_intf_pins MB1/UART2] [get_bd_intf_pins tmr_voter_UART_6/UART2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_rs232_uart] [get_bd_intf_pins MB3/UART2] [get_bd_intf_pins tmr_voter_UART_6/UART2]
  connect_bd_intf_net -intf_net MB2_tmr_sem [get_bd_intf_pins MB2/M08_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/S_AXI2]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_tmr_sem] [get_bd_intf_pins MB1/S_AXI12] [get_bd_intf_pins MB2/M08_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB2_tmr_sem] [get_bd_intf_pins MB2/M08_AXI] [get_bd_intf_pins MB3/S_AXI12]
  connect_bd_intf_net -intf_net MB3_GPIO_mb3_ds [get_bd_intf_pins MB3/GPIO_mb3_ds] [get_bd_intf_pins tmr_voter_ds/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_GPIO_mb3_ds] [get_bd_intf_pins MB2/GPIO3_3] [get_bd_intf_pins tmr_voter_ds/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_GPIO_mb3_ds] [get_bd_intf_pins MB1/GPIO3_0] [get_bd_intf_pins tmr_voter_ds/GPIO3]
  connect_bd_intf_net -intf_net MB3_GPIO_mb3_pb [get_bd_intf_pins MB3/GPIO_mb3_pb] [get_bd_intf_pins tmr_voter_pb/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_GPIO_mb3_pb] [get_bd_intf_pins MB2/GPIO3_4] [get_bd_intf_pins tmr_voter_pb/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_GPIO_mb3_pb] [get_bd_intf_pins MB1/GPIO3_2] [get_bd_intf_pins tmr_voter_pb/GPIO3]
  connect_bd_intf_net -intf_net MB3_GPIO_mb3_rs [get_bd_intf_pins MB3/GPIO_mb3_rs] [get_bd_intf_pins tmr_voter_RS/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_GPIO_mb3_rs] [get_bd_intf_pins MB2/GPIO3_5] [get_bd_intf_pins tmr_voter_RS/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_GPIO_mb3_rs] [get_bd_intf_pins MB1/GPIO3_1] [get_bd_intf_pins tmr_voter_RS/GPIO3]
  connect_bd_intf_net -intf_net MB3_M03_AXI [get_bd_intf_pins MB3/M03_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_0/S_AXI3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M03_AXI] [get_bd_intf_pins MB1/S_AXI3] [get_bd_intf_pins MB3/M03_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M03_AXI] [get_bd_intf_pins MB2/S_AXI3] [get_bd_intf_pins MB3/M03_AXI]
  connect_bd_intf_net -intf_net MB3_M04_AXI [get_bd_intf_pins MB3/M04_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_1/S_AXI3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M04_AXI] [get_bd_intf_pins MB1/S_AXI5] [get_bd_intf_pins MB3/M04_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M04_AXI] [get_bd_intf_pins MB2/S_AXI4] [get_bd_intf_pins MB3/M04_AXI]
  connect_bd_intf_net -intf_net MB3_M05_AXI [get_bd_intf_pins MB3/M05_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_2/S_AXI3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M05_AXI] [get_bd_intf_pins MB1/S_AXI7] [get_bd_intf_pins MB3/M05_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M05_AXI] [get_bd_intf_pins MB2/S_AXI6] [get_bd_intf_pins MB3/M05_AXI]
  connect_bd_intf_net -intf_net MB3_M_AXI_DC [get_bd_intf_pins MB3/M_AXI_DC] [get_bd_intf_pins tmr_voter_AXI4_3/S_AXI3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M_AXI_DC] [get_bd_intf_pins MB1/S_AXI9] [get_bd_intf_pins MB3/M_AXI_DC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M_AXI_DC] [get_bd_intf_pins MB2/S_AXI8] [get_bd_intf_pins MB3/M_AXI_DC]
  connect_bd_intf_net -intf_net MB3_M_AXI_IC [get_bd_intf_pins MB3/M_AXI_IC] [get_bd_intf_pins tmr_voter_AXI4_4/S_AXI3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M_AXI_IC] [get_bd_intf_pins MB1/S_AXI11] [get_bd_intf_pins MB3/M_AXI_IC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_M_AXI_IC] [get_bd_intf_pins MB2/S_AXI10] [get_bd_intf_pins MB3/M_AXI_IC]
  connect_bd_intf_net -intf_net MB3_TRACE [get_bd_intf_pins MB1/TraceSlave3] [get_bd_intf_pins MB3/TRACE]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_TRACE] [get_bd_intf_pins MB2/Trace3] [get_bd_intf_pins MB3/TRACE]
  connect_bd_intf_net -intf_net MB3_iic_main [get_bd_intf_pins MB3/iic_main] [get_bd_intf_pins tmr_voter_IIC_7/IIC3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_iic_main] [get_bd_intf_pins MB1/IIC3] [get_bd_intf_pins tmr_voter_IIC_7/IIC3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_iic_main] [get_bd_intf_pins MB2/IIC3] [get_bd_intf_pins tmr_voter_IIC_7/IIC3]
  connect_bd_intf_net -intf_net MB3_led_8bits [get_bd_intf_pins MB3/MB3_led_8bits] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_led_8bits] [get_bd_intf_pins MB1/GPIO3] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_led_8bits] [get_bd_intf_pins MB2/GPIO3] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO3]
  connect_bd_intf_net -intf_net MB3_rs232_uart [get_bd_intf_pins MB3/rs232_uart] [get_bd_intf_pins tmr_voter_UART_6/UART3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_rs232_uart] [get_bd_intf_pins MB1/UART3] [get_bd_intf_pins tmr_voter_UART_6/UART3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_rs232_uart] [get_bd_intf_pins MB2/UART3] [get_bd_intf_pins tmr_voter_UART_6/UART3]
  connect_bd_intf_net -intf_net MB3_tmr_sem [get_bd_intf_pins MB3/M08_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/S_AXI3]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_tmr_sem] [get_bd_intf_pins MB1/S_AXI13] [get_bd_intf_pins MB3/M08_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets MB3_tmr_sem] [get_bd_intf_pins MB2/S_AXI12] [get_bd_intf_pins MB3/M08_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins DEBUG] [get_bd_intf_pins MB1/DEBUG]
  connect_bd_intf_net -intf_net tmr_voter_AXI4LITE_0_M_AXI [get_bd_intf_pins M03_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_0/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_0_M_AXI] [get_bd_intf_pins M03_AXI] [get_bd_intf_pins MB1/M03_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_0_M_AXI] [get_bd_intf_pins M03_AXI] [get_bd_intf_pins MB2/M03_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_0_M_AXI] [get_bd_intf_pins M03_AXI] [get_bd_intf_pins MB3/M03_AXI1]
  connect_bd_intf_net -intf_net tmr_voter_AXI4LITE_1_M_AXI [get_bd_intf_pins M04_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_1/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_1_M_AXI] [get_bd_intf_pins M04_AXI] [get_bd_intf_pins MB1/M04_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_1_M_AXI] [get_bd_intf_pins M04_AXI] [get_bd_intf_pins MB2/M04_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_1_M_AXI] [get_bd_intf_pins M04_AXI] [get_bd_intf_pins MB3/M04_AXI1]
  connect_bd_intf_net -intf_net tmr_voter_AXI4LITE_2_M_AXI [get_bd_intf_pins M05_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_2/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_2_M_AXI] [get_bd_intf_pins M05_AXI] [get_bd_intf_pins MB1/M05_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_2_M_AXI] [get_bd_intf_pins M05_AXI] [get_bd_intf_pins MB2/M05_AXI1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_2_M_AXI] [get_bd_intf_pins M05_AXI] [get_bd_intf_pins MB3/M05_AXI1]
  connect_bd_intf_net -intf_net tmr_voter_AXI4LITE_8_M_AXI [get_bd_intf_pins tmr_sem_0/S_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_8_M_AXI] [get_bd_intf_pins MB1/M_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_8_M_AXI] [get_bd_intf_pins MB2/M_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4LITE_8_M_AXI] [get_bd_intf_pins MB3/M_AXI] [get_bd_intf_pins tmr_voter_AXI4LITE_8/M_AXI]
  connect_bd_intf_net -intf_net tmr_voter_AXI4_3_M_AXI [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins tmr_voter_AXI4_3/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4_3_M_AXI] [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins MB1/M_AXI_DC1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4_3_M_AXI] [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins MB2/M_AXI_DC1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4_3_M_AXI] [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins MB3/M_AXI_DC1]
  connect_bd_intf_net -intf_net tmr_voter_AXI4_4_M_AXI [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins tmr_voter_AXI4_4/M_AXI]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4_4_M_AXI] [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins MB1/M_AXI_IC1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4_4_M_AXI] [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins MB2/M_AXI_IC1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_AXI4_4_M_AXI] [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins MB3/M_AXI_IC1]
  connect_bd_intf_net -intf_net tmr_voter_GPIO_5_GPIO [get_bd_intf_pins led_8bits] [get_bd_intf_pins tmr_voter_GPIO_5/GPIO]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_GPIO_5_GPIO] [get_bd_intf_pins led_8bits] [get_bd_intf_pins MB1/led_8bits1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_GPIO_5_GPIO] [get_bd_intf_pins led_8bits] [get_bd_intf_pins MB2/led_8bits1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_GPIO_5_GPIO] [get_bd_intf_pins led_8bits] [get_bd_intf_pins MB3/led_8bits1]
  connect_bd_intf_net -intf_net tmr_voter_IIC_7_IIC [get_bd_intf_pins iic_main] [get_bd_intf_pins tmr_voter_IIC_7/IIC]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_IIC_7_IIC] [get_bd_intf_pins iic_main] [get_bd_intf_pins MB1/iic_main1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_IIC_7_IIC] [get_bd_intf_pins iic_main] [get_bd_intf_pins MB2/iic_main1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_IIC_7_IIC] [get_bd_intf_pins iic_main] [get_bd_intf_pins MB3/iic_main1]
  connect_bd_intf_net -intf_net tmr_voter_UART_6_UART [get_bd_intf_pins rs232_uart] [get_bd_intf_pins tmr_voter_UART_6/UART]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_UART_6_UART] [get_bd_intf_pins rs232_uart] [get_bd_intf_pins MB1/rs232_uart1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_UART_6_UART] [get_bd_intf_pins rs232_uart] [get_bd_intf_pins MB2/rs232_uart1]
  connect_bd_intf_net -intf_net [get_bd_intf_nets tmr_voter_UART_6_UART] [get_bd_intf_pins rs232_uart] [get_bd_intf_pins MB3/rs232_uart1]

  # Create port connections
  connect_bd_net -net Interrupt [get_bd_pins MB1/In8] [get_bd_pins MB2/In8] [get_bd_pins MB3/In8] [get_bd_pins tmr_sem_0/Interrupt]
  connect_bd_net -net MB1_Fatal_1 [get_bd_pins Fatal_1] [get_bd_pins MB1/Fatal_1]
  connect_bd_net -net MB1_LOCKSTEP_Master_Out [get_bd_pins MB1/LOCKSTEP_Master_Out] [get_bd_pins MB2/LOCKSTEP_Slave_In] [get_bd_pins MB3/LOCKSTEP_Slave_In]
  connect_bd_net -net MB1_SEM_heartbeat_expired_1 [get_bd_pins SEM_heartbeat_expired_1] [get_bd_pins MB1/SEM_heartbeat_expired_1]
  connect_bd_net -net MB1_Status_1 [get_bd_pins Status_1] [get_bd_pins MB1/Status_1]
  connect_bd_net -net MB1_To_TMR_Managers [get_bd_pins MB1/To_TMR_Managers] [get_bd_pins MB2/From_TMR_Manager_1] [get_bd_pins MB3/From_TMR_Manager_1]
  connect_bd_net -net MB2_Fatal_2 [get_bd_pins Fatal_2] [get_bd_pins MB2/Fatal_2]
  connect_bd_net -net MB2_SEM_heartbeat_expired_2 [get_bd_pins SEM_heartbeat_expired_2] [get_bd_pins MB2/SEM_heartbeat_expired_2]
  connect_bd_net -net MB2_Status_2 [get_bd_pins Status_2] [get_bd_pins MB2/Status_2]
  connect_bd_net -net MB2_To_TMR_Managers [get_bd_pins MB1/From_TMR_Manager_2] [get_bd_pins MB2/To_TMR_Managers] [get_bd_pins MB3/From_TMR_Manager_2]
  connect_bd_net -net MB3_Fatal_3 [get_bd_pins Fatal_3] [get_bd_pins MB3/Fatal_3]
  connect_bd_net -net MB3_SEM_heartbeat_expired_3 [get_bd_pins SEM_heartbeat_expired_3] [get_bd_pins MB3/SEM_heartbeat_expired_3]
  connect_bd_net -net MB3_Status_3 [get_bd_pins Status_3] [get_bd_pins MB3/Status_3]
  connect_bd_net -net MB3_To_TMR_Managers [get_bd_pins MB1/From_TMR_Manager_3] [get_bd_pins MB2/From_TMR_Manager_3] [get_bd_pins MB3/To_TMR_Managers]
  connect_bd_net -net S_AXI_ARESETN_1 [get_bd_pins S_AXI_ARESETN] [get_bd_pins tmr_sem_0/S_AXI_ARESETN]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_introut [get_bd_pins In2] [get_bd_pins MB1/In2] [get_bd_pins MB2/In2] [get_bd_pins MB3/In2]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_introut [get_bd_pins In3] [get_bd_pins MB1/In3] [get_bd_pins MB2/In3] [get_bd_pins MB3/In3]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins In0] [get_bd_pins MB1/In0] [get_bd_pins MB2/In0] [get_bd_pins MB3/In0]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins In1] [get_bd_pins MB1/In1] [get_bd_pins MB2/In1] [get_bd_pins MB3/In1]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins In5] [get_bd_pins MB1/In5] [get_bd_pins MB2/In5] [get_bd_pins MB3/In5]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins ext_reset_in] [get_bd_pins MB1/ext_reset_in] [get_bd_pins MB2/ext_reset_in] [get_bd_pins MB3/ext_reset_in]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins MB1/Clk] [get_bd_pins MB2/Clk] [get_bd_pins MB3/Clk] [get_bd_pins tmr_sem_0/S_AXI_ACLK] [get_bd_pins tmr_voter_AXI4LITE_0/Clk] [get_bd_pins tmr_voter_AXI4LITE_1/Clk] [get_bd_pins tmr_voter_AXI4LITE_2/Clk] [get_bd_pins tmr_voter_AXI4LITE_8/Clk] [get_bd_pins tmr_voter_AXI4_3/Clk] [get_bd_pins tmr_voter_AXI4_4/Clk]
  connect_bd_net -net tmr_sem_0_SEM_classification [get_bd_pins MB1/SEM_classification] [get_bd_pins MB2/SEM_classification] [get_bd_pins MB3/SEM_classification] [get_bd_pins tmr_sem_0/SEM_classification]
  connect_bd_net -net tmr_sem_0_SEM_correction [get_bd_pins MB1/SEM_correction] [get_bd_pins MB2/SEM_correction] [get_bd_pins MB3/SEM_correction] [get_bd_pins tmr_sem_0/SEM_correction]
  connect_bd_net -net tmr_sem_0_SEM_detect_only [get_bd_pins MB1/SEM_detect_only] [get_bd_pins MB2/SEM_detect_only] [get_bd_pins MB3/SEM_detect_only] [get_bd_pins tmr_sem_0/SEM_detect_only]
  connect_bd_net -net tmr_sem_0_SEM_diagnostic_scan [get_bd_pins MB1/SEM_diagnostic_scan] [get_bd_pins MB2/SEM_diagnostic_scan] [get_bd_pins MB3/SEM_diagnostic_scan] [get_bd_pins tmr_sem_0/SEM_diagnostic_scan]
  connect_bd_net -net tmr_sem_0_SEM_essential [get_bd_pins MB1/SEM_essential] [get_bd_pins MB2/SEM_essential] [get_bd_pins MB3/SEM_essential] [get_bd_pins tmr_sem_0/SEM_essential]
  connect_bd_net -net tmr_sem_0_SEM_heartbeat [get_bd_pins MB1/SEM_heartbeat] [get_bd_pins MB2/SEM_heartbeat] [get_bd_pins MB3/SEM_heartbeat] [get_bd_pins tmr_sem_0/SEM_heartbeat]
  connect_bd_net -net tmr_sem_0_SEM_initialization [get_bd_pins MB1/SEM_initialization] [get_bd_pins MB2/SEM_initialization] [get_bd_pins MB3/SEM_initialization] [get_bd_pins tmr_sem_0/SEM_initialization]
  connect_bd_net -net tmr_sem_0_SEM_injection [get_bd_pins MB1/SEM_injection] [get_bd_pins MB2/SEM_injection] [get_bd_pins MB3/SEM_injection] [get_bd_pins tmr_sem_0/SEM_injection]
  connect_bd_net -net tmr_sem_0_SEM_observation [get_bd_pins MB1/SEM_observation] [get_bd_pins MB2/SEM_observation] [get_bd_pins MB3/SEM_observation] [get_bd_pins tmr_sem_0/SEM_observation]
  connect_bd_net -net tmr_sem_0_SEM_uncorrectable [get_bd_pins MB1/SEM_uncorrectable] [get_bd_pins MB2/SEM_uncorrectable] [get_bd_pins MB3/SEM_uncorrectable] [get_bd_pins tmr_sem_0/SEM_uncorrectable]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set ddr4_sdram [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 ddr4_sdram ]

  set default_sysclk_300 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 default_sysclk_300 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {300000000} \
   ] $default_sysclk_300

  set dip_switches_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 dip_switches_4bits ]

  set iic_main [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_main ]

  set led_8bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 led_8bits ]

  set mdio_mdc [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:mdio_rtl:1.0 mdio_mdc ]

  set push_buttons_5bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 push_buttons_5bits ]

  set rotary_switch [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 rotary_switch ]

  set rs232_uart [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 rs232_uart ]

  set sgmii_lvds [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sgmii_rtl:1.0 sgmii_lvds ]

  set sgmii_phyclk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sgmii_phyclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {625000000} \
   ] $sgmii_phyclk

  set spi_flash [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 spi_flash ]


  # Create ports
  set phy_reset_out [ create_bd_port -dir O -from 0 -to 0 -type rst phy_reset_out ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset

  # Create instance: axi_ethernet_0, and set properties
  set axi_ethernet_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0 ]
  set_property -dict [ list \
   CONFIG.DIFFCLK_BOARD_INTERFACE {sgmii_phyclk} \
   CONFIG.ENABLE_LVDS {true} \
   CONFIG.ETHERNET_BOARD_INTERFACE {sgmii_lvds} \
   CONFIG.MDIO_BOARD_INTERFACE {mdio_mdc} \
   CONFIG.PHYRST_BOARD_INTERFACE {phy_reset_out} \
   CONFIG.PHY_TYPE {SGMII} \
   CONFIG.lvdsclkrate {625} \
 ] $axi_ethernet_0

  # Create instance: axi_ethernet_0_dma, and set properties
  set axi_ethernet_0_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_0_dma ]
  set_property -dict [ list \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_sg_length_width {16} \
   CONFIG.c_sg_use_stsapp_length {1} \
 ] $axi_ethernet_0_dma

  # Create instance: axi_quad_spi_0, and set properties
  set axi_quad_spi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0 ]
  set_property -dict [ list \
   CONFIG.C_DUAL_QUAD_MODE {1} \
   CONFIG.C_FIFO_DEPTH {256} \
   CONFIG.C_NUM_SS_BITS {2} \
   CONFIG.C_SCK_RATIO {2} \
   CONFIG.C_SPI_MEMORY {2} \
   CONFIG.C_SPI_MODE {2} \
   CONFIG.C_USE_STARTUP {1} \
   CONFIG.C_USE_STARTUP_INT {1} \
   CONFIG.QSPI_BOARD_INTERFACE {spi_flash} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_quad_spi_0

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_CLKS {2} \
   CONFIG.NUM_SI {5} \
 ] $axi_smc

  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 ddr4_0 ]
  set_property -dict [ list \
   CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {100} \
   CONFIG.C0.BANK_GROUP_WIDTH {1} \
   CONFIG.C0.DDR4_AxiAddressWidth {31} \
   CONFIG.C0.DDR4_AxiDataWidth {512} \
   CONFIG.C0.DDR4_CLKFBOUT_MULT {4} \
   CONFIG.C0.DDR4_DataWidth {64} \
   CONFIG.C0.DDR4_InputClockPeriod {3332} \
   CONFIG.C0.DDR4_MemoryPart {MT40A256M16LY-062E} \
   CONFIG.C0_CLOCK_BOARD_INTERFACE {default_sysclk_300} \
   CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_062} \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
 ] $ddr4_0

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_1 ]

  # Create instance: rst_ddr4_0_100M, and set properties
  set rst_ddr4_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_100M ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $rst_ddr4_0_100M

  # Create instance: rst_ddr4_0_300M, and set properties
  set rst_ddr4_0_300M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ddr4_0_300M ]

  # Create instance: tmr_0
  create_hier_cell_tmr_0 [current_bd_instance .] tmr_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXIS_CNTRL [get_bd_intf_pins axi_ethernet_0/s_axis_txc] [get_bd_intf_pins axi_ethernet_0_dma/M_AXIS_CNTRL]
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXIS_MM2S [get_bd_intf_pins axi_ethernet_0/s_axis_txd] [get_bd_intf_pins axi_ethernet_0_dma/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXI_MM2S [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S] [get_bd_intf_pins axi_smc/S03_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXI_S2MM [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM] [get_bd_intf_pins axi_smc/S04_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXI_SG [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_SG] [get_bd_intf_pins axi_smc/S02_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxd [get_bd_intf_pins axi_ethernet_0/m_axis_rxd] [get_bd_intf_pins axi_ethernet_0_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxs [get_bd_intf_pins axi_ethernet_0/m_axis_rxs] [get_bd_intf_pins axi_ethernet_0_dma/S_AXIS_STS]
  connect_bd_intf_net -intf_net axi_ethernet_0_mdio [get_bd_intf_ports mdio_mdc] [get_bd_intf_pins axi_ethernet_0/mdio]
  connect_bd_intf_net -intf_net axi_ethernet_0_sgmii [get_bd_intf_ports sgmii_lvds] [get_bd_intf_pins axi_ethernet_0/sgmii]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports led_8bits] [get_bd_intf_pins tmr_0/led_8bits]
  connect_bd_intf_net -intf_net axi_iic_0_IIC [get_bd_intf_ports iic_main] [get_bd_intf_pins tmr_0/iic_main]
  connect_bd_intf_net -intf_net axi_quad_spi_0_SPI_1 [get_bd_intf_ports spi_flash] [get_bd_intf_pins axi_quad_spi_0/SPI_1]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports rs232_uart] [get_bd_intf_pins tmr_0/rs232_uart]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports ddr4_sdram] [get_bd_intf_pins ddr4_0/C0_DDR4]
  connect_bd_intf_net -intf_net default_sysclk_300_1 [get_bd_intf_ports default_sysclk_300] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DC [get_bd_intf_pins axi_smc/S00_AXI] [get_bd_intf_pins tmr_0/M_AXI_DC]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_IC [get_bd_intf_pins axi_smc/S01_AXI] [get_bd_intf_pins tmr_0/M_AXI_IC]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE] [get_bd_intf_pins tmr_0/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M04_AXI [get_bd_intf_pins axi_ethernet_0/s_axi] [get_bd_intf_pins tmr_0/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_quad_spi_0/AXI_LITE] [get_bd_intf_pins tmr_0/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins tmr_0/DEBUG]
  connect_bd_intf_net -intf_net sgmii_phyclk_1 [get_bd_intf_ports sgmii_phyclk] [get_bd_intf_pins axi_ethernet_0/lvds_clk]
  connect_bd_intf_net -intf_net tmr_0_dip_switches_4bits [get_bd_intf_ports dip_switches_4bits] [get_bd_intf_pins tmr_0/dip_switches_4bits]
  connect_bd_intf_net -intf_net tmr_0_push_buttons_5bits [get_bd_intf_ports push_buttons_5bits] [get_bd_intf_pins tmr_0/push_buttons_5bits]
  connect_bd_intf_net -intf_net tmr_0_rotary_switch [get_bd_intf_ports rotary_switch] [get_bd_intf_pins tmr_0/rotary_switch]

  # Create port connections
  connect_bd_net -net axi_ethernet_0_dma_mm2s_cntrl_reset_out_n [get_bd_pins axi_ethernet_0/axi_txc_arstn] [get_bd_pins axi_ethernet_0_dma/mm2s_cntrl_reset_out_n]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_introut [get_bd_pins axi_ethernet_0_dma/mm2s_introut] [get_bd_pins tmr_0/In2]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_prmry_reset_out_n [get_bd_pins axi_ethernet_0/axi_txd_arstn] [get_bd_pins axi_ethernet_0_dma/mm2s_prmry_reset_out_n]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_introut [get_bd_pins axi_ethernet_0_dma/s2mm_introut] [get_bd_pins tmr_0/In3]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_prmry_reset_out_n [get_bd_pins axi_ethernet_0/axi_rxd_arstn] [get_bd_pins axi_ethernet_0_dma/s2mm_prmry_reset_out_n]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_sts_reset_out_n [get_bd_pins axi_ethernet_0/axi_rxs_arstn] [get_bd_pins axi_ethernet_0_dma/s2mm_sts_reset_out_n]
  connect_bd_net -net axi_ethernet_0_interrupt [get_bd_pins axi_ethernet_0/interrupt] [get_bd_pins tmr_0/In0]
  connect_bd_net -net axi_ethernet_0_mac_irq [get_bd_pins axi_ethernet_0/mac_irq] [get_bd_pins tmr_0/In1]
  connect_bd_net -net axi_ethernet_0_phy_rst_n [get_bd_ports phy_reset_out] [get_bd_pins axi_ethernet_0/phy_rst_n]
  connect_bd_net -net axi_quad_spi_0_ip2intc_irpt [get_bd_pins axi_quad_spi_0/ip2intc_irpt] [get_bd_pins tmr_0/In5]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk [get_bd_pins axi_ethernet_0/axis_clk] [get_bd_pins axi_ethernet_0_dma/m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_0_dma/m_axi_s2mm_aclk] [get_bd_pins axi_ethernet_0_dma/m_axi_sg_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins rst_ddr4_0_300M/slowest_sync_clk]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] [get_bd_pins rst_ddr4_0_300M/ext_reset_in]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_ddr4_0_100M/mb_debug_sys_rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins axi_ethernet_0/s_axi_lite_clk] [get_bd_pins axi_ethernet_0_dma/s_axi_lite_aclk] [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins axi_quad_spi_0/s_axi_aclk] [get_bd_pins axi_smc/aclk1] [get_bd_pins ddr4_0/addn_ui_clkout1] [get_bd_pins rst_ddr4_0_100M/slowest_sync_clk] [get_bd_pins tmr_0/Clk]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins ddr4_0/sys_rst] [get_bd_pins rst_ddr4_0_100M/ext_reset_in]
  connect_bd_net -net rst_ddr4_0_100M_peripheral_aresetn [get_bd_pins axi_ethernet_0/s_axi_lite_resetn] [get_bd_pins axi_ethernet_0_dma/axi_resetn] [get_bd_pins axi_quad_spi_0/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins rst_ddr4_0_100M/peripheral_aresetn] [get_bd_pins tmr_0/S_AXI_ARESETN]
  connect_bd_net -net rst_ddr4_0_100M_peripheral_reset [get_bd_pins rst_ddr4_0_100M/peripheral_reset] [get_bd_pins tmr_0/ext_reset_in]
  connect_bd_net -net rst_ddr4_0_300M_peripheral_aresetn [get_bd_pins ddr4_0/c0_ddr4_aresetn] [get_bd_pins rst_ddr4_0_300M/peripheral_aresetn]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins axi_ethernet_0/signal_detect] [get_bd_pins xlconstant_0/dout]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_ethernet_0_dma/Data_SG] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_ethernet_0_dma/Data_MM2S] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces axi_ethernet_0_dma/Data_S2MM] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x40C00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0/s_axi/Reg0] -force
  assign_bd_address -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_gpio_ds/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_gpio_pb/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_gpio_rs/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x41C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_timer_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Instruction] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Instruction] [get_bd_addr_segs tmr_0/MB1/microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB1/tmr_manager_0/SLMB/Reg] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB1/microblaze_0/Data] [get_bd_addr_segs tmr_0/tmr_sem_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40C00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0/s_axi/Reg0] -force
  assign_bd_address -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_gpio_mb2_ds/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_gpio_mb2_pb/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_gpio_mb2_rs/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x41C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_timer_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Instruction] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Instruction] [get_bd_addr_segs tmr_0/MB2/microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB2/tmr_manager_0/SLMB/Reg] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB2/microblaze_0/Data] [get_bd_addr_segs tmr_0/tmr_sem_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40C00000 -range 0x00040000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0/s_axi/Reg0] -force
  assign_bd_address -offset 0x41E00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs axi_ethernet_0_dma/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_gpio_mb3_ds/S_AXI/Reg] -force
  assign_bd_address -offset 0x40020000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_gpio_mb3_pb/S_AXI/Reg] -force
  assign_bd_address -offset 0x40030000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_gpio_mb3_rs/S_AXI/Reg] -force
  assign_bd_address -offset 0x40800000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_iic_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs axi_quad_spi_0/AXI_LITE/Reg] -force
  assign_bd_address -offset 0x41C00000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_timer_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/axi_uartlite_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Instruction] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x00000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Instruction] [get_bd_addr_segs tmr_0/MB3/microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x41200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/microblaze_0_axi_intc/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/MB3/tmr_manager_0/SLMB/Reg] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces tmr_0/MB3/microblaze_0/Data] [get_bd_addr_segs tmr_0/tmr_sem_0/S_AXI/Reg] -force
 

  # Restore current instance
  current_bd_instance $oldCurInst


  validate_bd_design
  save_bd_design
}
# End of create_root_design()



##################################################################
# MAIN FLOW
##################################################################

create_root_design ""

open_bd_design [get_bd_files $design_name]
	
	make_wrapper -files [get_files $design_name.bd] -top -import -quiet
	regenerate_bd_layout
	puts "INFO: End of create_root_design"
}

