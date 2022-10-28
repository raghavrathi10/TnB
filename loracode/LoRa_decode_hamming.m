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

function [deocded] = LoRa_decode_hamming(symbols,CR)
% LoRa_decode_hamming LoRa payload hamming decode (4,4 + CR)
%
%   in:  symbols       symbols with hamming
%        CR            Code Rate
%
%  out:  deocded      Fully decoded payload symbols

% if CR > 2 && CR <= 4 % detection and correction
if CR == 4 % zz changed, orig above
    n = ceil(length(symbols).*4/(4 + 4)) ;
    
    H = [0,0,0,0,0,0,3,3,0,0,5,5,14,14,7,7,0,0,9,9,2,2,7,7,4,4,7,7,7,7, ...
        7,7,0,0,9,9,14,14,11,11,14,14,13,13,14,14,14,14,9,9,9,9,10,10,9, ...
        9,12,12,9,9,14,14,7,7,0,0,5,5,2,2,11,11,5,5,5,5,6,6,5,5,2,2,1,1, ...
        2,2,2,2,12,12,5,5,2,2,7,7,8,8,11,11,11,11,11,11,12,12,5,5,14,14, ...
        11,11,12,12,9,9,2,2,11,11,12,12,12,12,12,12,16,15,0,0,3,3,3,3,3, ...
        3,4,4,13,13,6,6,3,3,4,4,1,1,10,10,3,3,4,4,4,4,4,4,7,7,8,8,13,13, ...
        10,10,3,3,13,13,13,13,14,14,13,13,10,10,9,9,10,10,10,10,4,4,13, ...
        13,10,10,15,15,8,8,1,1,6,6,3,3,6,6,5,5,6,6,6,6,1,1,1,1,2,2,1,1, ...
        4,4,1,1,6,6,15,15,8,8,8,8,8,8,11,11,8,8,13,13,6,6,15,15,8,8,1,1, ...
        10,10,15,15,12,12,15,15,15,15,15,15] ;
    
    deocded = zeros(1,n) ;
    for ctr = 0 : n - 1
        r0 = bitand(symbols(2*ctr+1),hex2dec("FF")) ;
        if 2*ctr+2 > length(symbols)
            symbols(2*ctr+2) = 0 ;
        end
        r1 = bitand(symbols(2*ctr+2),hex2dec("FF")) ;
        
        s0 = H(r0+1) ;
        s1 = H(r1+1) ;
        
        deocded(ctr+1) = bitor(bitsll(s0,4),s1) ;
    end
% zz add bgn    
elseif CR == 3
    
    n = ceil(length(symbols).*4/(4 + 4)) ;
    
    H = [0,210,85,135,153,75,204,30,225,51,180,102,120,170,45,255] ;  
    H_bin = de2bi(H);
    H_bin(:,8) = 0;
    
    deocded = zeros(1,n) ;
    for ctr = 0 : n - 1
        r0 = bitand(symbols(2*ctr+1),hex2dec("7F")) ;
        if 2*ctr+2 > length(symbols)
            symbols(2*ctr+2) = 0 ;
        end
        r1 = bitand(symbols(2*ctr+2),hex2dec("7F")) ;
        
        tempp0 = repmat(de2bi(r0,8),16,1);
        tempp0diff = tempp0 - H_bin;
        tempp0score = sum(abs(tempp0diff)');
        [a,b] = min(tempp0score);
        s0 = b-1;
        tempp1 = repmat(de2bi(r1,8),16,1);
        tempp1diff = tempp1 - H_bin;
        tempp1score = sum(abs(tempp1diff)');
        [a,b] = min(tempp1score);
        s1 = b-1;
        
        deocded(ctr+1) = bitor(bitsll(s0,4),s1) ;
    end
% zz add end    
elseif CR > 0 && CR <= 2 % detection
    indices = [1 2 3 5] ;
    len = length(symbols) ;
    Ctr = 1 ;
    for ctr = 1 : 2 : len
        if ctr + 1 < len
            s1 = bitand(selectbits(symbols(ctr+1),indices),hex2dec("FF")) ;
        else
            s1 = 0 ;
        end
        s0 = bitand(selectbits(symbols(ctr),indices),hex2dec("FF")) ;
        deocded(Ctr) = bitor(bitsll(s0,4),s1);
        Ctr = Ctr + 1 ;
    end
end
end
