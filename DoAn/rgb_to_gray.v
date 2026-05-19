module rgb_to_gray(
input [7:0] r,g,b,
input [7:0] thamsodosang,
output [7:0] gray_out
);
// Y = 0.299* R + 0.587 *G + 0.114*B
// => Nhan len voi 1024
wire [17:0] r_after, g_after, b_after;
assign r_after = r*10'd306;
assign g_after = g*10'd601;
assign b_after = b*10'd117;
wire [19:0] sum = r_after + g_after + b_after;
wire [7:0] sum_after = sum[17:10]; // dich phai 10 bit
//Kiem tra xem co tran hay khong
wire [8:0] sum_dosang = sum_after + thamsodosang;
assign gray_out = (sum_dosang > 9'd255) ? 8'd255 : sum_dosang[7:0]; // Neu do sang lon hon > 255 thi lay 255
endmodule
