%% main_link_top.m
% 通信链路仿真与天线约束分析系统
%
% 核心原则：
% 1) 核心链路仿真只使用 local XYZ 坐标。
% 2) 距离 d 必须由 Tx/Rx 坐标计算得到，不允许作为输入直接赋值。
% 3) GPS/WGS84 仅作为 tools 中的可选预处理工具，不进入核心链路预算内核。
% 4) TOP 层不写核心逻辑，只负责调用各模块。
%
% 当前版本说明：
% 1) 按老师方向图表格中的频率 4.95GHz 进行链路预算。
% 2) 发射功率 Pt = 20 dBm。
% 3) Tx 使用弹载天线真实 CSV 方向图。
% 4) Rx 使用地面四臂螺旋天线真实 CSV 方向图。
% 5) 当前轨迹仍使用 synthetic 模拟轨迹。

clear; clc; close all;

%% 0. 工程路径
% rootDir 是当前 main_link_top.m 所在的工程根目录。
% 例如：
% D:\ly\desk\LinkSimulation_MATLAB_Pro\LinkSimulation_MATLAB_Pro
rootDir = fileparts(mfilename('fullpath'));

% 把工程里的各个代码文件夹加入 MATLAB 搜索路径。
% 这样后面才能直接调用 config、io、core、plot 等目录里的函数。
addpath(rootDir);
addpath(fullfile(rootDir, 'config'));
addpath(fullfile(rootDir, 'io'));
addpath(fullfile(rootDir, 'core'));
addpath(fullfile(rootDir, 'core', 'geometry'));
addpath(fullfile(rootDir, 'core', 'antenna'));
addpath(fullfile(rootDir, 'core', 'linkbudget'));
addpath(fullfile(rootDir, 'plot'));

fprintf('\n========== main_link_top ==========\n');
fprintf('工程目录: %s\n', rootDir);
fprintf('===================================\n\n');

%% 1. 用户可配置区
% simCfgIn 是用户手动输入的配置。
% 它会传给 linkInitConfig。
% linkInitConfig 会优先使用 simCfgIn 里的值；
% 如果 simCfgIn 没有提供某个字段，就使用默认值。
simCfgIn = struct();

%% 1.1 场景配置
% 当前使用你已经跑通的工程场景。
simCfgIn.scenarioName = 'tc06_realistic_local_xyz';

% synthetic 表示使用程序内置模拟轨迹。
% csv 表示读取 input/tx_track.csv 和 input/rx_track.csv。
simCfgIn.inputMode = 'synthetic';

% 是否画图。
simCfgIn.enablePlot = true;

% 是否保存图像。
simCfgIn.saveFigure = true;

%% 1.2 射频链路预算配置
% 重要修改：
% 现在你不是按 5GHz 算，而是按老师表格里的 4.95GHz 算。
%
% 也就是说：
% 路径损耗 Lfs 按 4.95GHz 算；
% 天线方向图也选择 4.95GHz 数据。
simCfgIn.f = 4.95e9;

% 老师要求的发射功率：20 dBm。
simCfgIn.Pt = 20;

% 接收灵敏度。
% 当前先用 -90 dBm。
% 如果老师或设备手册给了真实接收灵敏度，需要改这里。
simCfgIn.Sens = -90;

% 其他固定损耗。
% 例如线缆损耗、接头损耗、极化损耗、系统损耗等。
% 当前先设为 0 dB，表示暂不考虑额外损耗。
simCfgIn.L_other = 0;

% 目标链路余量。
% 这里表示希望接收功率比接收灵敏度至少高 3 dB。
simCfgIn.Margin_target = 3;

%% 1.3 天线类型配置
% pattern 表示使用真实方向图。
% omni 表示使用全向天线。
simCfgIn.txAntennaType = 'pattern';
simCfgIn.rxAntennaType = 'pattern';

% 方向图来源使用 CSV。
simCfgIn.txPatternSource = 'csv';
simCfgIn.rxPatternSource = 'csv';

% Tx 弹载天线方向图文件。
simCfgIn.txPatternFile = fullfile(rootDir, 'input', 'tx_antenna_pattern.csv');

% Rx 地面天线方向图文件。
simCfgIn.rxPatternFile = fullfile(rootDir, 'input', 'rx_antenna_pattern.csv');

% 老师给的方向图角度字段是 Phi / Theta。
simCfgIn.angleInputType = 'PhiTheta';

%% 1.4 Tx 弹载天线角度映射
% 老师说明：
%   phi270 theta90 是头
%   phi90  theta90 是弹尾
%
% 几何模块里通常认为：
%   Az = 0   是 body +X，也就是弹头方向
%   Az = 180 是 body -X，也就是弹尾方向
%
% 为了让：
%   Az=0   -> Phi=270
%   Az=180 -> Phi=90
%
% 使用：
%   Phi = mod(Az + 270, 360)
simCfgIn.txAngleMap.phiOffsetDeg = 270;

% Tx 方向图第二角度范围是 0~180。
% 老师说：
%   theta=0   是天顶
%   theta=90  是水平头/尾方向
%
% 几何模块的 El 通常是：
%   El=+90 是天顶
%   El=0   是水平
%
% 所以使用：
%   Theta = 90 - El
simCfgIn.txAngleMap.thetaMode = 'zenith0_horizon90';

%% 1.5 Rx 地面天线角度映射
% Rx 地面天线读取出来的第二角度范围是 -90~90。
% 这说明它已经是仰角形式。
% 所以 Rx 不需要做 90-El，直接使用 El。
simCfgIn.rxAngleMap.phiOffsetDeg = 0;
simCfgIn.rxAngleMap.thetaMode = 'identity';

