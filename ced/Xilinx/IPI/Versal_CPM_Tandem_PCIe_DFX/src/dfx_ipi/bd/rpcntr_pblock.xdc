create_pblock pblock_rp_cntr
resize_pblock pblock_rp_cntr -add SLICE_X84Y136:SLICE_X93Y139
add_cells_to_pblock pblock_rp_cntr [get_cells [list <?BD_NAME>_i/rp_cntr]] -clear_locs
set_property SNAPPING_MODE ON [get_pblocks pblock_rp_cntr]
