library verilog;
use verilog.vl_types.all;
entity programmer is
    generic(
        FLASH_OFFSET    : integer := 0;
        MAX_COMPONENT_NUMBER: integer := 4
    );
    port(
        sys_clk         : in     vl_logic;
        sys_nrst        : in     vl_logic;
        MISO            : in     vl_logic;
        MOSI            : out    vl_logic;
        SCK             : out    vl_logic;
        NSS             : out    vl_logic;
        command         : in     vl_logic_vector(15 downto 0);
        out_fifo_empty  : in     vl_logic;
        out_fifo_rd_data: in     vl_logic_vector(15 downto 0);
        out_fifo_rd_en  : out    vl_logic;
        program_done    : out    vl_logic;
        verify_done     : out    vl_logic;
        program_error   : out    vl_logic;
        spi_violation_err: out    vl_logic;
        spi_process_err : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of FLASH_OFFSET : constant is 1;
    attribute mti_svvh_generic_type of MAX_COMPONENT_NUMBER : constant is 1;
end programmer;
