library verilog;
use verilog.vl_types.all;
entity median is
    port(
        p0              : in     vl_logic_vector(7 downto 0);
        p1              : in     vl_logic_vector(7 downto 0);
        p2              : in     vl_logic_vector(7 downto 0);
        p3              : in     vl_logic_vector(7 downto 0);
        p4              : in     vl_logic_vector(7 downto 0);
        p5              : in     vl_logic_vector(7 downto 0);
        p6              : in     vl_logic_vector(7 downto 0);
        p7              : in     vl_logic_vector(7 downto 0);
        p8              : in     vl_logic_vector(7 downto 0);
        out_median      : out    vl_logic_vector(7 downto 0)
    );
end median;
