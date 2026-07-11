
import uvm_pkg::*;
import apb_pkg::*;
`include "uvm_macros.svh"

module top;
	
	logic pclk; 
	always #5 pclk = ~pclk;

//interface

	apb_if apb_vif(pclk);

initial begin
	pclk = 0;

	apb_vif.presetn = 0;

	#20;
	apb_vif.presetn = 1;

end

//DUT INSTANTIATION

	apb_master dut(
		.pclk(apb_vif.pclk),
		.presetn(apb_vif.presetn),

		.transfer(apb_vif.transfer),
		.read(apb_vif.read),
		.write(apb_vif.write),

		.apb_paddr(apb_vif.apb_paddr),
		.apb_write_data(apb_vif.apb_write_data),

		.prdata(apb_vif.prdata),
		.pready(apb_vif.pready),
		.pslverr(apb_vif.pslverr),

		.psel(apb_vif.psel),
		.penable(apb_vif.penable),
		.pwrite(apb_vif.pwrite),

		.paddr(apb_vif.paddr),
		.pwdata(apb_vif.pwdata),

		.apb_read_data_out(apb_vif.apb_read_data_out),
		.apb_read_data_valid(apb_vif.apb_read_data_valid)
	);

//slave response

assign apb_vif.pready = 1'b1;
assign apb_vif.pslverr = 1'b0;
assign apb_vif.prdata = 32'h0;


//UVM START

initial begin

	uvm_config_db #(virtual apb_if) ::set(
		null,
		"*",
		"vif",
		apb_vif
	);

	run_test("apb_test");
end


initial begin
$shm_open("wave.shm");  
$shm_probe("ACTMF");
end
endmodule
