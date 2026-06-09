# =============================================================================
# synth.tcl — Design Compiler synthesis script
# Design  : OV7670 Camera ASIC (top)
# Library : SAED32RVT SS 0.95V 125C
# Tool    : Synopsys Design Compiler W-2024.09
# =============================================================================

set DESIGN_NAME         top
set TARGET_LIB          saed32rvt_ss0p95v125c.db

set RTL_DIR             ../rtl
set RPT_DIR             ../reports/${DESIGN_NAME}
set NETLIST_DIR         ../netlist

set NETLIST_OUT         ${NETLIST_DIR}/${DESIGN_NAME}_netlist.v
set SDC_OUT             ${NETLIST_DIR}/${DESIGN_NAME}.sdc

# -----------------------------------------------------------------------------
# Clock Definitions
# -----------------------------------------------------------------------------

set CLK_TOP_PERIOD      10.0
set CLK_VGA_PERIOD      40.0
set CLK_PCLK_PERIOD     40.0

set CLK_TOP_NAME        i_top_clk
set CLK_VGA_NAME        w_clk25m
set CLK_PCLK_NAME       i_top_pclk

file mkdir ${RPT_DIR}
file mkdir ${NETLIST_DIR}

redirect -tee ${RPT_DIR}/synth.log {

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

set_app_var search_path ". ../lib ../rtl"

set_app_var target_library    ${TARGET_LIB}
set_app_var link_library      "* ${TARGET_LIB} dw_foundation.sldb"
set_app_var synthetic_library dw_foundation.sldb

set_app_var power_default_toggle_rate 0.1
set_app_var compile_clock_gating_through_hierarchy true

remove_design -all

sh rm -rf ./WORK ./work ./Work alib_cache
sh bash -c "rm -f ${RTL_DIR}/*.syn 2>/dev/null ; true"

define_design_lib WORK -path ./WORK

# -----------------------------------------------------------------------------
# Read RTL
# -----------------------------------------------------------------------------

analyze -format verilog [lsort [glob ${RTL_DIR}/*.v]]

elaborate ${DESIGN_NAME}
link

current_design ${DESIGN_NAME}

uniquify

# -----------------------------------------------------------------------------
# Initial Checks
# -----------------------------------------------------------------------------

check_design

# -----------------------------------------------------------------------------
# Clock Constraints
# -----------------------------------------------------------------------------

create_clock \
    -name ${CLK_TOP_NAME} \
    -period ${CLK_TOP_PERIOD} \
    [get_ports ${CLK_TOP_NAME}]

catch {
    create_clock \
        -name ${CLK_VGA_NAME} \
        -period ${CLK_VGA_PERIOD} \
        [get_ports ${CLK_VGA_NAME}]
}

create_clock \
    -name ${CLK_PCLK_NAME} \
    -period ${CLK_PCLK_PERIOD} \
    [get_ports ${CLK_PCLK_NAME}]

set_clock_groups -asynchronous \
    -group [get_clocks ${CLK_TOP_NAME}] \
    -group [get_clocks ${CLK_PCLK_NAME}]

set_clock_uncertainty -setup 0.10 [all_clocks]
set_clock_uncertainty -hold  0.05 [all_clocks]

set_clock_transition 0.10 [all_clocks]

# -----------------------------------------------------------------------------
# I/O Constraints
# -----------------------------------------------------------------------------

set NON_CLOCK_INPUTS \
    [remove_from_collection \
        [all_inputs] \
        [get_ports "${CLK_TOP_NAME} ${CLK_PCLK_NAME} ${CLK_VGA_NAME}"]]

set_input_delay -max 4.0 \
    -clock ${CLK_TOP_NAME} \
    ${NON_CLOCK_INPUTS}

set_input_delay -min 0.5 \
    -clock ${CLK_TOP_NAME} \
    ${NON_CLOCK_INPUTS}

set_output_delay -max 4.0 \
    -clock ${CLK_TOP_NAME} \
    [all_outputs]

set_output_delay -min 0.5 \
    -clock ${CLK_TOP_NAME} \
    [all_outputs]

set_input_transition 0.15 [all_inputs]

# -----------------------------------------------------------------------------
# Drive / Load Modeling
# -----------------------------------------------------------------------------

set_driving_cell \
    -lib_cell INVX4_RVT \
    -library ${TARGET_LIB} \
    ${NON_CLOCK_INPUTS}

set_load \
    [expr {4 * [load_of ${TARGET_LIB}/INVX1_RVT/A]}] \
    [all_outputs]

# -----------------------------------------------------------------------------
# Design Rule Constraints
# -----------------------------------------------------------------------------

set_max_fanout 16 [current_design]

# Previous value 0.12 caused unnecessary DRV pressure.
set_max_transition 0.15 [current_design]

# DO NOT force global max capacitance.
# Allow library limits to control capacitance.

set_fix_multiple_port_nets \
    -all \
    -buffer_constants

# -----------------------------------------------------------------------------
# Timing Exceptions
# -----------------------------------------------------------------------------

catch {
    set_false_path -from [get_ports i_top_rst]
}

catch {
    set_false_path \
        -from [get_ports i_top_cam_start] \
        -to [get_pins OV7670_cam/cam_btn_start_db/counter_reg*/RSTB]
}

catch {
    set_false_path \
        -from [get_ports i_top_cam_start] \
        -to [get_pins OV7670_cam/cam_btn_start_db/r_sample_reg/RSTB]
}

catch {
    set_false_path \
        -from [get_ports i_top_btn] \
        -to [get_pins top_btn_db/counter_reg*/RSTB]
}

catch {
    set_false_path \
        -from [get_ports i_top_btn] \
        -to [get_pins top_btn_db/r_sample_reg/RSTB]
}

# -----------------------------------------------------------------------------
# Clock Gating
# -----------------------------------------------------------------------------

set_clock_gating_style \
    -sequential_cell latch \
    -positive_edge_logic integrated \
    -minimum_bitwidth 4 \
    -num_stages 1

# -----------------------------------------------------------------------------
# Optimization Priorities
# -----------------------------------------------------------------------------

set_cost_priority -delay

# -----------------------------------------------------------------------------
# Compile Pass 1
# -----------------------------------------------------------------------------

compile_ultra \
    -gate_clock \
    -timing_high_effort_script \
    -no_autoungroup

# -----------------------------------------------------------------------------
# Compile Pass 2
# -----------------------------------------------------------------------------

compile_ultra \
    -incremental \
    -gate_clock \
    -no_autoungroup

# -----------------------------------------------------------------------------
# Area Recovery
# -----------------------------------------------------------------------------

optimize_netlist -area

# -----------------------------------------------------------------------------
# Compile Pass 3
# -----------------------------------------------------------------------------

compile_ultra \
    -incremental \
    -gate_clock \
    -no_autoungroup

# -----------------------------------------------------------------------------
# Final Cleanup
# -----------------------------------------------------------------------------

compile_ultra -incremental

update_timing

# -----------------------------------------------------------------------------
# Sanity Checks
# -----------------------------------------------------------------------------

check_design
check_timing

# -----------------------------------------------------------------------------
# Reports
# -----------------------------------------------------------------------------

report_qor \
    > ${RPT_DIR}/${DESIGN_NAME}_qor.rpt

report_area -hierarchy \
    > ${RPT_DIR}/${DESIGN_NAME}_area.rpt

report_power -hierarchy -analysis_effort high \
    > ${RPT_DIR}/${DESIGN_NAME}_power.rpt

report_clock_gating \
    > ${RPT_DIR}/${DESIGN_NAME}_clock_gating.rpt

report_constraint -all_violators \
    > ${RPT_DIR}/${DESIGN_NAME}_violations.rpt

report_net_fanout -threshold 16 \
    > ${RPT_DIR}/${DESIGN_NAME}_fanout.rpt

report_timing \
    -delay_type max \
    -path full \
    -max_paths 20 \
    -sort_by slack \
    > ${RPT_DIR}/${DESIGN_NAME}_setup.rpt

report_timing \
    -delay_type min \
    -path full \
    -max_paths 20 \
    -sort_by slack \
    > ${RPT_DIR}/${DESIGN_NAME}_hold.rpt

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

write_file \
    -format verilog \
    -hierarchy \
    -output ${NETLIST_OUT}

write_sdc ${SDC_OUT}

}