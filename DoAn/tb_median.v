`timescale 1ns / 1ps
module tb_median();
reg clk, rst_n, start;
wire done;
median_processor dut (
.clk(clk), .rst_n(rst_n), .start(start), .done(done)
);
// tao xung clock
initial clk = 0;
always #5 clk = ~clk;
initial begin
// Khoi tao cac tin hieu
rst_n = 0; start = 0;
#20 rst_n = 1;
#20 start = 1; // bat dau chay
wait(done); // cho den khi xong
$display("Da loc xong anh!");
$finish;
end
endmodule