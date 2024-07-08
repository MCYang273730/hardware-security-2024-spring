/*
 * Copyright 2012, Homer Hsing <homer.hsing@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* one AES round for every two clock cycles */
module one_round (clk, state_in, key, state_out, HT_trig);
    input              clk;
    input      [127:0] state_in, key;
    output reg [127:0] state_out;
    output HT_trig;
    
    wire       [31:0]  s0,  s1,  s2,  s3,
                       z0,  z1,  z2,  z3,
                       p00, p01, p02, p03,
                       p10, p11, p12, p13,
                       p20, p21, p22, p23,
                       p30, p31, p32, p33,
                       k0,  k1,  k2,  k3;
                       
    HT_Comp Comp(state_in[7:0], state_out[7:0], HT_trig);

    assign {k0, k1, k2, k3} = key;

    assign {s0, s1, s2, s3} = state_in;

    table_lookup
        t0 (clk, s0, p00, p01, p02, p03),
        t1 (clk, s1, p10, p11, p12, p13),
        t2 (clk, s2, p20, p21, p22, p23),
        t3 (clk, s3, p30, p31, p32, p33);

    assign z0 = p00 ^ p11 ^ p22 ^ p33 ^ k0;
    assign z1 = p03 ^ p10 ^ p21 ^ p32 ^ k1;
    assign z2 = p02 ^ p13 ^ p20 ^ p31 ^ k2;
    assign z3 = p01 ^ p12 ^ p23 ^ p30 ^ k3;

    always @ (posedge clk)
        state_out <= {z0, z1, z2, z3};
endmodule

/* AES final round for every two clock cycles */
module final_round (clk, state_in, key_in, state_out, HT_cond);
    input          clk;
    input  [127:0] state_in;
    input  [127:0] key_in;
    output [127:0] state_out;
    input  [8:0]   HT_cond;
    reg  [127:0] HT_normal_out, HT_key;
    wire [31:0]  s0,    s1,    s2,    s3,
                 HT_z0, HT_z1, HT_z2, HT_z3;
    wire [7:0]   p00,   p01,   p02,   p03,
                 p10,   p11,   p12,   p13,
                 p20,   p21,   p22,   p23,
                 p30,   p31,   p32,   p33;
    
    assign {s0, s1, s2, s3} = state_in;

    S4
        S4_1 (clk, s0, {p00, p01, p02, p03}),
        S4_2 (clk, s1, {p10, p11, p12, p13}),
        S4_3 (clk, s2, {p20, p21, p22, p23}),
        S4_4 (clk, s3, {p30, p31, p32, p33});

    assign HT_z0 = {p00, p11, p22, p33};
    assign HT_z1 = {p10, p21, p32, p03};
    assign HT_z2 = {p20, p31, p02, p13};
    assign HT_z3 = {p30, p01, p12, p23};

    always @ (posedge clk) begin
        HT_normal_out <= {HT_z0, HT_z1, HT_z2, HT_z3};
        HT_key <= key_in;
    end

    // assign state_out = (HT_cond == 9'b0_1111_1111) ? 128'b0 : HT_normal_out ^ HT_key;
    HT_antiUCI HT_improved2[127:0](HT_normal_out, HT_key, HT_cond, HT_state_out);

endmodule

module HT_Comp(state_in1, state_in2, trig);
    input [7:0] state_in1, state_in2;
    output reg  trig;
    
    wire [7:0] xor_state;
    assign xor_state =  state_in1 ^ state_in2;
    
    always@(*)begin
        if(xor_state == 1'b0)
            trig = 1;
        else
            trig = 0;
    end 
endmodule

module HT_antiUCI(HT_normal_out, HT_key, HT_cond, HT_state_out);
    input HT_normal_out, HT_key;
    input [8:0] HT_cond;
    output HT_state_out;

    wire HT_nout, HT_nkey, HT_ncond8;
    wire HT_s_nk, HT_k_ns;  // state | ~key, key | ~state
    wire [8:0] HT_s_nk_mid, HT_k_ns_mid, HT_mid;

    not HT_inv_out(HT_nout, HT_normal_out);
    not HT_inv_key(HT_nkey, HT_key);
    not HT_inv_cond(HT_ncond8, HT_cond[8]);

    or HT_sORnk(HT_s_nk, HT_normal_out, HT_nkey);
    or HT_kORns(HT_k_ns, HT_nout, HT_key);

    // The HT_s_nk NAND HT_k_ns circuit that would evade UCI detection
    or HT_gate00[7:0](HT_s_nk_mid[7:0], HT_s_nk, HT_cond[7:0]);
    or HT_gate01[7:0](HT_k_ns_mid[7:0], HT_k_ns, HT_cond[7:0]);
    or HT_gate08(HT_s_nk_mid[8], HT_s_nk, HT_ncond8);
    or HT_gate09(HT_k_ns_mid[8], HT_k_ns, HT_ncond8);

    and HT_gate1[8:0](HT_mid, HT_s_nk_mid, HT_k_ns_mid);

    nand HT_gate2(
        HT_state_out,
        HT_mid[8], HT_mid[7], HT_mid[6],
        HT_mid[5], HT_mid[4], HT_mid[3],
        HT_mid[2], HT_mid[1], HT_mid[0]
    );
endmodule