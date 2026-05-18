library verilog;
use verilog.vl_types.all;
entity equalize is
    generic(
        GRAYSCALE       : integer := 256;
        WIDTH           : integer := 604;
        HEIGHT          : integer := 345;
        TOTAL_PIXELS    : vl_notype
    );
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        equalize_start  : in     vl_logic;
        lut_in          : in     vl_logic_vector;
        write_done      : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of GRAYSCALE : constant is 1;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
    attribute mti_svvh_generic_type of HEIGHT : constant is 1;
    attribute mti_svvh_generic_type of TOTAL_PIXELS : constant is 3;
end equalize;
