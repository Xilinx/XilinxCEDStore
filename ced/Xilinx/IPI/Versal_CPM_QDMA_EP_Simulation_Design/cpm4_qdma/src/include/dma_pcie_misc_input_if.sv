`ifndef DMA_PCIE_MISC_INPUT_IF
`define DMA_PCIE_MISC_INPUT_IF 1

interface dma_pcie_misc_input_if();
logic [7:0]    cfg_bus_number;
logic          cfg_interrupt_msi_mask_update;
logic          cfg_err_cor_out;
logic          cfg_err_fatal_out;
logic          cfg_err_nonfatal_out;
logic          cfg_ext_read_received;
logic          cfg_ext_write_received;
logic          cfg_hot_reset_out;
logic [3:0]    cfg_interrupt_msi_enable;
logic          cfg_interrupt_msi_fail;
logic          cfg_interrupt_msi_sent;
logic          cfg_interrupt_msix_fail;
logic          cfg_interrupt_msix_sent;
logic          cfg_interrupt_sent;
logic          cfg_local_error_valid;
logic [4:0]    cfg_local_error_out;
logic          cfg_mgmt_read_write_done;
logic          cfg_msg_received;
logic          cfg_msg_transmit_done;
logic          cfg_per_function_update_done;
logic          cfg_phy_link_down;
logic          pcie_rq_seq_num_vld0;
logic          pcie_rq_seq_num_vld1;
logic   [15:0] cfg_function_status;
logic   [15:0] cfg_per_func_status_data;
logic   [3:0]  cfg_interrupt_msix_enable;
logic   [3:0]  cfg_interrupt_msix_mask;
logic   [1:0]  cfg_phy_link_status;
logic   [2:0]  cfg_current_speed;
logic   [2:0]  cfg_max_payload;
logic   [2:0]  cfg_max_read_req;
logic   [31:0] cfg_ext_write_data;
logic   [31:0] cfg_mgmt_read_data;
logic   [3:0]  cfg_ext_write_byte_enable;
logic   [3:0]  cfg_flr_in_process;
logic   [3:0]  cfg_negotiated_width;
logic   [5:0]  pcie_cq_np_req_count;
logic   [5:0]  pcie_rq_seq_num0;
logic   [5:0]  pcie_rq_seq_num1;
logic   [3:0]  pcie_tfc_nph_av;
logic   [4:0]  cfg_msg_received_type;
logic   [5:0]  cfg_ltssm_state;
logic          cfg_pl_status_change;
logic   [7:0]  cfg_ext_function_number;
logic   [7:0]  cfg_msg_received_data;
logic   [7:0]  cfg_fc_nph;
logic   [1:0]  cfg_fc_nph_scale;
logic   [9:0]  cfg_ext_register_number;
logic [255:0]  cfg2axi_flr_in_progress;
logic [255:0]  cfg2axi_interrupt_msix_enable;
logic [255:0]  cfg2axi_interrupt_msix_mask;
logic [255:0]  cfg_command_bus_master_enable_int;
logic [255:0]  cfg2axi_mem_space_enable;
logic [255:0]  cfg2axi_tph_requester_enable;

modport s (
input   cfg_bus_number,
input   cfg_interrupt_msi_mask_update,
input   cfg_err_cor_out,
input   cfg_err_fatal_out,
input   cfg_err_nonfatal_out,
input   cfg_ext_read_received,
input   cfg_ext_write_received,
input   cfg_hot_reset_out,
input   cfg_interrupt_msi_enable,
input   cfg_interrupt_msi_fail,
input   cfg_interrupt_msi_sent,
input   cfg_interrupt_msix_fail,
input   cfg_interrupt_msix_sent,
input   cfg_interrupt_sent,
input   cfg_local_error_valid,
input   cfg_local_error_out,
input   cfg_mgmt_read_write_done,
input   cfg_msg_received,
input   cfg_msg_transmit_done,
input   cfg_per_function_update_done,
input   cfg_phy_link_down,
input   pcie_cq_np_req_count,
input   pcie_rq_seq_num_vld0,
input   pcie_rq_seq_num_vld1,
input   cfg_function_status,
input   cfg_per_func_status_data,
input   cfg_interrupt_msix_enable,
input   cfg_interrupt_msix_mask,
input   cfg_phy_link_status,
input   cfg_current_speed,
input   cfg_max_payload,
input   cfg_max_read_req,
input   cfg_ext_write_data,
input   cfg_mgmt_read_data,
input   cfg_ext_write_byte_enable,
input   cfg_flr_in_process,
input   cfg_negotiated_width,
input   pcie_rq_seq_num0,
input   pcie_rq_seq_num1,
input   pcie_tfc_nph_av,
input   cfg_msg_received_type,
input   cfg_ltssm_state,
input   cfg_pl_status_change,
input   cfg_ext_function_number,
input   cfg_msg_received_data,
input   cfg_fc_nph,
input   cfg_fc_nph_scale,
input   cfg_ext_register_number,
input   cfg2axi_flr_in_progress,
input   cfg2axi_interrupt_msix_enable,
input   cfg2axi_interrupt_msix_mask,
input   cfg_command_bus_master_enable_int,
input   cfg2axi_mem_space_enable,
input   cfg2axi_tph_requester_enable
);

modport m (
output   cfg_bus_number,
output   cfg_interrupt_msi_mask_update,
output   cfg_err_cor_out,
output   cfg_err_fatal_out,
output   cfg_err_nonfatal_out,
output   cfg_ext_read_received,
output   cfg_ext_write_received,
output   cfg_hot_reset_out,
output   cfg_interrupt_msi_enable,
output   cfg_interrupt_msi_fail,
output   cfg_interrupt_msi_sent,
output   cfg_interrupt_msix_fail,
output   cfg_interrupt_msix_sent,
output   cfg_interrupt_sent,
output   cfg_local_error_valid,
output   cfg_local_error_out,
output   cfg_mgmt_read_write_done,
output   cfg_msg_received,
output   cfg_msg_transmit_done,
output   cfg_per_function_update_done,
output   cfg_phy_link_down,
output   pcie_cq_np_req_count,
output   pcie_rq_seq_num_vld0,
output   pcie_rq_seq_num_vld1,
output   cfg_function_status,
output   cfg_per_func_status_data,
output   cfg_interrupt_msix_enable,
output   cfg_interrupt_msix_mask,
output   cfg_phy_link_status,
output   cfg_current_speed,
output   cfg_max_payload,
output   cfg_max_read_req,
output   cfg_ext_write_data,
output   cfg_mgmt_read_data,
output   cfg_ext_write_byte_enable,
output   cfg_flr_in_process,
output   cfg_negotiated_width,
output   pcie_rq_seq_num0,
output   pcie_rq_seq_num1,
output   pcie_tfc_nph_av,
output   cfg_msg_received_type,
output   cfg_ltssm_state,
output   cfg_pl_status_change,
output   cfg_ext_function_number,
output   cfg_msg_received_data,
output   cfg_fc_nph,
output   cfg_fc_nph_scale,
output   cfg_ext_register_number,
output   cfg2axi_flr_in_progress,
output   cfg2axi_interrupt_msix_enable,
output   cfg2axi_interrupt_msix_mask,
output   cfg_command_bus_master_enable_int,
output   cfg2axi_mem_space_enable,
output   cfg2axi_tph_requester_enable
);
endinterface : dma_pcie_misc_input_if
`endif // DMA_PCIE_MISC_INPUT_IF
