% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [checksig, chechsig_noiseest] = zvl_cal_preamble_sigvec(LoRa_syncexpectlocs,T,OSF,preamble_signal,zvl_base_chirp)
    checksig = zeros(length(LoRa_syncexpectlocs), T);
    chechsig_noiseest = zeros(length(LoRa_syncexpectlocs),1);
    for syncidx=1:length(LoRa_syncexpectlocs)
        thisbgn = (syncidx - 1) * T * OSF + 1;
        thisend = thisbgn + T*OSF - 1;
        if thisbgn > 0
            thissig = preamble_signal(thisbgn:OSF:thisend);
            if syncidx <= 10
                DemodSig = thissig.*conj(zvl_base_chirp);
            else
                DemodSig = thissig.*(zvl_base_chirp);
            end
            checksig(syncidx,:) = (fft(DemodSig));
            chechsig_noiseest(syncidx) = median(abs(checksig(syncidx,:)));
        end
    end
end