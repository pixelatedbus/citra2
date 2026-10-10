function H = brightnessH(M, N, gL, gH, D0)
% BRIGHTNESSH  Centred emphasis filter: gain gL at low, gH at high frequencies.
%
%   Brightness lives in the lowest frequencies: the DC term is M*N times
%   the mean intensity, and slow changes of illumination sit next to it.
%   Edges and texture sit at higher frequencies. This filter gives the two
%   ranges separate gains, with a Gaussian transition of radius D0:
%
%       H = gH + (gL - gH) * exp(-D.^2 / (2*D0^2))
%
%   so H = gL at the centre and H -> gH far from it. D0 = 0 is the limit
%   of a very narrow Gaussian: only the DC term gets gL, every other
%   frequency gets gH.
%   Part D uses it twice (see brightenImage):
%     - low-frequency emphasis on the image itself: gL = k > 1, gH = 1
%       (D0 = 0: only the mean is raised);
%     - homomorphic filtering on log(image): gL and gH < 1 compress the
%       illumination and the contrast of the log image.
%
%   INPUT
%     M    number of rows of the spectrum (positive integer)
%     N    number of columns of the spectrum (positive integer)
%     gL   gain at the centre / low frequencies (real, >= 0)
%     gH   gain at high frequencies (real, >= 0)
%     D0   transition radius in frequency samples (real, >= 0; 0 = DC only)
%
%   OUTPUT
%     H    M x N double, centred, real, symmetric about the centre,
%          values between gL and gH (H = gL at the centre)

arguments
    M  (1,1) {mustBeInteger, mustBePositive}
    N  (1,1) {mustBeInteger, mustBePositive}
    gL (1,1) {mustBeReal, mustBeFinite, mustBeNonnegative}
    gH (1,1) {mustBeReal, mustBeFinite, mustBeNonnegative}
    D0 (1,1) {mustBeReal, mustBeFinite, mustBeNonnegative}
end

if D0 == 0
    G = zeros(M, N);                     % DC term only
    G(floor(M/2) + 1, floor(N/2) + 1) = 1;
else
    G = lowpassH(M, N, 'gaussian', D0);  % exp(-D.^2 / (2*D0^2))
end
H = gH + (gL - gH) * G;
end
