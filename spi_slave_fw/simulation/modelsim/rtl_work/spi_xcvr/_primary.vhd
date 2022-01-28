library verilog;
use verilog.vl_types.all;
entity spi_xcvr is
    generic(
        CLK_RATIO       : integer := 3
    );
    port(
        sys_clk         : in     vl_logic;
        sys_nrst        : in     vl_logic;
        enable          : in     vl_logic;
        wr_req          : in     vl_logic;
        wr_data         : in     vl_logic_vector(7 downto 0);
        busy            : out    vl_logic;
        done            : out    vl_logic;
        rd_data         : out    vl_logic_vector(7 downto 0);
        MISO            : in     vl_logic;
        SCK             : out    vl_logic;
        MOSI            : out    vl_logic;
        NSS             : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CLK_RATIO : constant is 1;
end spi_xcvr;
