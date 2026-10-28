
`timescale 1ns / 1ps

module skid_buffer_r #(
    parameter integer SBUF_TYPE  = 1,   // Unused, kept for compatibility
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

    reg [DATA_WIDTH-1:0] data0_reg;
    reg [DATA_WIDTH-1:0] data1_reg;

    reg valid0_reg;
    reg valid1_reg;

    wire push;
    wire pop;

    // Parameter validation
    initial begin
        if (DATA_WIDTH < 1) begin
            $error("%m: skid_buffer_r: DATA_WIDTH must be greater than zero");
            $finish;
        end
    end

    // Interface assignments
    assign bwd_ready_o = !valid1_reg;
    assign fwd_valid_o = valid0_reg;
    assign fwd_data_o  = data0_reg;

    // Handshake conditions
    assign push = bwd_valid_i && bwd_ready_o;
    assign pop  = fwd_valid_o && fwd_ready_i;

    // Two-entry skid buffer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data0_reg  <= {DATA_WIDTH{1'b0}};
            data1_reg  <= {DATA_WIDTH{1'b0}};

            valid0_reg <= 1'b0;
            valid1_reg <= 1'b0;
        end
        else begin
            case ({push, pop})

                // Push only
                2'b10: begin
                    if (!valid0_reg) begin
                        data0_reg  <= bwd_data_i;
                        valid0_reg <= 1'b1;
                    end
                    else begin
                        data1_reg  <= bwd_data_i;
                        valid1_reg <= 1'b1;
                    end
                end

                // Pop only
                2'b01: begin
                    if (valid1_reg) begin
                        data0_reg  <= data1_reg;
                        valid0_reg <= 1'b1;
                        valid1_reg <= 1'b0;
                    end
                    else begin
                        data0_reg  <= {DATA_WIDTH{1'b0}};
                        valid0_reg <= 1'b0;
                    end
                end

                // Push and pop in the same cycle
                2'b11: begin
                    data0_reg  <= bwd_data_i;
                    valid0_reg <= 1'b1;
                end

                // No operation
                default: begin
                end

            endcase
        end
    end

endmodule