%% 2. 参数初始化
% linkInitConfig 会根据 simCfgIn 生成完整配置结构体。
[SimCfg, GeoCfg, RfCfg, AntCfg, AlgoCfg, OutCfg, CfgDiag] = linkInitConfig(simCfgIn);

%% 3. 检查方向图文件是否存在
% 如果使用 pattern 方向图天线，必须保证 CSV 文件存在。
if strcmpi(AntCfg.tx.type, 'pattern')
    assert(exist(AntCfg.tx.patternFile, 'file') == 2, ...
        'Tx 方向图文件不存在: %s', AntCfg.tx.patternFile);
end

if strcmpi(AntCfg.rx.type, 'pattern')
    assert(exist(AntCfg.rx.patternFile, 'file') == 2, ...
        'Rx 方向图文件不存在: %s', AntCfg.rx.patternFile);
end

%% 4. 场景加载
% linkLoadOneScenario 负责：
% 1) 加载 Tx/Rx 轨迹；
% 2) 加载 Tx/Rx 天线方向图。
[TxNode, RxNode, AntTx, AntRx, InputDiag] = linkLoadOneScenario( ...
    SimCfg, ...
    GeoCfg, ...
    AntCfg);

%% 5. 链路仿真
% linkSimOneScenario 负责完整链路计算：
% 1) 轨迹预处理；
% 2) 计算 Tx->Rx、Rx->Tx 视线向量；
% 3) 计算 Tx/Rx 本体坐标系下 Az/El；
% 4) 查询 Tx/Rx 天线增益；
% 5) 计算 FSPL、Pr、Margin、G_total_required。
[LinkResult, SimDiag] = linkSimOneScenario( ...
    TxNode, ...
    RxNode, ...
    AntTx, ...
    AntRx, ...
    GeoCfg, ...
    RfCfg, ...
    AntCfg, ...
    AlgoCfg);

%% 6. 场景分析
% linkAnalyzeOneScenario 负责分析：
% 1) 最小接收功率；
% 2) 最小链路余量；
% 3) 最大路径损耗；
% 4) 最大所需总天线增益；
% 5) 失效比例或最差点等。
[AnalysisResult, AnalysisDiag] = linkAnalyzeOneScenario( ...
    LinkResult, ...
    RfCfg, ...
    AlgoCfg);

%% 7. 输出与绘图
% linkOutputOneScenario 负责保存：
% 1) CSV 结果；
% 2) MAT 结果；
% 3) 图片；
% 4) 控制台报告或文本报告。
[OutInfo, OutDiag] = linkOutputOneScenario( ...
    LinkResult, ...
    AnalysisResult, ...
    SimCfg, ...
    GeoCfg, ...
    RfCfg, ...
    AntCfg, ...
    OutCfg);

%% 8. 控制台总结
fprintf('\n==== 链路仿真完成：%s ====\n', SimCfg.scenarioName);
fprintf('坐标模式: %s | 距离来源: Tx/Rx 坐标计算\n', GeoCfg.coordinateMode);
fprintf('频率: %.3f GHz | 发射功率: %.2f dBm\n', RfCfg.f / 1e9, RfCfg.Pt);
fprintf('Tx 天线: %s | Rx 天线: %s\n', AntTx.type, AntRx.type);

if isfield(AnalysisResult, 'Summary')
    fprintf('最小接收功率 Pr_min      : %.2f dBm\n', AnalysisResult.Summary.minPr);
    fprintf('最小链路余量 Margin_min  : %.2f dB\n', AnalysisResult.Summary.minMargin);
    fprintf('最大总增益需求 Gt+Gr     : %.2f dBi\n', AnalysisResult.Summary.maxGtotalRequired);

    if isfield(AnalysisResult.Summary, 'maxDistance')
        fprintf('最大距离 d_max           : %.2f km\n', AnalysisResult.Summary.maxDistance / 1000);
    end
end

fprintf('输出目录: %s\n\n', OutInfo.outputDir);

%% 9. 可选：画方向图查询点检查图
% 这两张图用于检查：
% 1) Tx 方向图查询点是否落在预期区域；
% 2) Rx 方向图查询点是否落在地面天线覆盖区域。
if exist('LinkResult', 'var') && isstruct(LinkResult)

    %% 9.1 Tx 弹载天线方向图查询点
    if isfield(LinkResult, 'Az_query_tx') && ...
       isfield(LinkResult, 'El_query_tx') && ...
       isfield(LinkResult, 'Gt')

        figure;
        scatter(LinkResult.Az_query_tx, LinkResult.El_query_tx, 20, LinkResult.Gt, 'filled');
        xlabel('Tx Pattern Phi / Az [deg]');
        ylabel('Tx Pattern Theta / El [deg]');
        title('Tx 弹载天线方向图查询点');
        colorbar;
        grid on;
    end

    %% 9.2 Rx 地面天线方向图查询点
    if isfield(LinkResult, 'Az_query_rx') && ...
       isfield(LinkResult, 'El_query_rx') && ...
       isfield(LinkResult, 'Gr')

        figure;
        scatter(LinkResult.Az_query_rx, LinkResult.El_query_rx, 20, LinkResult.Gr, 'filled');
        xlabel('Rx Pattern Phi / Az [deg]');
        ylabel('Rx Pattern Theta / El [deg]');
        title('Rx 地面天线方向图查询点');
        colorbar;
        grid on;
    end
end

%% 10. 可选调试信息
% 如需查看配置和中间诊断信息，可以取消下面几行注释。
% disp(CfgDiag);
% disp(InputDiag);
% disp(SimDiag);
% disp(AnalysisDiag);
% disp(OutDiag);