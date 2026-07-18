class apb_read_seq extends apb_base_seq;

	`uvm_object_utils(apb_read_seq)

	apb_trans tr;

	function new(string name = "apb_read_seq");
		super.new(name);
	endfunction

//virtual task body();
	task body();


		repeat(10) begin
			tr = apb_trans::type_id::create("tr");
			
			start_item(tr);
				assert(tr.randomize()with {
					transfer == 1;
					write 	 == 0;
					read 	 == 1;
					})

			else
				`uvm_error(get_type_name(), "Randomization failed")
			finish_item(tr);
		end
	endtask
endclass

