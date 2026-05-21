function d = calcDistanceFromPosition(tx_xyz, rx_xyz)
% calcDistanceFromPosition
% 根据 Tx/Rx 坐标计算距离。
% V5.1 硬规则：距离只能由坐标计算，不能作为输入直接给定。

v = rx_xyz(:) - tx_xyz(:);
d = sqrt(sum(v.^2));
end
