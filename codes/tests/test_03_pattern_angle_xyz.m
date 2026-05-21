%% TC03: 定向天线角度扫描测试
% 目的：验证相同距离下，不同 Az/El 查询得到不同方向图增益。

clear; clc; close all;
simCfgIn = struct();
simCfgIn.scenarioName = 'tc03_pattern_angle_xyz';
simCfgIn.inputMode = 'synthetic';
simCfgIn.txAntennaType = 'pattern';
simCfgIn.rxAntennaType = 'omni';
simCfgIn.enablePlot = true;
simCfgIn.saveFigure = false;

[LinkResult] = run_one_scenario_for_test(simCfgIn);

Gt = LinkResult.AntSeries.Gt;
assert(max(Gt) - min(Gt) > 5, 'TC03 失败：角度变化没有导致明显 Gt 变化');
fprintf('TC03 通过：Gt range = %.2f dB\n', max(Gt)-min(Gt));
