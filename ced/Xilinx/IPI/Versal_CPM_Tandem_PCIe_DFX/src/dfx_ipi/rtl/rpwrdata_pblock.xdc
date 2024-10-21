create_pblock pblock_rp_wrdata
resize_pblock pblock_rp_wrdata -add SLICE_X60Y232:SLICE_X75Y235
add_cells_to_pblock pblock_rp_wrdata [get_cells [list <?BD_NAME>_i/pl_bram_inst/rp_wrdata]] -clear_locs
set_property SNAPPING_MODE ON [get_pblocks pblock_rp_wrdata]
