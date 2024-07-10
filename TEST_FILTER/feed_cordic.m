% MATLAB script to generate sinusoidal data for Verilog testbench

samples = 100;

% Parameters
t = 0:1:samples;  % Time vector for 100 samples
q = t*pi/samples;
r = t*1/samples;

z = r.*exp(1i*q);
plot(z)

I_short = fi(real(z),1,32,30,fimath('RoundingMethod','Floor'));
Q_short = fi(imag(z),1,32,30,fimath('RoundingMethod','Floor'));
I_dec = int32(double(I_short)*2^30);
Q_dec = int32(double(Q_short)*2^30);

%save files
writematrix(dec2bin(I_dec',32), 'I_bin.txt', 'Delimiter', '\t');
writematrix(dec2bin(Q_dec',32), 'Q_bin.txt', 'Delimiter', '\t');

