module equalize #(
	 parameter GRAYSCALE = 256,
	 parameter WIDTH = 430,
	 parameter HEIGHT = 554,
	 parameter TOTAL_PIXELS = WIDTH * HEIGHT
)
(
    input clk,
    input rst_n,
    input equalize_start,
	 //input [7:0] image_memory,
	 input [8 * GRAYSCALE -1:0] lut_in,
    output reg write_done
	 //output reg [7:0] anhoutput
);

parameter IMAGE_IN  = "Anhoutput.txt";
//parameter LUT_FILE  = "lut_output.txt";
parameter IMAGE_OUT = "Anhoutput_equalized.txt";

reg [7:0] image_memory [0:TOTAL_PIXELS-1];
//reg [7:0] lut [0:255];

reg [7:0] reg_anhoutput [0:TOTAL_PIXELS-1];
integer file_out;
integer i;
integer x, y;

//reg write_done;
reg equalize_done;

initial begin
    // đọc ảnh
    $readmemh(IMAGE_IN, image_memory);

    // đọc LUT
    //$readmemh(LUT_FILE, lut);

    // mở file output
    file_out = $fopen(IMAGE_OUT, "w");
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        equalize_done <= 0;
        x <= 0;
        y <= 0;
        write_done <= 0;
    end

    else if (equalize_start && !equalize_done) begin
        // mapping pixel
        reg_anhoutput[y*WIDTH + x] <= lut_in[ image_memory[y*WIDTH+x]*8 +: 8 ];

        // duyệt ảnh
        if (x < WIDTH - 1)
            x <= x + 1;
        else begin
            x <= 0;
            if (y < HEIGHT - 1)
                y <= y + 1;
            else
                equalize_done <= 1;
        end
    end
end


// ghi ảnh ra file

always @(posedge clk) begin
    if (equalize_done && !write_done) begin
        for (i = 0; i < TOTAL_PIXELS; i = i + 1)
            $fwrite(file_out, "%02h\n", reg_anhoutput[i]);

        $fclose(file_out);
        write_done <= 1;
		   $display("--- DONE: Da ghi equalize xong ---");
    end
end 

endmodule