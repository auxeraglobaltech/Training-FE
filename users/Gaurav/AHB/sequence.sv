class ahb_base_sequence extends uvm_sequence #(ahb_xtn);

    `uvm_object_utils(ahb_base_sequence)

    function new(string name="ahb_base_sequence");
        super.new(name);
    endfunction

endclass

class ahb_reset_seq extends ahb_base_sequence;

    `uvm_object_utils(ahb_reset_seq)

    ahb_xtn req;

    function new(string name="ahb_reset_seq");
        super.new(name);
    endfunction

    task body();

        req = ahb_xtn::type_id::create("req");

        start_item(req);

        req.HSEL      = 0;
        req.HADDR     = 32'h0;
        req.HTRANS    = 2'b00;      // IDLE
        req.HWRITE    = 0;
        req.HSIZE     = 3'b000;
        req.HBURST    = 3'b000;
        req.HWDATA    = 32'h0;
        req.HREADYin  = 1;

        finish_item(req);

        `uvm_info(get_type_name(),"Reset sequence completed",UVM_LOW)

    endtask

endclass

class ahb_write_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_write_seq)

   ahb_xtn req;

   function new(string name="ahb_write_seq");
      super.new(name);
   endfunction

   task body();

      req = ahb_xtn::type_id::create("req");

      start_item(req);

      assert(req.randomize() with
      {
         HSEL      == 1;
         HREADYin  == 1;
         HTRANS    == 2'b10;      
         HWRITE    == 1;

         HADDR inside {[32'h0000_0000:32'h0000_00FF]};

         HSIZE  == 3'b010;        

         HBURST == 3'b000;        
      });

      finish_item(req);

      `uvm_info(get_type_name(),"WRITE sequence completed",UVM_LOW)

   endtask

endclass

class ahb_read_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_read_seq)

   ahb_xtn req;

   function new(string name="ahb_read_seq");
      super.new(name);
   endfunction

   task body();

      req = ahb_xtn::type_id::create("req");

      start_item(req);

      assert(req.randomize() with
      {
         HSEL      == 1;
         HREADYin  == 1;
         HTRANS    == 2'b10;     
         HWRITE    == 0;

         HADDR inside {[32'h1000_0000:32'h1000_00FF]};

         HSIZE  == 3'b010;
         HBURST == 3'b000;
      });

      finish_item(req);

      `uvm_info(get_type_name(),"READ sequence completed",UVM_LOW)

   endtask

endclass


class ahb_idle_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_idle_seq)

   ahb_xtn req;

   function new(string name="ahb_idle_seq");
      super.new(name);
   endfunction

   task body();

      req = ahb_xtn::type_id::create("req");

      start_item(req);

      assert(req.randomize() with
      {
         HSEL      == 1;
         HREADYin  == 1;
         HTRANS    == 2'b00;     
      });

      finish_item(req);

      `uvm_info(get_type_name(),"IDLE sequence completed",UVM_LOW)

   endtask

endclass

class ahb_random_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_random_seq)

   ahb_xtn req;

   function new(string name="ahb_random_seq");
      super.new(name);
   endfunction

   task body();

      req = ahb_xtn::type_id::create("req");

      start_item(req);

      assert(req.randomize());

      finish_item(req);

      `uvm_info(get_type_name(),"Random sequence completed",UVM_LOW)

   endtask

endclass

class ahb_back_to_back_write_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_back_to_back_write_seq)

   ahb_xtn req;

   function new(string name="ahb_back_to_back_write_seq");
      super.new(name);
   endfunction

   task body();

      repeat(10)
      begin

         req = ahb_xtn::type_id::create($sformatf("write_req_%0d",$time));

         start_item(req);

         assert(req.randomize() with
         {
            HSEL      == 1;
            HREADYin  == 1;
            HWRITE    == 1;
            HTRANS    == 2'b10;
            HSIZE     == 3'b010;
            HBURST    == 3'b000;

            HADDR inside {[32'h0:32'hFF]};
         });

         finish_item(req);

      end

      `uvm_info(get_type_name(),"Back-to-Back WRITE Sequence Completed",UVM_LOW)

   endtask

endclass

class ahb_back_to_back_read_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_back_to_back_read_seq)

   ahb_xtn req;

   function new(string name="ahb_back_to_back_read_seq");
      super.new(name);
   endfunction

   task body();

      repeat(10)
      begin

         req = ahb_xtn::type_id::create($sformatf("read_req_%0d",$time));

         start_item(req);

         assert(req.randomize() with
         {
            HSEL      == 1;
            HREADYin  == 1;
            HWRITE    == 0;
            HTRANS    == 2'b10;
            HSIZE     == 3'b010;
            HBURST    == 3'b000;

            HADDR inside {[32'h0:32'hFF]};
         });

         finish_item(req);

      end

      `uvm_info(get_type_name(),
      "Back-to-Back READ Sequence Completed",
      UVM_LOW)

   endtask

endclass

class ahb_mixed_rw_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_mixed_rw_seq)

   ahb_xtn req;

   function new(string name="ahb_mixed_rw_seq");
      super.new(name);
   endfunction

   task body();

      repeat(20)
      begin

         req = ahb_xtn::type_id::create("req");

         start_item(req);

         assert(req.randomize() with
         {
            HSEL      == 1;
            HREADYin  == 1;

            HTRANS    == 2'b10;

            HSIZE     == 3'b010;

            HBURST    == 3'b000;

            HADDR inside {[32'h0:32'hFF]};
         });

         finish_item(req);

      end

      `uvm_info(get_type_name(),"Mixed READ/WRITE Sequence Completed",UVM_LOW)

   endtask

endclass

class ahb_write_read_seq extends ahb_base_sequence;

   `uvm_object_utils(ahb_write_read_seq)

   ahb_xtn req;

   bit [31:0] addr;

   function new(string name="ahb_write_read_seq");
      super.new(name);
   endfunction

   task body();

      addr = $urandom_range(0,255);

      req = ahb_xtn::type_id::create("write_req");

      start_item(req);

      assert(req.randomize() with
      {
         HSEL      == 1;
         HREADYin  == 1;
         HWRITE    == 1;
         HTRANS    == 2'b10;
         HSIZE     == 3'b010;
         HBURST    == 3'b000;
         HADDR     == local::addr;
      });

      finish_item(req);

      req = ahb_xtn::type_id::create("read_req");

      start_item(req);

      assert(req.randomize() with
      {
         HSEL      == 1;
         HREADYin  == 1;
         HWRITE    == 0;
         HTRANS    == 2'b10;
         HSIZE     == 3'b010;
         HBURST    == 3'b000;
         HADDR     == local::addr;
      });

      finish_item(req);

      `uvm_info(get_type_name(),"WRITE followed by READ Completed",UVM_LOW)

   endtask

endclass
