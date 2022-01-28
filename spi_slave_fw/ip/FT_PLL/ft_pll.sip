set_global_assignment -entity "ft_pll" -library "lib_ft_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ft_pll" -library "lib_ft_pll" -name IP_TOOL_VERSION "13.0sp1"
set_global_assignment -entity "ft_pll" -library "lib_ft_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ft_pll" -name SPD_FILE [file join $::quartus(sip_path) "ft_pll.spd"]

set_global_assignment -library "lib_ft_pll" -name MISC_FILE [file join $::quartus(sip_path) "ft_pll_sim/ft_pll.vo"]
