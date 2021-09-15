# ---------------------------------------
# Step 1: Specify libraries
# ---------------------------------------
set link_library \
[list /home/ScalableArchiLab/SAED32_EDK/lib/stdcell_lvt/db_ccs/saed32lvt_ss0p75v125c.db ]
set target_library \
[list /home/ScalableArchiLab/SAED32_EDK/lib/stdcell_lvt/db_ccs/saed32lvt_ss0p75v125c.db ]

# ---------------------------------------
# Step 2: Read designs
# ---------------------------------------
analyze -format sverilog $env(LAB_PATH)/RTL/DMAC_CFG.sv
analyze -format sverilog $env(LAB_PATH)/RTL/DMAC_ENGINE.sv
analyze -format sverilog $env(LAB_PATH)/RTL/DMAC_FIFO.sv
analyze -format sverilog $env(LAB_PATH)/RTL/DMAC_TOP.sv

set design_name         DMAC_TOP
elaborate $design_name

# connect all the library components and designs
link

# renames multiply references designs so that each
# instance references a unique design
uniquify

# ---------------------------------------
# Step 3: Define design environments
# ---------------------------------------
#
# ---------------------------------------
# Step 4: Set design constraints
# ---------------------------------------
# ---------------------------------------
# Clock
# ---------------------------------------
set clk_name clk
set clk_freq            200

# Reduce clock period to model wire delay (60% of original period)
set derating 0.65
set clk_period [expr 1000 / double($clk_freq)]
set clk_period [expr $clk_period * $derating]

create_clock -period $clk_period $clk_name
# Set infinite drive strength
set_drive 0 $clk_name

# ---------------------------------------
# Input/Output
# ---------------------------------------
# Apply default timing constraints for modules
set_input_delay  2.0 [all_inputs]  -clock $clk_name
set_output_delay 2.0 [all_outputs] -clock $clk_name

# ---------------------------------------
# Area
# ---------------------------------------
# If max_area is set 0, DesignCompiler will minimize the design as small as possible
set_max_area 0 

# ---------------------------------------
# Step 5: Synthesize and optimzie the design
# ---------------------------------------
compile_ultra
#compile

# ---------------------------------------
# Step 6: Analyze and resolve design problems
# ---------------------------------------
check_design  > $design_name.check_design.rpt

report_constraint -all_violators -verbose -sig 10 > $design_name.all_viol.rpt

report_design                             > $design_name.design.rpt
report_area -physical -hierarchy          > $design_name.area.rpt
report_timing -nworst 10 -max_paths 10    > $design_name.timing.rpt
report_power -analysis_effort high        > $design_name.power.rpt
report_cell                               > $design_name.cell.rpt
report_qor                                > $design_name.qor.rpt
report_reference                          > $design_name.reference.rpt
report_resources                          > $design_name.resources.rpt
report_hierarchy -full                    > $design_name.hierarchy.rpt
report_threshold_voltage_group            > $design_name.vth.rpt

# ---------------------------------------
# Step 7: Save the design database
# ---------------------------------------
write -hierarchy -format verilog -output  $design_name.netlist.v
write -hierarchy -format ddc     -output  $design_name.ddc
write_sdf -version 1.0                    $design_name.sdf
write_sdc                                 $design_name.sdc

# ---------------------------------------
# Step 8: Save the design database
# ---------------------------------------
set_scan_configuration -chain_count 5
create_test_protocol -infer_clock -infer_asynch

preview_dft

dft_drc

insert_dft

write -hierarchy -format verilog -output  $design_name.scan.netlist.v
write_test_protocol              -output  $design_name.scan.stil
write_sdc                                 $design_name.scan.sdc

exit
