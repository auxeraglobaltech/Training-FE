  //Store written addresses and burst length
  // bit [31:0] wr_addr_q[$];
  // bit [7:0]  wr_len_q[$];
    /* task body();
   //5 Write Burst Transactions
   repeat(5)
     begin

     txn = axi_seq_item::type_id::create("txn");

      start_item(txn);

     assert( txn.randomize () with {
         write==1;
         //alligned address range
         awaddr inside
        {[32'h0000_0000:
          32'h0000_00FF]};
          //increment burst
          awburst == 2'b01;

         })
     //Save write address
     wr_addr_q.push_back(txn.awaddr);
     wr_len_q.push_back(txn.awlen);
     
     finish_item(txn);
   `uvm_info("SEQ",$sformatf("Write :addr=%0h len=%0d ",txn.awaddr,txn.awlen),UVM_LOW)
    end
    //5 Read Burst Transactions
   #200ns;
   foreach(wr_addr_q[i]) 
    begin
    txn = axi_seq_item::type_id::create("txn");
     start_item(txn);

     assert( txn.randomize () with {
         write==0;
         //alligned address range
         araddr inside
        {[32'h0000_0000:
          32'h0000_00FF]};
          //increment burst
          arburst == 2'b01;
            araddr == wr_addr_q[i];
            arlen ==wr_len_q[i];

         })
 finish_item(txn);
   `uvm_info("SEQ",$sformatf("Read :addr=%0h len=%0d ",txn.araddr,txn.arlen),UVM_LOW)
    end
endtask*/
class axi_seq extends uvm_sequence#(axi_seq_item);
  `uvm_object_utils(axi_seq)
      //constructor
  function new(string name="axi_seq");
     super.new();
  endfunction
task body();
 `uvm_info("BASE_SEQ","Base sequence body",UVM_LOW)
endtask
endclass


class axi_incr_unaligned_sequence extends axi_seq;
  `uvm_object_utils(axi_incr_unaligned_sequence)
      //constructor
 axi_seq_item txn;
  function new(string name="axi_incr_unaligned_sequence");
     super.new();
  endfunction
task body();
bit [31:0] wr_addr;
bit [7:0]  wr_len;
repeat(5) begin

    // WRITE
    txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 1;
      awaddr inside {[32'h0:32'hff]};
      awburst == 2'b01;
       awaddr % (2**awsize) != 0;

    });
    wr_addr = txn.awaddr;
    wr_len  = txn.awlen;
    finish_item(txn);
   `uvm_info("SEQ2",$sformatf("INCR Unaligned Write :addr=%0h len=%0d ",wr_addr,wr_len),UVM_LOW)
   txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 0;
      araddr  == wr_addr;
      arlen   == wr_len;
      arburst == 2'b01;
    });
    finish_item(txn);
   `uvm_info("SEQ",$sformatf("INCR Unaligned Read :addr=%0h len=%0d ",txn.araddr,txn.arlen),UVM_LOW)
   end
endtask
endclass
class axi_incr_aligned_sequence extends axi_seq;
  `uvm_object_utils(axi_incr_aligned_sequence)
      //constructor
 axi_seq_item txn;
  function new(string name="axi_incr_aligned_sequence");
     super.new();
  endfunction
task body();
bit [31:0] wr_addr;
bit [7:0]  wr_len;
repeat(5) begin

    // WRITE
    txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 1;
      awaddr inside {[32'h0:32'hff]};
      awburst == 2'b01;
       awaddr % (2**awsize) == 0;

    });
    wr_addr = txn.awaddr;
    wr_len  = txn.awlen;
    finish_item(txn);
   `uvm_info("SEQ2",$sformatf("INCR aligned Write :addr=%0h len=%0d ",wr_addr,wr_len),UVM_LOW)
   txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 0;
      araddr  == wr_addr;
      arlen   == wr_len;
      arburst == 2'b01;
    });
    finish_item(txn);
   `uvm_info("SEQ",$sformatf("INCR aligned Read :addr=%0h len=%0d ",txn.araddr,txn.arlen),UVM_LOW)
   end
endtask

endclass

