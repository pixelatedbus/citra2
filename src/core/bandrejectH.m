function H = bandrejectH(M, N, type, D0, W, n)
% BANDREJECTH  Centred bandreject transfer function: a ring of radius D0 and width W.
%
%   Removes every frequency at distance ~D0 from the centre, whatever its
%   direction, and keeps the rest. Suited to periodic noise whose spikes
%   lie on (or spread around) a circle. With D = freqDistance(M, N):
%
%       ideal        H = 0 if D0 - W/2 <= D <= D0 + W/2, else 1
%       butterworth  H = 1 ./ (1 + ((D.*W) ./ (D.^2 - D0^2)).^(2n))
%       gaussian     H = 1 - exp(-((D.^2 - D0^2) ./ (D.*W)).^2)
%
%   All three are 0 on the ring (D = D0) and 1 at the centre (DC kept).
%   For Butterworth and Gaussian, W sets where |D.^2 - D0^2| = D.*W, the
%   band edge, where H = 0.5 and 1 - exp(-1) ~ 0.632. MATLAB's Inf
%   arithmetic gives the right limits at D = D0 and D = 0, so no eps
%   is needed (division by zero there gives Inf, and H the limit value).
%
%   INPUT
%     M     number of rows of the spectrum (positive integer)
%     N     number of columns of the spectrum (positive integer)
%     type  'ideal' | 'butterworth' | 'gaussian' (case-insensitive)
%     D0    ring radius in frequency samples (real, > 0)
%     W     ring width in frequency samples (real, > 0)
%     n     optional, Butterworth order (positive integer, default 2);
%           ignored by the other types
%
%   OUTPUT
%     H     M x N double in [0,1], centred, H = 1 at the centre

arguments
    M    (1,1) {mustBeInteger, mustBePositive}
    N    (1,1) {mustBeInteger, mustBePositive}
    type {mustBeTextScalar}
    D0   (1,1) {mustBeReal, mustBePositive}
    W    (1,1) {mustBeReal, mustBePositive}
    n    (1,1) {mustBeInteger, mustBePositive} = 2
end

D = freqDistance(M, N);

switch lower(type)
    case 'ideal'
        H = double(~(D >= D0 - W/2 & D <= D0 + W/2));
    case 'butterworth'
        H = 1 ./ (1 + ((D .* W) ./ (D.^2 - D0^2)).^(2 * n));
    case 'gaussian'
        H = 1 - exp(-((D.^2 - D0^2) ./ (D .* W)).^2);
    otherwise
        error('bandrejectH:unknownType', ...
            'Unknown type "%s". Use ideal, butterworth or gaussian.', type);
end
end
