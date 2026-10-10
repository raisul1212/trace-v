# Common settings for the verification scripts. Source, do not execute.
# Required: PDK_ROOT = the open_pdks "share/pdk" directory (contains sky130A/).
PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${PDK_ROOT:?PDK_ROOT must point at the open_pdks share/pdk directory}"
export PKG PDK_ROOT
export PDKPATH="$PDK_ROOT/sky130A"
export TOP=picorv32
export REPORTS="${REPORTS:-$PKG/reports}"
mkdir -p "$REPORTS"
# Strip machine-specific absolute paths from files (reports are shipped).
clean_paths() { python3 "$PKG/verify/util.py" clean "$@"; }
# Write the one-line verdict for a check: result <name> PASS|FAIL "<facts>"
result() { echo "$2 $3" > "$REPORTS/$1.result"; echo "$1: $2 $3"; }
