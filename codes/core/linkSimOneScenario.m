function [LinkResult, SimDiag] = linkSimOneScenario(TxNode, RxNode, AntTx, AntRx, GeoCfg, RfCfg, AntCfg, AlgoCfg)
% linkSimOneScenario
% 单场景链路仿真核心入口。

[TxState, RxState, PreDiag] = linkPreprocessTrack(TxNode, RxNode, GeoCfg);
[GeoSeries, GeoDiag] = linkCalcGeometrySeries(TxState, RxState, GeoCfg);
[AntSeries, AntDiag] = linkCalcAntennaGainSeries(GeoSeries, AntTx, AntRx, AntCfg);
[BudgetSeries, BudgetDiag] = linkCalcBudgetSeries(GeoSeries, AntSeries, RfCfg, AlgoCfg);

LinkResult = struct();
LinkResult.t = GeoSeries.t;
LinkResult.TxState = TxState;
LinkResult.RxState = RxState;
LinkResult.GeoSeries = GeoSeries;
LinkResult.AntSeries = AntSeries;
LinkResult.BudgetSeries = BudgetSeries;
LinkResult.AntTx = AntTx;
LinkResult.AntRx = AntRx;

SimDiag = struct();
SimDiag.message = '单场景链路仿真完成。';
SimDiag.PreDiag = PreDiag;
SimDiag.GeoDiag = GeoDiag;
SimDiag.AntDiag = AntDiag;
SimDiag.BudgetDiag = BudgetDiag;
end
