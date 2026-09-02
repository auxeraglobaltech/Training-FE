`timescale 1ns/1ps

module fifo_buffer #(
    parameter DATA_WIDTH = 64,
    parameter FIFO_DEPTH = 512,
    parameter ADDR_WIDTH = 9
)(
    input                       clk,
    input                       rst,

    // Write interface
    input                       wr_en,
    input  [DATA_WIDTH-1:0]     wr_data,

    // Read interface
    input                       rd_en,
    output reg [DATA_WIDTH-1:0] rd_data,

    // Status
    output                      full,
    output                      empty
);

    // ============================================================
    // FIFO MEMORY
    // ============================================================

    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];

    // ============================================================
    // READ / WRITE POINTERS
    // Extra MSB is used for full/empty detection
    // ============================================================

    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;

    // ============================================================
    // STATUS
    // ============================================================

    assign empty =
        (wr_ptr == rd_ptr);

    assign full =
        (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
        (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);

    // ============================================================
    // FIFO HANDSHAKES
    // ============================================================

    wire write_fire;
    wire read_fire;

    assign write_fire = wr_en && !full;
    assign read_fire  = rd_en && !empty;

    // ============================================================
    // WRITE LOGIC
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            wr_ptr <= 0;

        end

        else begin

            if (write_fire) begin

                mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;

                if (wr_ptr[ADDR_WIDTH-1:0] == FIFO_DEPTH-1) begin

                    wr_ptr[ADDR_WIDTH-1:0] <= 0;
                    wr_ptr[ADDR_WIDTH]     <= ~wr_ptr[ADDR_WIDTH];

                end

                else begin

                    wr_ptr <= wr_ptr + 1'b1;

                end

            end

        end

    end

    // ============================================================
    // READ LOGIC
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            rd_ptr  <= 0;
            rd_data <= 0;

        end

        else begin

            if (read_fire) begin

                rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];

                if (rd_ptr[ADDR_WIDTH-1:0] == FIFO_DEPTH-1) begin

                    rd_ptr[ADDR_WIDTH-1:0] <= 0;
                    rd_ptr[ADDR_WIDTH]     <= ~rd_ptr[ADDR_WIDTH];

                end

                else begin

                    rd_ptr <= rd_ptr + 1'b1;

                end

            end

        end

    end

endmodule
