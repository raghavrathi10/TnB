% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

% Part of the implementation in this file uses functions in
% # LoRaMatlab
% LoRa Modulation and Coding Scheme Simulator on Matlab
% # Cite as
% Please cite the code which is part of our accepted publication:
% B. Al Homssi, K. Dakic, S. Maselli, H. Wolf, S. Kandeepan, and A. Al-Hourani, "IoT Network Design using Open-Source LoRa Coverage Emulator," in IEEE Access. 2021.
% Link on IEEE:
% https://ieeexplore.ieee.org/document/9395074
% Link on researchgate:
% https://www.researchgate.net/publication/350581481_IoT_Network_Design_using_Open-Source_LoRa_Coverage_Emulator

function [CR_pld,CRC_pld,pld_length,first_few_pld_corrcw] = zlecc_decode_hdr(symbols_message, SF) 

CR_pld = 0;
CRC_pld = 0;
pld_length = 0;
first_few_pld_corrcw = [];


%% Decode Header
rdd_hdr         = 4 ;
ppm_hdr         = SF - 2 ;
use_symbols = symbols_message(1:8);
tempp = mod(use_symbols,4);
bad_symbols_idx = find(tempp); 
if length(unique(tempp)) == 1
    bad_symbols_idx = [];
end
if size(bad_symbols_idx,1) > 1 bad_symbols_idx = bad_symbols_idx'; end
tempp = find(use_symbols >= 2^SF);
bad_symbols_idx = union(bad_symbols_idx, tempp);

symbols_hdr     = mod(round(use_symbols/4),2^ppm_hdr) ;
% Graying
symbols_hdr_gry = LoRa_decode_gray(symbols_hdr) ;
% Interleaving
symbols_hdr_int = LoRa_decode_interleave(symbols_hdr_gry,ppm_hdr,rdd_hdr) ;
% Shuffle
symbols_hdr_shf = LoRa_decode_shuffle(symbols_hdr_int,ppm_hdr) ;

zlecc_common_cfg = zlecc_gen_common();
H_bin  = zlecc_common_cfg.H_bin;
LoRs_shuffle_order = zlecc_common_cfg.LoRs_shuffle_order;

tmp_rcvd = de2bi(symbols_hdr_shf, 8);
rcvblk = tmp_rcvd(:,LoRs_shuffle_order);

corblk = zeros(size(rcvblk));
for h=1:size(rcvblk,1)
    ps0b = rcvblk(h,1:4+rdd_hdr); 
    ps0b_exp = repmat(ps0b,16,1);
    tempp0 = ps0b_exp - H_bin(:,1:4+rdd_hdr);
    tempp1 = sum(abs(tempp0'));
    [a,b] = min(tempp1);
    corblk(h,:) = H_bin(b,:);
end 

[zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr4(rcvblk, corblk, bad_symbols_idx, zlecc_common_cfg);
for attidx=1:min(8,size(zcorrected_blk,1))
    zz_symbols_hdr_fec_0 = bi2de(zcorrected_blk{attidx}(:,1:4));
    zz_symbols_hdr_fec = zeros(attidx,3);
    for h=1:3
        if h < 3
            zz_symbols_hdr_fec(h) = zz_symbols_hdr_fec_0(2*h) + zz_symbols_hdr_fec_0(2*h-1)*16;
        else
            zz_symbols_hdr_fec(h) = zz_symbols_hdr_fec_0(2*h-1)*16;
        end
    end
    calcrcbits = zlecc_hdr_crc(zz_symbols_hdr_fec);
    rcvcrcbits = zeros(1,5);
    rcvcrcbits(5) = bitand(zz_symbols_hdr_fec(2),1);
    rcvcrcbits(1:4) = de2bi(round(zz_symbols_hdr_fec(3)/16),4);

    if sum(abs(calcrcbits-rcvcrcbits)) == 0
        CR_pld          = floor(bitsra(zz_symbols_hdr_fec(2),5));
        CRC_pld         = mod(floor(bitsra(zz_symbols_hdr_fec(2),4)),2) ;
        pld_length      = zz_symbols_hdr_fec(1) + CRC_pld*2 ;
        first_few_pld_corrcw = zcorrected_blk{attidx}(6:end,:);
        break;
    end
end
