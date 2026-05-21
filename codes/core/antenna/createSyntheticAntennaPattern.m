function [Az_grid, El_grid, Gain_grid] = createSyntheticAntennaPattern(sideName)
% createSyntheticAntennaPattern
% 生成用于验证流程的合成方向图。
% 主瓣默认朝 Body X 正向，即 Az=0, El=0。

az = -180:2:180;
el = -90:2:90;
[Az_grid, El_grid] = meshgrid(az, el);

% 角距离：主瓣在 Az=0, El=0
ang = sqrt((Az_grid/45).^2 + (El_grid/35).^2);

% 平滑方向图：主瓣高，偏离后下降；最低限制为 -30 dBi
if strcmpi(sideName, 'Tx')
    Gmax = 12;
else
    Gmax = 8;
end
Gain_grid = Gmax - 18*ang.^2;
Gain_grid = max(Gain_grid, -30);

% 加一点弱起伏，避免图形过于理想，但不影响主趋势
Gain_grid = Gain_grid + 1.5*cosd(2*Az_grid).*cosd(El_grid);
Gain_grid = max(Gain_grid, -30);
end
