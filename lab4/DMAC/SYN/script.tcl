# ---------------------------------------
# DESIGN PROFILE
# ---------------------------------------
set design_name         DMAC_TOP
set clk_port_name       clk
set clk_freq            200

# ---------------------------------------
# Read Libraries
# ---------------------------------------
set LIBLIST_PATH        $env(LIBLIST_PATH)
source $LIBLIST_PATH

# ---------------------------------------
# 0. Read Source Codes
# ---------------------------------------
set LAB_PATH            $env(LAB_PATH)
read_file $LAB_PATH/RTL/ -autoread -recursive -format sverilog -top $design_name

# ---------------------------------------
# 1. Environments Setting
# ---------------------------------------
link
uniquify

# ---------------------------------------
# 2. Constraints Setting
# ---------------------------------------
# Clock
# Reduce clock period to model wire delay (60% of original period)
set delay_percentage 0.6
set clk_period [expr 1000 / double($clk_freq)]
set clk_period [expr $clk_period * $delay_percentage]

# Create real clock if clock port is found
if {[sizeof_collection [get_ports $clk_port_name]] > 0} {
	set clk_name $clk_port_name
    create_clock -period $clk_period $clk_name
    # Set infinite drive strength
	set_drive 0 $clk_name
}
# Create virtual clock if clock port is not found
elseif {[sizeof_collection [get_ports $clk_port_name]] == 0} {
	set clk_name vclk
		create_clock -period $clk_period -name $clk_name
}
# Apply default timing constraints for modules
set_input_delay  0.0 [all_inputs] -clock $clk_name
set_output_delay 0.0 [all_outputs] -clock $clk_name

# Area
# If max_area is set 0, DesignCompiler will minimize the design as small as possible
set_max_area 0 

# ---------------------------------------
# 3. Compilation
# ---------------------------------------
#compile_ultra
compile

# ---------------------------------------
# 4. Design Reports
# ---------------------------------------
check_design  > $design_name.check_design.rpt

report_constraint -all_violators -verbose -sig 10 > $design_name.all_viol.rpt

report_design > $design_name.design.rpt
report_area -physical -hierarchy > $design_name.area.rpt
report_cell > $design_name.cell.rpt
report_qor > $design_name.qor.rpt
report_reference > $design_name.reference.rpt
report_resources > $design_name.resources.rpt
report_hierarchy -full > $design_name.hierarchy.rpt
report_timing -nworst 10 -max_paths 10 > $design_name.timing.rpt
report_power -analysis_effort high > $design_name.power.rpt
report_threshold_voltage_group > $design_name.vth.rpt

# Dump out the gate-level-netlist
write -hierarchy -format verilog -output  $design_name.netlist.v

exit


