%input1 and 2 must have the same length
function [out1, out2] = tustin_pipeline_fp_opt(input1, input2, alpha, gain)

if nargin < 4
    gain = 1;
end

alpha = fi([alpha],1,27,26);
input1 = fi(input1,1,26,25,fimath('RoundingMethod','Floor'));
input2 = fi(input2,1,26,25,fimath('RoundingMethod','Floor'));

temp = [input1;input2];
alter_x=temp(:)'; %interleave the two inputs
alter_y=zeros(1,length(alter_x)+1,'like',fi([],1,32,31,fimath('RoundingMethod','Floor','ProductMode','KeepMSB')));
sum1 = zeros(1,length(alter_x),'like',fi([],1,27,25,fimath('SumMode','KeepLSB','SumWordLength',27,'OverflowAction','Wrap','CastBeforeSum',false)));
round1 = zeros(1,length(alter_x),'like',fi([],1,26,25,fimath('RoundingMethod','Floor','ProductMode','KeepMSB')));
sum2 = zeros(1,length(alter_x),'like',fi([],1,27,25,fimath('SumMode','KeepLSB','SumWordLength',27,'OverflowAction','Wrap','CastBeforeSum',false)));
product1 = zeros(1,length(alter_x),'like',fi([],1,54,51,fimath('RoundingMethod','Floor','ProductMode','KeepMSB','ProductWordLength',54)));
sum3 = zeros(1,length(alter_x)+1,'like',fi([],1,54,51,fimath('SumMode','KeepLSB','SumWordLength',54,'OverflowAction','Wrap','CastBeforeSum',false)));


% for i=3:length(alter_x)
%     sum1(i) = alter_x(i) + alter_x(i-2);
%     round1(i) = sum1(i) * 2^(-1);
%     sum2(i) = round1(i) - removefimath(fi(alter_y(i-1),1,26,25,fimath('RoundingMethod','Floor')));
%     product1(i) =  sum2(i) * alpha;
%     sum3(i) = removefimath(product1(i-1)) + sum3(i-2);
%     alter_y(i) = sum3(i);
% end

for i=1:length(alter_x)
    if (i >= 3)
        sum1(i) = alter_x(i) + alter_x(i-2);
    else
        sum1(i) = alter_x(i);
    end    
    round1(i) = sum1(i) * 2^(-1);
    if (i >= 2)
        sum2(i) = round1(i) - removefimath(fi(alter_y(i-1),1,26,25,fimath('RoundingMethod','Floor')));
    else
        sum2(i) = round1(i) ;
    end  
    product1(i) =  sum2(i) * alpha;
    if (i <= 1)
        sum3(i+1) = removefimath(product1(i));
    else
        sum3(i+1) = removefimath(product1(i)) + sum3(i-1);
    end
    alter_y(i+1) = sum3(i+1);
end

%one clock later for the sum latency
out1 = [alter_y(2:2:end)]; 
out2 = [alter_y(3:2:end)];

end