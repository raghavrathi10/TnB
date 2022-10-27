% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr2(rcvblk, corblk, knownbadidx, zlecc_common_cfg)

zcorrected_locs = [];
zcorrected_blk = [];

H_bin  = zlecc_common_cfg.H_bin;
H_bin(:,[7:8]) = 0;
corrcvdiff = corblk - rcvblk;
[diff0idx,diff1idx,diff2idx,diff1locs] = zlecc_find_diff_in_blk(corrcvdiff,knownbadidx);

exp_diff1locs = diff1locs;
for h=1:length(diff1locs)
    hereidx = find(zlecc_common_cfg.CR2group(:,1) == diff1locs(h));
    exp_diff1locs = [exp_diff1locs, zlecc_common_cfg.CR2group(hereidx,2)];
end
exp_diff1locs = unique(exp_diff1locs);

for atterrornum=0:2
    zcorrected_locs = [];
    zcorrected_blk = [];
    
    if atterrornum == 0
        if length(exp_diff1locs) == 0
            zcorrected_blk{1} = rcvblk;
        end
    elseif atterrornum == 1
        if length(exp_diff1locs) == 2
            cantryflag = 0;
            for h=1:size(zlecc_common_cfg.CR2group,1)
                tempp = exp_diff1locs - zlecc_common_cfg.CR2group(h,:);
                if sum(abs(tempp)) == 0
                    cantryflag = 1;
                    break;
                end
            end           
            if cantryflag
                allpossible =  nchoosek(1:length(exp_diff1locs),1);
                for possidx=1:size(allpossible,1)
                    tempp = allpossible(possidx,:); thissel = exp_diff1locs(tempp);
                    [thisselgoodflag, herezcorblk] = zlecc_check_thissel(H_bin,thissel,rcvblk);
                    if thisselgoodflag
                        zcorrected_locs = [zcorrected_locs; thissel];
                        zcorrected_blk{size(zcorrected_locs,1)} = herezcorblk;
                    end
                end
            end
        end
    elseif atterrornum == 2
    end

    if size(zcorrected_blk,1) 
        break;
    end
end