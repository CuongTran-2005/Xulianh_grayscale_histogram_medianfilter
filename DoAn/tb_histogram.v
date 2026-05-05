`timescale 1ns/1ps

module tb_histogram;

reg clk;
reg rst;
reg start;

wire done;

// Instantiate DUT
histogram uut (
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

    // Start processing
    #20;
    start = 1;

    // Có thể tắt start nếu muốn (optional)
    // Chờ done
    wait(done);

    $display("Histogram processing DONE!");
	 start = 0;
    // Đợi thêm để đảm bảo ghi file xong
    #50;

    $display("Check file Anhoutput.txt");

    $stop;
end


// Timeout tránh treo simulation
initial begin
    #100000000;
    $display("Simulation TIMEOUT!");
    $stop;
end

endmodule