% NOTE: just need zlecc_hdr_crc

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


function [message_full,CR_pld,pld_length,CRC_pld] = LoRa_Decode_Full(symbols_message,SF)
% LoRa_Decode_Full decodes full payload packet
%
%   in:  symbols_message         LoRa payload symbol vector
%        SF                      spreading factor  
%
%  out:  message_full          message symbols vector (decoded)
%        CR_pld                code rate of payload
%        pld_length            length of payload
%        CRC_pld               payload cyclic rate code flag
%% Decode Header
rdd_hdr         = 4 ;
ppm_hdr         = SF - 2 ;
symbols_hdr     = mod(round(symbols_message(1:8)/4),2^ppm_hdr) ;
% Graying
symbols_hdr_gry = LoRa_decode_gray(symbols_hdr) ;
% Interleaving
symbols_hdr_int = LoRa_decode_interleave(symbols_hdr_gry,ppm_hdr,rdd_hdr) ;
% Shuffle
symbols_hdr_shf = LoRa_decode_shuffle(symbols_hdr_int,ppm_hdr) ;
% Hamming
symbols_hdr_fec = LoRa_decode_hamming(symbols_hdr_shf(1:5),rdd_hdr) ;
%% Extract info from Header
CR_pld          = floor(bitsra(symbols_hdr_fec(2),5)) ;

% zz add bgn
symbols_hdr_fec = mod(symbols_hdr_fec,2^8);
calcrcbits = zlecc_hdr_crc(symbols_hdr_fec);
rcvcrcbits = zeros(1,5);
rcvcrcbits(5) = bitand(symbols_hdr_fec(2),1);
rcvcrcbits(1:4) = de2bi(round(symbols_hdr_fec(3)/16),4);
if CR_pld > 4 || CR_pld < 1 % || sum(abs(calcrcbits-rcvcrcbits)) > 0
    message_full = [];
    CR_pld = 0; 
    pld_length = 0; 
    CRC_pld = 0;
    return
end
% zz add end
CRC_pld         = mod(floor(bitsra(symbols_hdr_fec(2),4)),2) ;
pld_length      = symbols_hdr_fec(1) + CRC_pld*2 ;
%% Decode Payload
rdd_pld         = CR_pld ;
ppm_pld         = SF ;
symbols_pld     = symbols_message(9:end) ;
% Graying
symbols_pld_gry = LoRa_decode_gray(symbols_pld) ;
% Interleaving
symbols_pld_int = LoRa_decode_interleave(symbols_pld_gry,ppm_pld,rdd_pld) ;
% Shuffle
symbols_pld_shf = LoRa_decode_shuffle(symbols_pld_int,length(symbols_pld_int)) ;
% Add part of header
symbols_pld_hdr = [(SF>7).*symbols_hdr_shf(end - SF + 8:end) symbols_pld_shf] ;
% White
symbols_pld_wht = LoRa_decode_white(symbols_pld_hdr,rdd_pld,0) ;
% Hamming
symbols_pld_fec = LoRa_decode_hamming(symbols_pld_wht,rdd_pld) ;
% Swaping
symbols_pld_fin = LoRa_decode_swap(symbols_pld_fec) ;
%% Final Message
message_full    = [symbols_hdr_fec symbols_pld_fin] ;
end

function [symbols_swp] = LoRa_decode_swap(symbols)
% LoRa_decode_shuffle swap payload packet
%
%   in:  symbols       symbol vector           
%
%  out:  symbols_swp   unswapped symbols

symbols_swp = zeros(1,length(symbols)) ;
for ctr = 1 : length(symbols)
    symbols_swp(ctr) = bitor(bitsll(bitand(symbols(ctr),hex2dec('0F')),4),bitsra(bitand(symbols(ctr),hex2dec('F0')),4)) ; % swap first half of 8-bit sequencne with other half 
end
end


function [symbols] = FSKDetection(signal,SF,detection)
% LoRa_Tx demodulates a Lora de-chirped signal using
% the coherence specified by the detection variable
%
%   in:  message      payload message
%        SF           spreading factor
%        detection    1= coherent detection, 2= non-coherent detection   
%
%  out:  symbols      FSK demodulated symbol vector 

if detection == 1 % coherent detection
    t = 0:1/(2^SF):0.999 ; % time vector
    for Ctr = 1 : 2^SF
        rtemp = conv(signal,exp(-j.*2.*pi.*(2^SF - Ctr + 1).*t)) ; % convolution w/ideal fsk signal
        r(Ctr,:) = real(rtemp(2^SF+1:2^SF:end)) ; % save resultant array
    end
    [~,idx] = max(r) ; % take max
    symbols = idx - 1 ; % store symbol vector
elseif detection == 2 % non-coherent detection
    [~,idx] = max(fft(reshape(signal,2^SF,length(signal)/(2^SF)))) ; % take max of fft window
    symbols = idx - 1 ; % store symbol array
end
end