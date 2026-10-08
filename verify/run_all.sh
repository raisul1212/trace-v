#!/usr/bin/env bash
# Run every check, write reports/, print a summary. Exit code 0 only if all pass.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/env.sh"
( cd "$PKG" && sha256sum -c SHA256SUMS > "$REPORTS/integrity.log" 2>&1 ) \
  && result integrity PASS "SHA256SUMS verified" || result integrity FAIL "see reports/integrity.log"
for s in versions sim sta transistors drc_magic drc_klayout antenna_magic lvs; do
  echo "--- $s"; bash "$HERE/$s.sh" || true
done
fail=0; : > "$REPORTS/summary.txt"
for n in integrity versions transistors sim_8.25ns sim_4.125ns_control sta_ss sta_tt sta_ff drc_magic drc_klayout antenna_magic lvs; do
  f="$REPORTS/$n.result"
  if [ -f "$f" ]; then line="$(cat "$f")"; else line="FAIL not run"; fi
  printf '%-18s %s\n' "$n" "$line" >> "$REPORTS/summary.txt"
  case "$line" in PASS*) ;; *) fail=1;; esac
done
echo; echo "================ SUMMARY ================"; cat "$REPORTS/summary.txt"
[ $fail = 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
