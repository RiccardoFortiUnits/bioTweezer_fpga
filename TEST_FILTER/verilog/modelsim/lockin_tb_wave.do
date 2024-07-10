onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lockin_tb/clk_50MHz
add wave -noupdate /lockin_tb/clk_100MHz
add wave -noupdate /lockin_tb/rst
add wave -noupdate /lockin_tb/uut/signal_in
add wave -noupdate /lockin_tb/uut/sin_ref
add wave -noupdate /lockin_tb/uut/cos_ref
add wave -noupdate /lockin_tb/uut/in_valid
add wave -noupdate /lockin_tb/uut/signal_in_real
add wave -noupdate /lockin_tb/uut/sin_ref_real
add wave -noupdate /lockin_tb/uut/cos_ref_real
add wave -noupdate /lockin_tb/uut/signal_ref
add wave -noupdate -radix symbolic /lockin_tb/uut/signal_ref_valid
add wave -noupdate -radix symbolic /lockin_tb/uut/mult
add wave -noupdate /lockin_tb/uut/mult_valid
add wave -noupdate /lockin_tb/uut/mult_real
add wave -noupdate -radix symbolic /lockin_tb/uut/mult_cast
add wave -noupdate /lockin_tb/uut/mult_cast_real
add wave -noupdate /lockin_tb/uut/alpha
add wave -noupdate /lockin_tb/uut/alpha_real
add wave -noupdate /lockin_tb/uut/filter_out
add wave -noupdate /lockin_tb/uut/filter_out_valid
add wave -noupdate /lockin_tb/uut/filter_out_real
add wave -noupdate /lockin_tb/uut/X_out
add wave -noupdate /lockin_tb/uut/Y_out
add wave -noupdate /lockin_tb/uut/out_valid
add wave -noupdate /lockin_tb/uut/X_out_real
add wave -noupdate /lockin_tb/uut/Y_out_real
add wave -noupdate /lockin_tb/uut/iir_lpf/out
add wave -noupdate /lockin_tb/uut/iir_lpf/in_reg
add wave -noupdate /lockin_tb/uut/iir_lpf/in_reg1
add wave -noupdate /lockin_tb/uut/iir_lpf/in_reg2
add wave -noupdate /lockin_tb/uut/iir_lpf/input_sum
add wave -noupdate /lockin_tb/uut/iir_lpf/input_average
add wave -noupdate /lockin_tb/uut/iir_lpf/average_reg
add wave -noupdate /lockin_tb/uut/iir_lpf/mult
add wave -noupdate /lockin_tb/uut/iir_lpf/acc_reg
add wave -noupdate /lockin_tb/uut/iir_lpf/acc_double
add wave -noupdate /lockin_tb/uut/iir_lpf/out
add wave -noupdate /lockin_tb/uut/iir_lpf/out_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {500121820 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 252
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {500140092 ps} {500204206 ps}
