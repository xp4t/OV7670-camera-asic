# run_icc2.tcl

puts "========== Starting ICC2 Flow =========="

# Floorplanning
source ./floorplanning/step1_data_setup.tcl
source ./floorplanning/step2_floorplan.tcl
source ./floorplanning/step3_powerplan.tcl

# Placement
source ./placement/step4_place.tcl

# CTS
source ./placement/step5_clock_tree_syntesis.tcl

# Routing
source ./placement/step6_route.tcl

# Signoff Checks
source ./signoff/signoff_drc.tcl

# Final Stream Out
source ./gdsout/step7_finishing.tcl

puts "========== ICC2 Flow Completed =========="
