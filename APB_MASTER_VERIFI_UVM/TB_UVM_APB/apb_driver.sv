class apb_driver extends uvm_driver #(apb_trans);
	`uvm_component_utils(apb_driver)
		
	//VIRTUAL INTERFACE
	//Since UVM components like the driver are class-based and classes cannot directly access module or interface instances,
	// we declare a virtual interface.
	//  A virtual interface is a handle (or reference) that points to the actual interface instance
	//   created in the top module. 
	//   It allows the driver to access and drive the signals of the real interface without creating another interface instance.
	
	 virtual apb_if vif;

	//transaction handle 
	
	apb_trans tr;

	//consructor
	
	function new(string name = "apb_driver" , uvm_component parent);
		super.new(name , parent);
	endfunction

	//BUILD PHASE  
	// build_phase() is a UVM phase function that executes at zero simulation time before the test starts running.
	// Its primary purpose is to: 
			// Create child components (-- builds hierarchy)
			// Retrieve configuration information. (retrieving the virtual interface)
		// Perform component initialization.

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

//Go to the configuration database and search for an entry named vif. If you find it, assign that handle to my local variable vif."n
		if(!uvm_config_db #(virtual apb_if) :: get(
			this,
			"",
			"vif",
			vif) )
			`uvm_fatal("DRV" , "VIRTUAL INTERFACE NOT FOUND")
		endfunction
		

	//RUN PHASE
	
	task run_phase(uvm_phase phase);

		forever begin
			//GET SEQUENCES FROM SEQUECER 
			seq_item_port.get_next_item(tr);
				drive(tr);
			seq_item_port.item_done();
		end
	endtask

	task drive(apb_trans tr);
		@(vif.drv_cb);

		vif.drv_cb.transfer <= tr.transfer;
		vif.drv_cb.read     <= tr.read;
		vif.drv_cb.write    <= tr.write;
		vif.drv_cb.apb_paddr <= tr.apb_paddr;
		vif.drv_cb.apb_write_data <= tr.apb_write_data;
	endtask
	
endclass
