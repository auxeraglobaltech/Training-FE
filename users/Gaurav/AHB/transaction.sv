class ahb_xtn extends uvm_sequence_item;

    rand bit         HSEL;
    rand bit [31:0]  HADDR;
    rand bit [1:0]   HTRANS;
    rand bit         HWRITE;
    rand bit [2:0]   HSIZE;
    rand bit [2:0]   HBURST;
    rand bit [31:0]  HWDATA;
    rand bit         HREADYin;


    bit [31:0] HRDATA;
    bit [1:0]  HRESP;
    bit        HREADYout;

    constraint c_hready {
        		HREADYin == 1;
    			}

    constraint c_htrans {
       	 		HTRANS inside {2'b00,2'b01,2'b10,2'b11};
    			}

    constraint c_hsize {
        		HSIZE inside {[0:2]};
    			}

    `uvm_object_utils_begin(ahb_xtn)

        `uvm_field_int(HSEL,      UVM_ALL_ON)
        `uvm_field_int(HADDR,     UVM_ALL_ON)
        `uvm_field_int(HTRANS,    UVM_ALL_ON)
        `uvm_field_int(HWRITE,    UVM_ALL_ON)
        `uvm_field_int(HSIZE,     UVM_ALL_ON)
        `uvm_field_int(HBURST,    UVM_ALL_ON)
        `uvm_field_int(HWDATA,    UVM_ALL_ON)
        `uvm_field_int(HREADYin,  UVM_ALL_ON)

        `uvm_field_int(HRDATA,    UVM_ALL_ON)
        `uvm_field_int(HRESP,     UVM_ALL_ON)
        `uvm_field_int(HREADYout, UVM_ALL_ON)

    `uvm_object_utils_end

    function new(string name="ahb_xtn");
        super.new(name);
    endfunction

    function string convert2string();

        return $sformatf(
            "HSEL=%0d HADDR=%h HTRANS=%0b HWRITE=%0d HSIZE=%0d HBURST=%0d HWDATA=%h HREADYin=%0d HRESP=%0b HREADYout=%0d HRDATA=%h",
            HSEL,
            HADDR,
            HTRANS,
            HWRITE,
            HSIZE,
            HBURST,
            HWDATA,
            HREADYin,
            HRESP,
            HREADYout,
	    HRDATA
        );

    endfunction

endclass

