class apb_monitor extends uvm_monitor;
	
	virtual apb_interface vif;
	apb_trans tr;
	
	`uvm_component_utils(apb_monitor)

	uvm_analysis_port #(apb_trans) ap;	//ap is analysis port tlm object -- it is not created autimatically
	
	function new(string name = "apb_monitor" ,
			uvm_component parent);
		super.new(name , parent);
		ap = new("ap" , this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(virtual apb_interface) ::get(
				this,
				"",
				"vif",
				vif))
			`uvm_fatal("MON" , "VIRTUAL INTERFACE NOT FOUND")
	endfunction

	task run_phase(uvm_phase phase);

		forever begin
			@(posedge vif.pclk);

			if(vif.psel && vif.penable && vif.pready) begin
				tr = apb_trans::type_id::create("tr");
				tr.transfer = vif.transfer;
				tr.write    = vif.write;
				tr.read = vif.read;
				tr.apb_paddr = vif.apb_paddr;
				tr.apb_write_data = vif.apb_write_data;

				tr.prdata = vif.prdata;
				tr.pready = vif.pready;
				tr.pslverr = vif.pslverr;
				
				//reconstructing pin level signals from interface to transaction level again

				ap.write(tr);
			end
		end
	endtask
endclass

