for f in ../sw/tests/*.c; do
  T=$(basename $f .c); N=ibex_base_test
  [ $T = c_sv_handshake ] && N=ibex_c_sv_sync_test
  make sim TEST=$T TEST_NAME=$N SEED=1 > /dev/null 2>&1
  printf "%-22s %s\n" $T "$(grep -h '\[SB\] TEST' ../runs/$(ls -t ../runs | head -1)/xrun.log | sed 's/.*\[SB\] //')"
done
