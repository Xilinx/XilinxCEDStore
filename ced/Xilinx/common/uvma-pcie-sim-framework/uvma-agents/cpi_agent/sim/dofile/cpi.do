onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/clock
add wave -noupdate -group GLOBAL /tb_top/mst_if/glbl/txcon_req
add wave -noupdate -group GLOBAL /tb_top/mst_if/glbl/rxcon_ack
add wave -noupdate -group GLOBAL /tb_top/mst_if/glbl/rx_empty

add wave -noupdate -group REQ_0 -group VLD                {/tb_top/mst_if/req[0]/req_is_valid}
add wave -noupdate -group REQ_0 -group VLD                {/tb_top/mst_if/req[0]/req_block}
add wave -noupdate -group REQ_0 -group VLD -radix prot_id {/tb_top/mst_if/req[0]/req_protocol_id}
add wave -noupdate -group REQ_0 -group VLD                {/tb_top/mst_if/req[0]/req_vc_id}
add wave -noupdate -group REQ_0 -group VLD                {/tb_top/mst_if/req[0]/req_shared_credit}
add wave -noupdate -group REQ_0 -group HDR                {/tb_top/mst_if/req[0]/req_header}
add wave -noupdate -group REQ_0 -group HDR                {/tb_top/mst_if/req[0]/req_cmd_parity}
add wave -noupdate -group REQ_0 -group CRD                {/tb_top/mst_if/req[0]/req_rxcrd_valid}
add wave -noupdate -group REQ_0 -group CRD -radix prot_id {/tb_top/mst_if/req[0]/req_rxcrd_protocol_id}
add wave -noupdate -group REQ_0 -group CRD                {/tb_top/mst_if/req[0]/req_rxcrd_shared}
add wave -noupdate -group REQ_0 -group CRD                {/tb_top/mst_if/req[0]/req_rxcrd_vc_id}
add wave -noupdate -group REQ_0 -group CRD                {/tb_top/mst_if/req[0]/req_txblock_crd_flow}

add wave -noupdate -group DAT_0 -group VLD                {/tb_top/mst_if/data[0]/data_is_valid}
add wave -noupdate -group DAT_0 -group VLD                {/tb_top/mst_if/data[0]/data_block}
add wave -noupdate -group DAT_0 -group VLD -radix prot_id {/tb_top/mst_if/data[0]/data_protocol_id}
add wave -noupdate -group DAT_0 -group VLD                {/tb_top/mst_if/data[0]/data_vc_id}
add wave -noupdate -group DAT_0 -group VLD                {/tb_top/mst_if/data[0]/data_shared_credit}
add wave -noupdate -group DAT_0 -group HDR                {/tb_top/mst_if/data[0]/data_header}
add wave -noupdate -group DAT_0 -group HDR                {/tb_top/mst_if/data[0]/data_cmd_parity}
add wave -noupdate -group DAT_0 -group BODY               {/tb_top/mst_if/data[0]/data_body}
add wave -noupdate -group DAT_0 -group BODY               {/tb_top/mst_if/data[0]/data_byte_enable}
add wave -noupdate -group DAT_0 -group BODY               {/tb_top/mst_if/data[0]/data_byte_enable_parity}
add wave -noupdate -group DAT_0 -group BODY               {/tb_top/mst_if/data[0]/data_parity}
add wave -noupdate -group DAT_0 -group BODY               {/tb_top/mst_if/data[0]/data_eop}
add wave -noupdate -group DAT_0 -group CRD                {/tb_top/mst_if/data[0]/data_rxcrd_valid}
add wave -noupdate -group DAT_0 -group CRD -radix prot_id {/tb_top/mst_if/data[0]/data_rxcrd_protocol_id}
add wave -noupdate -group DAT_0 -group CRD                {/tb_top/mst_if/data[0]/data_rxcrd_shared}
add wave -noupdate -group DAT_0 -group CRD                {/tb_top/mst_if/data[0]/data_rxcrd_vc_id}
add wave -noupdate -group DAT_0 -group CRD                {/tb_top/mst_if/data[0]/data_txblock_crd_flow}

add wave -noupdate -group RSP_0 -group VLD                {/tb_top/mst_if/rsp[0]/rsp_is_valid}
add wave -noupdate -group RSP_0 -group VLD                {/tb_top/mst_if/rsp[0]/rsp_block}
add wave -noupdate -group RSP_0 -group VLD -radix prot_id {/tb_top/mst_if/rsp[0]/rsp_protocol_id}
add wave -noupdate -group RSP_0 -group VLD                {/tb_top/mst_if/rsp[0]/rsp_vc_id}
add wave -noupdate -group RSP_0 -group VLD                {/tb_top/mst_if/rsp[0]/rsp_shared_credit}
add wave -noupdate -group RSP_0 -group HDR                {/tb_top/mst_if/rsp[0]/rsp_header}
add wave -noupdate -group RSP_0 -group HDR                {/tb_top/mst_if/rsp[0]/rsp_cmd_parity}
add wave -noupdate -group RSP_0 -group CRD                {/tb_top/mst_if/rsp[0]/rsp_rxcrd_valid}
add wave -noupdate -group RSP_0 -group CRD -radix prot_id {/tb_top/mst_if/rsp[0]/rsp_rxcrd_protocol_id}
add wave -noupdate -group RSP_0 -group CRD                {/tb_top/mst_if/rsp[0]/rsp_rxcrd_shared}
add wave -noupdate -group RSP_0 -group CRD                {/tb_top/mst_if/rsp[0]/rsp_rxcrd_vc_id}
add wave -noupdate -group RSP_0 -group CRD                {/tb_top/mst_if/rsp[0]/rsp_txblock_crd_flow}

configure wave -signalnamewidth 1
