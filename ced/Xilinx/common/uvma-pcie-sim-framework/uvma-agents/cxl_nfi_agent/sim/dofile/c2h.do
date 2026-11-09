set N    [string index [examine /params_pkg/N] end]
set MODE [string range [examine /params_pkg/MODE] 0 end]
if {$N >= 3} {
if {$MODE == "F68"} {
 set lbl f2
} else {
 set lbl ssC
}
add wave -position insertpoint -label c2h_$lbl\_fmt                sim:/tb_top/c2h_ss2_sf
add wave -position insertpoint -label c2h_$lbl\_mndr -radix s2mndr sim:/tb_top/c2h_ss2_mndr 
add wave -position insertpoint -label c2h_$lbl\_mdrs -radix s2mdrs sim:/tb_top/c2h_ss2_mdrs 
if {$MODE == "F256"} {
add wave -position insertpoint -label c2h_$lbl\_ssptr   {sim:/tb_top/c2h_f256_ssptr[2]}
add wave -position insertpoint -label c2h_$lbl\_rollin  {sim:/tb_top/c2h_rolli[2]}
add wave -position insertpoint -label c2h_$lbl\_rollout {sim:/tb_top/c2h_rollo[2]}
}
}
if {$N >= 2} {
if {$MODE == "F68"} {
 set lbl f1
} else {
 set lbl ssB
}
add wave -position insertpoint -label c2h_$lbl\_fmt                sim:/tb_top/c2h_ss1_sf
add wave -position insertpoint -label c2h_$lbl\_mndr -radix s2mndr sim:/tb_top/c2h_ss1_mndr
add wave -position insertpoint -label c2h_$lbl\_mdrs -radix s2mdrs sim:/tb_top/c2h_ss1_mdrs
if {$MODE == "F256"} {
add wave -position insertpoint -label c2h_$lbl\_ssptr   {sim:/tb_top/c2h_f256_ssptr[1]}
add wave -position insertpoint -label c2h_$lbl\_rollin  {sim:/tb_top/c2h_rolli[1]}
add wave -position insertpoint -label c2h_$lbl\_rollout {sim:/tb_top/c2h_rollo[1]}
}
}
if {$MODE == "F68"} {
 set lbl f0
} else {
 set lbl ssA
}
add wave -position insertpoint -label c2h_$lbl\_fmt                sim:/tb_top/c2h_ss0_sf
add wave -position insertpoint -label c2h_$lbl\_mndr -radix s2mndr sim:/tb_top/c2h_ss0_mndr
add wave -position insertpoint -label c2h_$lbl\_mdrs -radix s2mdrs sim:/tb_top/c2h_ss0_mdrs
if {$MODE == "F256"} {
add wave -position insertpoint -label c2h_$lbl\_ssptr   {sim:/tb_top/c2h_f256_ssptr[0]}
add wave -position insertpoint -label c2h_$lbl\_rollin  {sim:/tb_top/c2h_rolli[0]}
add wave -position insertpoint -label c2h_$lbl\_rollout {sim:/tb_top/c2h_rollo[0]}
}

add wave -divider "DUT_SIGNALS"
add wave -position insertpoint               sim:/tb_top/c2h_mst_if/clk
if {$MODE == "F68"} {
add wave -position insertpoint -radix binary sim:/tb_top/c2h_mst_if/adf
}
add wave -position insertpoint -radix binary sim:/tb_top/c2h_mst_if/valid
add wave -position insertpoint -radix binary sim:/tb_top/c2h_mst_if/ready[0]
if {$N >= 3} {
if {$MODE == "F68"} {
 set lbl FLIT2
} else {
 set lbl SLOTSETC
}
add wave -position insertpoint -group $lbl -label slot3[511:384] sim:/tb_top/c2h_mst_if/data[2][511:384]
add wave -position insertpoint -group $lbl -label slot2[383:256] sim:/tb_top/c2h_mst_if/data[2][383:256]
add wave -position insertpoint -group $lbl -label slot1[255:128] sim:/tb_top/c2h_mst_if/data[2][255:128]
add wave -position insertpoint -group $lbl -label slot0[127:0]   sim:/tb_top/c2h_mst_if/data[2][127:0]
}
if {$N >= 2} {
if {$MODE == "F68"} {
 set lbl FLIT1
} else {
 set lbl SLOTSETB
}
add wave -position insertpoint -group $lbl -label slot3[511:384] sim:/tb_top/c2h_mst_if/data[1][511:384]
add wave -position insertpoint -group $lbl -label slot2[383:256] sim:/tb_top/c2h_mst_if/data[1][383:256]
add wave -position insertpoint -group $lbl -label slot1[255:128] sim:/tb_top/c2h_mst_if/data[1][255:128]
add wave -position insertpoint -group $lbl -label slot0[127:0]   sim:/tb_top/c2h_mst_if/data[1][127:0]
}
if {$MODE == "F68"} {
 set lbl FLIT0
} else {
 set lbl SLOTSETA
}
add wave -position insertpoint -group $lbl -label slot3[511:384] sim:/tb_top/c2h_mst_if/data[0][511:384]
add wave -position insertpoint -group $lbl -label slot2[383:256] sim:/tb_top/c2h_mst_if/data[0][383:256]
add wave -position insertpoint -group $lbl -label slot1[255:128] sim:/tb_top/c2h_mst_if/data[0][255:128]
add wave -position insertpoint -group $lbl -label slot0[127:0]   sim:/tb_top/c2h_mst_if/data[0][127:0]
