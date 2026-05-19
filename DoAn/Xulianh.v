module Xulianh #(
	 parameter GRAYSCALE = 256,
	 parameter WIDTH = 698,
	 parameter HEIGHT = 463,
	 parameter TOTAL_PIXELS = WIDTH * HEIGHT
)(
	 input clk,
    input rst_n,
	 input start,
	 output done
);
wire median_done;
reg histogram_start;
always @(posedge clk or negedge rst_n)
begin
	if (!rst_n)
	begin
		histogram_start <=0;
		//$display("--- reset hist_start= %b,  median_done = %b ---", histogram_start, median_done);
	end
	else
	begin
	//$display("hist_start= %b,  median_done = %b ---", histogram_start, median_done);
	if (median_done == 1)
		histogram_start <=1;
	end
end
median_processor u_mp(
	 .clk (clk),
	 .rst_n (rst_n),
	 .start (start),
	 .done (median_done)
);

histogram_top u_ht (
	 .clk (clk),
	 .rst_n (rst_n),
	 .start (histogram_start),
	 .done (done)
);
endmodule