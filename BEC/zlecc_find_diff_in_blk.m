% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [diff0idx,diff1idx,diff2idx,diff1locs] = zlecc_find_diff_in_blk(corrcvdiff,knownbadidx)

hereranks = sum(abs(corrcvdiff'));
diff0idx = find(hereranks==0); 
diff1idx = find(hereranks==1);  
diff2idx = find(hereranks==2);  
diff1locs = [];
for h=1:length(diff1idx)
    tempp = find(corrcvdiff(diff1idx(h),:));
    diff1locs = [diff1locs, tempp];
end
diff1locs = unique(diff1locs);
diff1locs = union(knownbadidx,diff1locs);
if size(diff1locs,1) > 1 diff1locs = diff1locs'; end