################################################################################
# FLOORPLAN
# Source : top_1_data_setup
# Output : top_2_floorplan_clean
#
# PDK    : SAED32 RVT
# Tool   : IC Compiler II W-2024.09
#
# Fixes applied vs original:
#   - copy_block flag: -from_block → -from
#   - set_ignored_layers: was M1-M8 (all), corrected to M2-M7
#   - Routing directions: match SAED32 preferred dirs
#   - Removed duplicate save_block calls
#   - Consistent block naming (no typos)
#   - Pin layer via set_pin_physical_constraints (place_pins has no -layer)
################################################################################

################################################################################
# OPEN LIBRARY AND COPY BLOCK
################################################################################

open_lib OV7670

# FIX: was -from_block (wrong flag) → correct flag is -from
copy_block -from top_1_data_setup -to temp_floorplan_init

open_block temp_floorplan_init

################################################################################
# SANITY CHECK
################################################################################

report_lib OV7670

puts "================================================="
puts "Current Block : [current_block]"
puts "================================================="

################################################################################
# TIMING CHECKS
################################################################################

report_clocks -skew -attributes
report_exceptions
report_disable_timing

################################################################################
# POWER / GROUND NET VARIABLES
################################################################################

set power      "VDD"
set ground     "VSS"
set powerPort  "VDD"
set groundPort "VSS"

################################################################################
# APP OPTIONS
################################################################################

set_app_option -name time.disable_recovery_removal_checks -value false
set_app_option -name time.disable_case_analysis           -value false

group_path -name INPUT  -from [all_inputs]
group_path -name OUTPUT -to   [all_outputs]
group_path -name COMBO  -from [all_inputs] -to [all_outputs]

################################################################################
# ROUTING LAYER DIRECTIONS (SAED32 preferred)
# M1=H  M2=V  M3=H  M4=V  M5=H  M6=V  M7=H
################################################################################

set_attribute [get_layers M1] routing_direction horizontal
set_attribute [get_layers M2] routing_direction vertical
set_attribute [get_layers M3] routing_direction horizontal
set_attribute [get_layers M4] routing_direction vertical
set_attribute [get_layers M5] routing_direction horizontal
set_attribute [get_layers M6] routing_direction vertical
set_attribute [get_layers M7] routing_direction horizontal

# FIX: original set M1-M8 as ignored → all signal routing blocked.
# M1 reserved for std cell rails (follow-pin).
# M8 left available as top metal if needed.
# Routing engine uses M2-M7 for signals.
set_ignored_layers -min_routing_layer M2 -max_routing_layer M7

################################################################################
# POWER / GROUND NET ATTRIBUTES
################################################################################

set_attribute -objects [get_nets VDD] -name net_type -value power
set_attribute -objects [get_nets VSS] -name net_type -value ground

check_mv_design

################################################################################
# FLOORPLAN INITIALIZATION
# core_utilization 0.2 = conservative for OV7670 (278 std cells)
# core_offset 10um all sides
################################################################################

initialize_floorplan \
    -core_utilization 0.2 \
    -core_offset {10 10 10 10}

# Verify site rows
puts "===== SITE ROWS ====="
foreach_in_collection r [get_site_rows] {
    puts "[get_object_name $r] \
          orient=[get_attribute $r orientation] \
          bbox=[get_attribute $r bbox]"
}
puts "Row Count: [sizeof_collection [get_site_rows]]"

################################################################################
# PORT PLACEMENT
# set_individual_pin_constraints assigns layer/side BEFORE place_pins runs.
# Called once per port — loop over all ports.
# SAED32: M4 (vertical pref) suits all boundary sides for a simple IO ring.
# Adjust -side per port if package constraints exist.
# -side values: 1=left 2=bottom 3=right 4=top (ICC2 convention)
################################################################################

set_individual_pin_constraints \
    -ports [get_ports *] \
    -allowed_layers {M4}

place_pins \
    -ports [get_ports *] \
    -self

puts "===== PORT PLACEMENT ====="
puts "Terminal Count: [sizeof_collection [get_terminals]]"

foreach_in_collection t [get_terminals] {
    puts "[get_object_name $t]  bbox=[get_attribute $t bbox]"
}

################################################################################
# PLACEMENT
################################################################################

create_placement \
    -floorplan       \
    -effort high     \
    -timing_driven

legalize_placement

################################################################################
# CONGESTION CHECK (pre-route global — map only, no routes committed)
################################################################################

route_global \
    -congestion_map_only true \
    -effort high

report_placement

################################################################################
# SAVE
################################################################################

save_block -as top_2_floorplan_clean
save_lib

################################################################################
# CLOSE
################################################################################

close_block
close_lib