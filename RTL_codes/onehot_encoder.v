
`timescale 1ns/1ps
module onehot_encoder #(
    parameter integer INPUT_W  = 3,
    parameter integer OUTPUT_W = (INPUT_W <= 1) ? 1 : $clog2(INPUT_W)
) (
    input  wire [INPUT_W-1:0]  i,
    output reg  [OUTPUT_W-1:0] o
);
    integer idx;
    reg     priority_found;

    always @* begin
        o              = {OUTPUT_W{1'b0}};
        priority_found = 1'b0;
        for (idx = 0; idx < INPUT_W; idx = idx + 1) begin
            if (i[idx] && !priority_found) begin
                o              = idx;
                priority_found = 1'b1;
            end
        end
    end
endmodule

