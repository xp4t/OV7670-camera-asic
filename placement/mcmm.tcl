remove_corners -all
remove_modes -all
remove_scenarios -all

create_corner slow
create_corner fast

read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmax.lv.tluplus \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map \
    -name tlup_max

read_parasitic_tech \
    -tlup ../lib/saed32nm_1p9m_Cmin.lv.tluplus \
    -layermap ../lib/saed32nm_tf_itf_tluplus.map\
    -name tlup_min

set_parasitics_parameters \
	-early_spec tlup_min \
	-late_spec tlup_min \
	-corners {fast}

set_parasitics_parameters \
	-early_spec tlup_max \
	-late_spec tlup_max \
	-corners {slow}

create_mode func
current_mode func
create_scenario -mode func -corner fast -name func_fast
create_scenario -mode func -corner slow -name func_slow

current_scenario func_fast
read_sdc ../netlist/top.sdc

current_scenario func_fast
read_sdc ../netlist/top.sdc


