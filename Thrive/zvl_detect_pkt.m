% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

% A Low-Complexity LoRa Synchronization Algorithm Robust to Sampling Time Offsets
% Mathieu Xhonneux, Graduate Student Member, IEEE, Orion Afisiadis, Member, IEEE, David Bol, Senior
% Member, IEEE, and J´erˆome Louveaux, Member, IEEE

function [found_LoRa_sim_pkt_start_time, found_LoRa_pkt_CFO] = zvl_detect_pkt(BW, SF, OSF, zvl_cfg, zvl_LoRa_time_sig)

T = 2^SF;

zvl_peak_num_take_max_dn = 3; 
zvl_peak_num_take_max_up_array = [12,12,12,12,18,24]; 
zvl_peak_num_take_max_up = zvl_peak_num_take_max_up_array(SF-6);

sync_sig = zvl_LoRa_time_sig(:,1:OSF:end);
sync_sigvec_flat = zeros(1,ceil(length(sync_sig)/T)*T);
thisbgn = 1;
while thisbgn < length(sync_sigvec_flat) - T
    thisend = thisbgn + T - 1;
    thissig = sync_sig(:,thisbgn:thisend);
    for ant=1:size(thissig,1)
        DemodSig = zvl_cfg.basechirp.*thissig(ant,:);
        fftDemodSig = (fft(DemodSig));
        sync_sigvec_flat(thisbgn:thisend) = sync_sigvec_flat(thisbgn:thisend) + abs(fftDemodSig).*abs(fftDemodSig);
    end
    thisbgn = thisbgn + T;
end
sync_sigvec = reshape(sync_sigvec_flat, T, length(sync_sigvec_flat)/T)';
sync_rcd = cell(1,size(sync_sigvec,1));
zvl_sync_peak_thresh_coef = 9; % NOTE: using abs was 3, using power, trying 9
for h=1:length(sync_rcd)
    [a,b] = peakfinder(abs(sync_sigvec(h,:)), median((sync_sigvec(h,:)))*zvl_sync_peak_thresh_coef);
    if length(a)
        [tempp,bb] = sort(b, 'descend'); aa = a(bb);
        takenum = min(length(aa),zvl_peak_num_take_max_dn);
        sync_rcd{h}.peakloc = aa(1:takenum);
        sync_rcd{h}.peakhei = tempp(1:takenum);
    else
        sync_rcd{h}.peakloc = [];
        sync_rcd{h}.peakhei = [];
    end
end

candiates_dn = [];
lastinvalid = 0;
for symidx=1:length(sync_rcd)-20
    for peakidx=1:length(sync_rcd{symidx}.peakloc)
        thisloc = sync_rcd{symidx}.peakloc(peakidx);
        thishei = sync_rcd{symidx}.peakhei(peakidx);
        addflag = 1;
        for candidx=lastinvalid+1:length(candiates_dn)
            if candiates_dn{candidx}.bgnsym < symidx - 3
                lastinvalid = candidx;
                continue; 
            end
            thisrange = candiates_dn{candidx}.range;
            if length(find(thisrange == thisloc)) > 0
                addflag = 0;
                thisidx = symidx - candiates_dn{candidx}.bgnsym + 1;
                if candiates_dn{candidx}.hist(2,thisidx) < thishei
                    candiates_dn{candidx}.hist(1, thisidx) = thisloc;
                    candiates_dn{candidx}.hist(2, thisidx) = thishei;
                end
                break;   
            end
        end
        if addflag
            addidx = length(candiates_dn) + 1;
            candiates_dn{addidx}.bgnsym = symidx;
            candiates_dn{addidx}.range = mod(thisloc + [-1:1] - 1, T) + 1;
            candiates_dn{addidx}.peakloc = thisloc;
            candiates_dn{addidx}.hist = zeros(2,10);
            candiates_dn{addidx}.hist(1,1) = thisloc;
            candiates_dn{addidx}.hist(2,1) = thishei;
            candiates_dn{addidx}.rmvflag = 0;
            candiates_dn{addidx}.isupflag = 0;
        end
    end
end

hereremoveflag_dn = zeros(1, length(candiates_dn));
for h=1:length(candiates_dn)
    tempp = (find(candiates_dn{h}.hist(1,:)));
    if length(tempp) < 2
        hereremoveflag_dn(h) = 1;
        candiates_dn{h}.rmvflag = 1;
    else
        thisloc = candiates_dn{h}.peakloc;
        thisest = ((candiates_dn{h}.bgnsym -10)*T + thisloc)*OSF + 1;
        candiates_dn{h}.thisest = thisest;
    end
