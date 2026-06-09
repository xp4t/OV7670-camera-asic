################################################################################Open_Lib
open_lib ../floorplanning/OV7670
open_block top_7_signoff_final

################################################################################Parasitics
read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmax.lv.tluplus \
    -name maxTLU \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map
read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmin.lv.tluplus \
    -name minTLU \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map

################################################################################Write_SPEF
write_parasitics \
    -format spef \
    -output ../netlist/OV7670

################################################################################Write_Netlist
write_verilog \
    -include {pg_netlist} \
    ../netlist/OV7670_final.v

################################################################################Write_SDC
write_sdc -scenario func_fast -output ../netlist/OV7670_func_fast.sdc
write_sdc -scenario func_slow -output ../netlist/OV7670_func_slow.sdc

save_lib
close_block
close_lib