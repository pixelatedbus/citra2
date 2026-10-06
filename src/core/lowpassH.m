function H = lowpassH(M, N, type, D0, n)
% LOWPASSH  Centred low-pass transfer function: ideal, Gaussian or Butterworth.
%
%   Keeps frequencies near the centre (DC) and attenuates those far from
%   it, which smooths or blurs the image. With D = freqDistance(M, N):
%
%       ideal        H = 1 if D <= D0, else 0
%       gaussian     H = exp(-D.^2 / (2*D0^2))
%       butterworth  H = 1 ./ (1 + (D/D0).^(2n))
%
%   At D = D0 the three give 1, exp(-1/2) ~ 0.607 and 0.5. The ideal cut is
%   sharp (ringing), the Gaussian is smooth (no ringing), and the
%   Butterworth sits in between: larger n means a sharper cut.
%   Shared foundation: used by part B, and by parts D and F as a building block.
%
%   INPUT
%     M     number of rows of the spectrum (positive integer)
%     N     number of columns of the spectrum (positive integer)
%     type  'ideal' | 'gaussian' | 'butterworth' (case-insensitive)
%     D0    cutoff radius in frequency samples (real, > 0)
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
    n    (1,1) {mustBeInteger, mustBePositive} = 2
end

D = freqDistance(M, N);

switch lower(type)
    case 'ideal'
        H = double(D <= D0);
    case 'gaussian'
        H = exp(-D.^2 / (2 * D0^2));
    case 'butterworth'
        H = 1 ./ (1 + (D / D0).^(2 * n));
    otherwise
        error('lowpassH:unknownType', ...
            'Unknown type "%s". Use ideal, gaussian or butterworth.', type);
end
end
