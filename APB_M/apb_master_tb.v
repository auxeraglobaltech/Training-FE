`timescale 1ns/1ps

module apb_master_tb;

reg         PCLK;
reg         PRESETn;

wire        PSEL;
wire        PENABLE;
wire [31:0] PADDR;
wire        PWRITE;
wire [31:0] PWDATA;

reg  [31:0] PRDATA;
reg         PREADY;
reg         PSLVERR;

//------------------------------------------
// DUT
//------------------------------------------

apb_master dut
(
    .PCLK(PCLK),
    .PRESETn(PRESETn),

    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),

    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR)
);

//------------------------------------------
// Clock Generation
//------------------------------------------

initial
begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
end

//------------------------------------------
// Reset
//------------------------------------------

initial
begin
    PRESETn = 0;
    #20;
    PRESETn = 1;
end

//------------------------------------------
// Slave Model
//------------------------------------------

initial
begin
    PRDATA   = 32'h12345678;
    PREADY   = 1'b1;
    PSLVERR  = 1'b0;
end

//------------------------------------------
// Generate Wait States
//------------------------------------------

initial
begin

    #80;

    PREADY = 0;

    #30;

    PREADY = 1;

end

//------------------------------------------
// Generate Error
//------------------------------------------

initial
begin

    #170;

    PSLVERR = 1;

    #10;

    PSLVERR = 0;

end

//------------------------------------------
// Change Read Data
//------------------------------------------

always @(posedge PCLK)
begin

    if(PSEL && PENABLE && !PWRITE && PREADY)
        PRDATA <= PRDATA + 32'h10;

end

//------------------------------------------
// Monitor
//------------------------------------------

initial
begin

$display("---------------------------------------------------------------");
$display("TIME\tSTATE\tPSEL PENABLE PWRITE PADDR\t\tPWDATA\t\tPREADY");
$display("---------------------------------------------------------------");

$monitor("%0t\t%b\t%b\t%b\t%b\t%h\t%h\t%b",
        $time,
        dut.state,
        PSEL,
        PENABLE,
        PWRITE,
        PADDR,
        PWDATA,
        PREADY);

end

//------------------------------------------
// Dump Waveform
//------------------------------------------

initial
begin
    $dumpfile("apb_master.vcd");
    $dumpvars(0,apb_master_tb);
end

//------------------------------------------
// Finish Simulation
//------------------------------------------

initial
begin
    #400;
    $finish;
end

endmodule
