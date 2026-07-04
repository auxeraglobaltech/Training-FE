# Warp/thread parallelism micro-test:
#  1. tmc -1: activate all NUM_THREADS threads of warp 0; each thread writes
#     (0xA0 + tid) to slot[tid]; tmc 1 back to single-thread.
#  2. wspawn NUM_WARPS at warp_entry: each spawned warp (1 thread) writes
#     (0xB0 + wid) to wslot[wid] and retires; warp 0 polls until all present.
# main returns 0 on success (crt0 publishes the PASS magic).

#define NUM_THREADS 4
#define SLOTS       0x80030000
#define WSLOTS      0x80030100

.section .text
.global main
main:
  # ---- thread divergence within warp 0 ----
  li   t0, -1
  .insn r 0x0B, 0, 0, x0, t0, x0      # tmc -1 (all threads on)
  csrr t1, 0xCC0                      # VX_CSR_THREAD_ID
  li   t2, SLOTS
  slli t3, t1, 2
  add  t2, t2, t3
  addi t3, t1, 0xA0
  sw   t3, 0(t2)
  li   t0, 1
  .insn r 0x0B, 0, 0, x0, t0, x0      # tmc 1 (back to thread 0 only)

  # check thread slots
  li   t2, SLOTS
  li   t4, 0                          # tid iter
1:li   t5, NUM_THREADS
  bgeu t4, t5, 2f
  slli t3, t4, 2
  add  t3, t2, t3
  lw   t5, 0(t3)
  addi t6, t4, 0xA0
  bne  t5, t6, fail_threads
  addi t4, t4, 1
  j    1b
2:

  # ---- warp spawn ----
  csrr t0, 0xFC1                      # VX_CSR_NUM_WARPS
  la   t1, warp_entry
  .insn r 0x0B, 1, 0, x0, t0, t1      # wspawn t0 warps @ warp_entry

  # poll until warps 1..NUM_WARPS-1 have reported
  li   t2, WSLOTS
  li   t4, 1
3:csrr t5, 0xFC1
  bgeu t4, t5, done
  slli t3, t4, 2
  add  t3, t2, t3
  lw   t6, 0(t3)
  addi a1, t4, 0xB0
  bne  t6, a1, 3b                     # not yet: keep polling
  addi t4, t4, 1
  j    3b

done:
  li   a0, 0
  ret
fail_threads:
  li   a0, 1
  ret

# spawned warps land here (warp 0 also, but wspawn skips warp 0)
warp_entry:
  csrr t0, 0xCC1                      # VX_CSR_WARP_ID
  li   t1, WSLOTS
  slli t2, t0, 2
  add  t1, t1, t2
  addi t2, t0, 0xB0
  sw   t2, 0(t1)
  .insn r 0x0B, 7, 0, x0, x0, x0      # wsync
  .insn r 0x0B, 0, 0, x0, x0, x0      # tmc x0 (retire spawned warp)
