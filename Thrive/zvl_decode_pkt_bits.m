% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function [zvl_pkt_pass_CRC_flag, zvl_found_pkt,zvl_additional_corrected] = zvl_decode_pkt_bits(thisrclocs, SF, decoder_choice)

    zvl_pkt_pass_CRC_flag = 0;
    zvl_found_pkt = [];
    zvl_additional_corrected = 0;

    if decoder_choice == 0
        [thisorigdecodepkt_all,CR_pld,pld_length,CRC_pld] = LoRa_Decode_Full(thisrclocs,SF);
        zvl_pkt_pass_CRC_flag = 0;
        if ~(pld_length == 0 || pld_length > 20 || pld_length < 7 || CR_pld > 4 || CR_pld < 1 || (length(thisorigdecodepkt_all)<4+pld_length) )
            zlecc_found_pkt = thisorigdecodepkt_all(4:4+pld_length); 
            if length(zlecc_found_pkt) >= 7
                zvl_pkt_pass_CRC_flag = zlecc_check_message_crc(zlecc_found_pkt,pld_length);
            end
        end        
    else                    
        [CR_pld,CRC_pld,pld_length,zlecc_pldinhdr] = zlecc_decode_hdr(thisrclocs, SF); 
        if CR_pld > 0 && pld_length <= 32
            zlecc_pldmsg = thisrclocs(9:end); 
            [zvl_pkt_pass_CRC_flag, zlecc_found_pkt, zlecc_found_err_loc, zlecc_made_attempt_num, zlecc_total_attempt_num,zvl_additional_corrected] = zlecc_decode_pkt(SF, CR_pld, pld_length, zlecc_pldinhdr, zlecc_pldmsg);
        end
    end
    if zvl_pkt_pass_CRC_flag
        zvl_found_pkt = zlecc_found_pkt(1:pld_length);
    end