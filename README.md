# Training-FE
A comprehensive training framework designed to onboard and upskill engineers in Front-End ASIC design and verification, with a focus on real-world project readiness and industry best practices.

---

# Ibex RISC-V Core — UVM Verification Environment
## A Complete CPU Verification Training Guide

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Structure](#2-repository-structure)
3. [Quick Start](#3-quick-start)
4. [Architecture of the Testbench](#4-architecture-of-the-testbench)
5. [The Ibex Core — What We Are Verifying](#5-the-ibex-core--what-we-are-verifying)
6. [Feature Verification Plan](#6-feature-verification-plan)
7. [Test Methodology — C, UVM, or Hybrid?](#7-test-methodology--c-uvm-or-hybrid)
8. [Coverage Strategy](#8-coverage-strategy)
9. [Engineer Training Roadmap](#9-engineer-training-roadmap)
10. [How to Add a New Test](#10-how-to-add-a-new-test)

---

## 1. Project Overview

This repository contains a complete UVM-based verification environment for the
[lowRISC Ibex](https://github.com/lowRISC/ibex) 32-bit RISC-V CPU core, targeting
Cadence Xcelium simulation. It is structured as a training platform to take an
engineer with IP-level UVM experience and build them into a CPU verification
engineer.

**Core configuration used:**

| Parameter | Value | Reason |
|---|---|---|
| RV32M | Fast | Multiply/divide enabled |
| RV32B | None | Bit-manip off (add later) |
| ICache | 0 | Start simple, enable for cache tests |
| SecureIbex | 0 | No lockstep — reduces complexity |
| WritebackStage | 0 | In-order, no writeback buffer |
| PMP | 0 | Disabled by default — enable per plan |

---

## 2. Repository Structure

```
Training-FE/
├── RTL/
│   └── ibex/               ← lowRISC ibex (git submodule)
├── sw/
│   ├── crt0.S              ← startup: clear BSS, set stack, call main
│   ├── link.ld             ← linker script: ROM@0x0, RAM@0x10000
│   ├── common/
│   │   └── uart_simple.h   ← UART write helper
│   ├── tests/
│   │   └── hello_world.c   ← first C test
│   └── Makefile            ← builds ELF, vmem, dis
├── tb/
│   ├── top/
│   │   ├── ibex_if.sv      ← SystemVerilog interface (all DUT signals)
│   │   └── tb_top.sv       ← top module: clock, memory model, DUT instance
│   ├── env/
│   │   ├── ibex_agent.sv
│   │   ├── ibex_driver.sv  ← drives reset and interrupts
│   │   ├── ibex_monitor.sv ← watches data bus for tohost
│   │   ├── ibex_scoreboard.sv
│   │   └── ibex_env.sv
│   └── tests/
│       ├── ibex_base_test.sv
│       └── ibex_pkg.sv     ← packages all TB classes
├── sim/
│   ├── Makefile            ← simulation targets: sim, waves, clean
│   ├── run.tcl             ← SimVision tcl (legacy)
│   └── runs/               ← auto-created per-run folders
│       └── run_YYYYMMDD_HHMMSS_seedN/
│           ├── xrun.log
│           ├── hello_world.vmem
│           ├── hello_world.dis
│           └── waves.shm/
└── filelist.f              ← Xcelium compile file list
```

---

## 3. Quick Start

### Prerequisites
- Cadence Xcelium with UVM (CDNS-1.2)
- RISC-V GCC toolchain (`riscv32-unknown-elf-gcc`)
- ibex submodule: `git submodule update --init --recursive`

### Clone and Run
```bash
git clone --recurse-submodules <repo-url>
cd Training-FE

# Basic simulation
cd sim && make sim

# With waveforms
make sim WAVES=1

# Fixed seed for reproducibility
make sim SEED=12345 WAVES=1
```

### Run Output
Each run creates:
```
runs/run_20260530_143022_seed483921/
  xrun.log          — full simulation log
  hello_world.vmem  — memory image used
  hello_world.dis   — disassembly for PC tracing
  waves.shm/        — waveforms (if WAVES=1)
```

### Check Result
```bash
grep -E "PASSED|FAILED" runs/run_*/xrun.log | tail -3
```

---

## 4. Architecture of the Testbench

### How the Tohost Monitor Works

The testbench uses the standard RISC-V test termination convention.
When software finishes it writes a value to a fixed memory address (`0x00010000`).
The testbench watches every data bus transaction and checks that address.

```
CPU executes store to 0x00010000
         │
         ▼
data_req=1, data_we=1, data_addr=0x10000, data_wdata=?
         │
         ▼
tb_top tohost monitor (always @posedge clk)
         │
   wdata==1 ──► TEST PASSED ──► $finish after 100ns
   wdata!=1 ──► TEST FAILED ──► $finish after 100ns
```

This means any C test only needs to write `1` to `0x00010000` at the end.
The UVM environment does not need to know the internals of what the software did.

### Memory Map
```
0x00000000 - 0x0000FFFF   64 KB  Instruction ROM  (code + rodata)
0x00010000 - 0x0003FFFF  192 KB  Data RAM         (stack + BSS + data)
0x00010000               4 B     tohost register  (end-of-test signal)
0x00020000               4 B     UART TX register (character output)
```

### Memory Model (tb_top.sv)
- Single byte-addressed array covers the entire memory map
- Instruction port: combinatorial grant, registered rvalid/rdata (1-cycle latency)
- Data port: same protocol, write-before-read ordering
- `$readmemh` loads the vmem into the byte array at simulation start

---

## 5. The Ibex Core — What We Are Verifying

Ibex is a 2-stage (or optional 3-stage with writeback) in-order 32-bit RISC-V core.

### Interrupt Lines — 19 Total
```
irq_software_i        MSIP  — software-triggered
irq_timer_i           MTIP  — timer compare match
irq_external_i        MEIP  — external interrupt controller
irq_fast_i[14:0]      15 fast local interrupts (mcause 16–30)
irq_nm_i              NMI   — non-maskable, highest priority
```

### Cache
```
ICache=0   No instruction cache (direct to prefetch buffer)
ICache=1   Instruction cache, configurable ways and lines
ICacheECC  ECC protection on cache RAMs (SEC-DED)
```
There is **no data cache**. All loads/stores go directly to the data bus.

### PMP
```
PMPEnable=1        Enable PMP hardware
PMPNumRegions=4    4 to 16 regions configurable
PMPGranularity=0   Minimum 4-byte granularity
```

---

## 6. Feature Verification Plan

---

### 6.1 Instruction Set Architecture

**Goal:** Every instruction in the supported extensions executes correctly.

| Extension | Instructions | Test Method |
|---|---|---|
| RV32I | ADD, SUB, AND, OR, XOR, shifts, branches, loads, stores, LUI, AUIPC, JAL, JALR | C + UVM |
| RV32M | MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU | C |
| RV32C | All 16-bit compressed encodings | C (compiler generates) |
| Zicsr | CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI | C |

**Key edge cases:**
```
DIV by zero     → quotient = 0xFFFFFFFF, remainder = dividend
Overflow DIV    → INT_MIN / -1 = INT_MIN (no exception in RISC-V)
MULH variants   → upper 32 bits of 64-bit product
LUI+ADDI        → sign extension of 12-bit immediate
x0 writes       → writes to x0 are silently discarded
```

---

### 6.2 Pipeline Behavior

**Goal:** Data hazards, control hazards, and stalls are handled correctly.

| Scenario | Description | Test Method |
|---|---|---|
| RAW hazard | Use result of previous instruction immediately | Directed ASM |
| Load-use hazard | Load then immediately use loaded value | Directed ASM |
| Branch taken | Pipeline flush after taken branch | C + waveform |
| Branch not taken | No flush, next instruction executes | C |
| Jump-and-link | Return address saved correctly | C function calls |
| Back-to-back branches | Two consecutive branch instructions | Directed ASM |
| Pipeline flush on exception | Exception in EX flushes IF | Exception test |

**RAW hazard test (assembly):**
```asm
addi t0, zero, 5
addi t1, t0, 3    # uses t0 immediately — forwarding must work
# verify t1 == 8
```

---

### 6.3 Memory Bus Protocol (OBI)

**Goal:** The instruction and data bus follow the OBI protocol correctly under
all conditions including back-pressure, wait states, and outstanding transactions.

| Test | What to vary | Method |
|---|---|---|
| Zero wait state | gnt same cycle as req | Current TB |
| Wait states | gnt delayed N cycles | UVM driver |
| Back-pressure | gnt=0 for many cycles | UVM sequence |
| rvalid delay | rvalid delayed beyond gnt | UVM driver |
| Byte read | lbu, lhu instructions | C |
| Byte write | sb, sh instructions | C |
| Word read/write | lw, sw | C |

**UVM back-pressure driver example:**
```systemverilog
task drive_back_pressure();
  repeat ($urandom_range(0, 10)) begin
    vif.data_gnt <= 1'b0;
    @(posedge vif.clk);
  end
  vif.data_gnt <= 1'b1;
endtask
```

---

### 6.4 Interrupts

**Goal:** All 19 interrupt lines cause correct trap entry, handler execution,
and return. CSR state is correct before and after.

| Test | What to check |
|---|---|
| Interrupt while executing | mepc points to interrupted instruction |
| Interrupt disabled (mie=0) | Interrupt is not taken |
| Interrupt enabled (mie=1) | Interrupt taken within bounded latency |
| MRET instruction | Returns to mepc, restores mstatus.MIE |
| mcause value | Correct interrupt cause code written |
| mtval value | Zero for interrupts |
| All 15 fast interrupt lines | Each tested independently |
| NMI | Fires even with mstatus.MIE=0 |
| Interrupt latency | Cycles from assertion to handler measured |
| Spurious rejection | Deasserted before taken — must not trigger |

**mcause values for interrupts:**
```
0x80000003  software interrupt
0x80000007  timer interrupt
0x8000000B  external interrupt
0x80000010  fast irq 0
0x8000001E  fast irq 14
```

---

### 6.5 Exceptions and Traps

**Goal:** Every exception cause is generated, trapped, and reported correctly
in mcause, mepc, and mtval.

| Exception | How to trigger | mcause | mtval |
|---|---|---|---|
| Instruction access fault | Fetch from denied PMP region | 1 | Fault PC |
| Illegal instruction | Undefined opcode (.word 0x0) | 2 | Instruction word |
| Breakpoint | EBREAK instruction | 3 | 0 |
| Load address misalign | lw at odd address | 4 | Bad address |
| Load access fault | Load from PMP-denied region | 5 | Fault address |
| Store address misalign | sw at odd address | 6 | Bad address |
| Store access fault | Store to PMP-denied region | 7 | Fault address |
| Environment call | ECALL instruction | 11 | 0 |

**Triggering illegal instruction from C:**
```c
asm volatile(".word 0x00000000");  // handler must catch this
```

---

### 6.6 CSR Verification

**Goal:** Every CSR accessible in M-mode reads and writes correctly.

| CSR | Address | What to verify |
|---|---|---|
| mstatus | 0x300 | MIE, MPIE, MPP bits |
| misa | 0x301 | Reports RV32IMC |
| mie | 0x304 | Per-interrupt enable bits |
| mtvec | 0x305 | BASE and MODE fields |
| mscratch | 0x340 | Read/write any value |
| mepc | 0x341 | Written on trap, read by MRET |
| mcause | 0x342 | Interrupt bit + cause code |
| mtval | 0x343 | Exception-specific info |
| mip | 0x344 | Read-only, reflects pending interrupts |
| mcycle | 0xB00 | Increments every cycle |
| minstret | 0xB02 | Increments every retired instruction |
| mhpmcounter3-31 | 0xB03+ | Configurable performance counters |
| pmpcfg0-3 | 0x3A0+ | PMP config registers |
| pmpaddr0-15 | 0x3B0+ | PMP address registers |

**Test method:** Pure C — write known value, read back, compare.
Check WARL fields do not accept illegal values.

---

### 6.7 Physical Memory Protection (PMP)

**Enable PMP in TB:**
```systemverilog
ibex_top #(
  .PMPEnable     (1'b1),
  .PMPNumRegions (4),
  .PMPGranularity(0)
  ...
```

**Address matching modes:**
```
TOR   — region spans from previous pmpaddr to this pmpaddr
NA4   — naturally aligned 4-byte region
NAPOT — naturally aligned power-of-two region
        pmpaddr = base | ((size/2) - 1)
        1KB region example: pmpaddr = base | 0x1FF
```

**Verification levels:**

| Level | What to test | Method |
|---|---|---|
| L1 Basic | Single region R/W/X permission bits | C |
| L2 Boundary | Access at last legal byte vs first illegal byte | C |
| L3 Multi-region | Overlapping regions — lower number wins | C |
| L4 Locked | L-bit set — M-mode cannot reconfigure | C |
| L5 Execute | Mark RAM non-executable, jump to it → fault | C |
| L6 All 16 regions | PMPNumRegions=16, all tested independently | C |
| L7 Granularity | PMPGranularity=10 (4KB pages), sub-granularity masking | C |

---

### 6.8 Instruction Cache (ICache)

**Enable ICache:**
```systemverilog
.ICache   (1'b1),
.ICacheECC(1'b1),
```

| Test | Description | Method |
|---|---|---|
| Cold miss | First fetch always misses | Waveform |
| Hot hit | Second fetch of same line hits | Cycle count |
| Loop performance | Measure cycles with/without cache | C benchmark |
| Cache line boundary | Branch target spans two cache lines | Directed C |
| ECC single-bit correction | 1-bit error → corrected, alert_minor fires | UVM force |
| ECC double-bit detection | 2-bit error → alert_major fires | UVM force |
| Scramble key rotation | ICacheScramble=1, rotate key | UVM sequence |

**Performance test:**
```c
uint32_t t0 = read_csr(mcycle);
for (int i = 0; i < 1000; i++) { asm("nop"); }
uint32_t cycles_no_cache = read_csr(mcycle) - t0;
// enable cache, repeat, compare
```

---

### 6.9 Debug Interface

| Test | What to check |
|---|---|
| Halt request | Assert debug_req_i, CPU stops fetching |
| Halt in any stage | Halt while in IF, ID, EX |
| Single step | DCSR.step=1, one instruction per resume |
| Register read | All 32 GPRs readable in debug mode |
| Resume | CPU resumes from dpc |
| Breakpoint | tdata1/tdata2 configured, address hit → halt |
| Interrupt while halted | Taken after resume |

**Test method:** UVM controls `debug_req_i`. Full debug requires a Debug
Module UVM agent — advanced topic.

---

### 6.10 Power Management

| Test | Method |
|---|---|
| WFI instruction | Execute WFI, verify core_sleep_o asserts |
| Wakeup from interrupt | Assert any interrupt, verify core wakes |
| Wakeup latency | Cycles from interrupt assertion to first fetch |
| Sleep with pending interrupt | Interrupt before WFI — immediate wakeup |

```c
asm volatile("wfi");
// reaching here means wakeup succeeded
```

---

### 6.11 Security Features (SecureIbex=1)

| Feature | What it does | How to verify |
|---|---|---|
| Lockstep | Shadow core runs N cycles behind, compares outputs | Inject mismatch → alert fires |
| Dummy instructions | Random NOP-like instructions inserted | Verify they don't change register state |
| Register file ECC | ECC on all 32 registers | Inject bit flip → alert fires |
| alert_minor_o | Correctable error detected | Fire and check |
| alert_major_internal_o | Uncorrectable internal error | Fire and check |
| alert_major_bus_o | Bus integrity error | Fire and check |

---

## 7. Test Methodology — C, UVM, or Hybrid?

This is the most important concept for CPU verification engineers to understand.
Each method has a specific role.

---

### Pure C Test

**What it is:** A bare-metal C program compiled for the CPU and loaded into
simulation memory. The CPU executes it like real firmware.

**When to use:**
- ISA correctness (arithmetic, loads, stores)
- CSR read/write
- Exception handler correctness
- PMP configuration and access
- Cache performance measurement

**Advantages:**
- Closest to real software — catches real integration bugs
- Reusable on actual silicon and FPGA
- Low barrier — engineers write normal C

**Disadvantages:**
- Cannot control the environment (bus delays, interrupt timing)
- Cannot inject errors from outside the CPU

---

### Pure UVM Sequence

**What it is:** A UVM sequence drives bus signals directly. Used to verify the
bus interface, not the ISA.

**When to use:**
- OBI bus protocol compliance
- Back-pressure and wait-state scenarios
- Error injection on the bus
- Verifying the bus interface in isolation

**Advantages:**
- Full control of timing, back-pressure, error injection
- Can create conditions software cannot produce

**Disadvantages:**
- Does not exercise the actual CPU pipeline
- Cannot test anything requiring instruction execution

---

### C + UVM Hybrid — The Most Powerful Method

**What it is:** C software runs on the CPU while UVM sequences control the
environment simultaneously. Each does what it does best.

**When to use:**
- Interrupt timing tests
- Cache ECC injection
- PMP fault verification with bus-level checking
- Security fault injection
- Debug halt/resume

**How the synchronisation works:**
```
C writes a sync flag to a known address
        │
UVM monitor sees the flag on the data bus
        │
UVM sequence fires the stimulus (interrupt / error inject)
        │
C handler runs, writes result to tohost
        │
UVM scoreboard checks tohost value + timing
```

---

### Decision Matrix

| Feature | C Test | UVM Seq | Hybrid |
|---|---|---|---|
| ISA arithmetic | ✅ Primary | | |
| CSR read/write | ✅ Primary | | |
| Exception handlers | ✅ Primary | | |
| PMP configuration | ✅ Primary | | |
| OBI bus protocol | | ✅ Primary | |
| Bus back-pressure | | ✅ Primary | |
| Bus error injection | | ✅ Primary | |
| Interrupt timing | | | ✅ Primary |
| Interrupt latency | | | ✅ Primary |
| Cache ECC injection | | | ✅ Primary |
| PMP fault + bus check | | | ✅ Primary |
| Security fault injection | | | ✅ Primary |
| Debug halt/resume | | | ✅ Primary |
| WFI wakeup latency | | | ✅ Primary |

---

## 8. Coverage Strategy

### Functional Coverage

Define covergroups in UVM for every feature:

```systemverilog
covergroup interrupt_cg;
  cp_source: coverpoint irq_source {
    bins software = {IRQ_SOFTWARE};
    bins timer    = {IRQ_TIMER};
    bins external = {IRQ_EXTERNAL};
    bins fast[]   = {[IRQ_FAST_0:IRQ_FAST_14]};
    bins nmi      = {IRQ_NMI};
  }
  cp_mie_state: coverpoint mie_enabled {
    bins enabled  = {1};
    bins disabled = {0};
  }
  cx_irq_when_disabled: cross cp_source, cp_mie_state;
endgroup
```

### Code Coverage Targets

| Type | Target |
|---|---|
| Line coverage | 95%+ |
| Branch coverage | 90%+ |
| Toggle coverage | 85%+ |
| FSM state coverage | 100% |
| Assertion coverage | All assertions exercised |

Enable in Xcelium with `-coverage all` in `XRUN_OPTS`.

### Assertion Coverage

Every `ASSERT` in the ibex RTL should fire at least once in regression.
The ibex RTL contains assertions for:
- Bus protocol correctness
- Pipeline state machine transitions
- PMP address matching logic
- Cache line state transitions

---

## 9. Engineer Training Roadmap

This plan takes an engineer from IP-level UVM to full CPU verification.
Each phase builds on the previous. Estimated time: 1–2 weeks per phase.

---

### Phase 1 — Understand the DUT (Week 1)

**Goal:** Read the spec before touching any code.

- Read the [Ibex documentation](https://ibex-core.readthedocs.io)
- Understand the 2-stage pipeline (IF → ID/EX)
- Draw the data path from fetch to writeback on paper
- Understand the OBI bus protocol (req/gnt/rvalid/rdata)
- Read `ibex_top.sv` — know every port and why it exists
- Read `ibex_pkg.sv` — understand all parameter combinations

**Deliverable:** One-page architecture summary written by the engineer.

---

### Phase 2 — Run the Existing TB (Week 1–2)

**Goal:** Get comfortable with the simulation environment.

- Clone repo, run `make sim`, see TEST PASSED
- Run with `WAVES=1`, open waveform in SimVision
- Find in waveform: `clk`, `rst_n`, `instr_req`, `instr_addr`, `data_req`, `data_addr`, `data_wdata`
- Trace `hello_world` execution in the `.dis` file against the waveform
- Follow PC from reset vector (0x0) → `main` → tohost write
- Read the UVM log and understand every line

**Deliverable:** Waveform screenshot annotated with the execution flow.

---

### Phase 3 — Write a New C Test (Week 2)

**Goal:** Add a second C test independently.

- Write `sw/tests/isa_arithmetic.c` — test ADD, SUB, AND, OR, XOR
- Each operation verifies a known result
- If all correct, write tohost=1; else write tohost=2
- Build and run: `make sim TEST=isa_arithmetic`
- Trace any failure using the `.dis` disassembly

**Deliverable:** New C test passing in simulation.

---

### Phase 4 — OBI Bus Protocol (Week 3)

**Goal:** Understand and verify the instruction and data bus interfaces.

- Modify the UVM driver to add random wait states on `instr_gnt`
- Verify the CPU correctly holds `req=1` until `gnt=1`
- Add wait states on `data_gnt` during a store instruction
- Write a scoreboard check: every `req=1` must eventually get `gnt=1`

**Deliverable:** UVM driver with configurable wait state injection.

---

### Phase 5 — Exception Handling (Week 4)

**Goal:** Every exception cause generates the correct trap.

- Write `sw/tests/exception_test.c`
- Install a trap handler at `mtvec`
- Trigger each exception type (illegal instruction, ecall, misaligned)
- In the handler, read and verify mcause, mepc, mtval
- Cover at least 5 exception types

**Deliverable:** Exception test covering all standard exception types.

---

### Phase 6 — Interrupt Handling (Week 5)

**Goal:** All 19 interrupt lines cause correct handler entry and return.

- Write `sw/tests/interrupt_test.c` with mtvec handler
- Enable timer interrupt in mie
- UVM sequence asserts `irq_timer_i` at a specific cycle
- Verify handler fires, reads correct mcause
- Verify MRET restores execution at mepc
- Extend to all 15 fast interrupt lines

**Deliverable:** Hybrid interrupt test — UVM sequence + C handler cooperating.

---

### Phase 7 — PMP (Week 6)

**Goal:** PMP enforces permissions and fires correct exceptions.

- Enable `PMPEnable=1` in tb_top.sv
- Write `sw/tests/pmp_test.c`
- Configure NAPOT region as read-only
- Attempt a write — verify store access fault (mcause=7)
- Test boundary conditions
- Test locked regions

**Deliverable:** PMP test covering all three address modes and all permission bits.

---

### Phase 8 — ICache (Week 7)

**Goal:** Cache improves performance and ECC protects data integrity.

- Enable `ICache=1, ICacheECC=1` in tb_top.sv
- Write a loop benchmark — measure cycles with/without cache
- Use `$deposit` to inject a bit error into cache RAM
- Verify `alert_minor_o` fires for correctable error
- Verify `alert_major_internal_o` fires for uncorrectable error

**Deliverable:** Cache performance benchmark + ECC fault injection test.

---

### Phase 9 — Coverage Closure (Week 8)

**Goal:** Understand coverage-driven verification.

- Add functional covergroups for interrupts and exceptions
- Run constrained random interrupt sequences
- Identify coverage holes from the coverage report
- Write directed tests to close specific holes
- Run with `-coverage all`, target >90% functional coverage

**Deliverable:** Coverage report with >90% functional coverage on interrupts.

---

### Phase 10 — Advanced: Security and Debug (Week 9–10)

**Goal:** Verify security hardening and debug infrastructure.

- Enable `SecureIbex=1` — understand lockstep concept
- Inject mismatch between main and shadow core — verify alert fires
- Implement a simple Debug Module UVM agent
- Exercise halt, single-step, register read in debug mode
- Verify minstret increments correctly per retired instruction

**Deliverable:** Security fault injection test + debug halt/resume test.

---

## 10. How to Add a New Test

### Step 1 — Write the C Test

Create `sw/tests/<test_name>.c`:
```c
#include "../common/uart_simple.h"

int main(void) {
  int pass = 1;

  // test logic
  if (5 + 3 != 8) pass = 0;

  volatile unsigned int *tohost = (volatile unsigned int *)0x00010000;
  *tohost = pass ? 1 : 2;
  return 0;
}
```

### Step 2 — Build and Run
```bash
cd sim
make sim TEST=<test_name>
```

### Step 3 — Add a UVM Test Class (optional)

Create `tb/tests/<test_name>_test.sv`:
```systemverilog
class <test_name>_test extends ibex_base_test;
  `uvm_component_utils(<test_name>_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    // start your sequence here
    #2ms;
    phase.drop_objection(this);
  endtask
endclass
```

Add to `tb/tests/ibex_pkg.sv`:
```systemverilog
`include "tb/tests/<test_name>_test.sv"
```

Run:
```bash
make sim TEST=<test_name> TEST_NAME=<test_name>_test
```

### Step 4 — Debug a Failure

```bash
# find the failing PC in the log
grep "Illegal\|FAILED\|Error" runs/run_xxx/xrun.log

# look up that PC in the disassembly
grep "0x0000004" runs/run_xxx/hello_world.dis

# open waveform at that time
# SimVision: File → Open → runs/run_xxx/waves.shm
```

---

## Simulation Commands Reference

```bash
# from sim/ directory

make sim                          # run hello_world, no waves
make sim WAVES=1                  # run with waveform dump
make sim SEED=42                  # fixed seed
make sim TEST=isa_arithmetic      # different C test
make sim TEST_NAME=irq_test       # different UVM test class
make sim WAVES=1 SEED=42 TEST=pmp_test  # everything combined
make clean                        # remove all build artefacts and run folders
```

---

*This environment is designed as a living training platform.
Each phase adds a new test, a new feature, and a new skill.
The goal is not to finish quickly — it is to understand deeply.*
