//interface
// -- is a construct that bundles all the signals required for communication between DUT and TB into single container,
// simplyfying connectivity and reducing port declartion,
// can also have clocking blocks , modport and task and functions.

interface apb_if #(
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32
	)(input logic pclk);

	//global signals
	
	logic presetn;

	//control signals
	
	logic transfer;
	logic read;
	logic write;
	logic [ADDR_WIDTH -1 :0] apb_paddr;
	logic [DATA_WIDTH -1 :0] apb_write_data;

	//slave response
	
	logic [DATA_WIDTH-1 :0] prdata;
	logic pready;
	logic pslverr;
	
	//APB OUTPUT SIGNALS
	
	logic psel;
	logic penable;
	logic pwrite;
	logic [ADDR_WIDTH-1 :0] paddr;
	logic [DATA_WIDTH-1 :0] pwdata;

	//read response
	
	logic [DATA_WIDTH -1 :0] apb_read_data_out;
	logic apb_read_data_valid;
	
	logic [DATA_WIDTH -1:0] mem [0:255];


//clocking block
//responsibilites are: drive stimulus to DUT, synchronize with DUT clock

//"All signal sampling and driving performed through this clocking block 
//will be synchronized with the positive edge of pclk."

clocking drv_cb @(posedge pclk);
	default input #1step output #0;

	//DRIVER --> DUT

	output transfer;
	output write;
	output read;
	output apb_paddr;
	output apb_write_data;
	
	//SLAVE --> DRIVER
	
/*	input pready;
	input pslverr;
	input prdata;
*/
endclocking




  // DUT Modport

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

	output mem,
        output apb_read_data_out,
        output apb_read_data_valid
    );

  endinterface
