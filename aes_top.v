/*

AES Top Verilog file with CED State Machine and Fault-Injector module instantiation

*/
/////////////////////////////////////////////////////////////////////////////////////////
//
//
//
/////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 10ps

/////////////////////////////////////////////////////////////////////////////////////////


module aes_top (
  // inputs and outputs for AES core
  input		             clk,
  input                rst,
  input	               ld,
  input	[127:0]	key,
  input	[127:0]	text_in,
  output reg	done,
  output reg	[127:0]	text_out,

  //inputs and outputs for CED
  input [1:0]  ced_mode,
  input [3:0]  ced_round,
  output   fault_detected,
  output [4:0] fault_location,
  output reg   error,

  //inputs and outputs for Fault_injector
  input        en_FI,
  input        mode_FI,
  input  [3:0] bit_index_FI,
  input  [3:0] func_FI,
  input  [3:0] round_FI,
  //input  [3:0] round_in_FI,
  input  [1:0] row_FI,
  input  [1:0] column_FI,
  output [127:0] sb_in,
  output [127:0] sr_in,
  output [127:0] mc_in,
  output [127:0] kx_out,
  output [127:0] keys
  );

/////////////////////////////////////////////////////////////////////////////////////////
//
//      Local Wires and Registers
//
/////////////////////////////////////////////////////////////////////////////////////////

//Wires from Key Expansion Module
wire	[31:0]	w0_out, w1_out, w2_out, w3_out;
wire	[31:0]	w0_eff, w1_eff, w2_eff, w3_eff;
wire	[31:0]	w0, w1, w2, w3;
//Wires and Registers Related to Key Expansion module and KeyXor operation
wire  [127:000]  key_in, keys, keys_perm, keys_op, key_eff;
wire              keys_mux_sel; // wire to control the KeyXOR mux
//mmemory to save keys
reg [127:0] key_mem [00:15];
reg read_key_mem;
reg [3:0] key_addr;
reg [127:0] key_out;
reg [3:0] key_mem_cnt;
reg ld_key_mem;
reg key_sel; 

// State registers
wire [127:000] state;
reg	[7:0]	sa00, sa01, sa02, sa03, sa10, sa11, sa12, sa13;
reg	[7:0]	sa20, sa21, sa22, sa23, sa30, sa31, sa32, sa33;
wire state_mux;

// Grouped state register wires
wire [127:000] next_state;
wire [127:000] state_wire, next_state_eff, state_eff, state_in;
wire [007:000]	sa00_next, sa01_next, sa02_next, sa03_next;
wire [007:000]	sa10_next, sa11_next, sa12_next, sa13_next;
wire [007:000]	sa20_next, sa21_next, sa22_next, sa23_next;
wire [007:000]	sa30_next, sa31_next, sa32_next, sa33_next;

// Wires for Fault Detection
wire [127:000]  V1, V2_inv, V2;
wire [127:000]  V1_eff, V2_eff;
wire cmp;

// Wires for Initial Permutation
wire [127:000]   plain, plain_perm, plain_op, plain_op_eff, plain_eff;
reg             round_input_mux_sel;
reg    plain_mux_sel;


// MISC
reg  mc_mux_sel, state_mux_sel, ns_sel;
reg init_perm;
reg [3:0] round_cnt;
reg repeat_ced;
wire ld_mux;
assign ld_mux = ld;
reg temp_sel;
wire save;
wire key_clk;
reg clk_by_2;


// Wires for AES Rounds
//wire [127:000]   sbox, shrw, mxcl, kyxr;
//wire [127:000]   sb_in, sr_in, mc_in, kx_out;
//wire [127:000]   sb_in_eff, sr_in_eff, mc_in_eff, kx_in_eff;
wire [127:000]   sb_out_eff, sr_out_eff, mc_out_eff;//, kx_out_eff;

wire [007:000]   sb_in_00, sb_in_01, sb_in_02, sb_in_03;
wire [007:000]   sb_in_10, sb_in_11, sb_in_12, sb_in_13;
wire [007:000]   sb_in_20, sb_in_21, sb_in_22, sb_in_23;
wire [007:000]   sb_in_30, sb_in_31, sb_in_32, sb_in_33;
wire [007:000]   sr_in_00, sr_in_01, sr_in_02, sr_in_03;
wire [007:000]   sr_in_10, sr_in_11, sr_in_12, sr_in_13;
wire [007:000]   sr_in_20, sr_in_21, sr_in_22, sr_in_23;
wire [007:000]   sr_in_30, sr_in_31, sr_in_32, sr_in_33;
wire [007:000]   mc_in_00, mc_in_01, mc_in_02, mc_in_03;
wire [007:000]   mc_in_10, mc_in_11, mc_in_12, mc_in_13;
wire [007:000]   mc_in_20, mc_in_21, mc_in_22, mc_in_23;
wire [007:000]   mc_in_30, mc_in_31, mc_in_32, mc_in_33;
//wire [007:000]   kx_in_00, kx_in_01, kx_in_02, kx_in_03;
//wire [007:000]   kx_in_10, kx_in_11, kx_in_12, kx_in_13;
//wire [007:000]   kx_in_20, kx_in_21, kx_in_22, kx_in_23;
//wire [007:000]   kx_in_30, kx_in_31, kx_in_32, kx_in_33;

//wire [007:000]   sb_in_eff_00, sb_in_eff_01, sb_in_eff_02, sb_in_eff_03;
//wire [007:000]   sb_in_eff_10, sb_in_eff_11, sb_in_eff_12, sb_in_eff_13;
//wire [007:000]   sb_in_eff_20, sb_in_eff_21, sb_in_eff_22, sb_in_eff_23;
//wire [007:000]   sb_in_eff_30, sb_in_eff_31, sb_in_eff_32, sb_in_eff_33;
//wire [007:000]   sr_in_eff_00, sr_in_eff_01, sr_in_eff_02, sr_in_eff_03;
//wire [007:000]   sr_in_eff_10, sr_in_eff_11, sr_in_eff_12, sr_in_eff_13;
//wire [007:000]   sr_in_eff_20, sr_in_eff_21, sr_in_eff_22, sr_in_eff_23;
//wire [007:000]   sr_in_eff_30, sr_in_eff_31, sr_in_eff_32, sr_in_eff_33;
//wire [007:000]   mc_in_eff_00, mc_in_eff_01, mc_in_eff_02, mc_in_eff_03;
//wire [007:000]   mc_in_eff_10, mc_in_eff_11, mc_in_eff_12, mc_in_eff_13;
//wire [007:000]   mc_in_eff_20, mc_in_eff_21, mc_in_eff_22, mc_in_eff_23;
//wire [007:000]   mc_in_eff_30, mc_in_eff_31, mc_in_eff_32, mc_in_eff_33;
//wire [007:000]   kx_in_eff_00, kx_in_eff_01, kx_in_eff_02, kx_in_eff_03;
//wire [007:000]   kx_in_eff_10, kx_in_eff_11, kx_in_eff_12, kx_in_eff_13;
//wire [007:000]   kx_in_eff_20, kx_in_eff_21, kx_in_eff_22, kx_in_eff_23;
//wire [007:000]   kx_in_eff_30, kx_in_eff_31, kx_in_eff_32, kx_in_eff_33;

