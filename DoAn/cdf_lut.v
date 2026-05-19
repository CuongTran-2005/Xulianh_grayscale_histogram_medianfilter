module cdf_lut #(
	 parameter GRAYSCALE = 256,
	 parameter WIDTH = 698,
	 parameter HEIGHT = 463,
	 parameter TOTAL_PIXELS = WIDTH * HEIGHT
)
(
    input clk,
    input rst_n,
    input cdf_lut_start,
	 input [32 * GRAYSCALE -1:0] hist_in,
    output reg lut_done,
	 output reg [8 * GRAYSCALE -1:0] lut_out
);


//parameter HIST_FILE = "Anhoutput.txt";   // file histogram input
//parameter LUT_FILE  = "lut_output.txt";   // file output

//reg [31:0] hist [0:255];
//reg [7:0]  lut  [0:255];

integer i;
integer file_out;

reg [31:0] cdf;
reg write_done;
reg [7:0] count;

/*initial begin
    $readmemh(HIST_FILE, hist);   // đọc histogram từ file
    file_out = $fopen(LUT_FILE, "w");
end */


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lut_done <= 0;
        cdf <= 0;
        write_done <= 0;
		  count <= 0;
    end
    else if (cdf_lut_start && !lut_done) begin
		  //cdf = 0;
        // tính CDF + LUT
        //for (i = 0; i < 256; i = i + 1) 
		  //begin
			cdf = cdf + hist_in[count * 32 +:32];
			// scale về 0–255
			lut_out[count * 8 +: 8] = (cdf * 255) / TOTAL_PIXELS;
			count = count + 1;
        //end
		  if (count == 256) lut_done = 1;
		  //$display("--- DONE: Da ghi cdf_lut xong ---");
    end
end


// ghi LUT ra file
/*always @(posedge clk) begin
    if (done && !write_done) begin
        for (i = 0; i < 256; i = i + 1)
            $fwrite(file_out, "%0h\n", lut[i]);

        $fclose(file_out);
        write_done <= 1;
    end
end
*/
endmodule