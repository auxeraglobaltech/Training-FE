`timescale 1ns/1ps
module skid_buffer #(
	parameter DATA_WIDTH =32)
(
	input 			clk,
	input			rst_n,
	// INPUT / UPSTREAM
	input [DATA_WIDTH-1:0]	i_data,
	input 			i_valid,
	output			o_ready,
	// output DOWNSTREAM
	output [DATA_WIDTH-1:0] o_data,
	output			o_valid,
	input 			i_ready);

	reg [DATA_WIDTH-1:0] 	data_reg;
	reg			by_pass;
	
	
	always @(posedge clk) begin
	   if(!rst_n) begin
		data_reg <= {DATA_WIDTH{1'b0}};
		by_pass <= 1'b1;
	   end
	
	   else begin
		if(by_pass) begin
			if(i_valid && !i_ready) begin
				data_reg 	<= i_data;
				by_pass		<= 1'b0;
			end
		end
		
		// SKID MODE
		else begin
			if(i_ready) begin
				by_pass <= 1'b1;
			end
		end
	end
end

// continuous assignments

assign o_ready 	= by_pass;

// Data output 
assign o_data 	= by_pass ? i_data : data_reg;

// valid output 
assign o_valid	= by_pass ? i_valid : 1'b1;

endmodule

				
