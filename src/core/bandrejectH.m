function H = bandrejectH(M, N, type, D0, W, n)
% Centred bandreject ring of radius D0 and width W: 'ideal', 'butterworth' or 'gaussian'.
if nargin < 6, n = 2; end
D = freqDistance(M, N);
switch lower(type)
    case 'ideal'
        H = double(~(D >= D0 - W/2 & D <= D0 + W/2));
    case 'butterworth'
        H = 1 ./ (1 + ((D .* W) ./ (D.^2 - D0^2)).^(2 * n));
    case 'gaussian'
        H = 1 - exp(-((D.^2 - D0^2) ./ (D .* W)).^2);
    otherwise
        error('bandrejectH:unknownType', 'Unknown filter type "%s".', type);
end
end
