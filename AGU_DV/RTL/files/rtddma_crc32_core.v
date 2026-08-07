
//==============================================================================
// Project   : RTD-DMA
// Module    : rtddma_crc32_core
// File      : rtddma_crc32_core.v
//------------------------------------------------------------------------------
// Description :
//   Combinational CRC-32 update core.
//   - Polynomial: 0x04C11DB7 (standard CRC-32)
//   - Processes 32 bits of input data in parallel (one 32-bit word).
//   - Updates crc_in -> crc_out in one cycle.
//
//   Note: This version assumes MSB-first processing of data_in[31:0] with a
//   non-reflected polynomial form. If your protocol expects reflected CRC
//   (bit-reversed), adjust the bit order and/or polynomial accordingly.
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module rtddma_crc32_core
(
    input  wire [31:0] crc_in,   // current CRC value
    input  wire [31:0] data_in,  // 32-bit data word
    output wire [31:0] crc_out   // updated CRC
);

    // Local parameters for polynomial (non-reflected form)
    localparam [31:0] POLY = 32'h04C11DB7;

    reg [31:0] crc_next;
    integer i;

    always @* begin
        crc_next = crc_in;

        // Process data MSB-first: data_in[31] down to data_in[0]
        for (i = 31; i >= 0; i = i - 1) begin
            // XOR incoming data bit with current CRC MSB
            if ((crc_next[31] ^ data_in[i]) == 1'b1) begin
                crc_next = (crc_next << 1) ^ POLY;
            end
            else begin
                crc_next = (crc_next << 1);
            end
        end
    end

    assign crc_out = crc_next;

endmodule

