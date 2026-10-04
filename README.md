# PicoRV32 on SkyWater 130 nm — commercial and open-source flows

Lampro AI is implementing the [PicoRV32](https://github.com/YosysHQ/picorv32)
RISC-V core on the open [SkyWater SKY130](https://github.com/google/skywater-pdk)
process twice:

1. **Commercial implementation.** Cadence Genus (synthesis), Innovus
   (place-and-route), Tempus (timing) and Conformal (equivalence). The
   layout is then checked with open-source tools (magic, netgen), so anyone
   can re-check it.
2. **Open-source implementation, end to end.** The same core with open
   tools only, from RTL to GDS (in progress).

Both will be published here with their checks and their reports.

## Status (2026-10-04)

Commercial flow, `sky130_fd_sc_hd`, 8 ns clock (125 MHz). Figures are post-layout:

| check | tool | result |
|---|---|---|
| DRC | magic (open) | clean. Control: a planted 50 nm met1 sliver is flagged |
| Process antennas | magic (open) | clean. Control: the same layout with its antenna diode removed shows 1 violation |
| LVS | magic + netgen (open) | matched, 7400/7400 nets. Control: the netlist with one instance removed fails |
| Setup, ss 100 °C 1.60 V | Tempus, extracted parasitics, propagated clock | +0.386 ns |
| Hold, register-to-register, ss | Tempus | +1.006 ns |
| Setup / hold, ff and tt | Tempus | ff +5.45 / +0.306 ns, tt +4.07 / +0.492 ns (being added to the record) |
| Logic equivalence, RTL to routed netlist | Conformal | equivalent, 0 non-equivalent points. Control: one swapped gate gives 15 (being added to the record) |
| Static IR drop | Voltus | **open issue:** about 114 mV on VPWR with a single-point supply feed. Being fixed |

Each "control" is a copy of the design deliberately broken. The check must
fail on that copy before its result on the real design is accepted.

**Not yet:**
- IO timing. The block has no input or output delays; they belong to whoever integrates it.
- Integration into a shuttle harness, metal fill, and the foundry precheck.

This is a signed-off *block*, not yet a fabrication submission.

## Terms

No licence is granted yet; all rights are reserved while terms are
settled. Third-party material keeps its own terms. See [NOTICE](NOTICE).
