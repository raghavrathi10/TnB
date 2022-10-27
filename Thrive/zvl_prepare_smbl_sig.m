% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [thissig,thisploc,thisphei,thisknownpeaks,thisknownpeakidx,lastknownpeaks,lastknownpeakidx,nextknownpeaks,nextknownpeakidx,thismask,lastsig,nextsig] = zvl_prepare_smbl_sig(epoch_pkt_num,zvl_pkt_time_offset,zvl_pkt_cfo_offset,epoch_info,found_LoRa_pkt,rcvsig,zvl_cfg)

TAKE_PK_NUM = epoch_pkt_num*2; % NOTE: been 2 

thissig = zeros(epoch_pkt_num,zvl_cfg.T);
thisploc = zeros(epoch_pkt_num,TAKE_PK_NUM);
thisphei = zeros(epoch_pkt_num,TAKE_PK_NUM);
thisknownpeaks = zeros(epoch_pkt_num,1);
thisknownpeakidx = zeros(epoch_pkt_num,1); % 0: do not know; >0: know; -1: know have no peaks

lastsig = zeros(size(thissig));
lastploc = zeros(epoch_pkt_num,TAKE_PK_NUM);
lastphei = zeros(epoch_pkt_num,TAKE_PK_NUM);
lastknownpeaks = zeros(epoch_pkt_num,1);
lastknownpeakidx = zeros(epoch_pkt_num,1); 

nextsig = zeros(size(thissig));
nextploc = zeros(epoch_pkt_num,TAKE_PK_NUM);
nextphei = zeros(epoch_pkt_num,TAKE_PK_NUM);
nextknownpeaks = zeros(epoch_pkt_num,1);
nextknownpeakidx = zeros(epoch_pkt_num,1);
    
thismask = zeros(epoch_pkt_num,size(thisploc,2));

for pktidx=1:epoch_pkt_num
    orig_pktidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_pkt_id);

    for hereoffset=-1:1

        heresymidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_end_smbl) + hereoffset;
        herealightoidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_state);
        if heresymidx >= 0
            herethissig = rcvsig{orig_pktidx}{herealightoidx}(heresymidx+1,:);
        else
            herethissig = ones(1,zvl_cfg.T);
        end
        [ploc_use,phei_use] = zvl_get_peaks(abs(herethissig),TAKE_PK_NUM, [], zvl_cfg.peakmasklen); 
        herethisknownpeaks = 0;
        herethisknownpeakidx = 0;
        if heresymidx <= 0 || heresymidx > found_LoRa_pkt{orig_pktidx}.symbolnum+1
            herethisknownpeaks = -1;
        elseif heresymidx <= zvl_cfg.LoRa_preamble_all_num 
            herethisknownpeaks = zvl_cfg.LoRa_preamble_peak_locs(herealightoidx,heresymidx);
        elseif heresymidx > zvl_cfg.LoRa_preamble_all_num
            if found_LoRa_pkt{orig_pktidx}.decode_res == 1
                herepldidx = heresymidx - floor(zvl_cfg.LoRa_preamble_all_num);
                if herepldidx < length(found_LoRa_pkt{orig_pktidx}.reconpeaklocs)
                    herethisknownpeaks = found_LoRa_pkt{orig_pktidx}.reconpeaklocs(herepldidx);
                end
            elseif zvl_cfg.use_last_symbol_decision && hereoffset == -1
                herethisknownpeaks = found_LoRa_pkt{orig_pktidx}.foundpeaks(heresymidx); 
            end
        end
            
        if herethisknownpeaks > 0
            tempp = mod(herethisknownpeaks + zvl_cfg.nbr_base_vec - 1, zvl_cfg.T) + 1;
            for h=1:length(ploc_use)
                if length(find(tempp == ploc_use(h)))
                    herethisknownpeakidx = h;
                    break;
                end
            end
        elseif herethisknownpeaks < 0
            herethisknownpeakidx = -1;
        end

        if hereoffset == -1
            lastsig(pktidx,:) = herethissig;
            lastploc(pktidx,:) = ploc_use;
            lastphei(pktidx,:) = phei_use;
            lastknownpeaks(pktidx) = herethisknownpeaks;
            lastknownpeakidx(pktidx) = herethisknownpeakidx;
        elseif hereoffset == 0
            thisknownpeaks(pktidx) = herethisknownpeaks;
            thisknownpeakidx(pktidx) = herethisknownpeakidx;
            thissig(pktidx,:) = herethissig;
            thisploc(pktidx,:) = ploc_use;
            thisphei(pktidx,:) = phei_use;
        elseif hereoffset == 1
            nextsig(pktidx,:) = herethissig;
            nextploc(pktidx,:) = ploc_use;
            nextphei(pktidx,:) = phei_use;
            nextknownpeaks(pktidx) = herethisknownpeaks;
            nextknownpeakidx(pktidx) = herethisknownpeakidx;
        end
    end
end

for pktidx=1:epoch_pkt_num
    for hereoffset=-1:1
        if hereoffset == -1
            touseknowpeakidx = lastknownpeakidx;
            touseploc = lastploc;
            tousephei = lastphei;
            checkbgn = 1; 
            checkend = pktidx - 1;
        elseif hereoffset == 0
            touseknowpeakidx = thisknownpeakidx;
            touseploc = thisploc;
            tousephei = thisphei;
            checkbgn = 1; 
            checkend = epoch_pkt_num;
        elseif hereoffset == 1
            touseknowpeakidx = nextknownpeakidx;
            touseploc = nextploc;
            tousephei = nextphei;
            checkbgn = pktidx + 1; 
            checkend = epoch_pkt_num;
        end
        if touseknowpeakidx(pktidx) > 0
            herepeakidx = touseknowpeakidx(pktidx);
            hereloc = touseploc(pktidx,herepeakidx);
            herehei = tousephei(pktidx,herepeakidx);
            for pktidx2nd=checkbgn:checkend
                heretimediff = zvl_pkt_time_offset(pktidx) - zvl_pkt_time_offset(pktidx2nd); 
                herecfodiff = round(zvl_pkt_cfo_offset(pktidx) - zvl_pkt_cfo_offset(pktidx2nd));
                heremaskrage = mod(zvl_cfg.nbr_base_vec + hereloc + (heretimediff + herecfodiff)*zvl_cfg.time_n_cfo_shift_sign - 1,zvl_cfg.T)+1;
                for peakidx2nd=1:size(thisploc,2)
                    if length(find(heremaskrage == thisploc(pktidx2nd,peakidx2nd))) > 0 && herehei*2 > thisphei(pktidx2nd,peakidx2nd)
                        thismask(pktidx2nd,peakidx2nd) = pktidx;
                    end
                end
            end
        end
    end
end