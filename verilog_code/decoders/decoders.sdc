set_net_delay -from [get_registers *points_per_period\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *points_per_period\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *Y_increment_step\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Y_increment_step\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *SIN_increment_step\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *SIN_increment_step\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *X_phase\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *X_phase\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *X_ampl\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *X_ampl\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *Z_phase\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Z_phase\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *rotation_sin\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *rotation_sin\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *rotation_cos\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *rotation_cos\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *Z_scale_factor\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Z_scale_factor\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

#set_net_delay -from [get_registers *X_pixel\[*\]] -max \
#    -get_value_from_clock_period src_clock_period -value_multiplier 1.
#set_max_skew -from [get_registers *X_pixel\[*\]] \
#    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *Y_pixel\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Y_pixel\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *X_ampl_scaling\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *X_ampl_scaling\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8



set_net_delay -from [get_registers *Y_ampl_scaling\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Y_ampl_scaling\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *Y_phase\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Y_phase\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *Y_ampl\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *Y_ampl\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *lockin_phase\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *lockin_phase\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *lockin_CIC_decimation_rate\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *lockin_CIC_decimation_rate\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *lockin_MA_length\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *lockin_MA_length\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

#set_net_delay -from [get_registers *lockin_MA_stages\[*\]] -max \
#    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
#set_max_skew -from [get_registers *lockin_MA_stages\[*\]] \
#    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *lockin_sum_points\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *lockin_sum_points\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *number_of_rotations\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *number_of_rotations\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8




set_net_delay -from [get_registers *PI_coefficient_1\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *PI_coefficient_1\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *PI_coefficient_2\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *PI_coefficient_2\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8



set_net_delay -from [get_registers *offset_X_double\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *offset_X_double\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *offset_Y_double\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *offset_Y_double\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *offset_X\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *offset_X\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8

set_net_delay -from [get_registers *offset_Y\[*\]] -max \
    -get_value_from_clock_period src_clock_period -value_multiplier 0.8
set_max_skew -from [get_registers *offset_Y\[*\]] \
    -get_skew_value_from_clock_period src_clock_period -skew_value_multiplier 0.8