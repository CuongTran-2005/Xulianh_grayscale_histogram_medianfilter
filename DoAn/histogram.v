module histogram (
    input clk,
    input rst,
    input start,
    output reg done
);

parameter WIDTH = 430;
parameter HEIGHT = 554;
parameter TOTAL_PIXELS = WIDTH * HEIGHT;
parameter IMAGE_NAME = "Anhinput.txt";

reg [7:0] image_memory [0: TOTAL_PIXELS-1];
reg [31:0] hist [0:255];

integer i, x, y;
integer file_out;

reg write_done;

initial begin
    $readmemh(IMAGE_NAME, image_memory);
    file_out = $fopen("Anhoutput.txt", "w");
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        for (i = 0; i < 256; i = i + 1)
            hist[i] <= 0;

        done <= 0;
        x <= 0;
        y <= 0;
        write_done <= 0;
    end
    else if (start && !done) begin
        hist[image_memory[y*WIDTH + x]] <= hist[image_memory[y*WIDTH + x]] + 1;

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

//ghi file
 
always @(posedge clk) begin
    if (done && !write_done) begin
        for (i = 0; i < 256; i = i + 1)
            $fwrite(file_out, "%0h \n", hist[i]);

        $fclose(file_out);
        write_done <= 1;
    end
end
/*
always @(posedge clk) 
begin
	if (done && !write_done)
	for (i = 0; i<256;i = i+1)
	begin
		hist_out[i] <= hist[i];
	end
end
*/
endmodule