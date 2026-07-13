% main.m — WiFi物理层仿真总调度
clear; close all;

%% 1. 初始化配置
cfg = cfg.WiFiConfig(...
    'MCS', 0, ...
    'ChannelModel', 'AWGN', ...
    'SnrRange_dB', 0:2:30, ...
    'MaxFrames', 500, ...
    'MinErrors', 500);

disp(cfg);  % 打印当前配置，确保参数没错

%% 2. 预分配结果数组
n_snr = length(cfg.SnrRange_dB);
ber = zeros(1, n_snr);
total_bits = zeros(1, n_snr);
total_errs = zeros(1, n_snr);

%% 3. SNR循环仿真
for snr_idx = 1:n_snr
    snr_db = cfg.SnrRange_dB(snr_idx);
    fprintf('仿真 SNR = %d dB ... ', snr_db);

    while total_errs(snr_idx) < cfg.MinErrors ...
            && total_bits(snr_idx) < cfg.MaxFrames * cfg.Ndbps * cfg.NumSymbols

        % ---- 发射机 ----
        tx_bits = randi([0, 1], cfg.Ndbps * cfg.NumSymbols, 1);
        scrambled_bits = tx.scrambler(tx_bits, cfg);
        coded_bits = tx.convolutional_encoder(scrambled_bits, cfg);
        interleaved_bits = tx.interleaver(coded_bits, cfg);
        mod_symbols = tx.modulator(interleaved_bits, cfg);
        tx_signal = tx.ofdm_modulate(mod_symbols, cfg);

        % ---- 信道 ----
        rx_signal = channel.awgn_channel(tx_signal, cfg, snr_db);

        % ---- 接收机 ----
        freq_symbols = rx.ofdm_demodulate(rx_signal, cfg);
        llr = rx.soft_demod(freq_symbols, cfg);
        deint_llr = rx.deinterleaver(llr, cfg);
        rx_bits = rx.viterbi_decode(deint_llr, cfg);

        % ---- 统计 ----
        frame_errs = sum(tx_bits ~= rx_bits);
        total_errs(snr_idx) = total_errs(snr_idx) + frame_errs;
        total_bits(snr_idx) = total_bits(snr_idx) + length(tx_bits);
    end

    ber(snr_idx) = total_errs(snr_idx) / total_bits(snr_idx);
    fprintf('BER = %.2e (errs=%d, bits=%d)\n', ...
        ber(snr_idx), total_errs(snr_idx), total_bits(snr_idx));
end

%% 4. 结果可视化 & 保存
viz.plot_ber_curve(cfg.SnrRange_dB, ber, ...
    'label', sprintf('MCS%d, %s', cfg.MCS, cfg.ChannelModel), ...
    'color', 'b');

save(fullfile('results', ...
    sprintf('ber_mcs%d_%s.mat', cfg.MCS, cfg.ChannelModel)), ...
    'cfg', 'ber', 'total_errs', 'total_bits');
fprintf('\n仿真完成，结果已保存到 results/\n');