%% TC07: GPS/WGS84 到 local XYZ 的可选预处理验证
% 注意：GPS 不进入核心链路预算内核，只是可选工具。

clear; clc; close all;

thisFile = mfilename('fullpath');
rootDir = fileparts(fileparts(thisFile));
addpath(fullfile(rootDir, 'tools', 'gps_to_local_xyz'));

lat0 = 34.2468;
lon0 = 108.9280;
alt0 = 420;

lat = [lat0; lat0 + 0.001];
lon = [lon0; lon0];
alt = [alt0; alt0 + 100];

xyz = gpsWgs84ToLocalXyz(lat, lon, alt, lat0, lon0, alt0);

fprintf('GPS 转 local XYZ 结果：\n');
disp(xyz);

assert(abs(xyz(1,1)) < 1e-6 && abs(xyz(1,2)) < 1e-6 && abs(xyz(1,3)) < 1e-6, 'TC07 失败：参考点未转换到原点');
assert(abs(xyz(2,2)) > 50, 'TC07 失败：纬度变化没有形成明显 North/Y 方向位移');
fprintf('TC07 通过\n');
