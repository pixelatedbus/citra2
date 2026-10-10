function [f, R] = inverseRestore(g, H, mode, value)
% INVERSERESTORE  Inverse filtering in the frequency domain, stabilised.
%
%   Undoes a known degradation H by dividing it out of the spectrum:
%
%       Fhat = G ./ H        (applied per channel through applyFilter)
%
%   Where |H| is tiny, G ./ H multiplies the noise (and the 8-bit rounding
%   error) by a huge factor, and where H = 0 it is undefined. A motion
%   blur H is zero along whole lines, so the plain inverse is unusable.
%   The division is therefore stabilised in one of two ways:
%
%     'threshold'  R = 1 ./ H where |H| >= t, and R = 0 where |H| < t:
%                  frequencies the blur almost destroyed are dropped
%                  instead of amplified (value = t)
%     'radius'     R = B ./ H with B a Butterworth low-pass (order 10) of
%                  radius R0: only frequencies inside R0 are restored
%                  (value = R0, in frequency samples)
%     'none'       R = 1 ./ H, the plain inverse (to show the problem)
%
%   In every mode R = 0 where H is exactly 0, because 1/0 has no meaning
%   there. For the radius mode, note that |H| can still be close to 0
%   inside R0 (a motion blur H has zeros at about M/L samples along the
%   motion direction), so R0 must stay below the first zero to be stable.
%
%   INPUT
%     g      degraded image, M x N or M x N x C, double
%     H      centred degradation transfer function, M x N, complex
%            (e.g. psf2H(motionPSF(L, theta), M, N))
%     mode   'threshold' | 'radius' | 'none' (case-insensitive)
%     value  t for 'threshold' (real >= 0), R0 for 'radius' (real > 0);
%            ignored for 'none' (optional there)
%
%   OUTPUT
%     f      restored image, same size as g, double, not clipped
%     R      M x N complex restoration filter that was applied, centred,
%            so f = applyFilter(g, R)

arguments
    g {mustBeNumeric}
    H {mustBeNumeric}
    mode {mustBeTextScalar}
    value (1,1) {mustBeReal, mustBeNonnegative} = 0
end

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
        % plain inverse
    otherwise
        error('inverseRestore:unknownMode', ...
            'Unknown mode "%s". Use threshold, radius or none.', mode);
end
R(H == 0) = 0;

f = applyFilter(g, R);
end
