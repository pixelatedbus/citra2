function H = notchRejectH(M, N, type, notches, n)
% NOTCHREJECTH  Centred notch reject transfer function: small holes at chosen frequencies.
%
%   Removes the frequency spikes of periodic noise without touching the
%   rest of the spectrum. Each notch k is a small high-pass "hole" of
%   radius D0k centred at offset (duk, dvk) from the spectrum centre. A
%   real image has a conjugate-symmetric spectrum, so every spike has a
%   mirror twin at (-duk, -dvk); each row therefore makes a PAIR of holes:
%
%       H = prod over k of  Hhp(Dk+) .* Hhp(Dk-)
%       Dk+ = distance to (centre + [duk dvk]),  Dk- = distance to (centre - [duk dvk])
%
%   with the high-pass shape Hhp = 1 - Hlp of the chosen type:
%       ideal        Hlp = (D <= D0k)
%       gaussian     Hlp = exp(-D.^2 / (2*D0k^2))
%       butterworth  Hlp = 1 ./ (1 + (D/D0k).^(2n))
%   (the same shapes as lowpassH / highpassH). Offsets may be fractional,
%   so a notch can sit exactly on a spike that falls between samples.
%
%   Distances to a notch are measured PERIODICALLY (wrapping around the
%   spectrum edges, offsets taken in [-M/2, M/2) and [-N/2, N/2)), because
%   the DFT spectrum is periodic. This keeps H exactly symmetric for even
%   sizes too: with plain distances, the first row/column of an even-sized
%   spectrum has no mirror partner inside the grid, and the long tail of a
%   Butterworth notch made H slightly asymmetric there (imaginary residue up
%   to 2e-5 of the result, flagged by applyFilter's warning).
%
%   INPUT
%     M        number of rows of the spectrum (positive integer)
%     N        number of columns of the spectrum (positive integer)
%     type     'ideal' | 'gaussian' | 'butterworth' (case-insensitive)
%     notches  K x 3 real matrix, one row [du dv D0] per notch pair:
%              du = row offset, dv = column offset (frequency samples),
%              D0 = radius (> 0). K may be 0 (no notches, H = 1).
%     n        optional, Butterworth order (positive integer, default 2)
%
%   OUTPUT
%     H        M x N double in [0,1], centred, symmetric about the centre

arguments
    M       (1,1) {mustBeInteger, mustBePositive}
    N       (1,1) {mustBeInteger, mustBePositive}
    type    {mustBeTextScalar}
    notches (:,3) {mustBeReal, mustBeFinite}
    n       (1,1) {mustBeInteger, mustBePositive} = 2
end

if any(notches(:, 3) <= 0)
    error('notchRejectH:badRadius', 'Every notch radius D0 must be > 0.');
end

[V, U] = meshgrid(1:N, 1:M);              % U = row index, V = column index
uc = floor(M/2) + 1;
vc = floor(N/2) + 1;

H = ones(M, N);
for k = 1:size(notches, 1)
    du = notches(k, 1);
    dv = notches(k, 2);
    D0 = notches(k, 3);
    Dplus  = hypot(wrap(U - uc - du, M), wrap(V - vc - dv, N));
    Dminus = hypot(wrap(U - uc + du, M), wrap(V - vc + dv, N));
    H = H .* holeAt(Dplus, type, D0, n) .* holeAt(Dminus, type, D0, n);
end
end

function d = wrap(d, P)
% Periodic offset: map d into [-P/2, P/2) (the spectrum repeats every P samples).
d = mod(d + P/2, P) - P/2;
end

function Hhp = holeAt(D, type, D0, n)
% High-pass shape 1 - Hlp(D) around one notch centre.
switch lower(type)
    case 'ideal'
        Hlp = double(D <= D0);
    case 'gaussian'
        Hlp = exp(-D.^2 / (2 * D0^2));
    case 'butterworth'
        Hlp = 1 ./ (1 + (D / D0).^(2 * n));
    otherwise
        error('notchRejectH:unknownType', ...
            'Unknown type "%s". Use ideal, gaussian or butterworth.', type);
end
Hhp = 1 - Hlp;
end
