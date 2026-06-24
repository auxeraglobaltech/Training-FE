# 2×2×2 NoC — RTL + UVM Testbench

A compact Network-on-Chip used as a verification training platform: 2 AXI masters reach
2 AXI slaves directly and 2 APB slaves through an AXI→APB bridge, all routed and arbitrated
by the NoC fabric. Built for **Cadence Xcelium** with **UVM (CDNS-1.2)**.

## Layout
```
RTL/noc/
  RTL/    DUT — self-contained RTL (noc_pkg, decoder, arbiter, bridge, fabric, noc_top)
  tb/     UVM testbench (interfaces, agents, env, sequences, tests, SVA, top)
  sim/    filelist.f, Makefile, README, runs/ (per-run logs/waves)
```

## Address map (single source of truth — `RTL/noc_pkg.sv`)
| Target | Type | Base        | End         | Size   |
|--------|------|-------------|-------------|--------|
| S0     | AXI  | 0x0000_0000 | 0x0FFF_FFFF | 256 MB |
| S1     | AXI  | 0x1000_0000 | 0x1FFF_FFFF | 256 MB |
| P0     | APB  | 0x2000_0000 | 0x2000_FFFF | 64 KB  |
| P1     | APB  | 0x2001_0000 | 0x2001_FFFF | 64 KB  |
| (else) | —    | unmapped → DECERR        |        |

## Quick start
```bash
source ~/cshrc          # puts xrun (Xcelium 2503) on PATH
cd RTL/noc/sim
make elab               # compile + elaborate only (fast check)
make sim TESTNAME=noc_base_test
make sim TESTNAME=noc_rr_arb_test WAVES=1 SEED=42
```
Each run lands in `sim/runs/run_<timestamp>_seed<N>/xrun.log`. Pass/fail:
```bash
grep -E "PASSED|FAILED|UVM_ERROR|UVM_FATAL" sim/runs/run_*/xrun.log | tail
```

## Configuration (fixed for this build)
- 32-bit address & data, 4-bit master AXI ID (remapped to 5-bit slave-side), INCR bursts, AxQOS.
- **Reads:** multi-outstanding (cap `MAX_OUTSTANDING`), out-of-order multi-ID across the fabric.
  Same-`ARID` reads to *different* targets are serialised at ingress so same-ID order is preserved
  (the cross-slave same-ID contract); different IDs complete out of order freely.
- **Writes:** one outstanding per master (fabric-wide) — a deliberate simplification that avoids
  W-data interleaving hazards; same-ID write order is therefore automatic. The master agent issues
  W beats in AW order.
- Arbitration: priority (AxQOS) + round-robin tie-break, **strict** (low-priority can starve, by design).

## Bug injection (training)
Compile-time, OFF by default. `make sim TESTNAME=<t> BUG=<NAME>`:
| BUG name        | Injected defect |
|-----------------|-----------------|
| RR_FREEZE       | arbiter pointer not updated on an uncontested grant |
| PSLVERR_SWALLOW | APB PSLVERR reported back to AXI as OKAY |
| DECERR_OMIT     | unmapped access gets no response (fabric hangs → watchdog) |
| BRIDGE_ADDR     | bridge uses wrong INCR step for APB burst beats |
| BRESP_PERBEAT   | write burst emits one B per beat (illegal) |
| SAMEID_REORDER  | same-ID responses returned out of order |

## Tests (all pass on the golden RTL)
| Test                    | What it exercises |
|-------------------------|-------------------|
| `noc_sanity_test`       | One master: W+R to every target + DECERR (env bring-up) |
| `noc_decode_test`       | Range-edge addresses route correctly; unmapped -> DECERR |
| `noc_random_test`       | Randomised mixed traffic from one master |
| `noc_concurrency_test`  | Both masters, independent mixed traffic across the fabric |
| `noc_rr_arb_test`       | Both masters contend at S0, equal QoS (round-robin) |
| `noc_priority_test`     | Both masters contend at S0, M1 higher QoS (strict priority) |
| `noc_bridge_test`       | AXI->APB bridge with PSLVERR injection (PSLVERR -> SLVERR) |

```csh
make sim TESTNAME=noc_concurrency_test            # run a test
make sim TESTNAME=noc_rr_arb_test COV=1           # + functional/code coverage
make smoke                                        # non-UVM datapath + OOO smoke
```

Arbitration correctness is checked cycle-accurately by the `arb_sva` assertions
(mutual-exclusion + strict-priority-honoured); AXI/APB protocol assertions are
embedded in `axi_if`/`apb_if`; data/routing/DECERR by the routing-aware scoreboard.

## Bug-detection demos (each caught by the env)
```csh
make sim TESTNAME=noc_bridge_test BUG=PSLVERR_SWALLOW   # scoreboard: SB_WRESP/SB_RRESP
make sim TESTNAME=noc_decode_test BUG=DECERR_OMIT       # watchdog: hang -> UVM_ERROR
make sim TESTNAME=noc_bridge_test BUG=BRESP_PERBEAT     # extra B responses
make smoke BUG=PSLVERR_SWALLOW                          # datapath smoke catches it too
```

## Known scope notes
- Single-master out-of-order multi-ID reads are proven by the `make smoke` `[OOO]`
  check; the UVM responders are in-order, so the UVM suite exercises cross-master
  contention, routing, bridge and decode rather than single-master OOO depth.
- Writes are one-outstanding per master (documented contract above).
- Statistical RR fairness (and `RR_FREEZE` detection) would need windowed grant
  measurement; the current build verifies arbitration via the SVA layer.

## Status
Built in phases (see `sim/README` history / plan). Phase 0 = skeleton + clean elaboration;
later phases add the datapath, full OOO, the UVM env, coverage, assertions, and the test list.
