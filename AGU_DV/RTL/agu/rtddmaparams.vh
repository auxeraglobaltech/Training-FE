`ifndef RTDDMAPARAMS_VH
`define RTDDMAPARAMS_VH

// -----------------------------------------------------------------------------
// RTD-DMA Global Parameters
// Tape-out-oriented common parameter header for AGU-centric RTL integration.
// Includes canonical widths plus compatibility aliases for legacy include style.
// -----------------------------------------------------------------------------

// Fundamental bus and field widths
`define RTDDMA_ADDR_W                 40
`define RTDDMA_DATA_W                 128
`define RTDDMA_AXI_DATA_W             128
`define RTDDMA_APB_ADDR_W             16
`define RTDDMA_APB_DATA_W             32
`define RTDDMA_COUNT_W                16
`define RTDDMA_STRIDE_W               16
`define RTDDMA_FAULTCODE_W            8
`define RTDDMA_FAULTINFO_W            32
`define RTDDMA_STATE_W                3
`define RTDDMA_STATE_W_EXT            4
`define RTDDMA_WIDTHCODE_W            2
`define RTDDMA_ADDRMODE_W             2
`define RTDDMA_BURSTTYPE_W            2
`define RTDDMA_AXSIZE_W               3
`define RTDDMA_AXLEN_W                8
`define RTDDMA_OUTSTANDING_W          4
`define RTDDMA_CONTEXT_WORD_W         32
`define RTDDMA_CONTEXT_WORDS          8
`define RTDDMA_SEQID_W                16
`define RTDDMA_FLAGS_W                8
`define RTDDMA_DESCCRC_W              16

// Canonical depth / count limits
`define RTDDMAMAXOUTSTANDING          4'd8
`define RTDDMA_MAX_OUTSTANDING        4'd8
`define RTDDMA_MAX_BURST_BEATS        16
`define RTDDMA_MAX_BURST_BYTES        16'd256
`define RTDDMA_MAX_4KB_BYTES          16'd4096
`define RTDDMA_MAX_CHAIN_DEPTH        16'd256
`define RTDDMA_NUM_CONTEXT_WORDS      8
`define RTDDMA_NUM_MPU_REGIONS        4
`define RTDDMA_NUM_SLICES             2

// Address alignment helper masks
`define RTDDMA_ADDR_LSB_8BIT          3'd0
`define RTDDMA_ADDR_LSB_16BIT         3'd1
`define RTDDMA_ADDR_LSB_32BIT         3'd2
`define RTDDMA_ADDR_LSB_64BIT         3'd3

// Transfer width encodings
`define RTDDMA_WIDTH_8B               2'b00
`define RTDDMA_WIDTH_16B              2'b01
`define RTDDMA_WIDTH_32B              2'b10
`define RTDDMA_WIDTH_64B              2'b11

// Aliases intentionally duplicated for verification compatibility
`define RTDDMA_DATASIZE_8BIT          2'b00
`define RTDDMA_DATASIZE_16BIT         2'b01
`define RTDDMA_DATASIZE_32BIT         2'b10
`define RTDDMA_DATASIZE_64BIT         2'b11
`define RTDDMA_SRCWIDTH_8BIT          2'b00
`define RTDDMA_SRCWIDTH_16BIT         2'b01
`define RTDDMA_SRCWIDTH_32BIT         2'b10
`define RTDDMA_SRCWIDTH_64BIT         2'b11
`define RTDDMA_DSTWIDTH_8BIT          2'b00
`define RTDDMA_DSTWIDTH_16BIT         2'b01
`define RTDDMA_DSTWIDTH_32BIT         2'b10
`define RTDDMA_DSTWIDTH_64BIT         2'b11

// AXI burst types
`define RTDDMA_AXBURST_FIXED          2'b00
`define RTDDMA_AXBURST_INCR           2'b01
`define RTDDMA_AXBURST_WRAP           2'b10
`define RTDDMA_AXBURST_RSVD           2'b11

// Compatibility duplicates
`define RTDDMA_BURSTTYPE_FIXED        2'b00
`define RTDDMA_BURSTTYPE_INCR         2'b01
`define RTDDMA_BURSTTYPE_WRAP         2'b10
`define RTDDMA_BURSTTYPE_RESERVED     2'b11

// Misc synthesis-safe defaults
`define RTDDMA_RESET_ADDR             40'd0
`define RTDDMA_RESET_COUNT            16'd0
`define RTDDMA_RESET_FAULTINFO        32'd0
`define RTDDMA_RESET_SEQID            16'd0

`endif