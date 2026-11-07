onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/msix_if/clk
add wave -noupdate /tb_top/msix_if/user_req
add wave -noupdate /tb_top/msix_if/user_grant
add wave -noupdate /tb_top/msix_if/user_error
add wave -noupdate /tb_top/msix_if/user_func_num
add wave -noupdate -radix unsigned /tb_top/msix_if/user_vfunc_num
add wave -noupdate /tb_top/msix_if/user_vfunc_active
add wave -noupdate /tb_top/msix_if/user_operation
add wave -noupdate -radix unsigned /tb_top/msix_if/user_vector_num
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 239
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ns} {485 ns}
