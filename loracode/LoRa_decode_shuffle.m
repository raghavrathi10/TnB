% # LoRaMatlab
% LoRa Modulation and Coding Scheme Simulator on Matlab
% # Cite as
% Please cite the code which is part of our accepted publication:
% 
% B. Al Homssi, K. Dakic, S. Maselli, H. Wolf, S. Kandeepan, and A. Al-Hourani, "IoT Network Design using Open-Source LoRa Coverage Emulator," in IEEE Access. 2021.
% 
% Link on IEEE:
% https://ieeexplore.ieee.org/document/9395074
% 
% Link on researchgate:
% 
% https://www.researchgate.net/publication/350581481_IoT_Network_Design_using_Open-Source_LoRa_Coverage_Emulator

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
