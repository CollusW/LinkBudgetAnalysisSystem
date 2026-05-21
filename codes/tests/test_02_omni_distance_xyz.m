%% TC02: 全向天线变距离测试
% 目的：验证坐标距离增大时，Lfs 增大、Pr/Margin 下降。

clear; clc; close all;
simCfgIn = struct();
simCfgIn.scenarioName = 'tc02_omni_distance_xyz';
simCfgIn.inputMode = 'synthetic';
simCfgIn.txAntennaType = 'omni';
simCfgIn.rxAntennaType = 'omni';
simCfgIn.enablePlot = true;
simCfgIn.saveFigure = false;

[LinkResult] = run_one_scenario_for_test(simCfgIn);

d = LinkResult.GeoSeries.d;
Lfs = LinkResult.BudgetSeries.Lfs;
Pr = LinkResult.BudgetSeries.Pr;
Margin = LinkResult.BudgetSeries.Margin;

assert(all(diff(d) >= -1e-9), 'TC02 失败：距离没有随坐标单调增大');
assert(all(diff(Lfs) >= -1e-9), 'TC02 失败：Lfs 没有随距离增大');
assert(all(diff(Pr) <= 1e-9), 'TC02 失败：Pr 没有随距离下降');
assert(all(diff(Margin) <= 1e-9), 'TC02 失败：Margin 没有随距离下降');
fprintf('TC02 通过\n');
