//-------------------//
// Black Cell Module //
//-------------------//
module blackcell(input gik, pik, gkj, pkj, output gij, pij);
    assign gij = gik | (pik & gkj);
    assign pij = pik & pkj;
endmodule