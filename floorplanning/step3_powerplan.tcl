open_lib OV7670

copy_block -from top_2_floorplan_clean -to temp_powerplan_clean

open_block temp_powerplan_clean

if {[sizeof_collection [get_nets VDD]] == 0} { create_net VDD }
if {[sizeof_collection [get_nets VSS]] == 0} { create_net VSS }

set_attribute [get_nets VDD] net_type power
set_attribute [get_nets VSS] net_type ground

connect_pg_net -automatic

remove_pg_via_master_rules -all
remove_pg_patterns -all
remove_pg_strategies -all
remove_pg_strategy_via_rules -all

create_pg_ring_pattern CORE_RING \
    -horizontal_layer M7 \
    -vertical_layer M6 \
    -horizontal_width 1.0 \
    -vertical_width 1.0 \
    -horizontal_spacing 3.0 \
    -vertical_spacing 3.0

set_pg_strategy CORE_RING_STRAT \
    -core \
    -pattern {{name:CORE_RING} {nets:{VDD VSS}}}

compile_pg -strategies CORE_RING_STRAT

create_pg_mesh_pattern MESH_M7 \
    -layers {
        {
            {horizontal_layer:M7}
            {width:0.30}
            {spacing:interleaving}
            {pitch:4.0}
            {offset:0.5}
            {trim:true}
        }
    }

set_pg_strategy MESH_M7_STRAT \
    -core \
    -pattern {{name:MESH_M7} {nets:{VDD VSS}}}

compile_pg -strategies MESH_M7_STRAT

create_pg_mesh_pattern MESH_M6 \
    -layers {
        {
            {vertical_layer:M6}
            {width:0.30}
            {spacing:interleaving}
            {pitch:4.0}
            {offset:0.5}
            {trim:true}
        }
    }

set_pg_strategy MESH_M6_STRAT \
    -core \
    -pattern {{name:MESH_M6} {nets:{VDD VSS}}}

compile_pg -strategies MESH_M6_STRAT

create_pg_mesh_pattern MESH_M5 \
    -layers {
        {
            {horizontal_layer:M5}
            {width:0.14}
            {spacing:interleaving}
            {pitch:8.0}
            {offset:1.0}
            {trim:true}
        }
    }

set_pg_strategy MESH_M5_STRAT \
    -core \
    -pattern {{name:MESH_M5} {nets:{VDD VSS}}}

compile_pg -strategies MESH_M5_STRAT

create_pg_mesh_pattern MESH_M4 \
    -layers {
        {
            {vertical_layer:M4}
            {width:0.14}
            {spacing:interleaving}
            {pitch:8.0}
            {offset:1.0}
            {trim:true}
        }
    }

set_pg_strategy MESH_M4_STRAT \
    -core \
    -pattern {{name:MESH_M4} {nets:{VDD VSS}}}

compile_pg -strategies MESH_M4_STRAT

create_pg_mesh_pattern MESH_M3 \
    -layers {
        {
            {horizontal_layer:M3}
            {width:0.14}
            {spacing:interleaving}
            {pitch:8.0}
            {offset:1.0}
            {trim:true}
        }
    }

set_pg_strategy MESH_M3_STRAT \
    -core \
    -pattern {{name:MESH_M3} {nets:{VDD VSS}}}

compile_pg -strategies MESH_M3_STRAT

create_pg_mesh_pattern MESH_M2 \
    -layers {
        {
            {vertical_layer:M2}
            {width:0.10}
            {spacing:interleaving}
            {pitch:4.0}
            {offset:0.5}
            {trim:true}
        }
    }

set_pg_strategy MESH_M2_STRAT \
    -core \
    -pattern {{name:MESH_M2} {nets:{VDD VSS}}}

compile_pg -strategies MESH_M2_STRAT

create_pg_std_cell_conn_pattern M1_RAIL \
    -layers M1 \
    -rail_width 0.072 \
    -mark_as_follow_pin true

set_pg_strategy CORE_RAILS \
    -core \
    -pattern {{name:M1_RAIL} {nets:{VDD VSS}}}

compile_pg -strategies CORE_RAILS

check_pg_connectivity
check_pg_drc

report_pg_patterns
report_pg_strategies

save_block -as top_3_powerplan_clean
save_lib