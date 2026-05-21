function [Az, El] = mapPatternAngle(a1, a2, angleInputType)
%MAPPATTERNANGLE 外部方向图角度映射
%
% 支持：
%   AzEl:
%       a1 = Az
%       a2 = El
%
%   thetaPhi:
%       a1 = theta
%       a2 = phi
%       theta 从 +Z 天顶方向量起
%       phi 为方位角
%
%   PhiTheta:
%       a1 = Phi
%       a2 = Theta
%       当前直接映射为：
%           Az = Phi
%           El = Theta
%
% 说明：
%   老师给的 CSV 是 Phi/Theta 格式。
%   这里负责把 CSV 的角度读成内部网格角。
%   真正的弹体方向修正放在 mapBodyAzElToPatternAngle.m 里完成。

if nargin < 3 || isempty(angleInputType)
    angleInputType = 'PhiTheta';
end

a1 = double(a1);
a2 = double(a2);

switch lower(string(angleInputType))

    case "azel"
        Az = a1;
        El = a2;

    case "thetaphi"
        theta = a1;
        phi = a2;

        Az = phi;
        El = 90 - theta;

    case "phitheta"
        phi = a1;
        theta = a2;

        Az = phi;
        El = theta;

    case "theta0zenith"
        theta = a1;
        phi = a2;

        Az = phi;
        El = 90 - theta;

    otherwise
        error('未知角度输入类型：%s', angleInputType);
end

Az = mod(Az, 360);

end