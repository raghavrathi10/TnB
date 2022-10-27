% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [epoch_info,epoch_bgn,epoch_end] = zvl_setup_epoch_info(zvl_curr_time,found_LoRa_pkt_time,found_LoRa_pkt_CFO,zvl_cfg)

epoch_info = []; 
epoch_bgn = 0; 
epoch_end = 0;

pkt_in_epoch = zeros(1,size(found_LoRa_pkt_time,1));
found_pkts = [];
for pktidx=1:size(found_LoRa_pkt_time,1)
    time0 = found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn);
    time1 = found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_bgn_hdr) - zvl_cfg.T * zvl_cfg.LoRa_preamble_dnc_frac_num - zvl_cfg.T; % NOTE: when getting close to the data, align to the data
    time2 = found_LoRa_pkt_time(pktidx,zvl_cfg.time_idx_endp1);
    if zvl_curr_time >= time0 -  zvl_cfg.T && zvl_curr_time < time1
        pkt_in_epoch(pktidx) = 1; 
    end
    if zvl_curr_time >= time1 && zvl_curr_time < time2 + zvl_cfg.T
        pkt_in_epoch(pktidx) = 2; 
    end
    if pkt_in_epoch(pktidx) 
        herealignto = found_LoRa_pkt_time(pktidx,pkt_in_epoch(pktidx));
        thissymbolidx = ceil((zvl_curr_time - herealignto + 1)/zvl_cfg.T); 
        thispktbgn = herealignto + (thissymbolidx-1)*zvl_cfg.T;
        thispktend = thispktbgn + zvl_cfg.T; 
        heresmbloffset = (pkt_in_epoch(pktidx) - 1)*floor(zvl_cfg.LoRa_preamble_all_num);
        thispktsmbl_end = ceil((thispktend - herealignto)/zvl_cfg.T) + heresmbloffset;
        hereinfo = [pktidx,pkt_in_epoch(pktidx),0,thispktsmbl_end,thispktbgn,thispktend, found_LoRa_pkt_CFO(pktidx)];
        found_pkts = [found_pkts; hereinfo];
    end
end

if size(found_pkts,1) > 0
    [a,b] = sort(found_pkts(:,5));
    epoch_info = found_pkts(b,[1,2,3,5,4,7]);
    tempp = epoch_info(:,zvl_cfg.epoch_info_idx_bgn_time) - epoch_info(1,zvl_cfg.epoch_info_idx_bgn_time);
    tempp1 = mod(tempp,zvl_cfg.T);
    [aa,bb] = sort(tempp1);
    epoch_info = epoch_info(bb,:);
end