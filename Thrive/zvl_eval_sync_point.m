% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [thisscore, bup, bdn] = zvl_eval_sync_point(zvl_LoRa_time_sig, cfo_val_p_curr_cfo_est, thisbgn, SF, OSF, zvl_cfg)   
    thisscore = 0;
    T = 2^SF;
    thisadjwave = exp(1i*2*pi*[0:T*length(zvl_cfg.LoRa_syncexpectlocs)*OSF-1]/T/OSF*(cfo_val_p_curr_cfo_est));
    thisend = thisbgn + length(thisadjwave) - 1;
    thisscore = 0;
    if ~(thisbgn <= 0 || thisend > size(zvl_LoRa_time_sig,2))
        
        thissynvec_up = zeros(1,T);
        thissynvec_down = zeros(1,T);
        for ant=1:size(zvl_LoRa_time_sig,1)
            this_sync_sig = zvl_LoRa_time_sig(ant,thisbgn:thisend).*thisadjwave;
            [checksig, chechsig_noiseest] = zvl_cal_preamble_sigvec(zvl_cfg.LoRa_syncexpectlocs,T,OSF,this_sync_sig,zvl_cfg.basechirp);
            upchecksig = checksig(1:zvl_cfg.LoRa_preamble_upc_num + zvl_cfg.LoRa_preamble_sync_num,:);
            for zzz=1:zvl_cfg.LoRa_preamble_sync_num
                zzzidx = zzz + zvl_cfg.LoRa_preamble_upc_num;
                upchecksig(zzzidx,:) = circshift(upchecksig(zzzidx,:),-(zvl_cfg.LoRa_syncexpectlocs(zzzidx)-1));
            end
            tempp = abs(sum(upchecksig));
            thissynvec_up = thissynvec_up + tempp.*tempp;
            tempp = abs(sum(checksig(11:12,:)));
            thissynvec_down = thissynvec_down + tempp.*tempp;
        end
        herecheckrange = [T-2:T,1:3];
        herecheckmask = zeros(1,T); herecheckmask(herecheckrange) = 1;
        tempp = thissynvec_up.*herecheckmask;
        [aup,bup] = max(tempp);
        tempp = thissynvec_down.*herecheckmask;
        [adn,bdn] = max(tempp);
        if 1 % bup == 1 && bdn == 1
            thisscore = aup + adn;
        end
    end
