`timescale 1ns/1ps

module BrentKung #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] A,
    input  [WIDTH-1:0] B,
    input              Cin,
    output [WIDTH-1:0] Sum,
    output             Cout
);

    // --------------------------------------------------
    // Number of prefix levels
    // --------------------------------------------------
    localparam LEVELS = $clog2(WIDTH);

    // --------------------------------------------------
    // Generate and Propagate
    // --------------------------------------------------
    wire [WIDTH-1:0] G0;
    wire [WIDTH-1:0] P0;

    assign G0 = A & B;
    assign P0 = A ^ B;

    // --------------------------------------------------
    // Prefix Generate and Propagate
    // --------------------------------------------------
    wire [WIDTH-1:0] G [0:LEVELS];
    wire [WIDTH-1:0] P [0:LEVELS];

    assign G[0] = G0;
    assign P[0] = P0;

    genvar l, i;

    // --------------------------------------------------
    // Brent-Kung Prefix Tree
    // --------------------------------------------------
    generate

        for (l = 0; l < LEVELS; l = l + 1) begin : prefix_level

            for (i = 0; i < WIDTH; i = i + 1) begin : prefix_bit

                if (i >= (1 << l)) begin

                    assign G[l+1][i] =
                        G[l][i] |
                        (P[l][i] & G[l][i-(1 << l)]);

                    assign P[l+1][i] =
                        P[l][i] &
                        P[l][i-(1 << l)];

                end
                else begin

                    assign G[l+1][i] = G[l][i];
                    assign P[l+1][i] = P[l][i];

                end

            end

        end

    endgenerate

    // --------------------------------------------------
    // Carry computation
    // --------------------------------------------------
    wire [WIDTH:0] C;

    assign C[0] = Cin;

    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_generation

            assign C[i+1] =
                G[LEVELS][i] |
                (P[LEVELS][i] & Cin);

        end
    endgenerate

    // --------------------------------------------------
    // Sum
    // --------------------------------------------------
    assign Sum = P0 ^ C[WIDTH-1:0];

    // --------------------------------------------------
    // Final Carry
    // --------------------------------------------------
    assign Cout = C[WIDTH];

endmodule
