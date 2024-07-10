% MATLAB script to generate sinusoidal data for Verilog testbench

% Parameters
fs = 50e6;  % Sampling frequency (50 MHz)
t = 0:1/fs:1000/fs;  % Time vector for 64 samples

% Generate 1 MHz sinusoid
f_1 = 300e3;
f_2 = 6000e3;

sin_1 = round(2^24 * sin(2*pi*f_1*t));
sin_2 = round(2^23 * sin(2*pi*f_2*t));

cos_1 = round(2^24 * cos(2*pi*f_1*t));
cos_2 = round(2^23 * cos(2*pi*f_2*t));

sin_comp = sin_1 + sin_2;
cos_comp = cos_1 + cos_2;

% Generate 2 MHz sinusoid

% Write to text files
writematrix(sin_comp', 'sin_comp.txt', 'Delimiter', '\t');
writematrix(cos_comp', 'cos_comp.txt', 'Delimiter', '\t');
