function fig = plotLinkTimeSeries(LinkResult, RfCfg)
% plotLinkTimeSeries
% 绘制时序链路结果。

Geo = LinkResult.GeoSeries;
Ant = LinkResult.AntSeries;
Bud = LinkResult.BudgetSeries;
t = LinkResult.t;

fig = figure('Name', 'Link time series', 'Position', [100, 100, 1200, 800]);

subplot(2,2,1);
yyaxis left;
plot(t, Geo.d/1000, 'LineWidth', 1.5, 'DisplayName', 'Distance');
ylabel('Distance / km');
yyaxis right;
plot(t, Bud.Pr, 'LineWidth', 1.5, 'DisplayName', 'Pr'); hold on;
yline(RfCfg.Sens, '--', 'LineWidth', 1.2, 'DisplayName', 'Sensitivity');
ylabel('Pr / dBm');
xlabel('Time / s');
title('Distance and received power');
grid on; legend('Location','best');

subplot(2,2,2);
plot(t, Bud.Margin, 'LineWidth', 1.5, 'DisplayName', 'Current link'); hold on;
plot(t, Bud.Margin_omni_ref, '--', 'LineWidth', 1.5, 'DisplayName', 'Omni reference');
yline(RfCfg.Margin_target, ':', 'LineWidth', 1.5, 'DisplayName', 'Target margin');
xlabel('Time / s'); ylabel('Margin / dB');
title('Link margin'); grid on; legend('Location','best');

subplot(2,2,3);
plot(t, Ant.Gt, 'LineWidth', 1.5, 'DisplayName', 'Gt'); hold on;
plot(t, Ant.Gr, 'LineWidth', 1.5, 'DisplayName', 'Gr');
plot(t, Ant.Gtotal_actual, '--', 'LineWidth', 1.2, 'DisplayName', 'Gt+Gr actual');
xlabel('Time / s'); ylabel('Gain / dBi');
title('Tx/Rx antenna gain'); grid on; legend('Location','best');

subplot(2,2,4);
plot(t, Bud.G_total_required, 'LineWidth', 1.5, 'DisplayName', 'Required Gt+Gr'); hold on;
plot(t, Ant.Gtotal_actual, '--', 'LineWidth', 1.2, 'DisplayName', 'Actual Gt+Gr');
xlabel('Time / s'); ylabel('Gain / dBi');
title('Total antenna gain requirement'); grid on; legend('Location','best');
end
