module histogram #(
	 parameter GRAYSCALE = 256,
	 parameter WIDTH = 430,
	 parameter HEIGHT = 554,
	 parameter TOTAL_PIXELS = WIDTH * HEIGHT
)
(
    input clk,
    input rst_n,
    input start_hist,
	 //input [7:0] image_memory,
    output reg hist_done,
	 output reg [32 * GRAYSCALE -1:0] hist_out
);


parameter IMAGE_NAME = "Anhoutput.txt";
reg [7:0] image_memory [0: TOTAL_PIXELS-1];
reg doing;
//reg [31:0] hist [0:255];

integer i, x, y;
//integer file_out;
//reg write_done;

initial begin
    $readmemh(IMAGE_NAME, image_memory);
//    file_out = $fopen("Anhoutput.txt", "w");
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 256; i = i + 1)
            hist_out[i*32 +: 32] <= 0;
        hist_done <= 0;
		  doing <=0;
        x <= 0;
        y <= 0;
        //write_done <= 0;
    end
    else if (start_hist && !hist_done) begin
        //hist_out[32*image_memory +: 32] <= hist_out[32*image_memory +: 32] + 1;
		  hist_out[image_memory[y*WIDTH + x]*32 +: 32] <= hist_out[image_memory[y*WIDTH + x]*32+:32] + 1;
        if (x < WIDTH - 1)
            x <= x + 1;
        else begin
            x <= 0;
            if (y < HEIGHT - 1)
                y <= y + 1;
            else
				begin
                hist_done <= 1;
					 $display("--- DONE: Da ghi histogarm xong ---");
				end
        end
    end
end

//ghi file
/*
always @(posedge clk) begin
    if (done && !write_done) begin
        for (i = 0; i < 256; i = i + 1)
            $fwrite(file_out, "%0h \n", hist[i]);
        $fclose(file_out);
        write_done <= 1;
    end
end
*/
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