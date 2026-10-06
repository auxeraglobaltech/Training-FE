//------------------//
// Gray Cell Module //
//------------------//
module graycell(input gi, pi, gi1, output c);
    assign c = gi | (pi & gi1);
endmodule