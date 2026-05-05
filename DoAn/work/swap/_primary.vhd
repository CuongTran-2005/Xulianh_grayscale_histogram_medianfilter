library verilog;
use verilog.vl_types.all;
entity swap is
    port(
        a               : in     vl_logic_vector(7 downto 0);
        b               : in     vl_logic_vector(7 downto 0);
        min             : out    vl_logic_vector(7 downto 0);
        max             : out    vl_logic_vector(7 downto 0)
    );
end swap;
