%% test_08_antenna_pattern_validation.m
% 天线方向图独立验证脚本
%
% 目的：
% 1. 单独读取 Tx/Rx 方向图；
% 2. 绘制二维等高线图；
% 3. 绘制关键方向一维切面；
% 4. 检查弹头、弹尾、侧面、地面上半球等关键区域增益；
% 5. 对 Tx 弹尾 Phi=90°, Theta=90° 附近 ±15° 区域进行局部放大验证。
%
% 注意：
% 当前脚本只验证方向图本身，不跑完整链路预算。

clear; clc; close all;

%% 0. 工程路径
rootDir = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(rootDir));

fprintf('\n========== test_08_antenna_pattern_validation ==========' );
fprintf('\n工程目录: %s\n', rootDir);
fprintf('========================================================\n\n');

%% 1. 初始化配置
simCfgIn = struct();
simCfgIn.f = 4.95e9;
simCfgIn.angleInputType = 'PhiTheta';
simCfgIn.txPatternSource = 'csv';
simCfgIn.rxPatternSource = 'csv';
simCfgIn.txPatternFile = fullfile(rootDir, 'input', 'tx_antenna_pattern.csv');
simCfgIn.rxPatternFile = fullfile(rootDir, 'input', 'rx_antenna_pattern.csv');

[SimCfg, GeoCfg, RfCfg, AntCfg, AlgoCfg, OutCfg, CfgDiag] = linkInitConfig(simCfgIn); %#ok<ASGLU>

%% 2. 输出目录
figDir = fullfile(OutCfg.figureDir, 'antenna_validation');

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

reportFile = fullfile(figDir, 'antenna_validation_report.txt');
fid = fopen(reportFile, 'w');

if fid < 0
    error('无法创建方向图验证报告文件：%s', reportFile);
end

fprintf(fid, '天线方向图独立验证报告\n');
fprintf(fid, '频率设置: %.3f GHz\n\n', RfCfg.freqGHz);
fprintf(fid, '说明：本脚本只验证方向图本身，不运行完整链路预算。\n');
fprintf(fid, 'Rx 地面方向图：Theta=0° 按天顶方向理解，Theta=-90~90° 按上半球覆盖角域统计。\n');
fprintf(fid, 'Tx 弹载方向图：Phi=270°,Theta=90° 按弹头；Phi=90°,Theta=90° 按弹尾。\n\n');

%% 3. 读取 Tx / Rx 方向图
fprintf('\n--- 读取 Tx 弹载天线方向图 ---\n');
[AzTx, ElTx, GainTx] = loadAntennaPatternCsv( ...
    AntCfg.tx.patternFile, ...
    AntCfg.angleInputType, ...
    RfCfg.freqGHz);

fprintf('\n--- 读取 Rx 地面天线方向图 ---\n');
[AzRx, ElRx, GainRx] = loadAntennaPatternCsv( ...
    AntCfg.rx.patternFile, ...
    AntCfg.angleInputType, ...
    RfCfg.freqGHz);

fprintf(fid, 'Tx 方向图文件: %s\n', AntCfg.tx.patternFile);
fprintf(fid, 'Tx Phi/Az 范围: %.3f ~ %.3f deg\n', min(AzTx(:)), max(AzTx(:)));
fprintf(fid, 'Tx Theta 范围: %.3f ~ %.3f deg\n', min(ElTx(:)), max(ElTx(:)));
fprintf(fid, 'Tx Gain 范围: %.3f ~ %.3f dBi\n\n', min(GainTx(:)), max(GainTx(:)));

fprintf(fid, 'Rx 方向图文件: %s\n', AntCfg.rx.patternFile);
fprintf(fid, 'Rx Phi/Az 范围: %.3f ~ %.3f deg\n', min(AzRx(:)), max(AzRx(:)));
fprintf(fid, 'Rx Theta 范围: %.3f ~ %.3f deg\n', min(ElRx(:)), max(ElRx(:)));
fprintf(fid, 'Rx Gain 范围: %.3f ~ %.3f dBi\n\n', min(GainRx(:)), max(GainRx(:)));

%% 4. 绘制二维等高线图
PlotPatternContour( ...
    AzTx, ElTx, GainTx, ...
    'Tx 弹载天线方向图：Phi / Theta / Gain', ...
    'Phi [deg]', ...
    'Theta [deg]', ...
    fullfile(figDir, 'tx_pattern_contour.png'));

PlotPatternContour( ...
    AzRx, ElRx, GainRx, ...
    'Rx 地面天线方向图：Phi / Theta / Gain，Theta=0°为天顶', ...
    'Phi [deg]', ...
    'Theta [deg]', ...
    fullfile(figDir, 'rx_pattern_contour.png'));

%% 5. Tx 关键方向增益检查
% 老师说明：
%   Phi=270°, Theta=90° 是弹头方向；
%   Phi=90°,  Theta=90° 是弹尾方向。
% 若后续确认天线安装坐标不同，需要同步修改这里的关键方向定义。

