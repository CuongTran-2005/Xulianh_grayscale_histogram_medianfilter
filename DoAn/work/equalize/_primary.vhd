library verilog;
use verilog.vl_types.all;
entity equalize is
    generic(
        WIDTH           : integer := 430;
        HEIGHT          : integer := 554;
        TOTAL_PIXELS    : vl_notype;
        IMAGE_IN        : string  := "Anhinput.txt";
        LUT_FILE        : string  := "lut_output.txt";
        IMAGE_OUT       : string  := "Anhoutput_equalized.txt"
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
    attribute mti_svvh_generic_type of IMAGE_IN : constant is 1;
    attribute mti_svvh_generic_type of LUT_FILE : constant is 1;
    attribute mti_svvh_generic_type of IMAGE_OUT : constant is 1;
end equalize;
