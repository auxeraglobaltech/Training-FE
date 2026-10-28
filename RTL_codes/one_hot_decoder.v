`timescale 1ns / 1ps
module one_hot_decoder #(
    parameter integer SLV_AMT  = 2,
    parameter integer SLV_ID_W = (SLV_AMT <= 1) ? 2 : $clog2(SLV_AMT) + 1
) (
    input  wire [SLV_ID_W-1:0] dsp_AW_slv_id_i,
    input  wire                dsp_AW_disable_i,
    output wire [SLV_AMT-1:0]  slv_sel_o
);

    genvar slv_idx;

    generate
        for (slv_idx = 0; slv_idx < SLV_AMT; slv_idx = slv_idx + 1) begin : GEN_ONE_HOT_DECODER
            assign slv_sel_o[slv_idx] =
                !dsp_AW_disable_i &&
                (dsp_AW_slv_id_i == slv_idx);
        end
    endgenerate

endmodule


