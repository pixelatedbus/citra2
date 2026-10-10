function H = highpassH(M, N, type, D0, n)
% HIGHPASSH  Centred high-pass transfer function: ideal, Gaussian or Butterworth.
%
%   Removes frequencies near the centre (DC and slow intensity changes)
%   and keeps those far from it, so edges and fine detail remain. Built as
%   the complement of the matching low-pass filter:
%
%       H_hp = 1 - H_lp            (H_lp from lowpassH, same parameters)
%
%   which gives
%       ideal        H = 1 if D > D0, else 0
%       gaussian     H = 1 - exp(-D.^2 / (2*D0^2))
%       butterworth  H = 1 ./ (1 + (D0./D).^(2n))
%
%   At D = D0 the three give 0, 1 - exp(-1/2) ~ 0.393 and 0.5. H = 0 at the
%   centre, so the mean (DC) is removed and the result has negative values;
%   how to display it is the caller's choice (see highpassDisplay).
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
%     H     M x N double in [0,1], centred, H = 0 at the centre

arguments
    M    (1,1) {mustBeInteger, mustBePositive}
    N    (1,1) {mustBeInteger, mustBePositive}
    type {mustBeTextScalar}
    D0   (1,1) {mustBeReal, mustBePositive}
    n    (1,1) {mustBeInteger, mustBePositive} = 2
end

H = 1 - lowpassH(M, N, type, D0, n);
end
