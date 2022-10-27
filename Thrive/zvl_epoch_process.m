% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [found_LoRa_pkt_out, found_LoRa_pkt_time_out] = zvl_epoch_process(found_LoRa_pkt,rcvsig,zvl_curr_time,found_LoRa_pkt_time,found_LoRa_pkt_CFO,zvl_cfg, SF)

[epoch_info,epoch_bgn, epoch_end] = zvl_setup_epoch_info(zvl_curr_time,found_LoRa_pkt_time,found_LoRa_pkt_CFO,zvl_cfg);

if size(epoch_info,1) > 0
    epoch_pkt_num = size(epoch_info,1);
    zvl_pkt_time_offset = (epoch_info(:,zvl_cfg.epoch_info_idx_bgn_time) - epoch_info(1,zvl_cfg.epoch_info_idx_bgn_time))';
    zvl_pkt_cfo_offset = (epoch_info(:,zvl_cfg.epoch_info_idx_cfo) - epoch_info(1,zvl_cfg.epoch_info_idx_cfo))';
    
    [thissig,thisploc,thisphei,thisknownpeaks,thisknownpeakidx,lastknownpeaks,lastknownpeakidx,nextknownpeaks,nextknownpeakidx,thismask,lastsig,nextsig] = zvl_prepare_smbl_sig(epoch_pkt_num,zvl_pkt_time_offset,zvl_pkt_cfo_offset,epoch_info,found_LoRa_pkt,rcvsig,zvl_cfg);
    hardsel = zvl_make_hardsel(epoch_pkt_num,thisploc,thisphei,zvl_pkt_time_offset,zvl_pkt_cfo_offset,epoch_info,thisknownpeaks,lastknownpeaks,nextknownpeaks,thismask,lastsig,thissig,nextsig,found_LoRa_pkt,zvl_cfg);
    
    for pktidx=1:epoch_pkt_num
        orig_pktidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_pkt_id);
        if found_LoRa_pkt{orig_pktidx}.decode_res ~= 0 continue; end
        endsymidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_end_smbl);
        if endsymidx == 0 continue; end
        
        thissel = hardsel(pktidx);
        thisdecision = 2*zvl_cfg.T;
        thispeakidx = 0;
        if thisknownpeaks(pktidx) ~= -1
            if thissel > 0
                thisdecision = thisploc(pktidx,thissel);
                thispeakidx = thissel;
            end
        end
        if zvl_cfg.run_aligntrack && zvl_cfg.aligntrack_use_cfo_info == 0
            thisdecision = mod(thisdecision-1+round(orig_found_LoRa_pkt_CFO(orig_pktidx)), zvl_cfg.T)+1;
        end
        found_LoRa_pkt{orig_pktidx}.foundpeaks(endsymidx) = thisdecision;
        found_LoRa_pkt{orig_pktidx}.foundpeakidx(endsymidx) = thispeakidx;
        if thisknownpeaks(pktidx) == 0 && thissel > 0 && endsymidx > floor(zvl_cfg.LoRa_preamble_all_num)
            thissample = thisphei(pktidx,thissel);
            found_LoRa_pkt{orig_pktidx}.peakhist(endsymidx) = thissample;
            [a,b] = zvl_predict_peak_hei(found_LoRa_pkt{orig_pktidx}.peakhist(1:endsymidx));
            found_LoRa_pkt{orig_pktidx}.lowpass_hei = a;
            found_LoRa_pkt{orig_pktidx}.lowpass_std = b;
        end
        if endsymidx == floor(zvl_cfg.LoRa_header_smbl_count) % NOTE: redo at second try
            thispktfoundpeaks = found_LoRa_pkt{orig_pktidx}.foundpeaks(floor(zvl_cfg.LoRa_preamble_all_num)+1:floor(zvl_cfg.LoRa_preamble_all_num)+zvl_cfg.LoRa_header_smbl_num);
            [CR_pld,CRC_pld,pld_length,zlecc_pldinhdr] = zvl_decode_pkt_hdr((mod(thispktfoundpeaks-zvl_cfg.pld_peak_shift,2^SF)), SF); 
            if CR_pld > 0 && CR_pld < 5 && pld_length <= 32 && pld_length >=8
                % fprintf('zvl decoded pkt %d hdr -- %d %d %d \n', orig_pktidx, CR_pld,CRC_pld,pld_length); % sta_hdr_got = [sta_hdr_got, orig_pktidx];
                found_LoRa_pkt{orig_pktidx}.CR_pld = CR_pld; % > 0, means hdr crc pass
                found_LoRa_pkt{orig_pktidx}.CRC_pld = CRC_pld;
                found_LoRa_pkt{orig_pktidx}.pld_length = pld_length;
                found_LoRa_pkt{orig_pktidx}.zlecc_pldinhdr = zlecc_pldinhdr;
                here_tx_peak_loc = LoRa_Encode_Full(floor(rand(1,pld_length-2)*256), SF, CR_pld); 
                found_LoRa_pkt{orig_pktidx}.symbolnum = min(floor(zvl_cfg.LoRa_preamble_all_num) + max(3,length(here_tx_peak_loc)), size(rcvsig{orig_pktidx}{2},1)-5);
                found_LoRa_pkt_time(orig_pktidx,zvl_cfg.time_idx_endp1) = found_LoRa_pkt{orig_pktidx}.starttime + found_LoRa_pkt{orig_pktidx}.symbolnum * zvl_cfg.T;
            end
        elseif endsymidx >= floor(found_LoRa_pkt{orig_pktidx}.symbolnum) && found_LoRa_pkt{orig_pktidx}.CR_pld > 0 && found_LoRa_pkt{orig_pktidx}.CR_pld < 5
            found_LoRa_pkt{orig_pktidx}.decode_count = found_LoRa_pkt{orig_pktidx}.decode_count + 1;
            herecopysymlen = floor(found_LoRa_pkt{orig_pktidx}.symbolnum) - floor(zvl_cfg.LoRa_preamble_all_num);
            thispktfoundpeaks = found_LoRa_pkt{orig_pktidx}.foundpeaks(floor(zvl_cfg.LoRa_preamble_all_num)+1:floor(zvl_cfg.LoRa_preamble_all_num)+herecopysymlen);
            [zvl_pkt_pass_CRC_flag, zvl_found_pkt, zvl_additional_corrected] = zvl_decode_pkt_bits(mod(thispktfoundpeaks-zvl_cfg.pld_peak_shift,2^SF), SF, zvl_cfg.decoder_choice);
            if zvl_pkt_pass_CRC_flag == 0 && found_LoRa_pkt{orig_pktidx}.decode_count == 1
                peak_hist = found_LoRa_pkt{orig_pktidx}.peakhist(1:floor(found_LoRa_pkt{orig_pktidx}.symbolnum-zvl_cfg.LoRa_preamble_all_num));
                herefit = smoothdata(peak_hist,'rlowess',5);
                herediff = abs(peak_hist - herefit); 
                tempp = find(herediff > 0);
                thisthresh = median((herediff(tempp)));
                found_LoRa_pkt{orig_pktidx}.peakcurvefit = herefit;
                found_LoRa_pkt{orig_pktidx}.peakvarthresh = thisthresh;
            end
            found_LoRa_pkt{orig_pktidx}.decode_res = zvl_pkt_pass_CRC_flag;
            if zvl_pkt_pass_CRC_flag 
                thisnodeidx = int16(zvl_found_pkt(5)) + int16(zvl_found_pkt(6))*256;
                thispktidx = int16(zvl_found_pkt(7)) + int16(zvl_found_pkt(8))*256;
                fprintf('decoded pkt %d CRC pass, node id %d, seq# %d\n', orig_pktidx,thisnodeidx,thispktidx);
                found_LoRa_pkt{orig_pktidx}.additional_corrected = zvl_additional_corrected;
                found_LoRa_pkt{orig_pktidx}.pkt = zvl_found_pkt;
                found_LoRa_pkt{orig_pktidx}.crcpass = 1;
                found_LoRa_pkt{orig_pktidx}.node = thisnodeidx;
                found_LoRa_pkt{orig_pktidx}.seqnum = thispktidx;
                if length(zvl_found_pkt) == found_LoRa_pkt{orig_pktidx}.pld_length && length(zvl_found_pkt) > 4
                    found_LoRa_pkt{orig_pktidx}.reconpeaklocs = mod(LoRa_Encode_Full(zvl_found_pkt(1:found_LoRa_pkt{orig_pktidx}.pld_length-2), SF,  found_LoRa_pkt{orig_pktidx}.CR_pld) + zvl_cfg.pld_peak_shift - 1, zvl_cfg.T) + 1;
                    tempp = length(found_LoRa_pkt{orig_pktidx}.reconpeaklocs); thiscrpld = found_LoRa_pkt{orig_pktidx}.CR_pld; tempp2 = 13+tempp-1;
                    found_LoRa_pkt{orig_pktidx}.reconpeaklocs(tempp-thiscrpld-3:tempp) = zvl_cfg.T*2; %found_LoRa_pkt{orig_pktidx}.foundpeaks(tempp2-thiscrpld-3:tempp2);
                end
            end
        end
    end
end
found_LoRa_pkt_out = found_LoRa_pkt;
found_LoRa_pkt_time_out = found_LoRa_pkt_time;