function [TxNode, RxNode, AntTx, AntRx, InputDiag] = linkLoadOneScenario(SimCfg, GeoCfg, AntCfg)
%LINKLOADONESCENARIO 加载一个链路仿真场景
%
% 功能：
%   1. 加载 Tx/Rx 轨迹
%   2. 加载 Tx/Rx 天线模型
%
% 支持：
%   SimCfg.inputMode = synthetic / csv
%
% 注意：
%   CSV 轨迹不允许包含 d/distance/range 这类距离字段。
%   距离必须由 Tx/Rx 坐标计算得到。

%% 1. 加载轨迹
switch lower(SimCfg.inputMode)

    case 'synthetic'
        if exist('createLocalScenario', 'file') ~= 2
            error('找不到 createLocalScenario.m，无法生成 synthetic 场景。');
        end

        [TxNode, RxNode] = createLocalScenario(SimCfg.scenarioName);

    case 'csv'
        if exist('loadTrackCsv', 'file') ~= 2
            error('找不到 loadTrackCsv.m，无法读取 CSV 轨迹。');
        end

        TxNode = loadTrackCsv(SimCfg.txTrackFile, 'Tx', GeoCfg);
        RxNode = loadTrackCsv(SimCfg.rxTrackFile, 'Rx', GeoCfg);

    otherwise
        error('未知输入模式 SimCfg.inputMode = %s', SimCfg.inputMode);
end

%% 2. 加载天线模型
AntTx = loadOneAntennaModel(AntCfg.tx, AntCfg, 'Tx');
AntRx = loadOneAntennaModel(AntCfg.rx, AntCfg, 'Rx');

%% 3. 输入诊断
InputDiag = struct();

InputDiag.message = '场景输入加载完成。';
InputDiag.inputMode = SimCfg.inputMode;

InputDiag.txAntennaType = AntTx.type;
InputDiag.rxAntennaType = AntRx.type;

InputDiag.txPatternSource = getFieldOrDefault(AntCfg.tx, 'patternSource', 'none');
InputDiag.rxPatternSource = getFieldOrDefault(AntCfg.rx, 'patternSource', 'none');

InputDiag.txPatternFile = getFieldOrDefault(AntCfg.tx, 'patternFile', '');
InputDiag.rxPatternFile = getFieldOrDefault(AntCfg.rx, 'patternFile', '');

InputDiag.nTxSamples = getNodeSampleCount(TxNode);
InputDiag.nRxSamples = getNodeSampleCount(RxNode);

fprintf('\n========== linkLoadOneScenario ==========\n');
fprintf('输入模式: %s\n', InputDiag.inputMode);
fprintf('Tx 样本数: %d\n', InputDiag.nTxSamples);
fprintf('Rx 样本数: %d\n', InputDiag.nRxSamples);
fprintf('Tx 天线: %s\n', AntTx.type);
fprintf('Rx 天线: %s\n', AntRx.type);

if strcmpi(AntTx.type, 'pattern')
    fprintf('Tx 方向图: %s\n', AntTx.patternFile);
    fprintf('Tx Gain 范围: %.3f ~ %.3f dBi\n', ...
        min(AntTx.Gain_grid(:)), max(AntTx.Gain_grid(:)));
end

if strcmpi(AntRx.type, 'pattern')
    fprintf('Rx 方向图: %s\n', AntRx.patternFile);
    fprintf('Rx Gain 范围: %.3f ~ %.3f dBi\n', ...
        min(AntRx.Gain_grid(:)), max(AntRx.Gain_grid(:)));
end

fprintf('=========================================\n\n');

end

%% ========================================================================
% 子函数：加载单个天线模型
% =========================================================================
function Ant = loadOneAntennaModel(AntSubCfg, AntCfg, antName)

Ant = struct();

switch lower(AntSubCfg.type)

    case 'omni'
        Ant.type = 'omni';
        Ant.name = antName;
        Ant.omni_gain_dbi = AntSubCfg.omni_gain_dbi;

    case 'pattern'
        Ant.type = 'pattern';
        Ant.name = antName;

        patternSource = getFieldOrDefault(AntSubCfg, 'patternSource', 'synthetic');

        switch lower(patternSource)

            case 'csv'
                if exist('loadAntennaPatternCsv', 'file') ~= 2
                    error('找不到 loadAntennaPatternCsv.m。');
                end

                [Az_grid, El_grid, Gain_grid] = loadAntennaPatternCsv( ...
                    AntSubCfg.patternFile, ...
                    AntCfg.angleInputType);

                Ant.Az_grid = Az_grid;
                Ant.El_grid = El_grid;
                Ant.Gain_grid = Gain_grid;

                Ant.patternFile = AntSubCfg.patternFile;
                Ant.patternSource = 'csv';

            case 'synthetic'
                if exist('createSyntheticAntennaPattern', 'file') ~= 2
                    error('找不到 createSyntheticAntennaPattern.m，无法生成 synthetic 方向图。');
                end

                [Az_grid, El_grid, Gain_grid] = createSyntheticAntennaPattern();

                Ant.Az_grid = Az_grid;
                Ant.El_grid = El_grid;
                Ant.Gain_grid = Gain_grid;

                Ant.patternFile = '';
                Ant.patternSource = 'synthetic';

            otherwise
                error('未知方向图来源 patternSource = %s', patternSource);
        end

        Ant.interpolation = AntCfg.interpolation;
        Ant.outOfBound = AntCfg.outOfBound;

        if isfield(AntSubCfg, 'angleMap')
            Ant.angleMap = AntSubCfg.angleMap;
        else
            Ant.angleMap = struct();
            Ant.angleMap.phiOffsetDeg = 0;
            Ant.angleMap.thetaMode = 'identity';
        end

    otherwise
        error('未知天线类型：%s', AntSubCfg.type);
end

end

%% ========================================================================
% 子函数：获取节点样本数量
% =========================================================================
function n = getNodeSampleCount(Node)

if isfield(Node, 'track') && istable(Node.track)
    n = height(Node.track);
elseif isfield(Node, 't')
    n = numel(Node.t);
elseif isfield(Node, 'pos')
    n = size(Node.pos, 1);
else
    n = 0;
end

end

%% ========================================================================
% 子函数：安全读取字段
% =========================================================================
function val = getFieldOrDefault(s, name, defaultVal)

if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    val = s.(name);
else
    val = defaultVal;
end

end