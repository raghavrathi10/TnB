% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [zcorrected_locs,zcorrected_blk] = zlecc_decode_blk_cr4(rcvblk, corblk, knownbadidx, zlecc_common_cfg)
 
CR4_VERBOSE_FLAG = 0;
H_bin  = zlecc_common_cfg.H_bin;
H_dec = bi2de(H_bin);
corrcvdiff = corblk - rcvblk;
[diff0idx,diff1idx,diff2idx,diff1locs] = zlecc_find_diff_in_blk(corrcvdiff,knownbadidx);

if 0 % find(corrcvdiff)
    fprintf(1, ' -- one err column num: %d; row err num: [%d %d %d], knownbadidx len %d \n', length(diff1locs), length(diff0idx), length(diff1idx), length(diff2idx), length(knownbadidx));
end

for atterrornum=0:4
    zcorrected_locs = [];
    zcorrected_blk = [];

    if atterrornum == 0
        correctedlocs_flag = sum(abs(corrcvdiff));
        corrected_loc = find(correctedlocs_flag); 
        if length(corrected_loc) == 0
            zcorrected_blk{1} = corblk;
        end
    end
    
    if atterrornum == 1
        correctedlocs_flag = sum(abs(corrcvdiff));
        corrected_loc = find(correctedlocs_flag); 
        if length(corrected_loc) <= 1
            if length(corrected_loc) == 1
                zcorrected_locs = corrected_loc;
            end
            zcorrected_blk{1} = corblk;
        end
    end
    
    if atterrornum == 2
        if length(diff1locs) ==  2
            [thisselgoodflag, herezcorblk] = zlecc_check_thissel(H_bin,diff1locs,rcvblk);
            if thisselgoodflag 
                zcorrected_locs = diff1locs;
                zcorrected_blk{1} = herezcorblk;
                if CR4_VERBOSE_FLAG fprintf(1,'CASE 1 -- got 2 diffone -- '); end
            end
        elseif length(diff1locs) == 1
            [zcorblk,fixedflag,fixedother] = zlecc_CR_4_repair_with_one_col(rcvblk,corblk,diff1locs,diff2idx,H_bin); 
            if length(find(fixedflag==0)) == 0 && length(unique(fixedother)) == 1
                zcorrected_locs = [diff1locs fixedother(1)];
                zcorrected_blk{1} = zcorblk;
                if CR4_VERBOSE_FLAG fprintf(1,'CASE 2 -- got 1 diffone --'); end
            end
        elseif length(diff1locs) == 0
            diffflags = [];
            for h=1:length(diff2idx)
                thisidx = diff2idx(h);
                thisdiff = corrcvdiff(thisidx,:);
                thisflag = zeros(1,size(rcvblk,2)); thisflag(find(thisdiff)) = 1;
                if size(diffflags,1) == 0
                    diffflags = thisflag;
                else
                    canaddflag = 1;
                    for hh=1:size(diffflags,1)
                        tempp = thisflag - diffflags(hh,:);
                        if sum(abs(tempp)) == 0
                            canaddflag = 0;
                            break;
                        end
                    end
                    if canaddflag
                        diffflags = [diffflags; thisflag];
                    end
                end
            end
            thisidx = find(diffflags(1,:));
            for h=1:size(zlecc_common_cfg.CR4_2_group,1)
                if sum(abs(thisidx-zlecc_common_cfg.CR4_2_group(h,1:2))) == 0
                    thisgroup = zlecc_common_cfg.CR4_2_group(h,:);
                    break;
                end
            end
            theo_diffflags = zeros(4,size(diffflags,2));
            for h=1:4
                thisidx = thisgroup((h-1)*2+1:h*2);
                theo_diffflags(h,thisidx) = 1;    
            end
            canuseflag = zeros(1,size(diffflags,1));
            for h=1:size(diffflags,1)
                thisflag = diffflags(h,:);
                for hh=1:size(theo_diffflags,1)
                    if sum(abs(thisflag - theo_diffflags(hh,:))) == 0
                        canuseflag(h) = 1;
                        break;
                    end
                end
            end
            if prod(canuseflag) == 1
                for attidx=1:size(theo_diffflags,1)
                    thisflag = theo_diffflags(attidx,:); 
                    thisflagidx = find(thisflag);
                    zcorblk = rcvblk;
                    for h=1:length(diff2idx)
                        rowidx = diff2idx(h);
                        zcorblk(rowidx,:) = mod(zcorblk(rowidx,:)+thisflag,2);
                    end
                    zcorrected_locs = [zcorrected_locs; thisflagidx];
                    zcorrected_blk{attidx} = zcorblk;
                end
            end
        end
    end

    if atterrornum == 3
        alltrysel = [];
        if length(diff1locs) == 0
            if CR4_VERBOSE_FLAG fprintf(1,'CASE 3 -- got 0 diffone --'); end
        elseif length(diff1locs) == 1
            [zcorblk,fixedflag,fixedother] = zlecc_CR_4_repair_with_one_col(rcvblk,corblk,diff1locs,diff2idx,H_bin); 
            ext_diff1locs = unique(union(diff1locs, fixedother));
            alltrysel = zlecc_CR4_gen_sel(ext_diff1locs,zlecc_common_cfg);
        elseif length(diff1locs) == 2
            for attloc=1:size(rcvblk,2)
                if length(find(diff1locs == attloc))
                    continue;
                end
                alltrysel = [alltrysel; [diff1locs, attloc]];
            end
        elseif length(diff1locs) >= 3 && length(diff1locs) <= 4
            ext_diff1locs = sort(diff1locs);
            alltrysel = zlecc_CR4_gen_sel(ext_diff1locs,zlecc_common_cfg);
        end
        for selidx=1:size(alltrysel,1)
            thissel = alltrysel(selidx,:);
            [thisselgoodflag, herezcorblk] = zlecc_check_thissel(H_bin,thissel,rcvblk);
            if thisselgoodflag 
                zcorrected_locs = [zcorrected_locs; sort(thissel)];
                zcorrected_blk{size(zcorrected_locs,1)} = herezcorblk;
            end
        end
        if length(diff1locs) == 2
            if size(zcorrected_locs,1) == 2
                tempp = [setdiff(zcorrected_locs(1,:),diff1locs), setdiff(zcorrected_locs(2,:),diff1locs)];
                alltrysel = [diff1locs(1),tempp; diff1locs(2),tempp];
                for selidx=1:size(alltrysel,1)
                    thissel = alltrysel(selidx,:);
                    [thisselgoodflag, herezcorblk] = zlecc_check_thissel(H_bin,thissel,rcvblk);
                    if thisselgoodflag 
                        zcorrected_locs = [zcorrected_locs; sort(thissel)];
                        zcorrected_blk{size(zcorrected_locs,1)} = herezcorblk;
                    end
                end
            end
        end
    end
    
    if length(zcorrected_blk) > 0
        break;
    end

end