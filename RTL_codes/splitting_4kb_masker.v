`timescale 1ns/1ps
module splitting_4kb_masker #(
    parameter integer ADDR_WIDTH  = 32,
    parameter integer LEN_WIDTH   = 3,
    parameter integer SIZE_WIDTH  = 3,
    parameter integer BURST_WIDTH = 2
) (
    input  wire                   valid_i,
    input  wire [ADDR_WIDTH-1:0]  ADDR_i,
    input  wire [LEN_WIDTH-1:0]   LEN_i,
    input  wire [SIZE_WIDTH-1:0]  SIZE_i,
    input  wire [BURST_WIDTH-1:0] BURST_i,
    input  wire                   mask_sel_i,
    output reg  [ADDR_WIDTH-1:0]  ADDR_split_o,
    output reg  [LEN_WIDTH-1:0]   LEN_split_o,
    output reg                    crossing_flag,
    output reg                    invalid_o
);

    localparam integer CALC_WIDTH = ADDR_WIDTH + LEN_WIDTH + (1 << SIZE_WIDTH) + 4;

    localparam [BURST_WIDTH-1:0] AXI_BURST_INCR = 2'b01;
    localparam [BURST_WIDTH-1:0] AXI_BURST_RSVD = 2'b11;

    reg [CALC_WIDTH-1:0] start_addr_ext;
    reg [CALC_WIDTH-1:0] size_bytes_ext;
    reg [CALC_WIDTH-1:0] aligned_addr_ext;
    reg [CALC_WIDTH-1:0] total_beats_ext;
    reg [CALC_WIDTH-1:0] total_bytes_ext;
    reg [CALC_WIDTH-1:0] end_addr_ext;
    reg [CALC_WIDTH-1:0] page_offset_ext;
    reg [CALC_WIDTH-1:0] first_beats_ext;
    reg [CALC_WIDTH-1:0] second_beats_ext;
    reg [CALC_WIDTH-1:0] second_addr_ext;

`ifndef SYNTHESIS
    initial begin
        if (ADDR_WIDTH < 12) begin
            $display("splitting_4kb_masker: ADDR_WIDTH must be >= 12");
            $finish;
        end
    end
`endif

    always @* begin
        start_addr_ext   = {CALC_WIDTH{1'b0}};
        size_bytes_ext   = {CALC_WIDTH{1'b0}};
        aligned_addr_ext = {CALC_WIDTH{1'b0}};
        total_beats_ext  = {CALC_WIDTH{1'b0}};
        total_bytes_ext  = {CALC_WIDTH{1'b0}};
        end_addr_ext     = {CALC_WIDTH{1'b0}};
        page_offset_ext  = {CALC_WIDTH{1'b0}};
        first_beats_ext  = {CALC_WIDTH{1'b0}};
        second_beats_ext = {CALC_WIDTH{1'b0}};
        second_addr_ext  = {CALC_WIDTH{1'b0}};

        ADDR_split_o  = ADDR_i;
        LEN_split_o   = LEN_i;
        crossing_flag = 1'b0;
        invalid_o     = 1'b0;

        if (valid_i) begin
            if (BURST_i == AXI_BURST_RSVD) begin
                ADDR_split_o = {ADDR_WIDTH{1'b0}};
                LEN_split_o  = {LEN_WIDTH{1'b0}};
                invalid_o    = 1'b1;
            end
            else if (BURST_i == AXI_BURST_INCR) begin
                start_addr_ext   = {{(CALC_WIDTH-ADDR_WIDTH){1'b0}}, ADDR_i};
                size_bytes_ext   = {{(CALC_WIDTH-1){1'b0}}, 1'b1} << SIZE_i;
                aligned_addr_ext = start_addr_ext & ~(size_bytes_ext - 1'b1);

                total_beats_ext  = {{(CALC_WIDTH-LEN_WIDTH){1'b0}}, LEN_i} + 1'b1;
                total_bytes_ext  = total_beats_ext << SIZE_i;
                end_addr_ext     = aligned_addr_ext + total_bytes_ext - 1'b1;

                crossing_flag =
                    (end_addr_ext[CALC_WIDTH-1:12] !=
                     aligned_addr_ext[CALC_WIDTH-1:12]);

                if (crossing_flag) begin
                    page_offset_ext = aligned_addr_ext &
                                      {{(CALC_WIDTH-12){1'b0}}, 12'hFFF};

                    first_beats_ext  = (13'd4096 - page_offset_ext) >> SIZE_i;
                    second_beats_ext = total_beats_ext - first_beats_ext;
                    second_addr_ext  = aligned_addr_ext +
                                       (first_beats_ext << SIZE_i);

                    if ((first_beats_ext == 0) || (second_beats_ext == 0)) begin
                        ADDR_split_o  = {ADDR_WIDTH{1'b0}};
                        LEN_split_o   = {LEN_WIDTH{1'b0}};
                        crossing_flag = 1'b0;
                        invalid_o     = 1'b1;
                    end
                    else if (!mask_sel_i) begin
                        ADDR_split_o = ADDR_i;
                        LEN_split_o  = first_beats_ext - 1'b1;
                    end
                    else begin
                        ADDR_split_o = second_addr_ext[ADDR_WIDTH-1:0];
                        LEN_split_o  = second_beats_ext - 1'b1;
                    end
                end
            end
            // FIXED / WRAP: pass-through (already the default values)
        end
    end
endmodule


