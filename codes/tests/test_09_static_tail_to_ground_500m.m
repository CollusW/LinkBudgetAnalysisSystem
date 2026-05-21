%% test_09_static_tail_to_ground_500m.m
% 500 m 静态链路测试：弹尾冲地面
%
% 目的：
%   1. 构造一个简单静态点：空中端 Tx 与地面端 Rx 直线距离 500 m；
%   2. 按“弹尾冲地面”理解，Tx 弹载天线查询弹尾方向：Phi=90°, Theta=90°；
%   3. 地面天线垂直向上，空中端位于正上方，Rx 查询天顶方向：Phi=0°, Theta=0°；
%   4. 使用真实 Tx/Rx 方向图计算 Gt、Gr；
%   5. 计算 Lfs、Pr、Margin，并输出 CSV 和 TXT 报告。
%
% 注意：
%   本脚本是方向图与链路预算的静态点核对测试，不运行完整运动轨迹仿真。
%   该测试用于检查“弹尾冲地面”时查询角和链路预算是否符合预期。

clear; clc; close all;

%% 0. 工程路径
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

fprintf('\n========== test_09_static_tail_to_ground_500m ==========' );
fprintf('\n工程目录: %s\n', rootDir);
fprintf('=======================================================\n\n');

%% 1. 初始化配置
simCfgIn = struct();
simCfgIn.f = 4.95e9;
simCfgIn.Pt = 20;
simCfgIn.Sens = -90;
simCfgIn.L_other = 0;
simCfgIn.Margin_target = 3;
simCfgIn.angleInputType = 'PhiTheta';
simCfgIn.txPatternSource = 'csv';
simCfgIn.rxPatternSource = 'csv';
simCfgIn.txPatternFile = fullfile(rootDir, 'input', 'tx_antenna_pattern.csv');
simCfgIn.rxPatternFile = fullfile(rootDir, 'input', 'rx_antenna_pattern.csv');

[SimCfg, GeoCfg, RfCfg, AntCfg, AlgoCfg, OutCfg, CfgDiag] = linkInitConfig(simCfgIn);

%% 2. 输出目录
outDir = fullfile(OutCfg.outputDir, 'static_tail_to_ground_500m');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

reportFile = fullfile(outDir, 'static_tail_to_ground_500m_report.txt');
csvFile = fullfile(outDir, 'static_tail_to_ground_500m_result.csv');

%% 3. 静态点定义
% 这里直接定义地面端在原点，空中端在正上方 500 m。
% 这个几何关系用于说明距离；方向图查询角按老师定义直接指定。
d_m = 500;

Rx_pos_m = [0, 0, 0];
Tx_pos_m = [0, 0, 500];

% Tx 弹载天线：弹尾冲地面。
% 老师定义：Phi=90°, Theta=90° 是弹尾。
txPhi_deg = 90;
txTheta_deg = 90;

% Rx 地面天线：垂直向上，空中端在正上方。
% 老师定义：Theta=0° 是天顶方向；Phi 在天顶方向物理意义不敏感，这里取 Phi=0°。
rxPhi_deg = 0;
rxTheta_deg = 0;

%% 4. 读取真实方向图
fprintf('--- 读取 Tx 弹载天线方向图 ---\n');
[AzTx, ThetaTx, GainTx] = loadAntennaPatternCsv( ...
    AntCfg.tx.patternFile, ...
    AntCfg.angleInputType, ...
    RfCfg.freqGHz);

fprintf('\n--- 读取 Rx 地面天线方向图 ---\n');
[AzRx, ThetaRx, GainRx] = loadAntennaPatternCsv( ...
    AntCfg.rx.patternFile, ...
    AntCfg.angleInputType, ...
    RfCfg.freqGHz);

%% 5. 查询 Tx/Rx 天线增益
Gt = getAntennaGain( ...
    txPhi_deg, ...
    txTheta_deg, ...
    AzTx, ...
    ThetaTx, ...
    GainTx, ...
    AntCfg.interpolation, ...
    AntCfg.outOfBound);

Gr = getAntennaGain( ...
    rxPhi_deg, ...
    rxTheta_deg, ...
    AzRx, ...
    ThetaRx, ...
    GainRx, ...
    AntCfg.interpolation, ...
    AntCfg.outOfBound);

Gtotal_actual = Gt + Gr;

%% 6. 链路预算
Lfs = calcFSPL(d_m, RfCfg.f, RfCfg.c);
[Pr, Margin] = calcLinkBudget( ...
    RfCfg.Pt, ...
    Gt, ...
    Gr, ...
    Lfs, ...
    RfCfg.L_other, ...
    RfCfg.Sens);

G_total_required = calcGTotalRequired( ...
    Lfs, ...
    RfCfg.Margin_target, ...
    RfCfg.Pt, ...
    RfCfg.Sens, ...
    RfCfg.L_other);

Margin_to_target = Margin - RfCfg.Margin_target;

