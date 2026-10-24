`timescale 1ns / 1ps

module tb_brent_kung_adder;

    reg  [31:0] A, B;
    reg         Ci;
    wire [31:0] S;
    wire        Co;

    // Uhmm the expected result is 33 bits to accommodate the carry-out
    reg [32:0] expected;
    integer error_count = 0;
    integer test_count  = 0;
    integer i;

    // 
    brent_kung_adder uut (
        .A(A),
        .B(B),
        .Ci(Ci),
        .S(S),
        .Co(Co)
    );

    task check_result(input [31:0] a_in, input [31:0] b_in, input cin);
        begin
            A  = a_in;
            B  = b_in;
            Ci = cin;
            #10; // Wait for combinational propagation - is 10 enough

            expected = a_in + b_in + cin;
            test_count = test_count + 1;

            if ({Co, S} !== expected) begin
                $display("[FAIL] Time: %0t | A=0x%08h B=0x%08h Cin=%b | Expected: {Co,S}=0x%09h | Got: {Co,S}=0x%09h",
                         $time, A, B, Ci, expected, {Co, S});
                error_count = error_count + 1;
            end else begin
                $display("[PASS] Time: %0t | A=0x%08h B=0x%08h Cin=%b | Result: {Co,S}=0x%09h",
                         $time, A, B, Ci, {Co, S});
            end
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_brent_kung_adder);

        $display("---------------------------------------------------------------");
        $display(" Starting Brent-Kung 32-bit Adder Test Suite");
        $display("---------------------------------------------------------------");
// some standard test cases...ad anything extra you want
        check_result(32'h0000_0000, 32'h0000_0000, 1'b0); // Zero addition
        check_result(32'h0000_0001, 32'h0000_0001, 1'b0); // Basic 1 + 1
        check_result(32'hFFFF_FFFF, 32'h0000_0001, 1'b0); // Overflow (Cout check)
        check_result(32'h8000_0000, 32'h8000_0000, 1'b0); // MSB Carry generation
        check_result(32'h5555_5555, 32'hAAAA_AAAA, 1'b0); // Alternating bit pattern
        check_result(32'h5555_5555, 32'hAAAA_AAAA, 1'b1); // Full propagation chain
        check_result(32'h0000_000F, 32'h0000_0001, 1'b1); // Carry-in ripple effect
        check_result(32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1); // Max saturation vector

        // Randomized Stress Testing (1000 randomized vectors- your wish how manyevery you want)
        for (i = 0; i < 1000; i = i + 1) begin
            check_result($urandom(), $urandom(), $urandom() % 2);
        end

        // Your report card. Do or die mode
        $display("---------------------------------------------------------------");
        $display(" Simulation Summary: %0d Tests Completed", test_count);
        if (error_count == 0) begin
            $display(" [RESULT: PASSED] All 32-bit Brent-Kung tests matched golden model.");
        end else begin
            $display(" [RESULT: FAILED] Encountered %0d mismatches.", error_count);
        end
        $display("---------------------------------------------------------------");

        $finish;
    end

endmodule