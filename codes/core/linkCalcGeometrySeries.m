function [GeoSeries, GeoDiag] = linkCalcGeometrySeries(TxState, RxState, GeoCfg)
% linkCalcGeometrySeries
% 根据 local XYZ 坐标计算距离、视线向量、Body 坐标下 Az/El。

N = numel(TxState.t);

v_tx_to_rx = zeros(N,3);
v_rx_to_tx = zeros(N,3);
v_body_tx = zeros(N,3);
v_body_rx = zeros(N,3);
d = zeros(N,1);
Az_tx = zeros(N,1);
El_tx = zeros(N,1);
Az_rx = zeros(N,1);
El_rx = zeros(N,1);

for i = 1:N
    tx_xyz = TxState.xyz(i,:);
    rx_xyz = RxState.xyz(i,:);

    v_tx_to_rx(i,:) = calcRelativeVector(tx_xyz, rx_xyz);
    v_rx_to_tx(i,:) = calcRelativeVector(rx_xyz, tx_xyz);
    d(i) = calcDistanceFromPosition(tx_xyz, rx_xyz);

    Rtx = createBodyRotationMatrix(TxState.att(i,1), TxState.att(i,2), TxState.att(i,3));
    Rrx = createBodyRotationMatrix(RxState.att(i,1), RxState.att(i,2), RxState.att(i,3));

    % R 表示 Body -> local XYZ，因此 local XYZ -> Body 使用 R'
    v_body_tx(i,:) = (Rtx' * v_tx_to_rx(i,:).').';
    v_body_rx(i,:) = (Rrx' * v_rx_to_tx(i,:).').';

    [Az_tx(i), El_tx(i)] = calcAzElFromVector(v_body_tx(i,:));
    [Az_rx(i), El_rx(i)] = calcAzElFromVector(v_body_rx(i,:));
end

GeoSeries = struct();
GeoSeries.t = TxState.t;
GeoSeries.d = d;
GeoSeries.v_tx_to_rx = v_tx_to_rx;
GeoSeries.v_rx_to_tx = v_rx_to_tx;
GeoSeries.v_body_tx = v_body_tx;
GeoSeries.v_body_rx = v_body_rx;
GeoSeries.Az_tx = Az_tx;
GeoSeries.El_tx = El_tx;
GeoSeries.Az_rx = Az_rx;
GeoSeries.El_rx = El_rx;

GeoDiag = struct();
GeoDiag.message = '几何计算完成。';
GeoDiag.minDistance = min(d);
GeoDiag.maxDistance = max(d);
GeoDiag.coordinateSystem = GeoCfg.originDefinition;
GeoDiag.angleConvention = 'Az = atan2(y,x), El = atan2(z,sqrt(x^2+y^2))';
end
