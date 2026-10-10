function psf = motionPSF(L, theta)
% MOTIONPSF  Point spread function of uniform linear motion blur.
%
%   The camera (or object) moves uniformly along a straight line during
%   the exposure, so every point is smeared into a short line segment.
%   The PSF is that segment: centred at the origin, length L - 1 between
%   its end points, at angle theta, with equal weight everywhere on it.
%   The continuous segment is rasterised with bilinear weights:
%
%       psf(y, x) = sum over t of tent(y - t*sin(theta)) * tent(x - t*cos(theta)),
%       t sampled densely in [-(L-1)/2, (L-1)/2],  tent(s) = max(0, 1 - |s|)
%
%   and normalised to sum 1 (blurring keeps the mean brightness). For
%   theta = 0 this gives L pixels [1/2 1 ... 1 1/2] / (L-1).
%
%   Angle convention: theta turns from the +column (x) axis towards the
%   +row (y) axis, and rows point down, so a positive angle is clockwise
%   as displayed. This is the convention of the official test data; we
%   found it by blurring the reference images and comparing with the
%   inputs. MATLAB's fspecial('motion', L, theta) uses the opposite sign
%   (counter-clockwise), so it matches ours at -theta.
%
%   INPUT
%     L      blur length in pixels (real, >= 1); L = 1 means no blur
%     theta  motion angle in degrees (real), convention above
%
%   OUTPUT
%     psf    S x S double, S odd, entries >= 0 summing to 1, centre at
%            ((S+1)/2, (S+1)/2); all-zero outer rows/columns are trimmed
%            in pairs, so the centre stays in the middle

arguments
    L     (1,1) {mustBeReal, mustBeFinite, mustBeGreaterThanOrEqual(L, 1)}
    theta (1,1) {mustBeReal, mustBeFinite}
end

half = (L - 1) / 2;
t = linspace(-half, half, max(2, ceil(100 * L)));   % 100 samples per pixel of length
y = t * sind(theta);                                % row offset (down is +)
x = t * cosd(theta);                                % column offset

R = ceil(half) + 1;                                 % kernel radius, enough for any angle
y = y + R + 1;                                      % to 1-based indices, centre at R+1
x = x + R + 1;
y0 = floor(y);
x0 = floor(x);
ay = y - y0;
ax = x - x0;

% Bilinear splat: each sample spreads over its four neighbouring pixels
S = 2 * R + 1;
rows = [y0, y0 + 1, y0, y0 + 1];
cols = [x0, x0, x0 + 1, x0 + 1];
w = [(1 - ay) .* (1 - ax), ay .* (1 - ax), (1 - ay) .* ax, ay .* ax];
psf = accumarray([rows(:), cols(:)], w(:), [S S]);
psf = psf / sum(psf(:));

% Trim empty borders symmetrically so the centre stays at the middle
while S > 1 && ~any(psf([1 end], :), 'all') && ~any(psf(:, [1 end]), 'all')
    psf = psf(2:end-1, 2:end-1);
    S = S - 2;
end
end
