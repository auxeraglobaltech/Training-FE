//The driver drives transactions onto the APB interface. The DUT responds according to those inputs. 
//The monitor passively observes all interface activity--both the requests and the responses --and
// reconstructs complete APB transactions from the actual bus signals before broadcasting them 
// to components like the scoreboard and coverage collector.


class apb_monitor extends uvm_monitor;

	`uvm_component_utils(apb_monitor)

	virtual apb_if vif;

	uvm_analysis_port #(apb_trans) ap;

	function new(string name = "apb_monitor" , uvm_component parent);
		super.new(name , parent);

		//create this analysis port owned by monitor
		ap = new("ap" , this);	//just a tlm object so new -- this refers to current object which is currenty instance of apb_monitor
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db #(virtual apb_if) :: get(
				this,
				"",
				"vif",
				vif
		))
			`uvm_fatal("MON" , "FALED TO GET VIRTUAL INTERFACE")
	endfunction


	task run_phase(uvm_phase phase);
		forever begin
			@(posedge vif.pclk);

			if(vif.psel && 
				vif.penable && 
				vif.pready) begin

				apb_trans tr;

				tr = apb_trans ::type_id::create("tr");

				tr.transfer = vif.psel;
				tr.apb_paddr = vif.paddr;
				tr.pready   = vif.pready;
				tr.pslverr   = vif.pslverr;

				if(vif.pwrite) begin
				//	tr.apb_paddr = vif.paddr;
					tr.write = 1;
					tr.read = 0;
					tr.apb_write_data = vif.pwdata;
				end
				else begin
					tr.write = 0;
					tr.read = 1;
					tr.prdata = vif.prdata;
				end

				ap.write(tr);

				`uvm_info("MONITOR",
          				$sformatf("Observed APB Transaction:\n%s", tr.sprint()),
          				UVM_MEDIUM)
			end
		end
	endtask
endclass   
