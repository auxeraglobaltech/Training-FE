`timescale 1ns/1ps

module crc32_calc #(
    parameter CRC_SIZE   = 32,
    parameter DATA_WIDTH = 8,

    parameter [31:0] POLY    = 32'h04C11DB7,
    parameter [31:0] INIT    = 32'hFFFFFFFF,
    parameter REF_IN         = 1,
    parameter REF_OUT        = 1,
    parameter [31:0] XOR_OUT = 32'hFFFFFFFF
)
(
    input                    clk_i,
    input                    rst_i,
    input                    soft_reset_i,
    input                    valid_i,

    input  [DATA_WIDTH-1:0]  data_i,

    output [CRC_SIZE-1:0]    crc_o
);


reg [CRC_SIZE-1:0] crc;
reg [CRC_SIZE-1:0] crc_next;
reg [CRC_SIZE-1:0] crc_prev;


integer i;
integer j;


//--------------------------------------------------
// CRC Register
//--------------------------------------------------

always @(posedge clk_i)
begin
    if(rst_i)
        crc <= INIT;

    else if(soft_reset_i)
        crc <= INIT;

    else if(valid_i)
        crc <= crc_next;
end



//--------------------------------------------------
// Final CRC Output
//--------------------------------------------------

assign crc_o = crc ^ XOR_OUT;



//--------------------------------------------------
// CRC-32 Calculation
// CRC-32 Reflected Input and Output
//--------------------------------------------------

always @(*)
begin

    crc_next = crc;
    crc_prev = crc;


    for(i = 0; i < DATA_WIDTH; i = i + 1)
    begin

        crc_next[31] = crc_prev[0] ^ data_i[i];


        for(j = 1; j < CRC_SIZE; j = j + 1)
        begin

            if(POLY[j])

                crc_next[CRC_SIZE-1-j] =
                    crc_prev[CRC_SIZE-j] ^
                    crc_prev[0] ^
                    data_i[i];

            else

                crc_next[CRC_SIZE-1-j] =
                    crc_prev[CRC_SIZE-j];

        end


        crc_prev = crc_next;

    end

end


endmodule
