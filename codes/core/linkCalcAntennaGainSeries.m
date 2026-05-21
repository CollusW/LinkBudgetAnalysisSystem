function [AntSeries, AntDiag] = linkCalcAntennaGainSeries(GeoSeries, AntTx, AntRx, AntCfg)
%LINKCALCANTENNAGAINSERIES 查询 Tx/Rx 两端天线增益
%
% 输入：
%   GeoSeries.Az_tx / El_tx:
%       Tx 看 Rx 的方向，已经在 Tx body 坐标系下。
%
%   GeoSeries.Az_rx / El_rx:
%       Rx 看 Tx 的方向，已经在 Rx body 坐标系下。
%
% 输出：
%   AntSeries.Gt:
%       Tx 天线增益
%
%   AntSeries.Gr:
%       Rx 天线增益
%
%   AntSeries.Az_query_tx / El_query_tx:
%       实际用于查询 Tx 方向图的角度
%
%   AntSeries.Az_query_rx / El_query_rx:
%       实际用于查询 Rx 方向图的角度

N = numel(GeoSeries.t);

Az_tx = GeoSeries.Az_tx(:);
El_tx = GeoSeries.El_tx(:);
Az_rx = GeoSeries.Az_rx(:);
El_rx = GeoSeries.El_rx(:);

Gt = zeros(N, 1);
Gr = zeros(N, 1);

Az_query_tx = nan(N, 1);
El_query_tx = nan(N, 1);
Az_query_rx = nan(N, 1);
El_query_rx = nan(N, 1);

%% Tx 天线增益
if strcmpi(AntCfg.tx.type, 'omni')

    Gt(:) = AntCfg.tx.omni_gain_dbi;

else

    [Az_query_tx, El_query_tx] = mapBodyAzElToPatternAngle( ...
        Az_tx, ...
        El_tx, ...
        AntCfg.tx.angleMap);

    Gt = getAntennaGain( ...
        Az_query_tx, ...
        El_query_tx, ...
        AntTx.Az_grid, ...
        AntTx.El_grid, ...
        AntTx.Gain_grid, ...
        AntTx.interpolation, ...
        AntTx.outOfBound);
end

%% Rx 天线增益
if strcmpi(AntCfg.rx.type, 'omni')

    Gr(:) = AntCfg.rx.omni_gain_dbi;

else

    [Az_query_rx, El_query_rx] = mapBodyAzElToPatternAngle( ...
        Az_rx, ...
        El_rx, ...
        AntCfg.rx.angleMap);

    Gr = getAntennaGain( ...
        Az_query_rx, ...
        El_query_rx, ...
        AntRx.Az_grid, ...
        AntRx.El_grid, ...
        AntRx.Gain_grid, ...
        AntRx.interpolation, ...
        AntRx.outOfBound);
end

%% 输出
AntSeries = struct();

AntSeries.Gt = Gt;
AntSeries.Gr = Gr;
AntSeries.Gtotal_actual = Gt + Gr;

% 原始几何角
AntSeries.Az_body_tx = Az_tx;
AntSeries.El_body_tx = El_tx;
AntSeries.Az_body_rx = Az_rx;
AntSeries.El_body_rx = El_rx;

% 实际查询方向图的角
AntSeries.Az_query_tx = Az_query_tx;
AntSeries.El_query_tx = El_query_tx;
AntSeries.Az_query_rx = Az_query_rx;
AntSeries.El_query_rx = El_query_rx;

% 兼容 Phi/Theta 命名
AntSeries.Phi_tx = Az_query_tx;
AntSeries.Theta_tx = El_query_tx;
AntSeries.Phi_rx = Az_query_rx;
AntSeries.Theta_rx = El_query_rx;

AntDiag = struct();

AntDiag.message = '天线增益查询完成。';

AntDiag.Gt_min = min(Gt);
AntDiag.Gt_max = max(Gt);
AntDiag.Gt_mean = mean(Gt);

AntDiag.Gr_min = min(Gr);
AntDiag.Gr_max = max(Gr);
AntDiag.Gr_mean = mean(Gr);

AntDiag.Gtotal_min = min(Gt + Gr);
AntDiag.Gtotal_max = max(Gt + Gr);
AntDiag.Gtotal_mean = mean(Gt + Gr);

AntDiag.interpolation = AntCfg.interpolation;
AntDiag.outOfBound = AntCfg.outOfBound;

AntDiag.TxOutOfBoundCount = sum(Gt <= AntCfg.outOfBound);
AntDiag.RxOutOfBoundCount = sum(Gr <= AntCfg.outOfBound);

fprintf('\n========== linkCalcAntennaGainSeries ==========\n');
fprintf('Tx Gt 范围: %.3f ~ %.3f dBi, 平均 %.3f dBi\n', ...
    AntDiag.Gt_min, AntDiag.Gt_max, AntDiag.Gt_mean);
fprintf('Rx Gr 范围: %.3f ~ %.3f dBi, 平均 %.3f dBi\n', ...
    AntDiag.Gr_min, AntDiag.Gr_max, AntDiag.Gr_mean);
fprintf('Gt+Gr 范围: %.3f ~ %.3f dBi, 平均 %.3f dBi\n', ...
    AntDiag.Gtotal_min, AntDiag.Gtotal_max, AntDiag.Gtotal_mean);
fprintf('Tx 越界点数: %d / %d\n', AntDiag.TxOutOfBoundCount, N);
fprintf('Rx 越界点数: %d / %d\n', AntDiag.RxOutOfBoundCount, N);
fprintf('================================================\n\n');

end