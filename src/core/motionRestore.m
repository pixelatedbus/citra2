function [f, H, R] = motionRestore(g, psf, method, value, border)
% Restores a motion blur by inverse ('threshold', 'radius', 'none') or 'wiener'; border 'periodic', 'taper' or 'mirror'.
if nargin < 5, border = 'periodic'; end
[M, N, ~] = size(g);
switch border
    case 'periodic'
    case 'taper'
        w = taperRamp(M, max(size(psf))) * taperRamp(N, max(size(psf)))';
        g = w .* g + (1 - w) .* applyFilter(g, psf2H(psf, M, N));
    case 'mirror'
        g = [g, fliplr(g); flipud(g), rot90(g, 2)];
        if strcmpi(method, 'radius')
            value = 2 * value;
        end
    otherwise
        error('motionRestore:unknownBorder', 'Unknown border "%s".', border);
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
d = min((0:n-1)', (n-1:-1:0)');
w = 0.5 - 0.5 * cos(pi * min(d / width, 1));
end
