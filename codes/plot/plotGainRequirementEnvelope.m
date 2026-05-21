function fig = plotGainRequirementEnvelope(AnalysisResult)
% plotGainRequirementEnvelope
% Rx 视角最严苛 G_total_required 包络。

Env = AnalysisResult.GreqEnvelope;
fig = figure('Name', 'G total required envelope', 'Position', [200, 200, 800, 600]);

if isempty(fieldnames(Env))
    text(0.5, 0.5, 'Envelope disabled', 'HorizontalAlignment', 'center');
    axis off;
    return;
end

pcolor(Env.Az_bins, Env.El_bins, Env.Value);
shading flat;
colorbar;
xlabel('Az_{rx} / deg');
ylabel('El_{rx} / deg');
title('Rx view: worst-case required total antenna gain G_t+G_r');
axis([-180 180 -90 90]);
grid on;
end
