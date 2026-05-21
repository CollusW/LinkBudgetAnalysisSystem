% /*!
% * @brief This script is used to read antenna simulation results from CSV
% *        and plot 2D/3D antenna realized gain patterns, with ROI analysis.
% * @details Reads phi/theta/gain data, interpolates onto a regular grid,
% *          then produces four figures:
% *            Fig.100 - 2D pseudo-color heat map
% *            Fig.200 - 2D filled contour map with ROI overlay and extrema markers
% *            Fig.300 - 3D directional gain pattern (spherical coordinates)
% *            Fig.400 - 3D antenna pattern via patternCustom (Antenna Toolbox)
% *          A local function analyzeRoiGain() performs statistical analysis
% *          on a user-specified (phi, theta) region and annotates Fig.200.
% * @pre CSV file must exist in the working directory with columns:
% *      Phi[deg], Theta[deg], dB(RealizedGainTotal)
% * @bug Null
% * @warning Null
% * @author Collus & Claude
% * @version 1.6
% * @date 2026.05.20
% * @copyright Collus Wang all rights reserved.
% * @remark { revision history:
% *   2026.05.20. V1.0, Collus & Claude, first draft.
% *   2026.05.20. V1.1, Collus & Claude, add 3D directional gain pattern.
% *   2026.05.20. V1.2, Collus & Claude, use real dBi linear radius (no normalization).
% *   2026.05.20. V1.3, Collus & Claude, switch 3D plot to phi-theta-gain coordinate system.
% *   2026.05.20. V1.4, Collus & Claude, restore true 3D spherical polar pattern with real linear radius.
% *   2026.05.20. V1.5, Collus & Claude, add Fig.400 using patternCustom (Antenna Toolbox).
% *   2026.05.20. V1.6, Collus & Claude, add ROI gain analysis with annotation on Fig.200.
% * }
% */

clear variables
close all

%% ---- 0. 控制开关 & ROI 参数设置 -----------------------------------------
flagDebugPlot = true;   % true: 显示所有图; false: 仅保存，不弹窗

% 感兴趣区域 (ROI) 角度范围，按需修改
roiPhiMin   =  90-15;    % phi 下限 (deg)
roiPhiMax   =  90+15;    % phi 上限 (deg)
roiThetaMin =  90-15;    % theta 下限 (deg)
roiThetaMax =  90+15;    % theta 上限 (deg)

%% ---- 1. 读取数据 ---------------------------------------------------------
fileName = '314B_Air_RealizedGainPlot.csv';

data  = readmatrix(fileName);
phi   = data(:, 1);   % 方位角 (deg)，列向量
theta = data(:, 2);   % 俯仰角 (deg)，列向量
gain  = data(:, 3);   % 实现增益 (dBi)，列向量

%% ---- 2. 构建规则网格 -----------------------------------------------------
phiUnique   = unique(phi);    % 列向量
thetaUnique = unique(theta);  % 列向量

[phiGrid, thetaGrid] = meshgrid(phiUnique, thetaUnique);   % 行=theta, 列=phi
gainGrid = griddata(phi, theta, gain, phiGrid, thetaGrid, 'linear');

%% ---- 3. 二维伪彩色热力图 (Fig.100) ---------------------------------------
figure(100);
pcolor(phiGrid, thetaGrid, gainGrid);
shading interp;
colorbar;
colormap(jet);
xlabel('\phi 方位角 (deg)');
ylabel('\theta 俯仰角 (deg)');
title('天线方向增益二维分布图 (dBi)');

%% ---- 4. 二维等高线图 (Fig.200) -------------------------------------------
figure(200);
contourf(phiGrid, thetaGrid, gainGrid, 20);   % 20 条等高线
colorbar;
colormap(jet);
xlabel('\phi 方位角 (deg)');
ylabel('\theta 俯仰角 (deg)');
title('天线方向增益等高线图 (dBi)');

%% ---- 4b. ROI 增益分析，并在 Fig.200 上标注 --------------------------------
roiStats = analyzeRoiGain(gainGrid, phiUnique, thetaUnique, ...
    roiPhiMin, roiPhiMax, ...
    roiThetaMin, roiThetaMax, ...
    200);

%% ---- 5. 三维极坐标方向图 (Fig.300) ----------------------------------------
% 原理：在每个方向 (phi, theta) 上，以真实线性幅度作为径向距离，
%       将球坐标转换为直角坐标后绘制曲面，颜色标注真实 dBi 值。
%   r = 10^(gain_dBi / 20)       线性幅度，保留绝对量纲，不归一化
%   x = r * sin(theta) * cos(phi)
%   y = r * sin(theta) * sin(phi)
%   z = r * cos(theta)
%
% 注意：当增益为负 dBi 时，r 仍为正小数（如 -2 dBi -> r ≈ 0.794），
%       曲面形状正确反映方向性，颜色读数为真实 dBi。

