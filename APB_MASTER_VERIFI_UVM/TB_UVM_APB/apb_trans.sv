//TRANSACTION - is a packet of information(data object) contain all fields that represents one transfer. and 
//SEQUENCE - is an object that generates and randomize(if needed) and sends the transactions to the sequencer.
class apb_trans extends uvm_sequence_item;

	`uvm_object_utils(apb_trans)

	function new(string name= "apb_trans");
		super.new(name);
	endfunction

	//request fields
	rand bit transfer;
	rand bit write;
	rand bit read;
	rand bit [31:0] apb_paddr;
	rand bit [31:0] apb_write_data;

	//response fields
	bit [31:0] prdata;
	bit pready;
	bit pslverr;

	//constraints
	
	constraint read_write_c{
		read != write;
	}
	constraint transfer_c{
		if(transfer == 0)
			{
				read == 0;
				write == 0;
			}
	}
	constraint addr_align_c{
		apb_paddr [1:0] == 2'b00;
	}
	constraint addr_range_c{
		apb_paddr inside {[32'h0 : 32'h3FC]};
	}
endclass



//"Why do we need sequences if we already have transactions?"
//
// A transaction represents a single protocol operation, while a sequence defines the verification scenario by generating and ordering one or more transactions. The sequence controls how transactions are created, randomized, and sent for execution.
