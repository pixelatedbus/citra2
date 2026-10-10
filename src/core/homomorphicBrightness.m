function [g, H, Zin, Zout] = homomorphicBrightness(f, gL, gH, D0, t)
% Homomorphic brightening: filter the spectrum of log(f) and set its DC so the geometric mean becomes t.
if t <= 0 || t > 1
    error('homomorphicBrightness:badTarget', 'Target brightness t must be in (0, 1].');
end
eps0 = 1 / 255;
[M, N, C] = size(f);
z = log(max(f, 0) + eps0);
H = brightnessH(M, N, gL, gH, D0);
[~, Zout, Zin] = applyFilter(z, H);
uc = floor(M/2) + 1;
vc = floor(N/2) + 1;
s = log(t) - gL * mean(z, 'all');
Zout(uc, vc, :) = Zout(uc, vc, :) + M * N * s;
g = zeros(M, N, C);
for c = 1:C
    g(:, :, c) = exp(real(ifft2(ifftshift(Zout(:, :, c))))) - eps0;
end
end
