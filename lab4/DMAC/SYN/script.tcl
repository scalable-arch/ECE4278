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
# Parse Source Codes
# ---------------------------------------
set LAB_PATH            $env(LAB_PATH)
set FILELIST_RTL        $env(FILELIST_RTL)

set FILE [open $FILELIST_RTL]
set lines [split [read $FILE] "\n"]
close $FILE;
set sources []
foreach line $lines {
    if {$line == ""} { continue }
    set src [lindex [split $line " "] 1]
    eval "set src $src"
    lappend sources $src
}

# ---------------------------------------
# 0. Read Source Codes
# ---------------------------------------
read_file -format sverilog $sources

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
set clk_period [expr 1 / $clk_freq]
set clk_period [expr $clk_period * $delay_percentage]
# Create real clock if clock port is found
if {[sizeof_collection [get_ports $clk_port_name]] > 0} {
	set clk_name clk
		create_clock -period $clk_period clk
}
# Create virtual clock if clock port is not found
if {[sizeof_collection [get_ports $clk_port_name]] == 0} {
	set clk_name vclk
		create_clock -period $clk_period -name vclk
}
# If real clock, set infinite drive strength
if {[sizeof_collection [get_ports clk]] > 0} {
	set_drive 0 clk
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


