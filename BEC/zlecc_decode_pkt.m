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

% Part of the implementation in this file uses functions in
% https://github.com/jkadbear/LoRaPHY
% by jkadbear

function [zlecc_decodeflag, zlecc_found_pkt, zlecc_found_err_loc, zlecc_made_attempt_num, zlecc_total_attempt_num, zvl_additional_corrected] = zlecc_decode_pkt(SF, CR, pld_length, zlecc_pldinhdr, zlecc_pldmsg)

zlecc_decodeflag = 0;
zlecc_total_attempt_num = 0;
zlecc_made_attempt_num = 0;
zlecc_found_pkt = [];
zlecc_found_err_loc = [];
zvl_additional_corrected = 0;

if pld_length <= 0
    return;
end
if CR <= 0 || CR > 4
    return;
end

rdd_pld         = CR;
ppm_pld         = SF ;
symbols_pld     = zlecc_pldmsg;
% Graying
symbols_pld_gry = LoRa_decode_gray(symbols_pld) ;
% Interleaving
symbols_pld_int = LoRa_decode_interleave(symbols_pld_gry,ppm_pld,rdd_pld) ;
% Shuffle
symbols_pld_shf = LoRa_decode_shuffle(symbols_pld_int,length(symbols_pld_int)) ;
% Add part of header
if SF > 7 && size(zlecc_pldinhdr,1)
    hererevorder = [6     1     2     3     5     4     7     8];
    tempp = zlecc_pldinhdr(:,hererevorder);
    tempp1 = bi2de(tempp)';
    % tempp2 = LoRa_decode_white(tempp1,4,0);
    symbols_pld_hdr = [tempp1, symbols_pld_shf];
else
    symbols_pld_hdr = symbols_pld_shf;
end
% White
% symbols_pld_wht = LoRa_decode_white(symbols_pld_hdr,rdd_pld,0) ;
symbols_pld_wht = symbols_pld_hdr;

erasure_idx = find(zlecc_pldmsg >= 2^SF);
erasure_flag_flat = zeros(1,length(zlecc_pldmsg)); erasure_flag_flat(erasure_idx) = 1;

zz_rpt_codeword = [];
zz_indices = [1 2 3 5 4 0 6 7];
if CR > 2 && CR <= 4 % detection and correction
    n = ceil(length(symbols_pld_wht).*4/(4 + 4)) ;
    for ctr = 0 : n - 1
        r0 = bitand(symbols_pld_wht(2*ctr+1),hex2dec("FF")) ;
        if 2*ctr+2 > length(symbols_pld_wht)
            symbols_pld_wht(2*ctr+2) = 0 ;
        end
        r1 = bitand(symbols_pld_wht(2*ctr+2),hex2dec("FF")) ;
        
        ps1 = selectbits(r1,[zz_indices]);
        ps0 = selectbits(r0,[zz_indices]);
        zz_rpt_codeword(2*ctr+1) = ps0;
        zz_rpt_codeword(2*ctr+2) = ps1;
    end
elseif CR > 0 && CR <= 2 % detection
    len = length(symbols_pld_wht) ;
    for ctr = 1 : 2 : len
        r0 = bitand(selectbits(symbols_pld_wht(ctr),zz_indices),hex2dec("FF"));
        if ctr + 1 < len
            r1 = bitand(selectbits(symbols_pld_wht(ctr+1), zz_indices),hex2dec("FF")) ;
        else
            r1 = 0 ;
        end
        zz_rpt_codeword(ctr) = r0;
        zz_rpt_codeword(ctr+1) = r1;
    end
end

rcvd = de2bi(zz_rpt_codeword); 
rcvd(:,4+CR+1:8) = 0;

zlecc_common_cfg = zlecc_gen_common();
zlecc_header_peak_num = zlecc_common_cfg.zlecc_header_peak_num;
H_bin  = zlecc_common_cfg.H_bin;

if CR > 1
    corrcw = zlecc_get_corrected(rcvd,H_bin,CR);
else
    corrcw = rcvd;
end

