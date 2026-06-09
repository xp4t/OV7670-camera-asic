################################################################################Open_Lib
open_lib ../floorplanning/OV7670
open_block top_6_route_pg_fixed

################################################################################Parasitics
read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmax.lv.tluplus \
    -name maxTLU \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map
read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmin.lv.tluplus \
    -name minTLU \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map

################################################################################Filler_Cells
create_stdcell_fillers \
    -lib_cells {*/SHFILL128_RVT */SHFILL64_RVT \
                */SHFILL3_RVT */SHFILL2_RVT */SHFILL1_RVT}
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

################################################################################DRC
check_routes \
    > ../reports/signoff_check_routes.rpt
check_legality -verbose \
    > ../reports/signoff_check_legality.rpt
check_pg_connectivity \
    -nets {VDD VSS} \
    -check_std_cell_pins all \
    -write_connectivity_file ../reports/signoff_pg.rpt
check_lvs -max_errors 2000 \
    > ../reports/signoff_lvs.rpt

################################################################################Save
save_block -as top_7_signoff
save_lib
close_block
close_lib