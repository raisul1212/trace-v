#!/usr/bin/env python3
"""Helpers for the verify scripts (the container has no sed/awk, so these live here).
  util.py clean FILE...   replace machine-specific absolute paths in reports
  util.py sta LOG         evaluate one OpenSTA corner log -> "PASS|FAIL|NORES <facts>"
  util.py lyrdb FILE      count KLayout DRC findings -> "<n> <category xN ...>"
  util.py layoutspice IN OUT  rewrite the antenna-diode line of the extracted SPICE the way the PDK cell
                          SPICE writes it (D element, pj= instead of X instance, perim=; same values)
"""
import os, re, sys, collections

def clean(files):
    subs = []
    for var, tag in (("PKG", "<pkg>"), ("PDK_ROOT", "<PDK_ROOT>"), ("REPORTS", "<reports>"), ("HOME", "<home>")):
        v = os.environ.get(var, "")
        if len(v) > 1:
            subs.append((v.rstrip("/"), tag))
    subs.sort(key=lambda s: -len(s[0]))      # longest path first
    for f in files:
        if not os.path.isfile(f):
            continue
        t = open(f, encoding="utf-8", errors="surrogateescape").read()
        for a, b in subs:
            t = t.replace(a, b)
        open(f, "w", encoding="utf-8", errors="surrogateescape").write(t)

def sta(log):
    t = open(log, encoding="utf-8", errors="replace").read()
    g = lambda k: (re.search(r"^%s\s+(\S+)" % k, t, re.M) or [None, None])[1]
    s, h = g("STA_SETUP_WORST"), g("STA_HOLD_WORST")
    v = [g("STA_MAX_SLEW_VIOLATIONS"), g("STA_MAX_CAP_VIOLATIONS"), g("STA_MAX_FANOUT_VIOLATIONS")]
    err = re.search(r"^STA_SPEF_ERROR:\s*(.*)$", t, re.M)
    sd = re.search(r"^STA_SPEF_DRIVERS:\s+(-?\d+)\s+(-?\d+)", t, re.M)
    if None in [s, h] + v or not err or not sd:
        print("NORES no result"); return
    total, unann = int(sd.group(1)), int(sd.group(2))
    ann = total - unann
    if err.group(1).strip() != "none":
        print("FAIL SPEF read error: %s" % err.group(1).strip()[:120]); return
    if total <= 0 or unann < 0 or ann <= 0:
        print("FAIL SPEF annotated no drivers (%d of %d)" % (ann, total)); return
    ok = float(s) >= 0 and float(h) >= 0 and all(int(x) == 0 for x in v)
    print("%s setup %s ns, hold %s ns, slew/cap/fanout violations %s/%s/%s, SPEF annotated %d of %d drivers (%d unannotated)"
          % (("PASS" if ok else "FAIL"), s, h, *v, ann, total, unann))

def lyrdb(f):
    t = open(f, encoding="utf-8", errors="replace").read()
    items = re.findall(r"<item>(.*?)</item>", t, re.S)
    cats = collections.Counter(re.sub(r"[\s']", "", re.search(r"<category>(.*?)</category>", i, re.S).group(1)) for i in items)
    print(len(items), " ".join("%s x%d" % kv for kv in sorted(cats.items())))

def layoutspice(src, dst):
    """Write Magic's antenna-diode line in the form the PDK cell SPICE uses
    (D element, pj= instead of X instance, perim=); values are unchanged."""
    out = []
    for l in open(src, encoding="utf-8", errors="surrogateescape"):
        if "sky130_fd_pr__diode" in l and not l.startswith("*"):
            l = l.replace(" perim=", " pj=")
            if l.startswith("X"):
                l = "D" + l[1:]
        out.append(l)
    open(dst, "w", encoding="utf-8", errors="surrogateescape").write("".join(out))

if __name__ == "__main__":
    c = sys.argv[1]
    {"clean": lambda: clean(sys.argv[2:]), "sta": lambda: sta(sys.argv[2]), "lyrdb": lambda: lyrdb(sys.argv[2]), "layoutspice": lambda: layoutspice(sys.argv[2], sys.argv[3])}[c]()
