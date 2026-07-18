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
class axi_outstanding_wr_rd_sequence extends axi_seq;
`uvm_object_utils(axi_outstanding_wr_rd_sequence)
 function new(string name="axi_outstanding_wr_rd_sequence");
    super.new(name);
  endfunction
 task body();

    axi_seq_item txn;

    bit [31:0] wr_addr_q[$];
    bit [7:0]  wr_len_q[$];
    bit [1:0]  wr_burst_q[$];
    bit [3:0]  wr_id_q[$];
    // 5 outstanding writes
    repeat(5) begin

      txn = axi_seq_item::type_id::create("txn");

      start_item(txn);

      assert(txn.randomize() with {
        write   == 1;
        awburst == 2'b01;          // INCR
        awlen inside {[0:7]};
        awaddr inside {[32'h0:32'hff]};
        awaddr % (2**awsize) == 0;
      });

      // assign unique IDs
      txn.awid = wr_id_q.size() + 1;
      txn.wid  = txn.awid;

      wr_addr_q.push_back(txn.awaddr);
      wr_len_q.push_back(txn.awlen);
      wr_burst_q.push_back(txn.awburst);
      wr_id_q.push_back(txn.awid);
  `uvm_info("SEQ",$sformatf("Outstanding Write id=%0d addr=%0h len=%0d",txn.awid,txn.awaddr,txn.awlen),UVM_LOW)
  finish_item(txn);
  end
    // 5 outstanding reads
  #1000ns;
    foreach(wr_addr_q[i]) begin

      txn = axi_seq_item::type_id::create("txn");

      start_item(txn);

      assert(txn.randomize() with {
        write   == 0;
        araddr  == wr_addr_q[i];
        arlen   == wr_len_q[i];
        arburst == wr_burst_q[i];
        arid    == wr_id_q[i];
      });
  `uvm_info("SEQ",$sformatf("Outstanding Read id=%0d addr=%0h len=%0d",txn.arid,txn.araddr,txn.arlen),UVM_LOW)
  finish_item(txn);
  end

  endtask

endclass
class axi_ooo_wr_rd_sequence extends axi_seq;
`uvm_object_utils(axi_ooo_wr_rd_sequence)
 function new(string name="axi_ooo_wr_rd_sequence");
    super.new(name);
  endfunction
   task body();

    axi_seq_item txn;

    bit [31:0] wr_addr_q[$];
    bit [7:0]  wr_len_q[$];
    bit [1:0]  wr_burst_q[$];
    bit [3:0]  wr_id_q[$];

    // Issue 5 writes with unique IDs
    repeat(5) begin

      txn = axi_seq_item::type_id::create("txn");

      start_item(txn);

      assert(txn.randomize() with {
        write   == 1;
        awburst == 2'b01;
        awlen inside {[0:7]};
        awaddr inside {[32'h0:32'hff]};
        awaddr % (2**awsize) == 0;
      });

      txn.awid = wr_id_q.size() + 1;
      txn.wid  = txn.awid;

      wr_addr_q.push_back(txn.awaddr);
      wr_len_q.push_back(txn.awlen);
      wr_burst_q.push_back(txn.awburst);
      wr_id_q.push_back(txn.awid);
    `uvm_info("SEQ",$sformatf("OOO Write id =%0d addr=%0h len=%0d ",txn.awid,txn.awaddr,txn.awlen),UVM_LOW)
    finish_item(txn);
     end
    // Issue 5 reads using same addr/len/id
#1000ns;
    foreach(wr_addr_q[i]) begin

      txn = axi_seq_item::type_id::create("txn");

      start_item(txn);

      assert(txn.randomize() with {
        write   == 0;
        araddr  == wr_addr_q[i];
        arlen   == wr_len_q[i];
        arburst == wr_burst_q[i];
        arid    == wr_id_q[i];
      });
      `uvm_info("SEQ",$sformatf("OOO READ id=%0d addr=%0h len=%0d",txn.arid,txn.araddr,txn.arlen),UVM_LOW)
      finish_item(txn);
      end
      endtask
      endclass

    




 
