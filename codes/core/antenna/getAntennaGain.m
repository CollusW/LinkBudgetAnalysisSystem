function G = getAntennaGain(Az, El, Az_grid, El_grid, Gain_grid, interpolation, outOfBound)
%GETANTENNAGAIN 根据 Az/El 查询方向图增益
%
% 输入：
%   Az, El        : 查询角度，单位 deg，可为标量或数组
%   Az_grid       : Az 网格
%   El_grid       : El 网格
%   Gain_grid     : 增益网格，单位 dBi
%   interpolation : nearest / linear / bilinear
%   outOfBound    : 越界处理，可为数值、'min'、'extrapolate'
%
% 输出：
%   G             : 查询得到的增益，单位 dBi

if nargin < 6 || isempty(interpolation)
    interpolation = 'linear';
end

if nargin < 7 || isempty(outOfBound)
    outOfBound = -100;
end

Az = double(Az);
El = double(El);

inputSize = size(Az);

Az = Az(:);
El = El(:);

if numel(El) == 1 && numel(Az) > 1
    El = repmat(El, size(Az));
end

if numel(Az) == 1 && numel(El) > 1
    Az = repmat(Az, size(El));
end

if numel(Az) ~= numel(El)
    error('Az 和 El 的元素数量必须一致。');
end

% Az 归一化到 0~360
Az = mod(Az, 360);

% 如果方向图有 360 边界，允许 360；否则 360 归 0
azMin = min(Az_grid(:));
azMax = max(Az_grid(:));
elMin = min(El_grid(:));
elMax = max(El_grid(:));

if azMax < 360
    Az(abs(Az - 360) < 1e-9) = 0;
end

method = lower(string(interpolation));

switch method
    case "nearest"
        interpMethod = 'nearest';

    case "linear"
        interpMethod = 'linear';

    case "bilinear"
        interpMethod = 'linear';

    otherwise
        interpMethod = 'linear';
end

G = nan(size(Az));

% 判断越界
idxIn = Az >= azMin & Az <= azMax & El >= elMin & El <= elMax;

% 正常范围内插值
if any(idxIn)
    G(idxIn) = interp2( ...
        Az_grid, ...
        El_grid, ...
        Gain_grid, ...
        Az(idxIn), ...
        El(idxIn), ...
        interpMethod);
end

% 处理 interp2 得到 NaN 的点
idxNanInside = idxIn & isnan(G);

if any(idxNanInside)
    G(idxNanInside) = interp2( ...
        Az_grid, ...
        El_grid, ...
        Gain_grid, ...
        Az(idxNanInside), ...
        El(idxNanInside), ...
        'nearest');
end

% 越界点处理
idxOut = ~idxIn | isnan(G);

if any(idxOut)
    G(idxOut) = handleOutOfBound( ...
        Az(idxOut), ...
        El(idxOut), ...
        Az_grid, ...
        El_grid, ...
        Gain_grid, ...
        interpMethod, ...
        outOfBound);
end

% 最终兜底
idxNan = isnan(G);

if any(idxNan)
    G(idxNan) = min(Gain_grid(:));
end

G = reshape(G, inputSize);

end

function Gout = handleOutOfBound(Az, El, Az_grid, El_grid, Gain_grid, interpMethod, outOfBound)

if isnumeric(outOfBound)
    Gout = outOfBound * ones(size(Az));
    return;
end

if ischar(outOfBound) || isstring(outOfBound)
    switch lower(string(outOfBound))

        case "min"
            Gout = min(Gain_grid(:)) * ones(size(Az));

        case "extrapolate"
            Gout = interp2( ...
                Az_grid, ...
                El_grid, ...
                Gain_grid, ...
                Az, ...
                El, ...
                interpMethod, ...
                NaN);

            idxNan = isnan(Gout);

            if any(idxNan)
                Gout(idxNan) = interp2( ...
                    Az_grid, ...
                    El_grid, ...
                    Gain_grid, ...
                    Az(idxNan), ...
                    El(idxNan), ...
                    'nearest', ...
                    NaN);
            end

            idxNan = isnan(Gout);

            if any(idxNan)
                Gout(idxNan) = min(Gain_grid(:));
            end

        otherwise
            Gout = -100 * ones(size(Az));
    end
else
    Gout = -100 * ones(size(Az));
end

end