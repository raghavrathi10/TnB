function [symbols_gray] = LoRa_decode_gray(symbols)
% LoRa_decode_gray degray LoRa payload
%
%   in:  symbols       symbols with graying
%
%  out:  symbols_gray  degrayed symbols
symbols_gray = bitxor(symbols,floor(bitsra(symbols,1))) ;
end
