class ahb_scoreboard extends uvm_scoreboard;

   `uvm_component_utils(ahb_scoreboard)

   uvm_analysis_imp #(ahb_xtn, ahb_scoreboard) analysis_imp;


   function new(string name="ahb_scoreboard",uvm_component parent=null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      analysis_imp = new("analysis_imp", this);

      `uvm_info(get_type_name(),"Scoreboard Build Phase Completed",UVM_LOW)
   endfunction

   function void write(ahb_xtn tr);

      `uvm_info(get_type_name(),$sformatf("\nReceived Transaction\n%s",tr.convert2string()),UVM_MEDIUM)

      if(tr.HRESP != 2'b01)
         `uvm_error(get_type_name(),$sformatf("HRESP Mismatch! Expected=01 Got=%b",tr.HRESP))
      else
         `uvm_info(get_type_name(),"HRESP Check Passed",UVM_LOW)

      if(tr.HREADYout != 1'b1)
         `uvm_error(get_type_name(),$sformatf("HREADYout Mismatch! Expected=1 Got=%b",tr.HREADYout))
      else
         `uvm_info(get_type_name(),"HREADYout Check Passed",UVM_LOW)

      if(!tr.HWRITE)
      	begin
         	if(tr.HRDATA != 32'h00000000)
            		`uvm_error(get_type_name(),$sformatf("HRDATA Mismatch! Expected=00000000 Got=%h",tr.HRDATA))
         	else
            		`uvm_info(get_type_name(),"HRDATA Check Passed",UVM_LOW)
      	end

   endfunction

endclass
