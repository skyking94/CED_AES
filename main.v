// Module to perform State Machine operation for AES along with CED //
module main (
	input     clk,                           // Clock
	input     rst,                           // Asynchronous reset active low
	input [1:0] ced_mode,                    // Input Mode controller to determine which way the state machine will work
	input [3:0] ced_round,                   // Determines which round to repeat in CED Mode 2
	input [7:0] keyXor_0_eff_sig [3:0] [3:0],// Effective fault injected input from initial permutation / round 0
	input [7:0] keyXor_10_sig [3:0][3:0],    // Effective input from round 10
	input [7:0] keyXor_out_eff_sig[3:0][3:0],// Effective fault injected input from rounds 1 to 9
	output     [7:0] data_reg_sig [3:0][3:0],// Output from this module as "state" register output from AES rounds
	output      done_sig,                    // Output signal to state that the AES rounds are done
	output     [3:0] key_index_vector_sig,   // Output nibble for fault injector to track the AES round iteration
	output     fault_detected,               // Output signal to show that a fault has been detected by the CED
	output     [3:0] fault_location          // output signal to show where the fault has been detected by the CED
);

//Local registers
reg [7:0]   state_reg[3:0][3:0];
reg [3:0]   key_index;
reg         done;
reg         state;
reg         repeat_ced;

// Local Wires
wire [7:0] keyXor_0_eff_sig_per[3:0][3:0];
wire [7:0] keyXor_out_eff_sig_per[3:0][3:0];
wire [7:0] keyXor_10_sig_per[3:0][3:0];
wire [7:0] keyXor_0_eff_sig_save[3:0][3:0];
wire [7:0] keyXor_out_eff_sig_save[3:0][3:0];
wire [7:0] keyXor_10_sig_save[3:0][3:0];
wire [7:0] keyXor_0_eff_sig_ced[3:0][3:0];
wire [7:0] keyXor_out_eff_sig_ced[3:0][3:0];
wire [7:0] keyXor_10_sig_ced[3:0][3:0];

// Assignment operations
assign data_reg_sig = state_reg;
assign key_index_vector_sig = key_index;
assign done_sig = done;
assign fault_location = fault_detected ? key_index : fault_location;
assign keyXor_0_eff_sig_save = repeat_ced ? keyXor_0_eff_sig : keyXor_0_eff_sig_save;
assign keyXor_out_eff_sig_save = repeat_ced ? keyXor_out_eff_sig : keyXor_out_eff_sig;
assign keyXor_10_sig_save = repeat_ced ? keyXor_10_sig : keyXor_10_sig_save;


