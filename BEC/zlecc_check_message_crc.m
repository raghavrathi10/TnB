% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

function crcpassed = zlecc_check_message_crc(zlecc_found_pkt,pld_length)

actmsg = zlecc_found_pkt(1:pld_length-2);
CRC_dbl_b4wht = zlecc_16_bit_crc(actmsg,pld_length);
tempp = [actmsg, CRC_dbl_b4wht];
tempp1 = zlecc_white(tempp);
CRC_dbl = tempp1((end-1:end));
CRC_read = zlecc_found_pkt(pld_length-1:pld_length);
crcpassed = (sum(abs(double(CRC_dbl)-double(CRC_read))) == 0);
