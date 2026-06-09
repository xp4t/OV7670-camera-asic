################################################################################Open_Lib
open_lib ../floorplanning/OV7670
copy_block -from top_5_cts_clean -to temp_route_clean
open_block temp_route_clean
################################################################################Checking
set_ignored_layers \
    -min_routing_layer M2 \
    -max_routing_layer M7
report_ignored_layers
################################################################################Route_Optimization
source ./../placement/mcmm.tcl
set_voltage 1.05 -object_list VDD
set_voltage 0.00 -object_list VSS
route_opt
################################################################################Connecting_power/Ground_Nets_And_Pins
connect_pg_net -net VDD [get_pins -physical_context */VDD]
connect_pg_net -net VSS [get_pins -physical_context */VSS]
optimize_routes -max_detail_route_iterations 5
check_lvs -max_errors 2000
################################################################################Reports
set_app_options -name time.snapshot_storage_location -value "./"
create_qor_snapshot -name route -significant_digits 4
report_congestion
write_verilog -include {pg_netlist} "../netlist/route_out.v"
report_qor_snapshot -name route > ../reports/route.qor_snapshot.rpt
report_qor > ../reports/route.qor
report_constraints -all_violators > ../reports/route.con
report_timing -capacitance -transition_time -input_pins -nets -delay_type max \
    > ../reports/route.max.tim
report_timing -capacitance -transition_time -input_pins -nets -delay_type min \
    > ../reports/route.min.tim
################################################################################Save_Cell
save_block -as top_6_route_clean
save_lib
close_block
close_lib