% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [checksig_up, checksig_dn, chechsig_noiseest_up, chechsig_noiseest_dn] = zvl_cal_scan_preamble_sigvec(scan_num, preamble_up_len, preamble_dn_len, T,OSF,preamble_signal,zvl_base_chirp)
    
    len_up = scan_num + preamble_up_len - 1;
    checksig_up = zeros(len_up, T);
    chechsig_noiseest_up = zeros(len_up,1);
    len_dn = scan_num + preamble_dn_len - 1;
    checksig_dn = zeros(len_dn, T);
    chechsig_noiseest_dn = zeros(len_dn,1);

    for ant=1:size(preamble_signal,1)
        for syncidx=1:len_up
            thisbgn = (syncidx - 1) * T * OSF + 1;
            thisend = thisbgn + T*OSF - 1;
            thissig = preamble_signal(ant, thisbgn:OSF:thisend);
            DemodSig = thissig.*conj(zvl_base_chirp);
            thissigvec = abs(fft(DemodSig)).*abs(fft(DemodSig));
            checksig_up(syncidx,:) = checksig_up(syncidx,:) + thissigvec;
            chechsig_noiseest_up(syncidx) = chechsig_noiseest_up(syncidx) + median(thissigvec);
        end
    
        for syncidx=1:len_dn
            thisbgn = (syncidx - 1 + preamble_up_len) * T * OSF + 1;
            thisend = thisbgn + T*OSF - 1;
            thissig = preamble_signal(ant, thisbgn:OSF:thisend);
            DemodSig = thissig.*(zvl_base_chirp);
            thissigvec = abs(fft(DemodSig)).*abs(fft(DemodSig));
            checksig_dn(syncidx,:) = checksig_dn(syncidx,:) + thissigvec;
            chechsig_noiseest_dn(syncidx) = chechsig_noiseest_dn(syncidx) + median(thissigvec);
        end
    end
end