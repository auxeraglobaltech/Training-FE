`ifndef RTDDMAAGUDEFS_VH
`define RTDDMAAGUDEFS_VH

// -----------------------------------------------------------------------------
// RTD-DMA Fault Code Encodings
// Includes all explicit codes seen in AGU RTL plus exhaustive nearby safety codes
// and duplicate semantic aliases where names differ across docs/RTL.
// -----------------------------------------------------------------------------

`define RTDDMAFAULTNONE                   8'h00
`define RTDDMA_FAULT_NONE                 8'h00

// Generic infrastructure / protocol
`define RTDDMAFAULTFSMILLEGALSTATE        8'h01
`define RTDDMA_FAULT_FSM_ILLEGAL_STATE    8'h01
`define RTDDMAFAULTTIMEOUT                8'h02
`define RTDDMA_FAULT_TIMEOUT              8'h02
`define RTDDMAFAULTPARITY                 8'h03
`define RTDDMA_FAULT_PARITY               8'h03
`define RTDDMAFAULTECC                    8'h04
`define RTDDMA_FAULT_ECC                  8'h04
`define RTDDMAFAULTCRC                    8'h05
`define RTDDMA_FAULT_CRC                  8'h05

// Internal FIFO / datapath / progress
`define RTDDMAFAULTFIFOOVERFLOW           8'h10
`define RTDDMA_FAULT_FIFO_OVERFLOW        8'h10
`define RTDDMAFAULTFIFOUNDERFLOW          8'h11
`define RTDDMA_FAULT_FIFO_UNDERFLOW       8'h11
`define RTDDMAFAULTINTERNALUNDERFLOW      8'h12
`define RTDDMA_FAULT_INTERNAL_UNDERFLOW   8'h12
`define RTDDMAFAULTINTERNALOVERFLOW       8'h13
`define RTDDMA_FAULT_INTERNAL_OVERFLOW    8'h13
`define RTDDMAFAULTOUTSTANDINGMISMATCH    8'h14
`define RTDDMA_FAULT_OUTSTANDING_MISMATCH 8'h14
`define RTDDMAFAULTSTARVATION             8'h15
`define RTDDMA_FAULT_STARVATION           8'h15
`define RTDDMAFAULTPROGRESSSTALL          8'h16
`define RTDDMA_FAULT_PROGRESS_STALL       8'h16

// MPU / protection
`define RTDDMAFAULTMPUREGION              8'h20
`define RTDDMA_FAULT_MPU_REGION           8'h20
`define RTDDMAFAULTMPUBURST               8'h21
`define RTDDMA_FAULT_MPU_BURST            8'h21
`define RTDDMAFAULTMPUALIGN               8'h22
`define RTDDMA_FAULT_MPU_ALIGN            8'h22
`define RTDDMAFAULTMPUPERM                8'h23
`define RTDDMA_FAULT_MPU_PERM             8'h23

// AGU arithmetic / traversal
`define RTDDMAFAULTAGUADDROVERFLOW        8'h30
`define RTDDMA_FAULT_AGU_ADDR_OVERFLOW    8'h30
`define RTDDMAFAULTAGUADDRWRAP            8'h31
`define RTDDMA_FAULT_AGU_ADDR_WRAP        8'h31
`define RTDDMAFAULTAGUXCOUNTZERO          8'h32
`define RTDDMA_FAULT_AGU_XCOUNT_ZERO      8'h32
`define RTDDMAFAULTAGUYCOUNTZERO          8'h33
`define RTDDMA_FAULT_AGU_YCOUNT_ZERO      8'h33
`define RTDDMAFAULTAGUGATHEROOB           8'h34
`define RTDDMA_FAULT_AGU_GATHER_OOB       8'h34
`define RTDDMAFAULTAGUSCATTEROOB          8'h35
`define RTDDMA_FAULT_AGU_SCATTER_OOB      8'h35
`define RTDDMAFAULTAGUXOVERFLOW           8'h36
`define RTDDMA_FAULT_AGU_X_OVERFLOW       8'h36
`define RTDDMAFAULTAGUYOVERFLOW           8'h37
`define RTDDMA_FAULT_AGU_Y_OVERFLOW       8'h37
`define RTDDMAFAULTAGUXREVERSE            8'h38
`define RTDDMA_FAULT_AGU_X_REVERSE        8'h38
`define RTDDMAFAULTAGUYREVERSE            8'h39
`define RTDDMA_FAULT_AGU_Y_REVERSE        8'h39
`define RTDDMAFAULTAGUNULLDIM             8'h3A
`define RTDDMA_FAULT_AGU_NULL_DIM         8'h3A
`define RTDDMAFAULTAGUBOUNDS              8'h3B
`define RTDDMA_FAULT_AGU_BOUNDS           8'h3B
`define RTDDMAFAULTAGUSTRIDEOFLOW         8'h3C
`define RTDDMA_FAULT_AGU_STRIDE_OFLOW     8'h3C

// Descriptor / config / trigger / swap
`define RTDDMAFAULTDESCCRC                8'h40
`define RTDDMA_FAULT_DESC_CRC             8'h40
`define RTDDMAFAULTDESCPARITY             8'h41
`define RTDDMA_FAULT_DESC_PARITY          8'h41
`define RTDDMAFAULTDESCREGION             8'h42
`define RTDDMA_FAULT_DESC_REGION          8'h42
`define RTDDMAFAULTDESCLOOP               8'h43
`define RTDDMA_FAULT_DESC_LOOP            8'h43
`define RTDDMAFAULTTRIGGERREJECT          8'h44
`define RTDDMA_FAULT_TRIGGER_REJECT       8'h44
`define RTDDMAFAULTCFGCOMMIT              8'h45
`define RTDDMA_FAULT_CFG_COMMIT           8'h45
`define RTDDMAFAULTSWAPILLEGAL            8'h46
`define RTDDMA_FAULT_SWAP_ILLEGAL         8'h46
`define RTDDMAFAULTBANKINVALID            8'h47
`define RTDDMA_FAULT_BANK_INVALID         8'h47

// AXI / external response
`define RTDDMAFAULTAXI_DECERR             8'h50
`define RTDDMA_FAULT_AXI_DECERR           8'h50
`define RTDDMAFAULTAXI_SLVERR             8'h51
`define RTDDMA_FAULT_AXI_SLVERR           8'h51
`define RTDDMAFAULTAXI_TIMEOUT            8'h52
`define RTDDMA_FAULT_AXI_TIMEOUT          8'h52
`define RTDDMAFAULTAXI_PROTOCOL           8'h53
`define RTDDMA_FAULT_AXI_PROTOCOL         8'h53

// CDC / reset / safety infra
`define RTDDMAFAULTCDC                    8'h60
`define RTDDMA_FAULT_CDC                  8'h60
`define RTDDMAFAULTRESETSEQ               8'h61
`define RTDDMA_FAULT_RESET_SEQ            8'h61
`define RTDDMAFAULTFIRSTFAULTCORRUPT      8'h62
`define RTDDMA_FAULT_FIRSTFAULT_CORRUPT   8'h62
`define RTDDMAFAULTSAFESTATE              8'h63
`define RTDDMA_FAULT_SAFE_STATE           8'h63

`define RTDDMA_ADDR_MODE_LINEAR   2'b00
`define RTDDMA_ADDR_MODE_STRIDE   2'b01
`define RTDDMA_ADDR_MODE_GATHER   2'b10
`define RTDDMA_ADDR_MODE_SCATTER  2'b11

`endif
