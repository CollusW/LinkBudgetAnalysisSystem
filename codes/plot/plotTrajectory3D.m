function fig = plotTrajectory3D(LinkResult)
% plotTrajectory3D
% local XYZ 三维轨迹。

Tx = LinkResult.TxState.xyz;
Rx = LinkResult.RxState.xyz;

fig = figure('Name', '3D local XYZ trajectory', 'Position', [300, 300, 750, 600]);
plot3(Tx(:,1)/1000, Tx(:,2)/1000, Tx(:,3)/1000, 'o-', 'LineWidth', 1.5, 'DisplayName', 'Tx'); hold on;
plot3(Rx(:,1)/1000, Rx(:,2)/1000, Rx(:,3)/1000, '.-', 'LineWidth', 1.2, 'DisplayName', 'Rx');
plot3(Tx(1,1)/1000, Tx(1,2)/1000, Tx(1,3)/1000, 's', 'MarkerSize', 8, 'DisplayName', 'Tx start');
plot3(Rx(1,1)/1000, Rx(1,2)/1000, Rx(1,3)/1000, 'd', 'MarkerSize', 8, 'DisplayName', 'Rx start');
xlabel('X / km'); ylabel('Y / km'); zlabel('Z / km');
title('Tx/Rx local XYZ trajectory');
grid on; axis equal; legend('Location','best');
end
