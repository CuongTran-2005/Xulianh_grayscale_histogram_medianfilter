`timescale 1ns/1ps

module tb_equalize;

reg clk;
reg rst;
reg start;

wire done;

// Instantiate DUT
equalize uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .done(done)
);


// Clock 10ns (100MHz)
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end


// Stimulus
initial begin
    // Init
    rst = 0;
    start = 0;

    // Reset
    #20;
    rst = 1;

    // Start xử lý
    #20;
    start = 1;


    // Chờ hoàn thành
    wait(done);

    $display("Equalization DONE at time = %t", $time);
	 start = 0;	
    // Đợi ghi file xong
    #50;

    $display("Check file Anhoutput_equalized.txt");

    $stop;
end


// Timeout tránh treo
initial begin
    #100000000;
    $display("Simulation TIMEOUT!");
    $stop;
end


// Debug (optional)
always @(posedge clk) begin
    if (done)
        $display("Done asserted at time = %t", $time);
end

endmodule