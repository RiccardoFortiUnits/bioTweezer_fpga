set_global_assignment -entity "FP_fixed48_to_double" -library "lib_FP_fixed48_to_double" -name IP_TOOL_NAME "altera_fp_functions"
set_global_assignment -entity "FP_fixed48_to_double" -library "lib_FP_fixed48_to_double" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "FP_fixed48_to_double" -library "lib_FP_fixed48_to_double" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_FP_fixed48_to_double" -name SPD_FILE [file join $::quartus(sip_path) "FP_fixed48_to_double.spd"]

set_global_assignment -library "lib_FP_fixed48_to_double" -name MISC_FILE [file join $::quartus(sip_path) "FP_fixed48_to_double_sim/FP_fixed48_to_double.vo"]
