#!/bin/bash

echo "Running Design Compiler..."
dc_shell -f run_dc.tcl | tee dc.log

echo "Running ICC2..."
icc2_shell -f run_icc2.tcl | tee icc2.log

echo "Running PrimeTime..."
pt_shell -f run_pt.tcl | tee pt.log

echo "Flow Completed"
