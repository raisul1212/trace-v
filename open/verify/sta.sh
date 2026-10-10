#!/usr/bin/env bash
# OpenSTA run at ss/tt/ff with the routed netlist, SDC and SPEF.
# Pass: setup and hold slack >= 0 and no slew/cap/fanout violations, all three corners.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
rc=0
for c in ss tt ff; do
  CORNER=$c sta -no_init -exit "$PKG/verify/sta.tcl" > "$REPORTS/sta_$c.log" 2>&1
  clean_paths "$REPORTS/sta_$c.log"
  out="$(python3 "$PKG/verify/util.py" sta "$REPORTS/sta_$c.log")"
  st="${out%% *}"; facts="${out#* }"
  case "$st" in
    PASS) result "sta_$c" PASS "$facts";;
    FAIL) result "sta_$c" FAIL "$facts"; rc=1;;
    *) result "sta_$c" FAIL "no result (see reports/sta_$c.log)"; rc=2;;
  esac
done
exit $rc