//wire [007:000]   sb_out_00, sb_out_01, sb_out_02, sb_out_03;
//wire [007:000]   sb_out_10, sb_out_11, sb_out_12, sb_out_13;
//wire [007:000]   sb_out_20, sb_out_21, sb_out_22, sb_out_23;
//wire [007:000]   sb_out_30, sb_out_31, sb_out_32, sb_out_33;
//wire [007:000]   sr_out_00, sr_out_01, sr_out_02, sr_out_03;
//wire [007:000]   sr_out_10, sr_out_11, sr_out_12, sr_out_13;
//wire [007:000]   sr_out_20, sr_out_21, sr_out_22, sr_out_23;
//wire [007:000]   sr_out_30, sr_out_31, sr_out_32, sr_out_33;
//wire [007:000]   mc_out_00, mc_out_01, mc_out_02, mc_out_03;
//wire [007:000]   mc_out_10, mc_out_11, mc_out_12, mc_out_13;
//wire [007:000]   mc_out_20, mc_out_21, mc_out_22, mc_out_23;
//wire [007:000]   mc_out_30, mc_out_31, mc_out_32, mc_out_33;
wire [007:000]   kx_out_00, kx_out_01, kx_out_02, kx_out_03;
wire [007:000]   kx_out_10, kx_out_11, kx_out_12, kx_out_13;
wire [007:000]   kx_out_20, kx_out_21, kx_out_22, kx_out_23;
wire [007:000]   kx_out_30, kx_out_31, kx_out_32, kx_out_33;

wire [007:000]   sb_out_eff_00, sb_out_eff_01, sb_out_eff_02, sb_out_eff_03;
wire [007:000]   sb_out_eff_10, sb_out_eff_11, sb_out_eff_12, sb_out_eff_13;
wire [007:000]   sb_out_eff_20, sb_out_eff_21, sb_out_eff_22, sb_out_eff_23;
wire [007:000]   sb_out_eff_30, sb_out_eff_31, sb_out_eff_32, sb_out_eff_33;
wire [007:000]   sr_out_eff_00, sr_out_eff_01, sr_out_eff_02, sr_out_eff_03;
wire [007:000]   sr_out_eff_10, sr_out_eff_11, sr_out_eff_12, sr_out_eff_13;
wire [007:000]   sr_out_eff_20, sr_out_eff_21, sr_out_eff_22, sr_out_eff_23;
wire [007:000]   sr_out_eff_30, sr_out_eff_31, sr_out_eff_32, sr_out_eff_33;
wire [007:000]   mc_out_eff_00, mc_out_eff_01, mc_out_eff_02, mc_out_eff_03;
wire [007:000]   mc_out_eff_10, mc_out_eff_11, mc_out_eff_12, mc_out_eff_13;
wire [007:000]   mc_out_eff_20, mc_out_eff_21, mc_out_eff_22, mc_out_eff_23;
wire [007:000]   mc_out_eff_30, mc_out_eff_31, mc_out_eff_32, mc_out_eff_33;
//wire [007:000]   kx_out_eff_00, kx_out_eff_01, kx_out_eff_02, kx_out_eff_03;
//wire [007:000]   kx_out_eff_10, kx_out_eff_11, kx_out_eff_12, kx_out_eff_13;
//wire [007:000]   kx_out_eff_20, kx_out_eff_21, kx_out_eff_22, kx_out_eff_23;
//wire [007:000]   kx_out_eff_30, kx_out_eff_31, kx_out_eff_32, kx_out_eff_33;

// Wires and Registers for MUXs

/////////////////////////////////////////////////////////////////////////////////////////
//
//      Logic {assign statements}
//
/////////////////////////////////////////////////////////////////////////////////////////

// Related to AES rounds
/*assign {sb_in_00, sb_in_01, sb_in_02, sb_in_03,
                sb_in_10, sb_in_11, sb_in_12, sb_in_13,
                sb_in_20, sb_in_21, sb_in_22, sb_in_23,
                sb_in_30, sb_in_31, sb_in_32, sb_in_33} = plain_op_eff;*/

assign sb_in = {sb_in_00, sb_in_01, sb_in_02, sb_in_03,
                sb_in_10, sb_in_11, sb_in_12, sb_in_13,
                sb_in_20, sb_in_21, sb_in_22, sb_in_23,
                sb_in_30, sb_in_31, sb_in_32, sb_in_33};

assign sr_in = {sr_in_00, sr_in_01, sr_in_02, sr_in_03,
                sr_in_10, sr_in_11, sr_in_12, sr_in_13,
                sr_in_20, sr_in_21, sr_in_22, sr_in_23,
                sr_in_30, sr_in_31, sr_in_32, sr_in_33};

assign mc_in = {mc_in_00, mc_in_01, mc_in_02, mc_in_03,
                mc_in_10, mc_in_11, mc_in_12, mc_in_13,
                mc_in_20, mc_in_21, mc_in_22, mc_in_23,
                mc_in_30, mc_in_31, mc_in_32, mc_in_33};

assign {sb_out_eff_00,sb_out_eff_01,sb_out_eff_02,sb_out_eff_03,
        sb_out_eff_10,sb_out_eff_11,sb_out_eff_12,sb_out_eff_13,
        sb_out_eff_20,sb_out_eff_21,sb_out_eff_22,sb_out_eff_23,
        sb_out_eff_30,sb_out_eff_31,sb_out_eff_32,sb_out_eff_33} = sb_out_eff;

assign {sr_out_eff_00,sr_out_eff_01,sr_out_eff_02,sr_out_eff_03,
        sr_out_eff_10,sr_out_eff_11,sr_out_eff_12,sr_out_eff_13,
        sr_out_eff_20,sr_out_eff_21,sr_out_eff_22,sr_out_eff_23,
        sr_out_eff_30,sr_out_eff_31,sr_out_eff_32,sr_out_eff_33} = sr_out_eff;

assign {mc_out_eff_00,mc_out_eff_01,mc_out_eff_02,mc_out_eff_03,
        mc_out_eff_10,mc_out_eff_11,mc_out_eff_12,mc_out_eff_13,
        mc_out_eff_20,mc_out_eff_21,mc_out_eff_22,mc_out_eff_23,
        mc_out_eff_30,mc_out_eff_31,mc_out_eff_32,mc_out_eff_33} = mc_out_eff;

/*assign kx_out = {kx_out_00, kx_out_01, kx_out_02, kx_out_03,
                 kx_out_10, kx_out_11, kx_out_12, kx_out_13,
                 kx_out_20, kx_out_21, kx_out_22, kx_out_23,
                 kx_out_30, kx_out_31, kx_out_32, kx_out_33};*/



// Related to Fault Detection

