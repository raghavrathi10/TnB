% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [thisselgoodflag, herezcorblk] = zlecc_check_thissel(H_bin,thissel,rcvblk)
    cp_H_bin = H_bin;
    cp_H_bin(:,thissel) = 0;
    cp_rcvblk = rcvblk;
    cp_rcvblk(:,thissel) = 0;
    goodflag = zeros(1,size(cp_rcvblk,1));
    herezcorblk = rcvblk;
    for thisidx=1:size(cp_rcvblk,1)
        thisrcv = cp_rcvblk(thisidx,:);
        tempp = repmat(thisrcv,size(cp_H_bin,1),1); thisdiff = tempp - cp_H_bin;
        tempp = sum(abs(thisdiff)'); snaptoidx  = find(tempp == 0);
        if length(snaptoidx)
            goodflag(thisidx) = 1;
            herezcorblk(thisidx,:) = H_bin(snaptoidx(1),:);
        end
    end
    thisselgoodflag = (sum(goodflag) == length(goodflag)); 