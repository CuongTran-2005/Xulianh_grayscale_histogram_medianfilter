module equalize (
    input clk,
    input rst,
    input start,
    output reg done
);

parameter WIDTH = 430;
parameter HEIGHT = 554;
parameter TOTAL_PIXELS = WIDTH * HEIGHT;

parameter IMAGE_IN  = "Anhinput.txt";
parameter LUT_FILE  = "lut_output.txt";
parameter IMAGE_OUT = "Anhoutput_equalized.txt";

reg [7:0] image_memory [0:TOTAL_PIXELS-1];
reg [7:0] lut [0:255];

integer file_out;
integer i;
integer x, y;

reg write_done;

initial begin
    // đọc ảnh
    $readmemh(IMAGE_IN, image_memory);

    // đọc LUT
    $readmemh(LUT_FILE, lut);

    // mở file output
    file_out = $fopen(IMAGE_OUT, "w");
end


always @(posedge clk or negedge rst) begin
    if (!rst) begin
        done <= 0;
        x <= 0;
        y <= 0;
        write_done <= 0;
    end

    else if (start && !done) begin
        // mapping pixel
        image_memory[y*WIDTH + x] <= lut[image_memory[y*WIDTH + x]];

        // duyệt ảnh
        if (x < WIDTH - 1)
            x <= x + 1;
        else begin
            x <= 0;
            if (y < HEIGHT - 1)
                y <= y + 1;
            else
                done <= 1;
        end
    end
end


// ghi ảnh ra file
always @(posedge clk) begin
    if (done && !write_done) begin
        for (i = 0; i < TOTAL_PIXELS; i = i + 1)
            $fwrite(file_out, "%02h\n", image_memory[i]);

        $fclose(file_out);
        write_done <= 1;
    end
end

endmodule