function H = lowpassH(M, N, type, D0, n)
% Centred low-pass H(u,v): 'ideal', 'gaussian' or 'butterworth' of order n (default 2).
if nargin < 5, n = 2; end
D = freqDistance(M, N);
switch lower(type)
    case 'ideal'
        H = double(D <= D0);
    case 'gaussian'
        H = exp(-D.^2 / (2 * D0^2));
    case 'butterworth'
        H = 1 ./ (1 + (D / D0).^(2 * n));
    otherwise
        error('lowpassH:unknownType', 'Unknown filter type "%s".', type);
end
end
