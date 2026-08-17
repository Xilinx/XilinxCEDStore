import ext_cfg_pkg::*;

`uvm_analysis_imp_decl(_ext_cfg_rx)
`uvm_analysis_imp_decl(_ext_cfg_tx)
class bmd_extended_config_scoreboard_c extends uvm_scoreboard;
    `uvm_component_utils(bmd_extended_config_scoreboard_c)

    apci_tlp configs[$];

    uvm_analysis_imp_ext_cfg_rx #(apci_packet, bmd_extended_config_scoreboard_c) rxp;
    uvm_analysis_imp_ext_cfg_tx #(apci_packet, bmd_extended_config_scoreboard_c) txp;

    bit main_phase_started;

    // VSEC
    //////////////////////////////////////////
    bit [9:0] PCIE_EXT_CAP_ADDR;
    bit [9:0] PCIE_VSEC_ADDR;
    bit [9:0] VSEC_STATUS_ADDR;
    bit [9:0] VSEC_CONTROL_ADDR;

    bit [31:0] pcie_ext_cap_header;
    bit [31:0] pcie_vsec_header;
    bit [31:0] vsec_status_reg;
    bit [31:0] vsec_control_reg;

    // TPH
    //////////////////////////////////////////
    bit [9:0] TPH_REQ_EXT_CAP_ADDR;
    bit [9:0] TPH_REQ_CAP_REG_ADDR;
    bit [9:0] TPH_REQ_CTRL_REG_ADDR;
    bit [9:0] TPH_ST_TABLE_ADDR;

    bit [31:0] tph_ext_cap_header;
    bit [31:0] tph_cap_reg;
    bit [31:0] tph_ctrl_reg;
    bit [((ST_TABLE_SIZE + 1) >> 1)-1:0][31:0] tph_st_table;

    // Constructor
    function new(string name = "bmd_extended_config_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        rxp = new("rxp", this);
        txp = new("txp", this);

        // VSEC
        PCIE_EXT_CAP_ADDR       = VSEC_BASE_ADDRESS[11:2] + 0;
        PCIE_VSEC_ADDR          = VSEC_BASE_ADDRESS[11:2] + 1;
        VSEC_STATUS_ADDR        = VSEC_BASE_ADDRESS[11:2] + 2;
        VSEC_CONTROL_ADDR       = VSEC_BASE_ADDRESS[11:2] + 3;

        pcie_ext_cap_header     = {VSEC_NEXT_CAP, 4'h0, 16'h000B};
        pcie_vsec_header        = {VSEC_CAP_LENGTH, PCIE_VSEC_REV, PCIE_VSEC_ID};
        vsec_status_reg         = 32'h0000_0000;
        vsec_control_reg        = 32'h0403_0201;

        // TPH
        TPH_REQ_EXT_CAP_ADDR    = TPH_BASE_ADDRESS[11:2] + 0;
        TPH_REQ_CAP_REG_ADDR    = TPH_BASE_ADDRESS[11:2] + 1;
        TPH_REQ_CTRL_REG_ADDR   = TPH_BASE_ADDRESS[11:2] + 2;
        TPH_ST_TABLE_ADDR       = TPH_BASE_ADDRESS[11:2] + 3;

        tph_ext_cap_header      = {TPH_NEXT_CAP, 4'h1, 16'h0017};
        tph_cap_reg             = {5'h0, ST_TABLE_SIZE, 5'h0, ST_TABLE_LOC, EXT_TPH_REQ_SUP, 5'h0,
                                    DEV_SPEC_MODE_SUP, INT_VEC_MODE_SUP, NO_ST_MODE_SUP};
        tph_ctrl_reg            = '0;
        tph_st_table            = '0;
    endfunction

    function void clear();
        configs.delete();
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        phase.raise_objection(this);
        super.build_phase(phase);
        main_phase_started = 0;
        phase.drop_objection(this);
    endfunction

    task main_phase(uvm_phase phase);
        main_phase_started = 1;
    endtask

    // Write method - called when transaction received
    virtual function void write_ext_cfg_rx(apci_packet trans);
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                if (tlp.kind inside {APCI_TLP_cpl, APCI_TLP_cpld}) begin
                    configs.push_back(tlp);
                end
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from rx packet to rx tlp")
            end
        end
    endfunction

    // Write method - called when transaction sent
    virtual function void write_ext_cfg_tx(apci_packet trans);
        if (main_phase_started) begin
            apci_tlp tlp;
            if($cast(tlp, trans)) begin
                if (tlp.kind inside {APCI_TLP_cfgrd, APCI_TLP_cfgwr}) begin
                    configs.push_back(tlp);
                end
            end else begin
                `uvm_error(get_type_name(), "Failed to cast from tx packet to tx tlp")
            end
        end
    endfunction

    virtual function void call_report();
        bit [3:0]         this_first_be;
        bit [3:0]         this_last_be;

        // Assumes config tags never exceed 64
        bit [63:0]        rd_tags;
        bit [31:0][63:0]  rd_addr;
        bit [31:0][63:0]  rd_data;

        bit [63:0]        wr_tags;
        bit [31:0][63:0]  wr_addr;
        bit [31:0][63:0]  wr_data;
        foreach (configs[i]) begin
            if (configs[i].kind inside {APCI_TLP_cfgrd, APCI_TLP_cfgwr}) begin
                this_first_be = 4'hF;
                this_last_be = 4'hF;

                if (configs[i].u.fm_com.ohc[0]) begin
                    this_first_be = configs[i].ohc[0].ohc_a1.fbe;
                    this_last_be  = configs[i].ohc[0].ohc_a1.lbe;
                end

                if (configs[i].u.fm_cfg.reg_no >= VSEC_BASE_ADDRESS[11:2] ||
                    configs[i].u.fm_cfg.reg_no >= TPH_BASE_ADDRESS[11:2]) begin
                        if (configs[i].kind == APCI_TLP_cfgrd) begin // READ REQUEST
                            rd_tags[configs[i].u.fm_cfg.tag] = 1'b1;
                            rd_addr[configs[i].u.fm_cfg.tag] = configs[i].u.fm_cfg.reg_no;
                            rd_data[configs[i].u.fm_cfg.tag] = '0;
                            case (configs[i].u.fm_cfg.reg_no)
                                PCIE_EXT_CAP_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = pcie_ext_cap_header;
                                end

                                PCIE_VSEC_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = pcie_vsec_header;
                                end

                                VSEC_STATUS_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = vsec_status_reg;
                                end

                                VSEC_CONTROL_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = vsec_control_reg;
                                end

                                TPH_REQ_EXT_CAP_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = tph_ext_cap_header;
                                end

                                TPH_REQ_CAP_REG_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = tph_cap_reg;
                                end

                                TPH_REQ_CTRL_REG_ADDR : begin
                                    rd_data[configs[i].u.fm_cfg.tag] = tph_ctrl_reg;
                                end

                                default : begin
                                    if (configs[i].u.fm_cfg.reg_no <= TPH_ST_TABLE_ADDR + ((ST_TABLE_SIZE + 1) >> 1) &&
                                            configs[i].u.fm_cfg.reg_no > TPH_REQ_CTRL_REG_ADDR) begin
                                        rd_data[configs[i].u.fm_cfg.tag] = tph_st_table
                                                                                [configs[i].u.fm_cfg.reg_no -
                                                                                    TPH_ST_TABLE_ADDR];
                                    end else begin
                                        rd_data[configs[i].u.fm_cfg.tag] = '0;
                                    end
                                end
                            endcase
                        end else if (configs[i].kind == APCI_TLP_cfgwr) begin // WRITE REQUEST
                            wr_tags[configs[i].u.fm_cfg.tag] = 1'b1;
                            wr_addr[configs[i].u.fm_cfg.tag] = configs[i].u.fm_cfg.reg_no;
                            wr_data[configs[i].u.fm_cfg.tag] = '0;
                            case (configs[i].u.fm_cfg.reg_no)
                                PCIE_EXT_CAP_ADDR : begin
                                    wr_data[configs[i].u.fm_cfg.tag] = pcie_ext_cap_header; // Not writeable
                                end

                                PCIE_VSEC_ADDR : begin
                                    wr_data[configs[i].u.fm_cfg.tag] = pcie_vsec_header; // Not writeable
                                end

                                VSEC_STATUS_ADDR : begin
                                    wr_data[configs[i].u.fm_cfg.tag] = vsec_status_reg; // Not writeable
                                end

                                VSEC_CONTROL_ADDR : begin
                                    wr_data[configs[i].u.fm_cfg.tag][7:0]   = this_first_be[0] ?
                                                                                configs[i].payload[0][7:0]   :
                                                                                vsec_control_reg[7:0];
                                    wr_data[configs[i].u.fm_cfg.tag][15:8]  = this_first_be[1] ?
                                                                                configs[i].payload[0][15:8]  :
                                                                                vsec_control_reg[15:8];
                                    wr_data[configs[i].u.fm_cfg.tag][23:16] = this_first_be[2] ?
                                                                                configs[i].payload[0][23:16] :
                                                                                vsec_control_reg[23:16];
                                    wr_data[configs[i].u.fm_cfg.tag][31:24] = this_first_be[3] ?
                                                                                configs[i].payload[0][31:24] :
                                                                                vsec_control_reg[31:24];
                                end

                                TPH_REQ_EXT_CAP_ADDR : begin
                                    wr_data[configs[i].u.fm_cfg.tag] = tph_ext_cap_header; // Not writeable
                                end

                                TPH_REQ_CAP_REG_ADDR : begin
                                    wr_data[configs[i].u.fm_cfg.tag] = tph_cap_reg; // Not writeable
                                end

                                TPH_REQ_CTRL_REG_ADDR : begin
                                    if (this_first_be[0]) begin
                                        case(configs[i].payload[0][2:0])
                                            3'h0 : wr_data[configs[i].u.fm_cfg.tag][2:0] = '0;
                                            3'h1 : wr_data[configs[i].u.fm_cfg.tag][2:0] = INT_VEC_MODE_SUP  ?
                                                                                                    3'h1 :
                                                                                                    tph_ctrl_reg[2:0];
                                            3'h2 : wr_data[configs[i].u.fm_cfg.tag][2:0] = DEV_SPEC_MODE_SUP ?
                                                                                                    3'h2 :
                                                                                                    tph_ctrl_reg[2:0];
                                            default : wr_data[configs[i].u.fm_cfg.tag][2:0] = tph_ctrl_reg[2:0];
                                        endcase
                                    end else begin
                                        wr_data[configs[i].u.fm_cfg.tag][2:0] = tph_ctrl_reg[2:0];
                                    end

                                    if (this_first_be[1]) begin
                                        case(configs[i].payload[0][9:8])
                                            2'b00 : wr_data[configs[i].u.fm_cfg.tag][9:8] = 2'b00;
                                            2'b01 : wr_data[configs[i].u.fm_cfg.tag][9:8] = 2'b01;
                                            2'b11 : wr_data[configs[i].u.fm_cfg.tag][9:8] = EXT_TPH_REQ_SUP ?
                                                                                                2'b11 :
                                                                                                tph_ctrl_reg[9:8];
                                            default : wr_data[configs[i].u.fm_cfg.tag][9:8] = tph_ctrl_reg[9:8];
                                        endcase
                                    end else begin
                                        wr_data[configs[i].u.fm_cfg.tag][9:8] = tph_ctrl_reg[9:8];
                                    end
                                end

                                default : begin
                                    if (configs[i].u.fm_cfg.reg_no <= TPH_ST_TABLE_ADDR + ((ST_TABLE_SIZE + 1) >> 1) &&
                                            configs[i].u.fm_cfg.reg_no > TPH_REQ_CTRL_REG_ADDR) begin
                                        wr_data[configs[i].u.fm_cfg.tag][7:0]   = this_first_be[0] ?
                                                                                    configs[i].payload[0][7:0] :
                                                                                    tph_st_table
                                                                                        [configs[i].u.fm_cfg.reg_no -
                                                                                            TPH_ST_TABLE_ADDR][7:0];
                                        wr_data[configs[i].u.fm_cfg.tag][15:8]  = this_first_be[1] ?
                                                                                    configs[i].payload[0][15:8] :
                                                                                    tph_st_table
                                                                                        [configs[i].u.fm_cfg.reg_no -
                                                                                            TPH_ST_TABLE_ADDR][15:8];
                                        wr_data[configs[i].u.fm_cfg.tag][23:16] = this_first_be[2] ?
                                                                                    configs[i].payload[0][23:16] :
                                                                                    tph_st_table
                                                                                        [configs[i].u.fm_cfg.reg_no -
                                                                                            TPH_ST_TABLE_ADDR][23:16];
                                        wr_data[configs[i].u.fm_cfg.tag][31:24] = this_first_be[3] ?
                                                                                    configs[i].payload[0][31:24] :
                                                                                    tph_st_table
                                                                                        [configs[i].u.fm_cfg.reg_no -
                                                                                            TPH_ST_TABLE_ADDR][31:24];
                                    end else begin
                                        wr_data[configs[i].u.fm_cfg.tag] = '0;
                                    end
                                end
                            endcase
                        end
                end
            end

            if (configs[i].kind == APCI_TLP_cpl) begin // WRITE COMPLETION
                if (wr_tags[configs[i].u.fm_cpl.tag]) begin
                    case (wr_addr[configs[i].u.fm_cpl.tag])
                        VSEC_CONTROL_ADDR : begin
                            vsec_control_reg = wr_data[configs[i].u.fm_cpl.tag];
                        end

                        TPH_REQ_CTRL_REG_ADDR : begin
                            tph_ctrl_reg = wr_data[configs[i].u.fm_cpl.tag];
                        end

                        default : begin
                            if (wr_addr[configs[i].u.fm_cpl.tag] <= TPH_ST_TABLE_ADDR + ((ST_TABLE_SIZE + 1) >> 1) &&
                                    wr_addr[configs[i].u.fm_cpl.tag] > TPH_REQ_CTRL_REG_ADDR) begin
                                tph_st_table[wr_addr[configs[i].u.fm_cpl.tag] - TPH_ST_TABLE_ADDR] =
                                    wr_data[configs[i].u.fm_cpl.tag];
                            end
                        end
                    endcase
                    wr_data[configs[i].u.fm_cpl.tag] = '0;
                    wr_addr[configs[i].u.fm_cpl.tag] = '0;
                    wr_tags[configs[i].u.fm_cpl.tag] = 1'b0;
                end
            end else if (configs[i].kind == APCI_TLP_cpld) begin // READ COMPLETION
                if (rd_tags[configs[i].u.fm_cpl.tag]) begin
                    if (rd_data[configs[i].u.fm_cpl.tag] != configs[i].payload[0]) begin
                        `uvm_error(get_type_name(), $sformatf("Config read data mismatch. Expected: %0h, Got: %0h",
                                    rd_data[configs[i].u.fm_cpl.tag], configs[i].payload[0]))
                    end

                    rd_data[configs[i].u.fm_cpl.tag] = '0;
                    rd_addr[configs[i].u.fm_cpl.tag] = '0;
                    rd_tags[configs[i].u.fm_cpl.tag] = 1'b0;
                end
            end
        end
    endfunction
endclass
