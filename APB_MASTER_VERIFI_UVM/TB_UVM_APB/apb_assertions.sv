module apb_assertions
(
    input logic        pclk,
    input logic        presetn,

    input logic        transfer,
    input logic        read,
    input logic        write,

    input logic        psel,
    input logic        penable,
    input logic        pwrite,

    input logic        pready,
    input logic        pslverr,

    input logic [31:0] paddr,
    input logic [31:0] pwdata,
    input logic [31:0] prdata
);


 	property penable_requires_psel;
        	@(posedge pclk)
        	disable iff(!presetn)
        	penable |-> psel;
    	endproperty

    	apb_penable_requires_psel :
        	assert property(penable_requires_psel)
        	else
            		$error("[APB_ASSERT] PENABLE asserted without PSEL.");

    	property setup_to_access;
    		@(posedge pclk)
    		disable iff(!presetn)
    		(psel && !penable) |=> penable;
    	endproperty

    	apb_setup_to_access :
		assert property(setup_to_access)
		else
    	    		$error("[APB_ASSERT] ACCESS phase did not follow SETUP phase.");
   
    	property addr_stable_during_access;
    		@(posedge pclk)
    		disable iff(!presetn)
    		(psel && penable && !pready) |=> $stable(paddr);
    	endproperty

    	apb_addr_stable :
		assert property(addr_stable_during_access)
		else
    	    		$error("[APB_ASSERT] PADDR changed during ACCESS.");
    
    	property pwrite_stable;
    		@(posedge pclk)
    		disable iff(!presetn)
    		(psel && penable && !pready) |=> $stable(pwrite);
    	endproperty

    	apb_pwrite_stable :
		assert property(pwrite_stable)
		else
    	   		$error("[APB_ASSERT] PWRITE changed during ACCESS.");

    	property pwdata_stable;
    		@(posedge pclk)
    		disable iff(!presetn)
    		(psel && penable && pwrite && !pready) |=> $stable(pwdata);
    	endproperty

    	apb_pwdata_stable :
		assert property(pwdata_stable)
		else
    	   		$error("[APB_ASSERT] PWDATA changed during WRITE ACCESS.");

     	property read_write_exclusive;
    		@(posedge pclk)
    		disable iff(!presetn)
    		!(read && write);
	endproperty

	apb_rw_exclusive :
		assert property(read_write_exclusive)
		else
    			$error("[APB_ASSERT] READ and WRITE asserted together.");

	property no_penable_in_idle;
    		@(posedge pclk)
    		disable iff(!presetn)
    		(!psel) |-> (!penable);
	endproperty

	apb_no_penable_idle :
		assert property(no_penable_in_idle)
		else
    			$error("[APB_ASSERT] PENABLE asserted while PSEL is LOW.");

endmodule
