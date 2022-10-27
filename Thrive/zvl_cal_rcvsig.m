% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [rcvsig,rcvdownchirpsig] = zvl_cal_rcvsig(BW, SF, OSF, zvl_cfg, found_LoRa_sim_pkt_start_time, found_LoRa_pkt_CFO, zvl_LoRa_time_sig)

found_LoRa_pkt_num = length(found_LoRa_sim_pkt_start_time);
rcvsig = cell(1,found_LoRa_pkt_num);
rcvdownchirpsig = cell(1,found_LoRa_pkt_num);
for pktidx=1:found_LoRa_pkt_num
    cfo_val = found_LoRa_pkt_CFO(pktidx);
    thiscfoadjwave = exp(2*pi*1i*[0:zvl_cfg.T-1]*cfo_val/zvl_cfg.T);
    thisrcvdownchirpsig = zeros(2,zvl_cfg.T); 
    for pktalignidx=1:2
        thisrcvsig = zeros(floor(zvl_cfg.max_LoRa_sim_pkt_smbl_num+3),zvl_cfg.T); % NOTE: add the before and after zvl_cfg.T samples to run the code
        for symidx=1:size(thisrcvsig,1)
            thisbgn = found_LoRa_sim_pkt_start_time(pktidx) + (symidx-2)*zvl_cfg.T*OSF + round((pktalignidx-1)*zvl_cfg.LoRa_preamble_dnc_frac_num*zvl_cfg.T*OSF);
            thisend = thisbgn + zvl_cfg.T*OSF - 1;
            if thisbgn < 0 || thisend > length(zvl_LoRa_time_sig) 
                continue; 
            end
            for ant=1:size(zvl_LoRa_time_sig,1)
                sig = zvl_LoRa_time_sig(ant,thisbgn:OSF:thisend).*thiscfoadjwave;
                DemodSig = conj(zvl_cfg.basechirp).*sig;
                fftDemodSig = abs(fft(DemodSig));
                thisrcvsig(symidx,:) = thisrcvsig(symidx,:) + fftDemodSig.*fftDemodSig;
                if (symidx==zvl_cfg.LoRa_preamble_upc_num+4 || symidx==zvl_cfg.LoRa_preamble_upc_num+5) && pktalignidx == 1
                    DemodSig = (zvl_cfg.basechirp).*sig;
                    fftDemodSig = abs(fft(DemodSig));
                    thisrcvdownchirpsig(symidx-zvl_cfg.LoRa_preamble_upc_num-3,:) = thisrcvdownchirpsig(symidx-zvl_cfg.LoRa_preamble_upc_num-3,:) + fftDemodSig.*fftDemodSig;
                end
            end
        end
        rcvsig{pktidx}{pktalignidx} = thisrcvsig;
    end
    rcvdownchirpsig{pktidx} = thisrcvdownchirpsig;
end