% 5.1 计算径向距离（真实线性幅度）
gainLinear = 10 .^ (gainGrid ./ 20);

% 5.2 球坐标 -> 直角坐标
phiRad   = deg2rad(phiGrid);
thetaRad = deg2rad(thetaGrid);

xCoord = gainLinear .* sin(thetaRad) .* cos(phiRad);
yCoord = gainLinear .* sin(thetaRad) .* sin(phiRad);
zCoord = gainLinear .* cos(thetaRad);

% 5.3 绘图
figure(300);
surf(xCoord, yCoord, zCoord, gainGrid);   % 形状=线性幅度方向图，颜色=真实 dBi
shading interp;
hCb = colorbar;
hCb.Label.String = '增益 (dBi)';
colormap(jet);
axis equal;
grid on;
xlabel('X  [\phi=0°, \theta=90°]');
ylabel('Y  [\phi=90°, \theta=90°]');
zlabel('Z  [\theta=0°]');
title('天线三维极坐标方向图 (形状: 真实线性幅度, 颜色: 真实 dBi)');
view(45, 30);   % 默认视角：方位角 45°，仰角 30°

%% ---- 6. patternCustom 方向图 (Fig.400) ------------------------------------
% patternCustom 属于 Antenna Toolbox，接口与 HFSS/CST 导出格式高度一致。
% 函数签名：
%   patternCustom(magE, theta_vec, phi_vec)
%     magE      : 增益矩阵，尺寸 nPhi x nTheta（行=phi，列=theta），单位 dBi
%     theta_vec : theta 向量 (deg)，行向量
%     phi_vec   : phi 向量 (deg)，行向量
%
% gainGrid 由 meshgrid(phiUnique, thetaUnique) 生成，排布为 nTheta x nPhi，
% 与 patternCustom 要求（行=phi，列=theta）相反，故传入前需转置。

