% Implementation in this file is based on
% https://github.com/jkadbear/LoRaPHY
% by jkadbear

function CRC_dbl = zlecc_16_bit_crc(thisres,length_message) 

crcusemethod = 2; % NOTE: use 2

if crcusemethod == 1
    % NOTE: this is the version that has been used for quite some time till
    % the first Powder experiment
    crc16 = comm.CRCGenerator('Polynomial','z^16 + z^12 + z^5 + 1', 'InitialConditions',0,'FinalXOR',1);
    message_b = de2bi(thisres(1:4+length_message+1)); 
    message_b = reshape(message_b,numel(message_b),1);
    crccodeword = crc16(message_b);
    crcbits_0 = crccodeword(end-15:end);
    crcbits = reshape(crcbits_0,8,2)';
    CRC_dbl = bi2de(crcbits)';
elseif crcusemethod == 2
    data = thisres; % thisres(1:4+length_message+1);
    crc_generator = comm.CRCGenerator('Polynomial','X^16 + X^12 + X^5 + 1');
    input = data(1:end-2);
    seq = crc_generator(reshape(logical(de2bi(input, 8, 'left-msb'))', [], 1));
    checksum_b1 = bitxor(bi2de(seq(end-7:end)', 'left-msb'), data(end));
    checksum_b2 = bitxor(bi2de(seq(end-15:end-8)', 'left-msb'), data(end-1));
    CRC_dbl = [checksum_b1, checksum_b2];
elseif crcusemethod == 3
    data = uint8(thisres);
	res = 0; res = uint16(res);
	v = 0xff; v = uint16(v);
	crc = 0; crc = uint16(crc);
	for h=1:4+length_message+1
        for hh=1:8 
            tempp = bitshift(crc,1);
            if bitand(crc, 0x8000)
                crc = bitxor(tempp, poly);
            else
                crc = tempp;
            end
        end
        tempp = bitand(v, 0x00B8);
        tempp = bitxor(tempp, bitshift(tempp,-4));
        tempp = bitxor(tempp, bitshift(tempp,-2));
        tempp = bitxor(tempp, bitshift(tempp,-1));
        tempp = bitand(tempp, 1); 
        tempp1 = bitshift(v,1);
        v = bitor(tempp, tempp1);
		res = bitxor(crc,uint16(data(h)));
    end
	res = bitxor(res,v);
    tempp = bitand(v, 0x00B8);
    tempp = bitxor(tempp, bitshift(tempp,-4));
    tempp = bitxor(tempp, bitshift(tempp,-2));
    tempp = bitxor(tempp, bitshift(tempp,-1));
    tempp = bitand(tempp, 1); 
    tempp1 = bitshift(v,1);
    v = bitor(tempp, tempp1);
	res = bitxor(res, bitshift(v,8));
    CRC_dbl(1) = bitand(res, 0x00ff);
    CRC_dbl(2) = bitshift(bitand(res, 0xff00),-8);
elseif crcusemethod == 4
    data = thisres;
    crc_generator = comm.CRCGenerator('Polynomial','X^16 + X^12 + X^5 + 1');
    input = data(1:end-2);
    seq = crc_generator(reshape(logical(de2bi(input, 8, 'left-msb'))', [], 1));
    checksum_b1 = bitxor(bi2de(seq(end-7:end)', 'left-msb'), data(end));
    checksum_b2 = bitxor(bi2de(seq(end-15:end-8)', 'left-msb'), data(end-1));
    CRC_dbl = [checksum_b1, checksum_b2];
end

