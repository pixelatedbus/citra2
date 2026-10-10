function H = psf2H(psf, M, N)
% Centred transfer function of an odd-sized PSF for an M x N image, with the PSF centre moved to (1,1).
[h, w] = size(psf);
if mod(h, 2) == 0 || mod(w, 2) == 0
    error('psf2H:evenSize', 'PSF must have an odd size (got %d x %d).', h, w);
end
if h > M || w > N
    error('psf2H:tooLarge', 'PSF (%d x %d) is larger than the image (%d x %d).', h, w, M, N);
end
P = zeros(M, N);
P(1:h, 1:w) = psf;
P = circshift(P, [-(h - 1) / 2, -(w - 1) / 2]);
H = fftshift(fft2(P));
end
