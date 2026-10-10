# OpenSTA, one corner per run: CORNER=ss|tt|ff, PKG, PDK_ROOT in the environment.
set pkg $::env(PKG)
set lib(ss) sky130_fd_sc_hd__ss_100C_1v60.lib
set lib(tt) sky130_fd_sc_hd__tt_025C_1v80.lib
set lib(ff) sky130_fd_sc_hd__ff_n40C_1v95.lib
set corner $::env(CORNER)
read_liberty $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/$lib($corner)
read_verilog $pkg/netlist/picorv32.routed.v
link_design picorv32
read_sdc $pkg/constraints/picorv32.sdc
set_propagated_clock [all_clocks]
proc unannotated {} {
  sta::redirect_string_begin
  report_parasitic_annotation
  set out [sta::redirect_string_end]
  if {[regexp {Found ([0-9]+) unannotated drivers} $out -> n]} { return $n }
  return -1
}
set drivers [unannotated]      ;# before read_spef: every driver is unannotated
set spef_err none
if {[catch {read_spef $pkg/timing/picorv32.spef} e]} { set spef_err [string map [list \n { }] $e] }
set unann [unannotated]
puts "STA_SPEF_ERROR: $spef_err"
puts "STA_SPEF_DRIVERS: $drivers $unann"
puts "STA_CORNER $corner"
report_checks -path_delay max -format full_clock_expanded -digits 3
report_checks -path_delay min -format full_clock_expanded -digits 3
puts "STA_SETUP_WORST [format %.3f [expr {[sta::worst_slack_cmd max] * 1e9}]]"
puts "STA_HOLD_WORST [format %.3f [expr {[sta::worst_slack_cmd min] * 1e9}]]"
report_check_types -max_slew -max_capacitance -max_fanout
report_check_types -max_slew -max_capacitance -max_fanout -violators
puts "STA_MAX_SLEW_VIOLATIONS [sta::max_slew_violation_count]"
puts "STA_MAX_CAP_VIOLATIONS [sta::max_capacitance_violation_count]"
puts "STA_MAX_FANOUT_VIOLATIONS [sta::max_fanout_violation_count]"
