%% TC01: 全向天线固定坐标距离测试
% 目的：验证距离由坐标计算，且 FSPL/Pr/Margin 基础公式正确。

clear; clc; close all;
simCfgIn = struct();
simCfgIn.scenarioName = 'tc01_omni_static_xyz';
simCfgIn.inputMode = 'synthetic';
simCfgIn.txAntennaType = 'omni';
simCfgIn.rxAntennaType = 'omni';
simCfgIn.enablePlot = true;
simCfgIn.saveFigure = false;

[LinkResult, AnalysisResult] = run_one_scenario_for_test(simCfgIn);

Lfs = LinkResult.BudgetSeries.Lfs(1);
Pr = LinkResult.BudgetSeries.Pr(1);
Margin = LinkResult.BudgetSeries.Margin(1);
d = LinkResult.GeoSeries.d(1);

fprintf('d=%.2f m, Lfs=%.2f dB, Pr=%.2f dBm, Margin=%.2f dB\n', d, Lfs, Pr, Margin);

assert(abs(d - 1000) < 1e-9, 'TC01 失败：距离不是由坐标得到的 1000 m');
assert(abs(Lfs - 100.05) < 0.1, 'TC01 失败：Lfs 不符合 1 km, 2.4 GHz 预期');
assert(abs(Pr - (-70.05)) < 0.2, 'TC01 失败：Pr 不符合预期');
assert(abs(Margin - 19.95) < 0.2, 'TC01 失败：Margin 不符合预期');
fprintf('TC01 通过\n');
