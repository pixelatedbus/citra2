function [f, R] = wienerRestore(g, H, K)
% WIENERRESTORE  Wiener filtering in the frequency domain with a constant K.
%
%   Restores an image degraded as G = H .* F + N. The Wiener filter
%   minimises the mean squared error between the estimate and F. With the
%   noise-to-signal power ratio approximated by one constant K:
%
%       Fhat = conj(H) ./ (|H|.^2 + K) .* G      (per channel, applyFilter)
%
%   Where |H|^2 >> K this is 1 ./ H (inverse filtering). Where |H|^2 << K
%   the gain falls smoothly to 0 instead of exploding, so noise at the
%   frequencies the blur destroyed is not amplified. K = 0 is the plain
%   inverse filter; a larger K suppresses more noise but leaves more blur.
%   At H = 0 the filter is 0 for every K > 0.
%
%   INPUT
%     g   degraded image, M x N or M x N x C, double
%     H   centred degradation transfer function, M x N, complex
%     K   noise-to-signal ratio constant (real, >= 0)
%
%   OUTPUT
%     f   restored image, same size as g, double, not clipped
%     R   M x N complex Wiener filter that was applied, centred,
%         so f = applyFilter(g, R)

arguments
    g {mustBeNumeric}
    H {mustBeNumeric}
    K (1,1) {mustBeReal, mustBeNonnegative}
end

R = conj(H) ./ (abs(H).^2 + K);
R(H == 0) = 0;          % K = 0 would give 0/0 there

f = applyFilter(g, R);
end