data_block_num = floor((size(rcvd,1)-1)/SF);
zlecc_blk_res = cell(1,data_block_num);
zlecc_blk_candinum = zeros(1,data_block_num);
for blockidx=1:data_block_num
    thisbgn = (blockidx-1)*SF + 1 + size(zlecc_pldinhdr,1); % SF_offset(SF-6,2);
    thisend = thisbgn + SF - 1;
    corblk = corrcw(thisbgn:thisend,:); 
    rcvblk = rcvd(thisbgn:thisend,:); 
    
    erasure_blk_bgn = (blockidx-1)*(4+CR)+1;
    erasure_blk_end = min(erasure_blk_bgn + 4+CR - 1, length(zlecc_pldmsg));
    thiserasures = erasure_flag_flat(erasure_blk_bgn:erasure_blk_end);
    knownbadidx = find(thiserasures);
    
    if CR == 1
        % zlecc_decode_blk_cr1;
        [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr1(rcvblk, corblk, knownbadidx, zlecc_common_cfg);
    elseif CR == 2
        % zlecc_decode_blk_cr2;
        [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr2(rcvblk, corblk, knownbadidx, zlecc_common_cfg);
    elseif CR == 3
        % zlecc_decode_blk_cr3;
        [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr3(rcvblk, corblk, knownbadidx, zlecc_common_cfg);
    elseif CR == 4
        % zlecc_decode_blk_cr4;
        [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr4(rcvblk, corblk, knownbadidx, zlecc_common_cfg);
    end
    
    zlecc_blk_res{blockidx}.blk = zcorrected_blk;
    zlecc_blk_res{blockidx}.loc = zcorrected_locs;
    for h=1:size(zcorrected_locs,1)
        zlecc_blk_res{blockidx}.loc(h,:) = zlecc_blk_res{blockidx}.loc(h,:) + (blockidx-1)*(4+CR) + zlecc_header_peak_num;
    end
    zlecc_blk_candinum(blockidx) = length(zcorrected_blk);
end

if min(zlecc_blk_candinum) > 0
    a = zlecc_blk_candinum;
    if data_block_num == 1
        allschedule = allcomb([1:a(1)]);
    end
    if data_block_num == 2
        allschedule = allcomb([1:a(1)], [1:a(2)]);
    end
    if data_block_num == 3
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)]);
    end
    if data_block_num == 4
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)], [1:a(4)]);
    end
    if data_block_num == 5
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)], [1:a(4)], [1:a(5)]);
    end
    if data_block_num == 6
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)], [1:a(4)], [1:a(5)], [1:a(6)]);
    end
    if data_block_num == 7
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)], [1:a(4)], [1:a(5)], [1:a(6)], [1:a(7)]);
    end
    if data_block_num == 8
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)], [1:a(4)], [1:a(5)], [1:a(6)], [1:a(7)], [1:a(8)]);
    end
    if data_block_num == 9
        allschedule = allcomb([1:a(1)], [1:a(2)], [1:a(3)], [1:a(4)], [1:a(5)], [1:a(6)], [1:a(7)], [1:a(8)],[1:a(9)]);
    end
    zlecc_total_attempt_num = size(allschedule,1);

    schedule_sel_flag = zeros(1,size(allschedule,1));
    if length(schedule_sel_flag) <= zlecc_common_cfg.CRCattmax(CR)
        schedule_sel_flag(:) = 1;
    else
        tempp = randperm(length(schedule_sel_flag));
        schedule_sel_flag(tempp(1:zlecc_common_cfg.CRCattmax(CR))) = 1;
    end
    for scheduleidx=1:size(allschedule,1)
        if schedule_sel_flag(scheduleidx) == 0
            continue;
        end
        thisschedule = allschedule(scheduleidx,:);
        zcorrected = corrcw;
        zlecc_found_err_loc = [];
        for blockidx=1:data_block_num
            thisbgn = (blockidx-1)*SF + 1 + size(zlecc_pldinhdr,1); %SF_offset(SF-6,2);
            thisend = thisbgn + SF - 1;
            qqq = thisschedule(blockidx);
            zcorrected(thisbgn:thisend,:) =  zlecc_blk_res{blockidx}.blk{qqq};
            if length(zlecc_blk_res{blockidx}.loc)
                zlecc_found_err_loc = [zlecc_found_err_loc, zlecc_blk_res{blockidx}.loc(qqq,:)];
            end
        end
        copy_rcvcodeword_use = zcorrected(:,1:4);
        copy_rcvcodeword_use_1 = bi2de(copy_rcvcodeword_use);
        zlecc_found_pkt = [];
        for h=1:size(copy_rcvcodeword_use,1)/2
            zlecc_found_pkt(h) = copy_rcvcodeword_use_1((h-1)*2+1)+copy_rcvcodeword_use_1(h*2)*16;
        end
        zlecc_found_pkt = zlecc_white(zlecc_found_pkt);

        if zlecc_check_message_crc(zlecc_found_pkt,pld_length)
            zlecc_found_err_loc = sort(zlecc_found_err_loc);
            zlecc_decodeflag = 1;
            zlecc_made_attempt_num = scheduleidx;
            tempp = double(zcorrected) - double(corrcw);
            tempp1 = sum(abs(tempp'));
            zvl_additional_corrected = length(find(tempp1));
            break;
        end
    end
end