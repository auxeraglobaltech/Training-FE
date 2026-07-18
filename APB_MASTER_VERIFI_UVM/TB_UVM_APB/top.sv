`timescale 1ns/1ps

module top;

    import uvm_pkg::*;
    import apb_pkg::*;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // Clock Generation

    logic pclk;

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    // Interface

    apb_interface #(ADDR_WIDTH, DATA_WIDTH) vif(pclk);

    // DUT INSTANTIATION

    apb_master #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (

        .pclk                (pclk),
        .presetn             (vif.presetn),

        .transfer            (vif.transfer),
        .read                (vif.read),
        .write               (vif.write),
        .apb_paddr           (vif.apb_paddr),
        .apb_write_data      (vif.apb_write_data),

        .prdata              (vif.prdata),
        .pready              (vif.pready),
        .pslverr             (vif.pslverr),

        .psel                (vif.psel),
        .pwrite              (vif.pwrite),
        .penable             (vif.penable),
        .paddr               (vif.paddr),
        .pwdata              (vif.pwdata),

        .apb_read_data_out   (vif.apb_read_data_out),
        .apb_read_data_valid (vif.apb_read_data_valid)
    );

    // Reset

    initial begin

        vif.presetn = 0;

        // Master inputs
        vif.transfer       = 0;
        vif.read           = 0;
        vif.write          = 0;
        vif.apb_paddr      = 0;
        vif.apb_write_data = 0;

        // Slave outputs
        vif.pready  = 0;
        vif.pslverr = 0;
        vif.prdata  = 32'h0;

        #20;
        vif.presetn = 1;

    end

    // Simple APB Slave Model

    always @(posedge pclk or negedge vif.presetn) begin

        if (!vif.presetn) begin

            vif.pready  <= 0;
            vif.pslverr <= 0;
            vif.prdata  <= 32'h0;

        end
        else begin

            // Default every cycle
            vif.pready  <= 0;
            vif.pslverr <= 0;

            // ACCESS phase
            if (vif.psel && vif.penable) begin

                // Complete transfer
                vif.pready <= 1;

                // Dummy read data
                if (!vif.pwrite)
                    vif.prdata <= 32'h1234_5678;

            end

        end

    end

    // UVM Configuration

    initial begin

        uvm_config_db #(virtual apb_interface)::set(
            null,
            "*",
            "vif",
            vif
        );

        run_test("apb_random_test");

    end
    initial begin
	$shm_open("wave.shm");  
	$shm_probe("ACTMF");
    end

endmodule
