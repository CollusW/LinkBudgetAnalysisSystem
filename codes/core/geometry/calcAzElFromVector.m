function [Az, El] = calcAzElFromVector(v)
% calcAzElFromVector
% 根据 Body 坐标系下向量计算 Az/El。
%
% Body/local 角度约定：
%   Az = atan2(y, x)，范围 [-180, 180]
%   El = atan2(z, sqrt(x^2+y^2))，范围 [-90, 90]
%   Z 为向上，因此 El > 0 表示目标在上方。

x = v(1);
y = v(2);
z = v(3);

Az = atan2d(y, x);
El = atan2d(z, sqrt(x.^2 + y.^2));
end
