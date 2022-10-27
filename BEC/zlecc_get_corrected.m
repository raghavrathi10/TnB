% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function corrcw = zlecc_get_corrected(rcvd,H_bin,CR)

corrcw = zeros(size(rcvd));
for h=1:size(rcvd,1)
    ps0b = rcvd(h,1:4+CR); 
    ps0b_exp = repmat(ps0b,16,1);
    tempp0 = ps0b_exp - H_bin(:,1:4+CR);
    tempp1 = sum(abs(tempp0'));
    [a,b] = min(tempp1);
    corrcw(h,:) = H_bin(b,:);
end 
corrcw(:,4+CR+1:end) = 0;
