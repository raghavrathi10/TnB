% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function hardsel = zvl_make_hardsel(epoch_pkt_num,thisploc,thisphei,zvl_pkt_time_offset,zvl_pkt_cfo_offset,epoch_info,thisknownpeaks,lastknownpeaks,nextknownpeaks,thismask,lastsig,thissig,nextsig,found_LoRa_pkt,zvl_cfg)

hardsel = zeros(1,epoch_pkt_num);

thispeakestcost = zeros(size(thisploc));
thispeak_info = cell(size(thisploc));
for pktidx=1:size(thisploc,1)
    for peakidx=1:size(thisploc,2)
        thisloc = thisploc(pktidx,peakidx);
        if thisloc > zvl_cfg.T
            thispeakestcost(pktidx,peakidx) = -1;
            thispeak_info{pktidx,peakidx} = [];
            continue;
        end
        thishei = thisphei(pktidx,peakidx);
        attpeakhei = zeros(epoch_pkt_num,2);
        for h=1:epoch_pkt_num
            thisdiff = - (zvl_pkt_time_offset(h) - zvl_pkt_time_offset(pktidx));
            thiscfodiff = round(-(zvl_pkt_cfo_offset(h) - zvl_pkt_cfo_offset(pktidx)));
            thisexploc_ext = mod(thisloc + (thisdiff + thiscfodiff)*zvl_cfg.time_n_cfo_shift_sign + zvl_cfg.nbr_base_vec - 1, zvl_cfg.T) + 1;
            for hh=1:2
                if h <= pktidx
                    if hh == 1
                        herechecksignal = thissig(h,:);
                    else
                        herechecksignal = nextsig(h,:);
                    end
                else
                    if hh == 1
                        herechecksignal = lastsig(h,:);
                    else
                        herechecksignal = thissig(h,:);
                    end
                end
                attpeakhei(h,hh) = max(herechecksignal(thisexploc_ext));
            end
        end
        a = max(max(attpeakhei));
        if a > thishei
            thispeakestcost(pktidx,peakidx) = power((a-thishei)/a,2); % NOTE: works better 59 vs 39 than with power
        end
        
        thispeak_info{pktidx,peakidx} = attpeakhei;
    end
end  
tempp = find(thispeakestcost == -1); tempp1 = max(max(max(thispeakestcost)),1); thispeakestcost(tempp) = tempp1*3;

pktpeakcost = zeros(size(thispeakestcost));
for pktidx=1:epoch_pkt_num
    herecost = thispeakestcost(pktidx,:);
    orig_pktidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_pkt_id);
    thisub = found_LoRa_pkt{orig_pktidx}.lowpass_hei + zvl_cfg.stdbuf_c*found_LoRa_pkt{orig_pktidx}.lowpass_std; 
    thislb = max(0, found_LoRa_pkt{orig_pktidx}.lowpass_hei - zvl_cfg.stdbuf_c*found_LoRa_pkt{orig_pktidx}.lowpass_std); 
    if found_LoRa_pkt{orig_pktidx}.decode_count > 0 && found_LoRa_pkt{orig_pktidx}.decode_res == 0 
        heresymidx = epoch_info(pktidx,zvl_cfg.epoch_info_idx_end_smbl);
        if heresymidx <= length(found_LoRa_pkt{orig_pktidx}.peakcurvefit) && heresymidx > 0
            thisfitval = found_LoRa_pkt{orig_pktidx}.peakcurvefit(heresymidx);
            thisthresh = found_LoRa_pkt{orig_pktidx}.peakvarthresh/3;
            thisub = thisfitval + thisthresh;
            thislb = max(0,thisfitval-thisthresh);
        end
    end
    cp_thisphei = thisphei; tempp = find(cp_thisphei==0); cp_thisphei(tempp) = thisub*10;
    tempp0 = cp_thisphei(pktidx,:) - thisub; tempp0(find(tempp0 < 0)) = 0; qqq = find(tempp0 > 0); tempp0(qqq) = tempp0(qqq)./cp_thisphei(pktidx,qqq);
    tempp1 = thislb - cp_thisphei(pktidx,:); tempp1(find(tempp1 < 0)) = 0; qqq = find(tempp1 > 0); tempp1(qqq) = tempp1(qqq)/thislb;
    tempp2 = [tempp0; tempp1]; 
    herehistcost = max(tempp2);
    hereallcost = herecost + herehistcost.*herehistcost*zvl_cfg.hist_c; 
    pktpeakcost(pktidx,:) = hereallcost;
    % fprintf(1,'%d %.2f %.2f %.2f %.2f %.2f\n', epoch_info(pktidx,zvl_cfg.epoch_info_idx_end_smbl), thislb, thisub, max(thisphei), found_LoRa_pkt{orig_pktidx}.lowpass_hei, zvl_cfg.stdbuf_c*found_LoRa_pkt{orig_pktidx}.lowpass_std)
