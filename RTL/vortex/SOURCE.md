# Vendored source: Vortex GPGPU

- Upstream: https://github.com/vortexgpgpu/vortex
- Pinned commit: `b70e0d56ad1f09ce5dfb0a1c6cc2b4016ba04663` (v3.0 line)
- License: Apache-2.0 (see LICENSE)

Local additions (not upstream):
- `dv/` — our Xcelium/UVM verification project (shims, TB, sw tests, docs)
- `build/` — generated configure output (frozen 1-cluster × 1-core, XLEN=32)
- `SOURCE.md` — this file

Upstream files are unmodified; all Xcelium portability fixes live as shadow
copies in `dv/shim/` (see `dv/sim/filelist_vx.f`).

Vendoring notes (what is NOT in this snapshot — see `.gitignore`):
- all `.git` metadata removed (top repo + submodules); `.gitmodules` kept as a
  record of submodule URLs. To rebuild simx deps: `make -C third_party
  softfloat ramulator` (ramulator refetches its ext/ deps via CMake).
- build artifacts: `build/` (regenerate with `./configure --xlen=32`),
  `dv/xcelium.d`, ramulator `build/`+`ext/`, compiled kernels (`make -C dv/sw`).
- heavy upstream payloads unused by the 1-core DV env: 28nm ASIC cell
  libraries (`hw/syn/libs/cln28hp{m,c}`), OpenCL/graphics/vulkan test suites.

Toolchain (LLVM-vortex, riscv32-gnu, libc32/libcrt32) is installed outside
the repo at `/home/user1/vortex/` (prebuilt v3.0, ubuntu/focal binaries;
`/home/user1/vortex/lib/libstdc++.so.6` shim for RHEL9).
