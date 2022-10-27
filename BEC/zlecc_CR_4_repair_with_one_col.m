% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [zcorblk,fixedflag,fixedother] = zlecc_CR_4_repair_with_one_col(rcvblk,corblk,diff1locs,diff2idx,H_bin)

zcorblk = corblk;
fixedflag = zeros(1,length(diff2idx));
fixedother = zeros(1,length(diff2idx));
for h=1:length(diff2idx)
    thisidx = diff2idx(h);
    thisrcv = rcvblk(thisidx,:);
    thisrcv(diff1locs) = mod(thisrcv(diff1locs)+1,2);
    thisdiff = zeros(size(H_bin));
    for hh=1:size(H_bin,1)
        thisdiff(hh,:) = thisrcv - H_bin(hh,:);
    end
    tempp = sum(abs(thisdiff)');
    snaptoidx  = find(tempp == 1);
    if length(snaptoidx)
        fixedflag(h) = 1;
        zcorblk(thisidx,:) = H_bin(snaptoidx,:);
        fixedother(h) = find(thisdiff(snaptoidx,:));
    end
end 
