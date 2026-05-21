function [x, y, z] = wgs84_to_ecef(lat_deg, lon_deg, alt_m)
% wgs84_to_ecef
% WGS84 经纬高转 ECEF。
% 该函数只用于可选预处理工具，不属于核心链路预算内核。

a = 6378137.0;
f = 1 / 298.257223563;
e2 = f * (2 - f);

lat = deg2rad(lat_deg);
lon = deg2rad(lon_deg);

N = a ./ sqrt(1 - e2 .* sin(lat).^2);
x = (N + alt_m) .* cos(lat) .* cos(lon);
y = (N + alt_m) .* cos(lat) .* sin(lon);
z = (N .* (1 - e2) + alt_m) .* sin(lat);
end
