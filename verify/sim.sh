#!/usr/bin/env bash
# Gate-level simulation with SDF back-annotation (Icarus Verilog).
# 8 ns (the design clock) must PASS (RESULT 55); 4 ns is a negative control and must FAIL.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
V="$PDKPATH/libs.ref/sky130_fd_sc_hd/verilog"
W="$REPORTS/sim.work"; mkdir -p "$W"; cd "$W" || exit 2
cp "$PKG/timing/picorv32.sim.sdf" picorv32.sdf       # the testbench reads "picorv32.sdf" from cwd
iverilog -g2005-sv -gspecify -ginterconnect -DUSE_POWER_PINS -o sim.vvp \
  "$PKG/sim/tb_picorv32_golden.v" "$PKG/netlist/picorv32.sim.v" "$V/primitives.v" "$V/sky130_fd_sc_hd.v" \
  > "$REPORTS/sim_compile.log" 2>&1 || { clean_paths "$REPORTS/sim_compile.log"; result sim FAIL "compile failed (see reports/sim_compile.log)"; exit 2; }
clean_paths "$REPORTS/sim_compile.log"
rc=0
for p in 8 4; do
  vvp sim.vvp +period=$p > "$REPORTS/sim_${p}.log" 2>&1
  clean_paths "$REPORTS/sim_${p}.log"
  r=$(grep -a '^RESULT' "$REPORTS/sim_${p}.log" | tail -1)
  v=$(grep -a '^VERDICT' "$REPORTS/sim_${p}.log" | tail -1)
  if [ "$p" = 8 ]; then
    if [ "$v" = "VERDICT PASS" ] && [ "$r" = "RESULT 55" ]; then result sim_8ns PASS "$r, $v"; else result sim_8ns FAIL "${r:-no RESULT}, ${v:-no VERDICT}"; rc=1; fi
  else
    if [ "$v" = "VERDICT FAIL" ]; then result sim_4ns_control PASS "control fails as expected ($r)"; else result sim_4ns_control FAIL "control did not fail: ${r:-none}, ${v:-none}"; rc=1; fi
  fi
done
exit $rc
