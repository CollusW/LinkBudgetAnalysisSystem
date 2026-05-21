function [Az_grid, El_grid, Gain_grid] = loadAntennaPatternCsv(filePath, angleInputType, targetFreqGHz)
%LOADANTENNAPATTERNCsv 读取天线方向图 CSV
%
% 功能：
%   读取真实天线方向图 CSV，并转换为 Az/El/Gain 网格。
%
% 支持的 CSV 表头形式：
%
%   形式 1：
%       Az, El, Gain
%       Az [deg], El [deg], Gain [dBi]
%
%   形式 2：弹载天线格式
%       Phi [deg], Theta [deg], dB(RealizedGainTotal)
%
%   形式 3：地面天线格式
%       Freq [GHz], Phi [deg], Theta [deg], dB(RealizedGainLHCP) []
%
% 输入：
%   filePath       : CSV 文件路径
%   angleInputType : 角度输入类型
%                    'AzEl'      : 直接认为 Phi/Az 是方位角，Theta/El 是俯仰角
%                    'PhiTheta'  : 按 Phi/Theta 方向图读取
%                    'thetaPhi'  : 使用 mapPatternAngle(theta, phi, angleInputType)
%   targetFreqGHz  : 目标频率，单位 GHz。默认 4.95GHz。
%
% 输出：
%   Az_grid   : Az 网格，单位 deg
%   El_grid   : El 网格，单位 deg
%   Gain_grid : 增益网格，单位 dBi
%
% 说明：
%   1. 当前工程按老师表格频率 4.95GHz 计算。
%   2. 如果 CSV 中存在 Freq [GHz] 列，则自动选择最接近 targetFreqGHz 的频点。
%   3. 如果 CSV 中没有 Freq [GHz] 列，则默认整张表就是单一频点方向图，直接读取。

%% 0. 输入默认值
if nargin < 2 || isempty(angleInputType)
    angleInputType = 'PhiTheta';
end

% 关键修改：
% 当前工程严格按老师表格频率 4.95GHz 计算。
% 所以读取带 Freq 列的方向图时，默认目标频率是 4.95GHz。
if nargin < 3 || isempty(targetFreqGHz)
    targetFreqGHz = 4.95;
end

if ~exist(filePath, 'file')
    error('方向图文件不存在：%s', filePath);
end

%% 1. 读取 CSV，保留原始表头
% 使用 VariableNamingRule='preserve'，避免 MATLAB 自动改列名。
% 例如：
%   Phi [deg]
%   Theta [deg]
%   dB(RealizedGainLHCP) []
% 这些列名会被原样保留。
T = readtable(filePath, 'VariableNamingRule', 'preserve');

if isempty(T)
    error('方向图 CSV 为空：%s', filePath);
end

varNames = T.Properties.VariableNames;
normNames = normalizeVarNames(varNames);

%% 2. 查找列：Az/Phi、El/Theta、Gain、Freq
azCol = findFirstMatch(normNames, { ...
    'az', ...
    'azdeg', ...
    'azimuth', ...
    'azimuthdeg'});

elCol = findFirstMatch(normNames, { ...
    'el', ...
    'eldeg', ...
    'elevation', ...
    'elevationdeg'});

phiCol = findFirstMatch(normNames, { ...
    'phi', ...
    'phideg'});

thetaCol = findFirstMatch(normNames, { ...
    'theta', ...
    'thetadeg'});

gainCol = findGainColumn(normNames);

freqCol = findFirstMatch(normNames, { ...
    'freq', ...
    'freqghz', ...
    'frequency', ...
    'frequencyghz'});

