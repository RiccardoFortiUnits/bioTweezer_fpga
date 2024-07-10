%input1 and 2 must have the same length
function [out1, out2] = tustin_pipelined_fp(input1, input2, alpha, gain)

if nargin < 4
    gain = 1;
end

alpha = fi([alpha],1,32,31);

temp = [input1;input2];
alter_x=temp(:)'; %interleave the two inputs
alter_y=zeros(1,length(alter_x),'like',fi([],1,32,31,fimath('RoundingMethod','Floor','ProductMode','KeepMSB')));
sum1 = zeros(1,length(alter_x),'like',fi([],1,33,30,fimath('SumMode','FullPrecision')));
round1 = zeros(1,length(alter_x),'like',fi([],1,32,30,fimath('RoundingMethod','Floor','ProductMode','KeepMSB')));
sum2 = zeros(1,length(alter_x),'like',fi([],1,32,30,fimath('SumMode','KeepLSB','SumWordLength',32,'OverflowAction','Saturate','CastBeforeSum',false)));
product1 = zeros(1,length(alter_x),'like',fi([],1,64,61,fimath('RoundingMethod','Floor','ProductMode','FullPrecision')));
sum3 = zeros(1,length(alter_x),'like',fi([],1,64,61,fimath('SumMode','KeepLSB','SumWordLength',64,'OverflowAction','Saturate','CastBeforeSum',false)));


for i=3:length(alter_x)
    sum1(i) = (alter_x(i) + alter_x(i-2));
    round1(i) = sum1(i) * 2^(-1);
    sum2(i) = round1(i) - alter_y(i-1);
    product1(i) =  sum2(i) * alpha * gain;
    sum3(i) = removefimath(product1(i-1)) + sum3(i-2);
    alter_y(i) = sum3(i) * (1/gain);
end

out2 = [alter_y(1:2:end)];
out1 = [alter_y(2:2:end)];

end