`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   13:41:27 12/07/2017
// Design Name:   aes_cipher_top
// Module Name:   C:/Aakash/blackboard/fall 17/Hardware Security/Final Project/CED files/verilog/tb_top.v
// Project Name:  Final_Project_HS
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: aes_cipher_top
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module tb_top;

	// Inputs
	reg clk;
	reg rst;
	reg ld;
	reg [127:0] key;
	reg [127:0] text_in;
	reg [1:0] ced_mode;
	reg [3:0] ced_round;
	reg en_FI;
	reg mode_FI;
	reg [3:0] bit_index_FI;
	reg [3:0] func_FI;
	reg [3:0] round_FI;
	reg [3:0] round_in_FI;
	reg [3:0] round_stop_FI;
	reg [1:0] row_FI;
	reg [1:0] column_FI;


	// Outputs
	wire done, done_ref;
	wire [127:0] text_out, text_out_ref;
	wire fault_detected;
	wire [4:0] fault_location;
	wire error;
	wire [127:0] sbox_ref, shrw_ref, mxcl_ref, kyxr_ref, keys_ref;
   wire [127:0] sbox_uut, shrw_uut, mxcl_uut, kyxr_uut, keys_uut;
  // File I/O stuff
  integer i,fd;
  reg [127:000] a_in, a_in_inv;
  
	// Instantiate the Unit Under Test (UUT)
	aes_top uut (
		.clk(clk),
		.rst(rst),
		.ld(ld),
		.key(key),
		.text_in(text_in),
		.done(done),
		.text_out(text_out),
		.ced_mode(ced_mode),
		.ced_round(ced_round),
		.fault_detected(fault_detected),
		.fault_location(fault_location),
		.error(error),
		.en_FI(en_FI),
		.mode_FI(mode_FI),
		.bit_index_FI(bit_index_FI),
		.func_FI(func_FI),
		.round_FI(round_FI),
		//.round_in_FI(round_in_FI),
		.row_FI(row_FI),
		.column_FI(column_FI),
		.sb_in(sbox_uut),
		.sr_in(shrw_uut),
		.mc_in(mxcl_uut),
		.kx_out(kyxr_uut),
		.keys(keys_uut)
	);

	aes_top_ref ref_aes_top
	(.clk(clk),
    .rst(rst),
	 .ld(ld),
	 .done(done_ref),
	 .key(key),
	 .text_in(text_in),
	 .text_out(text_out_ref),
	 .sbox(sbox_ref),
	 .shrw(shrw_ref),
	 .mxcl(mxcl_ref),
	 .kyxr(kyxr_ref),
	 .keys(keys_ref)
	 );

	initial begin
		// Initialize Inputs
		clk = 1;
		rst = 0;
		ld = 0;
		key = 0;
		text_in = 0;
		ced_mode = 2'b00;
		ced_round = 0;
		en_FI = 0;
		mode_FI = 0;
		bit_index_FI = 3'h4;
		func_FI = 1;
		round_FI = 1;
		//round_in_FI = 0;
		row_FI = 1;
		column_FI = 1;

		/*

		FILE IO 
		
		en =  enables module. 0 for disable,1 for enable.
		mode = 0 for bit fault, 1 for byte fault.
		func = 0 for sbox,1 for shiftrow,2 for mixcolumn,3 for keyxor.
		round = determines which round fault should be injected. range 0 to 9.

		*/

		fd = $fopen("./input.txt","r");


		if (!$feof(fd))
		begin

			i = $fscanf (fd,"%d",en_FI);
			i = $fscanf (fd,"%d",mode_FI);
			i = $fscanf (fd,"%d",func_FI);
			i = $fscanf (fd,"%d",round_FI);
			i = $fscanf (fd,"%d",round_stop_FI);
			i = $fscanf (fd,"%d",row_FI);
			i = $fscanf (fd,"%d",column_FI);
			i = $fscanf (fd,"%d",bit_index_FI);
			i = $fscanf (fd,"%h",text_in);
			i = $fscanf (fd,"%h",key);

		end
		$fclose(fd);

		///////////// File I/O Ends ////////////////////////

		// Wait 100 ns for global reset to finish
		//text_in = 128'h0123456789ABCDEF0123456789ABCDEF;
		//key = 128'h0123456789ABCDEF0123456789ABCDEF;
		ced_mode = 2'h0;
		ld = 1;
		#2;
		rst = 1;
		#20
		rst = 0;
		#3;
      ld = 0;
		#13;
		rst = 0;
//      ld = 1;
//		#12;
//		ld = 0;
//		rst = 1;
//		#20;
//		rst = 0;
		// Add stimulus here
		
		$monitor("-------------\nsb - %h\nsr - %h\nmc - %h\nkx - %h\nkeys - %h\n-----------\n",sbox_uut, shrw_uut, mxcl_uut, kyxr_uut, keys_uut);
		
		#1 wait (done_ref) print_ciphertext(text_out_ref);
		#1 wait (done) print_ciphertext(text_out);
		#1 wait (fault_detected) fault(fault_detected);
		#1 wait (fault_detected) print_fault_loc(fault_location); 

		#500;
		
		a_in = alpha_permutation(text_in);
		a_in_inv = inv_alpha_permutation(a_in);
		
		$display ("-text - %h\n-a in- %h\n - a inv - %h\n", text_in, a_in, a_in_inv);
		
		$finish;
	end

	always #10 clk = ~clk;



//////////////////////////////////////////////////////////////////////////////
//
// Tasks
//

//task to print Fault Injector values -
task print_FI;
input round, row, column, round_end, en, mode;
begin
 $display("---------Fault Injector Parameters Input---------");
end
endtask

//task to print Ciphertext
task print_ciphertext;
input [127:0] text_out;
begin
  $display("-------------------------------------------");
	$display("Ciphertext is %h",text_out);
	$display("-------------------------------------------");
end
endtask

//task to print reference Ciphertext
task print_ciphertext_ref;
input [127:0] text_out;
begin
  $display("-------------------------------------------");
	$display("Reference Ciphertext is %h",text_out);
	$display("-------------------------------------------");
end
endtask

//task to print error
task print_error;
input error_in;
begin
  $display("---------wrong mode input for CED--------------");
end
endtask

//task to print fault detection result
task fault;
input a;
begin
  if (a) begin
  	$display("------Fault Detected--------------------------");
  end
	else begin
    $display("------No Fault Detected-----------------------");
	end
end
endtask

//task to print fault location
task print_fault_loc;
input [3:0] location;
begin
  if (fault_detected) begin
	  $display("---------fault detected at-----------");
		$display("---------VVVVVVVVVVVVVVVVV-----------");
  	if (location == 4'd0) begin
  		$display("-------Initial Permutation--------");
  	end
		else if (location == 4'd1) begin
			$display("----------Round 0-------------");
		end
		else if (location == 4'd2) begin
			$display("----------Round 1-------------");
		end
		else if (location == 4'd3) begin
			$display("----------Round 2-------------");
		end
		else if (location == 4'd4) begin
			$display("----------Round 3-------------");
		end
		else if (location == 4'd5) begin
			$display("----------Round 4-------------");
		end
		else if (location == 4'd6) begin
			$display("----------Round 5-------------");
		end
		else if (location == 4'd7) begin
			$display("----------Round 6-------------");
		end
		else if (location == 4'd8) begin
			$display("----------Round 7-------------");
		end
		else if (location == 4'd9) begin
			$display("----------Round 8-------------");
		end
		else if (location == 4'd10) begin
			$display("----------Round 9-------------");
		end
		else if (location == 4'd11) begin
			$display("----------Round 10-------------");
		end
		else begin
      $display("-->>Error in location input------");
		end
  end
	else begin
    $display("--------AES is Safe--------");
	end
end
endtask




function [127:000] alpha_permutation;
input [127:000] a;
alpha_permutation =  {a[103:096], a[127:120], a[119:112], a[111:104],
                      a[071:064], a[095:088], a[087:080], a[079:072],
                      a[039:032], a[063:056], a[055:048], a[047:040],
                      a[007:000], a[031:024], a[023:016], a[015:008]};
endfunction

function [127:000] inv_alpha_permutation;
input [127:000] a;
inv_alpha_permutation = {a[119:112], a[111:104], a[103:096], a[127:120],
                         a[087:080], a[079:072], a[071:064], a[095:088],
                         a[055:048], a[047:040], a[039:032], a[063:056],
                         a[023:016], a[015:008], a[007:000], a[031:024]};
endfunction




endmodule
