library verilog;
use verilog.vl_types.all;
entity programmer_tb is
    generic(
        CLK             : integer := 10;
        DELAY           : vl_notype
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of CLK : constant is 1;
    attribute mti_svvh_generic_type of DELAY : constant is 3;
end programmer_tb;
