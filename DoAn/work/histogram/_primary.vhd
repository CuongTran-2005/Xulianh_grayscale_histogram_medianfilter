library verilog;
use verilog.vl_types.all;
entity histogram is
    generic(
        WIDTH           : integer := 430;
        HEIGHT          : integer := 554;
        TOTAL_PIXELS    : vl_notype;
        IMAGE_NAME      : string  := "Anhinput.txt"
    );
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        start           : in     vl_logic;
        done            : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
    attribute mti_svvh_generic_type of HEIGHT : constant is 1;
    attribute mti_svvh_generic_type of TOTAL_PIXELS : constant is 3;
    attribute mti_svvh_generic_type of IMAGE_NAME : constant is 1;
end histogram;
