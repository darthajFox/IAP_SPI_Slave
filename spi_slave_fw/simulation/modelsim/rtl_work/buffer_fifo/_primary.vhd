library verilog;
use verilog.vl_types.all;
entity buffer_fifo is
    port(
        clock           : in     vl_logic;
        data            : in     vl_logic_vector(15 downto 0);
        rdreq           : in     vl_logic;
        sclr            : in     vl_logic;
        wrreq           : in     vl_logic;
        empty           : out    vl_logic;
        full            : out    vl_logic;
        q               : out    vl_logic_vector(15 downto 0)
    );
end buffer_fifo;
