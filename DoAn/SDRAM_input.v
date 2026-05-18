module SDRAM_input (
    input clk,
    input rst_n,

    input [19:0] addr,
    input [7:0]  data_in,
    input        we,

    output reg [7:0] data_out
);
	
	/*initial begin
		 $readmemh("Anhinput.txt", mem);
	end*/
    // 1MB memory
    reg [7:0] mem [0:(1<<20)-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= 8'd0;

            // optional clear memory
            /*
            for(i = 0; i < (1<<20); i = i + 1)
                mem[i] <= 8'd0;
            */
        end
        else begin

            // write
            if(we)
                mem[addr] <= data_in;

            // read
            data_out <= mem[addr];

        end
    end

endmodule