assign fault_detected = cmp;
assign fault_location = {1'b0, round_cnt};

/////////////////////////////////////////////////////////////////////////////////////////
//
//      Multiplexer Logic
//
/////////////////////////////////////////////////////////////////////////////////////////
// related to State register and its MUXs
assign plain_perm = alpha_permutation(plain);
/*assign state = {sa00, sa01, sa02, sa03,
                     sa10, sa11, sa12, sa13,
                     sa20, sa21, sa22, sa23,
                     sa30, sa31, sa32, sa33};*/

assign state = {sa00, sa10, sa20, sa30,
                sa01, sa11, sa21, sa31,
                sa02, sa12, sa22, sa32,
                sa03, sa13, sa23, sa33};

assign V1 = (round_cnt == 0) ? (save ? state : V1) : (save ? next_state : V1);
assign V2 = (round_cnt == 0) ? state : next_state;
assign save = ~repeat_ced;
assign cmp = (V2 == V1) ? 1'b0 : 1'b1; // Comparison between V1 & V2 for fault Detection

reg plain_sel;
//Input mux
assign plain = plain_mux_sel ? text_in : next_state_eff;
assign plain_eff = plain_sel ? plain : plain_eff;
//Round input Mux
assign plain_op = round_input_mux_sel ? plain : plain_perm;

assign next_state = kx_out;
// Next State Logic
assign next_state_eff = ns_sel ? plain_eff : next_state;

//assign plain_mux_sel = ~repeat_ced;
//assign round_input_mux_sel = ~repeat_ced;
/////////////////////////////////////////////////////////////////////////////////////////
//
//       Initial Permutation
//
/////////////////////////////////////////////////////////////////////////////////////////

/*always @(posedge clk)	sa33 <= #1 ld_mux ? text_in[007:000] ^ w3[07:00] : sa33_next;
always @(posedge clk)	sa23 <= #1 ld_mux ? text_in[015:008] ^ w3[15:08] : sa23_next;
always @(posedge clk)	sa13 <= #1 ld_mux ? text_in[023:016] ^ w3[23:16] : sa13_next;
always @(posedge clk)	sa03 <= #1 ld_mux ? text_in[031:024] ^ w3[31:24] : sa03_next;
always @(posedge clk)	sa32 <= #1 ld_mux ? text_in[039:032] ^ w2[07:00] : sa32_next;
always @(posedge clk)	sa22 <= #1 ld_mux ? text_in[047:040] ^ w2[15:08] : sa22_next;
always @(posedge clk)	sa12 <= #1 ld_mux ? text_in[055:048] ^ w2[23:16] : sa12_next;
always @(posedge clk)	sa02 <= #1 ld_mux ? text_in[063:056] ^ w2[31:24] : sa02_next;
always @(posedge clk)	sa31 <= #1 ld_mux ? text_in[071:064] ^ w1[07:00] : sa31_next;
always @(posedge clk)	sa21 <= #1 ld_mux ? text_in[079:072] ^ w1[15:08] : sa21_next;
always @(posedge clk)	sa11 <= #1 ld_mux ? text_in[087:080] ^ w1[23:16] : sa11_next;
always @(posedge clk)	sa01 <= #1 ld_mux ? text_in[095:088] ^ w1[31:24] : sa01_next;
always @(posedge clk)	sa30 <= #1 ld_mux ? text_in[103:096] ^ w0[07:00] : sa30_next;
always @(posedge clk)	sa20 <= #1 ld_mux ? text_in[111:104] ^ w0[15:08] : sa20_next;
always @(posedge clk)	sa10 <= #1 ld_mux ? text_in[119:112] ^ w0[23:16] : sa10_next;
always @(posedge clk)	sa00 <= #1 ld_mux ? text_in[127:120] ^ w0[31:24] : sa00_next;*/



/*always @ (posedge clk) sa33 <= #1 ld_mux ? plain_op_eff[007:000] ^ keys_op[007:000] : plain_op_eff[007:000] ^ keys_op[007:000];
always @ (posedge clk) sa23 <= #1 ld_mux ? plain_op_eff[015:008] ^ keys_op[015:008] : plain_op_eff[015:008] ^ keys_op[015:008];
always @ (posedge clk) sa13 <= #1 ld_mux ? plain_op_eff[023:016] ^ keys_op[023:016] : plain_op_eff[023:016] ^ keys_op[023:016];
always @ (posedge clk) sa03 <= #1 ld_mux ? plain_op_eff[031:024] ^ keys_op[031:024] : plain_op_eff[031:024] ^ keys_op[031:024];
always @ (posedge clk) sa32 <= #1 ld_mux ? plain_op_eff[039:032] ^ keys_op[039:032] : plain_op_eff[039:032] ^ keys_op[039:032];
always @ (posedge clk) sa22 <= #1 ld_mux ? plain_op_eff[047:040] ^ keys_op[047:040] : plain_op_eff[047:040] ^ keys_op[047:040];
always @ (posedge clk) sa12 <= #1 ld_mux ? plain_op_eff[055:048] ^ keys_op[055:048] : plain_op_eff[055:048] ^ keys_op[055:048];
always @ (posedge clk) sa02 <= #1 ld_mux ? plain_op_eff[063:056] ^ keys_op[063:056] : plain_op_eff[063:056] ^ keys_op[063:056];
always @ (posedge clk) sa31 <= #1 ld_mux ? plain_op_eff[071:064] ^ keys_op[071:064] : plain_op_eff[071:064] ^ keys_op[071:064];
always @ (posedge clk) sa21 <= #1 ld_mux ? plain_op_eff[079:072] ^ keys_op[079:072] : plain_op_eff[079:072] ^ keys_op[079:072];
always @ (posedge clk) sa11 <= #1 ld_mux ? plain_op_eff[087:080] ^ keys_op[087:080] : plain_op_eff[087:080] ^ keys_op[087:080];
always @ (posedge clk) sa01 <= #1 ld_mux ? plain_op_eff[095:088] ^ keys_op[095:088] : plain_op_eff[095:088] ^ keys_op[095:088];
always @ (posedge clk) sa30 <= #1 ld_mux ? plain_op_eff[103:096] ^ keys_op[103:096] : plain_op_eff[103:096] ^ keys_op[103:096];
always @ (posedge clk) sa20 <= #1 ld_mux ? plain_op_eff[111:104] ^ keys_op[111:104] : plain_op_eff[111:104] ^ keys_op[111:104];
always @ (posedge clk) sa10 <= #1 ld_mux ? plain_op_eff[119:112] ^ keys_op[119:112] : plain_op_eff[119:112] ^ keys_op[119:112];
always @ (posedge clk) sa00 <= #1 ld_mux ? plain_op_eff[127:120] ^ keys_op[127:120] : plain_op_eff[127:120] ^ keys_op[127:120];
*/


//assign {w0[31:24],w1[31:24],w2[31:24],w3[31:24],
//w0[23:16],w1[23:16],w2[23:16],w3[23:16],
//w0[15:08],w1[15:08],w2[15:08],w3[15:08],
//w0[07:00],w1[07:00],w2[07:00],w3[07:00]} = key_out;



/////////////////////////////////////////////////////////////////////////////////////////
//
//      Logic Related to KEYS
//
/////////////////////////////////////////////////////////////////////////////////////////
//Key XOR Input Mux
assign key_eff = (ced_mode == 2'b00) ? key_in : key_out;
assign keys_op = keys_mux_sel ? key_eff : keys_perm;
//assign keys_mux_sel = ~repeat_ced;
assign key_in = {w0_out, w1_out, w2_out, w3_out};

assign keys = key_in;

//assign state = plain_op ^ keys_op; //CHANGE THIS ACCORDING TO ABOVE LOGIC
assign keys_perm  = alpha_permutation(key_in);

 assign kx_out = {kx_out_00, kx_out_10, kx_out_20, kx_out_30,
                  kx_out_01, kx_out_11, kx_out_21, kx_out_31,
                  kx_out_02, kx_out_12, kx_out_22, kx_out_32,
                  kx_out_03, kx_out_13, kx_out_23, kx_out_33};

				  
assign key_clk = (ced_mode == 2'b00) ? clk : (ld | clk_by_2);
				  
/*always @ (posedge clk) sa33 <= #1 (ld_mux | temp_sel) ? plain_op_eff[007:000] ^ keys_op[007:000] : plain_op_eff[127:120];
always @ (posedge clk) sa23 <= #1 (ld_mux | temp_sel) ? plain_op_eff[015:008] ^ keys_op[015:008] : plain_op_eff[119:112];
always @ (posedge clk) sa13 <= #1 (ld_mux | temp_sel) ? plain_op_eff[023:016] ^ keys_op[023:016] : plain_op_eff[111:104];
always @ (posedge clk) sa03 <= #1 (ld_mux | temp_sel) ? plain_op_eff[031:024] ^ keys_op[031:024] : plain_op_eff[103:096];
always @ (posedge clk) sa32 <= #1 (ld_mux | temp_sel) ? plain_op_eff[039:032] ^ keys_op[039:032] : plain_op_eff[095:088];
always @ (posedge clk) sa22 <= #1 (ld_mux | temp_sel) ? plain_op_eff[047:040] ^ keys_op[047:040] : plain_op_eff[087:080];
always @ (posedge clk) sa12 <= #1 (ld_mux | temp_sel) ? plain_op_eff[055:048] ^ keys_op[055:048] : plain_op_eff[079:072];
always @ (posedge clk) sa02 <= #1 (ld_mux | temp_sel) ? plain_op_eff[063:056] ^ keys_op[063:056] : plain_op_eff[071:064];
always @ (posedge clk) sa31 <= #1 (ld_mux | temp_sel) ? plain_op_eff[071:064] ^ keys_op[071:064] : plain_op_eff[063:056];
always @ (posedge clk) sa21 <= #1 (ld_mux | temp_sel) ? plain_op_eff[079:072] ^ keys_op[079:072] : plain_op_eff[055:048];
always @ (posedge clk) sa11 <= #1 (ld_mux | temp_sel) ? plain_op_eff[087:080] ^ keys_op[087:080] : plain_op_eff[047:040];
always @ (posedge clk) sa01 <= #1 (ld_mux | temp_sel) ? plain_op_eff[095:088] ^ keys_op[095:088] : plain_op_eff[039:032];
always @ (posedge clk) sa30 <= #1 (ld_mux | temp_sel) ? plain_op_eff[103:096] ^ keys_op[103:096] : plain_op_eff[031:024];
always @ (posedge clk) sa20 <= #1 (ld_mux | temp_sel) ? plain_op_eff[111:104] ^ keys_op[111:104] : plain_op_eff[023:016];
always @ (posedge clk) sa10 <= #1 (ld_mux | temp_sel) ? plain_op_eff[119:112] ^ keys_op[119:112] : plain_op_eff[015:008];
always @ (posedge clk) sa00 <= #1 (ld_mux | temp_sel) ? plain_op_eff[127:120] ^ keys_op[127:120] : plain_op_eff[007:000];

assign kx_out_00 = mc_out_eff_00 ^ w0_eff[31:24];
assign kx_out_01 = mc_out_eff_01 ^ w0_eff[23:16];
assign kx_out_02 = mc_out_eff_02 ^ w0_eff[15:08];
assign kx_out_03 = mc_out_eff_03 ^ w0_eff[07:00];
assign kx_out_10 = mc_out_eff_10 ^ w1_eff[31:24];
assign kx_out_11 = mc_out_eff_11 ^ w1_eff[23:16];
assign kx_out_12 = mc_out_eff_12 ^ w1_eff[15:08];
assign kx_out_13 = mc_out_eff_13 ^ w1_eff[07:00];
assign kx_out_20 = mc_out_eff_20 ^ w2_eff[31:24];
assign kx_out_21 = mc_out_eff_21 ^ w2_eff[23:16];
assign kx_out_22 = mc_out_eff_22 ^ w2_eff[15:08];
assign kx_out_23 = mc_out_eff_23 ^ w2_eff[07:00];
assign kx_out_30 = mc_out_eff_30 ^ w3_eff[31:24];
assign kx_out_31 = mc_out_eff_31 ^ w3_eff[23:16];
assign kx_out_32 = mc_out_eff_32 ^ w3_eff[15:08];
assign kx_out_33 = mc_out_eff_33 ^ w3_eff[07:00];


always @(posedge clk) text_out[127:120] <= #1 sr_out_eff_00 ^ w0_eff[31:24];
always @(posedge clk) text_out[095:088] <= #1 sr_out_eff_01 ^ w1_eff[23:16];
always @(posedge clk) text_out[063:056] <= #1 sr_out_eff_02 ^ w2_eff[15:08];
always @(posedge clk) text_out[031:024] <= #1 sr_out_eff_03 ^ w3_eff[07:00];
always @(posedge clk) text_out[119:112] <= #1 sr_out_eff_10 ^ w0_eff[31:24];
always @(posedge clk) text_out[087:080] <= #1 sr_out_eff_11 ^ w1_eff[23:16];
always @(posedge clk) text_out[055:048] <= #1 sr_out_eff_12 ^ w2_eff[15:08];
always @(posedge clk) text_out[023:016] <= #1 sr_out_eff_13 ^ w3_eff[07:00];
always @(posedge clk) text_out[111:104] <= #1 sr_out_eff_20 ^ w0_eff[31:24];
always @(posedge clk) text_out[079:072] <= #1 sr_out_eff_21 ^ w1_eff[23:16];
always @(posedge clk) text_out[047:040] <= #1 sr_out_eff_22 ^ w2_eff[15:08];
always @(posedge clk) text_out[015:008] <= #1 sr_out_eff_23 ^ w3_eff[07:00];
always @(posedge clk) text_out[103:096] <= #1 sr_out_eff_30 ^ w0_eff[31:24];
always @(posedge clk) text_out[071:064] <= #1 sr_out_eff_31 ^ w1_eff[23:16];
always @(posedge clk) text_out[039:032] <= #1 sr_out_eff_32 ^ w2_eff[15:08];
always @(posedge clk) text_out[007:000] <= #1 sr_out_eff_33 ^ w3_eff[07:00];*/

always @ (posedge clk) sa33 <= #1 (ld_mux | temp_sel) ? plain_op_eff[007:000] ^ keys_op[007:000] : kx_out_33; //plain_op_eff[007:000];
always @ (posedge clk) sa23 <= #1 (ld_mux | temp_sel) ? plain_op_eff[015:008] ^ keys_op[015:008] : kx_out_32; //plain_op_eff[015:008];
always @ (posedge clk) sa13 <= #1 (ld_mux | temp_sel) ? plain_op_eff[023:016] ^ keys_op[023:016] : kx_out_31; //plain_op_eff[023:016];
always @ (posedge clk) sa03 <= #1 (ld_mux | temp_sel) ? plain_op_eff[031:024] ^ keys_op[031:024] : kx_out_30; //plain_op_eff[031:024];
always @ (posedge clk) sa32 <= #1 (ld_mux | temp_sel) ? plain_op_eff[039:032] ^ keys_op[039:032] : kx_out_23; //plain_op_eff[039:032];
always @ (posedge clk) sa22 <= #1 (ld_mux | temp_sel) ? plain_op_eff[047:040] ^ keys_op[047:040] : kx_out_22; //plain_op_eff[047:040];
always @ (posedge clk) sa12 <= #1 (ld_mux | temp_sel) ? plain_op_eff[055:048] ^ keys_op[055:048] : kx_out_21; //plain_op_eff[055:048];
always @ (posedge clk) sa02 <= #1 (ld_mux | temp_sel) ? plain_op_eff[063:056] ^ keys_op[063:056] : kx_out_20; //plain_op_eff[063:056];
always @ (posedge clk) sa31 <= #1 (ld_mux | temp_sel) ? plain_op_eff[071:064] ^ keys_op[071:064] : kx_out_13; //plain_op_eff[071:064];
always @ (posedge clk) sa21 <= #1 (ld_mux | temp_sel) ? plain_op_eff[079:072] ^ keys_op[079:072] : kx_out_12; //plain_op_eff[079:072];
always @ (posedge clk) sa11 <= #1 (ld_mux | temp_sel) ? plain_op_eff[087:080] ^ keys_op[087:080] : kx_out_11; //plain_op_eff[087:080];
always @ (posedge clk) sa01 <= #1 (ld_mux | temp_sel) ? plain_op_eff[095:088] ^ keys_op[095:088] : kx_out_10; //plain_op_eff[095:088];
always @ (posedge clk) sa30 <= #1 (ld_mux | temp_sel) ? plain_op_eff[103:096] ^ keys_op[103:096] : kx_out_03; //plain_op_eff[103:096];
always @ (posedge clk) sa20 <= #1 (ld_mux | temp_sel) ? plain_op_eff[111:104] ^ keys_op[111:104] : kx_out_02; //plain_op_eff[111:104];
always @ (posedge clk) sa10 <= #1 (ld_mux | temp_sel) ? plain_op_eff[119:112] ^ keys_op[119:112] : kx_out_01; //plain_op_eff[119:112];
always @ (posedge clk) sa00 <= #1 (ld_mux | temp_sel) ? plain_op_eff[127:120] ^ keys_op[127:120] : kx_out_00; //plain_op_eff[127:120];

assign kx_out_00 = mc_out_eff_00 ^ w0_out[31:24];
assign kx_out_01 = mc_out_eff_01 ^ w1_out[31:24];
assign kx_out_02 = mc_out_eff_02 ^ w2_out[31:24];
assign kx_out_03 = mc_out_eff_03 ^ w3_out[31:24];
assign kx_out_10 = mc_out_eff_10 ^ w0_out[23:16];
assign kx_out_11 = mc_out_eff_11 ^ w1_out[23:16];
assign kx_out_12 = mc_out_eff_12 ^ w2_out[23:16];
assign kx_out_13 = mc_out_eff_13 ^ w3_out[23:16];
assign kx_out_20 = mc_out_eff_20 ^ w0_out[15:08];
assign kx_out_21 = mc_out_eff_21 ^ w1_out[15:08];
assign kx_out_22 = mc_out_eff_22 ^ w2_out[15:08];
assign kx_out_23 = mc_out_eff_23 ^ w3_out[15:08];
assign kx_out_30 = mc_out_eff_30 ^ w0_out[07:00];
assign kx_out_31 = mc_out_eff_31 ^ w1_out[07:00];
assign kx_out_32 = mc_out_eff_32 ^ w2_out[07:00];
assign kx_out_33 = mc_out_eff_33 ^ w3_out[07:00];

always @(posedge clk) text_out[127:120] <= #1 sr_out_eff_00 ^ w0_out[31:24];
always @(posedge clk) text_out[095:088] <= #1 sr_out_eff_01 ^ w1_out[31:24];
always @(posedge clk) text_out[063:056] <= #1 sr_out_eff_02 ^ w2_out[31:24];
always @(posedge clk) text_out[031:024] <= #1 sr_out_eff_03 ^ w3_out[31:24];
always @(posedge clk) text_out[119:112] <= #1 sr_out_eff_10 ^ w0_out[23:16];
always @(posedge clk) text_out[087:080] <= #1 sr_out_eff_11 ^ w1_out[23:16];
always @(posedge clk) text_out[055:048] <= #1 sr_out_eff_12 ^ w2_out[23:16];
always @(posedge clk) text_out[023:016] <= #1 sr_out_eff_13 ^ w3_out[23:16];
always @(posedge clk) text_out[111:104] <= #1 sr_out_eff_20 ^ w0_out[15:08];
always @(posedge clk) text_out[079:072] <= #1 sr_out_eff_21 ^ w1_out[15:08];
always @(posedge clk) text_out[047:040] <= #1 sr_out_eff_22 ^ w2_out[15:08];
always @(posedge clk) text_out[015:008] <= #1 sr_out_eff_23 ^ w3_out[15:08];
always @(posedge clk) text_out[103:096] <= #1 sr_out_eff_30 ^ w0_out[07:00];
always @(posedge clk) text_out[071:064] <= #1 sr_out_eff_31 ^ w1_out[07:00];
always @(posedge clk) text_out[039:032] <= #1 sr_out_eff_32 ^ w2_out[07:00];
always @(posedge clk) text_out[007:000] <= #1 sr_out_eff_33 ^ w3_out[07:00];

//------------------------clock divider----------------------------------
always @ (posedge clk) begin
  if (rst) begin
    clk_by_2 = 0;
  end
  else begin
    clk_by_2 = ~clk_by_2;
  end
end

//---------------------key memory-------------------------------
always @ (posedge clk) begin
  if (ld) begin
    key_mem[0] = key_in;
	 key_mem_cnt = 4'd1;
  end
  else if (ld_key_mem && key_mem_cnt < 4'd13) begin
    key_mem_cnt = key_mem_cnt + 1;
	 key_mem[key_mem_cnt] = key_in;
  end
end

always @ (posedge clk)  begin
  if (read_key_mem == 1) begin
    if (ced_mode == 2'b00) begin
      key_out = key_mem[key_mem_cnt];
    end
	else if (ced_mode == 2'b01) begin
	  key_out = key_mem[key_addr];
	end
  end
end

/////////////////////////////////////////////////////////////////////////////////////////
//
//        AES Rounds 0 to 9
//
/////////////////////////////////////////////////////////////////////////////////////////

/*always @ (posedge clk) begin
  next_state = ns_sel ? kx_out : state;
end*/

assign sr_in_00 = sb_out_eff_00; //sa00_sub_eff;
assign sr_in_01 = sb_out_eff_01; //sa01_sub_eff;
assign sr_in_02 = sb_out_eff_02; //sa02_sub_eff;
assign sr_in_03 = sb_out_eff_03; //sa03_sub_eff;
assign sr_in_10 = sb_out_eff_11; //sa12_sub_eff;
assign sr_in_11 = sb_out_eff_12; //sa11_sub_eff;
assign sr_in_12 = sb_out_eff_13; //sa13_sub_eff;
assign sr_in_13 = sb_out_eff_10; //sa10_sub_eff;
assign sr_in_20 = sb_out_eff_22; //sa22_sub_eff;
assign sr_in_21 = sb_out_eff_23; //sa23_sub_eff;
assign sr_in_22 = sb_out_eff_20; //sa20_sub_eff;
assign sr_in_23 = sb_out_eff_21; //sa21_sub_eff;
assign sr_in_30 = sb_out_eff_33; //sa33_sub_eff;
assign sr_in_31 = sb_out_eff_30; //sa30_sub_eff;
assign sr_in_32 = sb_out_eff_31; //sa31_sub_eff;
assign sr_in_33 = sb_out_eff_32; //sa32_sub_eff;
//assign {sa00_mc, sa10_mc, sa20_mc, sa30_mc} = mix_col(sa00_sr_eff,sa10_sr_eff,sa20_sr_eff,sa30_sr_eff);
//assign {sa01_mc, sa11_mc, sa21_mc, sa31_mc} = mix_col(sa01_sr_eff,sa11_sr_eff,sa21_sr_eff,sa31_sr_eff);
//assign {sa02_mc, sa12_mc, sa22_mc, sa32_mc} = mix_col(sa02_sr_eff,sa12_sr_eff,sa22_sr_eff,sa32_sr_eff);
//assign {sa03_mc, sa13_mc, sa23_mc, sa33_mc} = mix_col(sa03_sr_eff,sa13_sr_eff,sa23_sr_eff,sa33_sr_eff);
assign {mc_in_00, mc_in_10, mc_in_20, mc_in_30} = mix_col(sr_out_eff_00,sr_out_eff_10,sr_out_eff_20,sr_out_eff_30);
assign {mc_in_01, mc_in_11, mc_in_21, mc_in_31} = mix_col(sr_out_eff_01,sr_out_eff_11,sr_out_eff_21,sr_out_eff_31);
assign {mc_in_02, mc_in_12, mc_in_22, mc_in_32} = mix_col(sr_out_eff_02,sr_out_eff_12,sr_out_eff_22,sr_out_eff_32);
assign {mc_in_03, mc_in_13, mc_in_23, mc_in_33} = mix_col(sr_out_eff_03,sr_out_eff_13,sr_out_eff_23,sr_out_eff_33);
/*assign sa00_next = sa00_mc_eff ^ w0_eff[31:24];
assign sa01_next = sa01_mc_eff ^ w1_eff[31:24];
assign sa02_next = sa02_mc_eff ^ w2_eff[31:24];
assign sa03_next = sa03_mc_eff ^ w3_eff[31:24];
assign sa10_next = sa10_mc_eff ^ w0_eff[23:16];
assign sa11_next = sa11_mc_eff ^ w1_eff[23:16];
assign sa12_next = sa12_mc_eff ^ w2_eff[23:16];
assign sa13_next = sa13_mc_eff ^ w3_eff[23:16];
assign sa20_next = sa20_mc_eff ^ w0_eff[15:08];
assign sa21_next = sa21_mc_eff ^ w1_eff[15:08];
assign sa22_next = sa22_mc_eff ^ w2_eff[15:08];
assign sa23_next = sa23_mc_eff ^ w3_eff[15:08];
assign sa30_next = sa30_mc_eff ^ w0_eff[07:00];
assign sa31_next = sa31_mc_eff ^ w1_eff[07:00];
assign sa32_next = sa32_mc_eff ^ w2_eff[07:00];
assign sa33_next = sa33_mc_eff ^ w3_eff[07:00];*/
/*assign kx_out_00 = mc_out_eff_00 ^ w0[31:24];
assign kx_out_01 = mc_out_eff_01 ^ w1[31:24];
assign kx_out_02 = mc_out_eff_02 ^ w2[31:24];
assign kx_out_03 = mc_out_eff_03 ^ w3[31:24];
assign kx_out_10 = mc_out_eff_10 ^ w0[23:16];
assign kx_out_11 = mc_out_eff_11 ^ w1[23:16];
assign kx_out_12 = mc_out_eff_12 ^ w2[23:16];
assign kx_out_13 = mc_out_eff_13 ^ w3[23:16];
assign kx_out_20 = mc_out_eff_20 ^ w0[15:08];
assign kx_out_21 = mc_out_eff_21 ^ w1[15:08];
assign kx_out_22 = mc_out_eff_22 ^ w2[15:08];
assign kx_out_23 = mc_out_eff_23 ^ w3[15:08];
assign kx_out_30 = mc_out_eff_30 ^ w0[07:00];
assign kx_out_31 = mc_out_eff_31 ^ w1[07:00];
assign kx_out_32 = mc_out_eff_32 ^ w2[07:00];
assign kx_out_33 = mc_out_eff_33 ^ w3[07:00];*/

//assign kx_out_00 = mc_out_eff_00 ^ w0[31:24];
//assign kx_out_01 = mc_out_eff_01 ^ w1[31:24];
//assign kx_out_02 = mc_out_eff_02 ^ w2[31:24];
//assign kx_out_03 = mc_out_eff_03 ^ w3[31:24];
//assign kx_out_10 = mc_out_eff_10 ^ w0[23:16];
//assign kx_out_11 = mc_out_eff_11 ^ w1[23:16];
//assign kx_out_12 = mc_out_eff_12 ^ w2[23:16];
//assign kx_out_13 = mc_out_eff_13 ^ w3[23:16];
//assign kx_out_20 = mc_out_eff_20 ^ w0[15:08];
//assign kx_out_21 = mc_out_eff_21 ^ w1[15:08];
//assign kx_out_22 = mc_out_eff_22 ^ w2[15:08];
//assign kx_out_23 = mc_out_eff_23 ^ w3[15:08];
//assign kx_out_30 = mc_out_eff_30 ^ w0[07:00];
//assign kx_out_31 = mc_out_eff_31 ^ w1[07:00];
//assign kx_out_32 = mc_out_eff_32 ^ w2[07:00];
//assign kx_out_33 = mc_out_eff_33 ^ w3[07:00];




/////////////////////////////////////////////////////////////////////////////////////////
//
//        AES Round 10
//
/////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////
//
//        AES Final Output
//
/////////////////////////////////////////////////////////////////////////////////////////

/*always @(posedge clk) text_out[127:120] <= #1 sa00_sr_eff ^ w0_eff[31:24];
always @(posedge clk) text_out[095:088] <= #1 sa01_sr_eff ^ w1_eff[31:24];
always @(posedge clk) text_out[063:056] <= #1 sa02_sr_eff ^ w2_eff[31:24];
always @(posedge clk) text_out[031:024] <= #1 sa03_sr_eff ^ w3_eff[31:24];
always @(posedge clk) text_out[119:112] <= #1 sa10_sr_eff ^ w0_eff[23:16];
always @(posedge clk) text_out[087:080] <= #1 sa11_sr_eff ^ w1_eff[23:16];
always @(posedge clk) text_out[055:048] <= #1 sa12_sr_eff ^ w2_eff[23:16];
always @(posedge clk) text_out[023:016] <= #1 sa13_sr_eff ^ w3_eff[23:16];
always @(posedge clk) text_out[111:104] <= #1 sa20_sr_eff ^ w0_eff[15:08];
always @(posedge clk) text_out[079:072] <= #1 sa21_sr_eff ^ w1_eff[15:08];
always @(posedge clk) text_out[047:040] <= #1 sa22_sr_eff ^ w2_eff[15:08];
always @(posedge clk) text_out[015:008] <= #1 sa23_sr_eff ^ w3_eff[15:08];
always @(posedge clk) text_out[103:096] <= #1 sa30_sr_eff ^ w0_eff[07:00];
always @(posedge clk) text_out[071:064] <= #1 sa31_sr_eff ^ w1_eff[07:00];
always @(posedge clk) text_out[039:032] <= #1 sa32_sr_eff ^ w2_eff[07:00];
always @(posedge clk) text_out[007:000] <= #1 sa33_sr_eff ^ w3_eff[07:00];*/

/*always @(posedge clk) text_out[127:120] <= #1 done ? sr_out_eff_00 ^ w0[31:24] : 8'd0;
always @(posedge clk) text_out[095:088] <= #1 done ? sr_out_eff_01 ^ w1[31:24] : 8'd0;
always @(posedge clk) text_out[063:056] <= #1 done ? sr_out_eff_02 ^ w2[31:24] : 8'd0;
always @(posedge clk) text_out[031:024] <= #1 done ? sr_out_eff_03 ^ w3[31:24] : 8'd0;
always @(posedge clk) text_out[119:112] <= #1 done ? sr_out_eff_10 ^ w0[23:16] : 8'd0;
always @(posedge clk) text_out[087:080] <= #1 done ? sr_out_eff_11 ^ w1[23:16] : 8'd0;
always @(posedge clk) text_out[055:048] <= #1 done ? sr_out_eff_12 ^ w2[23:16] : 8'd0;
always @(posedge clk) text_out[023:016] <= #1 done ? sr_out_eff_13 ^ w3[23:16] : 8'd0;
always @(posedge clk) text_out[111:104] <= #1 done ? sr_out_eff_20 ^ w0[15:08] : 8'd0;
always @(posedge clk) text_out[079:072] <= #1 done ? sr_out_eff_21 ^ w1[15:08] : 8'd0;
always @(posedge clk) text_out[047:040] <= #1 done ? sr_out_eff_22 ^ w2[15:08] : 8'd0;
always @(posedge clk) text_out[015:008] <= #1 done ? sr_out_eff_23 ^ w3[15:08] : 8'd0;
always @(posedge clk) text_out[103:096] <= #1 done ? sr_out_eff_30 ^ w0[07:00] : 8'd0;
always @(posedge clk) text_out[071:064] <= #1 done ? sr_out_eff_31 ^ w1[07:00] : 8'd0;
always @(posedge clk) text_out[039:032] <= #1 done ? sr_out_eff_32 ^ w2[07:00] : 8'd0;
always @(posedge clk) text_out[007:000] <= #1 done ? sr_out_eff_33 ^ w3[07:00] : 8'd0;*/

//always @(posedge clk) text_out[127:120] <= #1 sr_out_eff_00 ^ w0_eff[31:24];
//always @(posedge clk) text_out[095:088] <= #1 sr_out_eff_01 ^ w1_eff[31:24];
//always @(posedge clk) text_out[063:056] <= #1 sr_out_eff_02 ^ w2_eff[31:24];
//always @(posedge clk) text_out[031:024] <= #1 sr_out_eff_03 ^ w3_eff[31:24];
//always @(posedge clk) text_out[119:112] <= #1 sr_out_eff_10 ^ w0_eff[23:16];
//always @(posedge clk) text_out[087:080] <= #1 sr_out_eff_11 ^ w1_eff[23:16];
//always @(posedge clk) text_out[055:048] <= #1 sr_out_eff_12 ^ w2_eff[23:16];
//always @(posedge clk) text_out[023:016] <= #1 sr_out_eff_13 ^ w3_eff[23:16];
//always @(posedge clk) text_out[111:104] <= #1 sr_out_eff_20 ^ w0_eff[15:08];
//always @(posedge clk) text_out[079:072] <= #1 sr_out_eff_21 ^ w1_eff[15:08];
//always @(posedge clk) text_out[047:040] <= #1 sr_out_eff_22 ^ w2_eff[15:08];
//always @(posedge clk) text_out[015:008] <= #1 sr_out_eff_23 ^ w3_eff[15:08];
//always @(posedge clk) text_out[103:096] <= #1 sr_out_eff_30 ^ w0_eff[07:00];
//always @(posedge clk) text_out[071:064] <= #1 sr_out_eff_31 ^ w1_eff[07:00];
//always @(posedge clk) text_out[039:032] <= #1 sr_out_eff_32 ^ w2_eff[07:00];
//always @(posedge clk) text_out[007:000] <= #1 sr_out_eff_33 ^ w3_eff[07:00];


/*always @(posedge clk) text_out[127:120] <= #1 sr_out_eff_00 ^ key_out[127:120];
always @(posedge clk) text_out[095:088] <= #1 sr_out_eff_01 ^ key_out[095:088];
always @(posedge clk) text_out[063:056] <= #1 sr_out_eff_02 ^ key_out[063:056];
always @(posedge clk) text_out[031:024] <= #1 sr_out_eff_03 ^ key_out[031:024];
always @(posedge clk) text_out[119:112] <= #1 sr_out_eff_10 ^ key_out[119:112];
always @(posedge clk) text_out[087:080] <= #1 sr_out_eff_11 ^ key_out[087:080];
always @(posedge clk) text_out[055:048] <= #1 sr_out_eff_12 ^ key_out[055:048];
always @(posedge clk) text_out[023:016] <= #1 sr_out_eff_13 ^ key_out[023:016];
always @(posedge clk) text_out[111:104] <= #1 sr_out_eff_20 ^ key_out[111:104];
always @(posedge clk) text_out[079:072] <= #1 sr_out_eff_21 ^ key_out[079:072];
always @(posedge clk) text_out[047:040] <= #1 sr_out_eff_22 ^ key_out[047:040];
always @(posedge clk) text_out[015:008] <= #1 sr_out_eff_23 ^ key_out[015:008];
always @(posedge clk) text_out[103:096] <= #1 sr_out_eff_30 ^ key_out[103:096];
always @(posedge clk) text_out[071:064] <= #1 sr_out_eff_31 ^ key_out[071:064];
always @(posedge clk) text_out[039:032] <= #1 sr_out_eff_32 ^ key_out[039:032];
always @(posedge clk) text_out[007:000] <= #1 sr_out_eff_33 ^ key_out[007:000];*/




/////////////////////////////////////////////////////////////////////////////////////////
//
//        CED State Machine
//
/////////////////////////////////////////////////////////////////////////////////////////
/*
A two bit input signal (called MODE) determines if CED is going to occur.
("00": Normal operation, "01": repeating all rounds,
"10": repeating only one round which is determined by
another 4 bit input called "Round".
*/
// Reset Logic
always @ (posedge rst) begin
  if (rst) begin
    done = 0;
    error = 0;
    init_perm = 1;
    //fault_detected = 0;
    //fault_location = 0;
    round_cnt      = 0;
	 key_sel = 1;
    //MUXs
    ns_sel = 0;
    mc_mux_sel          = 1;
    //keys_mux_sel = 1;
    plain_mux_sel = 1;
    state_mux_sel = 0;
    round_input_mux_sel = 1;
    temp_sel = 1;
    repeat_ced = 0;
    //control of AES clock
    // ??
	 read_key_mem = 1;
	 ld_key_mem = 1;
  end
  else begin
    round_cnt = round_cnt;
  end
end

// AES + CED State Machine
always @ (posedge clk) begin
  case (ced_mode)
    2'b00: // Normal AES round;
          begin
           // Initial Permutations
            if (round_cnt == 0 && init_perm) begin
              plain_mux_sel = 1;
			  key_sel = 1;
             // keys_mux_sel = 1;
              state_mux_sel = 1;
              round_input_mux_sel = 1;
              init_perm = 0;
				  read_key_mem = 1;
				  ns_sel = 0;
            end
           // AES rounds
            else if (round_cnt < 4'd10 && ~init_perm) begin
              ns_sel = 1;
              plain_mux_sel = 1;
              state_mux_sel = 1;
              round_input_mux_sel = 1;
              temp_sel = 0;
              round_cnt = round_cnt + 1;
				      if (round_cnt == 4'd9) begin
				        done = 0;
				      end
            end
           // final round
            else if (round_cnt == 4'd10) begin
              mc_mux_sel = 0;
				      done = 0;
				      round_cnt = round_cnt + 1;
            end
				    else if (round_cnt == 4'd11) begin
				      done = 1;
				    end
            else begin
              init_perm = 1;
            end
          end
    2'b01: //AES Rounds with CED at all rounds
          begin
          //Initial Permutation
            if (round_cnt == 0 && init_perm) begin
				  key_sel = 0;
				  read_key_mem = 1;
				  key_addr = 4'd0;
              ns_sel = 0;
              plain_mux_sel = 1;
              //keys_mux_sel = repeat_ced;
              state_mux_sel = 1;
              round_input_mux_sel = 1;
              init_perm = 0;
              //now do repeat with CED
              repeat_ced = 1;
            end
            else if (round_cnt == 0 && repeat_ced && ~init_perm) begin
              // CED operation
              plain_mux_sel = 1;
              //keys_mux_sel = repeat_ced;
              repeat_ced = 0;
              init_perm = 0;
              round_input_mux_sel = 0;
              round_cnt = round_cnt + 1;
            end
            // Rounds 1 to 9
            else if (round_cnt < 4'd10 && ~init_perm && ~repeat_ced) begin
				  key_addr = round_cnt;
              ns_sel = 1;
              //keys_mux_sel = repeat_ced;
              round_input_mux_sel = 1;
              temp_sel = 0;
              mc_mux_sel = 1;
              plain_mux_sel = 0;
              state_mux_sel = 0;
              repeat_ced = 1;
            end
            else if (round_cnt < 4'd10 && ~init_perm && repeat_ced) begin
              //keys_mux_sel = repeat_ced;
              round_input_mux_sel = 0;
              repeat_ced = 0;
              round_cnt = round_cnt + 1;
            end
            // round 10
            else if (round_cnt == 4'd10 && ~repeat_ced) begin
              mc_mux_sel = 0;
              //keys_mux_sel = repeat_ced;
             round_input_mux_sel =1;
              repeat_ced = 1;
            end
            else if (round_cnt == 4'd10 && repeat_ced ) begin
              //keys_mux_sel =repeat_ced;
              round_input_mux_sel =0;
              repeat_ced = 0;
              done = 1;
            end
            else begin
              done = 0;
              init_perm = 1;
            end
          end
    2'b10 : // AES with CED repeat for Selected Round
            begin
              if (round_cnt == ced_round) begin
                repeat_ced = 1;
              end
              else begin
                repeat_ced = 0;
              end

            //Initial Permutation
              if (round_cnt == 0 && init_perm && ~repeat_ced) begin
                ns_sel = 1;
                plain_mux_sel = 1;
                //keys_mux_sel = 1;
                state_mux_sel = 1;
                //round_input_mux_sel = 1;
                init_perm = 0;
                //now do repeat with CED
                //repeat_ced = 1;
              end
              else if (round_cnt == 0 && repeat_ced && ~init_perm) begin
                // CED operation
                plain_mux_sel = 1;
                //keys_mux_sel = 1;
                //repeat_ced = 1;
                init_perm = 0;
                //round_input_mux_sel = 1;
                round_cnt = round_cnt + 1;
              end
              // Rounds 1 to 9
              else if (round_cnt < 4'd10 && ~init_perm && ~repeat_ced) begin
                ns_sel = 0;
                mc_mux_sel = 1;
                plain_mux_sel = 0;
                //keys_mux_sel = 1;
                //round_input_mux_sel = 1;
                state_mux_sel = 0;
                //repeat_ced = 1;
              end
              else if (round_cnt < 4'd10 && ~init_perm && repeat_ced) begin
                //keys_mux_sel = 0;
                //round_input_mux_sel = 0;
                //repeat_ced = 0;
                round_cnt = round_cnt + 1;
              end
              // round 10
              else if (round_cnt == 4'd10 && ~repeat_ced) begin
                mc_mux_sel = 0;
                //keys_mux_sel = 1;
                //round_input_mux_sel = 1;
                //repeat_ced = 1;
              end
              else if (round_cnt == 4'd10 && repeat_ced ) begin
                //keys_mux_sel = 0;
                //round_input_mux_sel = 0;
                //repeat_ced = 0;
                done = 1;
              end
              else begin
                done = 0;
                init_perm = 1;
              end
            end
    default: begin
              done = 0;
              error = 1;
             end
  endcase
end

/////////////////////////////////////////////////////////////////////////////////////////
//
//        Modules for AES Operation
//
/////////////////////////////////////////////////////////////////////////////////////////
aes_key_expand_128 u0(
	.clk(		clk	),
	.kld(		ld	),
	.key(		key	),
	.wo_0(		w0_out	),
	.wo_1(		w1_out	),
	.wo_2(		w2_out	),
	.wo_3(		w3_out	));

  aes_sbox us00(	.a(	sa00	), .d(	sb_in_00	));
  aes_sbox us01(	.a(	sa01	), .d(	sb_in_01	));
  aes_sbox us02(	.a(	sa02	), .d(	sb_in_02	));
  aes_sbox us03(	.a(	sa03	), .d(	sb_in_03	));
  aes_sbox us10(	.a(	sa10	), .d(	sb_in_10	));
  aes_sbox us11(	.a(	sa11	), .d(	sb_in_11	));
  aes_sbox us12(	.a(	sa12	), .d(	sb_in_12	));
  aes_sbox us13(	.a(	sa13	), .d(	sb_in_13	));
  aes_sbox us20(	.a(	sa20	), .d(	sb_in_20	));
  aes_sbox us21(	.a(	sa21	), .d(	sb_in_21	));
  aes_sbox us22(	.a(	sa22	), .d(	sb_in_22	));
  aes_sbox us23(	.a(	sa23	), .d(	sb_in_23	));
  aes_sbox us30(	.a(	sa30	), .d(	sb_in_30	));
  aes_sbox us31(	.a(	sa31	), .d(	sb_in_31	));
  aes_sbox us32(	.a(	sa32	), .d(	sb_in_32	));
  aes_sbox us33(	.a(	sa33	), .d(	sb_in_33	));

/////////////////////////////////////////////////////////////////////////////////////////
//
//        Fault Injector Module
//
/////////////////////////////////////////////////////////////////////////////////////////

  fault_injector xFault_Injector (
      .en(en_FI), //.................enable this module : 1-enable
      .mode(mode_FI), //.............0 - bit fault / 1 - byte fault
      .func(func_FI), //.............func = 0 for sbox,1 for shiftrow,2 for mixcolumn,3 for keyxor.
      .round(round_FI), //...........round where fault will be injected
      .round_stop(round_stop),//.....round where fault insertion will stop
      .row(row_FI), //...............row offset for fault injection
      .column(column_FI), //.........column offset for fault injection
      .bit_index(bit_index_FI), //...but offset for fault injection
      .round_in(round_cnt), //.......input for on-going AES round
      .error(error_FI),//............error in giving values to fault injector
      .data_in_sb(plain_op), //.....128-bit sbox original input
      .data_in_sr(sb_in), //.....128-bit shiftRows original input
      .data_in_mx(sr_in), //.....128-bit MixColumn original input
      .data_in_kx(mc_in), //.....128-bit KeyXor original input
      .data_out_sb(plain_op_eff), //...128-bit sbox effective or faulty input
      .data_out_sr(sb_out_eff), //...128-bit shiftRows effective or faulty input
      .data_out_mx(sr_out_eff), //...128-bit MixColumn effective or faulty input
      .data_out_kx(mc_out_eff)//,//..128-bit KeyXor effective or faulty input
  		);

/////////////////////////////////////////////////////////////////////////////////////////
//
//        Functions
//
/////////////////////////////////////////////////////////////////////////////////////////

function [31:0] mix_col;
input	[7:0]	s0,s1,s2,s3;
reg	[7:0]	s0_o,s1_o,s2_o,s3_o;
begin
mix_col[31:24]=xtime(s0)^xtime(s1)^s1^s2^s3;
mix_col[23:16]=s0^xtime(s1)^xtime(s2)^s2^s3;
mix_col[15:08]=s0^s1^xtime(s2)^xtime(s3)^s3;
mix_col[07:00]=xtime(s0)^s0^s1^s2^xtime(s3);
end
endfunction

function [7:0] xtime;
input [7:0] b; xtime={b[6:0],1'b0}^(8'h1b&{8{b[7]}});
endfunction

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


endmodule //aes_top
