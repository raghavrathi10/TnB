% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [CR_pld,CRC_pld,pld_length,zlecc_pldinhdr] = zvl_decode_pkt_hdr(smblval, SF)

if 0
    [thisorigdecodepkt_all,CR_pld,pld_length,CRC_pld] = LoRa_Decode_Full([smblval,zeros(1,100)],SF);
    zlecc_pldinhdr = [];
else
    [CR_pld,CRC_pld,pld_length,zlecc_pldinhdr] = zlecc_decode_hdr(smblval, SF);
end