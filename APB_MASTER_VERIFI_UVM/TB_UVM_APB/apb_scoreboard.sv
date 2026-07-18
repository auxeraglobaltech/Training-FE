//separate analysis implementations

`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class apb_scoreboard extends uvm_scoreboard;

	`uvm_component_utils(apb_scoreboard)
	
	uvm_analysis_imp_expected #(apb_trans , apb_scoreboard) expected_export;
	uvm_analysis_imp_actual #(apb_trans , apb_scoreboard) actual_export;
	

	//refernece memory

	bit[31:0] expected_mem [bit [31:0]];


	function new(string name = "apb_scoreboard" , 
			uvm_component parent);
		super.new(name , parent);
		expected_export = new("expected_export", this);
        	actual_export   = new("actual_export", this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
	//this function is automatically called whhen monitor sends:
	//ap.write(tr)

	// Expected transaction
    // Comes from driver

    function void write_expected(apb_trans tr);


        if(tr.write && tr.transfer)
        begin

            expected_mem[tr.apb_paddr] = tr.apb_write_data;


            `uvm_info("SCOREBOARD",
            $sformatf("Expected Write Stored : Addr=%0h Data=%0h",
            tr.apb_paddr,
            tr.apb_write_data),
            UVM_LOW)

        end


    endfunction


	// Actual transaction
    // Comes from monitor

    function void write_actual(apb_trans tr);


        if(tr.write && tr.transfer)
        begin


            if(expected_mem.exists(tr.apb_paddr))
            begin


                if(expected_mem[tr.apb_paddr] == tr.apb_write_data)
                begin

                    `uvm_info("SCOREBOARD",
                    "WRITE DATA MATCH : PASS",
                    UVM_LOW)

                end


                else
                begin

                    `uvm_error("SCOREBOARD",
                    $sformatf("WRITE DATA MISMATCH Expected=%0h Actual=%0h",
                    expected_mem[tr.apb_paddr],
                    tr.apb_write_data))

                end


            end


            else
            begin

                `uvm_error("SCOREBOARD",
                "ADDRESS NOT FOUND IN REFERENCE MEMORY")

            end


        end


    endfunction
endclass

