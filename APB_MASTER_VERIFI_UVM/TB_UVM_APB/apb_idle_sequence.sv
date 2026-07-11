class apb_idle_sequence extends uvm_sequence #(apb_trans);

	apb_trans tr;

	`uvm_object_utils(apb_idle_sequence)

	function new(string name = "apb_idle_sequence");
		super.new(name);
	endfunction

	task body();

		repeat(3) begin

			tr = apb_trans ::type_id::create("tr");
			start_item(tr);
				assert(tr.randomize() with 
				{
					transfer == 0;
					write == 0;
					read == 0;
				})
				else 
					`uvm_error("SEQ", "Randomization failed")
			finish_item(tr);
		end
	endtask
endclass
