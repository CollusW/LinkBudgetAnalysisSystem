function [BudgetSeries, BudgetDiag] = linkCalcBudgetSeries(GeoSeries, AntSeries, RfCfg, AlgoCfg)
% linkCalcBudgetSeries
% 计算 FSPL、Pr、Margin、全向参考和 G_total_required。

Lfs = calcFSPL(GeoSeries.d, RfCfg.f, RfCfg.c);
[Pr, Margin] = calcLinkBudget(RfCfg.Pt, AntSeries.Gt, AntSeries.Gr, Lfs, RfCfg.L_other, RfCfg.Sens);
G_total_required = calcGTotalRequired(Lfs, RfCfg.Margin_target, RfCfg.Pt, RfCfg.Sens, RfCfg.L_other);

if AlgoCfg.enableOmniReference
    Pr_omni_ref = RfCfg.Pt + 0 + 0 - Lfs - RfCfg.L_other;
    Margin_omni_ref = Pr_omni_ref - RfCfg.Sens;
else
    Pr_omni_ref = nan(size(Pr));
    Margin_omni_ref = nan(size(Margin));
end

BudgetSeries = struct();
BudgetSeries.Lfs = Lfs;
BudgetSeries.Pr = Pr;
BudgetSeries.Margin = Margin;
BudgetSeries.Pr_omni_ref = Pr_omni_ref;
BudgetSeries.Margin_omni_ref = Margin_omni_ref;
BudgetSeries.G_total_required = G_total_required;

BudgetDiag = struct();
BudgetDiag.message = '链路预算计算完成。';
BudgetDiag.minPr = min(Pr);
BudgetDiag.minMargin = min(Margin);
BudgetDiag.maxLfs = max(Lfs);
BudgetDiag.maxGtotalRequired = max(G_total_required);
end
