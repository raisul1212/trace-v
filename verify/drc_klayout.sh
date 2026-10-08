#!/usr/bin/env bash
# sky130A_mr.drc (SkyWater maintainers' KLayout deck): FEOL+BEOL+off-grid. Expect 0 findings.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
GDS="${GDS:-$PKG/layout/picorv32.gds}"
RDB="$REPORTS/klayout_drc.lyrdb"
klayout -b -r "$PDKPATH/libs.tech/klayout/drc/sky130A_mr.drc" \
  -rd input="$GDS" -rd top_cell="$TOP" -rd report="$RDB" \
  -rd feol=true -rd beol=true -rd offgrid=true -rd seal=false -rd floating_met=false \
  -rd thr=2 > "$REPORTS/drc_klayout.log" 2>&1
clean_paths "$REPORTS/drc_klayout.log"
[ -s "$RDB" ] && clean_paths "$RDB"
if [ ! -s "$RDB" ]; then result drc_klayout FAIL "no report produced (see reports/drc_klayout.log)"; exit 2; fi
read -r N CATS <<< "$(python3 "$PKG/verify/util.py" lyrdb "$RDB")"
if [ "$N" = 0 ]; then result drc_klayout PASS "0 findings"; else result drc_klayout FAIL "$N findings: $CATS"; exit 1; fi
