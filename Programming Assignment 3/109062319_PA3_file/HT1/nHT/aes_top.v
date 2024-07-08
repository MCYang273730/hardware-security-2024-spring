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
	
	// Instantiation of AES encryption module
	aes_128 AES (.clk(clk), .rst(rst), .state(state), .key(key), .out(out)); 
 
endmodule 