function S = spectrumImage(F)
% SPECTRUMIMAGE  Turn a centred spectrum into a displayable image in [0,1].
%
%   The magnitude of a spectrum spans many orders of magnitude (DC is
%   huge, high frequencies are tiny), so it is compressed with a log:
%
%       S = log(1 + |F|) / max(log(1 + |F|))
%
%   Dividing by the maximum (instead of stretching min..max) keeps zero
%   at zero, so frequencies removed by a filter show as black.
%   For a colour spectrum, |F| is averaged over the channels first, giving
%   one picture per image.
%
%   INPUT
%     F   centred spectrum, M x N or M x N x C, complex or real
%         (e.g. the F or G output of applyFilter)
%
%   OUTPUT
%     S   M x N double in [0,1]; all zeros if F is all zero

S = log(1 + mean(abs(F), 3));

peak = max(S(:));
if peak > 0
    S = S / peak;
end
end
