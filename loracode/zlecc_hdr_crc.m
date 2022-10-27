% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function crcits = zlecc_hdr_crc(hdrbytes)

H = [
1 1 0 0 0
1 0 1 0 0
1 0 0 1 0
1 0 0 0 1
0 1 1 0 0
0 1 0 1 0
0 1 0 0 1
0 0 1 1 0
0 0 1 0 1
0 0 0 1 1
0 0 1 1 1
0 1 0 1 1];

hdrbits_all = de2bi(hdrbytes,8);
hdrbits_all = hdrbits_all(:,8:-1:1);
hdrbits_all_flat = reshape(hdrbits_all',1, numel(hdrbits_all));
hdrbits_use = hdrbits_all_flat(1:size(H,1));
crcits = mod(hdrbits_use*H,2);
crcits = crcits(end:-1:1);
