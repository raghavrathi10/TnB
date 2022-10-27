% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [est_avg, est_std] = zvl_predict_peak_hei(peak_hist)

est_avg = 0;
est_std = 0;
usemethod = 4; % NOTE: been using 1 for a long time, 4 may be better

if usemethod == 1
    zvl_lowpass_c = 0.8;
    if length(peak_hist) >= 12
        est_avg = peak_hist(1);
        for h=2:length(peak_hist)
            thissample = peak_hist(h);
            thisdiff = abs(est_avg - thissample);
            est_avg = est_avg*zvl_lowpass_c + thissample*(1-zvl_lowpass_c);
            est_std = est_std*zvl_lowpass_c + thisdiff*(1-zvl_lowpass_c);
        end
    end
elseif usemethod == 2
    lpcorder = 8;
    x = peak_hist; tempp = find(x==0); x(tempp) = [];
    [a, thisvar] = lpc(x,min(lpcorder,length(x)));
    thisest = sum([-a(2:end)].*x(end:-1:end-length(a)+2));
    est_avg = max(thisest*1.1,0);
    est_std = thisvar/4;
elseif usemethod == 3 
    % TODO: deal with 0s
    herefitorder = 4;
    herelen = length(peak_hist);
    herelen_m1 = herelen - 1;
    p = polyfit(1:herelen_m1, peak_hist(1:herelen_m1), herefitorder);
    herefit_w_m1 = polyval(p,1:herelen);
    est_std = abs(herefit_w_m1(end) - peak_hist(end));
    p = polyfit(1:herelen, peak_hist, herefitorder);
    herefit = polyval(p,1:herelen+1);
    est_avg = max(herefit(end),0);
elseif usemethod == 4
    if length(peak_hist) >= 12
        herefit = smoothdata(peak_hist,'rlowess',5);
        herediff = abs(peak_hist - herefit); 
        tempp = find(herediff > 0); est_std = median(herediff(tempp));
        useableidx = find(herediff < est_std*4);
        est_avg = herefit(useableidx(end));
        if 0% useableidx(end) > length(peak_hist) - 2
            if length(useableidx) >= 3
                if useableidx(end-2) > useableidx(end)-4
                    diffidx = useableidx(end-2:end);
                    diffdata = herefit(diffidx);
                    diff_diffidx = diff(diffidx);
                    diff_diffdata = diff(diffdata);
                    tempp = diff_diffdata./diff_diffidx;
                    est_diff = mean(tempp);
                    est_avg = est_avg + est_diff;
                    est_avg = max(est_avg,0); 
                end
            end
        end
    end
end