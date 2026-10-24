// SV end of the C <-> SV handshake (C end: sw/common/c2sv.h).
//
//   C stores C2SV_ARG, then C2SV_CMD    -> this component clears ACK and
//                                          queues {cmd, arg}
//   test calls get_cmd()                -> receives {cmd, arg}, runs its
//                                          own SV code for that step
//   test calls reply(cmd, data)         -> drives SV2C_DATA / SV2C_ACK,
//                                          which tb_top returns on C's
//                                          loads; C sees ACK == cmd and
//                                          continues
//
// The component only moves data; what each command means is decided by
// the test (ibex_base_test::handle_c_cmd and its overrides).
class ibex_c2sv_mbox extends uvm_component;
  `uvm_component_utils(ibex_c2sv_mbox)

  localparam logic [31:0] C2SV_CMD = 32'h0003_0010;
  localparam logic [31:0] C2SV_ARG = 32'h0003_0014;

  typedef struct {
    logic [31:0] cmd;
    logic [31:0] arg;
  } c2sv_req_t;

  virtual ibex_if      vif;
  mailbox #(c2sv_req_t) req_q;
  logic [31:0]         last_arg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_q = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ibex_if)::get(this, "", "vif", vif))
      `uvm_fatal("C2SV", "No virtual interface found in config_db")
  endfunction

  // Blocks until C issues the next command.
  task get_cmd(output logic [31:0] cmd, output logic [31:0] arg);
    c2sv_req_t req;
    req_q.get(req);
    cmd = req.cmd;
    arg = req.arg;
  endtask

  // Releases C: it is spinning until SV2C_ACK == cmd.
  task reply(logic [31:0] cmd, logic [31:0] data);
    @(posedge vif.clk);
    vif.sv2c_data <= data;
    vif.sv2c_ack  <= cmd;
  endtask

  task run_phase(uvm_phase phase);
    c2sv_req_t req;
    vif.sv2c_ack  <= '0;
    vif.sv2c_data <= '0;
    forever begin
      @(vif.mon_cb);
      if (vif.mon_cb.data_req && vif.mon_cb.data_we) begin
        case ({vif.mon_cb.data_addr[31:2], 2'b00})
          C2SV_ARG: last_arg = vif.mon_cb.data_wdata;
          C2SV_CMD: begin
            // Clear ACK first so a C test reusing the same cmd id can't
            // see the previous step's ACK and run ahead of SV.
            vif.sv2c_ack <= '0;
            req.cmd = vif.mon_cb.data_wdata;
            req.arg = last_arg;
            req_q.put(req);
          end
          default: ;
        endcase
      end
    end
  endtask

endclass
