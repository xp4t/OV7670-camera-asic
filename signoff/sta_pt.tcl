################################################################################Libraries
set search_path    {../lib ../netlist}
set link_library   {saed32rvt_ss0p95v125c.db *}
set target_library {saed32rvt_ss0p95v125c.db}

################################################################################Setup_Analysis
read_verilog    ../netlist/OV7670_final.v
current_design  top
link_design

read_sdc ../netlist/OV7670_func_slow.sdc

read_parasitics \
    -format spef \
    ../netlist/OV7670.tlup_max_125.spef

update_timing -full

report_qor \
    > ../reports/pt_setup.qor
report_timing \
    -delay_type max \
    -capacitance -transition_time -input_pins -nets \
    -max_paths 10 \
    > ../reports/pt_setup.max.tim
report_constraint -all_violators \
    > ../reports/pt_setup.con

################################################################################Hold_Analysis
remove_annotated_parasitics -all

read_sdc ../netlist/OV7670_func_fast.sdc

read_parasitics \
    -format spef \
    ../netlist/OV7670.tlup_min_125.spef

update_timing -full

report_timing \
    -delay_type min \
    -capacitance -transition_time -input_pins -nets \
    -max_paths 10 \
    > ../reports/pt_hold.min.tim
report_constraint -all_violators \
    >> ../reports/pt_hold.min.tim

################################################################################Exit
exit