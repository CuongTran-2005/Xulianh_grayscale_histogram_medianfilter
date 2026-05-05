module swap(
input [7:0] a, input [7:0] b,
output [7:0] min, output [7:0] max
);
assign min = (a <= b) ? a : b;
assign max = (a <= b) ? b : a;
endmodule