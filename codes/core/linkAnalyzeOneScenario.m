function [AnalysisResult, AnalysisDiag] = linkAnalyzeOneScenario(LinkResult, RfCfg, AlgoCfg)
% linkAnalyzeOneScenario
% 场景级结果分析。

Geo = LinkResult.GeoSeries;
Ant = LinkResult.AntSeries;
Bud = LinkResult.BudgetSeries;

[marginMin, idxMinMargin] = min(Bud.Margin);
[prMin, idxMinPr] = min(Bud.Pr);

Summary = struct();
Summary.minPr = prMin;
Summary.minPrTime = LinkResult.t(idxMinPr);
Summary.minMargin = marginMin;
Summary.minMarginTime = LinkResult.t(idxMinMargin);
Summary.maxLfs = max(Bud.Lfs);
Summary.maxDistance = max(Geo.d);
Summary.maxGtotalRequired = max(Bud.G_total_required);
Summary.minActualGtotal = min(Ant.Gtotal_actual);
Summary.outageRatio = mean(Bud.Margin < RfCfg.Margin_target);

if AlgoCfg.enableEnvelope
    [GreqEnvelope, MarginEnvelope] = buildGainRequirementEnvelope(Geo.Az_rx, Geo.El_rx, Bud.G_total_required, Bud.Margin, AlgoCfg.azBinDeg, AlgoCfg.elBinDeg);
else
    GreqEnvelope = struct();
    MarginEnvelope = struct();
end

AnalysisResult = struct();
AnalysisResult.Summary = Summary;
AnalysisResult.GreqEnvelope = GreqEnvelope;
AnalysisResult.MarginEnvelope = MarginEnvelope;

AnalysisDiag = struct();
AnalysisDiag.message = '场景分析完成。';
AnalysisDiag.outageRatio = Summary.outageRatio;
end
