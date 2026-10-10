function psf = motionPSF(L, theta)
% Motion blur PSF: a line of length L at angle theta (degrees, clockwise on screen) with bilinear weights.
half = (L - 1) / 2;
t = linspace(-half, half, max(2, ceil(100 * L)));
R = ceil(half) + 1;
y = t * sind(theta) + R + 1;
x = t * cosd(theta) + R + 1;
y0 = floor(y);
x0 = floor(x);
ay = y - y0;
ax = x - x0;
S = 2 * R + 1;
rows = [y0, y0 + 1, y0, y0 + 1];
cols = [x0, x0, x0 + 1, x0 + 1];
w = [(1 - ay) .* (1 - ax), ay .* (1 - ax), (1 - ay) .* ax, ay .* ax];
psf = accumarray([rows(:), cols(:)], w(:), [S S]);
psf = psf / sum(psf(:));
while S > 1 && ~any(psf([1 end], :), 'all') && ~any(psf(:, [1 end]), 'all')
    psf = psf(2:end-1, 2:end-1);
    S = S - 2;
end
end
