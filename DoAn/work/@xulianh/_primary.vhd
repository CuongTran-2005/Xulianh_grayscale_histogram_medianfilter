library verilog;
use verilog.vl_types.all;
entity Xulianh is
    generic(
        GRAYSCALE       : integer := 256;
        WIDTH           : integer := 430;
        HEIGHT          : integer := 554;
        TOTAL_PIXELS    : vl_notype
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        start           : in     vl_logic;
        done            : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of GRAYSCALE : constant is 1;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
    attribute mti_svvh_generic_type of HEIGHT : constant is 1;
    attribute mti_svvh_generic_type of TOTAL_PIXELS : constant is 3;
end Xulianh;
