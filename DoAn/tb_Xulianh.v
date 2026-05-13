`timescale 1ns/1ps

module tb_Xulianh;

reg clk;
reg rst_n;
reg start;

wire done;


// DUT
Xulianh uut (
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

    rst_n = 0;
    start = 0;

    // Reset
    #20;
    rst_n = 1;

    // Start processing
    #20;
    start = 1;


    // Wait median done
    wait(uut.median_done);
    $display("Median Processor DONE at %t", $time);

	 #20;
    // Wait histogram equalization done
    wait(done);
    $display("Full Image Processing DONE at %t", $time);

    // wait thêm để file ghi xong
    #100;

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

    if (uut.median_done)
        $display("Median Done at %t", $time);

    if (done)
        $display("Pipeline Done at %t", $time);
end
*/
endmodule