% +viz/plot_ber_curve.m
function plot_ber_curve(snr_db, ber, varargin)
%   绘制BER-SNR曲线，支持多组曲线叠加对比
%   用法：viz.plot_ber_curve(snr, ber, 'label', 'AWGN', 'color', 'b');
%         hold on;
%         viz.plot_ber_curve(snr, ber2, 'label', 'TDL-A', 'color', 'r');
    p = inputParser;
    addParameter(p, 'label', '', @ischar);
    addParameter(p, 'color', 'k', @ischar);
    addParameter(p, 'linewidth', 2, @isnumeric);
    addParameter(p, 'marker', 'o-', @ischar);
    parse(p, varargin{:});
    opts = p.Results;

    semilogy(snr_db, ber, [opts.color, opts.marker(2:end)], ...
        'LineWidth', opts.linewidth, ...
        'DisplayName', opts.label);
    grid on; hold on;
    xlabel('SNR (dB)'); ylabel('BER');
    title('WiFi Physical Layer — BER vs SNR');
    legend('Location', 'southwest');
end
