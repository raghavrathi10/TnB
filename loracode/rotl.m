function [y] = rotl(bits,count,size)
% rotl 
%
%   in:  bits            bit sequence
%        counts          
%        size
%
%  out:  y               rotated symbols

len_mask = bitsll(1,size) - 1 ;
count = mod(count,size) ;
bits = bitand(bits,len_mask) ;
y = bitor(bitand(bitsll(bits,count),len_mask), floor(bitsra(bits,size - count))) ;
end
