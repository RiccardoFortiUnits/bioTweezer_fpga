% MATLAB script to generate sinusoidal data for Verilog testbench

% Parameters
fs = 50e6;  % Sampling frequency (50 MHz)
t = 0:1/fs:100/fs;  % Time vector for 100 samples

% carrier
f_1MHz = 1e6;
sin_wfm = round(2^15 * sin(2*pi*f_1MHz*t) * 0.999);
cos_wfm = round(2^15 * cos(2*pi*f_1MHz*t) * 0.999);

% Write to text files
writematrix(sin_wfm', 'sin.txt', 'Delimiter', '\t');
writematrix(cos_wfm', 'cos.txt', 'Delimiter', '\t');

in_wfm = round(2^14 * sin(2*pi*f_1MHz*t + pi/8) * 0.999);
writematrix(in_wfm', 'signalin.txt', 'Delimiter', '\t');
