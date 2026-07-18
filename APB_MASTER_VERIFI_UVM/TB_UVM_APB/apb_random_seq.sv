class apb_random_seq extends apb_base_seq;

	`uvm_object_utils(apb_random_seq)

	apb_trans tr;

	function new(string name = "apb_random_seq");
		super.new(name);
	endfunction

//virtual task body();
	task body();


		repeat(10) begin
			tr = apb_trans::type_id::create("tr");
			
			start_item(tr);
				assert (tr.randomize())

			else
				`uvm_error(get_type_name(), "Randomization failed")
			finish_item(tr);
		end
	endtask
endclass

