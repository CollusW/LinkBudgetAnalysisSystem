function convertGpsCsvToLocalXyz(inputCsv, outputCsv, lat0, lon0, alt0)
% convertGpsCsvToLocalXyz
% 将 GPS/WGS84 CSV 预处理为核心链路仿真所需 local XYZ CSV。
%
% 输入 CSV 必需字段：t,lat,lon,alt,yaw,pitch,roll
% 输出 CSV 字段：t,x,y,z,yaw,pitch,roll
%
% 注意：该函数是预处理工具，不进入核心链路预算内核。

T = readtable(inputCsv);
vars = lower(string(T.Properties.VariableNames));
required = ["t","lat","lon","alt","yaw","pitch","roll"];
for k = 1:numel(required)
    if ~any(vars == required(k))
        error('GPS CSV 缺少字段：%s', required(k));
    end
end

lat = T{:, find(vars == "lat", 1)};
lon = T{:, find(vars == "lon", 1)};
alt = T{:, find(vars == "alt", 1)};
xyz = gpsWgs84ToLocalXyz(lat, lon, alt, lat0, lon0, alt0);

Tout = table();
Tout.t = T{:, find(vars == "t", 1)};
Tout.x = xyz(:,1);
Tout.y = xyz(:,2);
Tout.z = xyz(:,3);
Tout.yaw = T{:, find(vars == "yaw", 1)};
Tout.pitch = T{:, find(vars == "pitch", 1)};
Tout.roll = T{:, find(vars == "roll", 1)};

writetable(Tout, outputCsv);
fprintf('GPS 预处理完成：%s -> %s\n', inputCsv, outputCsv);
end
