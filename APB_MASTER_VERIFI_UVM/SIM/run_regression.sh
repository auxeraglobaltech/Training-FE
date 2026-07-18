#!/bin/bash

echo "======================================="
echo "      APB MASTER REGRESSION"
echo "======================================="

# Clean previous results
rm -rf results/apb_write_test/*
rm -rf results/apb_idle_test/*

########################################
# WRITE TEST
########################################

echo ""
echo "Running APB WRITE TEST..."
echo ""

xrun -uvm -sv -access +rwc \
-f ../TB_UVM_APB/filelist.f \
+UVM_TESTNAME=apb_write_test

mv wave.shm results/apb_write_test/
mv xcelium.d results/apb_write_test/
mv xrun.log results/apb_write_test/
mv xrun.history results/apb_write_test/

########################################
# IDLE TEST
########################################

echo ""
echo "Running APB IDLE TEST..."
echo ""

xrun -uvm -sv -access +rwc \
-f ../TB_UVM_APB/filelist.f \
+UVM_TESTNAME=apb_idle_test

mv wave.shm results/apb_idle_test/
mv xcelium.d results/apb_idle_test/
mv xrun.log results/apb_idle_test/
mv xrun.history results/apb_idle_test/

echo ""
echo "======================================="
echo "Regression Completed Successfully"
echo "======================================="
