function H = brightnessH(M, N, gL, gH, D0)
% Emphasis filter H = gH + (gL - gH) * Gaussian low-pass(D0); D0 = 0 gives gL to the DC term only.
if D0 == 0
    G = zeros(M, N);
    G(floor(M/2) + 1, floor(N/2) + 1) = 1;
else
    G = lowpassH(M, N, 'gaussian', D0);
end
H = gH + (gL - gH) * G;
end
