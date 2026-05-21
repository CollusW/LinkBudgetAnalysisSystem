function Lfs = calcFSPL(d_m, f_Hz, c)
% calcFSPL
% 自由空间路径损耗。
% Lfs = 20log10(4*pi*d*f/c)

d_m = max(d_m, eps);
Lfs = 20*log10(4*pi*d_m.*f_Hz./c);
end
