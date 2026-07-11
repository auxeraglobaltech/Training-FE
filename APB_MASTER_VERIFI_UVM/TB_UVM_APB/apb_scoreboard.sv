class apb_scoreboard extends uvm_scoreboard;

	`uvm_component_utils(apb_scoreboard)

	uvm_analysis_imp #(apb_trans ,		//transaction type
	       			apb_scoreboard) 	//component implementing write()
		analysis_imp;

  // Statistics
    int total_txn;
    int pass_txn;
    int fail_txn;
	

	function new(string name  ="apb_screboard" , uvm_component parent);
		super.new(name , parent);

		analysis_imp = new("analysis_imp" , this);
	endfunction

	function void write(apb_trans tr);
		 
		total_txn++;

		`uvm_info("SCOREBOARD" , 
			      $sformatf("Received Transaction : \n%s" , 
				tr.sprint()),
				UVM_MEDIUM)

		//WRITE TRNASACTION CHECH

		if (tr.write) 	begin
		
			if(!tr.pready) begin
				fail_txn++;

				 `uvm_error("WRITE",
                           "Slave is not ready (PREADY = 0)")
		   end

		   else if(tr.pslverr) begin
			   fail_txn++;
			   
				`uvm_error("WRITE" , 
					"APB SLVE ERROR (PSLVERR = 1)")
				end

		else begin

			pass_txn++;


				`uvm_info("WRITE" , 
					$sformatf("WRITE VERIFIED: Addr = 0x%0h -- DATA= 0x%0h",
					tr.apb_paddr , tr.apb_write_data),
				UVM_LOW)
			end

		end
	endfunction


	function void report_phase(uvm_phase phase);

        		`uvm_info("SCOREBOARD",
                  		$sformatf("\n\
				-----------------------------------\n\
					APB SCOREBOARD SUMMARY\n\
				-----------------------------------\n\
					Total Transactions : %0d\n\
					Passed             : %0d\n\
					Failed             : %0d\n\
				-----------------------------------",
                  				total_txn,
                  				pass_txn,
                  				fail_txn),
                 		 UVM_NONE)

    endfunction



endclass
