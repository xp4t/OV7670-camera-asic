open_lib ../floorplanning/OV7670

copy_block -from top_3_powerplan_clean -to temp_place_clean

open_block temp_place_clean

report_lib ../floorplanning/OV7670

set_app_options -name time.disable_recovery_removal_checks -value false
set_app_options -name time.disable_case_analysis -value false
set_app_options -name place.coarse.continue_on_missing_scandef -value true

source ./mcmm.tcl

set_app_options -name opt.common.user_instance_name_prefix -value place

set_voltage 1.05 -object_list VDD
set_voltage 0.00 -object_list VSS

set_lib_cell_purpose -include {optimization} \
    [get_lib_cells {*/NBUFFX2_RVT */NBUFFX4_RVT */NBUFFX8_RVT */NBUFFX16_RVT \
                    */INVX1_RVT */INVX2_RVT */INVX4_RVT */INVX8_RVT}]

set_lib_cell_purpose -exclude {optimization} \
    [get_lib_cells {*/AOBUF* */IBUFF* */TNBUFF* */AOINV*}]

place_opt

legalize_placement

set_app_option -name time.snapshot_storage_location -value "./"

create_qor_snapshot -name place_qor_snp -significant_digits 4
report_qor_snapshot -name place_qor_snp > ../reports/place.qor_snapshot.rpt
report_qor > ../reports/place.qor
report_constraints -all_violators > ../reports/place.con
report_timing -capacitance -transition_time -input_pins -nets -delay_type max > ../reports/place.max.tim
report_timing -capacitance -transition_time -input_pins -nets -delay_type min > ../reports/place.min.tim

save_block -as top_4_place_clean
save_lib

close_block
close_lib