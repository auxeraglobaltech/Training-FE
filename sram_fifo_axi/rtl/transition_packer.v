`timescale 1ns/1ps

module transition_packer #(
    parameter DATA_WIDTH = 64
)(
    input                       clk,
    input                       rst,

    // ------------------------------------------------------------
    // Variable-width transition input
    // ------------------------------------------------------------

    input                       trans_valid,
    output                      trans_ready,

    input  [DATA_WIDTH-1:0]     trans_data,
    input  [6:0]                trans_width,

    // ------------------------------------------------------------
    // FIFO interface
    // ------------------------------------------------------------

    output reg                  fifo_wr_en,
    output reg [DATA_WIDTH-1:0] fifo_wr_data,
    input                       fifo_full
);


    // ------------------------------------------------------------
    // Packing buffer
    //
    // Stores bits which have not yet formed a complete
    // DATA_WIDTH-bit FIFO word.
    // ------------------------------------------------------------

    reg [DATA_WIDTH-1:0] pack_buffer;

    // Number of valid bits currently in pack_buffer
    reg [6:0] pack_count;


    // ------------------------------------------------------------
    // Pending FIFO word
    //
    // Used when FIFO is full and a completed word is waiting
    // to be written.
    // ------------------------------------------------------------

    reg                     pending_valid;
    reg [DATA_WIDTH-1:0]    pending_data;


    // ------------------------------------------------------------
    // FIFO write interface
    // ------------------------------------------------------------

    always @(*) begin

        fifo_wr_en   = pending_valid;
        fifo_wr_data = pending_data;

    end


    // ------------------------------------------------------------
    // Input ready
    //
    // New transition can be accepted when there is no pending
    // FIFO word, or when the pending FIFO word can be accepted
    // in the current cycle.
    // ------------------------------------------------------------

    assign trans_ready = !pending_valid ||
                         (pending_valid && !fifo_full);


    // ------------------------------------------------------------
    // Packing Logic
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin

            pack_buffer  <= {DATA_WIDTH{1'b0}};
            pack_count   <= 7'd0;

            pending_valid <= 1'b0;
            pending_data  <= {DATA_WIDTH{1'b0}};

        end

        else begin

            // ----------------------------------------------------
            // Step 1
            //
            // If a pending FIFO word exists and FIFO is not full,
            // send it to FIFO.
            // ----------------------------------------------------

            if (pending_valid && !fifo_full) begin

                pending_valid <= 1'b0;

            end


            // ----------------------------------------------------
            // Step 2
            //
            // Accept a new transition.
            // ----------------------------------------------------

            if (trans_valid && trans_ready) begin

                // ------------------------------------------------
                // CASE 1
                //
                // Transition completely fits in current buffer.
                // ------------------------------------------------

                if ((pack_count + trans_width) < DATA_WIDTH) begin

                    pack_buffer <=
                        pack_buffer |
                        (trans_data << pack_count);

                    pack_count <=
                        pack_count + trans_width;

                end


                // ------------------------------------------------
                // CASE 2
                //
                // Transition exactly fills the current word.
                // ------------------------------------------------

                else if ((pack_count + trans_width) == DATA_WIDTH) begin

$display("");
$display("========================================");
$display("[%0t] PACKER CROSSING 64-BIT BOUNDARY", $time);
$display("PACK_COUNT BEFORE = %0d", pack_count);
$display("TRANS_WIDTH       = %0d", trans_width);
$display("TRANS_DATA        = %h", trans_data);
$display("PACK_BUFFER BEFORE = %h", pack_buffer);
$display("========================================");

                    pending_data <=
                        pack_buffer |
                        (trans_data << pack_count);

                    pending_valid <= 1'b1;

                    pack_buffer <=
                        {DATA_WIDTH{1'b0}};

                    pack_count <= 7'd0;

                end


                // ------------------------------------------------
                // CASE 3
                //
                // Transition crosses the current 64-bit boundary.
                // ------------------------------------------------

                else begin

                    // --------------------------------------------
                    // Number of bits required to complete current
                    // FIFO word.
                    // --------------------------------------------

                    // Example:
                    //
                    // pack_count  = 48
                    // trans_width = 24
                    //
                    // 16 bits go into current word.
                    // 8 bits remain.
                    // --------------------------------------------

                    pending_data <=
                        pack_buffer |
                        (trans_data << pack_count);

                    pending_valid <= 1'b1;


                    // --------------------------------------------
                    // Keep the remaining bits of the transition.
                    // --------------------------------------------

                    pack_buffer <=
                        trans_data >>
                        (DATA_WIDTH - pack_count);


                    // --------------------------------------------
                    // Remaining number of bits.
                    // --------------------------------------------

                    pack_count <=
                        pack_count +
                        trans_width -
                        DATA_WIDTH;

                end

            end

        end

    end

endmodule
