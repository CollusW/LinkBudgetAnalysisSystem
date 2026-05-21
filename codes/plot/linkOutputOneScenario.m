function [OutInfo, OutDiag] = linkOutputOneScenario(LinkResult, AnalysisResult, SimCfg, GeoCfg, RfCfg, AntCfg, OutCfg)
% linkOutputOneScenario
% 输出 CSV/MAT 与绘图。

if ~exist(OutCfg.outputDir, 'dir'); mkdir(OutCfg.outputDir); end
if ~exist(OutCfg.figureDir, 'dir'); mkdir(OutCfg.figureDir); end

Geo = LinkResult.GeoSeries;
Ant = LinkResult.AntSeries;
Bud = LinkResult.BudgetSeries;

t = LinkResult.t;
outTable = table(t, Geo.d, Geo.Az_tx, Geo.El_tx, Geo.Az_rx, Geo.El_rx, ...
    Bud.Lfs, Ant.Gt, Ant.Gr, Ant.Gtotal_actual, Bud.Pr, Bud.Margin, ...
    Bud.Margin_omni_ref, Bud.G_total_required, ...
    'VariableNames', {'t','d','Az_tx','El_tx','Az_rx','El_rx', ...
    'Lfs','Gt','Gr','Gtotal_actual','Pr','Margin','Margin_omni_ref','G_total_required'});

writetable(outTable, OutCfg.outputCsv);
save(OutCfg.outputMat, 'LinkResult', 'AnalysisResult', 'SimCfg', 'GeoCfg', 'RfCfg', 'AntCfg');

figureFiles = {};
if SimCfg.enablePlot
    fig1 = plotLinkTimeSeries(LinkResult, RfCfg);
    figureFiles{end+1} = saveMaybe(fig1, OutCfg, 'fig01_link_time_series', SimCfg.saveFigure); %#ok<AGROW>

    fig2 = plotMarginAzElMap(LinkResult);
    figureFiles{end+1} = saveMaybe(fig2, OutCfg, 'fig02_rx_azel_margin_map', SimCfg.saveFigure); %#ok<AGROW>

    fig3 = plotGainRequirementEnvelope(AnalysisResult);
    figureFiles{end+1} = saveMaybe(fig3, OutCfg, 'fig03_g_total_required_envelope', SimCfg.saveFigure); %#ok<AGROW>

    fig4 = plotPolarTrajectory(LinkResult);
    figureFiles{end+1} = saveMaybe(fig4, OutCfg, 'fig04_rx_polar_trajectory', SimCfg.saveFigure); %#ok<AGROW>

    fig5 = plotTrajectory3D(LinkResult);
    figureFiles{end+1} = saveMaybe(fig5, OutCfg, 'fig05_3d_trajectory', SimCfg.saveFigure); %#ok<AGROW>
end

OutInfo = struct();
OutInfo.outputDir = OutCfg.outputDir;
OutInfo.outputCsv = OutCfg.outputCsv;
OutInfo.outputMat = OutCfg.outputMat;
OutInfo.figureFiles = figureFiles;

OutDiag = struct();
OutDiag.message = '输出完成。';
OutDiag.outputCsv = OutCfg.outputCsv;
OutDiag.outputMat = OutCfg.outputMat;
end

function filePath = saveMaybe(figHandle, OutCfg, baseName, doSave)
filePath = '';
if doSave
    filePath = fullfile(OutCfg.figureDir, [baseName '.' OutCfg.figureFormat]);
    saveas(figHandle, filePath);
end
end
