

proc create_quad {parentCell nameHier refclk_name gt_type line_rate refclk_freq} {
    set parentObj [get_bd_cells $parentCell]
    # Set parent object as current
    current_bd_instance $parentObj

    create_bd_cell -type ip -vlnv xilinx.com:ip:gt_bridge_ip bridge

    source [::bd::get_vlnv_dir xilinx.com:ip:gt_quad_base:1.1]/tcl/params.tcl
    puts "# got params.tcl"
    if {$gt_type eq "GTM"} {
        if {$line_rate > 19.0} {
            set pam_sel "PAM4"
        } else {
            set pam_sel "NRZ"
        }
        set width [expr $line_rate > 57.0 ? 320 : 160]
        set user_settings_dict [dict create TX_LINE_RATE $line_rate TX_REFCLK_FREQUENCY $refclk_freq RX_LINE_RATE $line_rate RX_REFCLK_FREQUENCY $refclk_freq GT_TYPE GTM RX_PAM_SEL $pam_sel TX_PAM_SEL $pam_sel TX_USER_DATA_WIDTH $width RX_USER_DATA_WIDTH $width TX_OUTCLK_SOURCE TXPROGDIVCLK RX_OUTCLK_SOURCE RXPROGDIVCLK]
    } else {
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

   
    apply_bd_automation -rule xilinx.com:bd_rule:gt_ips -config { \
        Auto_Connect_Refclk_ports {1} \
            Auto_Connect_UsrClk_and_OutClks {1} \
            DataPath_Interface_Connection {Start_With_New_Quad} \
            Reset_Connection_Automation {1}\
            }  [get_bd_cells bridge]
    
    # trim unneeded ports, and reconnect apb clock to CIPS
    puts "removing extra GT ports"
    delete_bd_objs [get_bd_nets bridge_link_status_out] [get_bd_ports link_status_bridge]
    delete_bd_objs [get_bd_nets bridge_tx_resetdone_out] [get_bd_ports tx_resetdone_out_bridge]
    delete_bd_objs [get_bd_nets bridge_rx_resetdone_out] [get_bd_ports rx_resetdone_out_bridge]
    delete_bd_objs [get_bd_nets bridge_txusrclk_out] [get_bd_ports txusrclk_bridge]
    delete_bd_objs [get_bd_nets bridge_rxusrclk_out] [get_bd_ports rxusrclk_bridge]
    delete_bd_objs [get_bd_nets bridge_rpll_lock_out] [get_bd_ports rpll_lock_bridge]
    delete_bd_objs [get_bd_nets bridge_lcpll_lock_out] [get_bd_ports lcpll_lock_bridge]
    delete_bd_objs [get_bd_nets gt_reset_bridge_1] [get_bd_ports gt_reset_bridge]
    delete_bd_objs [get_bd_nets rate_sel_bridge_1] [get_bd_ports rate_sel_bridge]
    delete_bd_objs [get_bd_nets apb3clk_bridge_1] [get_bd_ports apb3clk_bridge]
    delete_bd_objs [get_bd_nets apb3clk_quad_1] [get_bd_ports apb3clk_quad]

    puts "renaming refclks"
    set_property name bridge_refclk${refclk_name}_diff_gt_ref_clock [get_bd_intf_ports bridge_diff_gt_ref_clock]
    set_property name bridge_refclk${refclk_name}_diff_gt_ref_clock_1 [get_bd_intf_nets bridge_diff_gt_ref_clock_1]
    
    puts "creating hierarchy and clock port"
    group_bd_cells $nameHier [get_bd_cells bufg_gt] [get_bd_cells bridge] [get_bd_cells gt_quad_base] [get_bd_cells urlp] [get_bd_cells bufg_gt_1] [get_bd_cells util_ds_buf] [get_bd_cells xlcp] [get_bd_cells xlconstant]
    current_bd_instance $nameHier
    create_bd_pin -dir I -type clk apb3clk
    connect_bd_net [get_bd_pins apb3clk] [get_bd_pins bridge/apb3clk] [get_bd_pins gt_quad_base/apb3clk]

    current_bd_instance $parentCell

}