txKeys = {
    '弹头方向 head', 270, 90;
    '弹尾方向 tail', 90, 90;
    '侧面方向 side-0', 0, 90;
    '侧面方向 side-180', 180, 90;
    'Z轴/主辐射方向 top', 0, 0;
};

fprintf('\n--- Tx 弹载天线关键方向增益 ---\n');
fprintf(fid, '--- Tx 弹载天线关键方向增益 ---\n');

for i = 1:size(txKeys, 1)
    name = txKeys{i, 1};
    phi = txKeys{i, 2};
    theta = txKeys{i, 3};

    G = QueryGain(AzTx, ElTx, GainTx, phi, theta);

    fprintf('%s: Phi=%.1f deg, Theta=%.1f deg, Gain=%.3f dBi\n', ...
        name, phi, theta, G);

    fprintf(fid, '%s: Phi=%.1f deg, Theta=%.1f deg, Gain=%.3f dBi\n', ...
        name, phi, theta, G);
end

fprintf(fid, '\n');

%% 6. Tx 弹尾 ±15° 区域检查
% 这里先按矩形近似区域检查：
%   Phi 在 90±15 deg；
%   Theta 在 90±15 deg。
% 如果老师要求严格球面角距离，后续再升级为球面夹角统计。

tailPhi0 = 90;
tailTheta0 = 90;
tailRangeDeg = 15;

tailMask = abs(WrapTo180Local(AzTx - tailPhi0)) <= tailRangeDeg & ...
           abs(ElTx - tailTheta0) <= tailRangeDeg;

tailGain = GainTx(tailMask);

fprintf('\n--- Tx 弹尾 ±15° 区域增益统计 ---\n');
fprintf(fid, '--- Tx 弹尾 ±15° 区域增益统计 ---\n');

if isempty(tailGain)
    fprintf('弹尾 ±15° 区域没有找到网格点，请检查方向图角度范围。\n');
    fprintf(fid, '弹尾 ±15° 区域没有找到网格点，请检查方向图角度范围。\n');
