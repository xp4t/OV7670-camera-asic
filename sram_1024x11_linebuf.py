word_size = 11
num_words = 1024          # 640 rounded up to power of 2
tech_name = "sky130"

num_rw_ports = 0
num_r_ports  = 1          # VGA reads pixels out
num_w_ports  = 1          # prefetch writes next line in

process_corners = ["TT"]
supply_voltages = [1.8]
temperatures = [25]

output_path = "gen_bram"
output_name = "sram_1024x11_linebuf"

drc_name = "magic"
lvs_name = "netgen"
pex_name = "magic"

num_spare_cols = 1
