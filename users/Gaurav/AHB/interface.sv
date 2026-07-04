interface ahb_if(input bit HCLK);

    logic 	  HRESETn;
    logic         HSEL;
    logic [31:0]  HADDR;
    logic [1:0]   HTRANS;
    logic         HWRITE;
    logic [2:0]   HSIZE;
    logic [2:0]   HBURST;
    logic [31:0]  HWDATA;
    logic         HREADYin;

    logic [31:0]  HRDATA;
    logic [1:0]   HRESP;
    logic         HREADYout;

    clocking drv_cb @(posedge HCLK);

	default input #1step output #0;

        output HSEL;
        output HADDR;
        output HTRANS;
        output HWRITE;
        output HSIZE;
        output HBURST;
        output HWDATA;
        output HREADYin;

        input HRDATA;
        input HRESP;
        input HREADYout;

    endclocking

    clocking mon_cb @(posedge HCLK);
	
	default input #1step;

        input HSEL;
        input HADDR;
        input HTRANS;
        input HWRITE;
        input HSIZE;
        input HBURST;
        input HWDATA;
        input HREADYin;

        input HRDATA;
        input HRESP;
        input HREADYout;

    endclocking

    modport DRIVER
    (
        clocking drv_cb,
        input HCLK,
        input HRESETn
    );

    modport MONITOR
    (
        clocking mon_cb,
        input HCLK,
        input HRESETn
    );

endinterface
