# synth.tcl — Design Compiler synthesis script for OV7670 ASIC (SAED32RVT)

set DESIGN_NAME         top

# Library database file
set TARGET_LIB          saed32rvt_ss0p95v125c.db

# Library name inside DC
set TARGET_LIB_NAME     saed32rvt_ss0p95v125c

set RTL_DIR             ../rtl
set RPT_DIR             ../reports/${DESIGN_NAME}
set NETLIST_DIR         ../netlist

set NETLIST_OUT         ${NETLIST_DIR}/power/${DESIGN_NAME}_power_netlist.v
set SDC_OUT             ${NETLIST_DIR}/power/${DESIGN_NAME}.sdc
set LOG_FILE            ${RPT_DIR}/synth.log

#------------------------------------------------------------------
# Clock definitions
#------------------------------------------------------------------
set CLK_TOP_NAME        i_top_clk
set CLK_TOP_PERIOD      10.0

set CLK_VGA_NAME        w_clk25m
set CLK_VGA_PERIOD      40.0

set CLK_PCLK_NAME       i_top_pclk
set CLK_PCLK_PERIOD     40.0

file mkdir ${RPT_DIR}
file mkdir ${NETLIST_DIR}
file mkdir ${NETLIST_DIR}/power

redirect -tee ${LOG_FILE} {

    #--------------------------------------------------------------
    # Setup
    #--------------------------------------------------------------
    set_app_var search_path       ". ../lib ../rtl"
    set_app_var target_library    ${TARGET_LIB}
    set_app_var link_library      "* ${TARGET_LIB}"
    set_app_var synthetic_library dw_foundation.sldb

    remove_design -all

    #--------------------------------------------------------------
    # Read RTL
    #--------------------------------------------------------------
    analyze -format verilog [lsort [glob ${RTL_DIR}/*.v]]

    elaborate ${DESIGN_NAME}
    link
    check_design

    current_design ${DESIGN_NAME}

    #--------------------------------------------------------------
    # Clock constraints
    #--------------------------------------------------------------
    create_clock \
        -name $CLK_TOP_NAME \
        -period $CLK_TOP_PERIOD \
        [get_ports $CLK_TOP_NAME]

    create_clock \
        -name $CLK_VGA_NAME \
        -period $CLK_VGA_PERIOD \
        [get_ports $CLK_VGA_NAME]

    create_clock \
        -name $CLK_PCLK_NAME \
        -period $CLK_PCLK_PERIOD \
        [get_ports $CLK_PCLK_NAME]

    set_clock_groups -asynchronous \
        -group [get_clocks $CLK_TOP_NAME] \
        -group [get_clocks $CLK_VGA_NAME] \
        -group [get_clocks $CLK_PCLK_NAME]

    set_clock_uncertainty -setup 0.10 [all_clocks]
    set_clock_uncertainty -hold  0.05 [all_clocks]

    set_clock_transition 0.05 [all_clocks]

    #--------------------------------------------------------------
    # IO constraints
    #--------------------------------------------------------------
    set CLOCK_PORTS [get_ports [list \
        $CLK_TOP_NAME \
        $CLK_VGA_NAME \
        $CLK_PCLK_NAME]]

    set_input_delay -max [expr {$CLK_TOP_PERIOD * 0.4}] \
        -clock [get_clocks $CLK_TOP_NAME] \
        [remove_from_collection \
            [all_inputs] \
            $CLOCK_PORTS]

    set_output_delay -max [expr {$CLK_TOP_PERIOD * 0.4}] \
        -clock [get_clocks $CLK_TOP_NAME] \
        [all_outputs]

    #--------------------------------------------------------------
    # Input drive model
    #--------------------------------------------------------------
    set_driving_cell \
        -lib_cell INVX1_RVT \
        -library $TARGET_LIB_NAME \
        [remove_from_collection \
            [all_inputs] \
            $CLOCK_PORTS]

    #--------------------------------------------------------------
    # Output load model
    #--------------------------------------------------------------
    set_load \
        [expr {4 * [load_of $TARGET_LIB_NAME/INVX1_RVT/A]}] \
        [all_outputs]

    #--------------------------------------------------------------
    # Reset constraints
    #--------------------------------------------------------------
    set_false_path -from [get_ports i_top_rst]

    #--------------------------------------------------------------
    # Design rule constraints
    #--------------------------------------------------------------
    set_max_fanout 32 [current_design]

    #--------------------------------------------------------------
    # Compile options
    #--------------------------------------------------------------
    set_app_var compile_ultra_ungroup_small_hierarchies true

    #--------------------------------------------------------------
    # Compile
    #--------------------------------------------------------------
    compile \
        -map_effort medium \
        -area_effort none \
        -power_effort high

    #--------------------------------------------------------------
    # Reports
    #--------------------------------------------------------------
    check_design \
        > ${RPT_DIR}/${DESIGN_NAME}_check_design.log

    report_timing \
        -max_paths 10 \
        -delay_type max \
        -sort_by slack \
        > ${RPT_DIR}/${DESIGN_NAME}_power_timing_setup.log

    report_timing \
        -max_paths 10 \
        -delay_type min \
        -sort_by slack \
        > ${RPT_DIR}/${DESIGN_NAME}_power_timing_hold.log

    report_qor \
        > ${RPT_DIR}/${DESIGN_NAME}_power_qor.log

    report_area \
        -hierarchy \
        > ${RPT_DIR}/${DESIGN_NAME}_power_area.log

    report_power \
        -hierarchy \
        > ${RPT_DIR}/${DESIGN_NAME}_power_power.log

    report_constraint \
        -all_violators \
        > ${RPT_DIR}/${DESIGN_NAME}_power_violations.log

    report_clock_gating \
        > ${RPT_DIR}/${DESIGN_NAME}_power_clock_gating.log

    #--------------------------------------------------------------
    # Outputs
    #--------------------------------------------------------------
    write_file \
        -format verilog \
        -hierarchy \
        -pg \
        -output ${NETLIST_OUT}

    write_sdc ${SDC_OUT}

    quit
}