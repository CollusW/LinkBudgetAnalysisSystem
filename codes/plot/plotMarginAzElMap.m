function fig = plotMarginAzElMap(LinkResult)
% plotMarginAzElMap
% Rx 本体视角 Az/El - Margin 空间映射。

Geo = LinkResult.GeoSeries;
Bud = LinkResult.BudgetSeries;

fig = figure('Name', 'Rx Az/El - Margin map', 'Position', [150, 150, 750, 600]);
scatter(Geo.Az_rx, Geo.El_rx, 28, Bud.Margin, 'filled');
colorbar;
xlabel('Az_{rx} / deg');
ylabel('El_{rx} / deg');
title('Rx view: Az/El - link margin');
axis([-180 180 -90 90]);
grid on;
end
