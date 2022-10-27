% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function alltrysel = zlecc_CR4_gen_sel(ext_diff1locs,zlecc_common_cfg)

alltrysel = [];
if length(ext_diff1locs) == 3
    for h=1:size(zlecc_common_cfg.CR4group,1)
        if length(setdiff(ext_diff1locs,zlecc_common_cfg.CR4group(h,:))) == 0
            ext_diff1locs = zlecc_common_cfg.CR4group(h,:);
            break;
        end
    end
end
if length(ext_diff1locs) == 4
    allpossible =  nchoosek(1:length(ext_diff1locs),3);
    for possidx=1:size(allpossible,1)
        tempp = allpossible(possidx,:); thissel = ext_diff1locs(tempp);
        alltrysel = [alltrysel; thissel];
    end
end
