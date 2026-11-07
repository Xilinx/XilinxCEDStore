onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate /tb_top/clk
add wave -noupdate /tb_top/slv_if/req_trigger
add wave -noupdate /tb_top/slv_if/rsp_trigger

add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_valid
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_cs
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_wr
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_rd
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_addr
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_dout
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_bar_num
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_io_access
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_cxl_mbar0_access
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_dbi_access
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_rom_access
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_vfunc_active
add wave -noupdate -expand -group REQ /tb_top/slv_if/lbc_ext_vfunc_num

add wave -noupdate -expand -group RSP /tb_top/slv_if/ext_lbc_ack
add wave -noupdate -expand -group RSP /tb_top/slv_if/ext_lbc_din
add wave -noupdate -expand -group RSP /tb_top/slv_if/ext_lbc_override_en

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {60 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 288
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
