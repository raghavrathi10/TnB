% Copyright (C) 2022 
% Florida State University 
% All Rights Reserved

zvl_cfg.T = 2^SF;
zvl_cfg.basechirp = lora_chirp(0, 1, BW, SF, 0, 0, 1);;

zvl_cfg.LoRa_preamble_upc_num = 8;
zvl_cfg.LoRa_preamble_sync_num = 2;
zvl_cfg.LoRa_preamble_dnc_num = 2.25;
zvl_cfg.LoRa_preamble_all_num = zvl_cfg.LoRa_preamble_upc_num + zvl_cfg.LoRa_preamble_sync_num + zvl_cfg.LoRa_preamble_dnc_num;
zvl_cfg.LoRa_preamble_dnc_frac_num = zvl_cfg.LoRa_preamble_dnc_num - floor(zvl_cfg.LoRa_preamble_dnc_num);

zvl_cfg.LoRa_syncexpectlocs = [ones(1,zvl_cfg.LoRa_preamble_upc_num), 9, 17, 1, 1]; zvl_cfg.pld_peak_shift = 2;
zvl_cfg.time_n_cfo_shift_sign = -1;
tempp2 = mod(zvl_cfg.LoRa_syncexpectlocs - round(zvl_cfg.LoRa_preamble_dnc_frac_num*zvl_cfg.T) - 1, zvl_cfg.T)+1;
zvl_cfg.LoRa_preamble_peak_locs = [zvl_cfg.LoRa_syncexpectlocs; tempp2];
zvl_cfg.LoRa_preamble_peak_locs(:,end-1:end) = -1;

zvl_cfg.decoder_choice = 1;

zvl_cfg.use_last_symbol_decision = 0;
zvl_cfg.run_aligntrack = 0;
zvl_cfg.aligntrack_use_own_peak_finder = 0;
zvl_cfg.aligntrack_use_cfo_info = 0;

if 0
    zvl_cfg.decoder_choice = 0;
    zvl_cfg.use_last_symbol_decision = 1;
    zvl_cfg.run_aligntrack = 1;
    zvl_cfg.aligntrack_use_own_peak_finder = 1;
    zvl_cfg.aligntrack_use_cfo_info = 0;
end

zvl_cfg.epoch_info_idx_pkt_id = 1;
zvl_cfg.epoch_info_idx_state = 2;
zvl_cfg.epoch_info_idx_bgn_smbl = 3;
zvl_cfg.epoch_info_idx_bgn_time = 4;
zvl_cfg.epoch_info_idx_end_smbl = 5;
zvl_cfg.epoch_info_idx_cfo = 6;

zvl_cfg.stdbuf_c = 4; % NOTE: results before 2/28/22 with 4
zvl_cfg.hist_c = 0.1; % NOTE: has been using 0.1

zvl_cfg.time_idx_bgn = 1;
zvl_cfg.time_idx_bgn_hdr = 2; 
zvl_cfg.time_idx_bgn_data = 4; % NOTE: to be consistent
zvl_cfg.time_idx_endp1 = 3;

zvl_cfg.LoRa_header_smbl_num = 8;
zvl_cfg.LoRa_header_smbl_count = zvl_cfg.LoRa_preamble_all_num + zvl_cfg.LoRa_header_smbl_num;
zvl_cfg.LoRa_max_data_smbl_num = 50; % TODO
zvl_cfg.max_LoRa_sim_pkt_smbl_num = (zvl_cfg.LoRa_preamble_all_num + zvl_cfg.LoRa_header_smbl_num + zvl_cfg.LoRa_max_data_smbl_num ); 


exp_oneside_L = SF-5; % NOTE: has been 1 
zvl_cfg.nbr_base_vec = [-exp_oneside_L:exp_oneside_L];
if BW <= 125000
    zvl_cfg.peakmasklen = 1;
elseif BW <= 250000
    zvl_cfg.peakmasklen = 2;
elseif BW <= 500000
    zvl_cfg.peakmasklen = 3;    
end
zvl_cfg.peakmasklen = max(exp_oneside_L, zvl_cfg.peakmasklen);