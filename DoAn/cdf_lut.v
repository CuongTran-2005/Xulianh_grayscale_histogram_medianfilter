module cdf_lut (
    input clk,
    input rst,
    input start,
    output reg done
);

parameter WIDTH = 430;
parameter HEIGHT = 554;
parameter TOTAL_PIXELS = WIDTH * HEIGHT;
parameter HIST_FILE = "Anhoutput.txt";   // file histogram input
parameter LUT_FILE  = "lut_output.txt";   // file output

reg [31:0] hist [0:255];
reg [7:0]  lut  [0:255];

integer i;
integer file_out;

reg [31:0] cdf;
reg write_done;

initial begin
    $readmemh(HIST_FILE, hist);   // đọc histogram từ file
    file_out = $fopen(LUT_FILE, "w");
end


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        done <= 0;
        cdf <= 0;
        write_done <= 0;
    end

    else if (start && !done) begin

        // tính CDF + LUT
        for (i = 0; i < 256; i = i + 1) 
		  begin
            cdf = cdf + hist[i];

            // scale về 0–255
            lut[i] = (cdf * 255) / TOTAL_PIXELS;
        end

        done <= 1;
    end
end


// ghi LUT ra file
always @(posedge clk) begin
    if (done && !write_done) begin
        for (i = 0; i < 256; i = i + 1)
            $fwrite(file_out, "%0h\n", lut[i]);

        $fclose(file_out);
        write_done <= 1;
    end
end

endmodule