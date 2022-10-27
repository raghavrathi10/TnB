%--------------------------------------------------------------------------
% reporting

sta_crc_res = [];
for h=1:length(found_LoRa_pkt)
    if found_LoRa_pkt{h}.crcpass
        node = found_LoRa_pkt{h}.node;
        seqnum = found_LoRa_pkt{h}.seqnum;
        BECadd = found_LoRa_pkt{h}.additional_corrected;
        if node > 0
            sta_crc_res = [sta_crc_res; [node, seqnum, h, BECadd]];
        end
    end
end
sta_decoded_pkt_num = 0;
if size(sta_crc_res,1)
    tempp = double(sta_crc_res(:,1))*1000000 + double(sta_crc_res(:,2));
    sta_decoded_pkt_num = length(unique(tempp));
end

sta_hdr_res = [];
for h=1:length(found_LoRa_pkt)
    if found_LoRa_pkt{h}.CR_pld > 0 && found_LoRa_pkt{h}.pld_length == 16
        if found_LoRa_pkt{h}.crcpass
            node = double(found_LoRa_pkt{h}.node);
            seqnum = double(found_LoRa_pkt{h}.seqnum);
            sta_hdr_res = [sta_hdr_res; [node, seqnum, h, found_LoRa_pkt{h}.starttime]];
        else
            sta_hdr_res = [sta_hdr_res; [0, 0, h, found_LoRa_pkt{h}.starttime]];
        end
    end
end
sta_detected_pkt_num = size(sta_hdr_res,1);

sta_decoded_hist = [];
if size(sta_crc_res,1)
    sta_decoded_node_list = unique(sta_crc_res(:,1));
    for nodeidx=1:length(sta_decoded_node_list)
        node = sta_decoded_node_list(nodeidx);
        tempp = (find(sta_crc_res(:,1) == node));
        thisnodeinfo = sta_crc_res(tempp,:);
        detectid = thisnodeinfo(:,3);
        SNRhist = []; timehist = []; cfohist = [];
        for dpidx=1:length(detectid)
            thisdp = detectid(dpidx);
            thissmblsnr = [];
            for smblidx=1:found_LoRa_pkt{thisdp}.symbolnum
                thispekpower = found_LoRa_pkt{thisdp}.peakhist(smblidx);
                thisnoisepower = median(rcvsig{thisdp}{2}(smblidx+1,:));
                tempp = thispekpower/thisnoisepower/2^SF;
                thissmblsnr = [thissmblsnr, tempp];
            end
            thisSNR = mean(thissmblsnr);
            SNRhist = [SNRhist,thisSNR];
            timehist = [timehist,found_LoRa_pkt{thisdp}.starttime];
            cfohist = [cfohist, found_LoRa_pkt{thisdp}.cfo];
        end
        thisinfo = [double(node),size(thisnodeinfo,1), 10*log10(mean(SNRhist))];
        sta_decoded_hist{nodeidx}.node = double(node);
        sta_decoded_hist{nodeidx}.seq = thisnodeinfo(:,2);
        sta_decoded_hist{nodeidx}.SNR = SNRhist;
        sta_decoded_hist{nodeidx}.time = timehist;
        sta_decoded_hist{nodeidx}.cfo = cfohist;
    end
end

fprintf('\n----------------- Report -------------------\n\n');
for nodeidx=1:length(sta_decoded_hist)
    fprintf(1,'node %d with %d packets received:\n', sta_decoded_hist{nodeidx}.node, length(sta_decoded_hist{nodeidx}.seq));
    for pktidx=1:length(sta_decoded_hist{nodeidx}.seq)
        fprintf(1,'\t | seq %3d | est SNR %5.2f dB | time %7d | cfo %5.2f |\n', sta_decoded_hist{nodeidx}.seq(pktidx), ...
            sta_decoded_hist{nodeidx}.SNR(pktidx),sta_decoded_hist{nodeidx}.time(pktidx),sta_decoded_hist{nodeidx}.cfo(pktidx));
    end
end

fprintf('\n--- TnB decoded %d pkts ---\n\n', sta_decoded_pkt_num);
%--------------------------------------------------------------------------
