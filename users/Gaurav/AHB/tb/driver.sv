class ahb_driver extends uvm_driver #(ahb_xtn);

   `uvm_component_utils(ahb_driver)

   virtual ahb_if vif;

   function new(string name = "ahb_driver", uvm_component parent);
      super.new(name,parent);
   endfunction

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);

    if(!uvm_config_db#(virtual ahb_if)::get(this, "", "vif",vif)) 
	`uvm_fatal("Driver","interface is not set properly");
    	`uvm_info("DRIVER","Build PHASE STARTED",UVM_LOW);
  endfunction

  task run_phase(uvm_phase phase);

      ahb_xtn req;

	forever 
		begin

         		seq_item_port.get_next_item(req);

         		drive_transfer(req);

         		seq_item_port.item_done();

      		end

   endtask

   task drive_transfer(ahb_xtn req);
//`ifndef SEQ
        @(vif.drv_cb);

        vif.drv_cb.HSEL      <= req.HSEL;
        vif.drv_cb.HADDR     <= req.HADDR;
        vif.drv_cb.HTRANS    <= req.HTRANS;
        vif.drv_cb.HWRITE    <= req.HWRITE;
        vif.drv_cb.HSIZE     <= req.HSIZE;
        vif.drv_cb.HBURST    <= req.HBURST;
        vif.drv_cb.HREADYin  <= req.HREADYin;

	@(vif.drv_cb);

   	if (req.HWRITE)
        vif.drv_cb.HWDATA <= req.HWDATA;

        `uvm_info(get_type_name(),
                  $sformatf("Driving Transaction:\n%s",req.convert2string()),UVM_MEDIUM)

        @(vif.drv_cb);
	//@(vif.drv_cb);
//`else




//`endif

    endtask
  

endclass
