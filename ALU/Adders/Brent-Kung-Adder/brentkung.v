`timescale 1ns/1ps




//-------------------------//
// Brent-Kung 32-bit Adder //
//-------------------------//
module brent_kung_adder(
    input [31:0] A, B,
    input Ci,
    output [31:0] S,
    output Co
);
    wire [31:0] P1, G1;  // First order propagate and generate
    wire [32:0] C;       // Carry signals, including C[0] for Ci
    wire [15:0] G2, P2;
    wire [7:0] G3, P3;
    wire [3:0] G4, P4;
    wire [1:0] G5, P5;
    wire G6, P6;

    // Pre-processing (Generate & Propagate)
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: preprocessing_stage
            preprocess pp (A[i], B[i], G1[i], P1[i]);
        end
    endgenerate

    // Prefix tree for carry computation
    generate
        for (i = 0; i < 16; i = i + 1) begin: second_stage
            blackcell bc (G1[2*i+1], P1[2*i+1], G1[2*i], P1[2*i], G2[i], P2[i]);
        end
        for (i = 0; i < 8; i = i + 1) begin: third_stage
            blackcell bc (G2[2*i+1], P2[2*i+1], G2[2*i], P2[2*i], G3[i], P3[i]);
        end
        for (i = 0; i < 4; i = i + 1) begin: fourth_stage
            blackcell bc (G3[2*i+1], P3[2*i+1], G3[2*i], P3[2*i], G4[i], P4[i]);
        end
        for (i = 0; i < 2; i = i + 1) begin: fifth_stage
            blackcell bc (G4[2*i+1], P4[2*i+1], G4[2*i], P4[2*i], G5[i], P5[i]);
        end
    endgenerate

    // Last level black cell
    blackcell bc_last (G5[1], P5[1], G5[0], P5[0], G6, P6);

    // Compute carries
    assign C[0] = Ci;  // Initialize C[0] with Carry-in
    assign C[1] = G1[0] | (P1[0] & C[0]);
    assign C[2] = G2[0] | (P2[0] & C[0]);
    assign C[4] = G3[0] | (P3[0] & C[0]);
    assign C[8] = G4[0] | (P4[0] & C[0]);
    assign C[16] = G5[0] | (P5[0] & C[0]);
    assign C[32] = G6 | (P6 & C[0]);

    generate
        for (i = 3; i < 32; i = i + 1) begin: carry_stage
            if (i != 4 && i != 8 && i != 16) begin
                graycell gc (G1[i-1], P1[i-1], C[i-1], C[i]);
            end
        end
    endgenerate

    // Post-processing (Sum computation)
    generate
        for (i = 0; i < 32; i = i + 1) begin: postprocessing_stage
            postprocess pp (C[i], P1[i], S[i]);
        end
    endgenerate

    assign Co = C[32];

endmodule
