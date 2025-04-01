

proc create_quad {parentCell nameHier refclk_name gt_type line_rate refclk_freq} {
    set parentObj [get_bd_cells $parentCell]
    # Set parent object as current
    current_bd_instance $parentObj

    create_bd_cell -type ip -vlnv xilinx.com:ip:prbs_generator_checker bridge

    #source [::bd::get_vlnv_dir xilinx.com:ip:gt_quad_base:1.1]/tcl/params.tcl
    #puts "# got params.tcl"
    if {$gt_type eq "GTM"} {
        if {$line_rate > 19.0} {
            set pam_sel "PAM4"
        } else {
            set pam_sel "NRZ"
        }
	create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf
	set_property CONFIG.C_BUF_TYPE {IBUFDS_GTME5} [get_bd_cells util_ds_buf]
	make_bd_intf_pins_external  [get_bd_intf_pins util_ds_buf/CLK_IN_D1]
	#set_property name gt_refclk_$name [get_bd_intf_ports CLK_IN_D1_0]
	create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant xlconstant
	set_property CONFIG.CONST_VAL {0} [get_bd_cells xlconstant]
	connect_bd_net [get_bd_pins xlconstant/dout] [get_bd_pins util_ds_buf/IBUFDS_GTME5_CEB]
        set width [expr $line_rate > 57.0 ? 320 : 160]
        set user_settings_dict [dict create TX_LINE_RATE $line_rate TX_REFCLK_FREQUENCY $refclk_freq RX_LINE_RATE $line_rate RX_REFCLK_FREQUENCY $refclk_freq GT_TYPE GTM RX_PAM_SEL $pam_sel TX_PAM_SEL $pam_sel TX_USER_DATA_WIDTH $width RX_USER_DATA_WIDTH $width TX_OUTCLK_SOURCE TXPROGDIVCLK RX_OUTCLK_SOURCE RXPROGDIVCLK]
    } else {
	create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf util_ds_buf
	set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} [get_bd_cells util_ds_buf]
	make_bd_intf_pins_external  [get_bd_intf_pins util_ds_buf/CLK_IN_D]
	#set_property name gt_refclk_$name [get_bd_intf_ports CLK_IN_D_0]
        set user_settings_dict [dict create TX_LINE_RATE $line_rate TX_REFCLK_FREQUENCY $refclk_freq RX_LINE_RATE $line_rate RX_REFCLK_FREQUENCY $refclk_freq ]
    }

    set settings_dict [dict create LR0 $user_settings_dict]
    set complete_settings [get_GT_string "None" $settings_dict ""]
    set values [dict create ]
    set values [dict get $complete_settings LR0_SETTINGS]
    set_property -dict [list \
        CONFIG.IP_NO_OF_LANES 4 \
        CONFIG.GT_TYPE $gt_type \
        CONFIG.IP_LR0_SETTINGS $values \
        ] [get_bd_cells bridge]

   

   create_bd_cell -type ip -vlnv xilinx.com:ip:gtwiz_versal gtwiz_versal
   create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_tx
   create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt bufg_gt_rx

           set_property -dict [list \
          CONFIG.INTF0_NO_OF_LANES 4 \
          CONFIG.GT_TYPE $gt_type \
          CONFIG.NO_OF_QUADS {1} \
          ] [get_bd_cells gtwiz_versal]
	
	connect_bd_net [get_bd_pins bufg_gt_tx/usrclk] [get_bd_pins bridge/gt_txusrclk] [get_bd_pins gtwiz_versal/QUAD0_TX0_usrclk] [get_bd_pins gtwiz_versal/QUAD0_TX1_usrclk] [get_bd_pins gtwiz_versal/QUAD0_TX2_usrclk] [get_bd_pins gtwiz_versal/QUAD0_TX3_usrclk]
	connect_bd_net [get_bd_pins bufg_gt_rx/usrclk] [get_bd_pins bridge/gt_rxusrclk] [get_bd_pins gtwiz_versal/QUAD0_RX0_usrclk] [get_bd_pins gtwiz_versal/QUAD0_RX1_usrclk] [get_bd_pins gtwiz_versal/QUAD0_RX2_usrclk] [get_bd_pins gtwiz_versal/QUAD0_RX3_usrclk]

	connect_bd_intf_net [get_bd_intf_pins bridge/GT_TX0] [get_bd_intf_pins gtwiz_versal/INTF0_TX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_TX1] [get_bd_intf_pins gtwiz_versal/INTF0_TX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_TX2] [get_bd_intf_pins gtwiz_versal/INTF0_TX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_TX3] [get_bd_intf_pins gtwiz_versal/INTF0_TX3_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_RX0] [get_bd_intf_pins gtwiz_versal/INTF0_RX0_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_RX1] [get_bd_intf_pins gtwiz_versal/INTF0_RX1_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_RX2] [get_bd_intf_pins gtwiz_versal/INTF0_RX2_GT_IP_Interface]
	connect_bd_intf_net [get_bd_intf_pins bridge/GT_RX3] [get_bd_intf_pins gtwiz_versal/INTF0_RX3_GT_IP_Interface]

	make_bd_intf_pins_external  [get_bd_intf_pins gtwiz_versal/Quad0_GT_Serial]

        if {$gt_type eq "GTM"} {
          connect_bd_net [get_bd_pins util_ds_buf/IBUFDS_GTME5_O] [get_bd_pins gtwiz_versal/QUAD0_GTREFCLK0]
	} else {
          connect_bd_net [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins gtwiz_versal/QUAD0_GTREFCLK0]
	}

    #puts "renaming refclks"
    if {$gt_type eq "GTM"} {
      set_property name bridge_refclk${refclk_name}_diff_gt_ref_clock [get_bd_intf_ports CLK_IN_D1_0]  	
    } else {
      set_property name bridge_refclk${refclk_name}_diff_gt_ref_clock [get_bd_intf_ports CLK_IN_D_0]
    }
    puts "creating hierarchy and clock port"
    if {$gt_type eq "GTM"} { 
      group_bd_cells $nameHier [get_bd_cells bufg_gt_tx] [get_bd_cells bridge] [get_bd_cells gtwiz_versal] [get_bd_cells bufg_gt_rx] [get_bd_cells util_ds_buf] [get_bd_cells xlconstant]
    } else {
      group_bd_cells $nameHier [get_bd_cells bufg_gt_tx] [get_bd_cells bridge] [get_bd_cells gtwiz_versal] [get_bd_cells bufg_gt_rx] [get_bd_cells util_ds_buf]
    }
    current_bd_instance $nameHier
    create_bd_pin -dir I -type clk apb3clk
    connect_bd_net [get_bd_pins gtwiz_versal/QUAD0_TX0_outclk] [get_bd_pins bufg_gt_tx/outclk]
    connect_bd_net [get_bd_pins gtwiz_versal/QUAD0_RX0_outclk] [get_bd_pins bufg_gt_rx/outclk]
    connect_bd_net [get_bd_pins gtwiz_versal/INTF0_TX_clr_out] [get_bd_pins bufg_gt_tx/gt_bufgtclr]
    connect_bd_net [get_bd_pins gtwiz_versal/INTF0_TX_clr_out] [get_bd_pins bufg_gt_rx/gt_bufgtclr]
    connect_bd_net [get_bd_pins gtwiz_versal/INTF0_rst_tx_done_out] [get_bd_pins bridge/tx_reset_in]
    connect_bd_net [get_bd_pins gtwiz_versal/INTF0_rst_rx_done_out] [get_bd_pins bridge/rx_reset_in]
    connect_bd_net [get_bd_pins apb3clk] [get_bd_pins bridge/apb3clk] [get_bd_pins gtwiz_versal/gtwiz_freerun_clk]

    current_bd_instance $parentCell

}
