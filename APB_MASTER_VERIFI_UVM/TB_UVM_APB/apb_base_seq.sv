class apb_base_seq extends uvm_sequence #(apb_trans);
	`uvm_object_utils(apb_base_seq)

	function new(string name = "apb_base_seq");
		super.new(name);
	endfunction
	//no task body meant -- base sequence is "not meant to run".
	//keeps class simple
	//every functional sequence implement its body() 
endclass

