function [TxState, RxState, PreDiag] = linkPreprocessTrack(TxNode, RxNode, GeoCfg)
% linkPreprocessTrack
% 轨迹预处理与时间对齐。
% 核心坐标只保留 local XYZ。

TxT = TxNode.track;
RxT = RxNode.track;

required = {'t','x','y','z','yaw','pitch','roll'};
for k = 1:numel(required)
    assert(any(strcmp(TxT.Properties.VariableNames, required{k})), 'Tx 缺少字段 %s', required{k});
    assert(any(strcmp(RxT.Properties.VariableNames, required{k})), 'Rx 缺少字段 %s', required{k});
end

if isequal(TxT.t, RxT.t)
    t = TxT.t;
    TxAligned = TxT;
    RxAligned = RxT;
else
    switch lower(GeoCfg.timeAlignment)
        case 'linear'
            t0 = max(min(TxT.t), min(RxT.t));
            t1 = min(max(TxT.t), max(RxT.t));
            if t1 <= t0
                error('Tx/Rx 时间轴没有重叠区间，无法对齐。');
            end
            dtTx = median(diff(unique(TxT.t)));
            dtRx = median(diff(unique(RxT.t)));
            dt = min(dtTx, dtRx);
            t = (t0:dt:t1)';
            TxAligned = interpTrack(TxT, t);
            RxAligned = interpTrack(RxT, t);
        otherwise
            error('暂不支持时间对齐方式：%s', GeoCfg.timeAlignment);
    end
end

TxState = struct();
TxState.name = TxNode.name;
TxState.t = t;
TxState.xyz = [TxAligned.x, TxAligned.y, TxAligned.z];
TxState.att = [TxAligned.yaw, TxAligned.pitch, TxAligned.roll];

RxState = struct();
RxState.name = RxNode.name;
RxState.t = t;
RxState.xyz = [RxAligned.x, RxAligned.y, RxAligned.z];
RxState.att = [RxAligned.yaw, RxAligned.pitch, RxAligned.roll];

PreDiag = struct();
PreDiag.message = '轨迹预处理完成。';
PreDiag.nSamples = numel(t);
PreDiag.coordinateMode = GeoCfg.coordinateMode;
PreDiag.distanceRule = GeoCfg.distanceRule;
end

function Tout = interpTrack(T, tq)
vars = {'x','y','z','yaw','pitch','roll'};
Tout = table();
Tout.t = tq(:);
for i = 1:numel(vars)
    Tout.(vars{i}) = interp1(T.t, T.(vars{i}), tq, 'linear', 'extrap');
end
end
