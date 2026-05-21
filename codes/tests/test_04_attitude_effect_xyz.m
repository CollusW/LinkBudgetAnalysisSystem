%% TC04: 姿态影响测试
% 目的：验证 Rx 姿态变化会改变 Rx Body 视角 Az/El 和方向图增益。

clear; clc; close all;
simCfgIn = struct();
simCfgIn.scenarioName = 'tc04_attitude_effect_xyz';
simCfgIn.inputMode = 'synthetic';
simCfgIn.txAntennaType = 'omni';
simCfgIn.rxAntennaType = 'pattern';
simCfgIn.enablePlot = true;
simCfgIn.saveFigure = false;

[LinkResult] = run_one_scenario_for_test(simCfgIn);

Gr = LinkResult.AntSeries.Gr;
Az_rx = LinkResult.GeoSeries.Az_rx;
assert(max(Az_rx)-min(Az_rx) > 20, 'TC04 失败：姿态变化没有改变 Rx 视角 Az');
assert(max(Gr)-min(Gr) > 5, 'TC04 失败：姿态变化没有导致明显 Gr 变化');
fprintf('TC04 通过：Az_rx range = %.2f deg, Gr range = %.2f dB\n', max(Az_rx)-min(Az_rx), max(Gr)-min(Gr));
