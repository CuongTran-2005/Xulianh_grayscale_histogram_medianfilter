`timescale 1ns/1ps

module tb_histogram_top;

reg clk;
reg rst_n;
reg start;

wire done;


// Instantiate DUT
histogram_top uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .done(done)
);


// Clock 10ns
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end


// Stimulus
initial begin

    // init
    rst_n = 0;
    start = 0;

    // reset
    #20;
    rst_n = 1;

    // start pipeline
    #20;
    start = 1;

	 wait(uut.hist_done_wire);
    $display("Histogram DONE at time = %t", $time);

    // Wait LUT done
    wait(uut.lut_done_wire);
    $display("CDF LUT DONE at time = %t", $time);
	 
    // wait done
    wait(done);

    $display("Histogram Equalization DONE!");

    // đợi ghi file
    #100;

    $display("Check output files.");

    $stop;
end


// timeout
initial begin
    #100000000;

    $display("TIMEOUT!");

    $stop;
end


// debug
/*always @(posedge clk) begin

    if (uut.hist_done_wire)
        $display("Histogram DONE at %t", $time);

    if (uut.lut_done_wire)
        $display("CDF LUT DONE at %t", $time);

    if (done)
        $display("Equalize DONE at %t", $time);
end*/

endmodule