%input1 and 2 must have the same length
function [out1, out2] = tustin_pipelined(input1, input2, alpha, gain)

if nargin < 4
    gain = 1;
end

temp = [input1;input2];
alter_x=temp(:)'; %interleave the two inputs
alter_y=zeros(1,length(alter_x));
sum1 = alter_y;
sum2 = alter_y;
sum3 = alter_y;
product1 = alter_y;

%Original version
% 
% for i=3:length(alter_x)
%     sum1(i) = 1/2*(alter_x(i) + alter_x(i-2));
%     sum2(i) = sum1(i) - alter_y(i-1);
%     product1(i) =  sum2(i) * alpha * gain;
%     sum3(i) = product1(i-1) + sum3(i-2);
%     alter_y(i) = sum3(i) * (1/gain);
% end

%Version with multiply after accumulate
for i=3:length(alter_x)
    sum1(i) = 1/2*(alter_x(i) + alter_x(i-2));
    sum2(i) = sum1(i) - alter_y(i-1);
    sum3(i) = sum2(i-1) + sum3(i-2);
    alter_y(i) = sum3(i) * alpha ;
end

%if a delay after the input sum is wanted
%in this case there is an additional delay on the output
% 
% alter_y_dup=zeros(1,length(alter_x));
% sum1_dup = alter_y_dup;
% sum2_dup = alter_y_dup;
% sum3_dup = alter_y_dup;
% product1_dup = alter_y_dup;
% for i=3:length(alter_x)
%     sum1_dup(i) = 1/2*(alter_x(i) + alter_x(i-2));
%     product1_dup(i) =  (sum1_dup(i-1) - alter_y_dup(i-1)) * alpha;
%     sum3_dup(i) = product1_dup(i-1)+sum3_dup(i-2);
%     alter_y_dup(i) = sum3_dup(i);
% end


out2 = [alter_y(1:2:end)];
out1 = [alter_y(2:2:end)];

end
