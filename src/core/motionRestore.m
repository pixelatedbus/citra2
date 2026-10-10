function [f, H, R] = motionRestore(g, psf, method, value, border)
% MOTIONRESTORE  Restore a motion-blurred image with a known PSF (part F).
%
%   One call for the GUI and the batch run: builds H(u,v) from the PSF
%   (psf2H), restores with inverse filtering (inverseRestore) or Wiener
%   filtering (wienerRestore), and handles the image border.
%
%   Border: the DFT treats the image as periodic, so restoration assumes
%   the blur wrapped around the edges. A real blur (and the official test
%   data) does not wrap. The mismatch at the edges then shows up as
%   ringing stripes along the motion direction. Three options:
%     'periodic'  restore the image as it is (no padding; G = H .* F
%                 holds exactly only for a circular blur)
%     'taper'     edge taper: near the borders, blend g into its own
%                 circular blur, gt = w.*g + (1-w).*applyFilter(g, H),
%                 with w a raised-cosine ramp from 0 at the edge to 1 at
%                 one PSF width inside. The edges then fit the periodic
%                 model and the jump at the wrap-around is gone.
%     'mirror'    restore the 2M x 2N mirror extension [g fliplr(g);
%                 flipud(g) rot90(g,2)], then keep the top-left M x N
%                 block. Exact only for theta = 0 or 90 degrees: a
%                 mirrored copy of a diagonal blur has the mirrored angle.
%   With 'mirror', H and R are built for the 2M x 2N spectrum, and a
%   radius R0 is doubled internally so it keeps its meaning in samples of
%   the M x N spectrum.
%
%   INPUT
%     g       degraded image, M x N or M x N x C, double in [0,1]
%     psf     odd-sized PSF summing to 1, e.g. motionPSF(L, theta)
%     method  'threshold' | 'radius' | 'none' (inverse filter, see
%             inverseRestore) or 'wiener' (case-insensitive)
%     value   t, R0 or K for that method (real >= 0; ignored for 'none')
%     border  optional, 'periodic' (default), 'taper' or 'mirror'
%
%   OUTPUT
%     f       restored image, same size as g, double, not clipped
%     H       centred degradation function used (M x N, or 2M x 2N with
%             'mirror'), complex
%     R       centred restoration filter used, same size as H, complex

arguments
    g {mustBeNumeric}
    psf {mustBeNumeric}
    method {mustBeTextScalar}
    value (1,1) {mustBeReal, mustBeNonnegative}
    border {mustBeMember(border, {'periodic', 'taper', 'mirror'})} = 'periodic'
end

[M, N, ~] = size(g);
switch border
    case 'taper'
        H = psf2H(psf, M, N);
        w = taperRamp(M, max(size(psf))) * taperRamp(N, max(size(psf)))';
        g = w .* g + (1 - w) .* applyFilter(g, H);
    case 'mirror'
        g = [g, fliplr(g); flipud(g), rot90(g, 2)];
        if strcmpi(method, 'radius')
            value = 2 * value;
        end
end

H = psf2H(psf, size(g, 1), size(g, 2));
if strcmpi(method, 'wiener')
    [f, R] = wienerRestore(g, H, value);
else
    [f, R] = inverseRestore(g, H, method, value);
end
f = f(1:M, 1:N, :);
end

function w = taperRamp(n, width)
% Column vector: 0 at both ends, rising as a raised cosine to 1 at 'width'
% samples from the nearest end.
d = min((0:n-1)', (n-1:-1:0)');
w = 0.5 - 0.5 * cos(pi * min(d / width, 1));
end
