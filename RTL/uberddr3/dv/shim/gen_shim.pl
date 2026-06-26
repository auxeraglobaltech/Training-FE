#!/usr/bin/perl
# ============================================================================
#  gen_shim.pl — regenerate dv/shim/ddr3_controller.sv from the pristine
#  upstream rtl/ddr3_controller.v with the minimal Xcelium-compatibility edits.
#
#  Run from RTL/uberddr3:  perl dv/shim/gen_shim.pl
#
#  Two classes of edit (upstream tolerated by iverilog -g2012 / Vivado --relax,
#  but rejected by Xcelium's strict IEEE-1364 constant-function rules):
#   (1) 5 time-conversion exprs inside constant functions used $rtoi($ceil(..)):
#       replaced by exact integer ceil-division (a+b-1)/b  (or nCK*P).
#   (2) get_slot() referenced localparams (CL_nCK, CWL_nCK, tRCD) defined AFTER
#       its call site (forward param refs — illegal in a constant function).
#       Replaced by locals computed in-function from top-level params and the
#       (forward-OK) CL_generator/CWL_generator functions. Values are identical.
# ============================================================================
use strict; use warnings;
local $/; my $f = <STDIN>;

# (1) $rtoi($ceil(...)) -> integer ceil-division
$f =~ s/\$rtoi\(\s*\$ceil\(\s*ps\*1\.0\/CONTROLLER_CLK_PERIOD\s*\)\s*\)/((ps + CONTROLLER_CLK_PERIOD - 1)\/CONTROLLER_CLK_PERIOD)/g;
$f =~ s/\$rtoi\(\s*\$ceil\(\s*nCK\*1\.0\/serdes_ratio\s*\)\s*\)/((nCK + serdes_ratio - 1)\/serdes_ratio)/g;
$f =~ s/\$rtoi\(\s*\$ceil\(\s*ps\*1\.0\/\s*DDR3_CLK_PERIOD\s*\)\s*\)/((ps + DDR3_CLK_PERIOD - 1)\/DDR3_CLK_PERIOD)/g;
$f =~ s/\$rtoi\(\s*\$ceil\(\s*nCK\*1\.0\*DDR3_CLK_PERIOD\s*\)\s*\)/((nCK*DDR3_CLK_PERIOD))/g;
$f =~ s/\$rtoi\(\s*\$ceil\(\s*tRCD\*1\.0\/\s*DDR3_CLK_PERIOD\s*\)\s*\)/((tRCD + DDR3_CLK_PERIOD - 1)\/DDR3_CLK_PERIOD)/g;

# (2) scope a transform to the get_slot function body only
$f =~ s/(function\[1:0\]\s+get_slot\s.*?endfunction)/fix_get_slot($1)/se;

sub fix_get_slot {
    my $g = shift;
    # declare locals before the function's first 'begin', and initialise them
    my $decl = "integer cl_nck, cwl_nck, trcd;";
    my $init = "cl_nck = DLL_OFF? 4'd5 : CL_generator(DDR3_CLK_PERIOD);\n"
             . "            cwl_nck = DLL_OFF? 4'd6 : CWL_generator(DDR3_CLK_PERIOD);\n"
             . "            trcd = (SPEED_BIN==0)? TRCD : (SPEED_BIN==1)? 13750 : (SPEED_BIN==2)? 13500 : 13750;";
    $g =~ s/(reg\[2:0\]\s+remaining_slot;\s*\n)(\s*)begin/$1$2$decl\n$2begin\n            $init/;
    # replace the forward-referenced module localparams with the in-function locals
    $g =~ s/\bCL_nCK\b/cl_nck/g;
    $g =~ s/\bCWL_nCK\b/cwl_nck/g;
    $g =~ s/\btRCD\b/trcd/g;
    return $g;
}

my $hdr = <<'EOF';
// ============================================================================
//  dv/shim/ddr3_controller.sv  —  XCELIUM COMPATIBILITY SHIM (generated)
//  Regenerate with:  perl dv/shim/gen_shim.pl  (reads ../../rtl/ddr3_controller.v)
//  See dv/shim/gen_shim.pl header for the exact, value-preserving edits.
//  Upstream rtl/ddr3_controller.v is kept pristine; this shim compiles in place.
// ============================================================================
EOF
print $hdr, $f;
