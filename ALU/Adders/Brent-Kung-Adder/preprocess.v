

//----------------------//
// Pre-Processing Module//
//----------------------//
module preprocess(input a, b, output g, p);
    assign g = a & b;
    assign p = a ^ b;
endmodule

