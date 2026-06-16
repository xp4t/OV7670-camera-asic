# run_icc2.tcl

puts "========== Starting ICC2 Flow =========="

# Floorplanning

cd floorplanning
source step1_data_setup.tcl
source step2_floorplan.tcl
source step3_powerplan.tcl
cd ..
# Placement
cd placement
source step4_place.tcl

# CTS
source step5_clock_tree_syntesis.tcl

# Routing
source step6_route.tcl
cd ..

# Signoff Checks

cd signoff
source signoff_drc.tcl
cd ..

cd gdsout
source step7_finishing.tcl
cd ..


puts "========== ICC2 Flow Completed =========="
