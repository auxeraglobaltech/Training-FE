class apb_sequencer extends uvm_sequencer #(apb_trans);

	`uvm_component_utils(apb_sequencer)

	apb_trans tr;

	function new(string name = "apb_sequencer" , 
			uvm_component parent);
		super.new(name , parent);
	endfunction

endclass