end


sync_sigvec_up_flat = zeros(1,ceil(length(sync_sig)/T)*T);
thisbgn = 1;
while thisbgn < length(sync_sigvec_flat) - T
    thisend = thisbgn + T - 1;
    thissig = sync_sig(:,thisbgn:thisend);
    for ant=1:size(thissig,1)
        DemodSig = conj(zvl_cfg.basechirp).*thissig(ant,:);
        fftDemodSig = (fft(DemodSig));
        sync_sigvec_up_flat(thisbgn:thisend) = sync_sigvec_up_flat(thisbgn:thisend) + abs(fftDemodSig).*abs(fftDemodSig);
    end
    thisbgn = thisbgn + T;
end
sync_sigvec_up = reshape(sync_sigvec_up_flat, T, length(sync_sigvec_up_flat)/T)';
sync_rcd_up = cell(1,size(sync_sigvec_up,1));
for h=1:length(sync_rcd_up)
    [a,b] = peakfinder(abs(sync_sigvec_up(h,:)), median((sync_sigvec_up(h,:)))*zvl_sync_peak_thresh_coef);
    if length(a)
        [tempp,bb] = sort(b, 'descend'); aa = a(bb);
        takenum = min(length(aa),zvl_peak_num_take_max_up);
        sync_rcd_up{h}.peakloc = aa(1:takenum);
        sync_rcd_up{h}.peakhei = tempp(1:takenum);
    else
        sync_rcd_up{h}.peakloc = [];
        sync_rcd_up{h}.peakhei = [];
    end
end

candiates_up = [];
lastinvalid = 0;
for symidx=1:length(sync_rcd_up)-20
    for peakidx=1:length(sync_rcd_up{symidx}.peakloc)
        thisloc = sync_rcd_up{symidx}.peakloc(peakidx);
        thishei = sync_rcd_up{symidx}.peakhei(peakidx);
        addflag = 1;
        for candidx=lastinvalid+1:length(candiates_up)
            if candiates_up{candidx}.bgnsym < symidx - 12
                lastinvalid = candidx;
                continue; 
            end
            thisrange = candiates_up{candidx}.range;
            if length(find(thisrange == thisloc)) > 0
                addflag = 0;
                thisidx = symidx - candiates_up{candidx}.bgnsym + 1;
                if candiates_up{candidx}.hist(2,thisidx) < thishei
                    candiates_up{candidx}.hist(1, thisidx) = thisloc;
                    candiates_up{candidx}.hist(2, thisidx) = thishei;
                end
                break;   
            end
        end
        if addflag
            addidx = length(candiates_up) + 1;
            candiates_up{addidx}.bgnsym = symidx;
            candiates_up{addidx}.range = mod(thisloc + [-1:1] - 1, T) + 1;
            candiates_up{addidx}.peakloc = thisloc;
            candiates_up{addidx}.hist = zeros(2,100);
            candiates_up{addidx}.hist(1,1) = thisloc;
            candiates_up{addidx}.hist(2,1) = thishei;
            candiates_up{addidx}.rmvflag = 0;
            candiates_up{addidx}.isupflag = 1;
        end
    end
end

hereremoveflag_up = zeros(1, length(candiates_up));
for h=1:length(candiates_up)
    tempp = (find(candiates_up{h}.hist(1,:)));
    if length(tempp) < 7 % used to be 7
        hereremoveflag_up(h) = 1;
        candiates_up{h}.rmvflag = 1;
    else
        thisloc = candiates_up{h}.peakloc;
        thisest = (candiates_up{h}.bgnsym*T - thisloc)*OSF + 1;
        candiates_up{h}.thisest = thisest;
    end
end

