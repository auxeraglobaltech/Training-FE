`timescale 1ns / 1ps
module skid_buffer_dsp_w #(
    parameter integer SBUF_TYPE  = 1,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire [DATA_WIDTH-1:0] bwd_data_i,
    input  wire                  bwd_valid_i,
    output wire                  bwd_ready_o,

    output wire [DATA_WIDTH-1:0] fwd_data_o,
    output wire                  fwd_valid_o,
    input  wire                  fwd_ready_i
);

    reg [DATA_WIDTH-1:0] data0_reg, data1_reg;
    reg                  valid0_reg, valid1_reg;

    wire push;
    wire pop;

    assign fwd_data_o  = data0_reg;
    assign fwd_valid_o = valid0_reg;

    assign pop         = valid0_reg && fwd_ready_i;
    assign bwd_ready_o = rst_n && !valid1_reg;
    assign push        = bwd_valid_i && bwd_ready_o;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data0_reg  <= {DATA_WIDTH{1'b0}};
            data1_reg  <= {DATA_WIDTH{1'b0}};
            valid0_reg <= 1'b0;
            valid1_reg <= 1'b0;
        end
        else begin
            case ({push, pop})

                2'b10: begin // Push only
                    if (!valid0_reg) begin
                        data0_reg  <= bwd_data_i;
                        valid0_reg <= 1'b1;
                    end
                    else begin
                        data1_reg  <= bwd_data_i;
                        valid1_reg <= 1'b1;
                    end
                end

                2'b01: begin // Pop only
                    if (valid1_reg) begin
                        data0_reg  <= data1_reg;
                        valid1_reg <= 1'b0;
                    end
                    else begin
                        valid0_reg <= 1'b0;
                    end
                end

                2'b11: begin // Push and Pop in the same cycle
                    if (valid1_reg) begin
                        data0_reg  <= data1_reg;
                        data1_reg  <= bwd_data_i;
                    end
                    else begin
                        data0_reg  <= bwd_data_i;
                    end
                end

                default: begin
                    // Hold current state
                end

            endcase
        end
    end

endmodule


