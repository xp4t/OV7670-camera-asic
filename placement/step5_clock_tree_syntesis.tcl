open_lib ../floorplanning/OV7670

copy_block -from top_4_place_clean -to temp_cts_clean

open_block temp_cts_clean

report_lib ../floorplanning/OV7670

check_legality -verbose

set_ignored_layers -min_routing_layer M2 -max_routing_layer M7

set_app_options -name cts.compile.enable_cell_relocation -value all
set_app_options -name cts.compile.size_pre_existing_cell_to_cts_references -value true

set_clock_tree_options \
    -clocks [all_clocks] \
    -target_skew 0.1

source ./../placement/mcmm.tcl

set_voltage 1.05 -object_list VDD
set_voltage 0.00 -object_list VSS

set_lib_cell_purpose -include {optimization} \
    [get_lib_cells {*/NBUFFX2_RVT */NBUFFX4_RVT */NBUFFX8_RVT */NBUFFX16_RVT \
                    */INVX1_RVT */INVX2_RVT */INVX4_RVT */INVX8_RVT}]

set_lib_cell_purpose -include cts \
    [get_lib_cells {*/NBUFFX2_RVT */NBUFFX4_RVT */NBUFFX8_RVT */NBUFFX16_RVT \
                    */INVX1_RVT */INVX2_RVT */INVX4_RVT */INVX8_RVT}]

set_lib_cell_purpose -exclude {optimization cts} \
    [get_lib_cells {*/AOBUF* */IBUFF* */TNBUFF* */AOINV*}]

set_clock_uncertainty 0.1 [all_clocks]

create_routing_rule CLK_SPACING -spacings {M2 0.3 M3 0.5 M4 0.7}

set_clock_routing_rules -rules CLK_SPACING \
    -min_routing_layer M2 -max_routing_layer M4

report_clock_settings

set_app_options -name opt.common.user_instance_name_prefix -value clock

clock_opt -from build_clock -to build_clock

set_app_option -name time.snapshot_storage_location -value "./"

create_qor_snapshot -name clock_pre_route -significant_digits 4
report_qor_snapshot -name clock_pre_route > ../reports/clock_pre_route.qor_snapshot.rpt
report_qor > ../reports/clock_pre_route.qor
report_constraints -all_violators > ../reports/clock_pre_route.con
report_timing -capacitance -transition_time -input_pins -nets -delay_type max \
    > ../reports/clock_pre_route.max.tim
report_timing -capacitance -transition_time -input_pins -nets -delay_type min \
    > ../reports/clock_pre_route.min.tim

clock_opt -from route_clock -to final_opto

report_clock_qor > ../reports/clock_tree.rpt
report_clock_timing -type skew > ../reports/clock_timing.rpt

create_qor_snapshot -name clock -significant_digits 4
report_qor_snapshot -name clock > ../reports/clock.qor_snapshot.rpt
report_qor > ../reports/clock.qor
report_constraints -all_violators > ../reports/clock_route.con
report_timing -capacitance -transition_time -input_pins -nets -delay_type max \
    > ../reports/clock.max.tim
report_timing -capacitance -transition_time -input_pins -nets -delay_type min \
    > ../reports/clock.min.tim

connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]

save_block -as top_5_cts_clean
save_lib

close_block
close_lib