keep_list_dn = find(hereremoveflag_dn == 0);
keep_list_up = find(hereremoveflag_up == 0);
candiates  = [candiates_dn(keep_list_dn),candiates_up(keep_list_up)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



zvl_loc_drift_max_up = ceil(32*2^(SF-7)/power(2,BW/125000)); % NOTE: used to be 6, now have to expand it
zvl_loc_drift_max_down = zvl_loc_drift_max_up; % NOTE: used to be 3
zvl_preamble_up_len = 10;
zvl_preamble_down_len = 2;
scanoffset_array = [-2:2]; % NOTE: was [-4:4], but makes no sense, changed to [-2:2], worked, but then missing some pkts 
zvl_symbol_scan_thresh = 5;
upscanval_array = [-zvl_loc_drift_max_up:zvl_loc_drift_max_up];
upscan_idx_array = [1:zvl_preamble_up_len];
downscanval_array = [-zvl_loc_drift_max_down:zvl_loc_drift_max_down];
downscan_idx_array = [zvl_preamble_up_len+1:zvl_preamble_up_len+2];
restricted_scan_array = [-2^(SF-6):2^(SF-6)];
restricted_scan_array = [-3:3];

found_LoRa_sim_pkt_start_time = [];
found_LoRa_pkt_CFO = [];
found_LoRa_sim_pkt_score = [];
sta_sync_res = [];
for candidx=1:length(candiates)
% for candidx=143:143
    
    if candiates{candidx}.isupflag
        herediff = floor(found_LoRa_sim_pkt_start_time/T/OSF) - candiates{candidx}.bgnsym;
        [a,b] = min(abs(herediff));
        if a <= 1
            % fprintf(1, 'candidx %d dup with pkt %d \n', candidx, b)
            continue;
        end
    end

    thisest = candiates{candidx}.thisest;
    thisfromupflag = candiates{candidx}.isupflag;

    % thisest = 5347097;

    thisbgn = thisest + scanoffset_array(1)*OSF*T;
    if thisbgn < 0  continue;  end
    thisend = thisbgn + (length(zvl_cfg.LoRa_syncexpectlocs)+length(scanoffset_array)-1)*OSF*T;
    scan_preamble_signal = zvl_LoRa_time_sig(:,thisbgn:thisend);
    [checksig_up, checksig_dn, chechsig_noiseest_up, chechsig_noiseest_dn] = zvl_cal_scan_preamble_sigvec(length(scanoffset_array), zvl_preamble_up_len, length(downscan_idx_array), T,OSF, scan_preamble_signal,zvl_cfg.basechirp);
    
    scanscore = zeros(1,length(scanoffset_array));
    scanscore_soft = zeros(1,length(scanoffset_array)); 

    scanuploc = zeros(1,length(scanoffset_array));
    scandownloc = zeros(1,length(scanoffset_array));
    scan_updown_x = zeros(length(scanoffset_array),2);

    for scanidx=1:length(scanoffset_array)
 
        checksig = zeros(floor(zvl_cfg.LoRa_preamble_all_num),T); 
        chechsig_noiseest = zeros(floor(zvl_cfg.LoRa_preamble_all_num),1);
        checksig(upscan_idx_array,:) = checksig_up(scanidx-1+upscan_idx_array,:);
        chechsig_noiseest(upscan_idx_array,:) = chechsig_noiseest_up(scanidx-1+upscan_idx_array,:);
        checksig(downscan_idx_array,:) = checksig_dn(scanidx-1+1:scanidx-1+length(downscan_idx_array),:);
        chechsig_noiseest(downscan_idx_array,:) = chechsig_noiseest_dn(scanidx-1+1:scanidx-1+length(downscan_idx_array),:);

        needshiftidx = find(zvl_cfg.LoRa_syncexpectlocs ~= 1);
        for h=1:length(needshiftidx)
            hh = needshiftidx(h);
            hhh = zvl_cfg.LoRa_syncexpectlocs(hh);
            checksig(hh, :) = circshift(checksig(hh, :), -(hhh-1));
        end
        
        found_x_vals_in_preamble = zeros(1,2);
        for updnidx=1:2
            if updnidx == 1
                if thisfromupflag == 0
                    herescanarray = upscanval_array;
                else
                    herescanarray = restricted_scan_array;
                end
                hereidxarrary = upscan_idx_array;
            else
                if thisfromupflag == 0
                    herescanarray = restricted_scan_array; 
                else
                    herescanarray = downscanval_array;
                end
                hereidxarrary = downscan_idx_array;
            end

            checkpointvals_0 = checksig(hereidxarrary,:);
            checkpointvals = checkpointvals_0(:,mod(herescanarray, T) + 1);
            tempp = zvl_sync_peak_thresh_coef*chechsig_noiseest(hereidxarrary);
            threshmat = repmat(tempp, 1,size(checkpointvals,2));
            herediff = checkpointvals - threshmat;
            tempp = find(herediff>0); posdiffflagmat = zeros(size(herediff)); posdiffflagmat(tempp) = 1;
            herescanscores = sum(posdiffflagmat);
            herescansumval = sum(checkpointvals);

            [a,b] = max(herescanscores);
            scanscore(scanidx) = scanscore(scanidx) + a;
            tempp = find(herescanscores<a);
            tempp1 = herescansumval; tempp1(tempp) = 0;
            [aa,bb] = max(tempp1);
            found_x_vals_in_preamble(updnidx) = herescanarray(bb);
            scanscore_soft(scanidx) = scanscore_soft(scanidx) + aa;
        end
        scan_updown_x(scanidx,:) = found_x_vals_in_preamble;
    end

    maxmatchingscore = max(scanscore);
    if maxmatchingscore < zvl_symbol_scan_thresh continue; end
    allmaxlocs = find(scanscore == maxmatchingscore);

    tempp = zeros(1, length(scanscore)); tempp(allmaxlocs) = scanscore_soft(allmaxlocs);
    [a,goodscanloc] = max(tempp);
    
    x1 = scan_updown_x(goodscanloc,1);
    x2 = scan_updown_x(goodscanloc,2);
    int_cfo_est = round((x1+x2)/2); ceil((x1+x2)/2); % NOTE: ceil round makes no diff because x1 and x2 are integers
    int_sto_est = x1 - int_cfo_est;
    thisest_adj_0 = thisest + (scanoffset_array(goodscanloc))*T*OSF - int_sto_est*OSF;
    init_cfo_est = -int_cfo_est; init_sto_est = thisest_adj_0;

    init_fcfo_check_len = zvl_cfg.LoRa_preamble_upc_num;
    this_sync_sig_all_ant_0 = zvl_LoRa_time_sig(:,init_sto_est:init_sto_est+OSF*T*init_fcfo_check_len-1);
    thisadjwave = exp(1i*2*pi*[0:size(this_sync_sig_all_ant_0,2)-1]/T/OSF*(init_cfo_est));
    this_sync_sig_all_ant = this_sync_sig_all_ant_0.*repmat(thisadjwave,size(this_sync_sig_all_ant_0,1),1);
    powersigs = zeros(1,T); cmplx_sigs = [];
    for ant=1:size(this_sync_sig_all_ant,1)
        [checksig, chechsig_noiseest] = zvl_cal_preamble_sigvec(ones(1,init_fcfo_check_len),T,OSF,this_sync_sig_all_ant(ant,:),zvl_cfg.basechirp);
        cmplx_sigs{ant} = checksig;
        powersigs = powersigs + sum(abs(checksig).*abs(checksig));
    end 
    cppowersigs = powersigs; cppowersigs(setdiff([1:T],[T-1:T,1:2])) = 0;
    [a,maxpointloc] = max(cppowersigs);
    peakvals = [];
    for ant=1:size(this_sync_sig_all_ant,1)
        peakvals(ant,:) = transpose(cmplx_sigs{ant}(:,maxpointloc)); 
        phasechg(ant,:) = angle(peakvals(ant,2:end)./peakvals(ant,1:end-1));
    end 
    [a,useant] = max(mean(abs(peakvals')));
    herephase_0 = phasechg(useant,:);
    herephase = herephase_0;
    for h=2:length(herephase)
        if herephase(h)-herephase(h-1) > pi
            herephase(h:end) = herephase(h)-2*pi;
        elseif herephase(h)-herephase(h-1) <- pi
            herephase(h:end) = herephase(h)+2*pi;
        end
    end
    init_fcfo_est = -mean(herephase)/2/pi;

    curr_cfo_est = init_cfo_est;
    curr_sto_est = init_sto_est;

    for outterscanidx=0:2 
        if outterscanidx == 0
            % lora_cfo_val_array = [-1:1/16:0.9999];
            lora_cfo_val_array = [-1:1/16:0];
            fine_sync_offset_array = [0];
        elseif outterscanidx == 1
            % tempp = scores(:,1); foldscores = tempp(1:length(tempp)/2) + tempp(length(tempp)/2+1:end);
            foldscores = scores(:,1);
            [a,b] = peakfinder(foldscores);
            if length(a)
                [tempp,bb] = sort(b, 'descend'); aa = a(bb);
                cfocenter = lora_cfo_val_array(aa(1));
                lora_cfo_val_array = [cfocenter, cfocenter+1];
            else
                lora_cfo_val_array = [];
            end
            fine_sync_offset_array = [-OSF:4:OSF];
        elseif outterscanidx == 2
            tempp = sum(dbg_scores');
            useidx = find(tempp);
            if length(useidx) == 1
                useidx = useidx(1);
                lora_cfo_val_array = lora_cfo_val_array(useidx);
                if 0
                    last_fine_sync_offset_array = fine_sync_offset_array;
                    fine_sync_offset_array = [-OSF:OSF];
                    tempp = find(dbg_scores(useidx,:));
                    if length(tempp) == 2
                        if tempp(1) + 1 == tempp(2)
                            if tempp(1) == 1
                                thisbgn = -OSF;
                            elseif tempp(2) == size(dbg_scores,2)
                                thisbgn = 0;
                            else
                                thisbgn = last_fine_sync_offset_array(tempp(1))-2;
                            end
                            thisend = thisbgn + OSF;  
                            fine_sync_offset_array = [thisbgn:thisend];
                        end
                    end
                else
                    [a,b] = max(dbg_scores(useidx,:));
                    thismid = fine_sync_offset_array(b);
                    fine_sync_offset_array = [thismid-OSF/2:thismid+OSF/2];
                end
            else
                % NOTE: lora_cfo_val_array not changing
                fine_sync_offset_array = [-OSF:OSF];
            end
        end


        scores = [];
        dbg_scores = zeros(length(lora_cfo_val_array),length(fine_sync_offset_array));
        dbg_upl = zeros(size(dbg_scores));
        dbg_dnl = zeros(size(dbg_scores));
        for cfotyidx=1:length(lora_cfo_val_array)
            cfo_val = lora_cfo_val_array(cfotyidx);
            for offsetidx=1:length(fine_sync_offset_array)
                thisoffset = fine_sync_offset_array(offsetidx);
                [thisscore, uploc, dnloc] = zvl_eval_sync_point(zvl_LoRa_time_sig, cfo_val+curr_cfo_est, thisoffset+curr_sto_est, SF, OSF, zvl_cfg);   
                if outterscanidx > 0
                    if ~(uploc==1 && dnloc==1)
                        thisscore = 0;
                    end
                end
                thisres = [thisscore,cfo_val,thisoffset];
                scores = [scores; thisres];
                dbg_scores(cfotyidx,offsetidx) = thisscore;
                if uploc > T/2 uploc = uploc - T -1; end
                if dnloc > T/2 dnloc = dnloc - T- 1; end
                dbg_upl(cfotyidx,offsetidx) = uploc;
                dbg_dnl(cfotyidx,offsetidx) = dnloc;
            end
        end    
        if size(scores,1) > 0 && outterscanidx > 1
            [this_pkt_score,fine_adj_idx] = max(scores(:,1));
            frac_cfo_est = scores(fine_adj_idx,2);
            fine_time_adj = scores(fine_adj_idx,3);
            curr_cfo_est = curr_cfo_est + frac_cfo_est;
            curr_sto_est = curr_sto_est + fine_time_adj;
        end
    end



    cfo_est = curr_cfo_est;
    thisest_adj = curr_sto_est;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    hereaddtoidx = 0;
    if length(found_LoRa_sim_pkt_start_time) == 0
        hereaddtoidx = 1;
    else
        herediff = abs(thisest_adj - found_LoRa_sim_pkt_start_time);
        [a,mindistidx] = min(herediff);
        if a > OSF*10
            hereaddtoidx = length(found_LoRa_pkt_CFO) + 1;
        else
            if found_LoRa_sim_pkt_score(mindistidx) < this_pkt_score
                hereaddtoidx = mindistidx;
            end
        end
    end
    
    if hereaddtoidx > 0
        found_LoRa_pkt_CFO(hereaddtoidx) = cfo_est;
        found_LoRa_sim_pkt_start_time(hereaddtoidx) = thisest_adj;
        found_LoRa_sim_pkt_score(hereaddtoidx) = this_pkt_score;

        herethisidx = length(found_LoRa_sim_pkt_start_time);
        fprintf('%d: found %d, cfo %.3f', herethisidx,  found_LoRa_sim_pkt_start_time(herethisidx), found_LoRa_pkt_CFO(herethisidx));
        fprintf(' -- init found %d (diff %d), init cfo %.3f (diff %f)\n', init_sto_est, init_sto_est-found_LoRa_sim_pkt_start_time(herethisidx), init_cfo_est, init_cfo_est-found_LoRa_pkt_CFO(herethisidx));
        % fprintf('\n');
    end
end

[a,b] = sort(found_LoRa_sim_pkt_start_time);
found_LoRa_sim_pkt_start_time = found_LoRa_sim_pkt_start_time(b);
found_LoRa_pkt_CFO = found_LoRa_pkt_CFO(b);
