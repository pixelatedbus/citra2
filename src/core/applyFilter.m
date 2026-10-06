function [g, G, F] = applyFilter(f, H)
% APPLYFILTER  Filter an image in the frequency domain with a centred H(u,v).
%
%   Runs the project pipeline on each channel separately (grey has one
%   channel, RGB has three, all filtered with the same H):
%
%       F = fftshift(fft2(f))        centred spectrum of the input
%       G = H .* F                   apply the transfer function
%       g = real(ifft2(ifftshift(G)))  back to the spatial domain
%
%   real() only drops round-off: for a real image and an H that is
%   symmetric about the centre, the inverse transform is real.
%   No zero-padding, so the filter acts circularly (wraps at the borders).
%   The result is not clipped; clip only when displaying or saving.
%
%   INPUT
%     f   image, M x N (grey) or M x N x C (colour), double, normally [0,1]
%     H   transfer function, M x N, centred (DC at floor(M/2)+1, floor(N/2)+1),
%         real or complex
%
%   OUTPUT
%     g   filtered image, same size as f, double, not clipped
%     G   centred spectrum after filtering, M x N x C, complex
%     F   centred spectrum of the input, M x N x C, complex

[M, N, C] = size(f);
if ~isequal(size(H), [M N])
    error('applyFilter:sizeMismatch', ...
        'H is %d x %d but the image is %d x %d.', size(H, 1), size(H, 2), M, N);
end

F = complex(zeros(M, N, C));
G = complex(zeros(M, N, C));
g = zeros(M, N, C);

% One channel at a time: fftshift on an M x N x 3 array would also
% shift along the third dimension and reorder the colour channels.
for c = 1:C
    F(:, :, c) = fftshift(fft2(f(:, :, c)));
    G(:, :, c) = H .* F(:, :, c);
    g(:, :, c) = real(ifft2(ifftshift(G(:, :, c))));
end
end
