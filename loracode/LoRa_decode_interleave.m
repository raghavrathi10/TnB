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

function [symbols_interleaved] = LoRa_decode_interleave(symbols,ppm,rdd)
% LoRa_decode_interleave deinterleaves payload packet
%
%   in:  symbols       interleaved symbols
%        ppm
%        rdd
%
%  out:  symbols_interleaved  deinterleaved symbols

symbols_interleaved = [] ;
sym_idx_ext = 1 ;
for block_idx = 1 : floor(length(symbols)/(4+rdd))
    sym_int = zeros(1,ppm) ;
    for sym_idx = 1 : 4 + rdd
        sym_rot = rotl(symbols(sym_idx_ext),sym_idx-1,ppm) ;
        mask = bitsll(1,ppm-1) ;
        ctr = ppm ;
        while mask > 0
            sym_int(ctr) = sym_int(ctr) + bitsll(double(bitand(sym_rot,mask)>0),sym_idx-1) ;
            mask = floor(bitsra(mask,1)) ;
            ctr = ctr - 1 ;
        end
        sym_idx_ext = sym_idx_ext + 1 ;
    end
    symbols_interleaved = [symbols_interleaved sym_int] ;
end
end
