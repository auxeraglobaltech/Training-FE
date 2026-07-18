class apb_trans extends uvm_sequence_item;
	
	`uvm_object_utils(apb_trans)

	function new(string name = "apb_trans");
		super.new(name);
	endfunction
	
	rand bit transfer;
	rand bit write;
	rand bit read;

	rand bit [31:0] apb_paddr;
	rand bit [31:0] apb_write_data;
	
	bit [31:0] prdata;
	bit pready;
	bit pslverr;

//constraints

	constraint rw_c {
        read != write;
    }

    constraint transfer_c {
        if(!transfer){
            read == 0;
            write == 0;
        }
    }
/*
    constraint addr_align_c {
        apb_paddr[1:0] == 2'b00;
    }
*/
    constraint addr_range_c {
        apb_paddr inside {[32'h0000_0000 : 32'h0000_03FC]};
    }

endclass

