% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

% Part of the implementation in this file uses information in
% # LoRaMatlab
% LoRa Modulation and Coding Scheme Simulator on Matlab
% # Cite as
% Please cite the code which is part of our accepted publication:
% B. Al Homssi, K. Dakic, S. Maselli, H. Wolf, S. Kandeepan, and A. Al-Hourani, "IoT Network Design using Open-Source LoRa Coverage Emulator," in IEEE Access. 2021.
% Link on IEEE:
% https://ieeexplore.ieee.org/document/9395074
% Link on researchgate:
% https://www.researchgate.net/publication/350581481_IoT_Network_Design_using_Open-Source_LoRa_Coverage_Emulator

function zlecc_common_cfg = zlecc_gen_common()

zlecc_common_cfg.CRCattmax = [25,16,16,16]; % NOTE: orig: [125, 16, 16, 16]

zlecc_header_peak_num = 8;
H = [0,210,85,135,153,75,204,30,225,51,180,102,120,170,45,255] ; 
H_bin = de2bi(H);
LoRs_shuffle_order = [2,3,4,6,5,1,7,8];
H_bin = H_bin(:,LoRs_shuffle_order);
H_dec = bi2de(H_bin);

zlecc_common_cfg.zlecc_header_peak_num = zlecc_header_peak_num;
zlecc_common_cfg.H_bin = H_bin;
zlecc_common_cfg.H_dec = H_dec;
zlecc_common_cfg.LoRs_shuffle_order = LoRs_shuffle_order;

hereallcomb = nchoosek([1:6],1); heregroup = [];
for www=1:size(hereallcomb,1)
    wwwone = hereallcomb(www,:);
    diffflags = zeros(1,6); diffflags(wwwone) = 1;
    toadd = [];
    for h=1:size(H_bin,1)
        tempp = diffflags - H_bin(h,1:6);
        if length(find(tempp)) == 1
            temppflag = zeros(size(tempp)); temppflag(find(tempp)) = 1;
            toadd = [toadd; temppflag];
            heregroup(www) = find(tempp);
        end
    end
end
zlecc_common_cfg.CR2group = [hereallcomb';heregroup]';

hereallcomb = nchoosek([1:7],2); heregroup = [];
for www=1:size(hereallcomb,1)
    wwwone = hereallcomb(www,:);
    diffflags = zeros(1,7); diffflags(wwwone) = 1;
    toadd = [];
    for h=1:size(H_bin,1)
        tempp = diffflags - H_bin(h,1:7);
        if length(find(tempp)) == 1
            temppflag = zeros(size(tempp)); temppflag(find(tempp)) = 1;
            toadd = [toadd; temppflag];
            heregroup(www) = find(tempp);
        end
    end
    % fprintf('%d\n',size(toadd,1));
end
zlecc_common_cfg.CR3group = [hereallcomb';heregroup]';

hereallcomb = nchoosek([1:8],3); heregroup = [];
for www=1:size(hereallcomb,1)
    wwwone = hereallcomb(www,:);
    diffflags = zeros(1,8); diffflags(wwwone) = 1;
    toadd = [];
    for h=1:size(H_bin,1)
        tempp = diffflags - H_bin(h,1:8);
        if length(find(tempp)) == 1
            temppflag = zeros(size(tempp)); temppflag(find(tempp)) = 1;
            toadd = [toadd; temppflag];
            heregroup(www) = find(tempp);
        end
    end
end
CR4group_raw = [hereallcomb';heregroup]';
herermflag = zeros(1,size(CR4group_raw,1));
for www=1:size(CR4group_raw,1)
    CR4group_raw(www,:) = sort(CR4group_raw(www,:));
    b = CR4group_raw(www,:);
    for hhh=1:www-1
        a =  CR4group_raw(hhh,:);
        if sum(abs(a - b)) == 0
            herermflag(www) = 1;
            break;
        end
    end
end
CR4group = CR4group_raw; CR4group(find(herermflag),:) = [];
zlecc_common_cfg.CR4group = CR4group; 

hereallcomb = nchoosek([1:8],2); heregroup = [];
for www=1:size(hereallcomb,1)
    wwwone = hereallcomb(www,:);
    diffflags = zeros(1,8); diffflags(wwwone) = 1;
    toadd = [];
    for h=1:size(H_bin,1)
        tempp = diffflags - H_bin(h,1:8);
        if length(find(tempp)) == 2
             toadd = [toadd, find(tempp)];
        end
    end
    heregroup = [heregroup; toadd];
end
zlecc_common_cfg.CR4_2_group = heregroup;