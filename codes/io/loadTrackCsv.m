function Node = loadTrackCsv(filePath, nodeName, GeoCfg)
% loadTrackCsv
% 读取 local XYZ 轨迹 CSV。
%
% 必需列：t,x,y,z,yaw,pitch,roll
% 禁止列：d,distance,range,r  等距离字段。

if ~exist(filePath, 'file')
    error('%s 轨迹文件不存在：%s', nodeName, filePath);
end

T = readtable(filePath);
vars = lower(string(T.Properties.VariableNames));

required = ["t","x","y","z","yaw","pitch","roll"];
for k = 1:numel(required)
    if ~any(vars == required(k))
        error('%s 轨迹文件缺少必要字段：%s', nodeName, required(k));
    end
end

if isfield(GeoCfg, 'rejectDistanceInput') && GeoCfg.rejectDistanceInput
    forbidden = ["d","distance","range","r","dist"];
    for k = 1:numel(forbidden)
        if any(vars == forbidden(k))
            error(['%s 轨迹文件包含禁止字段 %s。\n' ...
                   'V5.1 规定：距离必须由 Tx/Rx 坐标计算，不能作为输入。'], nodeName, forbidden(k));
        end
    end
end

% 统一字段大小写
T = T(:, cellstr(required));
T.Properties.VariableNames = {'t','x','y','z','yaw','pitch','roll'};

Node = struct();
Node.name = nodeName;
Node.coordinateMode = 'local_xyz';
Node.track = T;
end
