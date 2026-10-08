# TRACE-V: a PicoRV32 RISC-V core on SKY130, built by agentic AI and verified with independent open-source tools

TRACE-V stands for "Traceable RISC-V: AI-built, Checked, Evidenced". It is a routed,
block-level implementation of [PicoRV32](https://github.com/YosysHQ/picorv32)
(32-bit RISC-V, RV32I, default parameters) in the SkyWater `sky130A` process with the
`sky130_fd_sc_hd` standard-cell library, clocked at 8.25 ns (about 121 MHz). The repository is
https://github.com/raisul1212/trace-v.

Release v1.0.1 replaces the 8 ns route of v1.0 with an 8.25 ns route, which has a wider setup margin at the slow corner; the 8 ns release remains available at tag v1.0.

The release covers the following checks. Timing was signed off at three corners with 0.25 ns clock uncertainty. DRC was run with two independent decks, LVS against the routed netlist, and logic equivalence at both synthesis and routing. Post-layout gate-level simulation was run with flop timing checks, and static IR was analyzed. Every physical, DRV and simulation check was shown to fail on a known-bad input before it was trusted. The physical, timing and simulation checks can be reproduced from this package with open-source tools.

The package contains the design data, the commercial-tool results the release is based on, and the scripts that re-run the open-source checks.

## File map

| Path | Content |
|---|---|
| `rtl/picorv32.v` | PicoRV32 source, unmodified (ISC license) |
| `netlist/picorv32.synth.v` | Gate-level netlist after logic synthesis |
| `netlist/picorv32.routed.v` | Post-route netlist (clock tree, repair buffers); used for STA |
| `netlist/picorv32.routed.pg.v` | Post-route netlist with power pins; used for LVS |
| `netlist/picorv32.sim.v` | Post-route netlist with the cell supplies tied off; used for simulation |
| `layout/picorv32.gds` | Final layout (GDSII) |
| `layout/picorv32.def` | Final layout (DEF) |
| `constraints/picorv32.sdc` | Timing constraints |
| `timing/picorv32.spef` | Extracted parasitics (nominal RC) |
| `timing/picorv32.sdf` | Delay file as written by the timing tool |
| `timing/picorv32.sim.sdf` | Same delays with the port-ended INTERCONNECT entries removed, for Icarus Verilog |
| `sim/tb_picorv32_golden.v` | Testbench: hand-assembled RV32I program summing 1..10, stores 55 to `0x10000000` |
| `verify/` | One script per check; `run_all.sh` runs all of them |
| `reports/` | Output of `verify/run_all.sh` on this package |
| `docs/TRACE-V_PicoRV32_SKY130_deck.pdf`, `docs/TRACE-V_PicoRV32_SKY130_whitepaper.pdf` | Presentation and whitepaper |
| `LICENSE`, `LICENSES/`, `NOTICE` | License of this package, the third-party licenses, and who holds what |
| `SHA256SUMS` | Checksums of every file except `reports/` and itself |

## PDK pin

All checks use this PDK:

* open_pdks 1.0.471, commit `97d08448b2f813d15d71d3cc183014e9ac7a4f3f`
  ([RTimothyEdwards/open_pdks](https://github.com/RTimothyEdwards/open_pdks))
* `sky130_fd_sc_hd` at commit `4f4cfd106206c21fcd52b59c69749dbc90ccda07`
  ([google/skywater-pdk](https://github.com/google/skywater-pdk))

The PDK is installed with [volare](https://github.com/efabless/volare):

```
volare enable --pdk sky130 97d08448b2f813d15d71d3cc183014e9ac7a4f3f
```

`PDK_ROOT` is set to the directory that contains `sky130A/` (for volare,
`$HOME/.volare/volare/sky130/versions/<hash>`; for other installs, the open_pdks
`share/pdk` directory).

## Tools

The open-source checkers are available pre-installed in the public container image
`ghcr.io/librelane/librelane:3.0.14` (for example `apptainer pull docker://ghcr.io/librelane/librelane:3.0.14`).
The versions printed inside it, and recorded in `reports/versions.txt` by every run, are:

```
Magic:          8.3.623
Netgen:         Netgen 1.5.316 compiled on Tue Feb 10 11:09:08 UTC 2026
KLayout:        KLayout 0.30.7
OpenSTA:        2.7.0
Icarus Verilog: Icarus Verilog version 13.0 (devel) ()
Python:         Python 3.13.9
```

The same tools can be installed separately. Besides the checkers, the scripts use `bash`, GNU `grep`, `cut`
and `tr`, and `python3`.

## How to verify

The checks are run with:

```
export PDK_ROOT=/path/to/pdk-root          # contains sky130A/
cd <package directory>
# inside the container (bind mounts adjusted to the system):
apptainer exec -B "$PDK_ROOT" -B "$PWD" librelane_3.0.14.sif bash verify/run_all.sh
# or, with the tools installed locally:
bash verify/run_all.sh
```

`run_all.sh` verifies `SHA256SUMS`, prints the tool versions, runs every check below, writes the
logs and one `*.result` file per check into `reports/`, and prints a summary. Each check can also
be run alone (`bash verify/<name>.sh`). A check fails if its input does not load: an empty layout
or an unreadable SPEF is reported as FAIL, not as zero violations.

| Script | What it does | Expected |
|---|---|---|
| `verify/drc_magic.sh` | Magic full-chip DRC, `drc(full)` style, on `layout/picorv32.gds` | 0 errors |
| `verify/drc_klayout.sh` | KLayout, SkyWater `sky130A_mr.drc` deck (FEOL, BEOL, off-grid) | 0 findings |
| `verify/antenna_magic.sh` | Magic extraction and `antennacheck`; the feedback entries added by `antennacheck` are counted | 0 violations |
| `verify/lvs.sh` | Magic extraction from the GDS, Netgen LVS against `netlist/picorv32.routed.pg.v` with the PDK setup file; standard cells are also compared at transistor level | `Circuits match uniquely` |
| `verify/sta.sh` (`sta.tcl`) | OpenSTA at ss 100 C 1.60 V, tt 25 C 1.80 V, ff -40 C 1.95 V with the routed netlist, SDC and SPEF, propagated clock; the SPEF annotation is checked | setup and hold slack >= 0, no slew, capacitance or fanout violations, SPEF read without error |
| `verify/sim.sh` | Icarus Verilog gate-level simulation with SDF back-annotation at 8.25 ns, plus a 4.125 ns negative control (half the period) | 8.25 ns: `RESULT 55`, `VERDICT PASS`; 4.125 ns: `VERDICT FAIL` |
| `verify/transistors.sh` | Transistor count: cell instances in `layout/picorv32.def` times the transistors per cell in the PDK cell SPICE | 87237 |

The 4.125 ns control is part of the simulation check: a passing simulation at a clock that the timing
rejects would show that the SDF was not applied. Each verify script was checked to fail on a deliberately damaged input.

## Results

### 1. Signoff results (commercial tools, 8.25 ns)

Produced with commercial signoff tools and recorded in the project ledger. The scripts in this package do not regenerate these numbers.

| Item | Result |
|---|---|
| DRC (Magic) | 0 |
| DRC (KLayout) | 0 |
| Antenna | 0 |
| LVS | matched, 8,492 / 8,492 nets |
| Logic equivalence (RTL to netlist) | equivalent at both steps (1,916 and 1,864 compare points) |
| Setup slack, ss / tt / ff | +0.180 / +2.388 / +2.957 ns |
| Hold slack, ss / tt / ff | +0.716 / +0.214 / +0.034 ns |
| Clock uncertainty | 0.25 ns, included in the slacks above |
| Slew, capacitance, fanout violations | 0 at all corners |
| Gate-level simulation (Icarus Verilog) | passes at 8.25 ns; the control fails |
| Gate-level simulation with timing checks (Xcelium) | 0 violations at 8.25 ns, with 3,114 setup/hold checks applied; the 4 ns control fails with 76 violations |
| Static IR drop | VPWR 11 mV / VGND 11.6 mV against an 80 mV budget |
| Power | 13.0 mW at 20% activity |
| Size | 7,845 cells, 71,909 um2, 87,237 transistors, die 357.42 x 355.64 um |

### 2. Reproduced with open-source tools

The checks were run in a fresh copy of this package, inside the container `ghcr.io/librelane/librelane:3.0.14`, with the PDK above. The script exit status is non-zero while any check fails.

| Check | Status | Detail |
|---|---|---|
| Package checksums | PASS | SHA256SUMS verified |
| Transistor count (DEF x PDK cell SPICE) | PASS | 87237 transistors in 20924 DEF components (136 cell types) |
| Gate-level simulation, 8.25 ns | PASS | RESULT 55, VERDICT PASS |
| Simulation negative control, 4.125 ns | PASS | control fails as expected (RESULT trap) |
| OpenSTA ss (100 C, 1.60 V) | PASS | setup 0.280 ns, hold 0.712 ns, slew/cap/fanout violations 0/0/0, SPEF annotated 8384 of 8557 drivers (173 unannotated) |
| OpenSTA tt (25 C, 1.80 V) | PASS | setup 2.403 ns, hold 0.212 ns, slew/cap/fanout violations 0/0/0, SPEF annotated 8384 of 8557 drivers (173 unannotated) |
| OpenSTA ff (-40 C, 1.95 V) | PASS | setup 2.964 ns, hold 0.032 ns, slew/cap/fanout violations 0/0/0, SPEF annotated 8384 of 8557 drivers (173 unannotated) |
| DRC, Magic | PASS | 0 DRC errors (145 cell types in the top cell) |
| DRC, KLayout sky130A_mr | PASS | 0 findings |
| Antenna, Magic | PASS | 0 antenna violations (20800 gates analyzed.; 1 extraction warning(s)) |
| LVS, Magic + Netgen | PASS | Circuits match uniquely; Circuit 1 contains 8273 devices, Circuit 2 contains 8273 devices. Circuit 1 contains 8492 nets, Circuit 2 contains 8492 nets. |

Notes on this run:

* The ss setup slack is +0.280 ns in OpenSTA and +0.180 ns in the commercial signoff timer; both meet timing. The setup slack is the worst over all paths, including the half-period input and output paths.
* LVS: the antenna diodes are written by Magic as an instance with `perim=`, and by the PDK cell SPICE as a diode element with `pj=`. `verify/lvs.sh` rewrites that one line of the extracted SPICE (same values) before Netgen runs; without it, Netgen fails on every diode cell. LVS compares 8,273 cell instances and 8,492 nets, and each library cell is also compared at transistor level against the PDK SPICE.
* The transistor count is derived from the DEF components, which include tap and filler cells (zero transistors); the cell count in table 1 is counted differently.
* A gate-level simulation at 4.125 ns (control) must fail; the core traps and `RESULT trap` is printed. At 8.25 ns, `RESULT 55` and `VERDICT PASS` are printed.

## Limitations

* Timing is signed off at nominal RC. An independent re-extraction shows max RC costs 0.21 ns of ss setup; an estimate combining the two extractors puts the margin at about -0.03 ns at max RC, so about 8.3 ns would be needed there. The package holds one SPEF (nominal RC); the three STA corners reuse it.
* The I/O timing is set to the testbench's half-cycle protocol: inputs are driven and outputs are sampled on the falling clock edge. The ports `mem_la_*`, `pcpi_*`, `eoi` and `trace_*` are unconstrained.
* The margins are thin: ss setup +0.180 ns and ff hold +0.034 ns, after 0.25 ns of clock uncertainty.
* The post-layout simulation runs one 9-instruction program covering 6 of 40 RV32I opcodes; LEC and STA cover the whole design.
* Scope: packaging, electromigration, metal fill, seal ring, pad frame, foundry precheck and dynamic IR were outside the scope of this block-level release.

## What was cleaned

The package was derived from the working run directory without changing the design:

* `layout/picorv32.gds` is copied unmodified (`SHA256SUMS` records its hash).
* Tool header comment lines that carried host names, file paths and commands were removed from the DEF and the Verilog netlists. Nothing else in these files was edited.
* Eight buffer instances named by the flow were renamed `alias_1` to `alias_8` consistently in every netlist, the DEF, the SPEF and the SDFs.
* `constraints/picorv32.sdc`: the leading comment lines were rewritten; every command is byte-identical.
* `sim/tb_picorv32_golden.v`: the leading comment block was rewritten; the code is unchanged.
* `timing/picorv32.sim.sdf` is `timing/picorv32.sdf` with the INTERCONNECT entries ending at a port removed (454 entries; Icarus Verilog cannot annotate them).
* `rtl/picorv32.v` is the upstream file, byte for byte.

## License

* This package is licensed for **non-commercial academic instruction and research only** (`LICENSE`, copyright 2026 Raisul Islam). Commercial or any other use requires written permission; see Contact below.
* Publications, theses and teaching materials that use these files should cite https://github.com/raisul1212/trace-v.
* The third-party components keep their own licenses: `rtl/picorv32.v` is ISC (copyright 2015 Claire Xenia Wolf, `LICENSES/ISC-picorv32.txt`); the SkyWater SKY130 PDK and cell data are Apache-2.0 (SkyWater Technology Foundry and Google LLC, `LICENSES/Apache-2.0.txt`). `NOTICE` lists all three.

## Contact

This design was implemented and signed off by an agentic chip-design framework. For research collaboration or licensing inquiries about the framework, contact Raisul Islam — raisul@purdue.edu.
