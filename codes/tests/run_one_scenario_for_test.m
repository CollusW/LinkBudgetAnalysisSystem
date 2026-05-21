function [LinkResult, AnalysisResult, OutInfo] = run_one_scenario_for_test(simCfgIn)
% run_one_scenario_for_test
% 测试脚本统一入口。

thisFile = mfilename('fullpath');
testsDir = fileparts(thisFile);
rootDir = fileparts(testsDir);

addpath(rootDir);
addpath(fullfile(rootDir, 'config'));
addpath(fullfile(rootDir, 'io'));
addpath(fullfile(rootDir, 'core'));
addpath(fullfile(rootDir, 'core', 'geometry'));
addpath(fullfile(rootDir, 'core', 'antenna'));
addpath(fullfile(rootDir, 'core', 'linkbudget'));
addpath(fullfile(rootDir, 'plot'));

[SimCfg, GeoCfg, RfCfg, AntCfg, AlgoCfg, OutCfg] = linkInitConfig(simCfgIn);
[TxNode, RxNode, AntTx, AntRx] = linkLoadOneScenario(SimCfg, GeoCfg, AntCfg);
[LinkResult] = linkSimOneScenario(TxNode, RxNode, AntTx, AntRx, GeoCfg, RfCfg, AntCfg, AlgoCfg);
[AnalysisResult] = linkAnalyzeOneScenario(LinkResult, RfCfg, AlgoCfg);
[OutInfo] = linkOutputOneScenario(LinkResult, AnalysisResult, SimCfg, GeoCfg, RfCfg, AntCfg, OutCfg);

fprintf('\n==== TEST DONE: %s ====\n', SimCfg.scenarioName);
fprintf('d_min/max = %.3f / %.3f km\n', min(LinkResult.GeoSeries.d)/1000, max(LinkResult.GeoSeries.d)/1000);
fprintf('Pr_min    = %.2f dBm\n', AnalysisResult.Summary.minPr);
fprintf('Margin_min= %.2f dB\n', AnalysisResult.Summary.minMargin);
fprintf('Greq_max  = %.2f dBi\n\n', AnalysisResult.Summary.maxGtotalRequired);
end