if isempty(gainCol)
    disp(varNames');
    error('方向图 CSV 必须包含增益列，例如 Gain、Gain_dBi、dB(RealizedGainTotal)、dB(RealizedGainLHCP)。');
end

%% 3. 如果存在频率列，自动选择最接近 targetFreqGHz 的频点
% 例如：
%   targetFreqGHz = 4.95
%   CSV 中有 Freq [GHz] = 4.95
% 则会选择 4.95GHz。
%
% 如果 CSV 中没有 Freq 列，例如 Tx 弹载天线方向图，
% 则跳过这一步，默认整张 CSV 是单频点方向图。
if ~isempty(freqCol)
    freqGHzAll = T{:, freqCol};

    if ~isnumeric(freqGHzAll)
        freqGHzAll = str2double(string(freqGHzAll));
    end

    validFreq = isfinite(freqGHzAll);

    if any(validFreq)
        uniqueFreq = unique(freqGHzAll(validFreq));
        [~, idxNearest] = min(abs(uniqueFreq - targetFreqGHz));
        chosenFreqGHz = uniqueFreq(idxNearest);

        idxFreq = abs(freqGHzAll - chosenFreqGHz) < 1e-9;
        T = T(idxFreq, :);

        fprintf('方向图包含频率列，目标 %.3f GHz，实际选用 %.3f GHz：%s\n', ...
            targetFreqGHz, chosenFreqGHz, filePath);
    else
        warning('方向图存在频率列，但频率数据无有效数值：%s', filePath);
    end
else
    fprintf('方向图不包含频率列，默认整张表为单一频点方向图：%s\n', filePath);
end

%% 4. 提取角度
hasAzEl = ~isempty(azCol) && ~isempty(elCol);
hasPhiTheta = ~isempty(phiCol) && ~isempty(thetaCol);

if hasAzEl
    Az = T{:, azCol};
    El = T{:, elCol};

elseif hasPhiTheta
    phi = T{:, phiCol};
    theta = T{:, thetaCol};

    [Az, El] = convertPhiThetaToAzEl(phi, theta, angleInputType);

else
    disp(varNames');
    error('方向图 CSV 必须包含 Az/El 或 Phi/Theta 字段。');
end

%% 5. 提取增益
Gain = T{:, gainCol};

%% 6. 转成数值列向量
Az = toNumericColumn(Az);
El = toNumericColumn(El);
Gain = toNumericColumn(Gain);

%% 7. 清理非法数据
valid = isfinite(Az) & isfinite(El) & isfinite(Gain);

Az = Az(valid);
El = El(valid);
Gain = Gain(valid);

if isempty(Az)
    error('方向图有效数据为空：%s', filePath);
end

%% 8. 角度归一化
% Az 统一到 0~360。
Az = mod(Az, 360);

% 如果有 360°，统一成 0°，避免重复边界造成网格问题。
Az(abs(Az - 360) < 1e-9) = 0;

%% 9. 构造规则网格
azVec = unique(Az(:));
elVec = unique(El(:));

azVec = sort(azVec);
elVec = sort(elVec);

[Az_grid, El_grid] = meshgrid(azVec, elVec);
Gain_grid = nan(size(Az_grid));

%% 10. 填充网格
% CSV 通常是一行一个角度点，这里把散点形式的 Gain 放入二维网格。
for i = 1:numel(Az)
    [~, iaz] = min(abs(azVec - Az(i)));
    [~, iel] = min(abs(elVec - El(i)));

    Gain_grid(iel, iaz) = Gain(i);
end

%% 11. 如果 CSV 不是完整网格，用 linear griddata 补齐
if any(isnan(Gain_grid(:)))
    G2 = griddata(Az(:), El(:), Gain(:), Az_grid, El_grid, 'linear');

    idx = isnan(Gain_grid) & ~isnan(G2);
    Gain_grid(idx) = G2(idx);
end

%% 12. 仍缺失的点，用 nearest 补齐
if any(isnan(Gain_grid(:)))
    G3 = griddata(Az(:), El(:), Gain(:), Az_grid, El_grid, 'nearest');

    idx = isnan(Gain_grid) & ~isnan(G3);
    Gain_grid(idx) = G3(idx);
end

%% 13. 如果还有 NaN，用最小增益填充
if any(isnan(Gain_grid(:)))
    minGain = min(Gain(:));
    Gain_grid(isnan(Gain_grid)) = minGain;
end

%% 14. 增加 Az=360 边界，避免 interp2 在 360 附近越界
% 如果原始网格没有 360°，则复制 Az=0° 的增益到 360°。
if ~isempty(azVec) && max(azVec) < 360
    Az_grid = [Az_grid, 360 * ones(size(Az_grid, 1), 1)];
    El_grid = [El_grid, El_grid(:, 1)];
    Gain_grid = [Gain_grid, Gain_grid(:, 1)];
end

%% 15. 控制台输出
fprintf('\n已加载方向图：%s\n', filePath);
fprintf('  数据点数量：%d\n', numel(Gain));
fprintf('  Az 范围：%.3f ~ %.3f deg\n', min(Az_grid(:)), max(Az_grid(:)));
fprintf('  El 范围：%.3f ~ %.3f deg\n', min(El_grid(:)), max(El_grid(:)));
fprintf('  Gain 范围：%.3f ~ %.3f dBi\n', min(Gain_grid(:)), max(Gain_grid(:)));

end

%% ========================================================================
%  子函数：表头归一化
% =========================================================================
function normNames = normalizeVarNames(varNames)

normNames = strings(size(varNames));

for i = 1:numel(varNames)
    s = string(varNames{i});
    s = lower(s);

    % 去掉常见符号，方便匹配列名。
    s = erase(s, " ");
    s = erase(s, "_");
    s = erase(s, "-");
    s = erase(s, "[");
    s = erase(s, "]");
    s = erase(s, "(");
    s = erase(s, ")");
    s = erase(s, "{");
    s = erase(s, "}");
    s = erase(s, "/");
    s = erase(s, "\");
    s = erase(s, ".");
    s = erase(s, "°");

    normNames(i) = s;
end

end

%% ========================================================================
%  子函数：查找字段
% =========================================================================
function idx = findFirstMatch(normNames, candidates)

idx = [];

% 第一轮：完全匹配
for i = 1:numel(normNames)
    name = normNames(i);

    for k = 1:numel(candidates)
        cand = lower(string(candidates{k}));

        if name == cand
            idx = i;
            return;
        end
    end
end

% 第二轮：包含匹配
for i = 1:numel(normNames)
    name = normNames(i);

    for k = 1:numel(candidates)
        cand = lower(string(candidates{k}));

        if contains(name, cand)
            idx = i;
            return;
        end
    end
end

end

%% ========================================================================
%  子函数：查找增益列
% =========================================================================
function idx = findGainColumn(normNames)

idx = [];

% 优先级 1：RealizedGain
% 可识别：
%   dB(RealizedGainTotal)
%   dB(RealizedGainLHCP) []
for i = 1:numel(normNames)
    name = normNames(i);

    if contains(name, "realizedgain")
        idx = i;
        return;
    end
end

% 优先级 2：gain_dbi / gain
for i = 1:numel(normNames)
    name = normNames(i);

    if contains(name, "gaindbi") || name == "gain" || contains(name, "gain")
        idx = i;
        return;
    end
end

% 优先级 3：dB 开头的列
for i = 1:numel(normNames)
    name = normNames(i);

    if startsWith(name, "db")
        idx = i;
        return;
    end
end

end

%% ========================================================================
%  子函数：Phi/Theta 转 Az/El
% =========================================================================
function [Az, El] = convertPhiThetaToAzEl(phi, theta, angleInputType)

phi = toNumericColumn(phi);
theta = toNumericColumn(theta);

switch lower(string(angleInputType))

    case {"azel", "phitheta", "phi_theta"}
        % 老师给的方向图字段：
        %   Phi   = 方位角
        %   Theta = 第二角度
        %
        % 这里先直接转成内部 Az/El 网格：
        %   Az = Phi
        %   El = Theta
        %
        % 注意：
        %   弹载天线“phi270 theta90 是头、phi90 theta90 是弹尾”
        %   不在这里处理。
        %   那个是在 linkCalcAntennaGainSeries 中通过 angleMap 处理。
        Az = phi;
        El = theta;

    case {"thetaphii", "thetaphi", "theta_phi"}
        % 如果你的项目中已有 mapPatternAngle，则优先调用它。
        if exist('mapPatternAngle', 'file') == 2
            [Az, El] = mapPatternAngle(theta, phi, char(angleInputType));
        else
            Az = phi;
            El = theta;
        end

    case {"polar", "theta0zenith", "zenith0"}
        % 常见球坐标：
        %   theta = 0   表示天顶
        %   theta = 90  表示水平面
        %   theta = 180 表示地底
        %
        % 转成 El：
        %   El = 90 - theta
        Az = phi;
        El = 90 - theta;

    otherwise
        warning('未知 angleInputType=%s，默认按 Phi->Az, Theta->El 处理。', string(angleInputType));
        Az = phi;
        El = theta;
end

Az = mod(Az, 360);

end

%% ========================================================================
%  子函数：转数值列向量
% =========================================================================
function x = toNumericColumn(x)

if istable(x)
    x = table2array(x);
end

if iscell(x)
    x = string(x);
end

if isstring(x) || ischar(x) || iscategorical(x)
    x = str2double(string(x));
end

x = double(x);
x = x(:);

end