end

orig_pktpeakcost = pktpeakcost; 
heremaxcost = max(max(pktpeakcost))+1;

for zzz=1:epoch_pkt_num
    if thisknownpeaks(zzz) > 0
        thisloc = thisknownpeaks(zzz);
        thisexploc_ext = mod(thisloc + zvl_cfg.nbr_base_vec - 1, zvl_cfg.T) + 1;
        for vvv=1:size(thisploc,2)
            if length(find(thisexploc_ext == thisploc(zzz,vvv)))
                pktpeakcost(zzz,vvv) = heremaxcost;
                hardsel(zzz) = vvv;
                break;
            end
        end
        pktpeakcost(zzz,:) = heremaxcost;
    elseif thisknownpeaks(zzz) == -1
       pktpeakcost(zzz,:) = heremaxcost;
    end
end
for pktidx=1:size(thismask,1)
    for peakidx=1:size(thismask,2)
        if thismask(pktidx,peakidx)
            pktpeakcost(pktidx,peakidx) = heremaxcost;
        end
    end
end


for zzz=1:epoch_pkt_num
    a = min(pktpeakcost');
    [aa,bb] = min(a);
    if aa < heremaxcost  
        hereallcandidates = find(a==aa);
        if length(hereallcandidates) == 1
            thisrounddecisionpktidx = hereallcandidates(1);
        else
            thisscore = zeros(1,length(hereallcandidates));
            for qqq=1:length(hereallcandidates)
                thiscandi = hereallcandidates(qqq);
                [aaa,bbb] = min(pktpeakcost(thiscandi,:));
                thisscore(qqq) = length(find(pktpeakcost(thiscandi,:)==aaa));
            end
            [aaa,bbb] = min(thisscore);
            thisrounddecisionpktidx = hereallcandidates(bbb);
        end
        [aaa,bbb] = min(pktpeakcost(thisrounddecisionpktidx,:));
        thiskptdecision = bbb;
        hardsel(thisrounddecisionpktidx) = thiskptdecision;
        pktpeakcost(thisrounddecisionpktidx,:) = heremaxcost;
        thisloc = thisploc(thisrounddecisionpktidx,thiskptdecision);
        for qqq=1:epoch_pkt_num
            thisdiff = - (zvl_pkt_time_offset(qqq) - zvl_pkt_time_offset(thisrounddecisionpktidx));
            thiscfodiff = round(- (zvl_pkt_cfo_offset(qqq) - zvl_pkt_cfo_offset(thisrounddecisionpktidx)));
            thisexploc_ext = mod(thisloc + (thisdiff + thiscfodiff)*zvl_cfg.time_n_cfo_shift_sign + zvl_cfg.nbr_base_vec - 1, zvl_cfg.T) + 1; 
            for vvv=1:size(thisploc,2)
                if length(find(thisexploc_ext == thisploc(qqq,vvv))) && thishei*2 > thisphei(qqq,vvv)
                    pktpeakcost(qqq,vvv) = heremaxcost;
                end
            end
        end
    end
end