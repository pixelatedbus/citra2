function H = psf2H(psf, M, N)
% PSF2H  Centred transfer function H(u,v) of a PSF, for an M x N image.
%
%   The degradation model of part F is G = H .* F (+ noise). H is the DFT
%   of the PSF placed in an M x N array. The PSF's centre must sit at
%   index (1,1), with the rest wrapped around the edges (circshift).
%   Otherwise the blurred or restored image is shifted by the offset of
%   the centre. Then
%
%       P = M x N zeros, psf in the top-left corner, circshift(-centre)
%       H = fftshift(fft2(P))
%
%   fftshift centres H like every other filter in this project, so it
%   goes straight into applyFilter. A real PSF that is symmetric about its
%   centre (a motion line is) gives a conjugate-symmetric H, so filtered
%   images stay real. H is complex in general and |H(centre)| = sum(psf).
%
%   INPUT
%     psf  h x w double, h and w odd, centre at ((h+1)/2, (w+1)/2),
%          e.g. motionPSF(L, theta); not larger than M x N
%     M    number of rows of the image (positive integer)
%     N    number of columns of the image (positive integer)
%
%   OUTPUT
%     H    M x N complex double, centred (DC at floor(M/2)+1, floor(N/2)+1)

arguments
    psf {mustBeNumeric, mustBeReal}
    M   (1,1) {mustBeInteger, mustBePositive}
    N   (1,1) {mustBeInteger, mustBePositive}
end

[h, w] = size(psf);
if mod(h, 2) == 0 || mod(w, 2) == 0
    error('psf2H:evenSize', 'PSF must have odd size so it has a centre pixel (got %d x %d).', h, w);
end
if h > M || w > N
    error('psf2H:tooLarge', 'PSF (%d x %d) is larger than the image (%d x %d).', h, w, M, N);
end

P = zeros(M, N);
P(1:h, 1:w) = psf;
P = circshift(P, [-(h - 1) / 2, -(w - 1) / 2]);   % PSF centre to (1,1)
H = fftshift(fft2(P));
end
