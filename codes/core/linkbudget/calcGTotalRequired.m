function G_total_required = calcGTotalRequired(Lfs, Margin_target, Pt, Sens, L_other)
% calcGTotalRequired
% 为满足目标链路余量所需的 Tx+Rx 总天线增益。
% Margin = Pt + Gt + Gr - Lfs - L_other - Sens >= Margin_target
% 所以 Gt+Gr >= Lfs + L_other + Margin_target - (Pt - Sens)

G_total_required = Lfs + L_other + Margin_target - (Pt - Sens);
end
