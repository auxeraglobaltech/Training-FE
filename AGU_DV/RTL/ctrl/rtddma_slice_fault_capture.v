// rtl/ctrl/rtddma_slice_fault_capture.v
//status: placeholder
//
//
`include "rtdma_params.vh"
//
module rtdma_slice_fault_capture #(
    parameter AXI_ADDR_W = `RTDDMA_AXI_ADDR_W
)(
    input  wire                   clk,
    input  wire                   rst_n,

    // --------------------------------------------------------
    // 1. Fault Sources (from sub-modules)
    // --------------------------------------------------------
    // From Descriptor Validator
    input  wire                   desc_val_fault,
    input  wire [3:0]             desc_val_fault_type,
    
    // From AXI/Datapath (placeholders for when we build them)
    input  wire                   mpu_exec_fault,
    input  wire [AXI_ADDR_W-1:0]  mpu_bad_addr,
    input  wire                   axi_timeout_fault,

    // Context context tracking (to know WHERE it failed)
    input  wire [AXI_ADDR_W-1:0]  current_desc_ptr,

    // --------------------------------------------------------
    // 2. Control / APB Interface
    // --------------------------------------------------------
    input  wire                   clear_fault_pulse, // From APB write (W1C)
    input  wire                   cfg_auto_halt_en,  // From SLICE_FAULT_CTRL
    input  wire                   cfg_irq_en,        // From SLICE_FAULT_CTRL

    // --------------------------------------------------------
    // 3. Hardware Reaction Outputs
    // --------------------------------------------------------
    output reg                    slice_halt_req,    // Hardware freeze signal to all FSMs
    output wire                   slice_irq,         // To global interrupt aggregator

    // --------------------------------------------------------
    // 4. Latched Diagnostic State (To APB Regs)
    // --------------------------------------------------------
    output reg                    fault_active,      // Slice is in FAULT state
    output reg  [3:0]             latched_fault_type,
    output reg  [AXI_ADDR_W-1:0]  latched_desc_ptr,
    output reg  [AXI_ADDR_W-1:0]  latched_bad_addr
);

    // Internal aggregation
    wire any_fault_now = desc_val_fault | mpu_exec_fault | axi_timeout_fault;

    // Interrupt generation (combinational off the latched active state + mask)
    assign slice_irq = fault_active & cfg_irq_en;

    // =====================================================================
    // FIRST-FAULT LATCH (Safety Critical)
    // =====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_active       <= 1'b0;
            latched_fault_type <= 4'd0;
            latched_desc_ptr   <= {AXI_ADDR_W{1'b0}};
            latched_bad_addr   <= {AXI_ADDR_W{1'b0}};
            slice_halt_req     <= 1'b0;
        end 
        else if (clear_fault_pulse) begin
            // Software acknowledged and cleared the fault
            fault_active       <= 1'b0;
            latched_fault_type <= 4'd0;
            latched_desc_ptr   <= {AXI_ADDR_W{1'b0}};
            latched_bad_addr   <= {AXI_ADDR_W{1'b0}};
            slice_halt_req     <= 1'b0;
        end 
        else if (any_fault_now && !fault_active) begin
            // 🔴 FIRST FAULT CAPTURE
            // We only latch if !fault_active. This prevents a cascading fault 
            // (e.g. MPU fault causing a Timeout fault later) from overwriting the root cause.
            
            fault_active   <= 1'b1;
            slice_halt_req <= cfg_auto_halt_en; // Freeze FSMs if configured to do so

            // Priority encode the exact cause
            if (desc_val_fault) begin
                latched_fault_type <= desc_val_fault_type;
                latched_desc_ptr   <= current_desc_ptr;
                latched_bad_addr   <= {AXI_ADDR_W{1'b0}}; // N/A for descriptor format error
            end 
            else if (mpu_exec_fault) begin
                latched_fault_type <= 4'hA; // e.g., MPU_EXEC_ERR code
                latched_desc_ptr   <= current_desc_ptr;
                latched_bad_addr   <= mpu_bad_addr; // Exact address that failed the MPU
            end 
            else if (axi_timeout_fault) begin
                latched_fault_type <= 4'hB; // e.g., TIMEOUT_ERR code
                latched_desc_ptr   <= current_desc_ptr;
                latched_bad_addr   <= {AXI_ADDR_W{1'b0}};
            end
        end
        // If fault_active is already 1, we do NOTHING. We preserve the first fault.
    end

endmodule