class axi_fixed_aligned_sequence extends axi_seq;
  `uvm_object_utils(axi_fixed_aligned_sequence)
      //constructor
 axi_seq_item txn;
  function new(string name="axi_fixed_aligned_sequence");
     super.new();
  endfunction
task body();
bit [31:0] wr_addr;
bit [7:0]  wr_len;
repeat(5) begin

    // WRITE
    txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 1;
      awaddr inside {[32'h0:32'hff]};
      awburst == 2'b00;
       awaddr % (2**awsize) == 0;

    });
    wr_addr = txn.awaddr;
    wr_len  = txn.awlen;
    finish_item(txn);
   `uvm_info("SEQ2",$sformatf("Fixed aligned Write :addr=%0h len=%0d ",wr_addr,wr_len),UVM_LOW)
   txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 0;
      araddr  == wr_addr;
      arlen   == wr_len;
      arburst == 2'b00;
    });
    finish_item(txn);
   `uvm_info("SEQ",$sformatf("Fixed aligned Read :addr=%0h len=%0d ",txn.araddr,txn.arlen),UVM_LOW)
   end
endtask
endclass
class axi_wrap_aligned_sequence extends axi_seq;
  `uvm_object_utils(axi_wrap_aligned_sequence)
      //constructor
 axi_seq_item txn;
  function new(string name="axi_wrap_aligned_sequence");
     super.new();
  endfunction
task body();
bit [31:0] wr_addr;
bit [7:0]  wr_len;
repeat(5) begin

    // WRITE
    txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 1;
      awaddr inside {[32'h0:32'hff]};
      awburst == 2'b10;
       awaddr % (2**awsize) == 0;

    });
    wr_addr = txn.awaddr;
    wr_len  = txn.awlen;
    finish_item(txn);
   `uvm_info("SEQ2",$sformatf("Wrap aligned Write :addr=%0h len=%0d ",wr_addr,wr_len),UVM_LOW)
   txn = axi_seq_item::type_id::create("txn");

    start_item(txn);
    assert(txn.randomize() with {
      write   == 0;
      araddr  == wr_addr;
      arlen   == wr_len;
      arburst == 2'b10;
    });
    finish_item(txn);
   `uvm_info("SEQ",$sformatf("Wrap aligned Read :addr=%0h len=%0d ",txn.araddr,txn.arlen),UVM_LOW)
   end
endtask
endclass
/*class axi_5write_5read_sequence extends axi_seq;

  `uvm_object_utils(axi_5write_5read_sequence)

  function new(string name = "axi_5write_5read_sequence");
    super.new(name);
  endfunction
   task body();
   axi_seq_item txn;
   bit [31:0] wr_addr_q[$];
   bit [7:0]  wr_len_q[$];
   bit [1:0]  wr_burst_q[$];
   bit [3:0]  wr_id_q[$];
   repeat(5) begin

      txn = axi_seq_item::type_id::create("txn");

      start_item(txn);

      assert(txn.randomize() with {

        write == 1;
        awburst == 2'b01;
        awaddr % (2**awsize) == 0;
    });
      //finish_item(txn);
      wr_addr_q.push_back(req.awaddr);
      wr_len_q.push_back(req.awlen);
      wr_burst_q.push_back(req.awburst);
      wr_id_q.push_back(req.awid);
   `uvm_info("SEQ",$sformatf("Write Burst:addr=%0h len=%0d burst=%0b id=%0d",txn.awaddr,txn.awlen,txn.awburst,txn.awid),UVM_LOW)
      finish_item(txn);
      end

      //Read Same 5 bursts
      foreach(wr_addr_q[i]) begin

      txn = axi_seq_item::type_id::create("txn");

      start_item(txn);
       assert(txn.randomize() with {

        write == 0;

        araddr  == wr_addr_q[i];
        arlen   == wr_len_q[i];
        arburst == wr_burst_q[i];
        arid    == wr_id_q[i];

      });
   `uvm_info("SEQ",$sformatf("Read Burst:addr=%0h len=%0d burst=%0b id=%0d",txn.araddr,txn.arlen,txn.arburst,txn.arid),UVM_LOW)
   finish_item(txn);
   end
   endtask
   endclass*/





 
