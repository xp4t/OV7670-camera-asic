################################################################################Open_Lib
open_lib ../floorplanning/OV7670
copy_block -from top_7_signoff -to temp_finish
open_block temp_finish

################################################################################Parasitics
read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmax.lv.tluplus \
    -name maxTLU \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map
read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmin.lv.tluplus \
    -name minTLU \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map

################################################################################Insert_Redundant_Vias
add_redundant_vias

################################################################################Insert_Metal_Fill
set icv_mfill_runset "../lib/icv_runsets/saed32nm_1p9m_mfill_rules.rs"
set_app_options \
    -name signoff.create_metal_fill.runset \
    -value ${icv_mfill_runset}
set_app_options \
    -name signoff.physical.layer_map_file \
    -value ../lib/saed32nm_1p9m_gdsout.map
# signoff_create_metal_fill -select_layers {M2 M6}
# Commented out — requires ICV binary, skip for now

################################################################################PG_Connect
set_attribute -objects [get_nets VDD] -name net_type -value power
set_attribute -objects [get_nets VSS] -name net_type -value ground
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

################################################################################Verify
check_mv_design
check_lvs -max_errors 2000 \
    > ../reports/OV7670.lvs.rpt
check_pg_connectivity \
    -nets {VDD VSS} \
    -check_std_cell_pins all \
    -write_connectivity_file ../reports/OV7670.pg.rpt

################################################################################Reports
report_design -all \
    > ../reports/OV7670.PR_summary.rpt
report_timing \
    -capacitance -transition_time -input_pins -nets \
    -delay_type max \
    > ../reports/OV7670.max.tim
report_timing \
    -capacitance -transition_time -input_pins -nets \
    -delay_type min \
    > ../reports/OV7670.min.tim
report_qor \
    > ../reports/OV7670.qor

################################################################################Write_Verilog
write_verilog \
    -include {pg_netlist unconnected_ports} \
    ../netlist/OV7670.pg.v
write_verilog \
    -exclude {physical_only_cells} \
    ../netlist/OV7670.v

################################################################################SDC_Out
write_sdc -scenario func_slow \
    -output ../netlist/OV7670_func_slow.sdc
write_sdc -scenario func_fast \
    -output ../netlist/OV7670_func_fast.sdc

################################################################################SPEF_Out
write_parasitics \
    -format spef \
    -output ../netlist/OV7670

################################################################################DEF_Out
write_def ../netlist/OV7670_final.def

################################################################################GDS_Out
save_block -as top_8_final
write_gds \
    -output_pin all \
    -long_names \
    -compress \
    ../netlist/OV7670_final.gds

################################################################################Save
save_lib
#close_block
#close_lib