#!/bin/bash
# Run every C test in sw/tests/ once and print one result line per test.
# Run from sim/ after sourcing the Cadence environment:
#   cd sim && source ~/.cadence_env.bash && ./test.sh
#
# Most tests run with ibex_base_test. Tests that talk to SV need the SV
# test class that implements their commands:
#   c_sv_handshake  -> ibex_c_sv_sync_test
#   irq_csv_*       -> ibex_irq_csv_test
for f in ../sw/tests/*.c; do
  T=$(basename $f .c)
  case $T in
    c_sv_handshake) N=ibex_c_sv_sync_test ;;
    irq_csv_*)      N=ibex_irq_csv_test ;;
    *)              N=ibex_base_test ;;
  esac
  make sim TEST=$T TEST_NAME=$N SEED=1 > /dev/null 2>&1
  printf "%-22s %s\n" $T "$(grep -h '\[SB\] TEST' ../runs/$(ls -t ../runs | head -1)/xrun.log | sed 's/.*\[SB\] //')"
done
