function xyz = gpsWgs84ToLocalXyz(lat, lon, alt, lat0, lon0, alt0)
% gpsWgs84ToLocalXyz
% 将 WGS84 经纬高转换到以参考点为原点的 local XYZ。
%
% 为避免和核心链路坐标混乱，这里输出采用：
%   X = East
%   Y = North
%   Z = Up
%
% 若工程需要 Tx 前方为 X，也可在预处理后额外做一次旋转。

[x, y, z] = wgs84_to_ecef(lat, lon, alt);
[x0, y0, z0] = wgs84_to_ecef(lat0, lon0, alt0);

dx = x - x0;
dy = y - y0;
dz = z - z0;

lat0r = deg2rad(lat0);
lon0r = deg2rad(lon0);

R = [-sin(lon0r),              cos(lon0r),             0;
     -sin(lat0r)*cos(lon0r), -sin(lat0r)*sin(lon0r), cos(lat0r);
      cos(lat0r)*cos(lon0r),  cos(lat0r)*sin(lon0r), sin(lat0r)];

enu = R * [dx(:)'; dy(:)'; dz(:)'];
xyz = enu.';
end
