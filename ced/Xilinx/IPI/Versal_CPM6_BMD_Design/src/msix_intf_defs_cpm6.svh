`ifndef MSIX_INTF_DEFS_CPM6
`define MSIX_INTF_DEFS_CPM6

`define STRUCT_MSIX_IF
interface msix_intf;
    logic               ven_msi_grant;
    logic               ven_msi_req;
    logic [2:0]         ven_msi_func_num;
    logic [7:0]         ven_msi_vfunc_num;
    logic               ven_msi_vfunc_active;
    logic [2:0]         ven_msi_tc;
    logic [63:0]        msix_addr;
    logic [31:0]        msix_data;

    modport master(
        input ven_msi_grant, 
        output ven_msi_req, 
        output ven_msi_func_num, 
        output ven_msi_vfunc_num, 
        output ven_msi_vfunc_active, 
        output ven_msi_tc, 
        output msix_addr, 
        output msix_data
    );

    modport slave(
        output ven_msi_grant, 
        input ven_msi_req, 
        input ven_msi_func_num, 
        input ven_msi_vfunc_num, 
        input ven_msi_vfunc_active, 
        input ven_msi_tc, 
        input msix_addr, 
        input msix_data
    );
endinterface

`define STRUCT_MSIX_USER_IF
interface msix_user_intf;

    logic [2:0]         user_func_num;
    logic [7:0]         user_vfunc_num;
    logic               user_vfunc_active;
    logic               user_req;
    logic [10:0]        user_vector_num;
    logic               user_grant; // Potential backpressure to user logic to not send interrupt/hold current interrupt
    logic [1:0]         user_operation; // 00 = send interrupt, 01 = check pending status, 10 = clear pending status
    logic               user_error; // 00 = no error, 01 = mask error (= pending set), 10 = parity error (might not want to support)

    modport master(
        output user_func_num,
        output user_vfunc_num,
        output user_vfunc_active, 
        output user_req, 
        output user_vector_num,
        output user_operation, 
        input user_grant,
        input user_error
    );

    modport slave(
        input user_func_num,
        input user_vfunc_num,
        input user_vfunc_active, 
        input user_req, 
        input user_vector_num, 
        input user_operation,
        output user_grant,
        output user_error
    );
endinterface

`define STRUCT_MSIX_BRAM_IF
interface msix_bram_intf #(parameter RAM_ADDR_WIDTH = 1024, RAM_DATA_WIDTH = 32, BYTE_WRITE_WIDTH = 32);
    logic rd_en;
    logic [RAM_ADDR_WIDTH - 1:0] rd_addr;
    logic [RAM_DATA_WIDTH - 1:0] rd_data;
    logic wr_port_en;
    logic [RAM_DATA_WIDTH/BYTE_WRITE_WIDTH - 1:0] wr_en;
    logic [RAM_ADDR_WIDTH - 1:0] wr_addr;
    logic [RAM_DATA_WIDTH - 1:0] wr_data;

    modport slave(
        input rd_en,
        input rd_addr,
        output rd_data,
        input wr_port_en,
        input wr_en,
        input wr_addr,
        input wr_data
    );

    modport master(
        output rd_en,
        output rd_addr,
        input rd_data,
        output wr_port_en,
        output wr_en,
        output wr_addr,
        output wr_data
    );
endinterface

`define STRUCT_MSIX_SEND_INTERRUPT_IF
interface msix_send_interrupt_intf;
    logic [2:0]         send_func_num;
    logic [7:0]         send_vfunc_num;
    logic               send_vfunc_active; 
    logic               send_req;
    logic [63:0]        send_addr;
    logic [31:0]        send_data;
    logic               send_ack;

    modport slave(
        input send_func_num, 
        input send_vfunc_num, 
        input send_vfunc_active, 
        input send_req, 
        input send_addr, 
        input send_data, 
        output send_ack
    );

    modport master(
        output send_func_num, 
        output send_vfunc_num, 
        output send_vfunc_active, 
        output send_req, 
        output send_addr, 
        output send_data, 
        input send_ack
    );
endinterface

`define STRUCT_MSIX_LOOKUP_REQ_IF
interface msix_lookup_req_intf;
    logic [2:0]         lookup_func_num;
    logic [7:0]         lookup_vfunc_num;
    logic               lookup_vfunc_active;
    logic [10:0]        lookup_vector_num;
    logic               lookup_req;
    logic               lookup_ack;
    logic [63:0]        lookup_addr;
    logic [31:0]        lookup_data;
    logic [1:0]         lookup_operation; // 00 = lookup, 01 = check pending status, 10 = clear pending status
    logic               lookup_error;       // LOOKUP: 00 = no error, 01 = mask error (pending set), maybe 10 = parity error
                                            // LOOKUP_QUERY: 0 = no pending, 1 = pending bit set
                                            // LOOKUP_CLEAR: 0 = pending bit cleared, 1 = pending still set - should never happen!

    modport master(
        output lookup_func_num,
        output lookup_vfunc_num,
        output lookup_vfunc_active, 
        output lookup_vector_num, 
        output lookup_req,
        output lookup_operation,
        input lookup_addr, 
        input lookup_data, 
        input lookup_ack,         
        input lookup_error
    );

    modport slave(
        input lookup_func_num,
        input lookup_vfunc_num, 
        input lookup_vfunc_active,
        input lookup_vector_num, 
        input lookup_req, 
        input lookup_operation,
        output lookup_addr, 
        output lookup_data, 
        output lookup_ack, 
        output lookup_error
    );
endinterface

`define STRUCT_MSIX_CTRL_LOGIC_SIDEBAND_IF
interface msix_ctrl_logic_sideband_intf #(MSIX_PF_COUNT = 8, MSIX_VF_COUNT = 256);
    logic [MSIX_PF_COUNT-1:0] msix_pf_msix_enable;
    logic [MSIX_PF_COUNT-1:0] msix_pf_msix_func_mask;
    logic [MSIX_PF_COUNT-1:0] msix_pf_flr_pf_active;
    logic msix_pf_cfg_flit_mode; // PF0 only, but will use all PF info ready as valid signal
    logic msix_pf_info_ready;
    logic [((MSIX_VF_COUNT > 0) ? (MSIX_VF_COUNT-1) : 0) :0] msix_vf_msix_enable;
    logic [((MSIX_VF_COUNT > 0) ? (MSIX_VF_COUNT-1) : 0)  :0] msix_vf_msix_func_mask;
    logic [((MSIX_VF_COUNT > 0) ? (MSIX_VF_COUNT-1) : 0)  :0] msix_vf_flr_vf_active;
    logic msix_vf_info_ready;

    modport master(
        output msix_pf_msix_enable,
        output msix_pf_msix_func_mask,
        output msix_pf_flr_pf_active,
        output msix_vf_msix_enable,
        output msix_vf_msix_func_mask,
        output msix_vf_flr_vf_active,
        output msix_pf_cfg_flit_mode,
        output msix_pf_info_ready,
        output msix_vf_info_ready
    );

    modport slave(
        input msix_pf_msix_enable,
        input msix_pf_msix_func_mask,
        input msix_pf_flr_pf_active,
        input msix_vf_msix_enable,
        input msix_vf_msix_func_mask,
        input msix_vf_flr_vf_active,
        input msix_pf_cfg_flit_mode,
        input msix_pf_info_ready,
        input msix_vf_info_ready
    );

endinterface

`else
`endif
