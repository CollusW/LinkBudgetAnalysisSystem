function fig = plotPolarTrajectory(LinkResult)
% plotPolarTrajectory
% Rx 视角极坐标轨迹：极角 Az_rx，极径距离，颜色 Margin。

Geo = LinkResult.GeoSeries;
Bud = LinkResult.BudgetSeries;

fig = figure('Name', 'Rx polar trajectory', 'Position', [250, 250, 700, 600]);
polarscatter(deg2rad(Geo.Az_rx), Geo.d/1000, 36, Bud.Margin, 'filled');
colorbar;
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.ThetaDir = 'clockwise';
title({'Rx view polar trajectory', 'angle = Az_{rx}, radius = distance / km, color = Margin'});
end
