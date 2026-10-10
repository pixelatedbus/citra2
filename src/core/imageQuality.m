function [mse, psnr] = imageQuality(g, ref)
% MSE and PSNR (peak value 1) of g against ref, both clipped to [0,1] first.
if ~isequal(size(g), size(ref))
    error('imageQuality:sizeMismatch', 'Result is %s but reference is %s.', mat2str(size(g)), mat2str(size(ref)));
end
g = min(max(g, 0), 1);
ref = min(max(ref, 0), 1);
mse = mean((g - ref).^2, 'all');
psnr = 10 * log10(1 / mse);
end
