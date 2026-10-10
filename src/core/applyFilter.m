function [g, G, F] = applyFilter(f, H)
% Filters every channel with a centred H(u,v): g = real(ifft2(ifftshift(H .* fftshift(fft2(f))))).
[M, N, C] = size(f);
if ~isequal(size(H), [M N])
    error('applyFilter:sizeMismatch', 'H is %d x %d but the image is %d x %d.', size(H, 1), size(H, 2), M, N);
end
F = complex(zeros(M, N, C));
G = F;
g = zeros(M, N, C);
worstImag = 0;
for c = 1:C
    F(:, :, c) = fftshift(fft2(f(:, :, c)));
    G(:, :, c) = H .* F(:, :, c);
    z = ifft2(ifftshift(G(:, :, c)));
    g(:, :, c) = real(z);
    if any(z(:))
        worstImag = max(worstImag, max(abs(imag(z(:)))) / max(abs(z(:))));
    end
end
if worstImag > 1e-6
    warning('applyFilter:complexResult', ...
        'Result had an imaginary part of %.1e, so H is probably not symmetric about the centre.', worstImag);
end
end
