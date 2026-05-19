`timescale 1ns/1ps
module tb_rgb_to_gray(); 
reg clk;
reg rst_n; 
reg start; 
wire done;
reg [7:0] r, g, b; 
reg [7:0] thamsodosang; 
wire [7:0] gray_out;

parameter WIDTH = 644; 
parameter HEIGHT = 433;
parameter TOTAL_PIXELS = WIDTH * HEIGHT; 
parameter DOSANG = 8'd50;

reg [23:0] memory [0:TOTAL_PIXELS-1]; 
integer i = 0; 
integer file_out;

// Logic tao tin hieu done
assign done = (i == TOTAL_PIXELS);
rgb_to_gray uut (
.r(r), .g(g), .b(b), 
.thamsodosang(thamsodosang),
.gray_out(gray_out) 
);
//Khoi tao
initial clk = 0; 
always #5 clk = ~clk;

initial begin 
rst_n = 0; 
start = 0;
thamsodosang = DOSANG;

$readmemh("c:/Nam_3_HK2_2025_2026/HDL/Do_an_mon/pic_input_2.txt", memory); 
file_out = $fopen("c:/Nam_3_HK2_2025_2026/HDL/Do_an_mon/output_gray_50.txt", "w");
#20 rst_n = 1; 
#10 start = 1;
end
	//Khoi xu ly
always @(posedge clk or negedge rst_n) begin 
if (!rst_n) begin 
i <= 0;
r <= 0; g <= 0; b <= 0; 
end
else if (start) begin
if (i < TOTAL_PIXELS) begin 
r <= memory[i][23:16]; 
g <= memory[i][15:8]; 
b <= memory[i][7:0];
if (i > 0) begin
$fwrite(file_out, "%h\n", gray_out); 
end
i <= i + 1; 
end
else begin
$fwrite(file_out, "%h\n", gray_out); 
$fclose(file_out);
$display("XU LY HOAN THANH: %0d x %0d pixels", WIDTH, HEIGHT); 
#10; // Cho tin hieu done hien thi tren waveform 
$finish; 
end 
end
end
endmodule
