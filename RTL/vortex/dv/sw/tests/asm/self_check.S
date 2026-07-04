# riscv-tests-style self-checking micro-test (rv32im):
# ALU / shift / mul / div / load-store checks. Uses the common crt0
# (returns from main; a0 = 0 pass, else 1-based failing check number).

.section .text
.global main
main:
  li   a0, 1                    # check id

  # --- add/sub ---
  li   t0, 1234
  li   t1, 4321
  add  t2, t0, t1
  li   t3, 5555
  bne  t2, t3, fail
  addi a0, a0, 1
  sub  t2, t1, t0
  li   t3, 3087
  bne  t2, t3, fail
  addi a0, a0, 1

  # --- logic ---
  li   t0, 0xF0F0F0F0
  li   t1, 0x0FF00FF0
  and  t2, t0, t1
  li   t3, 0x00F000F0
  bne  t2, t3, fail
  addi a0, a0, 1
  xor  t2, t0, t1
  li   t3, 0xFF00FF00
  bne  t2, t3, fail
  addi a0, a0, 1

  # --- shifts ---
  li   t0, 0x80000000
  srai t2, t0, 4
  li   t3, 0xF8000000
  bne  t2, t3, fail
  addi a0, a0, 1
  srli t2, t0, 4
  li   t3, 0x08000000
  bne  t2, t3, fail
  addi a0, a0, 1

  # --- slt ---
  li   t0, -5
  li   t1, 3
  slt  t2, t0, t1
  bne  t2, x0, 1f
  j    fail
1:sltu t2, t0, t1               # unsigned: 0xFFFFFFFB > 3
  bne  t2, x0, fail
  addi a0, a0, 1

  # --- mul/div (M ext) ---
  li   t0, 123
  li   t1, 456
  mul  t2, t0, t1
  li   t3, 56088
  bne  t2, t3, fail
  addi a0, a0, 1
  li   t0, 56088
  li   t1, 456
  divu t2, t0, t1
  li   t3, 123
  bne  t2, t3, fail
  addi a0, a0, 1
  remu t2, t0, t1
  bne  t2, x0, fail
  addi a0, a0, 1

  # --- load/store (word/half/byte) ---
  la   t0, scratch
  li   t1, 0xDEADBEEF
  sw   t1, 0(t0)
  lw   t2, 0(t0)
  bne  t2, t1, fail
  addi a0, a0, 1
  lhu  t2, 0(t0)
  li   t3, 0xBEEF
  bne  t2, t3, fail
  addi a0, a0, 1
  lb   t2, 3(t0)                # 0xDE sign-extended
  li   t3, 0xFFFFFFDE
  bne  t2, t3, fail

  li   a0, 0                    # all checks passed
  ret
fail:
  ret                           # a0 = failing check id

.section .data
.align 4
scratch: .word 0
