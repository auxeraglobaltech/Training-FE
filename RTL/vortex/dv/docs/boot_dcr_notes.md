# Vortex single-core boot / DCR / memory notes (Phase 1 reference)

Extracted from `sim/rtlsim/{main.cpp,processor.cpp,rtlsim_shim.sv}` and the
generated `build/hw/{VX_config.vh,VX_types.vh}` at pinned commit
`b70e0d56ad1f09ce5dfb0a1c6cc2b4016ba04663`. This is the contract the SV/UVM
testbench (dcr agent, mem responder, ctrl monitor, scoreboard) implements.

## Frozen config (default `configure --xlen=32` output — already 1-core)
| Param | Value |
|---|---|
| `VX_CFG_NUM_CLUSTERS` / `NUM_CORES` | 1 / 1 |
| `VX_CFG_NUM_WARPS` / `NUM_THREADS` | 4 / 4 |
| `VX_CFG_RESET_DELAY` | 8 cycles |
| `VX_CFG_PLATFORM_MEMORY_ADDR_WIDTH` | 32 (XLEN=32) |
| `VX_CFG_PLATFORM_MEMORY_DATA_SIZE` | 64 bytes per beat (512-bit) |
| DCR bus | 12-bit addr, 32-bit data |

## Reset sequence (processor.cpp `reset()`)
1. `start=0`, all `mem_req_ready[b]=0`, `mem_rsp_valid[b]=0`, `dcr_req_valid=0`.
2. `reset=1` for `VX_CFG_RESET_DELAY` (8) clock cycles.
3. `reset=0`, pump 8 more cycles to settle.
4. Then drive `mem_req_ready[b]=1` (responder always-ready is fine).

## Boot DCR programming (main.cpp — write BEFORE loading + start)
All via single-cycle DCR writes: assert `dcr_req_valid=1, dcr_req_rw=1, addr, data`
for one clk, then deassert one cycle. Addresses from VX_types.vh:

| DCR reg | Addr | Boot value |
|---|---|---|
| `VX_DCR_KMU_STARTUP_ADDR0` | 12'h010 | 0x8000_0000 (flat .bin/.hex) or ELF entry |
| `VX_DCR_KMU_STARTUP_ADDR1` | 12'h011 | (XLEN=64 only) |
| `VX_DCR_KMU_KERNEL_ENTRY0/1` | 12'h012/013 | (not written at boot) |
| `VX_DCR_KMU_STARTUP_ARG0/1` | 12'h014/015 | 0 / 0 |
| `VX_DCR_KMU_BLOCK_DIM_X/Y/Z` | 12'h016/017/018 | 1 / 1 / 1 |
| `VX_DCR_KMU_GRID_DIM_X/Y/Z` | 12'h019/01A/01B | 1 / 1 / 1 |
| `VX_DCR_KMU_LMEM_SIZE` | 12'h01C | 0 |
| `VX_DCR_KMU_BLOCK_SIZE` | 12'h01D | 1 |
| `VX_DCR_KMU_WARP_STEP_X` | 12'h01E | `VX_CFG_NUM_THREADS` (=4) |
| `VX_DCR_KMU_WARP_STEP_Y/Z` | 12'h01F/020 | 0 / 0 |
| `VX_DCR_KMU_CLUSTER_DIM_X/Y/Z` | 12'h021/022/023 | 1 / 1 / 1 |

DCR read: `dcr_req_valid=1, rw=0, addr, data=<tag>` one cycle; wait
`dcr_rsp_valid`, capture `dcr_rsp_data`.

## Run / completion (processor.cpp `run()`)
1. Pulse `start=1` for exactly one cycle.
2. Wait for `busy` to rise, then wait for `busy==0`. **Caution:** `busy` is
   discontinuous across KMU launch phases — completion must be defined as
   `busy` low **stable for >=100 consecutive cycles** (a single rise/fall wait
   false-passes with zero fetches).
3. Post-run: flush caches — one DCR **read** of `VX_DCR_BASE_CACHE_FLUSH`
   (12'h000) per core, tag = core id.
4. Exit code: 4-byte word at memory `VX_MEM_IO_EXIT_CODE` = **33608 (0x8348)**.
   **0 = PASS** (simx returns this word's low byte as its process rc, so any
   non-zero "pass magic" breaks co-sim). (ELF/HTIF path instead watches the
   `tohost` symbol.)
5. DV addition (this env's crt0/nop contract): done flag **0x600DC0DE at
   0x8350** — proves the kernel actually executed, since unwritten memory
   reads back 0 (indistinguishable from a passing exit code). Scoreboard also
   requires n_rd > 0.

## Memory responder protocol (per bank b)
- Request accepted when `mem_req_valid[b] && mem_req_ready[b]`.
- Byte address (non-interleaved, `VX_CFG_PLATFORM_MEMORY_INTERLEAVE==0`):
  `(mem_req_addr[b] + (b << (ADDR_WIDTH - log2(NUM_BANKS)))) * DATA_SIZE`
  Interleaved (==1): `(mem_req_addr[b]*NUM_BANKS + b) * DATA_SIZE`.
- Write: apply `mem_req_data` bytes masked by 64-bit `mem_req_byteen`; no rsp.
- Read: return full 64-byte line with same `mem_req_tag` on
  `mem_rsp_valid/data/tag`; hold until `mem_rsp_ready[b]`.
- Out-of-order response is legal (tag matches); upstream adds DRAM latency —
  our responder can use fixed/random latency knob.

## Program image
- `.bin` loaded flat at 0x8000_0000; `.hex` self-addressed; ELF via loader
  (entry from header). For the TB: readmemh-style hex + base addr is easiest.
- Console output ring (`vx_printf`) lives at `VX_MEM_IO_COUT_ADDR` (64),
  size 33536 — a kernel that prints will hang unless the ring is drained;
  first kernels should avoid printing.
