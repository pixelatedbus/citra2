function [g, H, Zin, Zout] = homomorphicBrightness(f, gL, gH, D0, t)
% HOMOMORPHICBRIGHTNESS  Brighten an image by homomorphic filtering (part D).
%
%   An image is roughly illumination x reflectance, and a dark image is
%   one whose illumination is too low. The log turns that product into a
%   sum, so it can be filtered in the frequency domain:
%
%       z    = log(f + eps0)                     eps0 = 1/255 (one grey level)
%       Z    = fftshift(fft2(z))                 log spectrum, per channel
%       Zout = H .* Z,  H = brightnessH(M, N, gL, gH, D0)
%       Zout(centre) = Zout(centre) + M*N*s      DC: set the brightness
%       g    = exp(real(ifft2(ifftshift(Zout)))) - eps0
%
%   The DC term of the log spectrum is M*N times mean(log(f + eps0)), the
%   log of the geometric mean of f + eps0. The shift s is chosen so that
%   the geometric mean of the result (+ eps0) becomes the target t:
%
%       s = log(t) - gL * mean(log(f + eps0))    (mean over all channels)
%
%   gL < 1 compresses slow illumination changes (bright and dark regions
%   move closer) and gH sets the contrast of edges and texture (gH < 1
%   raises dark detail more than bright detail, as a gamma < 1 does).
%   Colour: every channel gets the same H and the same shift s, so the
%   colour channels keep their relation.
%
%   INPUT
%     f    image, M x N or M x N x C, double in [0,1]
%     gL   low-frequency gain of the log spectrum (real, >= 0)
%     gH   high-frequency gain of the log spectrum (real, >= 0)
%     D0   transition radius in frequency samples (real, >= 0; 0 = only
%          the DC term gets gL)
%     t    target brightness: geometric mean of the result (real, in (0, 1])
%
%   OUTPUT
%     g    brightened image, same size as f, double, not clipped
%     H    M x N filter applied to the log spectrum (brightnessH)
%     Zin  M x N x C centred log spectrum before filtering
%     Zout M x N x C centred log spectrum after filtering and the DC shift

arguments
    f {mustBeNumeric}
    gL (1,1) {mustBeReal, mustBeFinite, mustBeNonnegative}
    gH (1,1) {mustBeReal, mustBeFinite, mustBeNonnegative}
    D0 (1,1) {mustBeReal, mustBeFinite, mustBeNonnegative}
    t  (1,1) {mustBeReal, mustBePositive, mustBeLessThanOrEqual(t, 1)}
end

eps0 = 1 / 255;
[M, N, ~] = size(f);
z = log(max(f, 0) + eps0);

H = brightnessH(M, N, gL, gH, D0);
[~, Zout, Zin] = applyFilter(z, H);

uc = floor(M/2) + 1;
vc = floor(N/2) + 1;
s = log(t) - gL * mean(z, 'all');
Zout(uc, vc, :) = Zout(uc, vc, :) + M * N * s;

g = zeros(size(f));
for c = 1:size(f, 3)
    g(:, :, c) = exp(real(ifft2(ifftshift(Zout(:, :, c))))) - eps0;
end
end
