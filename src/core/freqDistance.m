function D = freqDistance(M, N, du, dv)
% Distance of every sample of a centred M x N spectrum from the centre, optionally shifted by (du, dv).
if nargin < 3, du = 0; end
if nargin < 4, dv = 0; end
uc = floor(M/2) + 1 + du;
vc = floor(N/2) + 1 + dv;
[V, U] = meshgrid(1:N, 1:M);
D = sqrt((U - uc).^2 + (V - vc).^2);
end
