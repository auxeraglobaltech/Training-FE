class apb_sequence extends uvm_sequence #(apb_trans);
	
	apb_trans tr;	//handle of the class apb_trans
	
	`uvm_object_utils(apb_sequence)
	
	//"This macro registers the apb_sequence class with the UVM factory so that objects of this class can be created
	// using type_id::create() and can participate in factory overrides."
	
//	Since we inherit from uvm_sequence, that class already has its own constructor.
//	we are saying: "Call the constructor of my parent class (uvm_sequence) so it can initialize everything it owns."
//	MAIN PURPOSE IS: used to initialize the object. we are doing is letting
//	base class initialize itself properly.

	function new(string name = "apb_sequence");
		super.new(name);
	endfunction

	
	
		task body();

		repeat(20)begin
			
			
			tr = apb_trans ::type_id ::create("tr"); 	//fresh object for tr handle is created for each transfer
			
			start_item(tr);
				assert(tr.randomize() with {
					 transfer == 1 ;
					 write == 1 ;
					read == 0; 
				})
				else 
					`uvm_error("SEQ" , "Randomization failed")
			finish_item(tr);
		end
	endtask

endclass
