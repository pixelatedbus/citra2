function g = motionDegrade(f, psf, sigma, seed)
% MOTIONDEGRADE  Apply the degradation model G = H .* F + N to a clean image.
%
%   Blurs f with the PSF in the frequency domain (circularly, through
%   psf2H and applyFilter) and adds white Gaussian noise of standard
%   deviation sigma:
%
%       g = real(ifft2(H .* F)) + sigma * randn
%
%   Used to try the restoration on a clean image (GUI "simulate" option)
%   and in tests, where the true image is known. The noise comes from a
%   fixed seed so a result can be reproduced; the global random state is
%   restored afterwards. The result is not clipped.
%
%   INPUT
%     f      clean image, M x N or M x N x C, double in [0,1]
%     psf    odd-sized PSF summing to 1, e.g. motionPSF(L, theta)
%     sigma  optional, noise standard deviation (real >= 0, default 0)
%     seed   optional, random seed for the noise (default 0)
%
%   OUTPUT
%     g      degraded image, same size as f, double, not clipped

arguments
    f {mustBeNumeric}
    psf {mustBeNumeric}
    sigma (1,1) {mustBeReal, mustBeNonnegative} = 0
    seed (1,1) {mustBeInteger, mustBeNonnegative} = 0
end

g = applyFilter(f, psf2H(psf, size(f, 1), size(f, 2)));
if sigma > 0
    previous = rng(seed);
    g = g + sigma * randn(size(g));
    rng(previous);
end
end
