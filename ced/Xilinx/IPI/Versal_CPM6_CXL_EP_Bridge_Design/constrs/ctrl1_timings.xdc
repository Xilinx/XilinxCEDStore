# parameter overrides for TOP/BOT_PL_MUX_MODE for timing arc
set cpm6_c [get_cells -hier -filter {REF_NAME == CPM6}]
set_property TOP_PL_MUX_MODE CXL $cpm6_c
