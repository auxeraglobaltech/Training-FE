class ahb_monitor extends uvm_monitor;

   `uvm_component_utils(ahb_monitor)

   virtual ahb_if vif;

   uvm_analysis_port #(ahb_xtn) ap;

   function new(string name = "ahb_monitor", uvm_component parent);
      super.new(name,parent);
      ap=new("ap",this);
   endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
   
    if(!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) 
    `uvm_fatal("Monitor","interface is not set properly");
    `uvm_info("MONITOR","Build PHASE STARTED",UVM_LOW);
  endfunction

  task run_phase(uvm_phase phase);

        ahb_xtn tr;

        forever 
	begin

            	@(vif.mon_cb);

            	if(vif.mon_cb.HSEL && vif.mon_cb.HREADYin && (vif.mon_cb.HTRANS inside {2'b10,2'b11})) 
		
		begin

                tr = ahb_xtn::type_id::create("tr");

                tr.HSEL      = vif.mon_cb.HSEL;
                tr.HADDR     = vif.mon_cb.HADDR;
                tr.HTRANS    = vif.mon_cb.HTRANS;
                tr.HWRITE    = vif.mon_cb.HWRITE;
                tr.HSIZE     = vif.mon_cb.HSIZE;
                tr.HBURST    = vif.mon_cb.HBURST;
                tr.HREADYin  = vif.mon_cb.HREADYin;

		@(vif.mon_cb);

		if(tr.HWRITE)
    		tr.HWDATA = vif.mon_cb.HWDATA;

		while(!vif.mon_cb.HREADYout)
    		@(vif.mon_cb);

		tr.HRESP     = vif.mon_cb.HRESP;
		tr.HREADYout = vif.mon_cb.HREADYout;

		if(!tr.HWRITE)
    		tr.HRDATA = vif.mon_cb.HRDATA;

		$display("[%0t] MONITOR : HRESP=%b HREADYout=%b",$time,vif.mon_cb.HRESP,vif.mon_cb.HREADYout);

                ap.write(tr);

                `uvm_info(get_type_name(),tr.convert2string(),UVM_MEDIUM)

            	end

        end

    endtask

endclass

