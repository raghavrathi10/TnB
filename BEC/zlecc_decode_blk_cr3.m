% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function  [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr3(rcvblk, corblk, knownbadidx, zlecc_common_cfg)

H_bin  = zlecc_common_cfg.H_bin;
H_bin(:,8) = 0;
corrcvdiff = corblk - rcvblk;
[diff0idx,diff1idx,diff2idx,diff1locs] = zlecc_find_diff_in_blk(corrcvdiff,knownbadidx);

for atterrornum=1:2
    zcorrected_locs = [];
    zcorrected_blk = [];

    if atterrornum == 1
        correctedlocs_flag = sum(abs(corrcvdiff));
        corrected_loc = find(correctedlocs_flag); 
        if length(corrected_loc) <= 1
            if length(corrected_loc) == 1
                zcorrected_locs = [corrected_loc];
            end
            zcorrected_blk{1} = corblk;
            break;
        end
    end
    
    if atterrornum == 2
        if length(diff1locs) ==  2
            diff1locs = sort(diff1locs);
            for h=1:size(zlecc_common_cfg.CR3group,1)
                tempp = diff1locs - zlecc_common_cfg.CR3group(h,1:2);
                if sum(abs(tempp)) == 0
                    diff1locs = zlecc_common_cfg.CR3group(h,:);
                    break;
                end
            end
        end
        if length(diff1locs) == 3
            allpossible =  nchoosek(1:length(diff1locs),2);
            for possidx=1:size(allpossible,1)
                tempp = allpossible(possidx,:); thissel = diff1locs(tempp);
               [thisselgoodflag, herezcorblk] = zlecc_check_thissel(H_bin,thissel,rcvblk);
               if thisselgoodflag
                    zcorrected_locs = [zcorrected_locs; thissel];
                    zcorrected_blk{size(zcorrected_locs,1)} = herezcorblk;
                end
            end
        end
    end
end