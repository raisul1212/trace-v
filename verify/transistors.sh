#!/usr/bin/env bash
# Transistor count from layout/picorv32.def and the PDK cell SPICE. Expect 88053.
set -u
. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
out="$(python3 "$PKG/verify/transistors.py" "${EXPECTED_TRANSISTORS:-88053}")"
st="${out%% *}"; facts="${out#* }"
if [ "$st" = PASS ]; then result transistors PASS "$facts"; else result transistors FAIL "$facts"; exit 1; fi
