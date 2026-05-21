%% TC05: local XYZ 完整轨迹 + 双端方向图测试
% 目的：验证轨迹、姿态、双端方向图、链路预算的完整主流程。

clear; clc; close all;
simCfgIn = struct();
simCfgIn.scenarioName = 'tc05_full_local_trajectory_xyz';
simCfgIn.inputMode = 'synthetic';
simCfgIn.txAntennaType = 'pattern';
simCfgIn.rxAntennaType = 'pattern';
simCfgIn.enablePlot = true;
simCfgIn.saveFigure = false;

[LinkResult] = run_one_scenario_for_test(simCfgIn);

assert(numel(LinkResult.t) > 50, 'TC05 失败：样本数过少');
assert(max(LinkResult.GeoSeries.d)-min(LinkResult.GeoSeries.d) > 1000, 'TC05 失败：轨迹距离变化不足');
assert(max(LinkResult.AntSeries.Gt)-min(LinkResult.AntSeries.Gt) > 3, 'TC05 失败：Gt 变化不足');
assert(max(LinkResult.AntSeries.Gr)-min(LinkResult.AntSeries.Gr) > 3, 'TC05 失败：Gr 变化不足');
fprintf('TC05 通过\n');
