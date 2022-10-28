% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

% FOR EDUCATION AND ADADEMIC RESEARCH ONLY 

TraceName = '../AEexpdata/outdoor1-SF8-CR4'; 
SF = 8;

addpath ./Thrive
addpath ./BEC
addpath ./loracode
addpath ./peakfinder

thisfile = fopen(TraceName); A = fread(thisfile, 'int16'); fclose(thisfile); 
zvl_LoRa_time_sig = A(1:2:end) + 1i*A(2:2:end); A = []; zvl_LoRa_time_sig = transpose(zvl_LoRa_time_sig); 

OSF = 8;
BW = 125000;

zvl_init;

[found_LoRa_pkt_start_time, found_LoRa_pkt_CFO] = zvl_detect_pkt(BW, SF, OSF, zvl_cfg, zvl_LoRa_time_sig);
[rcvsig,rcvdownchirpsig] = zvl_cal_rcvsig(BW, SF, OSF, zvl_cfg, found_LoRa_pkt_start_time, found_LoRa_pkt_CFO, zvl_LoRa_time_sig);
found_LoRa_pkt = zvl_decode_found_pkts(BW, SF, OSF, zvl_cfg, found_LoRa_pkt_start_time,found_LoRa_pkt_CFO, rcvsig, rcvdownchirpsig);

TnB_ReportResults;    