always @(posedge clk) begin : proc_state_reg
	if(~rst) begin
		state_reg <= 128'd0;
		key_index <= 4'd0;
		done      <= 1'b0;
		state     <= 1'b0;
		repeat_ced <= 1'b0;
	end 
    else if (done) begin
        state_reg <= 128'd0;
    end
	else begin
		if(state == 1'b0) begin
			if(ced_mode == 2'b00) begin
				// Normal AES round
				if(key_index == 4'd0) begin
					/* code */
					state_reg <= keyXor_0_eff_sig;
				end
				else if(key_index < 4'd10) begin
					/* code */
					state_reg <= keyXor_out_eff_sig;
				end
				else if(key_index == 4'd10) begin
					/* code */
					state_reg <= keyXor_10_sig;
					done      <= 1'b1;
				end
				state <= 1'b1;
			end
			else if(ced_mode == 2'b01) begin
				/* AES Rounds with 1 time repetition for CED */
				if(key_index == 4'd0 && ~repeat_ced) begin
					repeat_ced <= 1'b1;
					state_reg <= keyXor_0_eff_sig;
				end
				else if(key_index == 4'd0 && repeat_ced) begin
					repeat_ced <= 1'b0;
					state_reg <= keyXor_0_eff_sig_per;
					if(cmp_key_0 == 1'b1) begin
						fault_detected <= 1'b1;
					end
					else begin
						fault_detected <= 1'b0;
					end
				end
				else if(key_index < 4'd10 && ~repeat_ced) begin
					repeat_ced <= 1'b1;
					state_reg <= keyXor_out_eff_sig;
				end
				else if(key_index < 4'd10 && repeat_ced) begin
					repeat_ced = 1'b0;
					state_reg <= keyXor_out_eff_sig_per;
					if(cmp_key_out == 1'b1) begin
						fault_detected <= 1'b1;
					end
					else begin
						fault_detected <= 1'b0;
					end
				end
				else if(key_index == 4'd10 && ~repeat_ced) begin
					repeat_ced = 1'b1;
					state_reg <= keyXor_10_sig;
				end
				else if(key_index == 4'd10 && repeat_ced) begin
					repeat_ced = 1'b0;
					state_reg <= keyXor_10_sig_per;
					if(cmp_key_10 == 1'b1) begin
						fault_detected <= 1'b1;
					end
					else begin
						fault_detected <= 1'b0;
					end
				end
			end
			else if(ced_mode == 2'b10) begin
				if(key_index == ced_round) begin
					repeat_ced <= 1'b1;
				end
				else begin
					repeat_ced <= 1'b0;
				end
				/*AES Rounds with selected CED approach*/
				if(key_index == 4'd0 && ~repeat_ced) begin
					state_reg <= keyXor_0_eff_sig;
				end
				else if(key_index == 4'd0 && repeat_ced) begin
					state_reg <= keyXor_0_eff_sig_per;
					if(cmp_key_0 == 1'b1) begin
						fault_detected <= 1'b1;
					end
					else begin
						fault_detected <= 1'b0;
					end
				end
				else if(key_index < 4'd10 && ~repeat_ced) begin
					state_reg <= keyXor_out_eff_sig;
				end
				else if(key_index < 4'd10 && repeat_ced) begin
					state_reg <= keyXor_out_eff_sig_per;
					if(cmp_key_out == 1'b1) begin
						fault_detected <= 1'b1;
					end
					else begin
						fault_detected <= 1'b0;
					end
				end
				else if(key_index == 4'd10 && ~repeat_ced) begin
					state_reg <= keyXor_10_sig;
				end
				else if(key_index == 4'd10 && repeat_ced) begin
					state_reg <= keyXor_10_sig_per;
					if(cmp_key_10 == 1'b1) begin
						fault_detected <= 1'b1;
					end
					else begin
						fault_detected <= 1'b0;
					end
				end
			end
			else begin
                state_reg <= 128'd0;
                key_index <= 4'd0;
                done <= 1'b0;
			end
		end
		else if(state == 1'b1 && done == 1'b0) begin
			 state <= 1'b0;
			 key_index <= key_index + 1;
		end
		state_reg <= 128'd31;
	end
end



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Alpha and Inverse Alpha Permutations
//

assign keyXor_0_eff_sig_per = alpha_permutation(keyXor_0_eff_sig);
assign keyXor_out_eff_sig_per = alpha_permutation(keyXor_out_eff_sig);
assign keyXor_10_sig_per = alpha_permutation(keyXor_10_sig);

assign keyXor_0_eff_sig_ced = inv_alpha_permutation(keyXor_0_eff_sig);
assign keyXor_out_eff_sig_ced = inv_alpha_permutation(keyXor_out_eff_sig);
assign keyXor_10_sig_ced = inv_alpha_permutation(keyXor_10_sig); 

aplha alpha_key_0 (keyXor_0_eff_sig, keyXor_0_eff_sig_per);
aplha alpha_key_out (keyXor_out_eff_sig, keyXor_10_sig_per);
aplha alpha_key_10 (keyXor_10_sig, keyXor_10_sig_per);
inv_aplha alpha_key_0_ced (keyXor_0_eff_sig, keyXor_0_eff_sig_ced);
inv_aplha alpha_key_out_ced (keyXor_out_eff_sig, keyXor_out_eff_sig_ced);
inv_aplha alpha_key_10_ced (keyXor_10_sig, keyXor_10_sig_ced);


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//   CED Operations
//

assign cmp_key_0 = (keyXor_0_eff_sig_save == keyXor_0_eff_sig_ced) ? 1'b0 : 1'b1; 
assign cmp_key_out = (keyXor_out_eff_sig_save == keyXor_out_eff_sig_ced) ? 1'b0 : 1'b1; 
assign cmp_key_10 = (keyXor_10_sig_save == keyXor_10_sig_ced) ? 1'b0 : 1'b1; 



endmodule