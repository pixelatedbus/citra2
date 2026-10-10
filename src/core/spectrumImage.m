function S = spectrumImage(F)
% Spectrum for display: log(1 + |F|) averaged over channels and divided by its maximum.
S = log(1 + mean(abs(F), 3));
if max(S(:)) > 0
    S = S / max(S(:));
end
end