%% 7. 控制台输出
fprintf('\n========== 500 m 静态链路测试：弹尾冲地面 ==========' );
fprintf('\n频率 f                 : %.3f GHz', RfCfg.freqGHz);
fprintf('\n发射功率 Pt            : %.2f dBm', RfCfg.Pt);
fprintf('\n接收灵敏度 Sens        : %.2f dBm', RfCfg.Sens);
fprintf('\n其他损耗 L_other       : %.2f dB', RfCfg.L_other);
fprintf('\n目标链路余量           : %.2f dB', RfCfg.Margin_target);
fprintf('\n距离 d                 : %.2f m', d_m);
fprintf('\nTx 查询角              : Phi=%.2f deg, Theta=%.2f deg', txPhi_deg, txTheta_deg);
fprintf('\nRx 查询角              : Phi=%.2f deg, Theta=%.2f deg', rxPhi_deg, rxTheta_deg);
fprintf('\nTx 增益 Gt             : %.3f dBi', Gt);
fprintf('\nRx 增益 Gr             : %.3f dBi', Gr);
fprintf('\n实际总增益 Gt+Gr       : %.3f dBi', Gtotal_actual);
fprintf('\n自由空间路径损耗 Lfs   : %.3f dB', Lfs);
fprintf('\n接收功率 Pr            : %.3f dBm', Pr);
fprintf('\n链路余量 Margin        : %.3f dB', Margin);
fprintf('\n所需总增益 Gt+Gr       : %.3f dBi', G_total_required);
fprintf('\nMargin - 目标余量      : %.3f dB', Margin_to_target);

if Margin >= RfCfg.Margin_target
    passText = '通过：Margin 已达到目标链路余量';
else
    passText = '不通过：Margin 未达到目标链路余量';
end
fprintf('\n判定                    : %s\n', passText);
fprintf('=======================================================\n\n');

%% 8. 保存 CSV
ResultTable = table();
ResultTable.distance_m = d_m;
ResultTable.tx_phi_deg = txPhi_deg;
ResultTable.tx_theta_deg = txTheta_deg;
ResultTable.rx_phi_deg = rxPhi_deg;
ResultTable.rx_theta_deg = rxTheta_deg;
ResultTable.Gt_dBi = Gt;
ResultTable.Gr_dBi = Gr;
ResultTable.Gtotal_actual_dBi = Gtotal_actual;
ResultTable.frequency_GHz = RfCfg.freqGHz;
ResultTable.Pt_dBm = RfCfg.Pt;
ResultTable.Sens_dBm = RfCfg.Sens;
ResultTable.L_other_dB = RfCfg.L_other;
ResultTable.Lfs_dB = Lfs;
ResultTable.Pr_dBm = Pr;
ResultTable.Margin_dB = Margin;
ResultTable.Margin_target_dB = RfCfg.Margin_target;
ResultTable.Margin_to_target_dB = Margin_to_target;
ResultTable.G_total_required_dBi = G_total_required;

writetable(ResultTable, csvFile);

%% 9. 保存 TXT 报告
fid = fopen(reportFile, 'w');

fprintf(fid, '500 m 静态链路测试：弹尾冲地面\n');
fprintf(fid, '本测试只验证单个静态点，不运行完整运动轨迹仿真。\n\n');

fprintf(fid, '一、测试条件\n');
fprintf(fid, '距离 d                 : %.2f m\n', d_m);
fprintf(fid, 'Rx 位置                : [%.2f, %.2f, %.2f] m\n', Rx_pos_m(1), Rx_pos_m(2), Rx_pos_m(3));
fprintf(fid, 'Tx 位置                : [%.2f, %.2f, %.2f] m\n', Tx_pos_m(1), Tx_pos_m(2), Tx_pos_m(3));
fprintf(fid, '频率 f                 : %.3f GHz\n', RfCfg.freqGHz);
fprintf(fid, '发射功率 Pt            : %.2f dBm\n', RfCfg.Pt);
fprintf(fid, '接收灵敏度 Sens        : %.2f dBm\n', RfCfg.Sens);
fprintf(fid, '其他损耗 L_other       : %.2f dB\n', RfCfg.L_other);
fprintf(fid, '目标链路余量           : %.2f dB\n\n', RfCfg.Margin_target);

fprintf(fid, '二、方向图查询角\n');
fprintf(fid, 'Tx 弹载天线：弹尾冲地面，按 Phi=90°, Theta=90° 查询。\n');
fprintf(fid, 'Tx 查询角              : Phi=%.2f deg, Theta=%.2f deg\n', txPhi_deg, txTheta_deg);
fprintf(fid, 'Rx 地面天线：空中端在天顶方向，按 Phi=0°, Theta=0° 查询。\n');
fprintf(fid, 'Rx 查询角              : Phi=%.2f deg, Theta=%.2f deg\n\n', rxPhi_deg, rxTheta_deg);

fprintf(fid, '三、天线增益与链路预算结果\n');
fprintf(fid, 'Tx 增益 Gt             : %.3f dBi\n', Gt);
fprintf(fid, 'Rx 增益 Gr             : %.3f dBi\n', Gr);
fprintf(fid, '实际总增益 Gt+Gr       : %.3f dBi\n', Gtotal_actual);
fprintf(fid, '自由空间路径损耗 Lfs   : %.3f dB\n', Lfs);
fprintf(fid, '接收功率 Pr            : %.3f dBm\n', Pr);
fprintf(fid, '链路余量 Margin        : %.3f dB\n', Margin);
fprintf(fid, '所需总增益 Gt+Gr       : %.3f dBi\n', G_total_required);
fprintf(fid, 'Margin - 目标余量      : %.3f dB\n', Margin_to_target);
fprintf(fid, '判定                    : %s\n\n', passText);

fprintf(fid, '四、说明\n');
fprintf(fid, '1. Tx 查询角使用老师定义的弹尾方向：Phi=90°, Theta=90°。\n');
fprintf(fid, '2. Rx 查询角使用地面天线天顶方向：Phi=0°, Theta=0°。\n');
fprintf(fid, '3. 如果后续确认弹尾方向或地面天线天顶方向定义有变化，需要同步修改本测试中的查询角。\n');
fprintf(fid, '4. 本测试用于方向图与链路预算二次核对，不代表完整运动轨迹场景。\n');

fclose(fid);

fprintf('CSV 结果文件 : %s\n', csvFile);
fprintf('TXT 报告文件 : %s\n', reportFile);
