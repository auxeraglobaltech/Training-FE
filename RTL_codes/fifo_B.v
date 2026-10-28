
`timescale 1ns / 1ps

module fifo_B #(
    parameter integer FIFO_TYPE   = 2,   // unused, kept for compatibility
    parameter integer DATA_WIDTH  = 32,
    parameter integer FIFO_DEPTH  = 16,
    parameter integer PTR_WIDTH   = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH),
    parameter integer COUNT_WIDTH = (FIFO_DEPTH <= 1) ? 1 : $clog2(FIFO_DEPTH + 1)
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  data_i,
    output wire [DATA_WIDTH-1:0]  data_o,
    input  wire                   rd_valid_i,
    input  wire                   wr_valid_i,
    output wire                   empty_o,
    output wire                   full_o,
    output wire                   wr_ready_o,
    output wire                   rd_ready_o,
    output wire                   almost_empty_o,
    output wire                   almost_full_o,
    output reg  [COUNT_WIDTH-1:0] counter
);

    localparam [PTR_WIDTH-1:0]   LAST_PTR = FIFO_DEPTH - 1;
    localparam [COUNT_WIDTH-1:0] DEPTH_C  = FIFO_DEPTH;
    localparam [COUNT_WIDTH-1:0] DEPTH_M1 = FIFO_DEPTH - 1;
    localparam [COUNT_WIDTH-1:0] ONE_C    = 1;

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH-1:0]  wr_ptr;
    reg [PTR_WIDTH-1:0]  rd_ptr;

    wire do_write;
    wire do_read;

`ifndef SYNTHESIS
    initial begin
        if (DATA_WIDTH < 1 || FIFO_DEPTH < 1) begin
            $display("fifo: DATA_WIDTH and FIFO_DEPTH must be >= 1");
            $finish;
        end
    end
`endif

    assign empty_o    = (counter == {COUNT_WIDTH{1'b0}});
    assign full_o     = (counter == DEPTH_C);
    assign wr_ready_o = !full_o;
    assign rd_ready_o = !empty_o;

    assign do_write   = wr_valid_i && wr_ready_o;
    assign do_read    = rd_valid_i && rd_ready_o;

    assign almost_empty_o = (counter <= ONE_C);
    assign almost_full_o  = (counter >= DEPTH_M1);

    // FWFT (First-Word Fall-Through): Head element is visible combinationally
    assign data_o = empty_o ? {DATA_WIDTH{1'b0}} : mem[rd_ptr];

    always @(posedge clk) begin
        if (do_write)
            mem[wr_ptr] <= data_i;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr  <= {PTR_WIDTH{1'b0}};
            rd_ptr  <= {PTR_WIDTH{1'b0}};
            counter <= {COUNT_WIDTH{1'b0}};
        end
        else begin
            if (do_write) begin
                if (wr_ptr == LAST_PTR)
                    wr_ptr <= {PTR_WIDTH{1'b0}};
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (do_read) begin
                if (rd_ptr == LAST_PTR)
                    rd_ptr <= {PTR_WIDTH{1'b0}};
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({do_write, do_read})
                2'b10:   counter <= counter + 1'b1;
                2'b01:   counter <= counter - 1'b1;
                default: counter <= counter;
            endcase
        end
    end

endmodule

