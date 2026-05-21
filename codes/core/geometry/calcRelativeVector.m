function v = calcRelativeVector(origin_xyz, target_xyz)
% calcRelativeVector
% 计算 target 相对于 origin 的向量。
% 输入均为 local XYZ 坐标，单位 m。

v = target_xyz(:).' - origin_xyz(:).';
end
