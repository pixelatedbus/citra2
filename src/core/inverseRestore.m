function [f, R] = inverseRestore(g, H, mode, value)
% Inverse filter G ./ H, stabilised by 'threshold' (drop |H| < t), 'radius' (Butterworth R0) or 'none'.
if nargin < 4, value = 0; end
R = 1 ./ H;
switch lower(mode)
    case 'threshold'
        R(abs(H) < value) = 0;
    case 'radius'
        if value <= 0
            error('inverseRestore:badRadius', 'Radius R0 must be positive.');
        end
        R = lowpassH(size(H, 1), size(H, 2), 'butterworth', value, 10) .* R;
    case 'none'
    otherwise
        error('inverseRestore:unknownMode', 'Unknown mode "%s".', mode);
end
R(H == 0) = 0;
f = applyFilter(g, R);
end
