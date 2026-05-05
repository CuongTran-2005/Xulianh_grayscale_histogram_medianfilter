module median (
input [7:0] p0, p1, p2, p3, p4, p5, p6, p7, p8,
output [7:0] out_median
);
// day trung gian cho 9 tang
wire [7:0] s1[0:8], s2[0:8], s3[0:8], s4[0:8], s5[0:8],
s6[0:8], s7[0:8], s8[0:8], s9[0:8];
//stage 1
swap sw1_0(p0, p1, s1[0], s1[1]);
swap sw1_1(p2, p3, s1[2], s1[3]);
swap sw1_2(p4, p5, s1[4], s1[5]);
swap sw1_3(p6, p7, s1[6], s1[7]);
assign s1[8] = p8;
// stage 2
swap sw2_0(s1[1], s1[2], s2[1], s2[2]);
swap sw2_1(s1[3], s1[4], s2[3], s2[4]);
swap sw2_2(s1[5], s1[6], s2[5], s2[6]);
swap sw2_3(s1[7], s1[8], s2[7], s2[8]);
assign s2[0] = s1[0];
// stage 3
swap sw3_0(s2[0], s2[1], s3[0], s3[1]);
swap sw3_1(s2[2], s2[3], s3[2], s3[3]);
swap sw3_2(s2[4], s2[5], s3[4], s3[5]);
swap sw3_3(s2[6], s2[7], s3[6], s3[7]);
assign s3[8] = s2[8];
// stage 4
swap sw4_0(s3[0], s3[2], s4[0], s4[2]);
swap sw4_1(s3[1], s3[3], s4[1], s4[3]);
swap sw4_2(s3[4], s3[6], s4[4], s4[6]);
swap sw4_3(s3[5], s3[7], s4[5], s4[7]);
assign s4[8] = s3[8];
// stage 5
swap sw5_0(s4[1], s4[2], s5[1], s5[2]);
swap sw5_1(s4[5], s4[6], s5[5], s5[6]);
swap sw5_2(s4[0], s4[4], s5[0], s5[4]);
swap sw5_3(s4[3], s4[7], s5[3], s5[7]);
assign s5[8] = s4[8];
// stage 6
swap sw6_0(s5[1], s5[5], s6[1], s6[5]);
swap sw6_1(s5[2], s5[6], s6[2], s6[6]);
swap sw6_2(s5[0], s5[8], s6[0], s6[8]);
assign s6[3] = s5[3];
assign s6[4] = s5[4];
assign s6[7] = s5[7];
// stage 7
swap sw7_0(s6[2], s6[4], s7[2], s7[4]);
swap sw7_1(s6[3], s6[5], s7[3], s7[5]);
assign s7[0] = s6[0];
assign s7[1] = s6[1];
assign s7[6] = s6[6];
assign s7[7] = s6[7];
assign s7[8] = s6[8];
// stage 8
swap sw8_0(s7[2], s7[3], s8[2], s8[3]);
swap sw8_1(s7[4], s7[5], s8[4], s8[5]);
assign s8[0] = s7[0];
assign s8[1] = s7[1];
assign s8[6] = s7[6];
assign s8[7] = s7[7];
assign s8[8] = s7[8];
// stage 9
wire [7:0] u9_3, u9_5;
swap sw9_0(s8[3], s8[5], s9[3], s9[5]);
swap sw9_1(s8[4], s9[5], s9[4], u9_5);
swap sw9_2(s9[3], s9[4], u9_3, out_median);
endmodule