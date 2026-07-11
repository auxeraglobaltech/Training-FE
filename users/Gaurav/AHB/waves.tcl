set test_name $env(TEST)
set out_dir   $env(OUT_DIR)

database -open waves \
         -shm \
         -into ${out_dir}/waves.shm

probe -create -all -depth all

run

exit
