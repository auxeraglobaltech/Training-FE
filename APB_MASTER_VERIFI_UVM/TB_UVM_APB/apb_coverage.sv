class apb_coverage extends uvm_subscriber #(apb_trans);

	`uvm_component_utils(apb_coverage)

	apb_trans tr;

	covergroup apb_cg;

		cp_transfer : coverpoint tr.transfer{
			bins idle = {0};
			bins transfer = {1};
		}

		cp_read : coverpoint tr.read {
			//bins idle = {0};
			bins read = {1};
		}
		
		cp_write : coverpoint tr.write {
			bins write = {1};
		}

		 // Address Coverage
        	
		 cp_addr : coverpoint tr.apb_paddr {
           	 	bins low_addr  = {[32'h0000_0000 : 32'h0000_00FC]};
            		bins mid_addr  = {[32'h0000_0100 : 32'h0000_01FC]};
            		bins high_addr = {[32'h0000_0200 : 32'h0000_03FC]};
        	}

        // PREADY Coverage
        	
		cp_pready : coverpoint tr.pready {
            		bins ready     = {1};
            		bins not_ready = {0};
        	}

        // PSLVERR Coverage
        
		cp_pslverr : coverpoint tr.pslverr {
            		bins no_error = {0};
            		bins error    = {1};
        	}

        // Cross Coverage

        	cross cp_write, cp_addr;

        	cross cp_read, cp_addr;

        	cross cp_write, cp_pready;

        	cross cp_read, cp_pready;

        	cross cp_write, cp_pslverr;

        	cross cp_read, cp_pslverr;	

	endgroup

    // Constructor

    function new(string name = "apb_coverage",
                 uvm_component parent);

        super.new(name,parent);

        apb_cg = new();

    endfunction

    // Receive transaction from Monitor

    function void write(apb_trans t);

        tr = t;

        apb_cg.sample();

    endfunction

    // Report Phase

    function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        `uvm_info(get_type_name(),
                  $sformatf("Functional Coverage = %0.2f%%",
                  apb_cg.get_coverage()),
                  UVM_LOW)

    endfunction

endclass



//COVERAGE OUTPUT 

/*
* UVM_INFO ./tb/apb_coverage.sv(91) @ 325000: uvm_test_top.env.cov [apb_coverage] Functional Coverage = 70.83%

--- UVM Report catcher Summary ---


Number of demoted UVM_FATAL reports  :    0
Number of demoted UVM_ERROR reports  :    0
Number of demoted UVM_WARNING reports:    0
Number of caught UVM_FATAL reports   :    0
Number of caught UVM_ERROR reports   :    0
Number of caught UVM_WARNING reports :    0

--- UVM Report Summary ---
*/
