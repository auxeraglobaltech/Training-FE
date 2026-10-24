`timescale 1ns / 1ps

module tb_brent_kung_adder;
    reg [31:0] A, B;
    reg Ci;
    wire [31:0] S;
    wire Co;

    // Instantiate Brent-Kung Adder
    brent_kung_adder uut (
        .A(A), .B(B), .Ci(Ci),
        .S(S), .Co(Co)
    );

    initial begin
        // EPWave dump setup
        $dumpfile("waveform.vcd");  
        $dumpvars(0, tb_brent_kung_adder);

        // Initialize inputs
        A = 0; B = 0; Ci = 0;
        #10; // Wait for 10 ns before starting tests

        // Test Case 1: Basic Addition
        A = 32'b00000000000000000000000000000001; // A = 1
        B = 32'b00000000000000000000000000000001; // B = 1
        Ci = 0;  
        #20; // Increased delay

        // Test Case 2: Adding large numbers (Overflow case)
        A = 32'b11111111111111111111111111111111; // A = 4294967295
        B = 32'b00000000000000000000000000000001; // B = 1
        Ci = 0;
        #20;

        // Test Case 3: Carry Propagation (Adding two large positive numbers)
        A = 32'b10000000000000000000000000000000; // A = 2147483648
        B = 32'b10000000000000000000000000000000; // B = 2147483648
        Ci = 0;
        #20;

        // Test Case 4: Zero Addition
        A = 32'b00000000000000000000000000000000; // A = 0
        B = 32'b00000000000000000000000000000000; // B = 0
        Ci = 0;
        #20;

        // Test Case 5: Random Addition
        A = 32'b00000000000000000000000000001010; // A = 10
        B = 32'b00000000000000000000000000010100; // B = 20
        Ci = 0;
        #20;

        // Test Case 6: Carry-in Effect
        A = 32'b00000000000000000000000000001111; // A = 15
        B = 32'b00000000000000000000000000000001; // B = 1
        Ci = 1;
        #20;

        // Finish Simulation
        $finish;
    end

    initial begin
        $monitor("Time = %t | A = %b | B = %b | Cin = %b | S = %b | Cout = %b",
                 $time, A, B, Ci, S, Co);
    end
endmodule
