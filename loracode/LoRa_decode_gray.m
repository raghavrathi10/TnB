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

function [symbols_gray] = LoRa_decode_gray(symbols)
% LoRa_decode_gray degray LoRa payload
%
%   in:  symbols       symbols with graying
%
%  out:  symbols_gray  degrayed symbols
symbols_gray = bitxor(symbols,floor(bitsra(symbols,1))) ;
end
