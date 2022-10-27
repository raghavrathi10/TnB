function [symbols_shuf] = LoRa_decode_shuffle(symbols,N)
% LoRa_decode_shuffle unshuffles payload packet
%
%   in:  symbols       symbol vector
%        N             
%
%  out:  symbols_shuf  unshuffled symbols

pattern = [5 0 1 2 4 3 6 7] ;
symbols_shuf = zeros(1,N) ;
for ctr = 1 : N
    for Ctr = 1 : length(pattern)
        symbols_shuf(ctr) = symbols_shuf(ctr) + bitsll(double(bitand(symbols(ctr),bitsll(1,pattern(Ctr)))>0),Ctr-1) ;
    end
end
end
