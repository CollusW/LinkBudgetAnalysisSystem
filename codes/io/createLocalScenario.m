function [TxNode, RxNode] = createLocalScenario(scenarioName)
% createLocalScenario
% 生成 local XYZ 合成测试场景。
%
% local XYZ 约定：
%   X：前方，Y：右侧，Z：向上，单位 m。
%   Tx/Rx 距离永远由坐标计算，不直接赋值。

scenarioName = lower(string(scenarioName));

switch scenarioName
    case "tc01_omni_static_xyz"
        t = (0:1:20)';
        tx = makeTrack(t, zeros(size(t)), zeros(size(t)), zeros(size(t)), 0*t, 0*t, 0*t);
        rx = makeTrack(t, 1000+0*t, zeros(size(t)), zeros(size(t)), 0*t, 0*t, 0*t);

    case "tc02_omni_distance_xyz"
        t = (0:1:120)';
        x = linspace(500, 5000, numel(t))';
        tx = makeTrack(t, 0*t, 0*t, 0*t, 0*t, 0*t, 0*t);
        rx = makeTrack(t, x, 0*t, 0*t, 0*t, 0*t, 0*t);

    case "tc03_pattern_angle_xyz"
        t = (0:1:180)';
        R = 2000;
        az = linspace(-90, 90, numel(t))';
        x = R*cosd(az);
        y = R*sind(az);
        z = 100 + 0*t;
        tx = makeTrack(t, 0*t, 0*t, 0*t, 0*t, 0*t, 0*t);
        rx = makeTrack(t, x, y, z, 0*t, 0*t, 0*t);

    case "tc04_attitude_effect_xyz"
        t = (0:1:180)';
        tx = makeTrack(t, 0*t, 0*t, 0*t, 0*t, 0*t, 0*t);
        rxX = 2000 + 0*t;
        rxY = 0*t;
        rxZ = 200 + 0*t;
        yawRx = linspace(-90, 90, numel(t))';
        pitchRx = 5*sind(2*pi*t/max(t));
        rollRx = 10*sind(2*pi*t/max(t));
        rx = makeTrack(t, rxX, rxY, rxZ, yawRx, pitchRx, rollRx);

    case {"tc05_full_local_trajectory_xyz", "synthetic_full_trajectory_pattern"}
        t = (0:1:200)';
        theta = linspace(-120, 120, numel(t))';
        R = 2500 + 2000*(0.5 + 0.5*sin(2*pi*t/max(t)));
        x = R.*cosd(theta);
        y = R.*sind(theta);
        z = 500 + 300*sind(theta/2);
        [yawRx, pitchRx, rollRx] = attitudeFromTrack(t, x, y, z);
        tx = makeTrack(t, 0*t, 0*t, 0*t, 0*t, 0*t, 0*t);
        rx = makeTrack(t, x, y, z, yawRx, pitchRx, rollRx);

    case {"tc06_realistic_local_xyz", "realistic_local_xyz"}
        % 工程风格地空链路：空中节点从近端进入、绕站机动、远离。
        t = (0:1:240)';
        theta = linspace(-65, 75, numel(t))';      % 方位扫描
        R = linspace(2500, 8500, numel(t))';       % 水平距离逐渐增大
        R = R + 700*sin(2*pi*t/max(t));            % 增加机动起伏
        x = R.*cosd(theta);
        y = R.*sind(theta);
        z = 500 + 500*(0.5 + 0.5*sin(2*pi*t/max(t) - pi/4));
        [yawRx, pitchRx, rollRx] = attitudeFromTrack(t, x, y, z);

        % Tx 固定在原点。yaw=0 表示主瓣朝 X 正向。
        txYaw = 0*t;
        txPitch = 0*t;
        txRoll = 0*t;
        tx = makeTrack(t, 0*t, 0*t, 0*t, txYaw, txPitch, txRoll);
        rx = makeTrack(t, x, y, z, yawRx, pitchRx, rollRx);

    otherwise
        error('未知 synthetic 场景名称：%s', scenarioName);
end

TxNode = struct();
TxNode.name = 'Tx';
TxNode.coordinateMode = 'local_xyz';
TxNode.track = tx;

RxNode = struct();
RxNode.name = 'Rx';
RxNode.coordinateMode = 'local_xyz';
RxNode.track = rx;

end

function T = makeTrack(t, x, y, z, yaw, pitch, roll)
T = table(t(:), x(:), y(:), z(:), yaw(:), pitch(:), roll(:), ...
    'VariableNames', {'t','x','y','z','yaw','pitch','roll'});
end

function [yaw, pitch, roll] = attitudeFromTrack(t, x, y, z)
% 根据轨迹切线生成较自然的航向/俯仰/滚转。
dx = gradient(x, t);
dy = gradient(y, t);
dz = gradient(z, t);
yaw = atan2d(dy, dx);
horizSpeed = sqrt(dx.^2 + dy.^2);
pitch = atan2d(dz, max(horizSpeed, eps));
roll = 12*sind(linspace(0, 2*pi, numel(t)))';
end
