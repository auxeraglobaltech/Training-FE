module top;
  
  import uvm_pkg::*;
  import ahb_pkg::*;
  `include "uvm_macros.svh"

  bit HCLK;
  bit HRESETn;
 
  ahb_default_slave dut (

    .HCLK    (HCLK),
    .HRESETn (HRESETn),
    .HSEL (ahb_intf.HSEL),
 
    .HADDR   (ahb_intf.HADDR),
    .HTRANS  (ahb_intf.HTRANS),
    .HWRITE  (ahb_intf.HWRITE),
    .HSIZE   (ahb_intf.HSIZE),
    .HBURST  (ahb_intf.HBURST),

    .HWDATA  (ahb_intf.HWDATA),

    .HRDATA  (ahb_intf.HRDATA),
    .HREADYin  (ahb_intf.HREADYin),
    .HREADYout (ahb_intf.HREADYout),
    .HRESP   (ahb_intf.HRESP)
  );
  
  initial 
	begin
    		HCLK = 0;
    		forever #5 HCLK = ~HCLK;
  	end

  initial 
	begin
    		HRESETn = 0; 
		@(posedge HCLK);
    		HRESETn = 1;
  	end

  ahb_if ahb_intf(HCLK) ;

  assign ahb_intf.HRESETn = HRESETn;


  initial 
	begin
    		uvm_config_db#(virtual ahb_if)::set(null,"*","vif",ahb_intf);

   		run_test();
  	end
 
  initial
	begin
		$shm_open("wave.shm");  
		$shm_probe("ACTMF");
	end

endmodule
