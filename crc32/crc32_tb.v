`timescale 1ns/1ps

module crc32_calc_tb;

parameter CRC_SIZE   = 32;
parameter DATA_WIDTH = 8;

reg                     clk_i;
reg                     rst_i;
reg                     soft_reset_i;
reg                     valid_i;
reg  [DATA_WIDTH-1:0]   data_i;

wire [CRC_SIZE-1:0]     crc_o;


//--------------------------------------------------
// DUT
//--------------------------------------------------

crc32_calc dut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .soft_reset_i(soft_reset_i),
    .valid_i(valid_i),
    .data_i(data_i),
    .crc_o(crc_o)
);


//--------------------------------------------------
// Clock Generation (100 MHz)
//--------------------------------------------------

initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
end


//--------------------------------------------------
// Task : Send One Byte
//--------------------------------------------------

task send_byte;
    input [7:0] data;
begin
    @(posedge clk_i);
    valid_i = 1;
    data_i  = data;

    @(posedge clk_i);
    valid_i = 0;

    $display("Time=%0t  Data=0x%02h  CRC=0x%08h",
              $time, data, crc_o);
end
endtask


//--------------------------------------------------
// Test Sequence
//--------------------------------------------------

initial begin

    rst_i        = 1;
    soft_reset_i = 0;
    valid_i      = 0;
    data_i       = 0;

    #20;
    rst_i = 0;

    // Send some bytes
    send_byte(8'h12);
    send_byte(8'h34);
    send_byte(8'h56);
    send_byte(8'h78);

    // Soft Reset
    @(posedge clk_i);
    soft_reset_i = 1;

    @(posedge clk_i);
    soft_reset_i = 0;

    // Send more data
    send_byte(8'hAA);
    send_byte(8'h55);
    send_byte(8'hFF);

    #20;

    $display("----------------------------------------");
    $display("Final CRC = 0x%08h", crc_o);
    $display("----------------------------------------");

    $finish;

end


//--------------------------------------------------
// Waveform Dump
//--------------------------------------------------

initial begin
    $dumpfile("crc32.vcd");
    $dumpvars(0, crc32_calc_tb);
end

endmodule
 
