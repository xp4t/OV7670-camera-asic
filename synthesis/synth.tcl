# This synth.tcl can be used to check the warnings of the rtl files. 
set DESIGN_NAME mem_bram
file mkdir reports
file mkdir reports/${DESIGN_NAME}

set LOG_FILE ./reports/${DESIGN_NAME}/synth.log
redirect -tee $LOG_FILE {
remove_design -all
set search_path {./lib ./rtl}
set target_library {your_tech_file.db your_tech_file.db}
set link_library "* your_tech_file.db your_tech_file.db"

analyze -format verilog ./rtl/${DESIGN_NAME}.v

elaborate ${DESIGN_NAME}

link

check_design

current_design  ${DESIGN_NAME}

compile_ultra
start_gui

report_timing > ./reports/${DESIGN_NAME}/${DESIGN_NAME}_timing_reports.log
report_qor > ./reports/${DESIGN_NAME}/${DESIGN_NAME}_qor_reports.log
report_area -hierarchy  > ./reports/${DESIGN_NAME}/${DESIGN_NAME}_area_reports.log
report_power -hierarchy > ./reports/${DESIGN_NAME}/${DESIGN_NAME}_power_reports.log

write_file -f verilog -hier -output ./netlist/${DESIGN_NAME}_netlist.v

}
