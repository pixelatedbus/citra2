function [mse, psnr] = imageQuality(g, ref)
% IMAGEQUALITY  MSE and PSNR of a result image against a reference image.
%
%   Measures how close a processed or restored image is to the reference
%   (ground truth) from the data's reference/ folder. Both images are
%   first clipped to [0,1], so the score describes what is displayed and
%   saved, not out-of-range values that a filter may produce.
%
%       MSE  = mean over all pixels and channels of (g - ref)^2
%       PSNR = 10 * log10(1 / MSE)        (peak value 1, in dB)
%
%   Lower MSE / higher PSNR means closer to the reference. Identical
%   images give MSE = 0 and PSNR = Inf.
%
%   INPUT
%     g     result image, M x N or M x N x C, double (values outside [0,1]
%           are clipped)
%     ref   reference image, same size as g, double in [0,1]
%
%   OUTPUT
%     mse   mean squared error, scalar double >= 0
%     psnr  peak signal-to-noise ratio in dB, scalar double (Inf if mse = 0)

if ~isequal(size(g), size(ref))
    error('imageQuality:sizeMismatch', ...
        'Result is %s but reference is %s.', mat2str(size(g)), mat2str(size(ref)));
end

g   = min(max(g, 0), 1);
ref = min(max(ref, 0), 1);

mse  = mean((g - ref).^2, 'all');
psnr = 10 * log10(1 / mse);
end
