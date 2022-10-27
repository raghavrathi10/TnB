function [r] = selectbits(data,indices)
% selectbits concat zeros (from 4-bit to 8-bit)
%
%   in:  data            symbol sequence
%        indices         vector = [1 2 3 4 5]
%
%  out:  r       `        symbols 

r = 0 ;
for ctr = 0 : length(indices) - 1
    if bitand(data,bitsll(1,indices(ctr+1))) > 0
        r = r + bitsll(1,ctr) ; % shift to left
    else
        r = r + 0 ;
    end
end
end
