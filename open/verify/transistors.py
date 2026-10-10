#!/usr/bin/env python3
"""Transistor count: instances in layout/picorv32.def x pfet/nfet lines per cell in the PDK cell SPICE.
Usage: transistors.py [EXPECTED]   (needs PKG and PDK_ROOT in the environment)
Prints "PASS|FAIL <facts>"; exit status 0 on PASS."""
import os, re, sys, collections

pkg, pdk = os.environ["PKG"], os.environ["PDK_ROOT"]
exp = int(sys.argv[1]) if len(sys.argv) > 1 else None
spice = pdk + "/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice"

per_cell, cur = {}, None
for line in open(spice, encoding="utf-8", errors="replace"):
    t = line.split()
    if not t:
        continue
    if t[0].lower() == ".subckt":
        cur = t[1]; per_cell[cur] = 0
    elif t[0].lower() == ".ends":
        cur = None
    elif cur and t[0][0] in "xX" and re.search(r"sky130_fd_pr__\w*fet\w*", line):
        per_cell[cur] += 1

txt = open(pkg + "/layout/picorv32.def", encoding="utf-8", errors="replace").read()
m = re.search(r"^COMPONENTS\s+(\d+)\s*;(.*?)^END COMPONENTS", txt, re.S | re.M)
if not m:
    print("FAIL no COMPONENTS section in layout/picorv32.def"); sys.exit(1)
declared = int(m.group(1))
cells = collections.Counter(re.findall(r"^\s*-\s+\S+\s+(\S+)", m.group(2), re.M))
n_inst = sum(cells.values())
missing = sorted(c for c in cells if c not in per_cell)
total = sum(n * per_cell.get(c, 0) for c, n in cells.items())
facts = "%d transistors in %d DEF components (%d cell types)" % (total, n_inst, len(cells))
if missing or n_inst != declared or total == 0:
    print("FAIL %s; declared %d instances, unknown cell types: %s" % (facts, declared, ",".join(missing) or "none")); sys.exit(1)
if exp is not None and total != exp:
    print("FAIL %s; expected %d" % (facts, exp)); sys.exit(1)
print("PASS " + facts)
