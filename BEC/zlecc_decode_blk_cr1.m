% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr1(rcvblk, corblk, knownbadidx,zlecc_common_cfg)

errsymdrome = [(mod(rcvblk(:,1) + rcvblk(:,2) + rcvblk(:,3) + rcvblk(:,4),2) - rcvblk(:,5))'];

if length(find(errsymdrome(1,:)))
    allcandidateshere = [1:5];
else
    allcandidateshere = [];
end

zcorrected_locs = [];
zcorrected_blk = [];
if length(allcandidateshere) == 0
    zcorrected_blk{1} = corblk;
else
    zcorrected_locs = zeros(length(allcandidateshere),1);
    for candidx=1:length(allcandidateshere)
        colidx = allcandidateshere(candidx);
        hereidx = [1,2,3,4,5];
        hereidx_wo_this = setdiff(hereidx,colidx);
        tempp1 = rcvblk(:,hereidx_wo_this);
        thisreplacement = mod(sum(tempp1')',2);
        copy_rcvblk = rcvblk;
        copy_rcvblk(:,colidx) = thisreplacement;
        zcorrected_locs(candidx) = allcandidateshere(candidx);
        zcorrected_blk{candidx} = copy_rcvblk;
    end
end