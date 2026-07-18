interface apb_interface #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32) (
	
	input logic pclk);

//logic pclk;
logic presetn;

logic transfer;
logic write;
logic read;
logic [ADDR_WIDTH -1 :0] apb_paddr;
logic [DATA_WIDTH -1 :0] apb_write_data;

logic [DATA_WIDTH -1 :0] prdata;
logic pready;
logic pslverr;

logic psel;
logic penable;
logic pwrite;
logic [ADDR_WIDTH -1 :0] paddr;
logic [DATA_WIDTH -1 :0] pwdata;

logic [DATA_WIDTH-1:0] apb_read_data_out;
logic apb_read_data_valid;

//driver clocking block
//it defines -- how the driver accesses signals on every positive edge. -- to
//prevent race condition.

clocking drv_cb @(posedge pclk);

	default input #1step output #0;

	output transfer;
        output write;	
        output read;	
        output apb_paddr;	
        output apb_write_data;

	input apb_read_data_out;
	input apb_read_data_valid;

endclocking

clocking slave_cb @(posedge pclk);

	default input #1step output #0;
	input  psel;
        input  penable;
        input  pwrite;
        input  paddr;
        input  pwdata;

	output pready;
	output pslverr;
	output prdata;

endclocking

modport DUT (
	input  pclk,
        input  presetn,

        input  transfer,
        input  read,
        input  write,
        input  apb_paddr,
        input  apb_write_data,

        input  prdata,
        input  pready,
        input  pslverr,

        output psel,
        output penable,
        output pwrite,
        output paddr,
        output pwdata,

        output apb_read_data_out,
        output apb_read_data_valid
	);

modport DRIVER(
	clocking drv_cb,
	input pclk,
	input presetn
	);

modport SLAVE(
        clocking slave_cb,
        input pclk,
        input presetn
    );

 modport MONITOR(

        input pclk,
        input presetn,

        input transfer,
        input read,
        input write,
        input apb_paddr,
        input apb_write_data,

        input psel,
        input penable,
        input pwrite,
        input paddr,
        input pwdata,

        input prdata,
        input pready,
        input pslverr,

        input apb_read_data_out,
        input apb_read_data_valid

    );

endinterface

