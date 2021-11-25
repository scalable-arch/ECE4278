# ---------------------------------------
# Step 1: Specify libraries
# ---------------------------------------
set link_library \
[list /home/ScalableArchiLab/SAED32_EDK/lib/stdcell_lvt/db_ccs/saed32lvt_ss0p75v125c.db ]
set target_library \
[list /home/ScalableArchiLab/SAED32_EDK/lib/stdcell_lvt/db_ccs/saed32lvt_ss0p75v125c.db ]

set design_name         DMAC_TOP

read_ddc $design_name.ddc

#dft_drc

# ---------------------------------------
# - Specify Scan Configuration
# ---------------------------------------
# Set Scan Chain Type
set_scan_configuration -style multiplexed_flip_flop
set_scan_configuration -chain_count 2

report_scan_configuration

set test_default_period 100
set_dft_signal -view exist -type ScanClock -port clk -timing [list 50 100]
set_dft_signal -view exist -type Reset -port rst_n -active_state 0
create_test_protocol

# ---------------------------------------
# - Preview Scan configuration
# ---------------------------------------
preview_dft -show all

# ---------------------------------------
# - Scan Chain Synthesis
# ---------------------------------------
insert_dft

# ---------------------------------------
# - Report Scan information
# ---------------------------------------
dft_drc -coverage_estimate

# ---------------------------------------
# - Write output
# ---------------------------------------
write -hierarchy -format verilog -output  $design_name.netlist.scan.v
write -hierarchy -format ddc     -output  $design_name.scan.ddc
write_scan_def -output $design_name.def
set test_stil_netlist_format verilog
write_test_protocol -output $design_name.spf

exit
