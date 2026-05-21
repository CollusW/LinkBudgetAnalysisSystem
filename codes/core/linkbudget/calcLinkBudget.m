function [Pr, Margin] = calcLinkBudget(Pt, Gt, Gr, Lfs, L_other, Sens)
% calcLinkBudget
% 接收功率与链路余量。

Pr = Pt + Gt + Gr - Lfs - L_other;
Margin = Pr - Sens;
end
