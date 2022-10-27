% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function found_LoRa_pkt = zvl_decode_found_pkts(BW, SF, OSF, zvl_cfg, found_LoRa_sim_pkt_start_time,found_LoRa_pkt_CFO, rcvsig, rcvdownchirpsig)

%--------------------------------------------------------------------------
% init 

found_LoRa_pkt_num = length(found_LoRa_sim_pkt_start_time);
found_LoRa_pkt = cell(1,found_LoRa_pkt_num);
found_LoRa_pkt_time = zeros(length(found_LoRa_sim_pkt_start_time),4); % NOTE: a copy, to make things a bit easier
for pktidx=1:found_LoRa_pkt_num
    found_LoRa_pkt{pktidx}.peakhist = zeros(1,floor(zvl_cfg.max_LoRa_sim_pkt_smbl_num));
    found_LoRa_pkt{pktidx}.lowpass_hei = 0; 
    found_LoRa_pkt{pktidx}.lowpass_std = 0;
    for symidx=1:floor(zvl_cfg.LoRa_preamble_all_num)
        if (symidx==zvl_cfg.LoRa_preamble_upc_num+3 || symidx==zvl_cfg.LoRa_preamble_upc_num+4)
            thisloc = 1;
            hereusesig = rcvdownchirpsig{pktidx}(symidx-zvl_cfg.LoRa_preamble_upc_num-2,:);
        else
            thisloc = zvl_cfg.LoRa_preamble_peak_locs(1,symidx);
            hereusesig = abs(rcvsig{pktidx}{1}(symidx+1,:));
        end
        tempp = mod(thisloc + zvl_cfg.nbr_base_vec - 1, zvl_cfg.T) + 1;
        [thissample,b] = max(hereusesig(tempp));
        found_LoRa_pkt{pktidx}.peakhist(symidx) = thissample;
    end
    [a,b] = zvl_predict_peak_hei(found_LoRa_pkt{pktidx}.peakhist(1:floor(zvl_cfg.LoRa_preamble_all_num)));
    found_LoRa_pkt{pktidx}.lowpass_hei = a;
    found_LoRa_pkt{pktidx}.lowpass_std = b;
    
    found_LoRa_pkt{pktidx}.foundpeaks = zeros(1,floor(zvl_cfg.max_LoRa_sim_pkt_smbl_num));
    found_LoRa_pkt{pktidx}.foundpeakidx = zeros(1,floor(zvl_cfg.max_LoRa_sim_pkt_smbl_num));
    found_LoRa_pkt{pktidx}.decode_res = 0;
    found_LoRa_pkt{pktidx}.decode_count = 0;
    
    found_LoRa_pkt{pktidx}.cfo = found_LoRa_pkt_CFO(pktidx);
    found_LoRa_pkt{pktidx}.CR_pld = 0;
    found_LoRa_pkt{pktidx}.crcpass = 0;

    found_LoRa_pkt{pktidx}.starttime = round(found_LoRa_sim_pkt_start_time(pktidx)/OSF);
    found_LoRa_pkt{pktidx}.endtime = found_LoRa_pkt{pktidx}.starttime + zvl_cfg.max_LoRa_sim_pkt_smbl_num * zvl_cfg.T;
    found_LoRa_pkt{pktidx}.symbolnum = zvl_cfg.max_LoRa_sim_pkt_smbl_num;
    
    found_LoRa_pkt{pktidx}.reconpeaklocs = [];

    found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn) = found_LoRa_pkt{pktidx}.starttime;
    found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn_hdr) = found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn) + zvl_cfg.LoRa_preamble_all_num * zvl_cfg.T;
    found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn_data) = found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn_hdr) + zvl_cfg.LoRa_header_smbl_num * zvl_cfg.T;
    found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_endp1) = found_LoRa_pkt{pktidx}.endtime;
end

%--------------------------------------------------------------------------
% process 

for zvl_overall_decode_attempt=1:2
    zvl_curr_time = min(found_LoRa_pkt_time(:,zvl_cfg.time_idx_bgn)) - zvl_cfg.T; 
    w_last_print_time = 0;
    while zvl_curr_time < max(found_LoRa_pkt_time(:,zvl_cfg.time_idx_endp1)) + zvl_cfg.T*3
        [found_LoRa_pkt,found_LoRa_pkt_time] = zvl_epoch_process(found_LoRa_pkt,rcvsig,zvl_curr_time,found_LoRa_pkt_time,found_LoRa_pkt_CFO,zvl_cfg, SF);
        zvl_curr_time = zvl_curr_time + zvl_cfg.T;
        if w_last_print_time < zvl_curr_time - BW
            w_last_print_time = zvl_curr_time;
            fprintf(1,' --- decode attempt %d: at time %.0f sec--- \n', zvl_overall_decode_attempt, zvl_curr_time/BW);
        end
    end
end