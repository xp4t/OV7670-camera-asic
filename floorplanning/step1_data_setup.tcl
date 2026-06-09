create_lib OV7670 \
    -technology ../lib/saed32nm_1p9m.tf \
    -ref_libs {../lib/saed32_rvt.ndm}

read_verilog ../netlist/top_netlist.v

current_design top

source ../netlist/top.sdc

link_block

read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmax.lv.tluplus \
    -name maxTLU

read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmin.lv.tluplus \
    -name minTLU

set_parasitic_parameters \
    -early_spec minTLU \
    -late_spec maxTLU

save_block -as top_1_data_setup

save_lib

close_block
close_lib