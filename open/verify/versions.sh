#!/usr/bin/env bash
# Print the version of every tool the checks use into reports/versions.txt.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
{
  echo "Magic:          $(magic --version 2>&1 | head -1)"
  echo "Netgen:         $(netgen -batch quit 2>&1 | grep -a 'Netgen' | head -1)"
  echo "KLayout:        $(klayout -v 2>&1 | head -1)"
  echo "OpenSTA:        $(sta -version 2>&1 | head -1)"
  echo "Icarus Verilog: $(iverilog -V 2>&1 | head -1)"
  echo "Python:         $(python3 --version 2>&1)"
} > "$REPORTS/versions.txt"
cat "$REPORTS/versions.txt"
result versions PASS "$(tr -s ' ' < "$REPORTS/versions.txt" | tr '\n' ';')"
