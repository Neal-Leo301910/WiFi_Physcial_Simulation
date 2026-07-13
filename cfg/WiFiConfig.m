% +cfg/WiFiConfig.m
classdef WiFiConfig < handle
    properties
        % ===== 物理层参数 =====
        Bandwidth = 20e6;           % 带宽 (Hz)
        SubcarrierSpacing = 312.5e3;% 子载波间隔
        NumDataSC = 48;             % 数据子载波数
        NumPilotSC = 4;             % 导频子载波数
        NumTotalSC = 64;            % FFT点数 (20MHz)
        CpLength = 16;              % 循环前缀长度 (samples)
        NumSymbols = 50;            % 每帧OFDM符号数

        % ===== 调制与编码 =====
        MCS = 0;                    % MCS索引 (此处以802.11a为例, 0~7)
        ModulationOrder = 2;        % 1=BPSK, 2=QPSK, 4=16QAM...
        CodeRate = '1/2';           % 编码码率

        % ===== 信道参数 =====
        ChannelModel = 'AWGN';      % 'AWGN' / 'TDL-A' / 'TDL-B' / 'CDL-C'
        SnrRange_dB = 0:5:30;       % SNR仿真范围
        MaxDoppler = 0;             % 最大多普勒 (Hz)
        PathDelays = [0, 10, 20]*1e-9; % 多径时延 (s)
        PathPowers = [0, -3, -6];   % 多径功率 (dB)

        % ===== 射频损伤（默认关闭）=====
        Cfo_Hz = 0;                 % 载波频偏
        PhaseNoiseLevel = -inf;     % 相噪水平 (dBc/Hz)
        IqAmpImbalance = 0;         % IQ幅度不平衡 (dB)
        IqPhaseImbalance = 0;       % IQ相位不平衡 (deg)

        % ===== 仿真控制 =====
        MaxFrames = 1000;           % 最大帧数
        MinErrors = 100;            % 最小错误比特数（早停条件）
        Seed = 42;                  % 随机种子
    end

    properties (Dependent)
        Nbpsc    % Number of bits per subcarrier
        Ncbps    % Number of coded bits per OFDM symbol
        Ndbps    % Number of data bits per OFDM symbol
    end

    methods
        function obj = WiFiConfig(varargin)
            % 支持构造时传入 name-value pairs 覆盖默认值
            % 用法：cfg = WiFiConfig('MCS', 3, 'SnrRange_dB', 0:2:20);
            for i = 1:2:nargin
                obj.(varargin{i}) = varargin{i+1};
            end
            rng(obj.Seed);  % 固定随机种子保证可复现
        end

        function val = get.Nbpsc(obj)
            val = log2(obj.ModulationOrder);
        end

        function val = get.Ncbps(obj)
            val = obj.NumDataSC * obj.Nbpsc;
        end

        function val = get.Ndbps(obj)
            val = obj.Ncbps * obj.calc_code_rate();
        end

        function rate = calc_code_rate(obj)
            nums = str2double(strsplit(obj.CodeRate, '/'));
            rate = nums(1) / nums(2);
        end

        function disp(obj)
            fprintf('===== WiFi PHY 仿真配置 =====\n');
            fprintf('  带宽:      %d MHz\n', obj.Bandwidth/1e6);
            fprintf('  FFT点数:   %d\n', obj.NumTotalSC);
            fprintf('  MCS:       %d\n', obj.MCS);
            fprintf('  码率:      %s\n', obj.CodeRate);
            fprintf('  SNR范围:   [%s] dB\n', ...
                strjoin(string(obj.SnrRange_dB), ', '));
            fprintf('  信道模型:  %s\n', obj.ChannelModel);
            fprintf('==============================\n');
        end
    end
end