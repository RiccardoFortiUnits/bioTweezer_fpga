function [out] = tustin_ideal(input,alpha)

out = zeros(1,length(input));

for i=2:length(input)
    out(i) = out(i-1)+alpha*((input(i)+input(i-1))/2 - out(i-1));
end

end

