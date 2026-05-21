%% TC06: 准实际 local XYZ 地空链路测试
% 目的：替代过于简单的固定距离例子，验证更接近实际的坐标轨迹、姿态、方向图和链路预算。
%
% 场景：Tx 在原点，Rx 从 2.5 km 附近机动到 8.5 km 附近，带高度和姿态变化。

clear; clc; close all;
simCfgIn = struct();
simCfgIn.scenarioName = 'tc06_realistic_local_xyz';
simCfgIn.inputMode = 'synthetic';
simCfgIn.txAntennaType = 'pattern';
simCfgIn.rxAntennaType = 'pattern';
simCfgIn.enablePlot = true;
simCfgIn.saveFigure = false;

[LinkResult, AnalysisResult] = run_one_scenario_for_test(simCfgIn);

fprintf('TC06 关键结果：\n');
fprintf('距离范围       : %.2f ~ %.2f km\n', min(LinkResult.GeoSeries.d)/1000, max(LinkResult.GeoSeries.d)/1000);
fprintf('Tx Az 范围     : %.2f ~ %.2f deg\n', min(LinkResult.GeoSeries.Az_tx), max(LinkResult.GeoSeries.Az_tx));
fprintf('Rx Az 范围     : %.2f ~ %.2f deg\n', min(LinkResult.GeoSeries.Az_rx), max(LinkResult.GeoSeries.Az_rx));
fprintf('Gt+Gr 实际范围 : %.2f ~ %.2f dBi\n', min(LinkResult.AntSeries.Gtotal_actual), max(LinkResult.AntSeries.Gtotal_actual));
fprintf('Margin 最小值  : %.2f dB\n', AnalysisResult.Summary.minMargin);

assert(max(LinkResult.GeoSeries.d)-min(LinkResult.GeoSeries.d) > 4000, 'TC06 失败：实际风格轨迹距离变化不足');
assert(max(LinkResult.GeoSeries.Az_tx)-min(LinkResult.GeoSeries.Az_tx) > 50, 'TC06 失败：Tx 视角方位变化不足');
fprintf('TC06 通过\n');