else
    fprintf('弹尾 ±15° 区域 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(tailGain), mean(tailGain), max(tailGain));

    fprintf(fid, '弹尾 ±15° 区域 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(tailGain), mean(tailGain), max(tailGain));

    fprintf(fid, '说明：是否满足“弹尾 ±15° 大于 5 dBi”，需结合老师最终指标与坐标定义判定。\n');
end

fprintf(fid, '\n');

%% 6.1 Tx 弹尾 ±15° 局部放大等高线图
PlotLocalContour( ...
    AzTx, ElTx, GainTx, ...
    75, 105, ...
    75, 105, ...
    'Tx 弹载天线：弹尾 ±15° 局部方向图，中心 Phi=90°, Theta=90°', ...
    fullfile(figDir, 'tx_tail_zoom_phi75_105_theta75_105.png'));

%% 7. Rx 地面天线上半球覆盖检查
% 老师说明：
%   地面天线垂直向上安装；
%   Phi = 方位角 0~360°；
%   Theta = 上下角 -90~90°；
%   Theta = 0° 为天顶方向。
%
% 因此，这里将 Theta=-90~90 整体作为地面天线的上半球覆盖角域，
% 重点统计该角域内 Gain > -1 dBi 的比例。

rxHemiMask = ElRx >= -90 & ElRx <= 90;
rxHemiGain = GainRx(rxHemiMask);

theta0Mask = abs(ElRx - 0) < 1e-9;
theta0Gain = GainRx(theta0Mask);

horizonMask = abs(abs(ElRx) - 90) < 1e-9;
horizonGain = GainRx(horizonMask);

fprintf('\n--- Rx 地面天线上半球覆盖统计 ---\n');
fprintf(fid, '--- Rx 地面天线上半球覆盖统计 ---\n');

if ~isempty(rxHemiGain)
    pctAboveNeg1 = 100 * mean(rxHemiGain > -1);

    fprintf('Rx 覆盖角域 Theta=-90~90 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(rxHemiGain), mean(rxHemiGain), max(rxHemiGain));
    fprintf('Rx 覆盖角域 Gain > -1 dBi 占比 = %.2f %%\n', pctAboveNeg1);

    fprintf(fid, 'Rx 覆盖角域 Theta=-90~90 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(rxHemiGain), mean(rxHemiGain), max(rxHemiGain));
    fprintf(fid, 'Rx 覆盖角域 Gain > -1 dBi 占比 = %.2f %%\n', pctAboveNeg1);
end

if ~isempty(theta0Gain)
    fprintf('Rx 天顶方向 Theta=0 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(theta0Gain), mean(theta0Gain), max(theta0Gain));

    fprintf(fid, 'Rx 天顶方向 Theta=0 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(theta0Gain), mean(theta0Gain), max(theta0Gain));
end

if ~isempty(horizonGain)
    fprintf('Rx 水平边缘 Theta=±90 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(horizonGain), mean(horizonGain), max(horizonGain));

    fprintf(fid, 'Rx 水平边缘 Theta=±90 Gain min/mean/max = %.3f / %.3f / %.3f dBi\n', ...
        min(horizonGain), mean(horizonGain), max(horizonGain));
end

fprintf(fid, '\n');

%% 8. 绘制一维切面图
% Tx：Theta=90 水平切面，能看到弹头/弹尾/侧面方向。
PlotPhiCut( ...
    AzTx, ElTx, GainTx, ...
    90, ...
    'Tx 弹载天线：Theta=90° 水平切面', ...
    fullfile(figDir, 'tx_phi_cut_theta90.png'));

% Tx：Phi=90 弹尾方向附近，观察 Theta 方向变化。
PlotThetaCut( ...
    AzTx, ElTx, GainTx, ...
    90, ...
    'Tx 弹载天线：Phi=90° 弹尾方向切面', ...
    fullfile(figDir, 'tx_theta_cut_phi90_tail.png'));

% Rx：Theta=0 天顶方向方位切面。
PlotPhiCut( ...
    AzRx, ElRx, GainRx, ...
    0, ...
    'Rx 地面天线：Theta=0° 天顶方向方位切面', ...
    fullfile(figDir, 'rx_phi_cut_theta0_top.png'));

% Rx：Phi=0 垂直切面。
PlotThetaCut( ...
    AzRx, ElRx, GainRx, ...
    0, ...
    'Rx 地面天线：Phi=0° 垂直切面，Theta=0°为天顶', ...
    fullfile(figDir, 'rx_theta_cut_phi0.png'));

%% 9. 结束
fclose(fid);

fprintf('\n方向图验证完成。\n');
fprintf('图像输出目录: %s\n', figDir);
fprintf('验证报告文件: %s\n', reportFile);

%% ========================================================================
%  本脚本局部函数
% =========================================================================

function PlotPatternContour(AzGrid, ElGrid, GainGrid, figTitle, xLabelText, yLabelText, savePath)

figure('Color', 'w');
contourf(AzGrid, ElGrid, GainGrid, 40, 'LineColor', 'none');
colorbar;
xlabel(xLabelText);
ylabel(yLabelText);
title(figTitle);
grid on;

saveas(gcf, savePath);

end

function PlotPhiCut(AzGrid, ElGrid, GainGrid, targetTheta, figTitle, savePath)

thetaVec = ElGrid(:, 1);
[~, idxTheta] = min(abs(thetaVec - targetTheta));

az = AzGrid(idxTheta, :);
gain = GainGrid(idxTheta, :);
actualTheta = thetaVec(idxTheta);

figure('Color', 'w');
plot(az, gain, 'LineWidth', 1.5);
grid on;
xlabel('Phi / Az [deg]');
ylabel('Gain [dBi]');
title(sprintf('%s，实际切面角 = %.2f°', figTitle, actualTheta));

saveas(gcf, savePath);

end

function PlotThetaCut(AzGrid, ElGrid, GainGrid, targetAz, figTitle, savePath)

azVec = AzGrid(1, :);
[~, idxAz] = min(abs(WrapTo180Local(azVec - targetAz)));

theta = ElGrid(:, idxAz);
gain = GainGrid(:, idxAz);
actualAz = azVec(idxAz);

figure('Color', 'w');
plot(theta, gain, 'LineWidth', 1.5);
grid on;
xlabel('Theta [deg]');
ylabel('Gain [dBi]');
title(sprintf('%s，实际切面角 = %.2f°', figTitle, actualAz));

saveas(gcf, savePath);

end

function PlotLocalContour(AzGrid, ElGrid, GainGrid, azMin, azMax, thetaMin, thetaMax, figTitle, savePath)

mask = AzGrid >= azMin & AzGrid <= azMax & ...
       ElGrid >= thetaMin & ElGrid <= thetaMax;

azVals = AzGrid(mask);
thetaVals = ElGrid(mask);
gainVals = GainGrid(mask);

if isempty(gainVals)
    warning('局部区域无数据，无法绘制：%s', figTitle);
    return;
end

azVec = unique(azVals);
thetaVec = unique(thetaVals);

[AZ, THETA] = meshgrid(azVec, thetaVec);
G = nan(size(AZ));

for i = 1:numel(azVals)
    [~, iaz] = min(abs(azVec - azVals(i)));
    [~, itheta] = min(abs(thetaVec - thetaVals(i)));
    G(itheta, iaz) = gainVals(i);
end

figure('Color', 'w');
contourf(AZ, THETA, G, 30, 'LineColor', 'none');
colorbar;
xlabel('Phi [deg]');
ylabel('Theta [deg]');
title(figTitle);
grid on;
hold on;
plot(90, 90, 'rx', 'LineWidth', 2, 'MarkerSize', 10);
text(90, 90, '  弹尾中心', 'Color', 'r', 'FontWeight', 'bold');

saveas(gcf, savePath);

end

function G = QueryGain(AzGrid, ElGrid, GainGrid, az, theta)

az = mod(az, 360);

G = interp2(AzGrid, ElGrid, GainGrid, az, theta, 'linear', NaN);

if isnan(G)
    G = interp2(AzGrid, ElGrid, GainGrid, az, theta, 'nearest', NaN);
end

end

function y = WrapTo180Local(x)

y = mod(x + 180, 360) - 180;

end
