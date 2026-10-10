function g = motionDegrade(f, psf, sigma, seed)
% Degradation model: circular blur with the PSF plus Gaussian noise of std sigma (fixed seed).
if nargin < 3, sigma = 0; end
if nargin < 4, seed = 0; end
g = applyFilter(f, psf2H(psf, size(f, 1), size(f, 2)));
if sigma > 0
    previous = rng(seed);
    g = g + sigma * randn(size(g));
    rng(previous);
end
end
