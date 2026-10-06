//----------------------//
// Post-Processing Module//
//----------------------//
module postprocess(input c, p, output s);
    assign s = c ^ p;
endmodule