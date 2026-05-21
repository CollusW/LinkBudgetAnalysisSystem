function [GreqEnvelope, MarginEnvelope] = buildGainRequirementEnvelope(Az, El, Greq, Margin, azBinDeg, elBinDeg)
% buildGainRequirementEnvelope
% 在 Rx 视角 Az/El 空间统计最严苛 G_total_required 和最小 Margin。

Az_bins = -180:azBinDeg:180;
El_bins = -90:elBinDeg:90;

Gmat = nan(numel(El_bins), numel(Az_bins));
Mmat = nan(numel(El_bins), numel(Az_bins));

for i = 1:numel(Az)
    [~, iaz] = min(abs(Az_bins - Az(i)));
    [~, iel] = min(abs(El_bins - El(i)));

    if isnan(Gmat(iel, iaz)) || Greq(i) > Gmat(iel, iaz)
        Gmat(iel, iaz) = Greq(i);
    end

    if isnan(Mmat(iel, iaz)) || Margin(i) < Mmat(iel, iaz)
        Mmat(iel, iaz) = Margin(i);
    end
end

GreqEnvelope = struct();
GreqEnvelope.Az_bins = Az_bins;
GreqEnvelope.El_bins = El_bins;
GreqEnvelope.Value = Gmat;

MarginEnvelope = struct();
MarginEnvelope.Az_bins = Az_bins;
MarginEnvelope.El_bins = El_bins;
MarginEnvelope.Value = Mmat;
end
