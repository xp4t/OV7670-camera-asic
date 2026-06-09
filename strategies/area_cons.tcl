# synth.tcl — Design Compiler synthesis script for OV7670 ASIC (SAED32RVT)

set DESIGN_NAME         top
set TARGET_LIB          saed32rvt_ss0p95v125c.db
set RTL_DIR             ../rtl
set RPT_DIR             ../reports/${DESIGN_NAME}
set NETLIST_DIR         ../netlist
set NETLIST_OUT         ${NETLIST_DIR}/area/${DESIGN_NAME}_area_netlist.v
set SDC_OUT             ${NETLIST_DIR}/area/${DESIGN_NAME}.sdc
set LOG_FILE            ${RPT_DIR}/synth.log

# Clock definitions — adjust frequencies to match your actual design
set CLK_TOP_NAME        i_top_clk
set CLK_TOP_PERIOD      10.0        ;# 100 MHz

set CLK_VGA_NAME        w_clk25m
set CLK_VGA_PERIOD      40.0        ;# 25 MHz

set CLK_PCLK_NAME       i_top_pclk
set CLK_PCLK_PERIOD     40.0        ;# 25 MHz (OV7670 PCLK max)

file mkdir ${RPT_DIR}
file mkdir ${NETLIST_DIR}
file mkdir ${NETLIST_DIR}/area

redirect -tee ${LOG_FILE} {

    #------------------------------------------------------------------
    # Setup
    #------------------------------------------------------------------
    set_app_var search_path         ". ../lib ../rtl"
    set_app_var target_library      ${TARGET_LIB}
    set_app_var link_library        "* ${TARGET_LIB}"
    set_app_var synthetic_library   dw_foundation.sldb

    remove_design -all

    #------------------------------------------------------------------
    # Read and elaborate RTL
    #------------------------------------------------------------------
    analyze -format verilog [lsort [glob ${RTL_DIR}/*.v]]
    elaborate ${DESIGN_NAME}
    link
    check_design
    current_design ${DESIGN_NAME}

    #------------------------------------------------------------------
    # Constraints
    #------------------------------------------------------------------

    # Clocks
    create_clock -name ${CLK_TOP_NAME} \
                 -period ${CLK_TOP_PERIOD} \
                 [get_ports ${CLK_TOP_NAME}]

    create_clock -name ${CLK_VGA_NAME} \
                 -period ${CLK_VGA_PERIOD} \
                 [get_ports ${CLK_VGA_NAME}]

    create_clock -name ${CLK_PCLK_NAME} \
                 -period ${CLK_PCLK_PERIOD} \
                 [get_ports ${CLK_PCLK_NAME}]

    # Treat clocks as asynchronous to each other (3 separate domains)
    set_clock_groups -asynchronous \
        -group [get_clocks ${CLK_TOP_NAME}] \
        -group [get_clocks ${CLK_VGA_NAME}] \
        -group [get_clocks ${CLK_PCLK_NAME}]

    # Clock uncertainty (jitter + skew)
    set_clock_uncertainty -setup 0.1 [all_clocks]
    set_clock_uncertainty -hold  0.05 [all_clocks]

    # Clock transition
    set_clock_transition 0.05 [all_clocks]

    # Input/output delays — 40% of period as placeholder
    set_input_delay  -max [expr {${CLK_TOP_PERIOD} * 0.4}] \
                     -clock ${CLK_TOP_NAME} \
                     [remove_from_collection [all_inputs] \
                         [get_ports ${CLK_TOP_NAME}]]

    set_output_delay -max [expr {${CLK_TOP_PERIOD} * 0.4}] \
                     -clock ${CLK_TOP_NAME} \
                     [all_outputs]

    # Drive strength on inputs (600 ohm typical IO)
    set_driving_cell -lib_cell INVX1_RVT \
                     -library ${TARGET_LIB} \
                     [all_inputs]

    # Load on outputs (4x standard inverter)
    set_load [expr {4 * [load_of ${TARGET_LIB}/INVX1_RVT/A]}] \
             [all_outputs]

    # False paths on async reset (crosses clock domains intentionally)
    set_false_path -from [get_ports i_top_rst]

    # Max fanout
    set_max_fanout 32 ${DESIGN_NAME}

    # Flatten hierarchy for better optimization
    set_app_var compile_ultra_ungroup_small_hierarchies true

    #------------------------------------------------------------------
    # Compile
    #------------------------------------------------------------------
    compile -map_effort medium -area_effort high -power_effort none
    #start_gui

    #------------------------------------------------------------------
    # Reports
    #------------------------------------------------------------------
    check_design > ${RPT_DIR}/${DESIGN_NAME}_check_design.log

    report_timing -max_paths 10 \
                  -delay_type max \
                  -sort_by slack \
                  > ${RPT_DIR}/${DESIGN_NAME}_area_timing_setup.log

    report_timing -max_paths 10 \
                  -delay_type min \
                  -sort_by slack \
                  > ${RPT_DIR}/${DESIGN_NAME}_area_timing_hold.log

    report_qor    > ${RPT_DIR}/${DESIGN_NAME}_area_qor.log

    report_area   -hierarchy \
                  > ${RPT_DIR}/${DESIGN_NAME}_area_area.log

    report_power  -hierarchy \
                  > ${RPT_DIR}/${DESIGN_NAME}_area_power.log

    report_constraint -all_violators \
                  > ${RPT_DIR}/${DESIGN_NAME}_area_violations.log

    report_clock_gating \
                  > ${RPT_DIR}/${DESIGN_NAME}_area_clock_gating.log

    #------------------------------------------------------------------
    # Write outputs
    #------------------------------------------------------------------
    write_file -f verilog \
               -hier \
	       -pg \
               -output ${NETLIST_OUT}

    write_sdc   ${SDC_OUT}

    quit
}