figure(400);
patternCustom(gainGrid.', thetaUnique.', phiUnique.');
title('天线三维方向图 - patternCustom (dBi)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ---- 本地函数区 ----------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function roiStats = analyzeRoiGain(gainGrid, phiUnique, thetaUnique, ...
    phiMin, phiMax, thetaMin, thetaMax, ...
    figId)
% /*!
% * @brief  对指定 (phi, theta) 区域内的天线增益进行统计分析，
%           并在指定图窗上标注 ROI 边框和极值点。
% * @param  gainGrid    [nTheta x nPhi] 增益网格矩阵 (dBi)
% * @param  phiUnique   phi 轴唯一值列向量 (deg)
% * @param  thetaUnique theta 轴唯一值列向量 (deg)
% * @param  phiMin      ROI phi 下限 (deg)
% * @param  phiMax      ROI phi 上限 (deg)
% * @param  thetaMin    ROI theta 下限 (deg)
% * @param  thetaMax    ROI theta 上限 (deg)
% * @param  figId       要标注的图窗编号（通常为 Fig.200）
% * @return roiStats    struct，包含以下字段：
% *           .gainMax      ROI 内最大增益 (dBi)
% *           .gainMin      ROI 内最小增益 (dBi)
% *           .gainMean     ROI 内平均增益 (dBi)
% *           .gainMedian   ROI 内中位增益 (dBi)
% *           .gainStd      ROI 内增益标准差 (dB)
% *           .gainRange    ROI 内增益峰峰差 (dB)
% *           .phiAtMax     最大增益对应 phi (deg)
% *           .thetaAtMax   最大增益对应 theta (deg)
% *           .phiAtMin     最小增益对应 phi (deg)
% *           .thetaAtMin   最小增益对应 theta (deg)
% *           .nPoints      ROI 内有效采样点数
% * @bug    Null
% * @warning Null
% */

%% -- (a) 提取 ROI 索引 ------------------------------------------------
idxPhi   = (phiUnique   >= phiMin)   & (phiUnique   <= phiMax);
idxTheta = (thetaUnique >= thetaMin) & (thetaUnique <= thetaMax);

% gainGrid 行=theta, 列=phi
gainRoi = gainGrid(idxTheta, idxPhi);

% 剔除插值产生的 NaN
validMask = ~isnan(gainRoi);
gainValid = gainRoi(validMask);

if isempty(gainValid)
    warning('analyzeRoiGain: ROI 内无有效数据，请检查角度范围。');
    roiStats = struct();
    return;
end

%% -- (b) 计算统计量 ---------------------------------------------------
roiStats.gainMax    = max(gainValid);
roiStats.gainMin    = min(gainValid);
roiStats.gainMean   = mean(gainValid);
roiStats.gainMedian = median(gainValid);
roiStats.gainStd    = std(gainValid);
roiStats.gainRange  = roiStats.gainMax - roiStats.gainMin;
roiStats.nPoints    = numel(gainValid);

% 定位极值点在 ROI 子矩阵中的坐标
[~, idxMaxLinear] = max(gainRoi(:));
[~, idxMinLinear] = min(gainRoi(:));
[rowMax, colMax]  = ind2sub(size(gainRoi), idxMaxLinear);
[rowMin, colMin]  = ind2sub(size(gainRoi), idxMinLinear);

% 映射回全局角度值
phiRoiVec   = phiUnique(idxPhi);
thetaRoiVec = thetaUnique(idxTheta);

roiStats.phiAtMax   = phiRoiVec(colMax);
roiStats.thetaAtMax = thetaRoiVec(rowMax);
roiStats.phiAtMin   = phiRoiVec(colMin);
roiStats.thetaAtMin = thetaRoiVec(rowMin);

%% -- (c) 打印统计报告 -------------------------------------------------
fprintf('\n========== ROI 增益分析报告 ==========\n');
fprintf('  ROI 范围 : phi [%.1f°, %.1f°]  theta [%.1f°, %.1f°]\n', ...
    phiMin, phiMax, thetaMin, thetaMax);
fprintf('  有效点数 : %d\n',             roiStats.nPoints);
fprintf('  最大增益 : %+.3f dBi  @ phi=%.1f°, theta=%.1f°\n', ...
    roiStats.gainMax, roiStats.phiAtMax, roiStats.thetaAtMax);
fprintf('  最小增益 : %+.3f dBi  @ phi=%.1f°, theta=%.1f°\n', ...
    roiStats.gainMin, roiStats.phiAtMin, roiStats.thetaAtMin);
fprintf('  平均增益 : %+.3f dBi\n',      roiStats.gainMean);
fprintf('  中位增益 : %+.3f dBi\n',      roiStats.gainMedian);
fprintf('  标准差   : %.3f dB\n',         roiStats.gainStd);
fprintf('  峰峰差   : %.3f dB\n',         roiStats.gainRange);
fprintf('=======================================\n\n');

%% -- (d) 在 Fig.200 上标注 ROI 边框与极值点 ---------------------------
figure(figId);
hold on;

% ROI 矩形边框（白色虚线）
roiX = [phiMin,  phiMax,  phiMax,  phiMin,  phiMin];
roiY = [thetaMin, thetaMin, thetaMax, thetaMax, thetaMin];
plot(roiX, roiY, 'w--', 'LineWidth', 2.0, 'DisplayName', 'ROI 边界');

% 最大值标记（白色上三角）
plot(roiStats.phiAtMax, roiStats.thetaAtMax, ...
    '^w', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Max: %.2f dBi', roiStats.gainMax));
text(roiStats.phiAtMax, roiStats.thetaAtMax, ...
    sprintf('  Max\n  %.2f dBi\n  (\\phi=%.0f°, \\theta=%.0f°)', ...
    roiStats.gainMax, roiStats.phiAtMax, roiStats.thetaAtMax), ...
    'Color', 'w', 'FontSize', 8, 'FontWeight', 'bold', ...
    'VerticalAlignment', 'bottom');

% 最小值标记（黄色下三角）
plot(roiStats.phiAtMin, roiStats.thetaAtMin, ...
    'vy', 'MarkerSize', 10, 'MarkerFaceColor', 'y', 'LineWidth', 1.5, ...
    'DisplayName', sprintf('Min: %.2f dBi', roiStats.gainMin));
text(roiStats.phiAtMin, roiStats.thetaAtMin, ...
    sprintf('  Min\n  %.2f dBi\n  (\\phi=%.0f°, \\theta=%.0f°)', ...
    roiStats.gainMin, roiStats.phiAtMin, roiStats.thetaAtMin), ...
    'Color', 'y', 'FontSize', 8, 'FontWeight', 'bold', ...
    'VerticalAlignment', 'top');

legend('Location', 'best', 'TextColor', 'w', 'Color', [0.2 0.2 0.2]);
hold off;
end