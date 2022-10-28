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
