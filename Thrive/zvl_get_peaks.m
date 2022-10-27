% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [ploc_use,phei_use] = zvl_get_peaks(thissig,TAKE_PK_NUM, masklist, masklen) 

extmasklist = [];
for h=-3:3
    extmasklist = [extmasklist,masklist+h];
end
extmasklist = mod(extmasklist-1, length(thissig)) + 1;
thissig(extmasklist) = 0;

[ploc,phei] = peakfinder(thissig, median(thissig)*16); 

[sorthei, sortorder] = sort(phei, 'descend');
ploc = ploc(sortorder);
phei = phei(sortorder);
maskflag = zeros(1,length(ploc));
for h=1:length(ploc)-1
    thismaskrange = mod(ploc(h) + [-masklen:masklen] - 1, length(thissig)) + 1;
    if maskflag(h) continue; end
    for hh=h+1:length(ploc)
        if find(thismaskrange == ploc(hh))
            maskflag(hh) = 1;
        end
    end
end
ploc(find(maskflag)) = [];
phei(find(maskflag)) = [];

% NOTE: for abs, have been using 4
%       for power, have been using 32, but losing actual signal peaks, so
%       try 16
if length(ploc) < TAKE_PK_NUM
    tempp = TAKE_PK_NUM - length(ploc);
    ploc = [ploc, ones(1,tempp)*2*length(thissig)];
    phei = [phei, zeros(1,tempp)];
end
[a,b] = sort(phei, 'descend');
ploc_use = ploc(b(1:TAKE_PK_NUM));
phei_use = phei(b(1:TAKE_PK_NUM));
[aa,bb] = sort(ploc_use);
ploc_use = ploc_use(bb);
phei_use = phei_use(bb);